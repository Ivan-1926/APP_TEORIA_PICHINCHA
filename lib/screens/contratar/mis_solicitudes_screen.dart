import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/credit_request_service.dart';
import '../../theme/app_theme.dart';

class MisSolicitudesScreen extends StatefulWidget {
  const MisSolicitudesScreen({super.key});

  @override
  State<MisSolicitudesScreen> createState() => _MisSolicitudesScreenState();
}

class _MisSolicitudesScreenState extends State<MisSolicitudesScreen> {
  bool _loading = true;
  List<Map<String, dynamic>> _rows = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final user = AuthService.currentUser;
      if (user == null || user.documento.isEmpty) {
        setState(() {
          _loading = false;
          _error = 'Inicia sesión para ver tus solicitudes.';
        });
        return;
      }
      final rows = await CreditRequestService.misSolicitudes(user.documento);
      setState(() {
        _rows = rows;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'aprobado':
      case 'desembolsado':
        return Colors.green;
      case 'rechazado':
        return Colors.red;
      case 'comite':
      case 'en_evaluacion':
        return Colors.orange;
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis solicitudes'),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!, textAlign: TextAlign.center))
              : _rows.isEmpty
                  ? const Center(
                      child: Text(
                        'Aún no tienes solicitudes de crédito.\nContrata un producto en la pestaña Productos.',
                        textAlign: TextAlign.center,
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _rows.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (_, i) {
                          final r = _rows[i];
                          final status = r['status']?.toString() ?? 'enviado';
                          final id = r['id']?.toString() ?? '';
                          final expediente =
                              'EXP-${id.replaceAll('-', '').substring(0, id.length.clamp(0, 8)).toUpperCase()}';
                          return Card(
                            child: ListTile(
                              title: Text(
                                r['purpose']?.toString() ?? 'Solicitud de crédito',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(
                                'Expediente: $expediente\n'
                                'Monto: \$${(r['amount'] as num?)?.toStringAsFixed(2) ?? '0'} · '
                                'Plazo: ${r['term_months'] ?? '-'} meses',
                              ),
                              isThreeLine: true,
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _statusColor(status).withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  status.toUpperCase(),
                                  style: TextStyle(
                                    color: _statusColor(status),
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
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
