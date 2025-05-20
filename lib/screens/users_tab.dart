import 'package:flutter/material.dart';
import '../services/user_service.dart';

class UsersTab extends StatefulWidget {
  @override
  _UsersTabState createState() => _UsersTabState();
}

class _UsersTabState extends State<UsersTab> {
  late Future<List<dynamic>> _users;
  List<dynamic> _filteredUsers = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  void _fetchUsers() {
    setState(() {
      _users = UserService.getUsers();
      _users.then((users) {
        setState(() {
          _filteredUsers = users;
        });
      });
    });
  }

  void _deleteUser(String id) async {
    await UserService.deleteUser(id, context);
    _fetchUsers();
  }

  void _showUserForm({Map<String, dynamic>? user}) async {
    final result = await showDialog(
      context: context,
      builder: (context) => UserFormDialog(user: user),
    );
    if (result == true) _fetchUsers();
  }

  void _filterUsers(String query) async {
    final users = await _users;
    setState(() {
      _searchQuery = query;
      _filteredUsers = users.where((u) => (u['name'] ?? '').toLowerCase().startsWith(query.toLowerCase())).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                decoration: InputDecoration(
                  labelText: 'Recherche par nom',
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: _filterUsers,
              ),
            ),
            Expanded(
              child: FutureBuilder<List<dynamic>>(
                future: _users,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Erreur: [${snapshot.error}'));
                  }
                  if (!snapshot.hasData || _filteredUsers.isEmpty) {
                    return Center(child: Text('Aucun utilisateur.'));
                  }
                  return ListView.builder(
                    itemCount: _filteredUsers.length,
                    itemBuilder: (context, index) {
                      final user = _filteredUsers[index];
                      return Card(
                        child: ListTile(
                          title: Text(user['name'] ?? ''),
                          subtitle: Text('${user['email'] ?? ''} | ${user['role'] ?? ''} | ${user['department'] ?? ''}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(Icons.edit),
                                onPressed: () => _showUserForm(user: user),
                              ),
                              IconButton(
                                icon: Icon(Icons.delete),
                                onPressed: () => _deleteUser(user['_id']),
                              ),
                            ],
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
            onPressed: () => _showUserForm(),
            child: Icon(Icons.add),
          ),
        ),
      ],
    );
  }
}

class UserFormDialog extends StatefulWidget {
  final Map<String, dynamic>? user;
  UserFormDialog({this.user});

  @override
  _UserFormDialogState createState() => _UserFormDialogState();
}

class _UserFormDialogState extends State<UserFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  String _role = 'staff';
  String _department = 'Housekeeping';
  final List<String> _roles = ['staff', 'manager'];
  final List<String> _departments = [
    'Housekeeping', 'Reception', 'Maintenance', 'Security',
    'Food & Beverage', 'Kitchen', 'Laundry', 'Spa', 'IT', 'Management'
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user?['name'] ?? '');
    _emailController = TextEditingController(text: widget.user?['email'] ?? '');
    _passwordController = TextEditingController();
    _role = widget.user?['role'] ?? 'staff';
    _department = widget.user?['department'] ?? 'Housekeeping';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final userData = {
      'name': _nameController.text,
      'email': _emailController.text,
      'role': _role,
      'department': _department,
    };
    if (widget.user == null) {
      userData['password'] = _passwordController.text;
      final exists = await UserService.checkEmailExists(_emailController.text);
      if (exists) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Cet email existe déjà.')));
        return;
      }
      await UserService.createUser(userData, context);
    } else {
      if (_passwordController.text.isNotEmpty) {
        userData['password'] = _passwordController.text;
      }
      await UserService.updateUser(widget.user!['_id'], userData, context);
    }
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.user == null ? 'Ajouter un utilisateur' : 'Modifier utilisateur'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: 'Nom'),
                validator: (v) => v == null || v.isEmpty ? 'Nom requis' : null,
              ),
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Email requis';
                  if (!v.contains('@') || !v.contains('.')) return 'Email invalide';
                  return null;
                },
              ),
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(labelText: 'Mot de passe'),
                obscureText: true,
                validator: (v) {
                  if (widget.user == null && (v == null || v.isEmpty)) return 'Mot de passe requis';
                  return null;
                },
              ),
              DropdownButtonFormField<String>(
                value: _role,
                items: _roles.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                onChanged: (v) => setState(() => _role = v!),
                decoration: InputDecoration(labelText: 'Rôle'),
              ),
              DropdownButtonFormField<String>(
                value: _department,
                items: _departments.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                onChanged: (v) => setState(() => _department = v!),
                decoration: InputDecoration(labelText: 'Département'),
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
          child: Text(widget.user == null ? 'Ajouter' : 'Modifier'),
        ),
      ],
    );
  }
} 