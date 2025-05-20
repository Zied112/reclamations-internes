class Reclamation {
  String id; // <-- Ajout de l'ID
  String objet;
  String description;
  List<String> departments;
  int priority;
  String status;
  String location;
  DateTime createdAt;
  DateTime updatedAt;
  String createdBy;
  String assignedTo;

  Reclamation({
    required this.id, // <-- Ajouté dans le constructeur
    required this.objet,
    required this.description,
    required this.departments,
    required this.priority,
    required this.status,
    required this.location,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
    required this.assignedTo,
  });

  factory Reclamation.fromJson(Map<String, dynamic> json) {
    return Reclamation(
      id: json['_id'] ?? '', // <-- Assure-toi que le backend renvoie `_id`
      objet: json['objet'] ?? 'Objet non défini',
      description: json['description'] ?? 'Description non définie',
      departments: List<String>.from(json['departments'] ?? []),
      priority: json['priority'] ?? 1,
      status: json['status'] ?? 'New',
      location: json['location'] ?? 'Emplacement non défini',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
      createdBy: json['createdBy'] ?? 'Non défini',
      assignedTo: json['assignedTo'] ?? 'Non défini',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id, // <-- Inclure l’ID dans le JSON
      'objet': objet,
      'description': description,
      'departments': departments,
      'priority': priority,
      'status': status,
      'location': location,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'createdBy': createdBy,
      'assignedTo': assignedTo,
    };
  }
}
