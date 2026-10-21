const express = require('express');
const { requireRole } = require('../middleware/auth');
const wrap = require('../middleware/wrap');
const ctrl = require('../controllers/studentController');

const router = express.Router();

router.use(requireRole('student'));   // protects EVERY route below with one line

// pages
router.get('/home', ctrl.homePage);
router.get('/', ctrl.homePage);
router.get('/rental_catalog',  ctrl.rental_catalog_Page);
router.get('/my_rental',  ctrl.my_rental_Page);


// data
router.get('/api/equipment',  wrap(ctrl.getEquipment));
router.get('/api/requests',   wrap(ctrl.getMyRequests));
router.post('/api/requests',  wrap(ctrl.createRequest));
router.get('/api/categories', wrap(ctrl.getCategories));

module.exports = router;