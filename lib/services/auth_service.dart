import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';
import 'bank_data_service.dart';
import 'supabase_service.dart';

class AuthService {
  static Usuario? _currentUser;
  static bool _isOfflineMode = false;
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
      if (_isOfflineMode) return;
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
      final nuevo = Usuario(
        id: uid,
        nombre: 'Usuario Nuevo',
        documento: '00000000',
        email: email ?? '',
        celular: '',
      );
      _currentUser = nuevo;
      _authStreamController.add(nuevo);
    } catch (e) {
      debugPrint('Error cargando perfil: $e');
    }
  }

  static Usuario? get currentUser => _currentUser;
  static bool get isOfflineMode => _isOfflineMode;

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

      _isOfflineMode = false;
      await _loadProfile(uid, email);
      return null;
    } on AuthException catch (e) {
      return _translateAuthError(e.message);
    } catch (e) {
      debugPrint('Error en registro: $e');
      return _signUpOffline(email, password, nombre, documento, celular);
    }
  }

  static Future<String?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await SupabaseService.client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
      final user = response.user;
      if (user == null) return 'Correo o contraseña incorrectos.';
      _isOfflineMode = false;
      await _loadProfile(user.id, user.email);
      return null;
    } on AuthException catch (e) {
      return _translateAuthError(e.message);
    } catch (e) {
      debugPrint('Error en login: $e');
      return _signInOffline(email, password);
    }
  }

  static void enterDemoMode() {
    _isOfflineMode = true;
    final demoUser = Usuario(
      id: BankDataService.demoUserId,
      nombre: 'Juan Pérez Rodríguez',
      documento: '72345678',
      email: 'juan.perez@demo.com',
      celular: '987654321',
    );
    _currentUser = demoUser;
    _authStreamController.add(demoUser);
  }

  static Future<void> signOut() async {
    if (_isOfflineMode) {
      _isOfflineMode = false;
      _currentUser = null;
      _authStreamController.add(null);
      return;
    }
    try {
      await SupabaseService.client.auth.signOut();
    } catch (e) {
      debugPrint('Error al cerrar sesión: $e');
    }
    _currentUser = null;
    _authStreamController.add(null);
  }

  static Future<String?> _signInOffline(String email, String password) async {
    enterDemoMode();
    return null;
  }

  static Future<String?> _signUpOffline(
    String email,
    String password,
    String nombre,
    String documento,
    String celular,
  ) async {
    _isOfflineMode = true;
    final nuevo = Usuario(
      id: 'cliente_demo_creado',
      nombre: nombre,
      documento: documento,
      email: email,
      celular: celular,
    );
    _currentUser = nuevo;
    _authStreamController.add(nuevo);
    return null;
  }

  static String _translateAuthError(String? message) {
    final msg = (message ?? '').toLowerCase();
    if (msg.contains('invalid login credentials')) {
      return 'Correo o contraseña incorrectos.';
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
