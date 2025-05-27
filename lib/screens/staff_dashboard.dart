import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:hotel_staff_app/screens/reclamation_form.dart';
import 'package:hotel_staff_app/screens/edit_reclamation_form.dart';
import '../services/reclamation_service.dart';
import 'reclamation.dart';
import '../services/api_service.dart';

class StaffDashboard extends StatefulWidget {
  @override
  _StaffDashboardState createState() => _StaffDashboardState();
}

class _StaffDashboardState extends State<StaffDashboard> with SingleTickerProviderStateMixin {
  late Future<List<Reclamation>> _reclamations;
  String? _userName;
  String? _userEmail;
  bool _isLoading = false;
  int _selectedIndex = 0; // Pour la navigation dans le menu

  // Filtres
  String? _selectedStatus;
  String? _selectedPriority;
  String? _selectedDepartment;
  DateTime? _startDate;
  DateTime? _endDate;

  final List<String> _statusOptions = ['New', 'In Progress', 'Done'];
  final List<String> _priorityOptions = ['1', '2', '3'];
  final List<String> _departmentOptions = ['Réception', 'Chambre', 'Restaurant', 'Maintenance', 'Autre'];

  // Titres des sections du menu
  final List<String> _menuTitles = [
    'Nouvelles réclamations',
    'Mes réclamations',
    'Prises en charge',
    'Historique'
  ];

  @override
  void initState() {
    super.initState();
    _fetchUserInfo();
    _fetchReclamations();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _fetchUserInfo() async {
    String? name = await ApiService.obtenirNomUtilisateurConnecte();
    String? email = await ApiService.obtenirEmailUtilisateurConnecte();
    setState(() {
      _userName = name;
      _userEmail = email;
    });
  }

  void _fetchReclamations() {
    setState(() {
      _reclamations = ReclamationService.getReclamations();
    });
  }

  Future<void> _takeInCharge(Reclamation r) async {
    if (_userName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: Impossible de récupérer le nom de l\'utilisateur')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await ReclamationService.updateReclamationStatus(
        r.id,
        'In Progress',
        assignedTo: _userName,
      );
      _fetchReclamations();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Réclamation prise en charge avec succès')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la prise en charge: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _markAsDone(Reclamation r) async {
    setState(() => _isLoading = true);
    try {
      await ReclamationService.updateReclamationStatus(r.id, 'Done', assignedTo: _userName);
      _fetchReclamations();
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(Duration(days: 365)),
      initialDateRange: _startDate != null && _endDate != null 
          ? DateTimeRange(start: _startDate!, end: _endDate!) 
          : null,
    );
    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  void _resetFilters() {
    setState(() {
      _selectedStatus = null;
      _selectedPriority = null;
      _selectedDepartment = null;
      _startDate = null;
      _endDate = null;
    });
  }

  List<Reclamation> _filterReclamations(List<Reclamation> reclamations, int menuIndex) {
    List<Reclamation> filtered = reclamations;
    
    switch (menuIndex) {
      case 0: // Nouvelles réclamations
        filtered = filtered.where((r) => r.status == 'New').toList();
        break;
      case 1: // Mes réclamations
        filtered = filtered.where((r) => r.createdBy == _userName).toList();
        break;
      case 2: // Prises en charge
        filtered = filtered.where((r) => r.assignedTo == _userName && r.status != 'Done').toList();
        break;
      case 3: // Historique
        filtered = filtered.where((r) => r.assignedTo == _userName && r.status == 'Done').toList();
        break;
    }

    // Appliquer les filtres supplémentaires si sélectionnés
    if (_selectedPriority != null) {
      filtered = filtered.where((r) => r.priority.toString() == _selectedPriority).toList();
    }
    if (_selectedDepartment != null) {
      filtered = filtered.where((r) => r.departments.contains(_selectedDepartment)).toList();
    }
    if (_startDate != null) {
      filtered = filtered.where((r) => r.createdAt.isAfter(_startDate!)).toList();
    }
    if (_endDate != null) {
      filtered = filtered.where((r) => r.createdAt.isBefore(_endDate!)).toList();
    }

    return filtered;
  }

  Widget _buildFilterSection() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Filtres',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Spacer(),
              TextButton.icon(
                onPressed: _resetFilters,
                icon: Icon(Icons.refresh, size: 18),
                label: Text('Réinitialiser'),
              ),
            ],
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedPriority,
                  decoration: InputDecoration(
                    labelText: 'Priorité',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    prefixIcon: Icon(Icons.priority_high),
                  ),
                  items: [
                    DropdownMenuItem(value: null, child: Text('Toutes')),
                    ..._priorityOptions.map((priority) => DropdownMenuItem(
                      value: priority,
                      child: Text('Priorité $priority'),
                    )),
                  ],
                  onChanged: (value) => setState(() => _selectedPriority = value),
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedDepartment,
                  decoration: InputDecoration(
                    labelText: 'Département',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    prefixIcon: Icon(Icons.business),
                  ),
                  items: [
                    DropdownMenuItem(value: null, child: Text('Tous')),
                    ..._departmentOptions.map((dept) => DropdownMenuItem(
                      value: dept,
                      child: Text(dept),
                    )),
                  ],
                  onChanged: (value) => setState(() => _selectedDepartment = value),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          InkWell(
            onTap: _pickDateRange,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: 20, color: Colors.grey[600]),
                      SizedBox(width: 8),
                      Text(
                        _startDate == null && _endDate == null
                            ? 'Sélectionner une période'
                            : '${DateFormat('dd/MM/yyyy').format(_startDate!)} - ${DateFormat('dd/MM/yyyy').format(_endDate!)}',
                        style: TextStyle(
                          color: _startDate == null ? Colors.grey : Colors.black,
                        ),
                      ),
                    ],
                  ),
                  Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReclamationCard(Reclamation r) {
    final dateFormatter = DateFormat('dd/MM/yyyy HH:mm');
    Color statusColor;
    IconData statusIcon;
    Color cardColor;
    String dateLabel;
    DateTime displayDate;

    // Définir la couleur de la carte en fonction de la priorité
    switch (r.priority) {
      case 1:
        cardColor = Colors.red.shade900.withOpacity(0.8);
        break;
      case 2:
        cardColor = Colors.orange.shade900.withOpacity(0.8);
        break;
      case 3:
        cardColor = Colors.purple.shade900.withOpacity(0.8);
        break;
      default:
        cardColor = Colors.grey.shade900.withOpacity(0.8);
    }

    // Définir la couleur, l'icône et la date en fonction du statut
    switch (r.status) {
      case 'New':
        statusColor = Colors.orange;
        statusIcon = Icons.new_releases;
        dateLabel = 'Créée le';
        displayDate = r.createdAt;
        break;
      case 'In Progress':
        statusColor = Colors.blue;
        statusIcon = Icons.work;
        dateLabel = 'Prise en charge le';
        displayDate = r.updatedAt;
        break;
      case 'Done':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        dateLabel = 'Terminée le';
        displayDate = r.updatedAt;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help;
        dateLabel = 'Créée le';
        displayDate = r.createdAt;
    }

    return Hero(
      tag: 'reclamation-${r.id}',
      child: Card(
        elevation: 4,
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: cardColor,
        child: InkWell(
          onTap: () => _showReclamationDetails(r),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              r.objet,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                            SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(Icons.access_time, size: 16, color: Colors.white.withOpacity(0.8)),
                                SizedBox(width: 4),
                                Text(
                                  '$dateLabel ${dateFormatter.format(displayDate)}',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.8),
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(statusIcon, color: statusColor, size: 16),
                            SizedBox(width: 4),
                            Text(
                              r.status,
                              style: TextStyle(
                                color: statusColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  if (r.createdBy == _userName && r.status == 'New')
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: IconButton(
                            icon: Icon(Icons.edit, color: Colors.white),
                            onPressed: () => _showReclamationForm(reclamation: r),
                          ),
                        ),
                        SizedBox(width: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: IconButton(
                            icon: Icon(Icons.delete, color: Colors.white),
                            onPressed: () => _deleteReclamation(r.id),
                          ),
                        ),
                      ],
                    ),
                  if (r.status == 'New')
                    Padding(
                      padding: const EdgeInsets.only(top: 16.0),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : () => _takeInCharge(r),
                          icon: Icon(Icons.check_circle, color: Colors.green),
                          label: Text('Prendre en charge'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: cardColor,
                            elevation: 2,
                            padding: EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ),
                  if (r.status == 'In Progress' && r.assignedTo == _userName)
                    Padding(
                      padding: const EdgeInsets.only(top: 16.0),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : () => _markAsDone(r),
                          icon: Icon(Icons.check),
                          label: Text('Marquer comme terminé'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: cardColor,
                            elevation: 2,
                            padding: EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showReclamationDetails(Reclamation r) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text(
                  r.objet,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  r.description,
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 24),
                _buildDetailRow(Icons.location_on, 'Emplacement', r.location),
                _buildDetailRow(Icons.work, 'Statut', r.status),
                _buildDetailRow(Icons.person, 'Créé par', r.createdBy),
                if (r.assignedTo.isNotEmpty)
                  _buildDetailRow(Icons.assignment_ind, 'Assigné à', r.assignedTo),
                SizedBox(height: 24),
                if (r.status == 'New')
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : () => _takeInCharge(r),
                      icon: Icon(Icons.work),
                      label: Text('Prendre en charge'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                if (r.status == 'In Progress' && r.assignedTo == _userName)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : () => _markAsDone(r),
                      icon: Icon(Icons.check),
                      label: Text('Marquer comme terminé'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: Colors.grey[800]),
            ),
          ),
        ],
      ),
    );
  }

  void _showReclamationForm({Reclamation? reclamation}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => reclamation == null 
          ? ReclamationForm() 
          : EditReclamationForm(reclamation: reclamation),
      ),
    );
    
    if (result == true) {
      _fetchReclamations();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text(reclamation == null 
                ? 'La réclamation a été créée avec succès'
                : 'La réclamation a été modifiée avec succès'),
            ],
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.only(
            bottom: MediaQuery.of(context).size.height - 100,
            left: 10,
            right: 10,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  Future<void> _deleteReclamation(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirmer la suppression'),
        content: Text('Êtes-vous sûr de vouloir supprimer cette réclamation ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);
      try {
        await ReclamationService.deleteReclamation(id, context);
        _fetchReclamations();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('La réclamation a été supprimée avec succès'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.only(
              bottom: MediaQuery.of(context).size.height - 100,
              left: 10,
              right: 10,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la suppression: $e'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(Icons.menu),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          ),
        ),
        title: Text(
          _menuTitles[_selectedIndex],
          style: TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
      ),
      drawer: Drawer(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.white, Colors.grey.shade50],
            ),
          ),
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.blue, Colors.blue.shade800],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.white,
                      child: Icon(Icons.person, size: 35, color: Colors.blue),
                    ),
                    SizedBox(height: 12),
                    Text(
                      _userName ?? 'Utilisateur',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      _userEmail ?? '',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              _buildDrawerItem(0, Icons.new_releases, 'Nouvelles réclamations', Colors.orange),
              _buildDrawerItem(1, Icons.list, 'Mes réclamations', Colors.blue),
              _buildDrawerItem(2, Icons.work, 'Prises en charge', Colors.green),
              _buildDrawerItem(3, Icons.history, 'Historique', Colors.purple),
            ],
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, Colors.grey.shade50],
          ),
        ),
        child: Column(
          children: [
            if (_selectedIndex == 0) _buildFilterSection(),
            Expanded(
              child: _buildReclamationsList(_selectedIndex),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ReclamationForm()),
          );
          
          if (result == true) {
            _fetchReclamations();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.white),
                    SizedBox(width: 8),
                    Text('La réclamation a été créée avec succès'),
                  ],
                ),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 3),
                behavior: SnackBarBehavior.floating,
                margin: EdgeInsets.only(
                  bottom: MediaQuery.of(context).size.height - 100,
                  left: 10,
                  right: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            );
            setState(() {
              _selectedIndex = 0;
            });
          }
        },
        child: Icon(Icons.add, color: Colors.blue),
        backgroundColor: Colors.white,
        elevation: 4,
      ),
    );
  }

  Widget _buildDrawerItem(int index, IconData icon, String title, Color color) {
    return ListTile(
      leading: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: _selectedIndex == index ? color.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: _selectedIndex == index ? FontWeight.bold : FontWeight.normal,
          color: _selectedIndex == index ? color : Colors.black87,
        ),
      ),
      selected: _selectedIndex == index,
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
        Navigator.pop(context);
      },
    );
  }

  Widget _buildReclamationsList(int menuIndex) {
    return FutureBuilder<List<Reclamation>>(
      future: _reclamations,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: Colors.red),
                SizedBox(height: 16),
                Text(
                  'Erreur de chargement',
                  style: TextStyle(fontSize: 18, color: Colors.red),
                ),
                SizedBox(height: 8),
                ElevatedButton(
                  onPressed: _fetchReclamations,
                  child: Text('Réessayer'),
                ),
              ],
            ),
          );
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox, size: 48, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'Aucune réclamation',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        List<Reclamation> filteredData = _filterReclamations(snapshot.data!, menuIndex);

        if (filteredData.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.filter_list, size: 48, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'Aucune réclamation dans cette catégorie',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            _fetchReclamations();
          },
          child: ListView.builder(
            padding: EdgeInsets.symmetric(vertical: 8),
            itemCount: filteredData.length,
            itemBuilder: (context, index) => _buildReclamationCard(filteredData[index]),
          ),
        );
      },
    );
  }
}
