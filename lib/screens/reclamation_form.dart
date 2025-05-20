import 'dart:io';
import 'package:flutter/foundation.dart';  // Import nécessaire pour kIsWeb
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/api_service.dart';  // Assurez-vous d'importer ApiService

class ReclamationForm extends StatefulWidget {
  @override
  _ReclamationFormState createState() => _ReclamationFormState();
}

class _ReclamationFormState extends State<ReclamationForm> {
  final _formKey = GlobalKey<FormState>();
  // Méthode pour obtenir l'URL en fonction de la plateforme
  static String get baseUrl {
    if (kIsWeb) {
      // Si l'application est sur le Web
      return 'http://localhost:5000';  // Utilise l'adresse de ton serveur local pour Web
    } else if (Platform.isAndroid) {
      // Si c'est un émulateur Android, utilise localhost
      return 'http://10.0.2.2:5000'; // Adresse spéciale pour l'émulateur Android
    } else if (Platform.isIOS) {
      // Si c'est un appareil iOS, utilise l'adresse locale ou une autre
      return 'http://<ton-ip-local>:5000'; // Remplace par l'IP de ton serveur local pour iOS
    } else {
      // Pour d'autres plateformes, utiliser l'IP locale de ton serveur
      return 'http://<ton-ip-local>:5000'; // Remplace par l'IP de ton serveur
    }
  }

  // Variables pour stocker les valeurs des champs
  String _objet = '';
  String _description = '';
  List<String> _departments = [];
  int _priority = 1;
  String _status = 'New';
  String _location = '';
  String _createdBy = ''; // Variable pour le nom de l'utilisateur connecté

  // Liste des départements pour CheckboxListTile
  final List<String> _availableDepartments = ['HR', 'IT', 'Maintenance', 'Admin'];

  // Liste des priorités pour Dropdown
  final List<int> _priorityOptions = [1, 2, 3];

  // Liste des statuts pour Dropdown
  final List<String> _statusOptions = ['New', 'In Progress', 'Done'];

  @override
  void initState() {
    super.initState();
    _getUserName();
  }

  // Fonction pour récupérer le nom de l'utilisateur connecté
  void _getUserName() async {
    String? name = await ApiService.obtenirNomUtilisateurConnecte();
    if (name != null) {
      setState(() {
        _createdBy = name;
      });
    } else {
      print("Aucun utilisateur connecté");
    }
  }

  // Fonction pour soumettre le formulaire
  void _submitForm() async {
    if (_createdBy.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Le nom de l\'utilisateur n\'est pas encore chargé. Veuillez patienter.')),
      );
      return;
    }
    print("Formulaire soumis");

    if (_formKey.currentState?.validate() ?? false) {
      print("Formulaire validé");

      _formKey.currentState?.save();

      // Vérifier si des départements ont été sélectionnés
      if (_departments.isEmpty) {
        print("Aucun département sélectionné");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Veuillez sélectionner au moins un département.')),
        );
        return;
      }

      print("Données de la réclamation à envoyer :");
      print("Objet : $_objet");
      print("Description : $_description");
      print("Départements : $_departments");
      print("Priorité : $_priority");
      print("Statut : $_status");
      print("Emplacement : $_location");

      // Créer l'objet de réclamation
      final reclamationData = {
        'objet': _objet,
        'description': _description,
        'createdBy': _createdBy,  // Utilisation du nom de l'utilisateur connecté
        'departments': _departments,
        'priority': _priority,
        'status': _status,
        'location': _location,
      };

      try {
        // Envoi de la réclamation via l'API
        final response = await http.post(
          Uri.parse('$baseUrl/api/reclamations/create'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode(reclamationData),
        );

        print("Réponse de l'API: ${response.statusCode}");
        print("Réponse de l'API corps : ${response.body}");

        if (response.statusCode == 201) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Réclamation créée avec succès!')),
          );
          // Vous pouvez ici rediriger ou nettoyer le formulaire après une soumission réussie
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Échec de la création de la réclamation.')),
          );
        }
      } catch (e) {
        // Gestion des erreurs réseau ou autres exceptions
        print("Erreur lors de la soumission : $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Une erreur est survenue. Veuillez réessayer.')),
        );
      }
    } else {
      print("Formulaire non validé");
    }
  }

  @override
  Widget build(BuildContext context) {
    // Afficher un indicateur de chargement si le nom n'est pas encore prêt
    if (_createdBy.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text('Créer une réclamation')),
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      appBar: AppBar(title: Text('Créer une réclamation')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  decoration: InputDecoration(labelText: 'Objet'),
                  validator: (value) => value!.isEmpty ? 'L\'objet est requis' : null,
                  onSaved: (value) => _objet = value!,
                ),
                TextFormField(
                  decoration: InputDecoration(labelText: 'Description'),
                  validator: (value) => value!.isEmpty ? 'La description est requise' : null,
                  onSaved: (value) => _description = value!,
                ),
                // Choix des départements
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
                    return DropdownMenuItem<int>(value: priority, child: Text(priority.toString()));
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
                    return DropdownMenuItem<String>(value: status, child: Text(status));
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _status = value!;
                    });
                  },
                  validator: (value) => value == null ? 'Le statut est requis' : null,
                ),
                TextFormField(
                  decoration: InputDecoration(labelText: 'Emplacement'),
                  validator: (value) => value!.isEmpty ? 'L\'emplacement est requis' : null,
                  onSaved: (value) => _location = value!,
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _createdBy.isEmpty ? null : _submitForm,  // Désactive si nom non prêt
                  child: Text('Soumettre la réclamation'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
