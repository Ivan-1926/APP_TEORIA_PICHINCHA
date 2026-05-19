import 'package:flutter/material.dart';
import 'dashboard/dashboard_screen.dart';
import 'ahorros/ahorros_screen.dart';
import 'creditos/creditos_screen.dart';
import 'transferencias/transferencias_screen.dart';
import 'perfil/perfil_screen.dart';

class HomeShellProvider extends InheritedWidget {
  final HomeShellState state;

  const HomeShellProvider({
    super.key,
    required this.state,
    required super.child,
  });

  static HomeShellState? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<HomeShellProvider>()?.state;
  }

  @override
  bool updateShouldNotify(HomeShellProvider oldWidget) => true;
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => HomeShellState();
}

class HomeShellState extends State<HomeShell> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    DashboardScreen(),
    AhorrosScreen(),
    CreditosScreen(),
    TransferenciasScreen(),
    PerfilScreen(),
  ];

  void switchTab(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return HomeShellProvider(
      state: this,
      child: Scaffold(
        body: IndexedStack(index: _currentIndex, children: _screens),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: switchTab,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Inicio'),
            BottomNavigationBarItem(icon: Icon(Icons.savings_outlined), activeIcon: Icon(Icons.savings), label: 'Ahorros'),
            BottomNavigationBarItem(icon: Icon(Icons.credit_card_outlined), activeIcon: Icon(Icons.credit_card), label: 'Créditos'),
            BottomNavigationBarItem(icon: Icon(Icons.swap_horiz_outlined), activeIcon: Icon(Icons.swap_horiz), label: 'Transferir'),
            BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Perfil'),
          ],
        ),
      ),
    );
  }
}
