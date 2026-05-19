import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/models.dart';

class FirestoreService {
  static final _db = FirebaseFirestore.instance;
  static const String demoUserId = 'cliente_demo';

  // ─── Colecciones ────────────────────────────────────────────────
  static CollectionReference get _usuarios => _db.collection('usuarios');
  static CollectionReference get _cuentas => _db.collection('cuentas_ahorro');
  static CollectionReference get _movimientos => _db.collection('movimientos');
  static CollectionReference get _creditos => _db.collection('creditos');
  static CollectionReference get _cuotas => _db.collection('cuotas');
  static CollectionReference get _transferencias => _db.collection('transferencias');

  // ─── Variables de Memoria para Fallback Offline ────────────────
  static bool _useLocalFallback = false;
  static final Map<String, Usuario> _mockUsuario = {};
  static final List<CuentaAhorro> _mockCuentas = [];
  static final List<Movimiento> _mockMovimientos = [];
  static final List<Credito> _mockCreditos = [];
  static final List<Cuota> _mockCuotas = [];
  static final List<Transferencia> _mockTransferencias = [];

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
    for (int i = 0; i < exp; i++) result *= base;
    return result;
  }

  // ─── Usuario ─────────────────────────────────────────────────────
  static Future<Usuario?> getUsuario(String id) async {
    _initMockData();
    if (_useLocalFallback) {
      return _mockUsuario[id];
    }
    try {
      final doc = await _usuarios.doc(id).get();
      if (!doc.exists) return null;
      return Usuario.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    } catch (e) {
      debugPrint("Firestore failed, falling back locally: $e");
      _useLocalFallback = true;
      return _mockUsuario[id];
    }
  }

  static Future<void> actualizarCelular(String usuarioId, String celular) async {
    _initMockData();
    if (_useLocalFallback) {
      final u = _mockUsuario[usuarioId];
      if (u != null) {
        u.celular = celular;
      }
      return;
    }
    try {
      await _usuarios.doc(usuarioId).update({'celular': celular});
    } catch (e) {
      _useLocalFallback = true;
      final u = _mockUsuario[usuarioId];
      if (u != null) {
        u.celular = celular;
      }
    }
  }

  // ─── Cuentas de Ahorro ───────────────────────────────────────────
  static Future<List<CuentaAhorro>> getCuentas(String usuarioId) async {
    _initMockData();
    if (_useLocalFallback) {
      return _mockCuentas.where((c) => c.usuarioId == usuarioId).toList();
    }
    try {
      final snap = await _cuentas.where('usuario_id', isEqualTo: usuarioId).get();
      return snap.docs
          .map((d) => CuentaAhorro.fromMap(d.data() as Map<String, dynamic>, d.id))
          .toList();
    } catch (e) {
      _useLocalFallback = true;
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
      final snap = await _cuentas.where('cci', isEqualTo: cci).limit(1).get();
      if (snap.docs.isEmpty) return null;
      final d = snap.docs.first;
      return CuentaAhorro.fromMap(d.data() as Map<String, dynamic>, d.id);
    } catch (e) {
      _useLocalFallback = true;
      final matches = _mockCuentas.where((c) => c.cci == cci);
      return matches.isEmpty ? null : matches.first;
    }
  }

  // ─── Movimientos ────────────────────────────────────────────────
  static Future<List<Movimiento>> getMovimientos(String usuarioId,
      {String? cuentaId, int limit = 5}) async {
    _initMockData();
    if (_useLocalFallback) {
      Iterable<Movimiento> filtered = _mockMovimientos.where((m) => m.usuarioId == usuarioId);
      if (cuentaId != null) {
        filtered = filtered.where((m) => m.cuentaId == cuentaId);
      }
      final sorted = filtered.toList()..sort((a, b) => b.fecha.compareTo(a.fecha));
      return sorted.take(limit).toList();
    }
    try {
      Query q = _movimientos.where('usuario_id', isEqualTo: usuarioId);
      if (cuentaId != null) q = q.where('cuenta_id', isEqualTo: cuentaId);
      q = q.orderBy('fecha', descending: true).limit(limit);
      final snap = await q.get();
      return snap.docs
          .map((d) => Movimiento.fromMap(d.data() as Map<String, dynamic>, d.id))
          .toList();
    } catch (e) {
      _useLocalFallback = true;
      Iterable<Movimiento> filtered = _mockMovimientos.where((m) => m.usuarioId == usuarioId);
      if (cuentaId != null) {
        filtered = filtered.where((m) => m.cuentaId == cuentaId);
      }
      final sorted = filtered.toList()..sort((a, b) => b.fecha.compareTo(a.fecha));
      return sorted.take(limit).toList();
    }
  }

  // ─── Depósito ───────────────────────────────────────────────────
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
      final batch = _db.batch();
      final cuentaRef = _cuentas.doc(cuentaId);
      batch.update(cuentaRef, {'saldo': FieldValue.increment(monto)});

      final movRef = _movimientos.doc();
      batch.set(movRef, {
        'cuenta_id': cuentaId,
        'usuario_id': usuarioId,
        'fecha': FieldValue.serverTimestamp(),
        'descripcion': descripcion,
        'monto': monto,
        'tipo': 'deposito',
      });

      await batch.commit();
    } catch (e) {
      _useLocalFallback = true;
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
    }
  }

  // ─── Transferencia ──────────────────────────────────────────────
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

      _mockMovimientos.add(Movimiento(
        id: 'mock_t_d_${now.millisecondsSinceEpoch}',
        cuentaId: destCuenta.id,
        usuarioId: destCuenta.usuarioId,
        fecha: now,
        descripcion: 'Transferencia recibida - $concepto',
        monto: monto,
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
      final cuentaDest = await getCuentaPorCCI(cciDestino);
      if (cuentaDest == null) return 'CCI destino no encontrado en el sistema.';

      final docOrigen = await _cuentas.doc(cuentaOrigenId).get();
      final saldoActual = ((docOrigen.data() as Map<String, dynamic>)['saldo'] ?? 0).toDouble();
      if (saldoActual < monto) return 'Saldo insuficiente.';

      final batch = _db.batch();
      final now = FieldValue.serverTimestamp();

      batch.update(_cuentas.doc(cuentaOrigenId), {'saldo': FieldValue.increment(-monto)});
      batch.update(_cuentas.doc(cuentaDest.id), {'saldo': FieldValue.increment(monto)});

      final movOrigen = _movimientos.doc();
      batch.set(movOrigen, {
        'cuenta_id': cuentaOrigenId,
        'usuario_id': usuarioOrigenId,
        'fecha': now,
        'descripcion': 'Transferencia enviada - $concepto',
        'monto': -monto,
        'tipo': 'transferencia',
      });

      final movDest = _movimientos.doc();
      batch.set(movDest, {
        'cuenta_id': cuentaDest.id,
        'usuario_id': cuentaDest.usuarioId,
        'fecha': now,
        'descripcion': 'Transferencia recibida - $concepto',
        'monto': monto,
        'tipo': 'transferencia',
      });

      final transRef = _transferencias.doc();
      batch.set(transRef, {
        'usuario_origen_id': usuarioOrigenId,
        'cuenta_origen_id': cuentaOrigenId,
        'cuenta_destino_id': cuentaDest.id,
        'cci_destino': cciDestino,
        'monto': monto,
        'concepto': concepto,
        'fecha': now,
      });

      await batch.commit();
      return null;
    } catch (e) {
      // Fallback
      _useLocalFallback = true;
      return realizarTransferencia(
        cuentaOrigenId: cuentaOrigenId,
        usuarioOrigenId: usuarioOrigenId,
        cciDestino: cciDestino,
        monto: monto,
        concepto: concepto,
      );
    }
  }

  // ─── Historial de Transferencias ────────────────────────────────
  static Future<List<Transferencia>> getTransferencias(String usuarioId) async {
    _initMockData();
    if (_useLocalFallback) {
      return _mockTransferencias.where((t) => t.usuarioOrigenId == usuarioId).toList()
        ..sort((a, b) => b.fecha.compareTo(a.fecha));
    }
    try {
      final snap = await _transferencias
          .where('usuario_origen_id', isEqualTo: usuarioId)
          .orderBy('fecha', descending: true)
          .limit(20)
          .get();
      return snap.docs
          .map((d) => Transferencia.fromMap(d.data() as Map<String, dynamic>, d.id))
          .toList();
    } catch (e) {
      _useLocalFallback = true;
      return _mockTransferencias.where((t) => t.usuarioOrigenId == usuarioId).toList()
        ..sort((a, b) => b.fecha.compareTo(a.fecha));
    }
  }

  // ─── Créditos ───────────────────────────────────────────────────
  static Future<List<Credito>> getCreditos(String usuarioId) async {
    _initMockData();
    if (_useLocalFallback) {
      return _mockCreditos.where((c) => c.usuarioId == usuarioId).toList();
    }
    try {
      final snap = await _creditos.where('usuario_id', isEqualTo: usuarioId).get();
      return snap.docs
          .map((d) => Credito.fromMap(d.data() as Map<String, dynamic>, d.id))
          .toList();
    } catch (e) {
      _useLocalFallback = true;
      return _mockCreditos.where((c) => c.usuarioId == usuarioId).toList();
    }
  }

  static Future<List<Cuota>> getCuotas(String creditoId) async {
    _initMockData();
    if (_useLocalFallback) {
      return _mockCuotas.where((c) => c.creditoId == creditoId).toList();
    }
    try {
      final snap = await _cuotas
          .where('credito_id', isEqualTo: creditoId)
          .orderBy('numero_cuota')
          .get();
      return snap.docs
          .map((d) => Cuota.fromMap(d.data() as Map<String, dynamic>, d.id))
          .toList();
    } catch (e) {
      _useLocalFallback = true;
      return _mockCuotas.where((c) => c.creditoId == creditoId).toList();
    }
  }
}
