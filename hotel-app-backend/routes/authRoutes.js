const express = require('express');
const bcrypt = require('bcryptjs');
const session = require('express-session');  // Import express-session for session management
const User = require('../models/User');
const router = express.Router();

// Middleware pour gérer les sessions
router.use(session({
  secret: '123',  // Clé secrète pour signer le cookie de session
  resave: false,
  saveUninitialized: true,
  cookie: { secure: false }  // Pour HTTP simple, change à `true` en HTTPS
}));

// Route d'inscription
router.post('/register', async (req, res) => {
  try {
    const { email, password, role } = req.body;

    // Vérifier si l'utilisateur existe déjà
    const existingUser = await User.findOne({ email });
    if (existingUser) {
      return res.status(400).json({ message: 'Utilisateur déjà existant' });
    }

    // Hachage du mot de passe
    const salt = await bcrypt.genSalt(10);
    const hashedPassword = await bcrypt.hash(password, salt);

    // Création de l'utilisateur
    const newUser = new User({
      email,
      password: hashedPassword,
      role,
    });

    await newUser.save();
    res.status(201).json({ message: 'Utilisateur créé avec succès' });
  } catch (err) {
    res.status(500).json({ message: 'Erreur serveur' });
  }
});

// Route de connexion (Login)
router.post('/login', async (req, res) => {
  try {
    const { email, password } = req.body;

    // Vérifier si l'utilisateur existe
    const user = await User.findOne({ email });
    if (!user) {
      return res.status(400).json({ message: 'Email ou mot de passe incorrect' });
    }

    // Comparer le mot de passe
    const isMatch = await bcrypt.compare(password, user.password);
    if (!isMatch) {
      return res.status(400).json({ message: 'Email ou mot de passe incorrect' });
    }

    // Créer une session pour l'utilisateur
    req.session.userId = user._id;  // Stocke l'ID utilisateur dans la session
    req.session.role = user.role;    // On peut aussi stocker le rôle de l'utilisateur si nécessaire

    res.status(200).json({ message: 'Connexion réussie' });
  } catch (err) {
    res.status(500).json({ message: 'Erreur serveur' });
  }
});

// Route protégée (exemple)
router.get('/protected', (req, res) => {
  if (!req.session.userId) {
    // Si l'utilisateur n'est pas connecté, on renvoie une erreur
    return res.status(401).json({ message: 'Non autorisé, veuillez vous connecter' });
  }

  // Si l'utilisateur est connecté, on renvoie le contenu protégé
  res.status(200).json({ message: 'Contenu protégé accessible', userId: req.session.userId });
});

module.exports = router;
