import 'package:flutter/material.dart';
import '../../services/bank_data_service.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';
import '../../widgets/brand_logo.dart';
import '../../services/sync_integration_service.dart';
import '../../services/auth_service.dart';
import '../../services/user_scope.dart';
import '../home_shell.dart';
import '../perfil/perfil_screen.dart';
import '../ayuda/ayuda_screen.dart';
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
    setState(() => _loading = true);
    final doc = AuthService.currentUser?.documento ?? activeDocumento;
    await SyncIntegrationService.procesarCreditosPendientes(doc);
    final cuentas = await BankDataService.getCuentas(activeUserId);
    final movs = await BankDataService.getMovimientos(activeUserId, limit: 5);
    if (!mounted) return;
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
              SliverToBoxAdapter(child: _buildDescubreSection(context)),
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
      backgroundColor: AppColors.surface,
      surfaceTintColor: AppColors.surface,
      title: const Row(
        children: [
          BrandMark(size: 30),
          SizedBox(width: 10),
          Text(
            'BANCO PICHINCHA',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
              fontSize: 14,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.help_outline, color: AppColors.primary),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AyudaScreen()),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.person_outline, color: AppColors.primary),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PerfilScreen()),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.notifications_outlined, color: AppColors.primary),
          onPressed: () => HomeShellProvider.of(context)?.switchTab(4),
        ),
      ],
    );
  }

  Widget _buildSaldoCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.18),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
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
      _QuickAction(icon: Icons.payments_outlined, label: 'Enviar', index: 1),
      _QuickAction(icon: Icons.add_circle_outline, label: 'Contratar', index: 2),
      _QuickAction(icon: Icons.account_balance_wallet_outlined, label: 'Cuentas', index: 3),
      _QuickAction(icon: Icons.mail_outline, label: 'Bandeja', index: 4),
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
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
            ),
            child: Icon(a.icon, color: AppColors.primary, size: 28),
          ),
          const SizedBox(height: 6),
          Text(a.label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
        ]),
      ),
    );
  }

  Widget _buildDescubreSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Descubre todo lo que puedes hacer',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 8),
          const Text(
            'Consultas 24/7, pagos de servicios, Yape, Plin e interbancarias.',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          _FeatureBanner(
            title: 'Yape',
            subtitle: 'Envía y recibe dinero desde la app',
            color: const Color(0xFF742284),
            onTap: () => HomeShellProvider.of(context)?.switchTab(1),
          ),
          const SizedBox(height: 8),
          _FeatureBanner(
            title: 'Plin',
            subtitle: 'Transferencias instantáneas a celular',
            color: const Color(0xFF00A19A),
            onTap: () => HomeShellProvider.of(context)?.switchTab(1),
          ),
          const SizedBox(height: 8),
          _FeatureBanner(
            title: 'Interbancarias gratis',
            subtitle: 'Hasta S/ 500 o US\$ 140 desde la app',
            color: AppColors.primary,
            onTap: () => HomeShellProvider.of(context)?.switchTab(1),
          ),
        ],
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

class _QuickAction {
  final IconData icon;
  final String label;
  final int index;
  const _QuickAction({required this.icon, required this.label, required this.index});
}

class _FeatureBanner extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _FeatureBanner({
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.accent.withValues(alpha: 0.2),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.phone_android, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                    Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
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
