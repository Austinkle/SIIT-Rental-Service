const path = require('path');
const db = require('../db');

const view = name => path.join(__dirname, '..', 'views', 'student', name + '.html');

// ----- pages -----
exports.homePage = (req, res) => res.sendFile(view('home'));
exports.rental_catalog_Page = (req, res) => res.sendFile(view('rental_catalog'));
exports.my_rental_Page = (req, res) => res.sendFile(view('my_rental'));

// ----- data -----
exports.getEquipment = async (req, res) => {
  const [rows] = await db.query(
    "SELECT equipment_id, name, available_quantity FROM equipment WHERE status = 'active'");
  res.json(rows);
};

exports.getMyRequests = async (req, res) => {
  const [rows] = await db.query(
    `SELECT e.name AS equipment, br.request_date, br.status
       FROM borrow_request br
       JOIN equipment e ON e.equipment_id = br.equipment_id
      WHERE br.user_id = ?
      ORDER BY br.request_date DESC`, [req.session.user.id]);
  res.json(rows);
};

exports.createRequest = async (req, res) => {
  const equipmentId = Number(req.body.equipment_id);
  if (!Number.isInteger(equipmentId)) return res.status(400).json({ error: 'Invalid equipment' });

  // user id comes from the session, never from the browser
  await db.query('INSERT INTO borrow_request (user_id, equipment_id) VALUES (?, ?)',
    [req.session.user.id, equipmentId]);
  res.json({ ok: true });
};