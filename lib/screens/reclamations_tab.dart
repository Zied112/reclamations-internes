import 'package:flutter/material.dart';
import '../services/reclamation_service.dart';
import 'reclamation.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ReclamationsTab extends StatefulWidget {
  @override
  _ReclamationsTabState createState() => _ReclamationsTabState();
}

class _ReclamationsTabState extends State<ReclamationsTab> {
  late Future<List<Reclamation>> _reclamations;
  String? _selectedStatus;
  String? _selectedDepartment;
  DateTime? _startDate;
  DateTime? _endDate;
  final List<String> _statusOptions = ['New', 'In Progress', 'Done'];
  final List<String> _departmentOptions = ['HR', 'IT', 'Maintenance', 'Admin'];
  
  // Définition de l'URL de base
  final String baseUrl = 'http://localhost:3000';

  @override
  void initState() {
    super.initState();
    _fetchReclamations();
  }

  void _fetchReclamations() {
    setState(() {
      _reclamations = ReclamationService.getReclamations();
    });
  }

  void _deleteReclamation(String id) async {
    await ReclamationService.deleteReclamation(id, context);
    _fetchReclamations();
  }

  void _showReclamationForm({Reclamation? reclamation}) async {
    final result = await showDialog(
      context: context,
      builder: (context) => ReclamationFormDialog(reclamation: reclamation),
    );
    if (result == true) _fetchReclamations();
  }

  List<Reclamation> _applyFilters(List<Reclamation> list) {
    return list.where((r) {
      final statusMatch = _selectedStatus == null || r.status == _selectedStatus;
      final deptMatch = _selectedDepartment == null || r.departments.contains(_selectedDepartment);
      final dateMatch = (_startDate == null || r.createdAt.isAfter(_startDate!)) && (_endDate == null || r.createdAt.isBefore(_endDate!));
      return statusMatch && deptMatch && dateMatch;
    }).toList();
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(Duration(days: 365)),
      initialDateRange: _startDate != null && _endDate != null ? DateTimeRange(start: _startDate!, end: _endDate!) : null,
    );
    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  void _showReclamationDetails(Reclamation reclamation) async {
    String assignedUserName = 'Non assignée';
    if (reclamation.assignedTo.isNotEmpty) {
      try {
        final response = await http.get(
          Uri.parse('$baseUrl/api/users/get'),
          headers: {'Content-Type': 'application/json'},
        );
        if (response.statusCode == 200) {
          final users = json.decode(response.body) as List;
          // Si assignedTo est déjà un nom (pas un ID), l'utiliser directement
          if (reclamation.assignedTo == 'staff') {
            assignedUserName = 'staff';
          } else {
            final assignedUser = users.firstWhere(
              (user) => user['_id'] == reclamation.assignedTo,
              orElse: () => null,
            );
            if (assignedUser != null) {
              assignedUserName = assignedUser['name'];
            }
          }
        }
      } catch (e) {
        print('Erreur lors de la récupération des informations de l\'utilisateur: $e');
        // En cas d'erreur, utiliser directement la valeur de assignedTo
        assignedUserName = reclamation.assignedTo;
      }
    }

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Détails de la réclamation'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Objet', reclamation.objet),
              SizedBox(height: 16),
              _buildDetailRow('Description', reclamation.description),
              SizedBox(height: 16),
              _buildDetailRow('Emplacement', reclamation.location),
              SizedBox(height: 16),
              _buildDetailRow('Départements', reclamation.departments.join(', ')),
              SizedBox(height: 16),
              _buildDetailRow('Priorité', 'Niveau ${reclamation.priority}'),
              SizedBox(height: 16),
              _buildDetailRow('Statut', reclamation.status),
              SizedBox(height: 16),
              _buildDetailRow('Créée le', DateFormat('dd/MM/yyyy HH:mm').format(reclamation.createdAt)),
              SizedBox(height: 16),
              _buildDetailRow('Dernière mise à jour', DateFormat('dd/MM/yyyy HH:mm').format(reclamation.updatedAt)),
              SizedBox(height: 16),
              _buildDetailRow('Assignée à', assignedUserName),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Fermer'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.grey[700],
          ),
        ),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Future<void> _takeInCharge(Reclamation r) async {
    try {
      await ReclamationService.updateReclamationStatus(
        r.id,
        'In Progress',
        assignedTo: 'staff', // Utiliser directement le nom "staff"
      );
      _fetchReclamations();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Réclamation prise en charge avec succès'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la prise en charge: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 10,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(left: 4, bottom: 8),
                                child: Row(
                                  children: [
                                    Icon(Icons.filter_list, size: 16, color: Colors.grey[600]),
                                    SizedBox(width: 4),
                                    Text(
                                      'Status',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey.shade300),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: _selectedStatus,
                                    hint: Text('Sélectionner', style: TextStyle(color: Colors.grey[600])),
                                    isExpanded: true,
                                    items: [null, ..._statusOptions].map((status) {
                                      return DropdownMenuItem<String>(
                                        value: status,
                                        child: Text(status ?? 'Tous', style: TextStyle(color: Colors.grey[800])),
                                      );
                                    }).toList(),
                                    onChanged: (val) => setState(() => _selectedStatus = val),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(left: 4, bottom: 8),
                                child: Row(
                                  children: [
                                    Icon(Icons.business, size: 16, color: Colors.grey[600]),
                                    SizedBox(width: 4),
                                    Text(
                                      'Département',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey.shade300),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: _selectedDepartment,
                                    hint: Text('Sélectionner', style: TextStyle(color: Colors.grey[600])),
                                    isExpanded: true,
                                    items: [null, ..._departmentOptions].map((dept) {
                                      return DropdownMenuItem<String>(
                                        value: dept,
                                        child: Text(dept ?? 'Tous', style: TextStyle(color: Colors.grey[800])),
                                      );
                                    }).toList(),
                                    onChanged: (val) => setState(() => _selectedDepartment = val),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
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
                                    color: _startDate == null ? Colors.grey[600] : Colors.grey[800],
                                  ),
                                ),
                              ],
                            ),
                            if (_startDate != null || _endDate != null)
                              IconButton(
                                icon: Icon(Icons.clear, size: 20, color: Colors.grey[600]),
                                onPressed: () => setState(() {
                                  _startDate = null;
                                  _endDate = null;
                                }),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: FutureBuilder<List<Reclamation>>(
                future: _reclamations,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Erreur: ${snapshot.error}'));
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(child: Text('Aucune réclamation.'));
                  }
                  final filtered = _applyFilters(snapshot.data!);
                  return ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final r = filtered[index];
                      final dateFormatter = DateFormat('dd/MM/yyyy HH:mm');
                      Color cardColor;
                      Color statusColor;
                      IconData statusIcon;
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
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    cardColor,
                                    cardColor.withOpacity(0.8),
                                  ],
                                ),
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
                                    SizedBox(height: 4),
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
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class ReclamationFormDialog extends StatefulWidget {
  final Reclamation? reclamation;
  ReclamationFormDialog({this.reclamation});

  @override
  _ReclamationFormDialogState createState() => _ReclamationFormDialogState();
}

class _ReclamationFormDialogState extends State<ReclamationFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _objetController;
  late TextEditingController _descriptionController;
  late TextEditingController _locationController;
  List<String> _departments = [];
  int _priority = 1;
  String _status = 'New';
  final List<String> _availableDepartments = ['HR', 'IT', 'Maintenance', 'Admin'];
  final List<int> _priorityOptions = [1, 2, 3];
  final List<String> _statusOptions = ['New', 'In Progress', 'Done'];

  @override
  void initState() {
    super.initState();
    _objetController = TextEditingController(text: widget.reclamation?.objet ?? '');
    _descriptionController = TextEditingController(text: widget.reclamation?.description ?? '');
    _locationController = TextEditingController(text: widget.reclamation?.location ?? '');
    _departments = widget.reclamation?.departments ?? [];
    _priority = widget.reclamation?.priority ?? 1;
    _status = widget.reclamation?.status ?? 'New';
  }

  @override
  void dispose() {
    _objetController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final reclamationData = Reclamation(
      id: widget.reclamation?.id ?? '',
      objet: _objetController.text,
      description: _descriptionController.text,
      departments: _departments,
      priority: _priority,
      status: _status,
      location: _locationController.text,
      createdAt: widget.reclamation?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
      createdBy: widget.reclamation?.createdBy ?? '',
      assignedTo: widget.reclamation?.assignedTo ?? '',
    );
    try {
      if (widget.reclamation == null) {
        await ReclamationService.createReclamation(reclamationData, context);
      } else {
        await ReclamationService.updateReclamation(reclamationData, context);
      }
      Navigator.of(context).pop(true);
    } catch (e) {
      // L'erreur est déjà affichée par le service
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.reclamation == null ? 'Ajouter une réclamation' : 'Modifier réclamation'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _objetController,
                decoration: InputDecoration(labelText: 'Objet'),
                validator: (v) => v == null || v.isEmpty ? 'Objet requis' : null,
              ),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(labelText: 'Description'),
                validator: (v) => v == null || v.isEmpty ? 'Description requise' : null,
              ),
              TextFormField(
                controller: _locationController,
                decoration: InputDecoration(labelText: 'Emplacement'),
                validator: (v) => v == null || v.isEmpty ? 'Emplacement requis' : null,
              ),
              // Départements
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Départements (sélectionner au moins un)'),
                  ..._availableDepartments.map((dept) {
                    return CheckboxListTile(
                      title: Text(dept),
                      value: _departments.contains(dept),
                      onChanged: (selected) {
                        setState(() {
                          if (selected == true) {
                            _departments.add(dept);
                          } else {
                            _departments.remove(dept);
                          }
                        });
                      },
                    );
                  }).toList(),
                ],
              ),
              DropdownButtonFormField<int>(
                value: _priority,
                decoration: InputDecoration(labelText: 'Priorité'),
                items: _priorityOptions.map((priority) {
                  return DropdownMenuItem<int>(value: priority, child: Text(priority.toString()));
                }).toList(),
                onChanged: (value) => setState(() => _priority = value!),
                validator: (value) => value == null ? 'La priorité est requise' : null,
              ),
              DropdownButtonFormField<String>(
                value: _status,
                decoration: InputDecoration(labelText: 'Statut'),
                items: _statusOptions.map((status) {
                  return DropdownMenuItem<String>(value: status, child: Text(status));
                }).toList(),
                onChanged: (value) => setState(() => _status = value!),
                validator: (value) => value == null ? 'Le statut est requis' : null,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: Text(widget.reclamation == null ? 'Ajouter' : 'Modifier'),
        ),
      ],
    );
  }
} 