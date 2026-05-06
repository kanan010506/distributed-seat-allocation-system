// src/routes/college.routes.js
// All routes require a valid JWT AND the 'College' role.

const express    = require('express');
const router     = express.Router();
const { authenticate, authorize } = require('../middleware/auth');
const collegeCtrl = require('../controllers/college.controller');

// Apply auth + College-role guard to every route in this file
router.use(authenticate, authorize('College'));

router.get('/dashboard',                              collegeCtrl.getDashboard);
router.get('/programs',                               collegeCtrl.getPrograms);
router.get('/programs/:programId/seats',              collegeCtrl.getSeatMatrix);
router.get('/allocations',                            collegeCtrl.getAllocations);
router.patch('/allocations/:allocationId/confirm',    collegeCtrl.confirmAdmission);
router.get('/report',                                 collegeCtrl.getReport);

module.exports = router;