import 'package:cloud_firestore/cloud_firestore.dart';

class Usuario {
  final String id;
  final String nombre;
  final String documento;
  final String email;
  String celular;

  Usuario({
    required this.id,
    required this.nombre,
    required this.documento,
    required this.email,
    required this.celular,
  });

  factory Usuario.fromMap(Map<String, dynamic> map, String id) => Usuario(
        id: id,
        nombre: map['nombre'] ?? '',
        documento: map['documento'] ?? '',
        email: map['email'] ?? '',
        celular: map['celular'] ?? '',
      );

  Map<String, dynamic> toMap() => {
        'nombre': nombre,
        'documento': documento,
        'email': email,
        'celular': celular,
      };
}

class CuentaAhorro {
  final String id;
  final String usuarioId;
  final String numero;
  final String cci;
  final String tipo;
  double saldo;

  CuentaAhorro({
    required this.id,
    required this.usuarioId,
    required this.numero,
    required this.cci,
    required this.tipo,
    required this.saldo,
  });

  factory CuentaAhorro.fromMap(Map<String, dynamic> map, String id) =>
      CuentaAhorro(
        id: id,
        usuarioId: map['usuario_id'] ?? '',
        numero: map['numero'] ?? '',
        cci: map['cci'] ?? '',
        tipo: map['tipo'] ?? 'Cuenta de Ahorros',
        saldo: (map['saldo'] ?? 0).toDouble(),
      );

  Map<String, dynamic> toMap() => {
        'usuario_id': usuarioId,
        'numero': numero,
        'cci': cci,
        'tipo': tipo,
        'saldo': saldo,
      };
}

class Movimiento {
  final String id;
  final String cuentaId;
  final String usuarioId;
  final DateTime fecha;
  final String descripcion;
  final double monto;
  final String tipo;

  Movimiento({
    required this.id,
    required this.cuentaId,
    required this.usuarioId,
    required this.fecha,
    required this.descripcion,
    required this.monto,
    required this.tipo,
  });

  bool get esCredito => monto > 0;

  factory Movimiento.fromMap(Map<String, dynamic> map, String id) => Movimiento(
        id: id,
        cuentaId: map['cuenta_id'] ?? '',
        usuarioId: map['usuario_id'] ?? '',
        fecha: (map['fecha'] as Timestamp).toDate(),
        descripcion: map['descripcion'] ?? '',
        monto: (map['monto'] ?? 0).toDouble(),
        tipo: map['tipo'] ?? '',
      );

  Map<String, dynamic> toMap() => {
        'cuenta_id': cuentaId,
        'usuario_id': usuarioId,
        'fecha': Timestamp.fromDate(fecha),
        'descripcion': descripcion,
        'monto': monto,
        'tipo': tipo,
      };
}

class Credito {
  final String id;
  final String usuarioId;
  final String descripcion;
  final double montoOriginal;
  final double saldoPendiente;
  final double cuotaMensual;
  final DateTime fechaInicio;
  final int plazoMeses;
  final double tasaInteres;

  Credito({
    required this.id,
    required this.usuarioId,
    required this.descripcion,
    required this.montoOriginal,
    required this.saldoPendiente,
    required this.cuotaMensual,
    required this.fechaInicio,
    required this.plazoMeses,
    required this.tasaInteres,
  });

  factory Credito.fromMap(Map<String, dynamic> map, String id) => Credito(
        id: id,
        usuarioId: map['usuario_id'] ?? '',
        descripcion: map['descripcion'] ?? '',
        montoOriginal: (map['monto_original'] ?? 0).toDouble(),
        saldoPendiente: (map['saldo_pendiente'] ?? 0).toDouble(),
        cuotaMensual: (map['cuota_mensual'] ?? 0).toDouble(),
        fechaInicio: (map['fecha_inicio'] as Timestamp).toDate(),
        plazoMeses: map['plazo_meses'] ?? 12,
        tasaInteres: (map['tasa_interes'] ?? 0).toDouble(),
      );

  Map<String, dynamic> toMap() => {
        'usuario_id': usuarioId,
        'descripcion': descripcion,
        'monto_original': montoOriginal,
        'saldo_pendiente': saldoPendiente,
        'cuota_mensual': cuotaMensual,
        'fecha_inicio': Timestamp.fromDate(fechaInicio),
        'plazo_meses': plazoMeses,
        'tasa_interes': tasaInteres,
      };
}

class Cuota {
  final String id;
  final String creditoId;
  final int numeroCuota;
  final DateTime fechaVencimiento;
  final double montoCuota;
  final double capital;
  final double interes;
  final double saldoRestante;
  final bool pagada;

  Cuota({
    required this.id,
    required this.creditoId,
    required this.numeroCuota,
    required this.fechaVencimiento,
    required this.montoCuota,
    required this.capital,
    required this.interes,
    required this.saldoRestante,
    required this.pagada,
  });

  factory Cuota.fromMap(Map<String, dynamic> map, String id) => Cuota(
        id: id,
        creditoId: map['credito_id'] ?? '',
        numeroCuota: map['numero_cuota'] ?? 0,
        fechaVencimiento: (map['fecha_vencimiento'] as Timestamp).toDate(),
        montoCuota: (map['monto_cuota'] ?? 0).toDouble(),
        capital: (map['capital'] ?? 0).toDouble(),
        interes: (map['interes'] ?? 0).toDouble(),
        saldoRestante: (map['saldo_restante'] ?? 0).toDouble(),
        pagada: map['pagada'] ?? false,
      );

  Map<String, dynamic> toMap() => {
        'credito_id': creditoId,
        'numero_cuota': numeroCuota,
        'fecha_vencimiento': Timestamp.fromDate(fechaVencimiento),
        'monto_cuota': montoCuota,
        'capital': capital,
        'interes': interes,
        'saldo_restante': saldoRestante,
        'pagada': pagada,
      };
}

class Transferencia {
  final String id;
  final String usuarioOrigenId;
  final String cuentaOrigenId;
  final String cuentaDestinoId;
  final String cciDestino;
  final double monto;
  final String concepto;
  final DateTime fecha;

  Transferencia({
    required this.id,
    required this.usuarioOrigenId,
    required this.cuentaOrigenId,
    required this.cuentaDestinoId,
    required this.cciDestino,
    required this.monto,
    required this.concepto,
    required this.fecha,
  });

  factory Transferencia.fromMap(Map<String, dynamic> map, String id) =>
      Transferencia(
        id: id,
        usuarioOrigenId: map['usuario_origen_id'] ?? '',
        cuentaOrigenId: map['cuenta_origen_id'] ?? '',
        cuentaDestinoId: map['cuenta_destino_id'] ?? '',
        cciDestino: map['cci_destino'] ?? '',
        monto: (map['monto'] ?? 0).toDouble(),
        concepto: map['concepto'] ?? '',
        fecha: (map['fecha'] as Timestamp).toDate(),
      );

  Map<String, dynamic> toMap() => {
        'usuario_origen_id': usuarioOrigenId,
        'cuenta_origen_id': cuentaOrigenId,
        'cuenta_destino_id': cuentaDestinoId,
        'cci_destino': cciDestino,
        'monto': monto,
        'concepto': concepto,
        'fecha': Timestamp.fromDate(fecha),
      };
}
