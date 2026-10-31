const path = require('path');
const db = require('../db');
const LOCATIONS = ['Rangsit', 'Bangkadi'];

const view = name => path.join(__dirname, '..', 'views', 'staff', name + '.html');

exports.requestsPage = (req, res) => res.sendFile(view('requests'));
exports.inventoryPage = (req, res) => res.sendFile(view('inventory'));

exports.getPending = async (req, res) => {
  const [rows] = await db.query(
    "SELECT br.request_id, CONCAT(u.first_name, ' ', u.last_name) AS student, " +
    "       e.name AS equipment, br.location, br.borrow_date, br.due_date, br.request_date " +
    "  FROM borrow_request br " +
    "  JOIN `user` u ON u.user_id = br.user_id " +
    "  JOIN equipment e ON e.equipment_id = br.equipment_id " +
    " WHERE br.status = 'pending' " +
    " ORDER BY br.borrow_date, br.request_date");
  res.json(rows);
};

exports.decideRequest = async (req, res) => {
  const requestId = Number(req.params.id);
  const action = req.body.action;                      // 'approve' or 'reject'
  if (!Number.isInteger(requestId) || !['approve', 'reject'].includes(action)) {
    return res.status(400).json({ error: 'Invalid request' });
  }
  const newStatus = action === 'approve' ? 'approved' : 'rejected';

  try {
    const [result] = await db.query(
      "UPDATE borrow_request SET status = ?, handled_by = ? " +
      "WHERE request_id = ? AND status = 'pending'",
      [newStatus, req.session.user.id, requestId]);

    if (result.affectedRows === 0) {
      return res.status(404).json({ error: 'Request not found or already handled' });
    }
    res.json({ ok: true });
  } catch (err) {
    // messages written with SIGNAL in the triggers (e.g. "No equipment available")
    if (err.sqlState === '45000') return res.status(400).json({ error: err.sqlMessage });
    throw err;
  }
};

const returnDeskPageFile = view('return_desk');
exports.returnDeskPage = (req, res) => res.sendFile(returnDeskPageFile);

function sendDbError(err, res) {
  if (err.sqlState === '45000') return res.status(400).json({ error: err.sqlMessage });
  throw err;
}

// list of returned items waiting for staff
exports.getReturnDesk = async (req, res) => {
  const [rows] = await db.query(
    `SELECT bt.transaction_id, e.name AS equipment, bt.location,
            CONCAT(u.first_name, ' ', u.last_name) AS student,
            bt.borrow_date, bt.due_date, bt.return_date,
            bt.condition_at_borrow, bt.condition_at_return,
            bt.flag_damage + 0 AS flag_damage,
            p.penalty_id, p.amount, p.paid_status
       FROM borrow_transaction bt
       JOIN equipment e ON e.equipment_id = bt.equipment_id
       JOIN \`user\` u ON u.user_id = bt.borrower_id
       LEFT JOIN penalty p ON p.transaction_id = bt.transaction_id AND p.penalty_type = 'damaged'
      WHERE bt.status = 'returned' AND bt.close_order = 0
      ORDER BY bt.return_date`);
  res.json(rows);
};

// number shown next to the "Return Desk" link
exports.getReturnDeskCount = async (req, res) => {
  const [rows] = await db.query(
    "SELECT COUNT(*) AS n FROM borrow_transaction WHERE status = 'returned' AND close_order = 0");
  res.json({ count: rows[0].n });
};

// "Accept and close order"
exports.closeOrder = async (req, res) => {
  const id = Number(req.params.id);
  if (!Number.isInteger(id)) return res.status(400).json({ error: 'Invalid order' });

  try {
    const [result] = await db.query(
      "UPDATE borrow_transaction SET close_order = 1, checked_by = ? " +
      "WHERE transaction_id = ? AND status = 'returned' AND close_order = 0",
      [req.session.user.id, id]);
    if (result.affectedRows === 0)
      return res.status(404).json({ error: 'Order not found or already closed' });
    res.json({ ok: true });
  } catch (err) { return sendDbError(err, res); }
};

// "Flag damage"
exports.flagDamage = async (req, res) => {
  const id = Number(req.params.id);
  const amount = Math.round(Number(req.body.amount) * 100) / 100;
  const reason = typeof req.body.reason === 'string' ? req.body.reason.replace(/\s+/g, ' ').trim() : '';

  if (!Number.isInteger(id)) return res.status(400).json({ error: 'Invalid order' });
  if (!Number.isFinite(amount) || amount <= 0 || amount > 100000)
    return res.status(400).json({ error: 'Enter an amount between 0.01 and 100000' });
  if (!reason || reason.length > 100)
    return res.status(400).json({ error: 'Enter a reason (max 100 characters)' });

  try {
    const [result] = await db.query(
      "UPDATE borrow_transaction SET flag_damage = 1, damage_amount = ?, damage_reason = ?, checked_by = ? " +
      "WHERE transaction_id = ? AND status = 'returned' AND close_order = 0 AND flag_damage = 0",
      [amount, reason, req.session.user.id, id]);
    if (result.affectedRows === 0)
      return res.status(404).json({ error: 'Order not found, already flagged, or already closed' });
    res.json({ ok: true });
  } catch (err) { return sendDbError(err, res); }
};

// "Mark penalty paid"
exports.markPenaltyPaid = async (req, res) => {
  const id = Number(req.params.id);
  if (!Number.isInteger(id)) return res.status(400).json({ error: 'Invalid penalty' });

  const [result] = await db.query(
    "UPDATE penalty SET paid_status = 'paid' WHERE penalty_id = ? AND paid_status = 'unpaid'", [id]);
  if (result.affectedRows === 0)
    return res.status(404).json({ error: 'Penalty not found or already paid' });
  res.json({ ok: true });
};
// list all equipment
exports.getEquipment = async (req, res) => {
  const q = (req.query.q || '').trim();
  const like = '%' + q + '%';
  const categoryId = Number(req.query.category) || null;   // null means "all categories"
  const location = req.query.location || null;

  const [rows] = await db.query(
    `SELECT e.equipment_id, e.name, c.category_name, e.description, e.status, e.location,
            e.available_quantity, e.total_quantity,
            GREATEST(0, e.total_quantity - e.available_quantity -
              (SELECT COUNT(*) FROM borrow_transaction bt
                WHERE bt.equipment_id = e.equipment_id AND bt.close_order = 0)) AS desk_loans
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
// get categories
exports.getCategories = async (req, res) => {
  const [rows] = await db.query(
    'SELECT category_id, category_name FROM category ORDER BY category_name');
  res.json(rows);
};

// get location
exports.getLocation = async (req, res) => {
  const [rows] = await db.query(
    'SELECT DISTINCT location FROM equipment ORDER BY location');
  res.json(rows);
};

// "Save item" in the Add form
exports.addEquipment = async (req, res) => {
  const b = req.body || {};
  const name = typeof b.name === 'string' ? b.name.replace(/\s+/g, ' ').trim() : '';
  const description = typeof b.description === 'string' ? b.description.trim() : '';
  const categoryId = Number(b.category_id);
  const location = typeof b.location === 'string' ? b.location : '';
  const quantity = b.quantity === '' || b.quantity == null ? 1 : Number(b.quantity);

  if (!name || name.length > 100)
    return res.status(400).json({ error: 'Enter an equipment name (max 100 characters)' });
  if (!Number.isInteger(categoryId) || categoryId < 1)
    return res.status(400).json({ error: 'Choose a category' });
  if (!LOCATIONS.includes(location))
    return res.status(400).json({ error: 'Choose a location' });
  if (!Number.isInteger(quantity) || quantity < 1 || quantity > 100)
    return res.status(400).json({ error: 'Quantity must be a whole number from 1 to 100' });
  if (description.length > 1000)
    return res.status(400).json({ error: 'Description is too long (max 1000 characters)' });

  try {
    // 'Good' is the starting condition note; it is copied to condition_at_borrow when the item is lent
    await db.query('CALL sp_add_equipment(?,?,?,?,?,?,?)',
      [req.session.user.id, name, categoryId, description || null, quantity, 'Good', location]);
    res.status(201).json({ ok: true });
  } catch (err) {
    if (err.code === 'ER_NO_REFERENCED_ROW_2')            // category id does not exist
      return res.status(400).json({ error: 'That category does not exist' });
    return sendDbError(err, res);
  }
};

// "Mark borrowed" / "Mark available"
exports.markEquipment = async (req, res) => {
  const id = Number(req.params.id);
  const action = req.body && req.body.action;
  if (!Number.isInteger(id) || !['borrowed', 'available'].includes(action))
    return res.status(400).json({ error: 'Invalid request' });

  let sql;
  if (action === 'borrowed') {
    // take one unit off the shelf (only if one is on the shelf)
    sql = "UPDATE equipment SET available_quantity = available_quantity - 1 " +
          "WHERE equipment_id = ? AND status = 'active' AND deleted_at IS NULL " +
          "AND available_quantity > 0";
  } else {
    // put one unit back, only if some units are out WITHOUT an open online order
    sql = "UPDATE equipment e SET e.available_quantity = e.available_quantity + 1 " +
          "WHERE e.equipment_id = ? AND e.deleted_at IS NULL " +
          "AND e.total_quantity - e.available_quantity > " +
          "(SELECT COUNT(*) FROM borrow_transaction bt " +
          "  WHERE bt.equipment_id = e.equipment_id AND bt.close_order = 0)";
  }

  try {
    const [result] = await db.query(sql, [id]);
    if (result.affectedRows === 0) {
      return res.status(409).json({ error: action === 'borrowed'
        ? 'No unit of this item is on the shelf'
        : 'Nothing to put back. Units borrowed online come back through the Return Desk' });
    }
    res.json({ ok: true });
  } catch (err) { return sendDbError(err, res); }
};

// "X" (soft delete)
exports.deleteEquipment = async (req, res) => {
  const id = Number(req.params.id);
  if (!Number.isInteger(id)) return res.status(400).json({ error: 'Invalid equipment' });

  try {
    await db.query('CALL sp_delete_equipment(?, ?)', [id, req.session.user.id]);
    res.json({ ok: true });
  } catch (err) { return sendDbError(err, res); }
};

exports.overduePage = (req, res) => res.sendFile(view('overdue'));

// list of overdue rentals: not returned past the due date, or returned late
exports.getOverdue = async (req, res) => {
  const kind = ['all', 'not_returned', 'returned_late'].includes(req.query.kind)
    ? req.query.kind : 'all';

  const [rows] = await db.query(
    `SELECT bt.transaction_id, e.name AS equipment, bt.location,
            CONCAT(u.first_name, ' ', u.last_name) AS student, u.email AS student_email,
            bt.borrow_date, bt.due_date, bt.return_date,
            IF(bt.return_date IS NULL, 'not_returned', 'returned_late') AS kind,
            IF(bt.return_date IS NULL,
               DATEDIFF(CURDATE(), DATE(bt.due_date)),
               DATEDIFF(DATE(bt.return_date), DATE(bt.due_date))) AS days_late,
            (SELECT COUNT(*) FROM notification n
              WHERE n.transaction_id = bt.transaction_id) AS times_notified,
            (SELECT MAX(n.created_at) FROM notification n
              WHERE n.transaction_id = bt.transaction_id) AS last_notified
       FROM borrow_transaction bt
       JOIN equipment e ON e.equipment_id = bt.equipment_id
       JOIN \`user\` u ON u.user_id = bt.borrower_id
      WHERE ( (bt.return_date IS NULL AND bt.status IN ('borrowed', 'overdue') AND bt.due_date < NOW())
           OR (bt.return_date IS NOT NULL AND bt.return_date > bt.due_date) )
        AND (? = 'all'
             OR (? = 'not_returned' AND bt.return_date IS NULL)
             OR (? = 'returned_late' AND bt.return_date IS NOT NULL))
      ORDER BY days_late DESC, bt.due_date
      LIMIT 100`,
    [kind, kind, kind]);
  res.json(rows);
};

// "Notify" button
exports.notifyOverdue = async (req, res) => {
  const id = Number(req.params.id);
  if (!Number.isInteger(id)) return res.status(400).json({ error: 'Invalid rental' });

  // One statement: it only inserts if the rental really is overdue AND the student
  // has not been notified about it in the last 24 hours. The text is built from the database.
  const [result] = await db.query(
    `INSERT INTO notification (user_id, transaction_id, sent_by, type, message)
     SELECT bt.borrower_id, bt.transaction_id, ?,
            IF(bt.return_date IS NULL, 'overdue', 'late_return'),
            IF(bt.return_date IS NULL,
               CONCAT('Overdue: "', e.name, '" was due on ', DATE_FORMAT(bt.due_date, '%d %b %Y'),
                      ' and has not been returned yet. Please return it to the ', bt.location,
                      ' library counter as soon as possible.'),
               CONCAT('Late return: "', e.name, '" was due on ', DATE_FORMAT(bt.due_date, '%d %b %Y'),
                      ' and was returned on ', DATE_FORMAT(bt.return_date, '%d %b %Y'),
                      '. Please return items on time.'))
       FROM borrow_transaction bt
       JOIN equipment e ON e.equipment_id = bt.equipment_id
      WHERE bt.transaction_id = ?
        AND ( (bt.return_date IS NULL AND bt.status IN ('borrowed', 'overdue') AND bt.due_date < NOW())
           OR (bt.return_date IS NOT NULL AND bt.return_date > bt.due_date) )
        AND NOT EXISTS (SELECT 1 FROM notification n
                         WHERE n.transaction_id = bt.transaction_id
                           AND n.created_at > NOW() - INTERVAL 1 DAY)`,
    [req.session.user.id, id]);

  if (result.affectedRows === 0)
    return res.status(409).json({
      error: 'This rental is not overdue, or the student was already notified in the last 24 hours' });
  res.json({ ok: true });
};