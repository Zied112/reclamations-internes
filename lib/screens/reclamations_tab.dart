import 'package:flutter/material.dart';
import '../services/reclamation_service.dart';
import 'reclamation.dart';
import 'package:intl/intl.dart';

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

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  DropdownButton<String>(
                    value: _selectedStatus,
                    hint: Text('Status'),
                    items: [null, ..._statusOptions].map((status) {
                      return DropdownMenuItem<String>(
                        value: status,
                        child: Text(status ?? 'Tous'),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => _selectedStatus = val),
                  ),
                  SizedBox(width: 8),
                  DropdownButton<String>(
                    value: _selectedDepartment,
                    hint: Text('Département'),
                    items: [null, ..._departmentOptions].map((dept) {
                      return DropdownMenuItem<String>(
                        value: dept,
                        child: Text(dept ?? 'Tous'),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => _selectedDepartment = val),
                  ),
                  SizedBox(width: 8),
                  ElevatedButton.icon(
                    icon: Icon(Icons.date_range),
                    label: Text(_startDate == null && _endDate == null ? 'Dates' : '${_startDate != null ? DateFormat('dd/MM/yyyy').format(_startDate!) : ''} - ${_endDate != null ? DateFormat('dd/MM/yyyy').format(_endDate!) : ''}'),
                    onPressed: _pickDateRange,
                  ),
                  if (_startDate != null || _endDate != null)
                    IconButton(
                      icon: Icon(Icons.clear),
                      onPressed: () => setState(() {
                        _startDate = null;
                        _endDate = null;
                      }),
                    ),
                ],
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
                      return Card(
                        child: ListTile(
                          title: Text(r.objet),
                          subtitle: Text(r.description),
                          trailing: IconButton(
                            icon: Icon(Icons.delete),
                            onPressed: () => _deleteReclamation(r.id),
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
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton(
            onPressed: () => _showReclamationForm(),
            child: Icon(Icons.add),
          ),
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