import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class AyudaScreen extends StatelessWidget {
  const AyudaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ayuda y Contacto')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _ContactCard(
            icon: Icons.phone_in_talk_outlined,
            title: 'Banca Telefónica',
            subtitle: '(01) 510-8000 · 24 horas',
          ),
          _ContactCard(
            icon: Icons.chat_bubble_outline,
            title: 'Chat en línea',
            subtitle: 'Atención de lunes a domingo',
          ),
          _ContactCard(
            icon: Icons.location_on_outlined,
            title: 'Agencias',
            subtitle: 'Encuentra la agencia más cercana',
          ),
          _ContactCard(
            icon: Icons.email_outlined,
            title: 'Correo',
            subtitle: 'atencion@pichincha.com.pe',
          ),
          const SizedBox(height: 24),
          const Text('Preguntas frecuentes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const SizedBox(height: 12),
          ...const [
            _FaqTile(question: '¿Cómo consulto mi saldo?', answer: 'Desde Inicio puedes ver tu saldo total y ocultarlo cuando lo necesites.'),
            _FaqTile(question: '¿Hasta qué hora puedo pagar servicios?', answer: 'Los pagos están disponibles hasta las 10:30 p.m.'),
            _FaqTile(question: '¿Puedo enviar dinero a Yape o Plin?', answer: 'Sí, desde la sección Enviar dinero puedes usar Yape, Plin o transferencias interbancarias.'),
            _FaqTile(question: '¿Cómo bloqueo mi tarjeta?', answer: 'Ve a Cuentas > Mis tarjetas y usa la opción Bloqueo temporal.'),
          ],
        ],
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _ContactCard({required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FaqTile extends StatelessWidget {
  final String question;
  final String answer;

  const _FaqTile({required this.question, required this.answer});

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      title: Text(question, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.textPrimary)),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(answer, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          ),
        ),
      ],
    );
  }
}
