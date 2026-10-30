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
router.get('/return_desk',  requireRole('staff'), ctrl.returnDeskPage);
router.get('/api/return-desk',        requireRole('staff'), wrap(ctrl.getReturnDesk));
router.get('/api/return-desk/count',  requireRole('staff'), wrap(ctrl.getReturnDeskCount));
router.post('/api/return-desk/:id/close', requireRole('staff'), wrap(ctrl.closeOrder));
router.post('/api/return-desk/:id/flag',  requireRole('staff'), wrap(ctrl.flagDamage));
router.post('/api/penalties/:id/paid',    requireRole('staff'), wrap(ctrl.markPenaltyPaid));

module.exports = router;