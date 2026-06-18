import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../data/catalog_data.dart';
import '../../services/auth_service.dart';
import '../../services/credit_request_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/product_tile.dart';
import 'mis_solicitudes_screen.dart';

class ContratarScreen extends StatefulWidget {
  const ContratarScreen({super.key});

  @override
  State<ContratarScreen> createState() => _ContratarScreenState();
}

class _ContratarScreenState extends State<ContratarScreen>
    with SingleTickerProviderStateMixin {
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

  bool _esCredito(CatalogItem item) {
    final t = '${item.title} ${item.subtitle}'.toLowerCase();
    return t.contains('crédito') ||
        t.contains('credito') ||
        t.contains('préstamo') ||
        t.contains('prestamo') ||
        t.contains('hipotec');
  }

  void _mostrarSolicitud(CatalogItem item) {
    if (_esCredito(item)) {
      _mostrarFormularioCredito(item);
    } else {
      _mostrarSolicitudSimple(item);
    }
  }

  void _mostrarSolicitudSimple(CatalogItem item) {
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
            Text(item.title,
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 8),
            Text(item.subtitle,
                style: const TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        'Interés registrado en "${item.title}". Un asesor te contactará.'),
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

  void _mostrarFormularioCredito(CatalogItem item) {
    final user = AuthService.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes iniciar sesión para solicitar crédito.')),
      );
      return;
    }

    final montoCtrl = TextEditingController(text: '5000');
    final plazoCtrl = TextEditingController(text: '12');
    final destinoCtrl = TextEditingController(text: 'Capital de trabajo');
    final garantiaCtrl = TextEditingController(text: 'Cuenta de ahorros');
    final formKey = GlobalKey<FormState>();
    var enviando = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(item.title,
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary)),
                  const SizedBox(height: 4),
                  Text('Canal: App Cliente · Estado inicial: enviado',
                      style: TextStyle(
                          color: AppColors.textSecondary.withOpacity(0.9),
                          fontSize: 12)),
                  const SizedBox(height: 16),
                  TextFormField(
                    initialValue: user.nombre,
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: 'Cliente',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    initialValue: user.documento,
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: 'DNI',
                      prefixIcon: Icon(Icons.badge_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: montoCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      labelText: 'Monto solicitado (USD) *',
                      prefixIcon: Icon(Icons.attach_money),
                    ),
                    validator: (v) {
                      final n = double.tryParse(v ?? '');
                      if (n == null || n < 500) return 'Mínimo \$500';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: plazoCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      labelText: 'Plazo (meses) *',
                      prefixIcon: Icon(Icons.calendar_month_outlined),
                    ),
                    validator: (v) {
                      final n = int.tryParse(v ?? '');
                      if (n == null || n < 3 || n > 60) {
                        return 'Plazo entre 3 y 60 meses';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: destinoCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Destino del crédito *',
                      prefixIcon: Icon(Icons.flag_outlined),
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Indica el destino' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: garantiaCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Garantía',
                      prefixIcon: Icon(Icons.security_outlined),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: enviando
                        ? null
                        : () async {
                            if (!formKey.currentState!.validate()) return;
                            setSheetState(() => enviando = true);
                            try {
                              final monto = double.parse(montoCtrl.text);
                              final plazo = int.parse(plazoCtrl.text);
                              final result = await CreditRequestService.enviar(
                                documento: user.documento,
                                nombre: user.nombre,
                                producto: item.title,
                                monto: monto,
                                plazoMeses: plazo,
                                destino: destinoCtrl.text.trim(),
                                garantia: garantiaCtrl.text.trim(),
                              );
                              if (!ctx.mounted) return;
                              Navigator.pop(ctx);
                              showDialog(
                                context: context,
                                builder: (dCtx) => AlertDialog(
                                  title: const Text('Solicitud registrada'),
                                  content: Text(
                                    'Tu expediente ${result.expediente} fue enviado.\n\n'
                                    'Estado: ${result.status}\n'
                                    'Un asesor de Fuerza de Ventas evaluará tu solicitud '
                                    'y el comité decidirá la aprobación.',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(dCtx),
                                      child: const Text('Entendido'),
                                    ),
                                  ],
                                ),
                              );
                            } catch (e) {
                              setSheetState(() => enviando = false);
                              if (ctx.mounted) {
                                ScaffoldMessenger.of(ctx).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                        'Error al registrar: ${e.toString().replaceAll('Exception:', '').trim()}'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          },
                    child: enviando
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Enviar solicitud de crédito'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contratar'),
        actions: [
          IconButton(
            tooltip: 'Mis solicitudes',
            icon: const Icon(Icons.description_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MisSolicitudesScreen()),
            ),
          ),
        ],
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
                  'Solicita créditos desde la app. El asesor y el comité evaluarán tu expediente.',
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
