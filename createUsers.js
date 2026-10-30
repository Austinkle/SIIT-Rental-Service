const bcrypt = require('bcrypt');
const db = require('./db');

(async () => {
  const hash = await bcrypt.hash('1234', 12);   // 12 = how slow/strong the hashing is

  // order of values must match the procedure parameters
  await db.query('CALL sp_create_student(?,?,?,?,?,?,?,?)',
    ['Peter', 'Parker', '6722771234@g.siit.tu.ac.th', hash, null, 6501234567, 'CPE', 2]);
  await db.query('CALL sp_create_staff(?,?,?,?,?,?)',
    ['Tony', 'Stark', 'staff1@example.com', hash, null, 7001]);
  await db.query('CALL sp_create_admin(?,?,?,?,?,?)',
    ['Mary', 'Jane', 'admin1@example.com', hash, null, 9001]);

  console.log('Users created');
  process.exit();
})();