import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class UserService {
  static String get baseUrl {
    if (kIsWeb) return 'http://localhost:5000';
    // ... adapte selon la plateforme
    return 'http://10.0.2.2:5000';
  }

  static Future<List<dynamic>> getUsers() async {
    final response = await http.get(Uri.parse('$baseUrl/api/users/get'));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Erreur lors du chargement des utilisateurs');
    }
  }

  static Future<void> deleteUser(String id, BuildContext context) async {
    final response = await http.delete(Uri.parse('$baseUrl/api/users/$id'));
    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Utilisateur supprimé')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur lors de la suppression de l\'utilisateur')));
      throw Exception('Erreur lors de la suppression');
    }
  }

  static Future<void> createUser(Map<String, dynamic> userData, BuildContext context) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/users/create'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(userData),
    );
    if (response.statusCode == 201) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Utilisateur créé avec succès')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur lors de la création de l\'utilisateur')));
      throw Exception('Erreur lors de la création de l\'utilisateur');
    }
  }

  static Future<void> updateUser(String id, Map<String, dynamic> userData, BuildContext context) async {
    final response = await http.put(
      Uri.parse('$baseUrl/api/users/update/$id'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(userData),
    );
    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Utilisateur modifié avec succès')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur lors de la modification de l\'utilisateur')));
      throw Exception('Erreur lors de la modification de l\'utilisateur');
    }
  }

  static Future<bool> checkEmailExists(String email) async {
    final response = await http.get(Uri.parse('$baseUrl/api/users/get'));
    if (response.statusCode == 200) {
      final users = json.decode(response.body) as List;
      return users.any((u) => u['email'] == email);
    }
    return false;
  }
} 