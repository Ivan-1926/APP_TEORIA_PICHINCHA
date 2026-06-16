import 'auth_service.dart';
import 'bank_data_service.dart';

/// ID del usuario autenticado o demo offline.
String get activeUserId =>
    AuthService.currentUser?.id ?? BankDataService.demoUserId;
