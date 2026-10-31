const express = require('express');
const { requireRole } = require('../middleware/auth');
const wrap = require('../middleware/wrap');
const ctrl = require('../controllers/adminController');

const router = express.Router();
router.use(requireRole('admin'));

router.get('/', ctrl.dashboardPage);

router.get('/api/users', wrap(ctrl.getUsers));
router.post('/api/users', wrap(ctrl.createUser));

router.get('/api/categories', wrap(ctrl.getCategories));
router.post('/api/categories', wrap(ctrl.createCategory));

router.get('/api/equipment', wrap(ctrl.getEquipment));
router.post('/api/equipment', wrap(ctrl.addEquipment));
router.patch('/api/equipment/:id/status', wrap(ctrl.setEquipmentStatus));
router.delete('/api/equipment/:id', wrap(ctrl.deleteEquipment));

module.exports = router;
