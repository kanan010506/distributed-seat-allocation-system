const express = require('express');
const router = express.Router();
const reportController = require('../controllers/report.controller');
const { authenticate, authorize } = require('../middleware/auth');

router.use(authenticate);
router.use(authorize('Admin'));

router.get('/allocation', reportController.getAllocationReport);
router.get('/allocations', reportController.getAllAllocations);

module.exports = router;
