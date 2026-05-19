import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/models.dart';
import 'firestore_service.dart';

class AuthService {
  static final fb.FirebaseAuth _auth = fb.FirebaseAuth.instance;
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static Usuario? _currentUser;
  static bool _isOfflineMode = false;

  static final StreamController<Usuario?> _authStreamController =
      StreamController<Usuario?>.broadcast();

  /// Stream reactivo que emite el estado del usuario autenticado (o null si no lo está)
  static Stream<Usuario?> get onAuthStateChanged {
    // Escuchar los cambios reales de Firebase Auth
    _auth.authStateChanges().listen((fbUser) async {
      if (fbUser == null) {
        if (!_isOfflineMode) {
          _currentUser = null;
          _authStreamController.add(null);
        }
      } else {
        _isOfflineMode = false;
        try {
          final usuario = await FirestoreService.getUsuario(fbUser.uid);
          if (usuario != null) {
            _currentUser = usuario;
            _authStreamController.add(usuario);
          } else {
            // Si el registro de Firestore no existe pero sí en Auth, crear uno genérico
            final nuevo = Usuario(
              id: fbUser.uid,
              nombre: fbUser.displayName ?? 'Usuario Nuevo',
              documento: '00000000',
              email: fbUser.email ?? '',
              celular: '',
            );
            _currentUser = nuevo;
            _authStreamController.add(nuevo);
          }
        } catch (e) {
          debugPrint("Error fetching authenticated user profile: $e. Falling back.");
        }
      }
    });

    return _authStreamController.stream;
  }

  /// Obtener el usuario actual
  static Usuario? get currentUser => _currentUser;

  /// Validar si está en modo offline simulado
  static bool get isOfflineMode => _isOfflineMode;

  /// Registrar un nuevo usuario en Firebase Auth y Firestore
  static Future<String?> signUp({
    required String email,
    required String password,
    required String nombre,
    required String documento,
    required String celular,
  }) async {
    try {
      // 1. Crear el usuario en Firebase Auth
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final uid = credential.user!.uid;

      // 2. Guardar el perfil detallado del usuario en Firestore
      await _db.collection('usuarios').doc(uid).set({
        'nombre': nombre.trim(),
        'documento': documento.trim(),
        'email': email.trim().toLowerCase(),
        'celular': celular.trim(),
      });

      // 3. Crear las cuentas de ahorro demo iniciales en Firestore para el nuevo usuario
      final batch = _db.batch();
      
      // Cuenta de Ahorro
      final numAhorros = '2100${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
      batch.set(_db.collection('cuentas_ahorro').doc('ca_$uid\_ahorros'), {
        'usuario_id': uid,
        'numero': numAhorros,
        'cci': '0022100$numAhorros\0000',
        'tipo': 'Cuenta de Ahorros',
        'saldo': 5000.00, // Regalo de bienvenida simulado
      });

      // Cuenta Corriente
      final numCorriente = '2100${(DateTime.now().millisecondsSinceEpoch + 1).toString().substring(7)}';
      batch.set(_db.collection('cuentas_ahorro').doc('ca_$uid\_corriente'), {
        'usuario_id': uid,
        'numero': numCorriente,
        'cci': '0022100$numCorriente\0000',
        'tipo': 'Cuenta Corriente',
        'saldo': 1000.00,
      });

      await batch.commit();

      // 4. Actualizar el displayName de Firebase Auth
      await credential.user!.updateDisplayName(nombre.trim());

      _isOfflineMode = false;
      return null; // Éxito (sin error)
    } on fb.FirebaseAuthException catch (e) {
      debugPrint("FirebaseAuthException during signup: ${e.code} - ${e.message}");
      
      // Fallback offline si Firebase tiene problemas
      if (e.code == 'network-request-failed' || e.code == 'api-key-not-valid') {
        return _signUpOffline(email, password, nombre, documento, celular);
      }
      
      return _translateAuthError(e.code);
    } catch (e) {
      debugPrint("General error during signup: $e");
      return _signUpOffline(email, password, nombre, documento, celular);
    }
  }

  /// Iniciar sesión
  static Future<String?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final uid = credential.user!.uid;
      final usuario = await FirestoreService.getUsuario(uid);
      if (usuario != null) {
        _currentUser = usuario;
        _isOfflineMode = false;
        _authStreamController.add(usuario);
      }
      return null;
    } on fb.FirebaseAuthException catch (e) {
      debugPrint("FirebaseAuthException during signin: ${e.code}");

      if (e.code == 'network-request-failed' || e.code == 'api-key-not-valid') {
        return _signInOffline(email, password);
      }

      return _translateAuthError(e.code);
    } catch (e) {
      debugPrint("General error during signin: $e");
      return _signInOffline(email, password);
    }
  }

  /// Iniciar sesión en modo Demo Offline (instantáneo y resiliencia total)
  static void enterDemoMode() {
    _isOfflineMode = true;
    final demoUser = Usuario(
      id: 'cliente_demo',
      nombre: 'Juan Pérez Rodríguez',
      documento: '72345678',
      email: 'juan.perez@demo.com',
      celular: '987654321',
    );
    _currentUser = demoUser;
    _authStreamController.add(demoUser);
  }

  /// Cerrar Sesión
  static Future<void> signOut() async {
    if (_isOfflineMode) {
      _isOfflineMode = false;
      _currentUser = null;
      _authStreamController.add(null);
      return;
    }

    try {
      await _auth.signOut();
    } catch (e) {
      debugPrint("Auth signout error: $e");
    }

    _currentUser = null;
    _authStreamController.add(null);
  }

  // ─── Métodos Auxiliares de Autenticación Offline ────────────────

  static Future<String?> _signInOffline(String email, String password) async {
    // Si inicia sesión offline, simulamos al cliente demo por defecto
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
    // Si se registra offline, creamos el usuario simulado
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

  /// Traducir códigos de error de Firebase Auth al español
  static String _translateAuthError(String code) {
    switch (code) {
      case 'invalid-email':
        return 'El correo electrónico no es válido.';
      case 'user-disabled':
        return 'Este usuario ha sido deshabilitado.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Correo o contraseña incorrectos.';
      case 'email-already-in-use':
        return 'El correo ya está registrado con otra cuenta.';
      case 'weak-password':
        return 'La contraseña debe tener al menos 6 caracteres.';
      case 'channel-error':
        return 'Complete todos los campos obligatorios.';
      default:
        return 'Ha ocurrido un error inesperado de autenticación. Intente de nuevo.';
    }
  }
}
