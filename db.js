const mysql = require('mysql2/promise');

// A pool reuses connections, so every request doesn't open a new one
module.exports = mysql.createPool({
  host: 'localhost',
  user: 'equip_app',                       // the limited account from section 3
  password: 'choose_a_strong_password',    // same password as in the grants file
  database: 'equipment_borrow'
});