import 'package:flutter/foundation.dart';
import '../models/models.dart';
import 'supabase_service.dart';

class BankDataService {
  static const String demoUserId = 'cliente_demo';

  static bool _useLocalFallback = false;
  static final Map<String, Usuario> _mockUsuario = {};
  static final List<CuentaAhorro> _mockCuentas = [];
  static final List<Movimiento> _mockMovimientos = [];
  static final List<Credito> _mockCreditos = [];
  static final List<Cuota> _mockCuotas = [];
  static final List<Transferencia> _mockTransferencias = [];
  static final List<TarjetaDebito> _mockTarjetas = [];
  static final List<MovimientoTarjeta> _mockMovimientosTarjeta = [];
  static final List<Notificacion> _mockNotificaciones = [];
  static final List<PagoServicio> _mockPagos = [];

  static void _initMockData() {
    if (_mockUsuario.isNotEmpty) return;
    _mockUsuario['cliente_demo'] = Usuario(
      id: 'cliente_demo',
      nombre: 'Juan Pérez Rodríguez',
      documento: '72345678',
      email: 'juan.perez@demo.com',
      celular: '987654321',
    );
    _mockUsuario['cliente_destino'] = Usuario(
      id: 'cliente_destino',
      nombre: 'María López García',
      documento: '87654321',
      email: 'maria.lopez@demo.com',
      celular: '912345678',
    );

    _mockCuentas.addAll([
      CuentaAhorro(
        id: 'ca001',
        usuarioId: 'cliente_demo',
        numero: '2100234567',
        cci: '00221002345670000',
        tipo: 'Cuenta de Ahorros',
        saldo: 15420.50,
      ),
      CuentaAhorro(
        id: 'ca002',
        usuarioId: 'cliente_demo',
        numero: '2100987654',
        cci: '00221009876540000',
        tipo: 'Cuenta Corriente',
        saldo: 5280.75,
      ),
      CuentaAhorro(
        id: 'ca003',
        usuarioId: 'cliente_destino',
        numero: '2100111222',
        cci: '00221001112220000',
        tipo: 'Cuenta de Ahorros',
        saldo: 8500.00,
      ),
    ]);

    final now = DateTime.now();
    _mockMovimientos.addAll([
      Movimiento(id: 'm1', cuentaId: 'ca001', usuarioId: 'cliente_demo', fecha: now.subtract(const Duration(days: 2)), descripcion: 'Depósito en efectivo', monto: 500.00, tipo: 'deposito'),
      Movimiento(id: 'm2', cuentaId: 'ca001', usuarioId: 'cliente_demo', fecha: now.subtract(const Duration(days: 5)), descripcion: 'Pago servicios de agua', monto: -45.00, tipo: 'retiro'),
      Movimiento(id: 'm3', cuentaId: 'ca001', usuarioId: 'cliente_demo', fecha: now.subtract(const Duration(days: 7)), descripcion: 'Transferencia recibida', monto: 1200.00, tipo: 'transferencia'),
      Movimiento(id: 'm4', cuentaId: 'ca001', usuarioId: 'cliente_demo', fecha: now.subtract(const Duration(days: 12)), descripcion: 'Pago servicio eléctrico', monto: -120.00, tipo: 'retiro'),
      Movimiento(id: 'm5', cuentaId: 'ca001', usuarioId: 'cliente_demo', fecha: now.subtract(const Duration(days: 18)), descripcion: 'Depósito nómina', monto: 2500.00, tipo: 'deposito'),
      Movimiento(id: 'm6', cuentaId: 'ca001', usuarioId: 'cliente_demo', fecha: now.subtract(const Duration(days: 25)), descripcion: 'Pago internet y cable', monto: -89.90, tipo: 'retiro'),
      Movimiento(id: 'm7', cuentaId: 'ca002', usuarioId: 'cliente_demo', fecha: now.subtract(const Duration(days: 3)), descripcion: 'Depósito en efectivo', monto: 300.00, tipo: 'deposito'),
      Movimiento(id: 'm8', cuentaId: 'ca002', usuarioId: 'cliente_demo', fecha: now.subtract(const Duration(days: 9)), descripcion: 'Retiro cajero automático', monto: -200.00, tipo: 'retiro'),
      Movimiento(id: 'm9', cuentaId: 'ca002', usuarioId: 'cliente_demo', fecha: now.subtract(const Duration(days: 20)), descripcion: 'Compra en supermercado', monto: -156.80, tipo: 'retiro'),
    ]);

    _mockCreditos.addAll([
      Credito(
        id: 'cr001',
        usuarioId: 'cliente_demo',
        descripcion: 'Préstamo Personal',
        montoOriginal: 25000.00,
        saldoPendiente: 18750.00,
        cuotaMensual: 555.56,
        fechaInicio: DateTime(2024, 1, 15),
        plazoMeses: 36,
        tasaInteres: 18.5,
      ),
      Credito(
        id: 'cr002',
        usuarioId: 'cliente_demo',
        descripcion: 'Préstamo Vehicular',
        montoOriginal: 35000.00,
        saldoPendiente: 28400.00,
        cuotaMensual: 778.89,
        fechaInicio: DateTime(2024, 6, 1),
        plazoMeses: 48,
        tasaInteres: 14.0,
      ),
    ]);

    _generateMockCuotas('cr001', 25000.00, 18.5 / 100 / 12, 36, DateTime(2024, 2, 15), 15);
    _generateMockCuotas('cr002', 35000.00, 14.0 / 100 / 12, 48, DateTime(2024, 7, 1), 8);

    _mockTarjetas.addAll([
      TarjetaDebito(
        id: 'td001',
        usuarioId: 'cliente_demo',
        cuentaId: 'ca002',
        numeroEnmascarado: '*6327',
        tipo: 'Tarjeta De Débito',
      ),
      TarjetaDebito(
        id: 'td002',
        usuarioId: 'cliente_demo',
        cuentaId: 'ca001',
        numeroEnmascarado: '*8841',
        tipo: 'Tarjeta De Débito',
      ),
    ]);

    _mockMovimientosTarjeta.addAll([
      MovimientoTarjeta(
        id: 'mt1',
        tarjetaId: 'td001',
        usuarioId: 'cliente_demo',
        fecha: DateTime(now.year, now.month, 23),
        comercio: 'Banco Pichincha',
        descripcion: 'Disp. efectivo Cajero Propio',
        monto: -200.00,
      ),
      MovimientoTarjeta(
        id: 'mt2',
        tarjetaId: 'td001',
        usuarioId: 'cliente_demo',
        fecha: DateTime(now.year, now.month, 23),
        comercio: 'El Capricho De Salvado',
        descripcion: 'Compra Comercio Ajeno',
        monto: -45.50,
      ),
    ]);

    _mockNotificaciones.addAll([
      Notificacion(
        id: 'n1',
        usuarioId: 'cliente_demo',
        titulo: 'Préstamo aprobado',
        mensaje: 'Tu Préstamo Personal por S/ 50,000.00 ha sido aprobado.',
        fecha: now.subtract(const Duration(hours: 5)),
        tipo: 'credito',
      ),
      Notificacion(
        id: 'n2',
        usuarioId: 'cliente_demo',
        titulo: 'Transferencia recibida',
        mensaje: 'Recibiste S/ 1,200.00 en tu Cuenta de Ahorros.',
        fecha: now.subtract(const Duration(days: 2)),
        tipo: 'transferencia',
        leida: true,
      ),
    ]);
  }

  static void _generateMockCuotas(String creditoId, double monto, double tasaMensual, int plazo, DateTime fechaInicio, int pagadas) {
    final r = tasaMensual;
    final n = plazo;
    final cuotaFija = monto * (r * _pow(1 + r, n)) / (_pow(1 + r, n) - 1);
    double saldo = monto;
    for (int i = 1; i <= plazo; i++) {
      final interes = saldo * r;
      final capital = cuotaFija - interes;
      saldo -= capital;
      _mockCuotas.add(Cuota(
        id: '${creditoId}_$i',
        creditoId: creditoId,
        numeroCuota: i,
        fechaVencimiento: DateTime(fechaInicio.year, fechaInicio.month + i - 1, fechaInicio.day),
        montoCuota: double.parse(cuotaFija.toStringAsFixed(2)),
        capital: double.parse(capital.toStringAsFixed(2)),
        interes: double.parse(interes.toStringAsFixed(2)),
        saldoRestante: double.parse(saldo < 0 ? '0' : saldo.toStringAsFixed(2)),
        pagada: i <= pagadas,
      ));
    }
  }

  static double _pow(double base, int exp) {
    double result = 1;
    for (int i = 0; i < exp; i++) {
      result *= base;
    }
    return result;
  }

  static void _enableFallback(Object error) {
    debugPrint('Supabase fallback local: $error');
    _useLocalFallback = true;
  }

  static Future<Usuario?> getUsuario(String id) async {
    _initMockData();
    if (_useLocalFallback) return _mockUsuario[id];
    try {
      final row = await SupabaseService.client.from('usuarios').select().eq('id', id).maybeSingle();
      if (row == null) return null;
      return Usuario.fromMap(Map<String, dynamic>.from(row), id);
    } catch (e) {
      _enableFallback(e);
      return _mockUsuario[id];
    }
  }

  static Future<void> actualizarCelular(String usuarioId, String celular) async {
    _initMockData();
    if (_useLocalFallback) {
      _mockUsuario[usuarioId]?.celular = celular;
      return;
    }
    try {
      await SupabaseService.client.from('usuarios').update({'celular': celular}).eq('id', usuarioId);
    } catch (e) {
      _enableFallback(e);
      _mockUsuario[usuarioId]?.celular = celular;
    }
  }

  static Future<List<CuentaAhorro>> getCuentas(String usuarioId) async {
    _initMockData();
    if (_useLocalFallback) {
      return _mockCuentas.where((c) => c.usuarioId == usuarioId).toList();
    }
    try {
      final rows = await SupabaseService.client.from('cuentas_ahorro').select().eq('usuario_id', usuarioId);
      return (rows as List)
          .map((r) => CuentaAhorro.fromMap(Map<String, dynamic>.from(r), r['id'] as String))
          .toList();
    } catch (e) {
      _enableFallback(e);
      return _mockCuentas.where((c) => c.usuarioId == usuarioId).toList();
    }
  }

  static Future<CuentaAhorro?> getCuentaPorCCI(String cci) async {
    _initMockData();
    if (_useLocalFallback) {
      final matches = _mockCuentas.where((c) => c.cci == cci);
      return matches.isEmpty ? null : matches.first;
    }
    try {
      final row = await SupabaseService.client.from('cuentas_ahorro').select().eq('cci', cci).maybeSingle();
      if (row == null) return null;
      return CuentaAhorro.fromMap(Map<String, dynamic>.from(row), row['id'] as String);
    } catch (e) {
      _enableFallback(e);
      final matches = _mockCuentas.where((c) => c.cci == cci);
      return matches.isEmpty ? null : matches.first;
    }
  }

  static Future<List<Movimiento>> getMovimientos(String usuarioId, {String? cuentaId, int limit = 5}) async {
    _initMockData();
    if (_useLocalFallback) {
      Iterable<Movimiento> filtered = _mockMovimientos.where((m) => m.usuarioId == usuarioId);
      if (cuentaId != null) filtered = filtered.where((m) => m.cuentaId == cuentaId);
      final sorted = filtered.toList()..sort((a, b) => b.fecha.compareTo(a.fecha));
      return sorted.take(limit).toList();
    }
    try {
      var query = SupabaseService.client.from('movimientos').select().eq('usuario_id', usuarioId);
      if (cuentaId != null) query = query.eq('cuenta_id', cuentaId);
      final rows = await query.order('fecha', ascending: false).limit(limit);
      return (rows as List)
          .map((r) => Movimiento.fromMap(Map<String, dynamic>.from(r), r['id'] as String))
          .toList();
    } catch (e) {
      _enableFallback(e);
      return getMovimientos(usuarioId, cuentaId: cuentaId, limit: limit);
    }
  }

  static Future<void> realizarDeposito({
    required String cuentaId,
    required String usuarioId,
    required double monto,
    required String descripcion,
  }) async {
    _initMockData();
    if (_useLocalFallback) {
      final cuenta = _mockCuentas.firstWhere((c) => c.id == cuentaId);
      cuenta.saldo += monto;
      _mockMovimientos.add(Movimiento(
        id: 'mock_m_${DateTime.now().millisecondsSinceEpoch}',
        cuentaId: cuentaId,
        usuarioId: usuarioId,
        fecha: DateTime.now(),
        descripcion: descripcion,
        monto: monto,
        tipo: 'deposito',
      ));
      return;
    }
    try {
      final cuentaRow = await SupabaseService.client.from('cuentas_ahorro').select('saldo').eq('id', cuentaId).single();
      final nuevoSaldo = (cuentaRow['saldo'] as num).toDouble() + monto;
      await SupabaseService.client.from('cuentas_ahorro').update({'saldo': nuevoSaldo}).eq('id', cuentaId);
      await SupabaseService.client.from('movimientos').insert({
        'cuenta_id': cuentaId,
        'usuario_id': usuarioId,
        'fecha': toDbDate(DateTime.now()),
        'descripcion': descripcion,
        'monto': monto,
        'tipo': 'deposito',
      });
    } catch (e) {
      _enableFallback(e);
      await realizarDeposito(cuentaId: cuentaId, usuarioId: usuarioId, monto: monto, descripcion: descripcion);
    }
  }

  static Future<String?> realizarTransferencia({
    required String cuentaOrigenId,
    required String usuarioOrigenId,
    required String cciDestino,
    required double monto,
    required String concepto,
  }) async {
    _initMockData();
    if (_useLocalFallback) {
      final matches = _mockCuentas.where((c) => c.cci == cciDestino);
      if (matches.isEmpty) return 'CCI destino no encontrado en el sistema.';
      final destCuenta = matches.first;
      final origCuenta = _mockCuentas.firstWhere((c) => c.id == cuentaOrigenId);
      if (origCuenta.saldo < monto) return 'Saldo insuficiente.';
      origCuenta.saldo -= monto;
      destCuenta.saldo += monto;
      final now = DateTime.now();
      _mockMovimientos.add(Movimiento(
        id: 'mock_t_o_${now.millisecondsSinceEpoch}',
        cuentaId: cuentaOrigenId,
        usuarioId: usuarioOrigenId,
        fecha: now,
        descripcion: 'Transferencia enviada - $concepto',
        monto: -monto,
        tipo: 'transferencia',
      ));
      _mockTransferencias.add(Transferencia(
        id: 'mock_t_${now.millisecondsSinceEpoch}',
        usuarioOrigenId: usuarioOrigenId,
        cuentaOrigenId: cuentaOrigenId,
        cuentaDestinoId: destCuenta.id,
        cciDestino: cciDestino,
        monto: monto,
        concepto: concepto,
        fecha: now,
      ));
      return null;
    }
    try {
      final destCuenta = await getCuentaPorCCI(cciDestino);
      if (destCuenta == null) return 'CCI destino no encontrado en el sistema.';
      final origRow = await SupabaseService.client.from('cuentas_ahorro').select('saldo').eq('id', cuentaOrigenId).single();
      final saldoActual = (origRow['saldo'] as num).toDouble();
      if (saldoActual < monto) return 'Saldo insuficiente.';
      final destRow = await SupabaseService.client.from('cuentas_ahorro').select('saldo').eq('id', destCuenta.id).single();
      await SupabaseService.client.from('cuentas_ahorro').update({'saldo': saldoActual - monto}).eq('id', cuentaOrigenId);
      await SupabaseService.client.from('cuentas_ahorro').update({'saldo': (destRow['saldo'] as num).toDouble() + monto}).eq('id', destCuenta.id);
      final now = DateTime.now();
      await SupabaseService.client.from('movimientos').insert([
        {
          'cuenta_id': cuentaOrigenId,
          'usuario_id': usuarioOrigenId,
          'fecha': toDbDate(now),
          'descripcion': 'Transferencia enviada - $concepto',
          'monto': -monto,
          'tipo': 'transferencia',
        },
        {
          'cuenta_id': destCuenta.id,
          'usuario_id': destCuenta.usuarioId,
          'fecha': toDbDate(now),
          'descripcion': 'Transferencia recibida - $concepto',
          'monto': monto,
          'tipo': 'transferencia',
        },
      ]);
      await SupabaseService.client.from('transferencias').insert({
        'usuario_origen_id': usuarioOrigenId,
        'cuenta_origen_id': cuentaOrigenId,
        'cuenta_destino_id': destCuenta.id,
        'cci_destino': cciDestino,
        'monto': monto,
        'concepto': concepto,
        'fecha': toDbDate(now),
      });
      return null;
    } catch (e) {
      _enableFallback(e);
      return realizarTransferencia(
        cuentaOrigenId: cuentaOrigenId,
        usuarioOrigenId: usuarioOrigenId,
        cciDestino: cciDestino,
        monto: monto,
        concepto: concepto,
      );
    }
  }

  static Future<List<Transferencia>> getTransferencias(String usuarioId) async {
    _initMockData();
    if (_useLocalFallback) {
      return _mockTransferencias.where((t) => t.usuarioOrigenId == usuarioId).toList()
        ..sort((a, b) => b.fecha.compareTo(a.fecha));
    }
    try {
      final rows = await SupabaseService.client
          .from('transferencias')
          .select()
          .eq('usuario_origen_id', usuarioId)
          .order('fecha', ascending: false)
          .limit(20);
      return (rows as List)
          .map((r) => Transferencia.fromMap(Map<String, dynamic>.from(r), r['id'] as String))
          .toList();
    } catch (e) {
      _enableFallback(e);
      return _mockTransferencias.where((t) => t.usuarioOrigenId == usuarioId).toList()
        ..sort((a, b) => b.fecha.compareTo(a.fecha));
    }
  }

  static Future<List<Credito>> getCreditos(String usuarioId) async {
    _initMockData();
    if (_useLocalFallback) return _mockCreditos.where((c) => c.usuarioId == usuarioId).toList();
    try {
      final rows = await SupabaseService.client.from('creditos').select().eq('usuario_id', usuarioId);
      return (rows as List)
          .map((r) => Credito.fromMap(Map<String, dynamic>.from(r), r['id'] as String))
          .toList();
    } catch (e) {
      _enableFallback(e);
      return _mockCreditos.where((c) => c.usuarioId == usuarioId).toList();
    }
  }

  static Future<List<Cuota>> getCuotas(String creditoId) async {
    _initMockData();
    if (_useLocalFallback) return _mockCuotas.where((c) => c.creditoId == creditoId).toList();
    try {
      final rows = await SupabaseService.client
          .from('cuotas')
          .select()
          .eq('credito_id', creditoId)
          .order('numero_cuota');
      return (rows as List)
          .map((r) => Cuota.fromMap(Map<String, dynamic>.from(r), r['id'] as String))
          .toList();
    } catch (e) {
      _enableFallback(e);
      return _mockCuotas.where((c) => c.creditoId == creditoId).toList();
    }
  }

  static Future<List<TarjetaDebito>> getTarjetas(String usuarioId) async {
    _initMockData();
    if (_useLocalFallback) return _mockTarjetas.where((t) => t.usuarioId == usuarioId).toList();
    try {
      final rows = await SupabaseService.client.from('tarjetas').select().eq('usuario_id', usuarioId);
      return (rows as List)
          .map((r) => TarjetaDebito.fromMap(Map<String, dynamic>.from(r), r['id'] as String))
          .toList();
    } catch (e) {
      _enableFallback(e);
      return _mockTarjetas.where((t) => t.usuarioId == usuarioId).toList();
    }
  }

  static Future<List<MovimientoTarjeta>> getMovimientosTarjeta(String tarjetaId) async {
    _initMockData();
    return _mockMovimientosTarjeta.where((m) => m.tarjetaId == tarjetaId).toList()
      ..sort((a, b) => b.fecha.compareTo(a.fecha));
  }

  static Future<void> toggleBloqueoTarjeta(String tarjetaId, bool bloquear) async {
    _initMockData();
    final tarjeta = _mockTarjetas.firstWhere((t) => t.id == tarjetaId);
    tarjeta.bloqueada = bloquear;
  }

  static Future<List<Notificacion>> getNotificaciones(String usuarioId) async {
    _initMockData();
    if (_useLocalFallback) {
      return _mockNotificaciones.where((n) => n.usuarioId == usuarioId).toList()
        ..sort((a, b) => b.fecha.compareTo(a.fecha));
    }
    try {
      final rows = await SupabaseService.client
          .from('notificaciones')
          .select()
          .eq('usuario_id', usuarioId)
          .order('fecha', ascending: false);
      return (rows as List)
          .map((r) => Notificacion.fromMap(Map<String, dynamic>.from(r), r['id'] as String))
          .toList();
    } catch (e) {
      _enableFallback(e);
      return _mockNotificaciones.where((n) => n.usuarioId == usuarioId).toList()
        ..sort((a, b) => b.fecha.compareTo(a.fecha));
    }
  }

  static Future<void> marcarNotificacionLeida(String notificacionId) async {
    _initMockData();
    final notif = _mockNotificaciones.where((n) => n.id == notificacionId);
    if (notif.isNotEmpty) notif.first.leida = true;
  }

  static int contarNotificacionesNoLeidas(String usuarioId) {
    _initMockData();
    return _mockNotificaciones.where((n) => n.usuarioId == usuarioId && !n.leida).length;
  }

  static Future<String?> realizarPagoServicio({
    required String cuentaId,
    required String usuarioId,
    required String servicio,
    required String referencia,
    required double monto,
  }) async {
    _initMockData();
    final cuentaMatches = _mockCuentas.where((c) => c.id == cuentaId);
    if (cuentaMatches.isEmpty) return 'Cuenta no encontrada.';
    final cuenta = cuentaMatches.first;
    if (cuenta.saldo < monto) return 'Saldo insuficiente.';
    cuenta.saldo -= monto;
    final now = DateTime.now();
    _mockMovimientos.add(Movimiento(
      id: 'mock_p_${now.millisecondsSinceEpoch}',
      cuentaId: cuentaId,
      usuarioId: usuarioId,
      fecha: now,
      descripcion: 'Pago $servicio - Ref. $referencia',
      monto: -monto,
      tipo: 'retiro',
    ));
    return null;
  }

  static Future<List<PagoServicio>> getPagos(String usuarioId) async {
    _initMockData();
    return _mockPagos.where((p) => p.usuarioId == usuarioId).toList()
      ..sort((a, b) => b.fecha.compareTo(a.fecha));
  }

  static Future<String?> enviarDineroWallet({
    required String cuentaOrigenId,
    required String usuarioOrigenId,
    required String wallet,
    required String celularDestino,
    required double monto,
    required String concepto,
  }) async {
    _initMockData();
    final origMatches = _mockCuentas.where((c) => c.id == cuentaOrigenId);
    if (origMatches.isEmpty) return 'Cuenta no encontrada.';
    final origCuenta = origMatches.first;
    if (origCuenta.saldo < monto) return 'Saldo insuficiente.';
    origCuenta.saldo -= monto;
    final now = DateTime.now();
    _mockMovimientos.add(Movimiento(
      id: 'mock_w_${now.millisecondsSinceEpoch}',
      cuentaId: cuentaOrigenId,
      usuarioId: usuarioOrigenId,
      fecha: now,
      descripcion: 'Envío $wallet a $celularDestino - $concepto',
      monto: -monto,
      tipo: 'transferencia',
    ));
    return null;
  }
}
