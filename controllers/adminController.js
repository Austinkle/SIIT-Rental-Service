const path = require('path');
const bcrypt = require('bcrypt');
const db = require('../db');

const BCRYPT_COST = 12;                                // same as authController.js
const STUDENT_ID_PATTERN = /^\d{10}$/;                 // same rule as sign-up: 10 digits
const STAFF_ID_PATTERN = /^\d{4,15}$/;
const EDITABLE_STATUSES = ['active', 'maintenance'];   // 'retired' is only set by removeEquipment

// ----- small helpers -----
// JSON can carry numbers, arrays or objects, so only accept real strings / numbers
const text = v => (typeof v === 'string' ? v.trim() : '');
const int = v => ((typeof v === 'number' || (typeof v === 'string' && v.trim() !== '')) ? Number(v) : NaN);
const fail = (res, msg, code = 400) => res.status(code).json({ error: msg });

// sp_add_equipment and sp_delete_equipment only accept a STAFF user (and equipment.added_by /
// deleted_by are foreign keys to staff), so an admin's own id would be refused. The admin
// therefore picks which staff member a change is recorded under.
// Returns that staff user_id, or null after sending an error response.
async function pickStaff(value, res) {
  const staffId = int(value);
  if (Number.isInteger(staffId)) {
    const [rows] = await db.query('SELECT 1 FROM staff WHERE user_id = ?', [staffId]);
    if (rows.length > 0) return staffId;
  }
  fail(res, 'Choose a staff member to record this change under');
  return null;
}

// ----- page -----
exports.dashboardPage = (req, res) =>
  res.sendFile(path.join(__dirname, '..', 'views', 'admin', 'dashboard.html'));

// ===================== users =====================
exports.getUsers = async (req, res) => {
  const [rows] = await db.query(
    'SELECT user_id, first_name, last_name, email, user_type FROM `user` ORDER BY user_id');
  res.json(rows);
};

// staff members the admin can record equipment changes under
exports.getStaff = async (req, res) => {
  const [rows] = await db.query(
    "SELECT u.user_id, CONCAT(u.first_name, ' ', u.last_name) AS name, u.email " +
    "  FROM staff s " +
    "  JOIN `user` u ON u.user_id = s.user_id " +
    " ORDER BY u.first_name, u.last_name");
  res.json(rows);
};

// Add a student or a staff member. Same rules as sign-up (authController.js), except the
// university e-mail domain is not enforced because an admin is trusted to type real accounts.
exports.createUser = async (req, res) => {
  const b = req.body || {};
  const role = text(b.role);                                   // 'student' or 'staff'
  const firstName = text(b.first_name);
  const lastName = text(b.last_name);
  const email = text(b.email).toLowerCase();
  const phone = text(b.phone);
  const idNumber = text(b.id_number);                          // student_id or staff_id
  const major = text(b.major);
  const password = typeof b.password === 'string' ? b.password : '';   // never trim a password
  const year = b.year === '' || b.year == null ? null : int(b.year);

  if (!['student', 'staff'].includes(role)) return fail(res, 'Choose student or staff');
  if (!firstName || firstName.length > 50 || !lastName || lastName.length > 50)
    return fail(res, 'Enter the first and last name (max 50 characters each)');
  if (role === 'student' && !STUDENT_ID_PATTERN.test(idNumber)) return fail(res, 'Student ID must be 10 digits');
  if (role === 'staff' && !STAFF_ID_PATTERN.test(idNumber)) return fail(res, 'Staff ID must be 4-15 digits');
  if (email.length > 100 || !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email))
    return fail(res, 'Enter a valid email address');
  if (phone && !/^[0-9+\-\s]{6,20}$/.test(phone)) return fail(res, 'Enter a valid phone number');
  if (password.length < 8) return fail(res, 'Password must be at least 8 characters');
  if (Buffer.byteLength(password, 'utf8') > 72) return fail(res, 'Password is too long (max 72 bytes)');
  if (password.toLowerCase() === email) return fail(res, 'Password cannot be the same as the email');
  if (role === 'student') {
    if (major.length > 50) return fail(res, 'Major is too long');
    if (year !== null && !(Number.isInteger(year) && year >= 1 && year <= 4))
      return fail(res, 'Year must be a number from 1 to 4');
  }

  const hash = await bcrypt.hash(password, BCRYPT_COST);

  try {
    // parameter order must match the procedures in equipment_borrow_triggers.sql
    if (role === 'student') {
      await db.query('CALL sp_create_student(?,?,?,?,?,?,?,?)',
        [firstName, lastName, email, hash, phone || null, Number(idNumber), major || null, year]);
    } else {
      await db.query('CALL sp_create_staff(?,?,?,?,?,?)',
        [firstName, lastName, email, hash, phone || null, Number(idNumber)]);
    }
    res.status(201).json({ ok: true });
  } catch (err) {
    if (err.code === 'ER_DUP_ENTRY') {                         // unique keys from the schema
      const msg = err.sqlMessage || '';
      if (msg.includes('user_email_unique')) return fail(res, 'This email is already registered', 409);
      if (msg.includes('student_student_id_unique')) return fail(res, 'This student ID is already registered', 409);
      if (msg.includes('staff_staff_id_unique')) return fail(res, 'This staff ID is already registered', 409);
      return fail(res, 'This email or ID is already registered', 409);
    }
    if (err.sqlState === '45000') return fail(res, err.sqlMessage);
    throw err;
  }
};

// ===================== categories =====================
exports.getCategories = async (req, res) => {
  const [rows] = await db.query(
    'SELECT c.category_id, c.category_name, COUNT(e.equipment_id) AS equipment_count ' +
    '  FROM category c ' +
    '  LEFT JOIN equipment e ON e.category_id = c.category_id AND e.deleted_at IS NULL ' +
    ' GROUP BY c.category_id, c.category_name ' +
    ' ORDER BY c.category_name');
  res.json(rows);
};

exports.createCategory = async (req, res) => {
  const name = text((req.body || {}).category_name);
  if (!name || name.length > 50) return fail(res, 'Enter a category name (max 50 characters)');

  try {
    const [result] = await db.query('INSERT INTO category (category_name) VALUES (?)', [name]);
    res.status(201).json({ ok: true, category_id: result.insertId });
  } catch (err) {
    // category_name is UNIQUE (and case-insensitive), so "camera" clashes with "Camera"
    if (err.code === 'ER_DUP_ENTRY') return fail(res, 'That category already exists', 409);
    throw err;
  }
};

// ===================== equipment =====================
// Everything, including removed items (they stay in the table so the history is kept)
exports.getEquipment = async (req, res) => {
  const [rows] = await db.query(
    "SELECT e.equipment_id, e.name, e.category_id, c.category_name, e.description, " +
    "       e.total_quantity, e.available_quantity, e.condition_note, e.status, e.deleted_at, " +
    "       CONCAT(u.first_name, ' ', u.last_name) AS added_by_name " +
    "  FROM equipment e " +
    "  JOIN category c ON c.category_id = e.category_id " +
    "  LEFT JOIN `user` u ON u.user_id = e.added_by " +
    " ORDER BY (e.deleted_at IS NOT NULL), e.name");
  res.json(rows);
};

// Goes through sp_add_equipment; equipment.added_by becomes the chosen staff member
exports.addEquipment = async (req, res) => {
  const b = req.body || {};
  const name = text(b.name);
  const categoryId = int(b.category_id);
  const quantity = int(b.total_quantity);
  const description = text(b.description);
  const condition = text(b.condition_note);

  if (!name || name.length > 100) return fail(res, 'Enter the equipment name (max 100 characters)');
  if (!Number.isInteger(categoryId) || categoryId < 1) return fail(res, 'Choose a category');
  if (!Number.isInteger(quantity) || quantity < 1 || quantity > 1000)
    return fail(res, 'Quantity must be a whole number from 1 to 1000');
  if (condition.length > 100) return fail(res, 'Condition is too long (max 100 characters)');
  if (description.length > 1000) return fail(res, 'Description is too long (max 1000 characters)');

  const staffId = await pickStaff(b.staff_id, res);
  if (staffId === null) return;

  try {
    const [result] = await db.query('CALL sp_add_equipment(?,?,?,?,?,?)',
      [staffId, name, categoryId, description || null, quantity, condition || null]);
    res.status(201).json({ ok: true, equipment_id: result?.[0]?.[0]?.equipment_id });
  } catch (err) {
    if (err.code === 'ER_NO_REFERENCED_ROW_2') return fail(res, 'That category does not exist');
    if (err.sqlState === '45000') return fail(res, err.sqlMessage);
    throw err;
  }
};

// Switch an item between 'active' (shown in the catalog) and 'maintenance' (hidden).
// 'retired' is not offered here: it is what removeEquipment sets, together with who and when.
exports.setEquipmentStatus = async (req, res) => {
  const equipmentId = int(req.params.id);
  const status = text((req.body || {}).status);
  if (!Number.isInteger(equipmentId) || !EDITABLE_STATUSES.includes(status)) {
    return fail(res, 'Status must be active or maintenance');
  }

  const [rows] = await db.query('SELECT deleted_at FROM equipment WHERE equipment_id = ?', [equipmentId]);
  if (rows.length === 0) return fail(res, 'Equipment not found', 404);
  if (rows[0].deleted_at) return fail(res, 'Removed equipment cannot change status');

  await db.query('UPDATE equipment SET status = ? WHERE equipment_id = ? AND deleted_at IS NULL',
    [status, equipmentId]);
  res.json({ ok: true });
};

// "Remove" = soft delete through sp_delete_equipment: the row stays (status 'retired',
// deleted_by, deleted_at) so old borrow records keep working. It refuses while the item is
// borrowed. The staff member to record comes in the query string: DELETE .../5?staff_id=2
exports.removeEquipment = async (req, res) => {
  const equipmentId = int(req.params.id);
  if (!Number.isInteger(equipmentId)) return fail(res, 'Invalid equipment');

  const staffId = await pickStaff(req.query.staff_id, res);
  if (staffId === null) return;

  try {
    await db.query('CALL sp_delete_equipment(?,?)', [equipmentId, staffId]);
    res.json({ ok: true });
  } catch (err) {
    if (err.sqlState === '45000') {
      return fail(res, err.sqlMessage, err.sqlMessage === 'Equipment not found' ? 404 : 400);
    }
    throw err;
  }
};
