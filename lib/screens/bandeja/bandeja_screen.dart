import 'package:flutter/material.dart';
import '../../services/bank_data_service.dart';
import '../../services/user_scope.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';
import '../../utils/format_utils.dart';

class BandejaScreen extends StatefulWidget {
  const BandejaScreen({super.key});

  @override
  State<BandejaScreen> createState() => _BandejaScreenState();
}

class _BandejaScreenState extends State<BandejaScreen> {
  List<Notificacion> _notificaciones = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final items = await BankDataService.getNotificaciones(activeUserId);
    setState(() {
      _notificaciones = items;
      _loading = false;
    });
  }

  Future<void> _abrir(Notificacion n) async {
    await BankDataService.marcarNotificacionLeida(n.id);
    setState(() => n.leida = true);
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(n.titulo),
        content: Text(n.mensaje),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cerrar')),
        ],
      ),
    );
  }

  IconData _iconoPorTipo(String tipo) {
    switch (tipo) {
      case 'credito':
        return Icons.check_circle_outline;
      case 'transferencia':
        return Icons.swap_horiz;
      case 'pago':
        return Icons.receipt_long_outlined;
      case 'promo':
        return Icons.campaign_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bandeja'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _notificaciones.isEmpty
              ? const Center(child: Text('No tienes mensajes.'))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _notificaciones.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final n = _notificaciones[i];
                      return Material(
                        color: n.leida ? AppColors.surface : AppColors.accent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(14),
                        child: InkWell(
                          onTap: () => _abrir(n),
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.divider),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceMuted,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(_iconoPorTipo(n.tipo), color: AppColors.primary, size: 20),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        n.titulo,
                                        style: TextStyle(
                                          fontWeight: n.leida ? FontWeight.w600 : FontWeight.w700,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        n.mensaje,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        FormatUtils.formatDateShort(n.fecha),
                                        style: const TextStyle(fontSize: 11, color: AppColors.textHint),
                                      ),
                                    ],
                                  ),
                                ),
                                if (!n.leida)
                                  Container(
                                    width: 8,
                                    height: 8,
                                    margin: const EdgeInsets.only(top: 4),
                                    decoration: const BoxDecoration(color: AppColors.accentDark, shape: BoxShape.circle),
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
