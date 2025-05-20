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

class _StaffDashboardState extends State<StaffDashboard> {
  late Future<List<Reclamation>> _reclamations;
  String? _userName;
  String? _userEmail;
  bool _isLoading = false;

  // Filtres
  String? _selectedStatus;
  String? _selectedPriority;
  DateTime? _startDate;
  DateTime? _endDate;
  bool _showMyReclamations = false;
  bool _showAssignedReclamations = false;

  final List<String> _statusOptions = ['New', 'In Progress', 'Done'];
  final List<String> _priorityOptions = ['1', '2', '3'];

  @override
  void initState() {
    super.initState();
    _fetchUserInfo();
    _fetchReclamations();
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
    setState(() => _isLoading = true);
    try {
      await ReclamationService.updateReclamationStatus(r.id, 'In Progress', assignedTo: _userName);
      _fetchReclamations();
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
      _startDate = null;
      _endDate = null;
      _showMyReclamations = false;
      _showAssignedReclamations = false;
    });
  }

  List<Reclamation> _applyFilters(List<Reclamation> reclamations) {
    return reclamations.where((r) {
      bool statusMatch = _selectedStatus == null || r.status == _selectedStatus;
      bool priorityMatch = _selectedPriority == null || r.priority.toString() == _selectedPriority;
      bool dateMatch = (_startDate == null || r.createdAt.isAfter(_startDate!)) && 
                      (_endDate == null || r.createdAt.isBefore(_endDate!));
      bool userMatch = !_showMyReclamations || r.createdBy == _userEmail;
      bool assignedMatch = !_showAssignedReclamations || r.assignedTo == _userName;

      return statusMatch && priorityMatch && dateMatch && 
             (!_showMyReclamations || userMatch) && 
             (!_showAssignedReclamations || assignedMatch);
    }).toList();
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
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilterChip(
                label: Text('Mes réclamations'),
                selected: _showMyReclamations,
                onSelected: (selected) {
                  setState(() {
                    _showMyReclamations = selected;
                    if (selected) _showAssignedReclamations = false;
                  });
                },
              ),
              FilterChip(
                label: Text('Prises en charge'),
                selected: _showAssignedReclamations,
                onSelected: (selected) {
                  setState(() {
                    _showAssignedReclamations = selected;
                    if (selected) _showMyReclamations = false;
                  });
                },
              ),
            ],
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedStatus,
                  decoration: InputDecoration(
                    labelText: 'Statut',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: [
                    DropdownMenuItem(value: null, child: Text('Tous')),
                    ..._statusOptions.map((status) => DropdownMenuItem(
                      value: status,
                      child: Text(status),
                    )),
                  ],
                  onChanged: (value) => setState(() => _selectedStatus = value),
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedPriority,
                  decoration: InputDecoration(
                    labelText: 'Priorité',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
            ],
          ),
          SizedBox(height: 16),
          InkWell(
            onTap: _pickDateRange,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _startDate == null && _endDate == null
                        ? 'Sélectionner une période'
                        : '${DateFormat('dd/MM/yyyy').format(_startDate!)} - ${DateFormat('dd/MM/yyyy').format(_endDate!)}',
                    style: TextStyle(
                      color: _startDate == null ? Colors.grey : Colors.black,
                    ),
                  ),
                  Icon(Icons.calendar_today, size: 20),
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

    switch (r.status) {
      case 'New':
        statusColor = Colors.orange;
        statusIcon = Icons.new_releases;
        break;
      case 'In Progress':
        statusColor = Colors.blue;
        statusIcon = Icons.work;
        break;
      case 'Done':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help;
    }

    return Card(
      elevation: 4,
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showReclamationDetails(r),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      r.objet,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
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
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Text(
                r.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.grey[600]),
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                  SizedBox(width: 4),
                  Text(
                    r.location,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  Spacer(),
                  Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                  SizedBox(width: 4),
                  Text(
                    dateFormatter.format(r.createdAt),
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
              if (r.status == 'New' && _showMyReclamations)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : () => _takeInCharge(r),
                      icon: Icon(Icons.work),
                      label: Text('Prendre en charge'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ),
              if (r.status == 'In Progress' && r.assignedTo == _userName && _showAssignedReclamations)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : () => _markAsDone(r),
                      icon: Icon(Icons.check),
                      label: Text('Marquer comme terminé'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
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
                _buildDetailRow(Icons.calendar_today, 'Créé le', DateFormat('dd/MM/yyyy HH:mm').format(r.createdAt)),
                SizedBox(height: 24),
                if (r.status == 'New' && _showMyReclamations)
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
                if (r.status == 'In Progress' && r.assignedTo == _userName && _showAssignedReclamations)
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tableau de bord'),
        elevation: 0,
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
                    _userName ?? 'Utilisateur',
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
                ],
              ),
            ),
            ListTile(
              leading: Icon(Icons.logout),
              title: Text('Déconnexion'),
              onTap: () {
                // TODO: Implémenter la déconnexion
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ReclamationForm()),
          ).then((_) => _fetchReclamations());
        },
        icon: Icon(Icons.add),
        label: Text('Nouvelle réclamation'),
        backgroundColor: Colors.blue,
      ),
      body: Column(
        children: [
          _buildFilterSection(),
          Expanded(
            child: FutureBuilder<List<Reclamation>>(
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

                List<Reclamation> filteredData = _applyFilters(snapshot.data!);

                if (filteredData.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.filter_list, size: 48, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'Aucune réclamation ne correspond aux filtres',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 8),
                        TextButton(
                          onPressed: _resetFilters,
                          child: Text('Réinitialiser les filtres'),
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
            ),
          ),
        ],
      ),
    );
  }
}
