const express = require('express');
const mongoose = require('mongoose');
const dotenv = require('dotenv');
const cors = require('cors');

// Charger les variables d'environnement
dotenv.config();

// Initialiser l'application Express
const app = express();

// Utiliser CORS pour autoriser les requêtes cross-origin
app.use(cors());

// Middleware pour parser les requêtes JSON
app.use(express.json());

// Importer les routes
const userRoutes = require('./routes/userRoutes');
const reclamationRoutes = require('./routes/reclamationRoutes');

// Utiliser les routes
app.use('/api/users', userRoutes);
app.use('/api/reclamations', reclamationRoutes);

// Route de base pour vérifier que l'API fonctionne
app.get('/', (req, res) => {
  res.json({ message: 'API is running' });
});

// Connexion à MongoDB
mongoose.connect(process.env.MONGO_URI)
  .then(() => {
    console.log('✅ MongoDB connecté');
    const PORT = process.env.PORT || 5000;
    app.listen(PORT, () => {
      console.log(`🚀 Serveur lancé sur le port ${PORT}`);
    });
  })
  .catch(err => console.error('Erreur MongoDB:', err));
