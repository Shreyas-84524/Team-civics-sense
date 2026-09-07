import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/repositories/notification_repository.dart';
import 'hazard_map_screen.dart';
import 'home_screen.dart';
import 'my_complaints_screen.dart';
import 'notifications_screen.dart';
import 'profile_screen.dart';

/// Main Shell holding the 5 Citizen Bottom Navigation tabs.
class MainNavigationScreen extends StatefulWidget {
  final int initialIndex;

  const MainNavigationScreen({super.key, this.initialIndex = 0});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  late int _currentIndex;
  final NotificationRepository _notificationRepository = MockNotificationRepository();

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _notificationRepository.getUnreadCount();
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomeScreen(onTabChange: _onTabTapped),
      const MyComplaintsScreen(),
      const HazardMapScreen(),
      const NotificationsScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: ValueListenableBuilder<int>(
        valueListenable: _notificationRepository.unreadCountListenable,
        builder: (context, unreadCount, _) {
          return Container(
            decoration: BoxDecoration(
              color: CivicFixColors.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 10,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: _onTabTapped,
              type: BottomNavigationBarType.fixed,
              backgroundColor: CivicFixColors.surface,
              selectedItemColor: CivicFixColors.primary,
              unselectedItemColor: CivicFixColors.secondaryText,
              selectedFontSize: 12,
              unselectedFontSize: 12,
              items: [
                const BottomNavigationBarItem(
                  icon: Icon(Icons.home_outlined),
                  activeIcon: Icon(Icons.home_rounded),
                  label: 'Home',
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.assignment_outlined),
                  activeIcon: Icon(Icons.assignment_rounded),
                  label: 'Complaints',
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.map_outlined),
                  activeIcon: Icon(Icons.map_rounded),
                  label: 'Map',
                ),
                BottomNavigationBarItem(
                  icon: Badge(
                    isLabelVisible: unreadCount > 0,
                    label: Text('$unreadCount'),
                    backgroundColor: CivicFixColors.alertDark,
                    child: const Icon(Icons.notifications_outlined),
                  ),
                  activeIcon: Badge(
                    isLabelVisible: unreadCount > 0,
                    label: Text('$unreadCount'),
                    backgroundColor: CivicFixColors.alertDark,
                    child: const Icon(Icons.notifications_rounded),
                  ),
                  label: 'Notifications',
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.person_outline_rounded),
                  activeIcon: Icon(Icons.person_rounded),
                  label: 'Profile',
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
