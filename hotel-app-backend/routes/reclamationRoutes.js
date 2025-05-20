const express = require('express');
const router = express.Router();
const reclamationController = require('../controllers/reclamationController');

router.post('/create', reclamationController.createReclamation);
router.get('/', reclamationController.getAllReclamations);
router.put('/:id/status', reclamationController.updateStatus);
router.put('/update/:id', reclamationController.updateReclamation);
router.delete('/:id', reclamationController.deleteReclamation);

module.exports = router;
