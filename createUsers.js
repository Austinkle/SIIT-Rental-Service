const bcrypt = require('bcrypt');
const db = require('./db');

(async () => {
  const hash1 = await bcrypt.hash('1234', 12);   // 12 = how slow/strong the hashing is
  const hash2 = await bcrypt.hash('1234', 12);
  const hash3 = await bcrypt.hash('1234', 12);

  // order of values must match the procedure parameters
  await db.query('CALL sp_create_student(?,?,?,?,?,?,?,?)',
    ['Peter', 'Parker', '6722771234@g.siit.tu.ac.th', hash1, null, 6501234567, 'CPE', 2]);
  await db.query('CALL sp_create_staff(?,?,?,?,?,?)',
    ['Tony', 'Stark', 'staff2@example.com', hash2, null, 7001]);
  await db.query('CALL sp_create_admin(?,?,?,?,?,?)',
    ['Mary', 'Jane', 'admin2@example.com', hash3, null, 9001]);

  console.log('Users created');
  process.exit();
})();