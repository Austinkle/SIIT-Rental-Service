const path = require('path');
const db = require('../db');

exports.dashboardPage = (req, res) =>
  res.sendFile(path.join(__dirname, '..', 'views', 'admin', 'dashboard.html'));

exports.getUsers = async (req, res) => {
  const [rows] = await db.query(
    'SELECT user_id, first_name, last_name, email, user_type FROM `user` ORDER BY user_id');
  res.json(rows);
};