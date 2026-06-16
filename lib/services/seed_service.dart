import 'package:flutter/foundation.dart';
import 'supabase_service.dart';

/// Siembra datos de demostración en Supabase si aún no existen.
class SeedService {
  static Future<void> seedIfNeeded() async {
    try {
      final existing = await SupabaseService.client
          .from('usuarios')
          .select('id')
          .eq('id', 'cliente_demo')
          .maybeSingle();
      if (existing != null) return;
    } catch (e) {
      debugPrint('Supabase no disponible para seed: $e');
      return;
    }

    try {
      await SupabaseService.client.from('usuarios').upsert([
        {
          'id': 'cliente_demo',
          'nombre': 'Juan Pérez Rodríguez',
          'documento': '72345678',
          'email': 'juan.perez@demo.com',
          'celular': '987654321',
        },
        {
          'id': 'cliente_destino',
          'nombre': 'María López García',
          'documento': '87654321',
          'email': 'maria.lopez@demo.com',
          'celular': '912345678',
        },
      ]);

      await SupabaseService.client.from('cuentas_ahorro').upsert([
        {
          'id': 'ca001',
          'usuario_id': 'cliente_demo',
          'numero': '2100234567',
          'cci': '00221002345670000',
          'tipo': 'Cuenta de Ahorros',
          'saldo': 15420.50,
        },
        {
          'id': 'ca002',
          'usuario_id': 'cliente_demo',
          'numero': '2100987654',
          'cci': '00221009876540000',
          'tipo': 'Cuenta Corriente',
          'saldo': 5280.75,
        },
        {
          'id': 'ca003',
          'usuario_id': 'cliente_destino',
          'numero': '2100111222',
          'cci': '00221001112220000',
          'tipo': 'Cuenta de Ahorros',
          'saldo': 8500.00,
        },
      ]);

      final now = DateTime.now();
      final movs = [
        {'cuenta_id': 'ca001', 'usuario_id': 'cliente_demo', 'dias': 2, 'desc': 'Depósito en efectivo', 'monto': 500.00, 'tipo': 'deposito'},
        {'cuenta_id': 'ca001', 'usuario_id': 'cliente_demo', 'dias': 5, 'desc': 'Pago servicios de agua', 'monto': -45.00, 'tipo': 'retiro'},
        {'cuenta_id': 'ca001', 'usuario_id': 'cliente_demo', 'dias': 7, 'desc': 'Transferencia recibida', 'monto': 1200.00, 'tipo': 'transferencia'},
      ];

      await SupabaseService.client.from('movimientos').insert(
        movs.map((m) => {
          'cuenta_id': m['cuenta_id'],
          'usuario_id': m['usuario_id'],
          'fecha': now.subtract(Duration(days: m['dias'] as int)).toIso8601String(),
          'descripcion': m['desc'],
          'monto': m['monto'],
          'tipo': m['tipo'],
        }).toList(),
      );

      await SupabaseService.client.from('creditos').upsert([
        {
          'id': 'cr001',
          'usuario_id': 'cliente_demo',
          'descripcion': 'Préstamo Personal',
          'monto_original': 25000.00,
          'saldo_pendiente': 18750.00,
          'cuota_mensual': 555.56,
          'fecha_inicio': DateTime(2024, 1, 15).toIso8601String(),
          'plazo_meses': 36,
          'tasa_interes': 18.5,
        },
        {
          'id': 'cr002',
          'usuario_id': 'cliente_demo',
          'descripcion': 'Préstamo Vehicular',
          'monto_original': 35000.00,
          'saldo_pendiente': 28400.00,
          'cuota_mensual': 778.89,
          'fecha_inicio': DateTime(2024, 6, 1).toIso8601String(),
          'plazo_meses': 48,
          'tasa_interes': 14.0,
        },
      ]);
    } catch (e) {
      debugPrint('Error sembrando datos demo: $e');
    }
  }
}
