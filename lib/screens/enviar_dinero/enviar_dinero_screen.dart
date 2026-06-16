import 'package:flutter/material.dart';
import '../../services/bank_data_service.dart';
import '../../services/user_scope.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';
import '../../utils/format_utils.dart';
import '../transferencias/transferencias_screen.dart';

class EnviarDineroScreen extends StatefulWidget {
  const EnviarDineroScreen({super.key});

  @override
  State<EnviarDineroScreen> createState() => _EnviarDineroScreenState();
}

class _EnviarDineroScreenState extends State<EnviarDineroScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Enviar dinero')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Descubre todo lo que puedes hacer',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 8),
          const Text(
            'Consultas 24/7, transferencias interbancarias y envíos a billeteras digitales.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 20),
          _WalletCard(
            title: 'Yape',
            subtitle: 'Envía y recibe dinero de Yape. Hazlo en la APP.',
            color: const Color(0xFF742284),
            onTap: () => _abrirFormularioWallet(context, 'Yape'),
          ),
          const SizedBox(height: 12),
          _WalletCard(
            title: 'Plin',
            subtitle: 'Envía y recibe dinero de Plin. Hazlo en la APP.',
            color: const Color(0xFF00A19A),
            onTap: () => _abrirFormularioWallet(context, 'Plin'),
          ),
          const SizedBox(height: 12),
          _WalletCard(
            title: 'Transferencias interbancarias',
            subtitle: 'Gratis hasta S/ 500 o US\$ 140 desde la APP (*)',
            color: AppColors.primary,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const TransferenciasScreen()),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            '(*) Consulta condiciones en transferenciasinterbancarias.pe',
            style: TextStyle(fontSize: 10, color: AppColors.textHint, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }

  void _abrirFormularioWallet(BuildContext context, String wallet) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _WalletForm(wallet: wallet),
    );
  }
}

class _WalletCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _WalletCard({
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.accent.withValues(alpha: 0.25),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.phone_android, color: Colors.white),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                    const SizedBox(height: 4),
                    Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}

class _WalletForm extends StatefulWidget {
  final String wallet;

  const _WalletForm({required this.wallet});

  @override
  State<_WalletForm> createState() => _WalletFormState();
}

class _WalletFormState extends State<_WalletForm> {
  final _formKey = GlobalKey<FormState>();
  final _celularCtrl = TextEditingController();
  final _montoCtrl = TextEditingController();
  final _conceptoCtrl = TextEditingController(text: 'Envío desde app');
  List<CuentaAhorro> _cuentas = [];
  CuentaAhorro? _cuenta;
  bool _loading = true;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _celularCtrl.dispose();
    _montoCtrl.dispose();
    _conceptoCtrl.dispose();
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

  Future<void> _enviar() async {
    if (!_formKey.currentState!.validate() || _cuenta == null) return;
    setState(() => _sending = true);
    final error = await BankDataService.enviarDineroWallet(
      cuentaOrigenId: _cuenta!.id,
      usuarioOrigenId: activeUserId,
      wallet: widget.wallet,
      celularDestino: _celularCtrl.text.trim(),
      monto: double.parse(_montoCtrl.text),
      concepto: _conceptoCtrl.text.trim(),
    );
    if (!mounted) return;
    setState(() => _sending = false);
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error), backgroundColor: AppColors.error));
    } else {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Envío a ${widget.wallet} realizado correctamente'),
          backgroundColor: AppColors.positive,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottom),
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Enviar con ${widget.wallet}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<CuentaAhorro>(
                    value: _cuenta,
                    decoration: const InputDecoration(labelText: 'Cuenta origen'),
                    items: _cuentas
                        .map((c) => DropdownMenuItem(
                              value: c,
                              child: Text('${c.tipo} - ${FormatUtils.formatCurrency(c.saldo)}'),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => _cuenta = v),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _celularCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(labelText: 'Celular destino (${widget.wallet})'),
                    validator: (v) => (v == null || v.length < 9) ? 'Ingresa un celular válido' : null,
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
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _conceptoCtrl,
                    decoration: const InputDecoration(labelText: 'Concepto'),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _sending ? null : _enviar,
                    child: _sending
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : Text('Enviar con ${widget.wallet}'),
                  ),
                ],
              ),
            ),
    );
  }
}
