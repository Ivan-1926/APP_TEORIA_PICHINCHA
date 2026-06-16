import 'package:flutter/material.dart';

class CatalogItem {
  final String title;
  final String subtitle;
  final IconData icon;

  const CatalogItem({
    required this.title,
    required this.subtitle,
    required this.icon,
  });
}

class CatalogSection {
  final String title;
  final List<CatalogItem> items;

  const CatalogSection({required this.title, required this.items});
}

const productosCatalog = [
  CatalogSection(
    title: 'Cuentas',
    items: [
      CatalogItem(
        title: 'Cuenta de Ahorros Preferente',
        subtitle: 'Ahorra y haz crecer tu dinero',
        icon: Icons.savings_outlined,
      ),
      CatalogItem(
        title: 'Depósito a Plazo Fijo',
        subtitle: 'Rentabilidad segura para ti',
        icon: Icons.trending_up_outlined,
      ),
      CatalogItem(
        title: 'Otras Cuentas',
        subtitle: 'Opciones para cada necesidad',
        icon: Icons.list_alt_outlined,
      ),
    ],
  ),
  CatalogSection(
    title: 'Préstamos y tarjetas',
    items: [
      CatalogItem(
        title: 'Préstamo con garantía líquida',
        subtitle: 'Tu crédito con más respaldo',
        icon: Icons.payments_outlined,
      ),
      CatalogItem(
        title: 'Crédito por Convenio',
        subtitle: 'Créditos exclusivos para ti',
        icon: Icons.local_offer_outlined,
      ),
      CatalogItem(
        title: 'Tarjeta Diners',
        subtitle: 'Diners Club',
        icon: Icons.credit_card_outlined,
      ),
    ],
  ),
  CatalogSection(
    title: 'Centro Hipotecario',
    items: [
      CatalogItem(
        title: 'Crédito Hipotecario Tradicional',
        subtitle: 'Financia tu casa propia',
        icon: Icons.home_outlined,
      ),
      CatalogItem(
        title: 'Crédito Mi Vivienda',
        subtitle: 'Tu nuevo hogar, más accesible',
        icon: Icons.apartment_outlined,
      ),
      CatalogItem(
        title: 'Crédito Techo Propio',
        subtitle: 'Haz realidad tu casa propia',
        icon: Icons.roofing_outlined,
      ),
      CatalogItem(
        title: 'Cuenta de Ahorros Hipotecario',
        subtitle: 'Financia tu construcción',
        icon: Icons.person_outline,
      ),
      CatalogItem(
        title: 'Crédito Hipotecario Constructor',
        subtitle: 'Remodela tu vivienda',
        icon: Icons.construction_outlined,
      ),
    ],
  ),
];

const serviciosCatalog = [
  CatalogSection(
    title: 'Seguros',
    items: [
      CatalogItem(
        title: 'Oncológico',
        subtitle: 'Respaldo en todo momento',
        icon: Icons.favorite_border,
      ),
      CatalogItem(
        title: 'Accidentes',
        subtitle: 'Cobertura ante imprevistos',
        icon: Icons.healing_outlined,
      ),
      CatalogItem(
        title: 'Financieros',
        subtitle: 'Seguridad para tus finanzas',
        icon: Icons.attach_money,
      ),
      CatalogItem(
        title: 'Vida',
        subtitle: 'Seguridad para tu familia',
        icon: Icons.favorite,
      ),
    ],
  ),
  CatalogSection(
    title: 'Pagos',
    items: [
      CatalogItem(
        title: 'Pago de servicios',
        subtitle: 'Facilita tus pagos frecuentes',
        icon: Icons.lightbulb_outline,
      ),
      CatalogItem(
        title: 'Pago de impuestos',
        subtitle: 'Cumple tus pagos al instante',
        icon: Icons.receipt_long_outlined,
      ),
      CatalogItem(
        title: 'Pago a instituciones',
        subtitle: 'Paga a distintas entidades',
        icon: Icons.account_balance_outlined,
      ),
      CatalogItem(
        title: 'Transferencias interbancarias BCR',
        subtitle: 'Transfiere a bancos locales',
        icon: Icons.swap_horiz,
      ),
      CatalogItem(
        title: 'Transferencias interbancarias CCE',
        subtitle: 'Transfiere rápido y seguro',
        icon: Icons.swap_horiz,
      ),
      CatalogItem(
        title: 'Transferencias internacionales',
        subtitle: 'Envía dinero a cualquier país',
        icon: Icons.flight_outlined,
      ),
    ],
  ),
];

const pagosServicios = [
  'Luz / Electricidad',
  'Agua',
  'Internet y cable',
  'Teléfono fijo',
  'Impuesto predial',
  'SUNAT – tributos',
  'Institución educativa',
  'Tarjeta de crédito otro banco',
];
