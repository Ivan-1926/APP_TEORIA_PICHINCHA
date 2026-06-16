import 'package:flutter/material.dart';
import '../../services/bank_data_service.dart';
import '../../services/user_scope.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';
import '../../utils/format_utils.dart';

class AhorrosScreen extends StatefulWidget {
  const AhorrosScreen({super.key});

  @override
  State<AhorrosScreen> createState() => _AhorrosScreenState();
}

class _AhorrosScreenState extends State<AhorrosScreen> {
  List<CuentaAhorro> _cuentas = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final cuentas = await BankDataService.getCuentas(activeUserId);
    setState(() {
      _cuentas = cuentas;
      _loading = false;
    });
  }

  void _mostrarDetalles(CuentaAhorro cuenta) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _DetalleCuentaSheet(cuenta: cuenta, onUpdated: _load),
    );
  }

  void _mostrarSimularDeposito(CuentaAhorro cuenta) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _DepositoSimuladoSheet(cuenta: cuenta, onCompleted: _load),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Cuentas de Ahorros'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              color: AppColors.primary,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _cuentas.length,
                itemBuilder: (context, index) {
                  final cuenta = _cuentas[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    elevation: 2,
                    shadowColor: Colors.black12,
                    child: InkWell(
                      onTap: () => _mostrarDetalles(cuenta),
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(Icons.account_balance_wallet,
                                          color: AppColors.primary, size: 24),
                                    ),
                                    const SizedBox(width: 12),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(cuenta.tipo,
                                            style: const TextStyle(
                                                fontSize: 16, fontWeight: FontWeight.bold)),
                                        const SizedBox(height: 2),
                                        Text('N° ${cuenta.numero}',
                                            style: const TextStyle(
                                                fontSize: 13, color: AppColors.textSecondary)),
                                      ],
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.accent.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    'Activa',
                                    style: TextStyle(
                                        color: AppColors.accentDark,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            const Divider(),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Saldo disponible',
                                        style: TextStyle(
                                            fontSize: 12, color: AppColors.textSecondary)),
                                    const SizedBox(height: 4),
                                    Text(FormatUtils.formatCurrency(cuenta.saldo),
                                        style: const TextStyle(
                                            fontSize: 22,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.primary)),
                                  ],
                                ),
                                Row(
                                  children: [
                                    IconButton(
                                      tooltip: 'Simular Depósito',
                                      icon: const Icon(Icons.add_circle_outline,
                                          color: AppColors.accent, size: 28),
                                      onPressed: () => _mostrarSimularDeposito(cuenta),
                                    ),
                                    const Icon(Icons.chevron_right, color: AppColors.textHint),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}

// ─── BOTTOM SHEET: ESTADO DE CUENTA (DETALLES) ────────────────────────────────

class _DetalleCuentaSheet extends StatefulWidget {
  final CuentaAhorro cuenta;
  final VoidCallback onUpdated;

  const _DetalleCuentaSheet({required this.cuenta, required this.onUpdated});

  @override
  State<_DetalleCuentaSheet> createState() => _DetalleCuentaSheetState();
}

class _DetalleCuentaSheetState extends State<_DetalleCuentaSheet> {
  List<Movimiento> _movimientos = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadMovimientos();
  }

  Future<void> _loadMovimientos() async {
    final movs = await BankDataService.getMovimientos(
      activeUserId,
      cuentaId: widget.cuenta.id,
      limit: 20,
    );
    setState(() {
      _movimientos = movs;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (context, controller) => Container(
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Handlebar
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.textHint.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Estado de Cuenta',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(),
            // Cuenta Header Card
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.cuenta.tipo,
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text('N° ${widget.cuenta.numero}',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      const SizedBox(height: 4),
                      Text('CCI: ${widget.cuenta.cci}',
                          style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
                    ],
                  ),
                  Text(FormatUtils.formatCurrency(widget.cuenta.saldo),
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary)),
                ],
              ),
            ),
            // Movements title
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Movimientos recientes',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              ),
            ),
            // Movements List
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _movimientos.isEmpty
                      ? const Center(child: Text('No hay movimientos registrados.'))
                      : ListView.separated(
                          controller: controller,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          itemCount: _movimientos.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final mov = _movimientos[index];
                            final esPos = mov.esCredito;
                            return Container(
                              color: Colors.white,
                              child: ListTile(
                                leading: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: (esPos ? AppColors.positive : AppColors.negative)
                                        .withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    esPos ? Icons.arrow_downward : Icons.arrow_upward,
                                    color: esPos ? AppColors.positive : AppColors.negative,
                                    size: 18,
                                  ),
                                ),
                                title: Text(mov.descripcion,
                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                                subtitle: Text(
                                    FormatUtils.formatDateTime(mov.fecha),
                                    style: const TextStyle(fontSize: 11)),
                                trailing: Text(
                                  '${esPos ? "+" : ""}${FormatUtils.formatCurrency(mov.monto)}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: esPos ? AppColors.positive : AppColors.negative,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── BOTTOM SHEET: SIMULAR DEPÓSITO ───────────────────────────────────────────

class _DepositoSimuladoSheet extends StatefulWidget {
  final CuentaAhorro cuenta;
  final VoidCallback onCompleted;

  const _DepositoSimuladoSheet({required this.cuenta, required this.onCompleted});

  @override
  State<_DepositoSimuladoSheet> createState() => _DepositoSimuladoSheetState();
}

class _DepositoSimuladoSheetState extends State<_DepositoSimuladoSheet> {
  final _montoController = TextEditingController();
  final _conceptoController = TextEditingController(text: 'Depósito simulación');
  final _formKey = GlobalKey<FormState>();
  bool _submitting = false;

  @override
  void dispose() {
    _montoController.dispose();
    _conceptoController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);

    try {
      final monto = double.parse(_montoController.text);
      await BankDataService.realizarDeposito(
        cuentaId: widget.cuenta.id,
        usuarioId: activeUserId,
        monto: monto,
        descripcion: _conceptoController.text,
      );

      widget.onCompleted();
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Depósito simulado con éxito!'),
            backgroundColor: AppColors.accentDark,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al realizar el depósito: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Simular Depósito',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Cuenta destino: ${widget.cuenta.tipo} (N° ${widget.cuenta.numero})',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _montoController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Monto (S/)',
                  hintText: '0.00',
                  prefixIcon: Icon(Icons.monetization_on_outlined),
                ),
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Ingrese un monto';
                  final num = double.tryParse(val);
                  if (num == null || num <= 0) return 'Monto debe ser mayor a 0';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _conceptoController,
                decoration: const InputDecoration(
                  labelText: 'Concepto / Descripción',
                  prefixIcon: Icon(Icons.description_outlined),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Ingrese un concepto';
                  return null;
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _submitting ? null : _submit,
                child: _submitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('Confirmar Depósito'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
