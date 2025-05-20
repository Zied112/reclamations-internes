import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'reclamation.dart';
import '../services/api_service.dart';

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
            SnackBar(content: Text('Veuillez sélectionner au moins un département.')),
          );
        }
        return;
      }

      final reclamationData = {
        'objet': _objet,
        'description': _description,
        'departments': _departments,
        'priority': _priority,
        'status': _status,
        'location': _location,
        'createdBy': _createdBy,
      };

      try {
        final response = await http.put(
          Uri.parse('http://10.0.2.2:5000/api/reclamations/update/${widget.reclamation.id}'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode(reclamationData),
        );

        if (response.statusCode == 200) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Réclamation modifiée avec succès!')),
            );
            Navigator.pop(context, true);
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Échec de la modification: ${response.body}')),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Une erreur est survenue: $e')),
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
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  initialValue: _objet,
                  decoration: InputDecoration(labelText: 'Objet'),
                  validator: (value) => value!.isEmpty ? 'L\'objet est requis' : null,
                  onSaved: (value) => _objet = value!,
                ),
                TextFormField(
                  initialValue: _description,
                  decoration: InputDecoration(labelText: 'Description'),
                  validator: (value) => value!.isEmpty ? 'La description est requise' : null,
                  onSaved: (value) => _description = value!,
                ),
                Text('Départements (sélectionner au moins un)'),
                ..._availableDepartments.map((String dept) {
                  return CheckboxListTile(
                    title: Text(dept),
                    value: _departments.contains(dept),
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
                DropdownButtonFormField<int>(
                  value: _priority,
                  decoration: InputDecoration(labelText: 'Priorité'),
                  items: _priorityOptions.map((int priority) {
                    return DropdownMenuItem<int>(
                      value: priority,
                      child: Text(priority.toString()),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _priority = value!;
                    });
                  },
                  validator: (value) => value == null ? 'La priorité est requise' : null,
                ),
                DropdownButtonFormField<String>(
                  value: _status,
                  decoration: InputDecoration(labelText: 'Statut'),
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
                TextFormField(
                  initialValue: _location,
                  decoration: InputDecoration(labelText: 'Emplacement'),
                  validator: (value) => value!.isEmpty ? 'L\'emplacement est requis' : null,
                  onSaved: (value) => _location = value!,
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _submitForm,
                  child: Text('Enregistrer les modifications'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 