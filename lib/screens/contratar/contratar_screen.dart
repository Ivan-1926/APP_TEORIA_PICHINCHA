import 'package:flutter/material.dart';
import '../../data/catalog_data.dart';
import '../../theme/app_theme.dart';
import '../../widgets/product_tile.dart';

class ContratarScreen extends StatefulWidget {
  const ContratarScreen({super.key});

  @override
  State<ContratarScreen> createState() => _ContratarScreenState();
}

class _ContratarScreenState extends State<ContratarScreen> with SingleTickerProviderStateMixin {
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

  void _mostrarSolicitud(CatalogItem item) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(item.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            const SizedBox(height: 8),
            Text(item.subtitle, style: const TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Solicitud de "${item.title}" registrada. Un asesor te contactará.'),
                    backgroundColor: AppColors.primary,
                  ),
                );
              },
              child: const Text('Solicitar producto'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contratar'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.accent,
          indicatorWeight: 3,
          tabs: const [
            Tab(text: 'Productos'),
            Tab(text: 'Servicios'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          ListView(
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Text(
                  'Descubre productos pensados para ti',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
              ),
              for (final section in productosCatalog)
                CatalogSectionView(section: section, onItemTap: _mostrarSolicitud),
              const SizedBox(height: 24),
            ],
          ),
          ListView(
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Text(
                  'Seguros, pagos y más servicios',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
              ),
              for (final section in serviciosCatalog)
                CatalogSectionView(section: section, onItemTap: _mostrarSolicitud),
              const SizedBox(height: 24),
            ],
          ),
        ],
      ),
    );
  }
}
