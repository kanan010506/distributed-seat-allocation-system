const express = require('express');
const router = express.Router();
const choiceController = require('../controllers/choice.controller');
const { authenticate, authorize } = require('../middleware/auth');

router.use(authenticate);
router.use(authorize('Student'));

router.get('/', choiceController.getChoices);
router.post('/', choiceController.addChoices); 
router.delete('/:choiceId', choiceController.deleteChoice);
router.put('/reorder', choiceController.reorderChoices);

module.exports = router;
