import 'package:flutter/material.dart';
import '../../widgets/custom_drawer.dart';
import 'home_screen.dart';
import 'report_issue_screen.dart';
import 'leaderboard_screen.dart';
import 'profile_screen.dart';
import 'solution_dashboard_screen.dart';

class CitizenMainScreen extends StatefulWidget {
  const CitizenMainScreen({super.key});

  @override
  State<CitizenMainScreen> createState() => _CitizenMainScreenState();
}

class _CitizenMainScreenState extends State<CitizenMainScreen> {
  int _currentIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  List<Widget> get _screens => [
    CitizenHomeScreen(onMenuTap: () {
      print('Menu button tapped - opening drawer');
      _scaffoldKey.currentState?.openDrawer();
    }),
    const SolutionDashboardScreen(),
    const LeaderboardScreen(),
    const ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    if (index == 2) {
      // Show report issue screen as a modal instead of navigation (now in middle position)
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const ReportIssueScreen(),
        ),
      );
    } else {
      setState(() {
        // Map navigation indices to screen indices
        if (index == 0) {
          _currentIndex = 0; // Home
        } else if (index == 1) {
          _currentIndex = 1; // Dashboard
        } else if (index == 3) {
          _currentIndex = 2; // Leaderboard
        } else if (index == 4) {
          _currentIndex = 3; // Profile
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: const CustomDrawer(),
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          child: BottomNavigationBar(
            currentIndex: _getNavigationIndex(),
            onTap: _onItemTapped,
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
            selectedItemColor: const Color(0xFF667eea),
            unselectedItemColor: Colors.grey[400],
            selectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
            unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 11,
            ),
            elevation: 0,
            items: [
              BottomNavigationBarItem(
                icon: _buildNavIcon(Icons.home_outlined, 0),
                activeIcon: _buildNavIcon(Icons.home, 0, isActive: true),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: _buildNavIcon(Icons.emoji_events_outlined, 1),
                activeIcon: _buildNavIcon(Icons.emoji_events, 1, isActive: true),
                label: 'Dashboard',
              ),
              BottomNavigationBarItem(
                icon: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF667eea).withOpacity(0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.add,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                label: 'Report',
              ),
              BottomNavigationBarItem(
                icon: _buildNavIcon(Icons.leaderboard_outlined, 2),
                activeIcon: _buildNavIcon(Icons.leaderboard, 2, isActive: true),
                label: 'Leaderboard',
              ),
              BottomNavigationBarItem(
                icon: _buildNavIcon(Icons.person_outline, 3),
                activeIcon: _buildNavIcon(Icons.person, 3, isActive: true),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }

  int _getNavigationIndex() {
    // Map screen index to navigation index
    switch (_currentIndex) {
      case 0:
        return 0; // Home
      case 1:
        return 1; // Dashboard
      case 2:
        return 3; // Leaderboard
      case 3:
        return 4; // Profile
      default:
        return 0;
    }
  }

  Widget _buildNavIcon(IconData icon, int index, {bool isActive = false}) {
    final isSelected = _currentIndex == index;
    
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isSelected 
            ? const Color(0xFF667eea).withOpacity(0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        icon,
        size: 24,
      ),
    );
  }
}

