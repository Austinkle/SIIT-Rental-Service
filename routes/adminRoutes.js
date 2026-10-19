const express = require('express');
const { requireRole } = require('../middleware/auth');
const wrap = require('../middleware/wrap');
const ctrl = require('../controllers/adminController');

const router = express.Router();
router.use(requireRole('admin'));

router.get('/', ctrl.dashboardPage);
router.get('/api/users', wrap(ctrl.getUsers));

module.exports = router;