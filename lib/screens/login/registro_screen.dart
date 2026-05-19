import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';

class RegistroScreen extends StatefulWidget {
  const RegistroScreen({super.key});

  @override
  State<RegistroScreen> createState() => _RegistroScreenState();
}

class _RegistroScreenState extends State<RegistroScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _docController = TextEditingController();
  final _celularController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscureText = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nombreController.dispose();
    _docController.dispose();
    _celularController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final error = await AuthService.signUp(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      nombre: _nombreController.text.trim(),
      documento: _docController.text.trim(),
      celular: _celularController.text.trim(),
    );

    if (mounted) {
      setState(() {
        _isLoading = false;
        _errorMessage = error;
      });

      if (error == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Cuenta creada con éxito! Bienvenido(a).'),
            backgroundColor: AppColors.accent,
          ),
        );
        Navigator.pop(context); // Volver al Login
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registro de Cliente'),
        elevation: 0,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Container(
        color: AppColors.background,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(
                  Icons.person_add_outlined,
                  size: 64,
                  color: AppColors.primary,
                ),
                const SizedBox(height: 16),
                const Center(
                  child: Text(
                    'Únete a Banco Pichincha',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Center(
                  child: Text(
                    'Crea una cuenta en segundos para simular tus finanzas.',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 32),

                // Caja de Alerta de Error
                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.error.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: AppColors.error, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(color: AppColors.error, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Nombre Completo
                TextFormField(
                  controller: _nombreController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre y Apellidos Completos',
                    prefixIcon: Icon(Icons.badge_outlined),
                    hintText: 'Ej. Juan Pérez Rodríguez',
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Ingrese su nombre completo';
                    if (val.trim().split(' ').length < 2) return 'Ingrese nombre y al menos un apellido';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // DNI / Documento
                TextFormField(
                  controller: _docController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Documento de Identidad (DNI)',
                    prefixIcon: Icon(Icons.credit_card_outlined),
                    hintText: '8 dígitos',
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Ingrese su DNI';
                    if (val.trim().length != 8) return 'El DNI debe tener exactamente 8 dígitos';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Celular
                TextFormField(
                  controller: _celularController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Número de Celular',
                    prefixIcon: Icon(Icons.phone_android_outlined),
                    hintText: 'Ej. 987654321',
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Ingrese su número celular';
                    if (val.trim().length != 9) return 'El celular debe tener 9 dígitos';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Correo Electrónico
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Correo Electrónico',
                    prefixIcon: Icon(Icons.email_outlined),
                    hintText: 'ejemplo@correo.com',
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Ingrese su correo';
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(val.trim())) {
                      return 'Ingrese un correo válido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Contraseña
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscureText,
                  decoration: InputDecoration(
                    labelText: 'Contraseña de Acceso',
                    prefixIcon: const Icon(Icons.lock_outline),
                    hintText: 'Mínimo 6 caracteres',
                    suffixIcon: IconButton(
                      icon: Icon(_obscureText ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => _obscureText = !_obscureText),
                    ),
                  ),
                  validator: (val) {
                    if (val == null || val.isEmpty) return 'Ingrese su contraseña';
                    if (val.length < 6) return 'Debe tener al menos 6 caracteres';
                    return null;
                  },
                ),
                const SizedBox(height: 32),

                // Registrarse Button
                ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('Completar Registro'),
                ),
                const SizedBox(height: 24),
                
                // Nota informativa corporativa
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, color: AppColors.accentDark, size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Nota: Al registrarte, recibirás automáticamente un saldo de bienvenida de S/ 5,000.00 en tu Cuenta de Ahorros y S/ 1,000.00 en tu Cuenta Corriente para tus simulaciones.',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 11, fontStyle: FontStyle.italic),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
