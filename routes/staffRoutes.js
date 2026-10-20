const express = require('express');
const { requireRole } = require('../middleware/auth');
const wrap = require('../middleware/wrap');
const ctrl = require('../controllers/staffController');

const router = express.Router();
router.use(requireRole('staff', 'admin'));

router.get('/', ctrl.requestsPage);
router.get('/requests', ctrl.requestsPage);

router.get('/api/pending-requests', wrap(ctrl.getPending));

module.exports = router;