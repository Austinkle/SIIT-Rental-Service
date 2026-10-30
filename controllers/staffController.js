const path = require('path');
const db = require('../db');

const view = name => path.join(__dirname, '..', 'views', 'staff', name + '.html');

exports.requestsPage = (req, res) => res.sendFile(view('requests'));

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