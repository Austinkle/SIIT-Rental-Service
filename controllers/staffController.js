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