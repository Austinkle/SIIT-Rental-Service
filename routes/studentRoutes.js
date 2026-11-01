const express = require('express');
const { requireRole } = require('../middleware/auth');
const wrap = require('../middleware/wrap');
const ctrl = require('../controllers/studentController');

const router = express.Router();

// ===== PUBLIC: no login needed (the catalog pages and their read-only data) =====
// pages
router.get('/',               ctrl.homePage);
router.get('/home',           ctrl.homePage);
router.get('/rental_catalog', ctrl.rental_catalog_Page);

//data
router.get('/api/equipment',  wrap(ctrl.getEquipment));
router.get('/api/categories', wrap(ctrl.getCategories));
router.get('/api/location',   wrap(ctrl.getLocation));

router.use(requireRole('student'));   // protects EVERY route below with one line

// pages
router.get('/my_rental',  ctrl.my_rental_Page);
router.get('/notifications', ctrl.notificationsPage);
router.get('/profile', ctrl.profilePage);

// data
router.get('/api/Myrequests',   wrap(ctrl.getMyRequests));
router.post('/api/requests',  wrap(ctrl.createRequest));
router.get('/api/Mytransaction', wrap(ctrl.getMyTransaction));
router.post('/api/Mytransaction/:id/return', wrap(ctrl.returnTransaction));
router.get('/api/notifications', wrap(ctrl.getNotifications));
router.get('/api/notifications/count', wrap(ctrl.getNotificationCount));
router.post('/api/notifications/read-all', wrap(ctrl.markAllNotificationsRead));
router.post('/api/notifications/:id/read', wrap(ctrl.markNotificationRead));
router.get('/api/profile', wrap(ctrl.getProfile));

module.exports = router;