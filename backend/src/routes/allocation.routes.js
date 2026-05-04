const express = require('express');
const router = express.Router();
const allocationController = require('../controllers/allocation.controller');
const { authenticate, authorize } = require('../middleware/auth');

router.use(authenticate);

router.get('/me', authorize('Student'), allocationController.getMyAllocation);
router.post('/run', authorize('Admin'), allocationController.runAllocation);

module.exports = router;
