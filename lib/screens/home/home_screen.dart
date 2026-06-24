import 'package:flutter/material.dart';

import '../../routes/app_routes.dart';
import '../../widgets/floating_navbar.dart';
import 'start_driving_screen.dart';
import 'trip_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  static const _pages = [StartDrivingScreen(), TripScreen()];

  void _goToProfile() {
    Navigator.of(context).pushNamed(AppRoutes.profile);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        title: const Text('NG-DAS'),
        actions: [
          Tooltip(
            message: 'Profile',
            child: IconButton(
              onPressed: _goToProfile,
              icon: const Icon(Icons.account_circle_outlined),
            ),
          ),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 280),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        child: KeyedSubtree(
          key: ValueKey(_currentIndex),
          child: _pages[_currentIndex],
        ),
      ),
      bottomNavigationBar: FloatingNavBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          FloatingNavBarItem(
            icon: Icons.play_circle_outline,
            label: 'Start Driving',
          ),
          FloatingNavBarItem(icon: Icons.route, label: 'Trips'),
        ],
      ),
    );
  }
}
