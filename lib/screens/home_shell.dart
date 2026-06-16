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
  int _badgeCount = 0;

  final List<Widget> _screens = const [
    DashboardScreen(),
    EnviarDineroScreen(),
    ContratarScreen(),
    CuentasHubScreen(),
    BandejaScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _refreshBadge();
  }

  Future<void> _refreshBadge() async {
    final count = await BankDataService.contarNotificacionesNoLeidas(activeUserId);
    if (mounted) setState(() => _badgeCount = count);
  }

  void switchTab(int index) {
    setState(() => _currentIndex = index);
    if (index == 4) _refreshBadge();
  }

  @override
  Widget build(BuildContext context) {
    return HomeShellProvider(
      state: this,
      child: Scaffold(
        body: IndexedStack(index: _currentIndex, children: _screens),
        bottomNavigationBar: PichinchaNavBar(
          currentIndex: _currentIndex,
          onTap: switchTab,
          badgeCount: _badgeCount,
        ),
      ),
    );
  }
}
