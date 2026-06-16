import 'supabase_service.dart';

/// Puente FVentas → tablas espejo cr_* → app cliente (rúbrica Criterio 1).
class SyncIntegrationService {
  /// Procesa eventos pendientes en sync_outbox para el DNI del cliente autenticado.
  static Future<int> procesarCreditosPendientes(String documento) async {
    final result = await SupabaseService.client.rpc(
      'rpc_procesar_sync_outbox',
      params: {'p_documento': documento.trim()},
    );
    if (result is int) return result;
    if (result is num) return result.toInt();
    return 0;
  }

  static Future<List<Map<String, dynamic>>> getSyncLogReciente({int limit = 10}) async {
    final rows = await SupabaseService.client
        .from('sync_log')
        .select()
        .order('created_at', ascending: false)
        .limit(limit);
    return (rows as List).map((r) => Map<String, dynamic>.from(r)).toList();
  }
}
