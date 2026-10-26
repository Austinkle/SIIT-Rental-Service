const mysql = require('mysql2/promise');

require('dotenv').config();

// A pool reuses connections, so every request doesn't open a new one
module.exports = mysql.createPool({
  host: process.env.DB_HOST,
  user: process.env.DB_USER,
  password: process.env.DB_PASS,
  database: process.env.DB_NAME
});