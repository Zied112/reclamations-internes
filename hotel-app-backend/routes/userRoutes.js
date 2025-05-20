const express = require('express');
const router = express.Router();
const userController = require('../controllers/userController');

// Route pour enregistrer un utilisateur
router.post('/create', userController.createUser);

// Route pour obtenir tous les utilisateurs
router.get('/get', userController.getAllUsers);


// Route pour la connexion
router.post('/login', userController.loginUser); 

// ✅ Nouvelle route pour mettre à jour un utilisateur par ID
router.put('/update/:id', userController.updateUser);

// Route pour supprimer un utilisateur par ID
router.delete('/:id', userController.deleteUser);

module.exports = router;
