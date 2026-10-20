const path = require('path');
const db = require('../db');

const view = name => path.join(__dirname, '..', 'views', 'staff', name + '.html');

exports.requestsPage = (req, res) => res.sendFile(view('requests'));

exports.getPending = async (req, res) => {
  const [rows] = await db.query(
    "SELECT CONCAT(u.first_name, ' ', u.last_name) AS student, " +
    "       e.name AS equipment, br.request_date, br.request_id" +
    "  FROM borrow_request br " +
    "  JOIN `user` u ON u.user_id = br.user_id " +
    "  JOIN equipment e ON e.equipment_id = br.equipment_id " +
    " WHERE br.status = 'pending' " +
    " ORDER BY br.request_date");
  res.json(rows);
};