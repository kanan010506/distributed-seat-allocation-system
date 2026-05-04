const express = require('express');
const router = express.Router();
const studentController = require('../controllers/student.controller');
const { authenticate, authorize } = require('../middleware/auth');

router.get('/me', authenticate, authorize('Student'), studentController.getProfile);

module.exports = router;
