// Run once from the project folder:  node seedEquipment.js
// Safe to run again: existing categories / equipment names are skipped.
const db = require('./db');

const STAFF_EMAIL = 'staff1@example.com';   // the staff account made by createUsers.js

const categories = ['Camera', 'Laptop', 'Audio', 'Electronics', 'Accessories'];

// [name, category, description, total_quantity, condition_note]
const equipment = [
  ['Canon EOS R50',        'Camera',      'Mirrorless camera with 18-45mm lens',       3, 'new'],
  ['GoPro Hero 11',        'Camera',      'Action camera with waterproof case',        2, 'good'],
  ['Tripod',               'Camera',      'Adjustable aluminium tripod',               5, 'good'],
  ['Dell Latitude 5420',   'Laptop',      '14-inch laptop, 16GB RAM',                  4, 'good'],
  ['MacBook Air M1',       'Laptop',      '13-inch laptop, 8GB RAM',                   2, 'new'],
  ['Rode Wireless GO II',  'Audio',       'Wireless microphone kit',                   2, 'good'],
  ['Bluetooth Speaker',    'Audio',       'Portable speaker for events',               3, 'fair'],
  ['Arduino Uno Kit',      'Electronics', 'Arduino Uno with sensors and breadboard',   10, 'new'],
  ['Raspberry Pi 4',       'Electronics', '4GB model with power supply and case',      6, 'good'],
  ['HDMI Cable 2m',        'Accessories', 'HDMI 2.0 cable',                            8, 'good'],
  ['USB-C Hub',            'Accessories', '7-in-1 hub (HDMI, USB-A, SD card)',         5, 'good'],
];

(async () => {
  try {
    // 1) find the staff user (sp_add_equipment records who added each item)
    const [staffRows] = await db.query(
      "SELECT user_id FROM `user` WHERE email = ? AND user_type = 'staff'", [STAFF_EMAIL]);
    if (staffRows.length === 0) {
      console.error('Staff user ' + STAFF_EMAIL + ' not found. Run createUsers.js first.');
      process.exit(1);
    }
    const staffId = staffRows[0].user_id;

    // 2) categories
    for (const name of categories) {
      await db.query('INSERT IGNORE INTO category (category_name) VALUES (?)', [name]);
    }
    const [catRows] = await db.query('SELECT category_id, category_name FROM category');
    const categoryId = {};
    catRows.forEach(c => { categoryId[c.category_name] = c.category_id; });

    // 3) equipment, through the stored procedure
    let added = 0;
    for (const [name, category, description, qty, note] of equipment) {
      const [existing] = await db.query(
        'SELECT 1 FROM equipment WHERE name = ? AND deleted_at IS NULL', [name]);
      if (existing.length > 0) continue;

      await db.query('CALL sp_add_equipment(?,?,?,?,?,?)',
        [staffId, name, categoryId[category], description, qty, note]);
      added++;
    }

    console.log('Done. Equipment added: ' + added);
  } catch (err) {
    console.error('Seeding failed:', err.sqlMessage || err.message);
    process.exitCode = 1;
  } finally {
    process.exit();
  }
})();