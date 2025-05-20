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
      appBar: AppBar(
        title: Text(_pageTitles[_selectedPage]),
        elevation: 0,
        backgroundColor: Colors.blue.shade700,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          tabs: [
            Tab(
              icon: Icon(Icons.dashboard),
              text: 'Dashboard',
            ),
            Tab(
              icon: Icon(Icons.assignment),
              text: 'Réclamations',
            ),
            Tab(
              icon: Icon(Icons.people),
              text: 'Utilisateurs',
            ),
          ],
          onTap: (index) {
            setState(() => _selectedPage = index);
          },
        ),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.blue.shade700, Colors.blue.shade900],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.person, size: 40, color: Colors.blue.shade700),
                  ),
                  SizedBox(height: 10),
                  Text(
                    _userName ?? 'Manager',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    _userEmail ?? '',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  SizedBox(height: 4),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _userRole ?? 'Manager',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            _buildDrawerItem(
              icon: Icons.dashboard,
              title: 'Dashboard',
              isSelected: _selectedPage == 0,
              onTap: () {
                setState(() => _selectedPage = 0);
                _tabController.animateTo(0);
                Navigator.pop(context);
              },
            ),
            _buildDrawerItem(
              icon: Icons.assignment,
              title: 'Réclamations',
              isSelected: _selectedPage == 1,
              onTap: () {
                setState(() => _selectedPage = 1);
                _tabController.animateTo(1);
                Navigator.pop(context);
              },
            ),
            _buildDrawerItem(
              icon: Icons.people,
              title: 'Utilisateurs',
              isSelected: _selectedPage == 2,
              onTap: () {
                setState(() => _selectedPage = 2);
                _tabController.animateTo(2);
                Navigator.pop(context);
              },
            ),
            Divider(),
            _buildDrawerItem(
              icon: Icons.settings,
              title: 'Paramètres',
              onTap: () {
                // TODO: Implémenter la page des paramètres
                Navigator.pop(context);
              },
            ),
            _buildDrawerItem(
              icon: Icons.logout,
              title: 'Déconnexion',
              onTap: () {
                // TODO: Implémenter la déconnexion
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
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
