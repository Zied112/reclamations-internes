const mongoose = require('mongoose');

const reclamationSchema = new mongoose.Schema({
  objet: { type: String, required: true }, // Correspond à _objet
  description: { type: String, required: true }, // Correspond à _description
  departments: { type: [String], required: true }, // Correspond à _departments (liste de strings)
  priority: { type: Number, required: true, default: 1 }, // Correspond à _priority (par défaut 1)
  status: { type: String, enum: ['New', 'In Progress', 'Done'], default: 'New', required: true }, // Correspond à _status
  location: { type: String, required: true }, // Correspond à _location
  assignedTo: { type: String, default: '' }, // Changed from ObjectId to String
  createdBy: { type: String, required: true }, // Stocke l'email ou le nom du staff
  createdAt: { type: Date, default: Date.now }, // La date de création
  updatedAt: { type: Date }, // Date de mise à jour
});

module.exports = mongoose.model('reclamation', reclamationSchema);
