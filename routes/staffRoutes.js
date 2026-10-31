const express = require('express');
const { requireRole } = require('../middleware/auth');
const wrap = require('../middleware/wrap');
const ctrl = require('../controllers/staffController');

const router = express.Router();
router.use(requireRole('staff', 'admin'));

// pages
router.get('/', ctrl.requestsPage);
router.get('/requests', ctrl.requestsPage);
router.get('/return_desk',  requireRole('staff'), ctrl.returnDeskPage);
router.get('/inventory', ctrl.inventoryPage);
router.get('/overdue', requireRole('staff'), ctrl.overduePage);

// data
router.get('/api/pending-requests', wrap(ctrl.getPending));
router.post('/api/requests/:id/decision', requireRole('staff'), wrap(ctrl.decideRequest));
router.get('/api/return-desk',        requireRole('staff'), wrap(ctrl.getReturnDesk));
router.get('/api/return-desk/count',  requireRole('staff'), wrap(ctrl.getReturnDeskCount));
router.post('/api/return-desk/:id/close', requireRole('staff'), wrap(ctrl.closeOrder));
router.post('/api/return-desk/:id/flag',  requireRole('staff'), wrap(ctrl.flagDamage));
router.post('/api/penalties/:id/paid',    requireRole('staff'), wrap(ctrl.markPenaltyPaid));
router.get('/api/equipment',  wrap(ctrl.getEquipment));
router.get('/api/categories', wrap(ctrl.getCategories));
router.get('/api/location', wrap(ctrl.getLocation));
router.post('/api/equipment', requireRole('staff'), wrap(ctrl.addEquipment));
router.post('/api/equipment/:id/mark', requireRole('staff'), wrap(ctrl.markEquipment));
router.delete('/api/equipment/:id', requireRole('staff'), wrap(ctrl.deleteEquipment));
router.get('/api/overdue', requireRole('staff'), wrap(ctrl.getOverdue));
router.post('/api/overdue/:id/notify', requireRole('staff'), wrap(ctrl.notifyOverdue));

module.exports = router;