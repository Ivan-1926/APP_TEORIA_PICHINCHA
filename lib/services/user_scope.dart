import 'auth_service.dart';

/// ID del usuario autenticado (Supabase Auth).
String get activeUserId {
  final id = AuthService.currentUser?.id;
  if (id == null || id.isEmpty) {
    throw StateError('No hay sesión activa. Inicia sesión con tu DNI.');
  }
  return id;
}

String get activeDocumento {
  final doc = AuthService.currentUser?.documento;
  if (doc == null || doc.isEmpty) return '00000000';
  return doc;
}
