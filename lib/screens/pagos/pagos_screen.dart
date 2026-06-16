import 'package:flutter/material.dart';
import '../../data/catalog_data.dart';
import '../../services/bank_data_service.dart';
import '../../services/user_scope.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';
import '../../utils/format_utils.dart';

class PagosScreen extends StatefulWidget {
  const PagosScreen({super.key});

  @override
  State<PagosScreen> createState() => _PagosScreenState();
}

class _PagosScreenState extends State<PagosScreen> with SingleTickerProviderStateMixin {
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
        title: const Text('Pagos'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.accent,
          tabs: const [
            Tab(text: 'Nuevo pago'),
            Tab(text: 'Historial'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _NuevoPagoTab(),
          _HistorialPagosTab(),
        ],
      ),
    );
  }
}

class _NuevoPagoTab extends StatefulWidget {
  const _NuevoPagoTab();

  @override
  State<_NuevoPagoTab> createState() => _NuevoPagoTabState();
}

class _NuevoPagoTabState extends State<_NuevoPagoTab> {
  final _formKey = GlobalKey<FormState>();
  final _referenciaCtrl = TextEditingController();
  final _montoCtrl = TextEditingController();
  String? _servicio;
  List<CuentaAhorro> _cuentas = [];
  CuentaAhorro? _cuenta;
  bool _loading = true;
  bool _paying = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _referenciaCtrl.dispose();
    _montoCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final cuentas = await BankDataService.getCuentas(activeUserId);
    setState(() {
      _cuentas = cuentas;
      _cuenta = cuentas.isNotEmpty ? cuentas.first : null;
      _loading = false;
    });
  }

  Future<void> _pagar() async {
    if (!_formKey.currentState!.validate() || _cuenta == null || _servicio == null) return;
    setState(() => _paying = true);
    final error = await BankDataService.realizarPagoServicio(
      cuentaId: _cuenta!.id,
      usuarioId: activeUserId,
      servicio: _servicio!,
      referencia: _referenciaCtrl.text.trim(),
      monto: double.parse(_montoCtrl.text),
    );
    if (!mounted) return;
    setState(() => _paying = false);
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error), backgroundColor: AppColors.error));
    } else {
      _referenciaCtrl.clear();
      _montoCtrl.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pago realizado correctamente'), backgroundColor: AppColors.positive),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Pagos disponibles hasta las 10:30 p.m.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<CuentaAhorro>(
              value: _cuenta,
              decoration: const InputDecoration(labelText: 'Cuenta a debitar'),
              items: _cuentas
                  .map((c) => DropdownMenuItem(value: c, child: Text('${c.tipo} (${FormatUtils.formatCurrency(c.saldo)})')))
                  .toList(),
              onChanged: (v) => setState(() => _cuenta = v),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _servicio,
              decoration: const InputDecoration(labelText: 'Servicio o institución'),
              items: pagosServicios.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
              onChanged: (v) => setState(() => _servicio = v),
              validator: (v) => v == null ? 'Selecciona un servicio' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _referenciaCtrl,
              decoration: const InputDecoration(labelText: 'Código / referencia de pago'),
              validator: (v) => (v == null || v.isEmpty) ? 'Ingresa la referencia' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _montoCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Monto (S/)'),
              validator: (v) {
                final m = double.tryParse(v ?? '');
                if (m == null || m <= 0) return 'Monto inválido';
                return null;
              },
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _paying ? null : _pagar,
              child: _paying
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Pagar servicio'),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistorialPagosTab extends StatefulWidget {
  const _HistorialPagosTab();

  @override
  State<_HistorialPagosTab> createState() => _HistorialPagosTabState();
}

class _HistorialPagosTabState extends State<_HistorialPagosTab> {
  List<PagoServicio> _pagos = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final pagos = await BankDataService.getPagos(activeUserId);
    setState(() {
      _pagos = pagos;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_pagos.isEmpty) {
      return const Center(child: Text('Aún no tienes pagos registrados.'));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _pagos.length,
      separatorBuilder: (_, __) => const Divider(),
      itemBuilder: (_, i) {
        final p = _pagos[i];
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.surfaceMuted,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.receipt, color: AppColors.primary),
          ),
          title: Text(p.servicio, style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text('Ref. ${p.referencia} · ${FormatUtils.formatDateShort(p.fecha)}'),
          trailing: Text(
            FormatUtils.formatCurrency(p.monto),
            style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.error),
          ),
        );
      },
    );
  }
}
