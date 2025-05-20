import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'reclamation.dart';
import '../services/api_service.dart';
import '../services/reclamation_service.dart';

class EditReclamationForm extends StatefulWidget {
  final Reclamation reclamation;

  EditReclamationForm({required this.reclamation});

  @override
  _EditReclamationFormState createState() => _EditReclamationFormState();
}

class _EditReclamationFormState extends State<EditReclamationForm> {
  final _formKey = GlobalKey<FormState>();
  late String _objet;
  late String _description;
  late List<String> _departments;
  late int _priority;
  late String _status;
  late String _location;
  late String _createdBy;

  // Liste des départements pour CheckboxListTile
  final List<String> _availableDepartments = ['HR', 'IT', 'Maintenance', 'Admin'];

  // Liste des priorités pour Dropdown
  final List<int> _priorityOptions = [1, 2, 3];

  // Liste des statuts pour Dropdown
  final List<String> _statusOptions = ['New', 'In Progress', 'Done'];

  @override
  void initState() {
    super.initState();
    // Initialiser les valeurs avec les données de la réclamation existante
    _objet = widget.reclamation.objet;
    _description = widget.reclamation.description;
    _departments = List<String>.from(widget.reclamation.departments);
    _priority = widget.reclamation.priority;
    _status = widget.reclamation.status;
    _location = widget.reclamation.location;
    _createdBy = widget.reclamation.createdBy;
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState?.validate() ?? false) {
      _formKey.currentState?.save();

      if (_departments.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Veuillez sélectionner au moins un département.'),
                ],
              ),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              margin: EdgeInsets.only(
                bottom: MediaQuery.of(context).size.height - 100,
                left: 10,
                right: 10,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              duration: Duration(seconds: 3),
            ),
          );
        }
        return;
      }

      final updatedReclamation = Reclamation(
        id: widget.reclamation.id,
        objet: _objet,
        description: _description,
        departments: _departments,
        priority: _priority,
        status: _status,
        location: _location,
        createdAt: widget.reclamation.createdAt,
        updatedAt: DateTime.now(),
        createdBy: _createdBy,
        assignedTo: widget.reclamation.assignedTo,
      );

      try {
        await ReclamationService.updateReclamation(updatedReclamation, context);
        if (mounted) {
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Une erreur est survenue: $e'),
                ],
              ),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              margin: EdgeInsets.only(
                bottom: MediaQuery.of(context).size.height - 100,
                left: 10,
                right: 10,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Modifier la réclamation'),
        elevation: 0,
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade50, Colors.white],
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Informations principales',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade800,
                            ),
                          ),
                          SizedBox(height: 16),
                          TextFormField(
                            initialValue: _objet,
                            decoration: InputDecoration(
                              labelText: 'Objet',
                              prefixIcon: Icon(Icons.title),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                            validator: (value) => value!.isEmpty ? 'L\'objet est requis' : null,
                            onSaved: (value) => _objet = value!,
                          ),
                          SizedBox(height: 16),
                          TextFormField(
                            initialValue: _description,
                            decoration: InputDecoration(
                              labelText: 'Description',
                              prefixIcon: Icon(Icons.description),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                            maxLines: 3,
                            validator: (value) => value!.isEmpty ? 'La description est requise' : null,
                            onSaved: (value) => _description = value!,
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Détails',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade800,
                            ),
                          ),
                          SizedBox(height: 16),
                          TextFormField(
                            initialValue: _location,
                            decoration: InputDecoration(
                              labelText: 'Emplacement',
                              prefixIcon: Icon(Icons.location_on),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                            validator: (value) => value!.isEmpty ? 'L\'emplacement est requis' : null,
                            onSaved: (value) => _location = value!,
                          ),
                          SizedBox(height: 16),
                          DropdownButtonFormField<int>(
                            value: _priority,
                            decoration: InputDecoration(
                              labelText: 'Priorité',
                              prefixIcon: Icon(Icons.priority_high),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                            items: _priorityOptions.map((int priority) {
                              return DropdownMenuItem<int>(
                                value: priority,
                                child: Text('Priorité $priority'),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _priority = value!;
                              });
                            },
                            validator: (value) => value == null ? 'La priorité est requise' : null,
                          ),
                          SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            value: _status,
                            decoration: InputDecoration(
                              labelText: 'Statut',
                              prefixIcon: Icon(Icons.work),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                            items: _statusOptions.map((String status) {
                              return DropdownMenuItem<String>(
                                value: status,
                                child: Text(status),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _status = value!;
                              });
                            },
                            validator: (value) => value == null ? 'Le statut est requis' : null,
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Départements concernés',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade800,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Sélectionnez au moins un département',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                          SizedBox(height: 8),
                          ..._availableDepartments.map((String dept) {
                            return CheckboxListTile(
                              title: Text(dept),
                              value: _departments.contains(dept),
                              activeColor: Colors.blue,
                              checkColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              onChanged: (bool? selected) {
                                setState(() {
                                  if (selected != null && selected) {
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
                    ),
                  ),
                  SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _submitForm,
                      icon: Icon(Icons.save),
                      label: Text('Enregistrer les modifications'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
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
} 