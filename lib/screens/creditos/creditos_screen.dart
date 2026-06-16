import 'package:flutter/material.dart';
import '../../services/bank_data_service.dart';
import '../../services/user_scope.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';
import '../../utils/format_utils.dart';

class CreditosScreen extends StatefulWidget {
  const CreditosScreen({super.key});

  @override
  State<CreditosScreen> createState() => _CreditosScreenState();
}

class _CreditosScreenState extends State<CreditosScreen> {
  List<Credito> _creditos = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final creditos = await BankDataService.getCreditos(activeUserId);
    setState(() {
      _creditos = creditos;
      _loading = false;
    });
  }

  void _mostrarCronograma(Credito credito) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CronogramaSheet(credito: credito),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mis Créditos')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              color: AppColors.primary,
              child: _creditos.isEmpty
                  ? const Center(child: Text('No tienes créditos activos.'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _creditos.length,
                      itemBuilder: (context, index) {
                        final credito = _creditos[index];
                        final pagadoEstimado = credito.montoOriginal - credito.saldoPendiente;
                        final proc = (pagadoEstimado / credito.montoOriginal).clamp(0.0, 1.0);

                        return Card(
                          margin: const EdgeInsets.only(bottom: 16),
                          elevation: 2,
                          shadowColor: Colors.black12,
                          child: InkWell(
                            onTap: () => _mostrarCronograma(credito),
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
                                              color: Colors.deepPurple.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: const Icon(Icons.credit_score,
                                                color: Colors.deepPurple, size: 24),
                                          ),
                                          const SizedBox(width: 12),
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(credito.descripcion,
                                                  style: const TextStyle(
                                                      fontSize: 16, fontWeight: FontWeight.bold)),
                                              const SizedBox(height: 2),
                                              Text('Tasa TEA: ${credito.tasaInteres}%',
                                                  style: const TextStyle(
                                                      fontSize: 12, color: AppColors.textSecondary)),
                                              if (credito.espejoCore) ...[
                                                const SizedBox(height: 4),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: AppColors.accent.withValues(alpha: 0.35),
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                  child: const Text(
                                                    'Originado Fuerza de Ventas',
                                                    style: TextStyle(
                                                      fontSize: 9,
                                                      fontWeight: FontWeight.w700,
                                                      color: AppColors.primary,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ],
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          '${credito.plazoMeses} meses',
                                          style: const TextStyle(
                                              color: AppColors.primary,
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  // Progress indicator
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text('Progreso de pago',
                                          style: TextStyle(
                                              fontSize: 12, color: AppColors.textSecondary)),
                                      Text('${(proc * 100).toStringAsFixed(0)}%',
                                          style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.primary)),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: proc,
                                      backgroundColor: AppColors.divider,
                                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                                      minHeight: 6,
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  const Divider(),
                                  const SizedBox(height: 16),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      _buildMontoCol('Monto Original', FormatUtils.formatCurrency(credito.montoOriginal)),
                                      _buildMontoCol('Saldo Pendiente', FormatUtils.formatCurrency(credito.saldoPendiente),
                                          highlight: true),
                                      _buildMontoCol('Cuota Mensual', FormatUtils.formatCurrency(credito.cuotaMensual)),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton.icon(
                                      onPressed: () => _mostrarCronograma(credito),
                                      icon: const Icon(Icons.calendar_month, size: 16),
                                      label: const Text('Ver Cronograma', style: TextStyle(fontSize: 13)),
                                    ),
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

  Widget _buildMontoCol(String label, String value, {bool highlight = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: highlight ? AppColors.error : AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

// ─── BOTTOM SHEET: CRONOGRAMA DE PAGOS (AMORTIZACIÓN) ─────────────────────────

class _CronogramaSheet extends StatefulWidget {
  final Credito credito;

  const _CronogramaSheet({required this.credito});

  @override
  State<_CronogramaSheet> createState() => _CronogramaSheetState();
}

class _CronogramaSheetState extends State<_CronogramaSheet> {
  List<Cuota> _cuotas = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final cuotas = await BankDataService.getCuotas(widget.credito.id);
    setState(() {
      _cuotas = cuotas;
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
                  const Text('Cronograma de Pagos',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(),
            // Summary Card
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(widget.credito.descripcion,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      Text('Tasa TEA: ${widget.credito.tasaInteres}%',
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Cuota mensual: ${FormatUtils.formatCurrency(widget.credito.cuotaMensual)}',
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      Text(
                          'Pendiente: ${_cuotas.where((c) => !c.pagada).length}/${widget.credito.plazoMeses} cuotas',
                          style: const TextStyle(color: AppColors.error, fontSize: 13, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ],
              ),
            ),
            // Payments timeline/list
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _cuotas.isEmpty
                      ? const Center(child: Text('Cronograma no generado.'))
                      : ListView.builder(
                          controller: controller,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          itemCount: _cuotas.length,
                          itemBuilder: (context, index) {
                            final cuota = _cuotas[index];
                            return Card(
                              color: Colors.white,
                              elevation: 0.5,
                              margin: const EdgeInsets.only(bottom: 12),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(
                                      color: cuota.pagada
                                          ? AppColors.accent.withOpacity(0.2)
                                          : AppColors.divider)),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            CircleAvatar(
                                              radius: 12,
                                              backgroundColor: cuota.pagada
                                                  ? AppColors.accent.withOpacity(0.1)
                                                  : AppColors.textHint.withOpacity(0.1),
                                              child: Text(
                                                '${cuota.numeroCuota}',
                                                style: TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.bold,
                                                    color: cuota.pagada
                                                        ? AppColors.accentDark
                                                        : AppColors.textSecondary),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              'Vence: ${FormatUtils.formatDate(cuota.fechaVencimiento)}',
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold, fontSize: 13),
                                            ),
                                          ],
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: cuota.pagada
                                                ? AppColors.accent.withOpacity(0.1)
                                                : AppColors.error.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            cuota.pagada ? 'PAGADA' : 'PENDIENTE',
                                            style: TextStyle(
                                                color: cuota.pagada
                                                    ? AppColors.accentDark
                                                    : AppColors.error,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    const Divider(),
                                    const SizedBox(height: 10),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        _buildCuotaMontoCol('Capital', FormatUtils.formatCurrency(cuota.capital)),
                                        _buildCuotaMontoCol('Interés', FormatUtils.formatCurrency(cuota.interes)),
                                        _buildCuotaMontoCol('Saldo rest.', FormatUtils.formatCurrency(cuota.saldoRestante)),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            const Text('Total Cuota',
                                                style: TextStyle(
                                                    fontSize: 10, color: AppColors.textSecondary)),
                                            const SizedBox(height: 2),
                                            Text(FormatUtils.formatCurrency(cuota.montoCuota),
                                                style: const TextStyle(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.bold,
                                                    color: AppColors.primary)),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
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

  Widget _buildCuotaMontoCol(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
      ],
    );
  }
}
