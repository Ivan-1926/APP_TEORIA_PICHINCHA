import 'package:flutter/material.dart';
import '../../services/firestore_service.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';
import '../home_shell.dart';
import '../../utils/format_utils.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<CuentaAhorro> _cuentas = [];
  List<Movimiento> _movimientos = [];
  bool _loading = true;
  bool _saldoVisible = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final cuentas = await FirestoreService.getCuentas(FirestoreService.demoUserId);
    final movs = await FirestoreService.getMovimientos(FirestoreService.demoUserId, limit: 5);
    setState(() {
      _cuentas = cuentas;
      _movimientos = movs;
      _loading = false;
    });
  }

  double get _saldoTotal => _cuentas.fold(0, (s, c) => s + c.saldo);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _load,
        color: AppColors.primary,
        child: CustomScrollView(
          slivers: [
            _buildAppBar(),
            if (_loading)
              const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
            else ...[
              SliverToBoxAdapter(child: _buildSaldoCard()),
              SliverToBoxAdapter(child: _buildAccionesRapidas(context)),
              SliverToBoxAdapter(child: _buildUltimosMovimientos()),
            ],
          ],
        ),
      ),
    );
  }

  SliverAppBar _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 0,
      floating: true,
      snap: true,
      backgroundColor: AppColors.primary,
      title: Row(children: [
        Image.network(
          'https://upload.wikimedia.org/wikipedia/commons/thumb/e/e3/Banco_Pichincha_logo.svg/200px-Banco_Pichincha_logo.svg.png',
          height: 28,
          errorBuilder: (_, __, ___) => const Text('Banco Pichincha',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        ),
      ]),
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined, color: Colors.white),
          onPressed: () {},
        ),
      ],
    );
  }

  Widget _buildSaldoCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primaryDark, AppColors.primary, AppColors.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('Saldo Total', style: TextStyle(color: Colors.white70, fontSize: 14)),
          GestureDetector(
            onTap: () => setState(() => _saldoVisible = !_saldoVisible),
            child: Icon(_saldoVisible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                color: Colors.white70, size: 20),
          ),
        ]),
        const SizedBox(height: 8),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: Text(
            _saldoVisible ? FormatUtils.formatCurrency(_saldoTotal) : 'S/ ••••••',
            key: ValueKey(_saldoVisible),
            style: const TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 16),
        const Divider(color: Colors.white24),
        const SizedBox(height: 12),
        Text('${_cuentas.length} cuenta${_cuentas.length != 1 ? "s" : ""} activa${_cuentas.length != 1 ? "s" : ""}',
            style: const TextStyle(color: Colors.white70, fontSize: 13)),
        const SizedBox(height: 8),
        ..._cuentas.map((c) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text(c.tipo, style: const TextStyle(color: Colors.white, fontSize: 13)),
                Text(
                  _saldoVisible ? FormatUtils.formatCurrency(c.saldo) : 'S/ ••••',
                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ]),
            )),
      ]),
    );
  }

  Widget _buildAccionesRapidas(BuildContext context) {
    final items = [
      _QuickAction(icon: Icons.savings, label: 'Ahorros', color: const Color(0xFF1E40AF), index: 1),
      _QuickAction(icon: Icons.credit_card, label: 'Créditos', color: const Color(0xFF7C3AED), index: 2),
      _QuickAction(icon: Icons.swap_horiz, label: 'Transferir', color: AppColors.accent, index: 3),
      _QuickAction(icon: Icons.person, label: 'Perfil', color: const Color(0xFFB45309), index: 4),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: Text('Acciones rápidas', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: items.map((a) => _buildQuickBtn(context, a)).toList(),
        ),
        const SizedBox(height: 20),
      ]),
    );
  }

  Widget _buildQuickBtn(BuildContext context, _QuickAction a) {
    return GestureDetector(
      onTap: () {
        HomeShellProvider.of(context)?.switchTab(a.index);
      },
      child: InkWell(
        onTap: () {
          HomeShellProvider.of(context)?.switchTab(a.index);
        },
        borderRadius: BorderRadius.circular(16),
        child: Column(children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: a.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: a.color.withOpacity(0.2)),
            ),
            child: Icon(a.icon, color: a.color, size: 28),
          ),
          const SizedBox(height: 6),
          Text(a.label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
        ]),
      ),
    );
  }

  Widget _buildUltimosMovimientos() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Últimos movimientos', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        if (_movimientos.isEmpty)
          const Center(child: Text('Sin movimientos recientes'))
        else
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _movimientos.length,
              separatorBuilder: (_, __) => const Divider(height: 1, indent: 56),
              itemBuilder: (_, i) => _MovimientoTile(mov: _movimientos[i]),
            ),
          ),
        const SizedBox(height: 24),
      ]),
    );
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

abstract class _HomeShellStateAccess {
  void switchTab(int index);
}

class _QuickAction {
  final IconData icon;
  final String label;
  final Color color;
  final int index;
  const _QuickAction({required this.icon, required this.label, required this.color, required this.index});
}

class _MovimientoTile extends StatelessWidget {
  final Movimiento mov;
  const _MovimientoTile({required this.mov});

  @override
  Widget build(BuildContext context) {
    final esPos = mov.esCredito;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: (esPos ? AppColors.positive : AppColors.negative).withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          esPos ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
          color: esPos ? AppColors.positive : AppColors.negative,
          size: 20,
        ),
      ),
      title: Text(mov.descripcion,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(FormatUtils.formatDateShort(mov.fecha),
          style: const TextStyle(fontSize: 12)),
      trailing: Text(
        '${esPos ? "+" : ""}${FormatUtils.formatCurrency(mov.monto)}',
        style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: esPos ? AppColors.positive : AppColors.negative),
      ),
    );
  }
}
