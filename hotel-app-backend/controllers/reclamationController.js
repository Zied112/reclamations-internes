const Reclamation = require('../models/reclamation');
const User = require('../models/user');

exports.createReclamation = async (req, res) => {
  try {
    const reclamationData = { ...req.body };
    
    // Si un utilisateur est assigné, récupérer son nom
    if (reclamationData.assignedTo) {
      const user = await User.findById(reclamationData.assignedTo);
      if (user) {
        reclamationData.assignedTo = user.name;
      }
    }

    const reclamation = new Reclamation(reclamationData);
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
    const { status, assignedTo } = req.body;

    console.log('--- [updateStatus] ---');
    console.log('ID:', id);
    console.log('status:', status);
    console.log('assignedTo:', assignedTo);

    // Vérifier si la réclamation existe
    const reclamation = await Reclamation.findById(id);
    if (!reclamation) {
      return res.status(404).json({ error: 'Réclamation non trouvée' });
    }

    // Si assignedTo est "staff", l'utiliser directement
    let assignedUserName = assignedTo;
    if (assignedTo && assignedTo !== 'staff') {
      try {
        const user = await User.findById(assignedTo);
        if (user) {
          assignedUserName = user.name;
        }
      } catch (err) {
        console.log('Erreur lors de la récupération de l\'utilisateur:', err);
        // En cas d'erreur, utiliser la valeur d'origine
        assignedUserName = assignedTo;
      }
    }

    // Mettre à jour la réclamation avec le statut et le nom de l'utilisateur assigné
    const updatedReclamation = await Reclamation.findByIdAndUpdate(
      id,
      { 
        status, 
        assignedTo: assignedUserName, 
        updatedAt: new Date() 
      },
      { new: true }
    );

    console.log('Réclamation mise à jour (status):', updatedReclamation);
    res.json(updatedReclamation);
  } catch (err) {
    console.log('Erreur updateStatus:', err);
    res.status(400).json({ error: `Erreur: ${err.message}` });
  }
};

exports.updateReclamation = async (req, res) => {
  const { id } = req.params;
  const updateData = { ...req.body };

  // Ajout de logs pour debug
  console.log('--- [updateReclamation] ---');
  console.log('ID:', id);
  console.log('updateData:', updateData);

  try {
    // Si un utilisateur est assigné, récupérer son nom
    if (updateData.assignedTo) {
      const user = await User.findById(updateData.assignedTo);
      if (user) {
        updateData.assignedTo = user.name;
      }
    }

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
