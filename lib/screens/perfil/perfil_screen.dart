import 'package:flutter/material.dart';
import '../../services/bank_data_service.dart';
import '../../services/auth_service.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';

class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  Usuario? _usuario;
  bool _loading = true;
  bool _editing = false;
  bool _saving = false;
  final _celularController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _celularController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final currentId = AuthService.currentUser!.id;
    final user = await BankDataService.getUsuario(currentId);
    setState(() {
      _usuario = user;
      if (user != null) _celularController.text = user.celular;
      _loading = false;
    });
  }

  Future<void> _guardarCelular() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    try {
      final currentId = AuthService.currentUser!.id;
      await BankDataService.actualizarCelular(
        currentId,
        _celularController.text.trim(),
      );
      setState(() {
        _usuario?.celular = _celularController.text.trim();
        _editing = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Celular actualizado correctamente'),
            backgroundColor: AppColors.accentDark,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al actualizar: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mi Perfil')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              color: AppColors.primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      const SizedBox(height: 10),
                      // Avatar Card
                      _buildAvatarCard(),
                      const SizedBox(height: 30),
                      // Fields list
                      _buildProfileField(
                        icon: Icons.person_outline,
                        label: 'Nombre completo',
                        value: _usuario?.nombre ?? '',
                      ),
                      const SizedBox(height: 16),
                      _buildProfileField(
                        icon: Icons.badge_outlined,
                        label: 'Documento de Identidad (DNI)',
                        value: _usuario?.documento ?? '',
                      ),
                      const SizedBox(height: 16),
                      _buildProfileField(
                        icon: Icons.email_outlined,
                        label: 'Correo electrónico',
                        value: _usuario?.email ?? '',
                      ),
                      const SizedBox(height: 16),
                      // Editable cellular field
                      _buildCellularField(),
                      const SizedBox(height: 40),
                      ElevatedButton.icon(
                        onPressed: () async {
                          await AuthService.signOut();
                        },
                        icon: const Icon(Icons.logout, color: Colors.white),
                        label: const Text('Cerrar Sesión Segura'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.error,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildAvatarCard() {
    final ini = _usuario?.nombre.split(' ').map((e) => e[0]).take(2).join('') ?? 'JD';
    return Center(
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: AppColors.primary.withOpacity(0.1),
            child: Text(
              ini,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _usuario?.nombre ?? '',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'Cliente Banco Pichincha',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileField({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCellularField() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _editing ? AppColors.primary : AppColors.divider),
      ),
      child: Row(
        children: [
          const Icon(Icons.phone_android_outlined, color: AppColors.primary, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Número de celular',
                    style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                const SizedBox(height: 4),
                if (_editing)
                  TextFormField(
                    controller: _celularController,
                    keyboardType: TextInputType.phone,
                    autofocus: true,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 4),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) return 'El celular no puede estar vacío';
                      if (val.trim().length < 9) return 'Celular debe tener al menos 9 números';
                      return null;
                    },
                  )
                else
                  Text(
                    _usuario?.celular ?? '',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
              ],
            ),
          ),
          if (_editing) ...[
            if (_saving)
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else ...[
              IconButton(
                icon: const Icon(Icons.check, color: AppColors.accentDark),
                onPressed: _guardarCelular,
              ),
              IconButton(
                icon: const Icon(Icons.close, color: AppColors.error),
                onPressed: () {
                  setState(() {
                    _celularController.text = _usuario?.celular ?? '';
                    _editing = false;
                  });
                },
              ),
            ]
          ] else
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: AppColors.primary),
              onPressed: () => setState(() => _editing = true),
            ),
        ],
      ),
    );
  }
}
