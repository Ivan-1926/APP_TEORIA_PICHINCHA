import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/bank_data_service.dart';
import '../../services/user_scope.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';
import '../../utils/format_utils.dart';
import '../../widgets/brand_logo.dart';

class TarjetasScreen extends StatefulWidget {
  const TarjetasScreen({super.key});

  @override
  State<TarjetasScreen> createState() => _TarjetasScreenState();
}

class _TarjetasScreenState extends State<TarjetasScreen> {
  final PageController _pageController = PageController(viewportFraction: 0.88);

  List<TarjetaDebito> _tarjetas = [];
  List<MovimientoTarjeta> _movimientos = [];
  String _titular = 'TITULAR';
  bool _loading = true;
  int _cardIndex = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final tarjetas = await BankDataService.getTarjetas(activeUserId);
    final usuario = AuthService.currentUser ?? await BankDataService.getUsuario(activeUserId);
    List<MovimientoTarjeta> movs = [];
    if (tarjetas.isNotEmpty) {
      movs = await BankDataService.getMovimientosTarjeta(tarjetas.first.id);
    }
    if (!mounted) return;
    setState(() {
      _tarjetas = tarjetas;
      _movimientos = movs;
      _titular = (usuario?.nombre ?? 'Titular').toUpperCase();
      _loading = false;
    });
  }

  Future<void> _onCardChanged(int index) async {
    if (index == _cardIndex || index >= _tarjetas.length) return;
    setState(() => _cardIndex = index);
    final movs = await BankDataService.getMovimientosTarjeta(_tarjetas[index].id);
    if (!mounted) return;
    setState(() => _movimientos = movs);
  }

  TarjetaDebito get _tarjetaActual =>
      _tarjetas[_cardIndex.clamp(0, _tarjetas.length - 1)];

  Future<void> _toggleBloqueo(TarjetaDebito tarjeta) async {
    await BankDataService.toggleBloqueoTarjeta(tarjeta.id, !tarjeta.bloqueada);
    setState(() => tarjeta.bloqueada = !tarjeta.bloqueada);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          tarjeta.bloqueada ? 'Tarjeta bloqueada temporalmente' : 'Tarjeta desbloqueada',
        ),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  void _consultarPin(TarjetaDebito tarjeta) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Consultar PIN'),
        content: Text(
          tarjeta.bloqueada
              ? 'Desbloquea la tarjeta para consultar el PIN.'
              : 'Por seguridad, tu PIN fue enviado por SMS al celular registrado.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cerrar')),
        ],
      ),
    );
  }

  void _masOpciones(TarjetaDebito tarjeta) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.info_outline, color: AppColors.primary),
              title: const Text('Información de la tarjeta'),
              subtitle: Text('${tarjeta.tipo} ${tarjeta.numeroEnmascarado}'),
              onTap: () => Navigator.pop(ctx),
            ),
            ListTile(
              leading: const Icon(Icons.receipt_long_outlined, color: AppColors.primary),
              title: const Text('Estado de cuenta'),
              onTap: () => Navigator.pop(ctx),
            ),
            ListTile(
              leading: const Icon(Icons.support_agent_outlined, color: AppColors.primary),
              title: const Text('Solicitar reposición'),
              onTap: () => Navigator.pop(ctx),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: AppColors.primary,
        appBar: _buildAppBar('Mis tarjetas', ''),
        body: const Center(child: CircularProgressIndicator(color: AppColors.accent)),
      );
    }

    if (_tarjetas.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Mis tarjetas')),
        body: const Center(child: Text('No tienes tarjetas activas.')),
      );
    }

    final tarjeta = _tarjetaActual;

    return Scaffold(
      backgroundColor: AppColors.primary,
      appBar: _buildAppBar('Mis tarjetas', '${tarjeta.tipo} ${tarjeta.numeroEnmascarado}'),
      body: Column(
        children: [
          const SizedBox(height: 8),
          SizedBox(
            height: 210,
            child: PageView.builder(
              controller: _pageController,
              itemCount: _tarjetas.length,
              onPageChanged: _onCardChanged,
              itemBuilder: (context, index) {
                return AnimatedScale(
                  scale: index == _cardIndex ? 1.0 : 0.94,
                  duration: const Duration(milliseconds: 250),
                  child: _DebitCardView(
                    tarjeta: _tarjetas[index],
                    titular: _titular,
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                children: [
                  if (_tarjetas.length > 1)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        _tarjetas.length,
                        (i) => AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: i == _cardIndex ? 10 : 8,
                          height: i == _cardIndex ? 10 : 8,
                          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 0).copyWith(bottom: 20),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: i == _cardIndex ? AppColors.primary : const Color(0xFFD1D5DB),
                          ),
                        ),
                      ),
                    ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _CardActionButton(
                        icon: Icons.credit_card_off_outlined,
                        label: 'Bloqueo\ntemporal',
                        onTap: () => _toggleBloqueo(tarjeta),
                      ),
                      _CardActionButton(
                        icon: Icons.visibility_outlined,
                        label: 'Consultar\nPIN',
                        onTap: () => _consultarPin(tarjeta),
                      ),
                      _CardActionButton(
                        icon: Icons.more_horiz,
                        label: 'Más info y\nopciones',
                        onTap: () => _masOpciones(tarjeta),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Movimientos',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                      IconButton(icon: const Icon(Icons.tune), onPressed: () {}),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (_movimientos.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(child: Text('Sin movimientos recientes')),
                    )
                  else
                    ..._buildMovimientosAgrupados(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(String title, String subtitle) {
    return AppBar(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.maybePop(context),
      ),
      title: Column(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          if (subtitle.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.white70,
              ),
            ),
          ],
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.menu, color: Colors.white),
          onPressed: () {},
        ),
      ],
    );
  }

  List<Widget> _buildMovimientosAgrupados() {
    final grouped = <String, List<MovimientoTarjeta>>{};
    for (final m in _movimientos) {
      final key = FormatUtils.formatDateShort(m.fecha);
      grouped.putIfAbsent(key, () => []).add(m);
    }
    final widgets = <Widget>[];
    grouped.forEach((fecha, items) {
      widgets.add(Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 4),
        child: Text(
          fecha,
          style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary),
        ),
      ));
      for (final m in items) {
        widgets.add(ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.surfaceMuted,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.credit_card, size: 18, color: AppColors.primary),
          ),
          title: Text(m.comercio, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          subtitle: Text(m.descripcion, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          trailing: Text(
            FormatUtils.formatCurrency(m.monto.abs()),
            style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          ),
        ));
      }
    });
    return widgets;
  }
}

class _DebitCardView extends StatelessWidget {
  final TarjetaDebito tarjeta;
  final String titular;

  const _DebitCardView({required this.tarjeta, required this.titular});

  String get _numeroFormateado {
    final ultimos = tarjeta.numeroEnmascarado.replaceAll('*', '').replaceAll(' ', '');
    if (ultimos.isEmpty) return '.... .... .... ....';
    return '.... .... .... $ultimos';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.accent,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 20, 22, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const BrandMark(size: 28),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'BANCO PICHINCHA',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 11,
                          color: AppColors.primary,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                    Text(
                      'Débito',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        color: AppColors.primary.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Row(
                  children: [
                    _EmvChip(),
                    const SizedBox(width: 14),
                    Icon(Icons.contactless, color: AppColors.primary.withValues(alpha: 0.9), size: 30),
                    const SizedBox(width: 6),
                    Text(
                      'PERÚ',
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary.withValues(alpha: 0.55),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  _numeroFormateado,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 17,
                    color: AppColors.primary,
                    letterSpacing: 2.2,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Text(
                        titular,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                          color: AppColors.primary,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    const Text(
                      'VISA',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        fontStyle: FontStyle.italic,
                        color: AppColors.primary,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (tarjeta.bloqueada)
            Container(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.lock_outline, color: Colors.white, size: 44),
                    SizedBox(height: 8),
                    Text(
                      'Bloqueada temporalmente',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _EmvChip extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 32,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.amber.shade200,
            Colors.amber.shade400,
            Colors.amber.shade600,
          ],
        ),
        border: Border.all(color: Colors.amber.shade800.withValues(alpha: 0.35)),
      ),
      child: CustomPaint(painter: _ChipLinesPainter()),
    );
  }
}

class _ChipLinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.amber.shade800.withValues(alpha: 0.25)
      ..strokeWidth = 0.8;
    for (var i = 1; i < 4; i++) {
      final y = size.height * i / 4;
      canvas.drawLine(Offset(4, y), Offset(size.width - 4, y), paint);
    }
    for (var i = 1; i < 3; i++) {
      final x = size.width * i / 3;
      canvas.drawLine(Offset(x, 4), Offset(x, size.height - 4), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CardActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _CardActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        width: 100,
        child: Column(
          children: [
            Container(
              width: 62,
              height: 62,
              decoration: BoxDecoration(
                color: AppColors.accent,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accent.withValues(alpha: 0.45),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(icon, color: AppColors.primary, size: 28),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                height: 1.25,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
