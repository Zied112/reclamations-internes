import 'package:flutter/material.dart';
import 'reclamations_tab.dart';
import 'users_tab.dart';
import 'manager_stats_dashboard.dart';
import '../services/api_service.dart';

class ManagerDashboard extends StatefulWidget {
  @override
  _ManagerDashboardState createState() => _ManagerDashboardState();
}

class _ManagerDashboardState extends State<ManagerDashboard> with SingleTickerProviderStateMixin {
  int _selectedPage = 0;
  String? _userName;
  String? _userEmail;
  String? _userRole;
  late TabController _tabController;

  final List<String> _pageTitles = [
    'Dashboard',
    'Réclamations',
    'Utilisateurs',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchUserInfo();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _fetchUserInfo() async {
    String? name = await ApiService.obtenirNomUtilisateurConnecte();
    String? email = await ApiService.obtenirEmailUtilisateurConnecte();
    String? role = await ApiService.obtenirRoleUtilisateurConnecte();
    setState(() {
      _userName = name;
      _userEmail = email;
      _userRole = role;
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget body;
    switch (_selectedPage) {
      case 0:
        body = ManagerStatsDashboard();
        break;
      case 1:
        body = ReclamationsTab();
        break;
      case 2:
        body = UsersTab();
        break;
      default:
        body = ManagerStatsDashboard();
    }

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue.shade50,
              Colors.white,
            ],
          ),
        ),
        child: body,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedPage,
        onTap: (index) {
          setState(() {
            _selectedPage = index;
            _tabController.animateTo(index);
          });
        },
        selectedItemColor: Colors.blue.shade700,
        unselectedItemColor: Colors.grey,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment),
            label: 'Réclamations',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Utilisateurs',
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    bool isSelected = false,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? Colors.blue.shade700 : Colors.grey.shade700,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? Colors.blue.shade700 : Colors.grey.shade800,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      selectedTileColor: Colors.blue.shade50,
      onTap: onTap,
    );
  }
}
