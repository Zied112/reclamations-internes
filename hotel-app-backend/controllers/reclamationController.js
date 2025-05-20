const Reclamation = require('../models/reclamation');
const User = require('../models/user');

exports.createReclamation = async (req, res) => {
  try {
    const reclamation = new Reclamation(req.body);
    await reclamation.save();
    res.status(201).json(reclamation);
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
};

exports.getAllReclamations = async (req, res) => {
  const reclamations = await Reclamation.find();
  res.json(reclamations);
};

exports.updateStatus = async (req, res) => {
  try {
    const { id } = req.params;
    let { status, assignedTo } = req.body;

    console.log('--- [updateStatus] ---');
    console.log('ID:', id);
    console.log('status:', status);
    console.log('assignedTo:', assignedTo);

    // Vérifier si la réclamation existe
    const reclamation = await Reclamation.findById(id);
    if (!reclamation) {
      return res.status(404).json({ error: 'Réclamation non trouvée' });
    }

    // Si un utilisateur est assigné, vérifier si c'est un nom ou un ObjectId
    if (assignedTo) {
      // Si ce n'est pas un ObjectId, on suppose que c'est un nom
      if (!assignedTo.match(/^[0-9a-fA-F]{24}$/)) {
        const user = await User.findOne({ name: assignedTo });
        if (!user) {
          return res.status(404).json({ error: 'Utilisateur assigné non trouvé' });
        }
        assignedTo = user._id;
      }
    }

    // Mettre à jour la réclamation avec le statut et l'utilisateur assigné
    const updatedReclamation = await Reclamation.findByIdAndUpdate(
      id,
      { status, assignedTo, updatedAt: new Date() },
      { new: true }
    );

    console.log('Réclamation mise à jour (status):', updatedReclamation);
    res.json(updatedReclamation);
  } catch (err) {
    // Retourner une erreur avec le message
    console.log('Erreur updateStatus:', err);
    res.status(400).json({ error: `Erreur: ${err.message}` });
  }
};

exports.updateReclamation = async (req, res) => {
  const { id } = req.params;
  const updateData = req.body;

  // Ajout de logs pour debug
  console.log('--- [updateReclamation] ---');
  console.log('ID:', id);
  console.log('updateData:', updateData);

  try {
    const updatedReclamation = await Reclamation.findByIdAndUpdate(
      id,
      { ...updateData, updatedAt: new Date() },
      { new: true }
    );

    if (!updatedReclamation) {
      console.log('Réclamation non trouvée');
      return res.status(404).json({ message: 'Réclamation non trouvée' });
    }

    console.log('Réclamation mise à jour:', updatedReclamation);
    res.status(200).json(updatedReclamation);
  } catch (error) {
    console.log('Erreur lors de la mise à jour:', error);
    res.status(500).json({ message: 'Erreur lors de la mise à jour', error });
  }
};

exports.deleteReclamation = async (req, res) => {
  try {
    await Reclamation.findByIdAndDelete(req.params.id);
    res.status(200).json({ message: 'Réclamation supprimée' });
  } catch (error) {
    res.status(500).json({ message: 'Erreur lors de la suppression', error });
  }
};
