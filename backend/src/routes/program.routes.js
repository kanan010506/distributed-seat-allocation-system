const express = require('express');
const router = express.Router();
const programController = require('../controllers/program.controller');

// Making these public for now so students can view them before/after login
router.get('/institutes', programController.getInstitutes);
router.get('/', programController.getPrograms);
router.get('/:programId/matrix', programController.getSeatMatrix);

module.exports = router;
