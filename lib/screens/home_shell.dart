import 'package:flutter/material.dart';
import 'dashboard/dashboard_screen.dart';
import 'enviar_dinero/enviar_dinero_screen.dart';
import 'contratar/contratar_screen.dart';
import 'cuentas/cuentas_hub_screen.dart';
import 'bandeja/bandeja_screen.dart';
import '../services/bank_data_service.dart';
import '../services/user_scope.dart';
import '../widgets/pichincha_nav_bar.dart';

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
    EnviarDineroScreen(),
    ContratarScreen(),
    CuentasHubScreen(),
    BandejaScreen(),
  ];

  void switchTab(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final badge = BankDataService.contarNotificacionesNoLeidas(activeUserId);

    return HomeShellProvider(
      state: this,
      child: Scaffold(
        body: IndexedStack(index: _currentIndex, children: _screens),
        bottomNavigationBar: PichinchaNavBar(
          currentIndex: _currentIndex,
          onTap: switchTab,
          badgeCount: badge,
        ),
      ),
    );
  }
}
