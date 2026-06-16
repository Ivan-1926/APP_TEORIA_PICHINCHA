import 'package:flutter/material.dart';
import '../../services/bank_data_service.dart';
import '../../services/user_scope.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';
import '../../utils/format_utils.dart';

class TransferenciasScreen extends StatefulWidget {
  const TransferenciasScreen({super.key});

  @override
  State<TransferenciasScreen> createState() => _TransferenciasScreenState();
}

class _TransferenciasScreenState extends State<TransferenciasScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transferencias interbancarias'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.accent,
          indicatorWeight: 3,
          tabs: const [
            Tab(icon: Icon(Icons.send), text: 'Nueva Transferencia'),
            Tab(icon: Icon(Icons.history), text: 'Historial'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _NuevaTransferenciaTab(onSuccess: () => _tabController.animateTo(1)),
          const _HistorialTransferenciasTab(),
        ],
      ),
    );
  }
}

// ─── TAB: NUEVA TRANSFERENCIA ────────────────────────────────────────────────

class _NuevaTransferenciaTab extends StatefulWidget {
  final VoidCallback onSuccess;
  const _NuevaTransferenciaTab({required this.onSuccess});

  @override
  State<_NuevaTransferenciaTab> createState() => _NuevaTransferenciaTabState();
}

class _NuevaTransferenciaTabState extends State<_NuevaTransferenciaTab> {
  final _formKey = GlobalKey<FormState>();

  final _cciController = TextEditingController();
  final _montoController = TextEditingController();
  final _conceptoController = TextEditingController();

  List<CuentaAhorro> _cuentasOrigen = [];
  CuentaAhorro? _cuentaSeleccionada;
  Usuario? _usuarioDestino;
  CuentaAhorro? _cuentaDestino;

  bool _loadingCuentas = true;
  bool _validandoCCI = false;
  bool _transferring = false;

  @override
  void initState() {
    super.initState();
    _loadCuentas();
    _cciController.addListener(_onCCIChanged);
  }

  @override
  void dispose() {
    _cciController.removeListener(_onCCIChanged);
    _cciController.dispose();
    _montoController.dispose();
    _conceptoController.dispose();
    super.dispose();
  }

  Future<void> _loadCuentas() async {
    final cuentas = await BankDataService.getCuentas(activeUserId);
    setState(() {
      _cuentasOrigen = cuentas;
      if (cuentas.isNotEmpty) _cuentaSeleccionada = cuentas.first;
      _loadingCuentas = false;
    });
  }

  void _onCCIChanged() {
    final cci = _cciController.text.trim();
    if (cci.length == 17) {
      _validarDestino(cci);
    } else {
      if (_usuarioDestino != null || _cuentaDestino != null) {
        setState(() {
          _usuarioDestino = null;
          _cuentaDestino = null;
        });
      }
    }
  }

  Future<void> _validarDestino(String cci) async {
    setState(() {
      _validandoCCI = true;
      _usuarioDestino = null;
      _cuentaDestino = null;
    });

    try {
      final destCuenta = await BankDataService.getCuentaPorCCI(cci);
      if (destCuenta != null) {
        final destUser = await BankDataService.getUsuario(destCuenta.usuarioId);
        setState(() {
          _cuentaDestino = destCuenta;
          _usuarioDestino = destUser;
        });
      }
    } catch (e) {
      // Ignorar o registrar error de validación
    } finally {
      setState(() => _validandoCCI = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_cuentaSeleccionada == null) return;
    if (_cuentaDestino == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Debe ingresar un CCI destino válido y registrado.'),
            backgroundColor: AppColors.error),
      );
      return;
    }

    setState(() => _transferring = true);

    final error = await BankDataService.realizarTransferencia(
      cuentaOrigenId: _cuentaSeleccionada!.id,
      usuarioOrigenId: activeUserId,
      cciDestino: _cciController.text.trim(),
      monto: double.parse(_montoController.text),
      concepto: _conceptoController.text.trim(),
    );

    setState(() => _transferring = false);

    if (error != null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), backgroundColor: AppColors.error),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Transferencia realizada con éxito!'),
            backgroundColor: AppColors.accentDark,
          ),
        );
        _cciController.clear();
        _montoController.clear();
        _conceptoController.clear();
        _loadCuentas(); // Refrescar saldos locales
        widget.onSuccess();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingCuentas) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Seleccione Cuenta Origen',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.divider),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<CuentaAhorro>(
                  value: _cuentaSeleccionada,
                  isExpanded: true,
                  items: _cuentasOrigen.map((c) {
                    return DropdownMenuItem<CuentaAhorro>(
                      value: c,
                      child: Text(
                        '${c.tipo} (N° ${c.numero}) - Bal: ${FormatUtils.formatCurrency(c.saldo)}',
                        style: const TextStyle(fontSize: 14),
                      ),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => _cuentaSeleccionada = val),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Datos del Destinatario',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _cciController,
              keyboardType: TextInputType.number,
              maxLength: 17,
              decoration: InputDecoration(
                labelText: 'Cuenta Destino CCI (17 dígitos)',
                hintText: 'Ej. 00221001112220000',
                prefixIcon: const Icon(Icons.credit_card_outlined),
                suffixIcon: _validandoCCI
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: Padding(
                          padding: EdgeInsets.all(12),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : null,
                counterText: '',
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) return 'Ingrese el CCI de destino';
                if (val.trim().length != 17) return 'El CCI debe tener exactamente 17 dígitos';
                return null;
              },
            ),
            if (_usuarioDestino != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.accent.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: AppColors.accentDark, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Destinatario: ${_usuarioDestino!.nombre}',
                            style: const TextStyle(
                                color: AppColors.accentDark,
                                fontWeight: FontWeight.bold,
                                fontSize: 13),
                          ),
                          Text(
                            'Banco: Banco Pichincha | CCI válido',
                            style: TextStyle(color: AppColors.accentDark.withOpacity(0.8), fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ] else if (_cciController.text.trim().length == 17 && !_validandoCCI) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.error.withOpacity(0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.error, color: AppColors.error, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'El CCI ingresado no corresponde a ningún usuario demo registrado.',
                        style: TextStyle(color: AppColors.error, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),
            const Text(
              'Detalles de la Transferencia',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _montoController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Monto a Transferir (S/)',
                hintText: '0.00',
                prefixIcon: Icon(Icons.monetization_on_outlined),
              ),
              validator: (val) {
                if (val == null || val.isEmpty) return 'Ingrese un monto';
                final num = double.tryParse(val);
                if (num == null || num <= 0) return 'Monto debe ser mayor a 0';
                if (_cuentaSeleccionada != null && num > _cuentaSeleccionada!.saldo) {
                  return 'Saldo insuficiente en cuenta origen';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _conceptoController,
              decoration: const InputDecoration(
                labelText: 'Concepto',
                hintText: 'Ej. Pago de almuerzo',
                prefixIcon: Icon(Icons.info_outline),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) return 'Ingrese un concepto';
                return null;
              },
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _transferring ? null : _submit,
              child: _transferring
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Text('Confirmar Transferencia'),
            ),
            const SizedBox(height: 12),
            const Center(
              child: Text(
                'Nota: Usa el CCI demo 00221001112220000 para probar.',
                style: TextStyle(color: AppColors.textHint, fontSize: 11, fontStyle: FontStyle.italic),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── TAB: HISTORIAL DE TRANSFERENCIAS ─────────────────────────────────────────

class _HistorialTransferenciasTab extends StatefulWidget {
  const _HistorialTransferenciasTab();

  @override
  State<_HistorialTransferenciasTab> createState() => _HistorialTransferenciasTabState();
}

class _HistorialTransferenciasTabState extends State<_HistorialTransferenciasTab> {
  List<Transferencia> _transferencias = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await BankDataService.getTransferencias(activeUserId);
    setState(() {
      _transferencias = list;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.primary,
      child: _transferencias.isEmpty
          ? ListView(
              children: const [
                SizedBox(height: 100),
                Center(
                  child: Column(
                    children: [
                      Icon(Icons.history_toggle_off, size: 64, color: AppColors.textHint),
                      SizedBox(height: 12),
                      Text('Aún no has realizado transferencias.',
                          style: TextStyle(color: AppColors.textSecondary)),
                    ],
                  ),
                ),
              ],
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _transferencias.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (context, index) {
                final t = _transferencias[index];
                return Card(
                  color: Colors.white,
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.swap_horiz, color: AppColors.primary),
                    ),
                    title: Text(
                      t.concepto.isEmpty ? 'Transferencia' : t.concepto,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 2),
                        Text('A CCI: ${t.cciDestino}', style: const TextStyle(fontSize: 12)),
                        Text(FormatUtils.formatDateTime(t.fecha),
                            style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
                      ],
                    ),
                    trailing: Text(
                      '-${FormatUtils.formatCurrency(t.monto)}',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.error),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
