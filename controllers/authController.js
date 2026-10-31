const bcrypt = require('bcrypt');
const db = require('../db');

const ALLOWED_EMAIL_DOMAIN = '@g.siit.tu.ac.th';   // set to null to accept any email while testing
const BCRYPT_COST = 12;                            // each +1 doubles the hashing time

// JSON can contain numbers, arrays or objects, so only accept real strings
const text = v => (typeof v === 'string' ? v.trim() : '');

exports.signup = async (req, res) => {
  const body = req.body || {};
  const firstName = text(body.first_name);
  const lastName  = text(body.last_name);
  const studentId = text(body.student_id);
  const email     = text(body.email).toLowerCase();
  const major     = text(body.major);
  const password  = typeof body.password === 'string' ? body.password : '';   // never trim a password
  const year      = body.year === '' || body.year == null ? null : Number(body.year);

  // ---- validation: the browser checks are only for convenience, this is the real check ----
  const fail = msg => res.status(400).json({ error: msg });

  if (!firstName || firstName.length > 50 || !lastName || lastName.length > 50)
    return fail('Enter your first and last name (max 50 characters each)');
  if (!/^\d{10}$/.test(studentId))
    return fail('Student ID must be 10 digits');
  if (email.length > 100 || !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email))
    return fail('Enter a valid email address');
  if (ALLOWED_EMAIL_DOMAIN && !email.endsWith(ALLOWED_EMAIL_DOMAIN))
    return fail('Use your university email (' + ALLOWED_EMAIL_DOMAIN + ')');
  if (password.length < 8)
    return fail('Password must be at least 8 characters');
  if (Buffer.byteLength(password, 'utf8') > 72)
    return fail('Password is too long (max 72 bytes)');
  if (password.toLowerCase() === email)
    return fail('Password cannot be the same as your email');
  if (major.length > 50)
    return fail('Major is too long');
  if (year !== null && !(Number.isInteger(year) && year >= 1 && year <= 4))
    return fail('Year must be a number from 1 to 4');

  // ---- hash, then save through the stored procedure ----
  const hash = await bcrypt.hash(password, BCRYPT_COST);

  try {
    await db.execute('CALL sp_create_student(?,?,?,?,?,?,?,?)',
      [firstName, lastName, email, hash, null, studentId, major || null, year]);
    res.status(201).json({ ok: true });
  } catch (err) {
    if (err.code === 'ER_DUP_ENTRY') {                 // unique keys from your schema
      const msg = err.sqlMessage || '';
      if (msg.includes('user_email_unique'))
        return fail('This email is already registered. Try signing in.');
      if (msg.includes('student_student_id_unique'))
        return fail('This student ID is already registered.');
    }
    throw err;   // anything else: server.js returns a generic "Server error"
  }
};