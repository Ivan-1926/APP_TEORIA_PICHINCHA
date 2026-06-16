import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'services/seed_service.dart';
import 'services/supabase_service.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await SupabaseService.initialize();
  } catch (e) {
    debugPrint("Supabase init failed: $e");
  }

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));

  try {
    await SeedService.seedIfNeeded();
  } catch (e) {
    debugPrint("Seeding failed: $e. Falling back to local offline mode.");
  }

  runApp(const AppPichincha());
}
