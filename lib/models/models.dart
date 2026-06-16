DateTime parseDbDate(dynamic value) {
  if (value == null) return DateTime.now();
  if (value is DateTime) return value;
  if (value is String) return DateTime.parse(value);
  throw ArgumentError('Fecha inválida: $value');
}

String toDbDate(DateTime date) => date.toIso8601String();

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
        'id': id,
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
        fecha: parseDbDate(map['fecha']),
        descripcion: map['descripcion'] ?? '',
        monto: (map['monto'] ?? 0).toDouble(),
        tipo: map['tipo'] ?? '',
      );

  Map<String, dynamic> toMap() => {
        'cuenta_id': cuentaId,
        'usuario_id': usuarioId,
        'fecha': toDbDate(fecha),
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
  final String? origenSolicitudId;
  final bool espejoCore;

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
    this.origenSolicitudId,
    this.espejoCore = false,
  });

  factory Credito.fromMap(Map<String, dynamic> map, String id) => Credito(
        id: id,
        usuarioId: map['usuario_id'] ?? '',
        descripcion: map['descripcion'] ?? '',
        montoOriginal: (map['monto_original'] ?? 0).toDouble(),
        saldoPendiente: (map['saldo_pendiente'] ?? 0).toDouble(),
        cuotaMensual: (map['cuota_mensual'] ?? 0).toDouble(),
        fechaInicio: parseDbDate(map['fecha_inicio']),
        plazoMeses: map['plazo_meses'] ?? 12,
        tasaInteres: (map['tasa_interes'] ?? 0).toDouble(),
        origenSolicitudId: map['origen_solicitud_id'] as String?,
        espejoCore: map['espejo_core'] == true,
      );

  Map<String, dynamic> toMap() => {
        'usuario_id': usuarioId,
        'descripcion': descripcion,
        'monto_original': montoOriginal,
        'saldo_pendiente': saldoPendiente,
        'cuota_mensual': cuotaMensual,
        'fecha_inicio': toDbDate(fechaInicio),
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
        fechaVencimiento: parseDbDate(map['fecha_vencimiento']),
        montoCuota: (map['monto_cuota'] ?? 0).toDouble(),
        capital: (map['capital'] ?? 0).toDouble(),
        interes: (map['interes'] ?? 0).toDouble(),
        saldoRestante: (map['saldo_restante'] ?? 0).toDouble(),
        pagada: map['pagada'] ?? false,
      );

  Map<String, dynamic> toMap() => {
        'credito_id': creditoId,
        'numero_cuota': numeroCuota,
        'fecha_vencimiento': toDbDate(fechaVencimiento),
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
        fecha: parseDbDate(map['fecha']),
      );

  Map<String, dynamic> toMap() => {
        'usuario_origen_id': usuarioOrigenId,
        'cuenta_origen_id': cuentaOrigenId,
        'cuenta_destino_id': cuentaDestinoId,
        'cci_destino': cciDestino,
        'monto': monto,
        'concepto': concepto,
        'fecha': toDbDate(fecha),
      };
}

class TarjetaDebito {
  final String id;
  final String usuarioId;
  final String cuentaId;
  final String numeroEnmascarado;
  final String tipo;
  bool bloqueada;

  TarjetaDebito({
    required this.id,
    required this.usuarioId,
    required this.cuentaId,
    required this.numeroEnmascarado,
    required this.tipo,
    this.bloqueada = false,
  });

  factory TarjetaDebito.fromMap(Map<String, dynamic> map, String id) => TarjetaDebito(
        id: id,
        usuarioId: map['usuario_id'] ?? '',
        cuentaId: map['cuenta_id'] ?? '',
        numeroEnmascarado: map['numero_enmascarado'] ?? '****',
        tipo: map['tipo'] ?? 'Tarjeta De Débito',
        bloqueada: map['bloqueada'] ?? false,
      );

  Map<String, dynamic> toMap() => {
        'usuario_id': usuarioId,
        'cuenta_id': cuentaId,
        'numero_enmascarado': numeroEnmascarado,
        'tipo': tipo,
        'bloqueada': bloqueada,
      };
}

class MovimientoTarjeta {
  final String id;
  final String tarjetaId;
  final String usuarioId;
  final DateTime fecha;
  final String comercio;
  final String descripcion;
  final double monto;

  MovimientoTarjeta({
    required this.id,
    required this.tarjetaId,
    required this.usuarioId,
    required this.fecha,
    required this.comercio,
    required this.descripcion,
    required this.monto,
  });
}

class Notificacion {
  final String id;
  final String usuarioId;
  final String titulo;
  final String mensaje;
  final DateTime fecha;
  final String tipo;
  bool leida;

  Notificacion({
    required this.id,
    required this.usuarioId,
    required this.titulo,
    required this.mensaje,
    required this.fecha,
    required this.tipo,
    this.leida = false,
  });

  factory Notificacion.fromMap(Map<String, dynamic> map, String id) => Notificacion(
        id: id,
        usuarioId: map['usuario_id'] ?? '',
        titulo: map['titulo'] ?? '',
        mensaje: map['mensaje'] ?? '',
        fecha: parseDbDate(map['fecha']),
        tipo: map['tipo'] ?? 'general',
        leida: map['leida'] ?? false,
      );

  Map<String, dynamic> toMap() => {
        'usuario_id': usuarioId,
        'titulo': titulo,
        'mensaje': mensaje,
        'fecha': toDbDate(fecha),
        'tipo': tipo,
        'leida': leida,
      };
}

class PagoServicio {
  final String id;
  final String usuarioId;
  final String cuentaId;
  final String servicio;
  final String referencia;
  final double monto;
  final DateTime fecha;

  PagoServicio({
    required this.id,
    required this.usuarioId,
    required this.cuentaId,
    required this.servicio,
    required this.referencia,
    required this.monto,
    required this.fecha,
  });
}
