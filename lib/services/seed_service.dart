import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Siembra datos de demostración en Firestore si aún no existen.
class SeedService {
  static final _db = FirebaseFirestore.instance;

  static Future<void> seedIfNeeded() async {
    try {
      final doc = await _db.collection('usuarios').doc('cliente_demo').get();
      if (doc.exists) return; // Ya sembrado
    } catch (e) {
      debugPrint("Firestore is offline or inaccessible during seeding check. Fallback active.");
      return;
    }

    final batch = _db.batch();

    // ── Usuarios ───────────────────────────────────────────────────
    batch.set(_db.collection('usuarios').doc('cliente_demo'), {
      'nombre': 'Juan Pérez Rodríguez',
      'documento': '72345678',
      'email': 'juan.perez@demo.com',
      'celular': '987654321',
    });
    batch.set(_db.collection('usuarios').doc('cliente_destino'), {
      'nombre': 'María López García',
      'documento': '87654321',
      'email': 'maria.lopez@demo.com',
      'celular': '912345678',
    });
    await batch.commit();

    // ── Cuentas de Ahorro ──────────────────────────────────────────
    final b2 = _db.batch();
    b2.set(_db.collection('cuentas_ahorro').doc('ca001'), {
      'usuario_id': 'cliente_demo',
      'numero': '2100234567',
      'cci': '00221002345670000',
      'tipo': 'Cuenta de Ahorros',
      'saldo': 15420.50,
    });
    b2.set(_db.collection('cuentas_ahorro').doc('ca002'), {
      'usuario_id': 'cliente_demo',
      'numero': '2100987654',
      'cci': '00221009876540000',
      'tipo': 'Cuenta Corriente',
      'saldo': 5280.75,
    });
    b2.set(_db.collection('cuentas_ahorro').doc('ca003'), {
      'usuario_id': 'cliente_destino',
      'numero': '2100111222',
      'cci': '00221001112220000',
      'tipo': 'Cuenta de Ahorros',
      'saldo': 8500.00,
    });
    await b2.commit();

    // ── Movimientos ────────────────────────────────────────────────
    final now = DateTime.now();
    final movs = [
      {'cuenta_id': 'ca001', 'usuario_id': 'cliente_demo', 'dias': 2,  'desc': 'Depósito en efectivo',       'monto': 500.00,   'tipo': 'deposito'},
      {'cuenta_id': 'ca001', 'usuario_id': 'cliente_demo', 'dias': 5,  'desc': 'Pago servicios de agua',     'monto': -45.00,   'tipo': 'retiro'},
      {'cuenta_id': 'ca001', 'usuario_id': 'cliente_demo', 'dias': 7,  'desc': 'Transferencia recibida',     'monto': 1200.00,  'tipo': 'transferencia'},
      {'cuenta_id': 'ca001', 'usuario_id': 'cliente_demo', 'dias': 12, 'desc': 'Pago servicio eléctrico',   'monto': -120.00,  'tipo': 'retiro'},
      {'cuenta_id': 'ca001', 'usuario_id': 'cliente_demo', 'dias': 18, 'desc': 'Depósito nómina',            'monto': 2500.00,  'tipo': 'deposito'},
      {'cuenta_id': 'ca001', 'usuario_id': 'cliente_demo', 'dias': 25, 'desc': 'Pago internet y cable',      'monto': -89.90,   'tipo': 'retiro'},
      {'cuenta_id': 'ca002', 'usuario_id': 'cliente_demo', 'dias': 3,  'desc': 'Depósito en efectivo',       'monto': 300.00,   'tipo': 'deposito'},
      {'cuenta_id': 'ca002', 'usuario_id': 'cliente_demo', 'dias': 9,  'desc': 'Retiro cajero automático',   'monto': -200.00,  'tipo': 'retiro'},
      {'cuenta_id': 'ca002', 'usuario_id': 'cliente_demo', 'dias': 20, 'desc': 'Compra en supermercado',     'monto': -156.80,  'tipo': 'retiro'},
    ];

    final b3 = _db.batch();
    for (final m in movs) {
      final ref = _db.collection('movimientos').doc();
      b3.set(ref, {
        'cuenta_id': m['cuenta_id'],
        'usuario_id': m['usuario_id'],
        'fecha': Timestamp.fromDate(now.subtract(Duration(days: m['dias'] as int))),
        'descripcion': m['desc'],
        'monto': m['monto'],
        'tipo': m['tipo'],
      });
    }
    await b3.commit();

    // ── Créditos ───────────────────────────────────────────────────
    final b4 = _db.batch();
    b4.set(_db.collection('creditos').doc('cr001'), {
      'usuario_id': 'cliente_demo',
      'descripcion': 'Préstamo Personal',
      'monto_original': 25000.00,
      'saldo_pendiente': 18750.00,
      'cuota_mensual': 555.56,
      'fecha_inicio': Timestamp.fromDate(DateTime(2024, 1, 15)),
      'plazo_meses': 36,
      'tasa_interes': 18.5,
    });
    b4.set(_db.collection('creditos').doc('cr002'), {
      'usuario_id': 'cliente_demo',
      'descripcion': 'Préstamo Vehicular',
      'monto_original': 35000.00,
      'saldo_pendiente': 28400.00,
      'cuota_mensual': 778.89,
      'fecha_inicio': Timestamp.fromDate(DateTime(2024, 6, 1)),
      'plazo_meses': 48,
      'tasa_interes': 14.0,
    });
    await b4.commit();

    // ── Cuotas cr001 (36 cuotas, 15 pagadas) ──────────────────────
    await _seedCuotas('cr001', 25000.00, 18.5 / 100 / 12, 36,
        DateTime(2024, 2, 15), 15);
    // ── Cuotas cr002 (48 cuotas, 8 pagadas) ───────────────────────
    await _seedCuotas('cr002', 35000.00, 14.0 / 100 / 12, 48,
        DateTime(2024, 7, 1), 8);
  }

  static Future<void> _seedCuotas(
    String creditoId,
    double monto,
    double tasaMensual,
    int plazo,
    DateTime fechaInicio,
    int pagadas,
  ) async {
    // Fórmula cuota fija: M * (r*(1+r)^n) / ((1+r)^n - 1)
    final r = tasaMensual;
    final n = plazo;
    final cuotaFija = monto * (r * _pow(1 + r, n)) / (_pow(1 + r, n) - 1);

    double saldo = monto;
    const batchSize = 20;
    List<Map<String, dynamic>> cuotas = [];

    for (int i = 1; i <= plazo; i++) {
      final interes = saldo * r;
      final capital = cuotaFija - interes;
      saldo -= capital;
      cuotas.add({
        'credito_id': creditoId,
        'numero_cuota': i,
        'fecha_vencimiento':
            Timestamp.fromDate(DateTime(fechaInicio.year, fechaInicio.month + i - 1, fechaInicio.day)),
        'monto_cuota': double.parse(cuotaFija.toStringAsFixed(2)),
        'capital': double.parse(capital.toStringAsFixed(2)),
        'interes': double.parse(interes.toStringAsFixed(2)),
        'saldo_restante': double.parse(saldo < 0 ? '0' : saldo.toStringAsFixed(2)),
        'pagada': i <= pagadas,
      });
    }

    for (int start = 0; start < cuotas.length; start += batchSize) {
      final b = _db.batch();
      final end = (start + batchSize).clamp(0, cuotas.length);
      for (final c in cuotas.sublist(start, end)) {
        b.set(_db.collection('cuotas').doc(), c);
      }
      await b.commit();
    }
  }

  static double _pow(double base, int exp) {
    double result = 1;
    for (int i = 0; i < exp; i++) result *= base;
    return result;
  }
}
