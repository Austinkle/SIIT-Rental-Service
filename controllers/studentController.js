const path = require('path');
const db = require('../db');

const view = name => path.join(__dirname, '..', 'views', 'student', name + '.html');

// ----- pages -----
exports.homePage = (req, res) => res.sendFile(view('home'));
exports.rental_catalog_Page = (req, res) => res.sendFile(view('rental_catalog'));
exports.my_rental_Page = (req, res) => res.sendFile(view('my_rental'));

// ----- data -----
exports.getMyRequests = async (req, res) => {
  const [rows] = await db.query(
    `SELECT e.name AS equipment, br.request_date, br.status
       FROM borrow_request br
       JOIN equipment e ON e.equipment_id = br.equipment_id
      WHERE br.user_id = ?
      ORDER BY br.request_date DESC`, [req.session.user.id]);
  res.json(rows);
};

exports.getEquipment = async (req, res) => {
  const q = (req.query.q || '').trim();
  const like = '%' + q + '%';
  const categoryId = Number(req.query.category) || null;   // null means "all categories"

  const [rows] = await db.query(
    `SELECT e.equipment_id, e.name, c.category_name, e.available_quantity, e.status
       FROM equipment e
       JOIN category c ON c.category_id = e.category_id
      WHERE e.status = 'active'
        AND e.deleted_at IS NULL
        AND (e.name LIKE ? OR c.category_name LIKE ?)
        AND (? IS NULL OR e.category_id = ?)
      ORDER BY e.name
      LIMIT 50`,
    [like, like, categoryId, categoryId]);

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

exports.getCategories = async (req, res) => {
  const [rows] = await db.query(
    'SELECT category_id, category_name FROM category ORDER BY category_name');
  res.json(rows);
};