import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../ahorros/ahorros_screen.dart';
import '../creditos/creditos_screen.dart';
import '../tarjetas/tarjetas_screen.dart';
import '../pagos/pagos_screen.dart';

class CuentasHubScreen extends StatelessWidget {
  const CuentasHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final items = [
      _HubItem(
        icon: Icons.savings_outlined,
        title: 'Mis cuentas',
        subtitle: 'Ahorros, corriente y movimientos',
        screen: const AhorrosScreen(),
      ),
      _HubItem(
        icon: Icons.credit_score_outlined,
        title: 'Mis créditos',
        subtitle: 'Préstamos y cronograma de pagos',
        screen: const CreditosScreen(),
      ),
      _HubItem(
        icon: Icons.credit_card_outlined,
        title: 'Mis tarjetas',
        subtitle: 'Débito, bloqueo y movimientos',
        screen: const TarjetasScreen(),
      ),
      _HubItem(
        icon: Icons.receipt_long_outlined,
        title: 'Pagos',
        subtitle: 'Servicios, impuestos e instituciones',
        screen: const PagosScreen(),
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Cuentas')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final item = items[index];
          return Material(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => item.screen),
              ),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceMuted,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(item.icon, color: AppColors.primary),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.title, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                          const SizedBox(height: 4),
                          Text(item.subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: AppColors.textSecondary),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _HubItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget screen;

  const _HubItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.screen,
  });
}
