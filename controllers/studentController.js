const path = require('path');
const db = require('../db');

const view = name => path.join(__dirname, '..', 'views', 'student', name + '.html');
const MAX_ADVANCE_DAYS = 14;   // how far ahead a student may book
const MAX_LOAN_DAYS = 7;       // longest allowed loan
const DAY = 24 * 60 * 60 * 1000;
const CONDITIONS = ['Good', 'Minor Wear', 'Damage'];
// ----- pages -----
exports.homePage = (req, res) => res.sendFile(view('home'));
exports.rental_catalog_Page = (req, res) => res.sendFile(view('rental_catalog'));
exports.my_rental_Page = (req, res) => res.sendFile(view('my_rental'));


// ----- data -----
exports.getMyRequests = async (req, res) => {
  const [rows] = await db.query(
    `SELECT e.name AS equipment, br.location, br.borrow_date, br.due_date,
            br.request_date, br.status
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
  const location = req.query.location || null; // Read location query parameter
  const active = req.query.status || null; // Read location query parameter
  const [rows] = await db.query(
    `SELECT e.equipment_id, e.name, c.category_name, e.description, e.status, e.location,
        e.available_quantity, e.total_quantity
   FROM equipment e
   JOIN category c ON c.category_id = e.category_id
  WHERE e.status = 'active'
    AND e.deleted_at IS NULL
    AND (e.name LIKE ? OR c.category_name LIKE ?)
    AND (? IS NULL OR e.category_id = ?)
    AND (? IS NULL OR e.location = ?)
  ORDER BY e.name
  LIMIT 50`,
    [like, like, categoryId, categoryId, location, location]);

  res.json(rows);
};

// 'YYYY-MM-DD' -> Date at local midnight, or null if it is not a real date
function parseDate(s) {
  if (typeof s !== 'string' || !/^\d{4}-\d{2}-\d{2}$/.test(s)) return null;
  const [y, m, d] = s.split('-').map(Number);
  const date = new Date(y, m - 1, d);
  const real = date.getFullYear() === y && date.getMonth() === m - 1 && date.getDate() === d;
  return real ? date : null;      // rejects things like 2026-02-31
}

exports.createRequest = async (req, res) => {
  const equipmentId = Number(req.body.equipment_id);
  if (!Number.isInteger(equipmentId)) return res.status(400).json({ error: 'Invalid equipment' });

  const borrow = parseDate(req.body.borrow_date);
  const due = parseDate(req.body.due_date);
  if (!borrow || !due) return res.status(400).json({ error: 'Choose a borrow date and a due date' });

  const today = new Date();
  today.setHours(0, 0, 0, 0);
  const daysAhead = Math.round((borrow - today) / DAY);
  const loanDays = Math.round((due - borrow) / DAY);

  if (daysAhead < 0)
    return res.status(400).json({ error: 'Borrow date cannot be in the past' });
  if (daysAhead > MAX_ADVANCE_DAYS)
    return res.status(400).json({ error: 'You can book at most ' + MAX_ADVANCE_DAYS + ' days ahead' });
  if (loanDays < 0)
    return res.status(400).json({ error: 'Due date cannot be before the borrow date' });
  if (loanDays > MAX_LOAN_DAYS)
    return res.status(400).json({ error: 'You can borrow for at most ' + MAX_LOAN_DAYS + ' days' });

  try {
    // INSERT ... SELECT copies the location from the equipment row, and only
    // inserts if that equipment exists and is still active
    const [result] = await db.query(
      `INSERT INTO borrow_request (user_id, equipment_id, borrow_date, due_date, location)
       SELECT ?, e.equipment_id, ?, ?, e.location
         FROM equipment e
        WHERE e.equipment_id = ? AND e.status = 'active' AND e.deleted_at IS NULL`,
      [req.session.user.id,
       req.body.borrow_date + ' 00:00:00',    // start of the borrow day
       req.body.due_date + ' 23:59:59',       // end of the due day
       equipmentId]);

    if (result.affectedRows === 0)
      return res.status(404).json({ error: 'This equipment is not available' });
    res.json({ ok: true });
  } catch (err) {
    // messages from your triggers, e.g. "Only students can submit borrow requests"
    if (err.sqlState === '45000') return res.status(400).json({ error: err.sqlMessage });
    throw err;
  }
};



exports.getCategories = async (req, res) => {
  const [rows] = await db.query(
    'SELECT category_id, category_name FROM category ORDER BY category_name');
  res.json(rows);
};

exports.getLocation = async (req, res) => {
  const [rows] = await db.query(
    'SELECT DISTINCT location FROM equipment ORDER BY location');
  res.json(rows);
};

exports.getMyTransaction = async (req, res) => {
  const [rows] = await db.query(
    `SELECT e.name AS equipment, bt.transaction_id, bt.location,
            bt.borrow_date, bt.due_date, bt.status,
            bt.close_order + 0 AS closed, bt.flag_damage + 0 AS flagged
       FROM borrow_transaction bt
       JOIN equipment e ON e.equipment_id = bt.equipment_id
      WHERE bt.borrower_id = ?
      ORDER BY bt.borrow_date DESC`, [req.session.user.id]);
  res.json(rows);
};


exports.returnTransaction = async (req, res) => {
  const id = Number(req.params.id);
  if (!Number.isInteger(id)) return res.status(400).json({ error: 'Invalid rental' });

  const condition = typeof req.body.condition === 'string' ? req.body.condition : '';
  const note = typeof req.body.note === 'string' ? req.body.note.replace(/\s+/g, ' ').trim() : '';

  if (!CONDITIONS.includes(condition))
    return res.status(400).json({ error: 'Choose the condition of the item' });
  if (condition === 'Damage' && !note)
    return res.status(400).json({ error: 'Please describe the damage' });

  // both parts go into the one column condition_at_return, e.g. "Minor Wear: small scratch"
  const value = note ? condition + ': ' + note : condition;
  if (value.length > 100)
    return res.status(400).json({ error: 'Details are too long (max ' + (98 - condition.length) + ' characters)' });

  try {
    const [result] = await db.query(
      "UPDATE borrow_transaction SET status = 'returned', condition_at_return = ? " +
      "WHERE transaction_id = ? AND borrower_id = ? AND status IN ('borrowed', 'overdue')",
      [value, id, req.session.user.id]);

    if (result.affectedRows === 0)
      return res.status(404).json({ error: 'Rental not found or already returned' });
    res.json({ ok: true });
  } catch (err) {
    if (err.sqlState === '45000') return res.status(400).json({ error: err.sqlMessage });
    throw err;
  }
};

exports.notificationsPage = (req, res) => res.sendFile(view('notifications'));

exports.getNotifications = async (req, res) => {
  const [rows] = await db.query(
    `SELECT notification_id, type, message, created_at, is_read
       FROM notification
      WHERE user_id = ?
      ORDER BY created_at DESC
      LIMIT 100`, [req.session.user.id]);
  res.json(rows);
};

exports.getNotificationCount = async (req, res) => {
  const [rows] = await db.query(
    'SELECT COUNT(*) AS n FROM notification WHERE user_id = ? AND is_read = 0',
    [req.session.user.id]);
  res.json({ count: rows[0].n });
};

exports.markNotificationRead = async (req, res) => {
  const id = Number(req.params.id);
  if (!Number.isInteger(id)) return res.status(400).json({ error: 'Invalid notification' });

  // "AND user_id = ?" means a student can only mark their own notifications
  await db.query('UPDATE notification SET is_read = 1 WHERE notification_id = ? AND user_id = ?',
    [id, req.session.user.id]);
  res.json({ ok: true });
};

exports.markAllNotificationsRead = async (req, res) => {
  await db.query('UPDATE notification SET is_read = 1 WHERE user_id = ? AND is_read = 0',
    [req.session.user.id]);
  res.json({ ok: true });
};
