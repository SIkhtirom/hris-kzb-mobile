import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../viewmodels/dashboard_viewmodel.dart';
import '../documents/document_hub_screen.dart';
import '../home/home_screen.dart';
import '../more/more_screen.dart';

class MainShell extends StatefulWidget {
  final VoidCallback? onLoggedOut;

  const MainShell({super.key, this.onLoggedOut});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      const HomeScreen(),
      const DocumentHubScreen(),
      MoreScreen(onLoggedOut: widget.onLoggedOut),
    ];

    return Scaffold(
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: DecoratedBox(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (value) {
            setState(() => _index = value);
            if (value == 0) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                context.read<DashboardViewModel>().refreshUser();
              });
            }
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: AppStrings.navHome,
            ),
            NavigationDestination(
              icon: Icon(Icons.description_outlined),
              selectedIcon: Icon(Icons.description),
              label: AppStrings.navDocuments,
            ),
            NavigationDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings),
              label: AppStrings.navMore,
            ),
          ],
        ),
      ),
    );
  }
}
