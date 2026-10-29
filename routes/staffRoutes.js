const express = require('express');
const { requireRole } = require('../middleware/auth');
const wrap = require('../middleware/wrap');
const ctrl = require('../controllers/staffController');

const router = express.Router();
router.use(requireRole('staff', 'admin'));

router.get('/', ctrl.requestsPage);
router.get('/requests', ctrl.requestsPage);

router.get('/api/pending-requests', wrap(ctrl.getPending));
router.post('/api/requests/:id/decision', requireRole('staff'), wrap(ctrl.decideRequest));

router.get('/equipment/new', requireRole('staff'), ctrl.addEquipmentPage);
router.get('/api/categories', wrap(ctrl.getCategories));
router.post('/api/equipment', requireRole('staff'), wrap(ctrl.addEquipment));

module.exports = router;
