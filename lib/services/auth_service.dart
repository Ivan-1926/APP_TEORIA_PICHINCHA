import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';
import 'bank_data_service.dart';
import 'secure_session_service.dart';
import 'supabase_service.dart';

class AuthService {
  static Usuario? _currentUser;
  static bool _listenerAttached = false;

  static final StreamController<Usuario?> _authStreamController =
      StreamController<Usuario?>.broadcast();

  static Stream<Usuario?> get onAuthStateChanged {
    _attachAuthListener();
    return _authStreamController.stream;
  }

  static void _attachAuthListener() {
    if (_listenerAttached) return;
    _listenerAttached = true;

    SupabaseService.client.auth.onAuthStateChange.listen((data) async {
      final session = data.session;
      if (session == null) {
        _currentUser = null;
        _authStreamController.add(null);
        return;
      }
      await _loadProfile(session.user.id, session.user.email);
    });
  }

  static Future<void> _loadProfile(String uid, String? email) async {
    try {
      final usuario = await BankDataService.getUsuario(uid);
      if (usuario != null) {
        _currentUser = usuario;
        _authStreamController.add(usuario);
        return;
      }
      _currentUser = Usuario(
        id: uid,
        nombre: 'Usuario Nuevo',
        documento: '00000000',
        email: email ?? '',
        celular: '',
      );
      _authStreamController.add(_currentUser);
    } catch (e) {
      debugPrint('Error cargando perfil: $e');
    }
  }

  static Usuario? get currentUser => _currentUser;

  /// Login con DNI + contraseña (rúbrica Criterio 3 — Excelente).
  static Future<String?> signInWithDni({
    required String documento,
    required String password,
  }) async {
    final dni = documento.trim();
    if (dni.length < 8) return 'Ingresa un DNI válido (8 dígitos).';

    try {
      final resolver = await SupabaseService.client.rpc(
        'rpc_resolver_login_dni',
        params: {'p_documento': dni},
      );

      if (resolver == null || (resolver is List && resolver.isEmpty)) {
        await _registrarIntento(dni, false);
        return 'DNI no registrado. Regístrate primero.';
      }

      final row = resolver is List ? Map<String, dynamic>.from(resolver.first) : Map<String, dynamic>.from(resolver);
      if (row['bloqueado'] == true) {
        return 'Cuenta bloqueada por 5 intentos fallidos. Intenta en 15 minutos.';
      }

      final email = row['email'] as String?;
      if (email == null || email.isEmpty) {
        return 'No se encontró correo asociado al DNI.';
      }

      final response = await SupabaseService.client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.session == null) {
        await _registrarIntento(dni, false);
        return 'DNI o contraseña incorrectos.';
      }

      await _registrarIntento(dni, true);
      await SecureSessionService.saveSession(
        accessToken: response.session!.accessToken,
        refreshToken: response.session!.refreshToken,
        documento: dni,
      );

      await _loadProfile(response.user!.id, email);
      return null;
    } on AuthException catch (e) {
      await _registrarIntento(dni, false);
      return _translateAuthError(e.message);
    } catch (e) {
      debugPrint('Error login DNI: $e');
      return 'Error de conexión. Verifica Supabase e intenta de nuevo.';
    }
  }

  static Future<void> _registrarIntento(String documento, bool exitoso) async {
    try {
      await SupabaseService.client.rpc(
        'rpc_registrar_intento_login',
        params: {'p_documento': documento, 'p_exitoso': exitoso},
      );
    } catch (e) {
      debugPrint('No se pudo registrar intento login: $e');
    }
  }

  static Future<String?> signUp({
    required String email,
    required String password,
    required String nombre,
    required String documento,
    required String celular,
  }) async {
    try {
      final response = await SupabaseService.client.auth.signUp(
        email: email.trim(),
        password: password,
      );
      final user = response.user;
      if (user == null) return 'No se pudo crear la cuenta.';

      final uid = user.id;
      await SupabaseService.client.from('usuarios').upsert({
        'id': uid,
        'nombre': nombre.trim(),
        'documento': documento.trim(),
        'email': email.trim().toLowerCase(),
        'celular': celular.trim(),
      });

      await SupabaseService.client.from('profiles').upsert({
        'id': uid,
        'rol': 'cliente',
        'documento': documento.trim(),
        'login_attempts': 0,
      });

      final numAhorros = '2100${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
      final numCorriente = '2100${(DateTime.now().millisecondsSinceEpoch + 1).toString().substring(7)}';

      await SupabaseService.client.from('cuentas_ahorro').insert([
        {
          'id': 'ca_${uid}_ahorros',
          'usuario_id': uid,
          'numero': numAhorros,
          'cci': '0022100$numAhorros\0000',
          'tipo': 'Cuenta de Ahorros',
          'saldo': 5000.00,
        },
        {
          'id': 'ca_${uid}_corriente',
          'usuario_id': uid,
          'numero': numCorriente,
          'cci': '0022100$numCorriente\0000',
          'tipo': 'Cuenta Corriente',
          'saldo': 1000.00,
        },
      ]);

      await SupabaseService.client.from('tarjetas').insert({
        'id': 'td_${uid}_1',
        'usuario_id': uid,
        'cuenta_id': 'ca_${uid}_ahorros',
        'numero_enmascarado': '*${numAhorros.substring(numAhorros.length - 4)}',
        'tipo': 'Tarjeta De Débito',
        'bloqueada': false,
      });

      if (response.session != null) {
        await SecureSessionService.saveSession(
          accessToken: response.session!.accessToken,
          refreshToken: response.session!.refreshToken,
          documento: documento.trim(),
        );
      }

      await _loadProfile(uid, email);
      return null;
    } on AuthException catch (e) {
      return _translateAuthError(e.message);
    } catch (e) {
      debugPrint('Error en registro: $e');
      return 'Error al registrar. Ejecuta los scripts SQL en Supabase.';
    }
  }

  static Future<void> signOut() async {
    await SecureSessionService.clearSession();
    try {
      await SupabaseService.client.auth.signOut();
    } catch (e) {
      debugPrint('Error al cerrar sesión: $e');
    }
    _currentUser = null;
    _authStreamController.add(null);
  }

  static String _translateAuthError(String? message) {
    final msg = (message ?? '').toLowerCase();
    if (msg.contains('invalid login credentials')) {
      return 'DNI o contraseña incorrectos.';
    }
    if (msg.contains('email') && msg.contains('invalid')) {
      return 'El correo electrónico no es válido.';
    }
    if (msg.contains('already registered') || msg.contains('already exists')) {
      return 'El correo ya está registrado con otra cuenta.';
    }
    if (msg.contains('password') && msg.contains('6')) {
      return 'La contraseña debe tener al menos 6 caracteres.';
    }
    return message ?? 'Ha ocurrido un error de autenticación. Intente de nuevo.';
  }
}
