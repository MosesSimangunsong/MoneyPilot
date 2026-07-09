import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/theme/app_colors.dart';

class MainShellScreen extends StatelessWidget {
  const MainShellScreen({
    super.key,
    required this.navigationShell,
  });

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: DecoratedBox(
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: AppColors.border),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: navigationShell.currentIndex,
          onTap: (int index) {
            navigationShell.goBranch(
              index,
              initialLocation: index == navigationShell.currentIndex,
            );
          },
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(LucideIcons.house),
              label: 'Beranda',
            ),
            BottomNavigationBarItem(
              icon: Icon(LucideIcons.newspaper),
              label: 'Berita',
            ),
            BottomNavigationBarItem(
              icon: Icon(LucideIcons.wallet),
              label: 'Keuangan',
            ),
            BottomNavigationBarItem(
              icon: Icon(LucideIcons.lineChart),
              label: 'Portofolio',
            ),
            BottomNavigationBarItem(
              icon: Icon(LucideIcons.brainCircuit),
              label: 'Analisis',
            ),
          ],
        ),
      ),
    );
  }
}
