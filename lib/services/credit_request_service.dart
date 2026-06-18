import 'dart:math' as math;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

class SolicitudCreditoResult {
  final String id;
  final String expediente;
  final String status;

  const SolicitudCreditoResult({
    required this.id,
    required this.expediente,
    required this.status,
  });

  factory SolicitudCreditoResult.fromMap(Map<String, dynamic> map) {
    return SolicitudCreditoResult(
      id: map['id']?.toString() ?? '',
      expediente: map['expediente']?.toString() ?? '',
      status: map['status']?.toString() ?? 'enviado',
    );
  }
}

/// Registra solicitudes de crédito originadas por el cliente (canal app).
class CreditRequestService {
  static const _teaDefault = 18.0;

  static double calcularCuotaMensual({
    required double monto,
    required int plazoMeses,
    double teaPercent = _teaDefault,
  }) {
    if (monto <= 0 || plazoMeses <= 0) return 0;
    final tem = math.pow(1 + teaPercent / 100, 1 / 12).toDouble() - 1;
    if (tem <= 0) return monto / plazoMeses;
    final factor = math.pow(1 + tem, plazoMeses).toDouble();
    return monto * (tem * factor) / (factor - 1);
  }

  /// Inserta en `fv_credit_applications` vía RPC (security definer).
  static Future<SolicitudCreditoResult> registrarSolicitud({
    required String documento,
    required String nombre,
    required String producto,
    required double monto,
    required int plazoMeses,
    required String destino,
    String? garantia,
  }) async {
    final res = await SupabaseService.client.rpc(
      'rpc_registrar_solicitud_cliente',
      params: {
        'p_documento': documento.trim(),
        'p_nombre': nombre.trim(),
        'p_producto': producto.trim(),
        'p_monto': monto,
        'p_plazo_meses': plazoMeses,
        'p_destino': destino.trim(),
        'p_garantia': garantia?.trim(),
      },
    );

    if (res is Map) {
      return SolicitudCreditoResult.fromMap(Map<String, dynamic>.from(res));
    }
    if (res is List && res.isNotEmpty) {
      return SolicitudCreditoResult.fromMap(
        Map<String, dynamic>.from(res.first as Map),
      );
    }
    throw Exception('No se pudo registrar la solicitud.');
  }

  /// Fallback directo si la RPC aún no está en Supabase.
  static Future<SolicitudCreditoResult> registrarSolicitudDirecta({
    required String documento,
    required String nombre,
    required String producto,
    required double monto,
    required int plazoMeses,
    required String destino,
    String? garantia,
  }) async {
    final cuota = calcularCuotaMensual(monto: monto, plazoMeses: plazoMeses);
    final purpose = StringBuffer('[Canal: cliente] $producto — $destino');
    if (garantia != null && garantia.isNotEmpty) {
      purpose.write(' | Garantía: $garantia');
    }

    final row = await SupabaseService.client
        .from('fv_credit_applications')
        .insert({
          'client_name': nombre,
          'client_dni': documento,
          'amount': monto,
          'term_months': plazoMeses,
          'tea': _teaDefault,
          'monthly_payment': double.parse(cuota.toStringAsFixed(2)),
          'purpose': purpose.toString(),
          'status': 'enviado',
          'submitted_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        })
        .select('id, status')
        .single();

    final id = row['id']?.toString() ?? '';
    return SolicitudCreditoResult(
      id: id,
      expediente: 'EXP-${id.replaceAll('-', '').substring(0, 8).toUpperCase()}',
      status: row['status']?.toString() ?? 'enviado',
    );
  }

  static Future<SolicitudCreditoResult> enviar({
    required String documento,
    required String nombre,
    required String producto,
    required double monto,
    required int plazoMeses,
    required String destino,
    String? garantia,
  }) async {
    try {
      return await registrarSolicitud(
        documento: documento,
        nombre: nombre,
        producto: producto,
        monto: monto,
        plazoMeses: plazoMeses,
        destino: destino,
        garantia: garantia,
      );
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST202' || e.message.contains('rpc_registrar_solicitud_cliente')) {
        return registrarSolicitudDirecta(
          documento: documento,
          nombre: nombre,
          producto: producto,
          monto: monto,
          plazoMeses: plazoMeses,
          destino: destino,
          garantia: garantia,
        );
      }
      rethrow;
    }
  }

  static Future<List<Map<String, dynamic>>> misSolicitudes(String documento) async {
    try {
      final res = await SupabaseService.client.rpc(
        'rpc_mis_solicitudes_cliente',
        params: {'p_documento': documento.trim()},
      );
      if (res is List) {
        return res.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
    } catch (_) {}

    final rows = await SupabaseService.client
        .from('fv_credit_applications')
        .select()
        .eq('client_dni', documento.trim())
        .order('submitted_at', ascending: false);
    return (rows as List).map((e) => Map<String, dynamic>.from(e)).toList();
  }
}
