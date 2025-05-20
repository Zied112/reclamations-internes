const express = require('express');
const router = express.Router();
const reclamationController = require('../controllers/reclamationController');

// Route pour créer une réclamation
router.post('/create', reclamationController.createReclamation);

// Route pour obtenir toutes les réclamations
router.get('/', reclamationController.getAllReclamations);

// Route pour mettre à jour le statut d'une réclamation
router.put('/:id/status', reclamationController.updateStatus);

// Route pour mettre à jour une réclamation
router.put('/update/:id', reclamationController.updateReclamation);

// Route pour supprimer une réclamation
router.delete('/:id', reclamationController.deleteReclamation);

module.exports = router;
