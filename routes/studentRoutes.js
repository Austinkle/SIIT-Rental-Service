const express = require('express');
const { requireRole } = require('../middleware/auth');
const wrap = require('../middleware/wrap');
const ctrl = require('../controllers/studentController');

const router = express.Router();

router.use(requireRole('student'));   // protects EVERY route below with one line

// pages
router.get('/',          ctrl.dashboardPage);
router.get('/equipment', ctrl.equipmentPage);
router.get('/requests',  ctrl.requestsPage);

// data
router.get('/api/equipment',  wrap(ctrl.getEquipment));
router.get('/api/requests',   wrap(ctrl.getMyRequests));
router.post('/api/requests',  wrap(ctrl.createRequest));

module.exports = router;