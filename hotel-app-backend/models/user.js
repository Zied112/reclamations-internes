const mongoose = require('mongoose');

// Schéma pour un utilisateur
const userSchema = new mongoose.Schema({
  name: { type: String, required: true },
  email: { type: String, required: true, unique: true },
  password: { type: String, required: true },
  role: { type: String, enum: ['staff', 'manager'], default: 'staff' },
  department: {
    type: String,
    enum: ['Housekeeping', 'Reception', 'Maintenance', 'Security', 'Food & Beverage', 'Kitchen', 'Laundry', 'Spa', 'IT', 'Management'],
    required: true
  }
}, { timestamps: true });


const User = mongoose.model('User', userSchema);

module.exports = User;
