const path = require('path');
const bcrypt = require('bcrypt');
const db = require('../db');

const LOCATIONS = ['Rangsit', 'Bangkadi'];
const EQUIPMENT_STATUSES = ['active', 'maintenance', 'retired'];
const EMAIL_RE = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
const MAX_BIGINT = 9223372036854775807n;

const view = name => path.join(__dirname, '..', 'views', 'admin', name + '.html');
const text = value => typeof value === 'string' ? value.replace(/\s+/g, ' ').trim() : '';
const validId = value => /^\d{1,19}$/.test(value) && BigInt(value) > 0n && BigInt(value) <= MAX_BIGINT;

exports.dashboardPage = (req, res) => res.sendFile(view('dashboard'));

exports.getUsers = async (req, res) => {
  const [rows] = await db.query(
    `SELECT u.user_id, u.first_name, u.last_name, u.email, u.user_type,
            s.student_id, st.staff_id, a.admin_id
       FROM \`user\` u
       LEFT JOIN student s ON s.user_id = u.user_id
       LEFT JOIN staff st ON st.user_id = u.user_id
       LEFT JOIN admin a ON a.user_id = u.user_id
      ORDER BY u.user_id`);
  res.json(rows);
};

exports.createUser = async (req, res) => {
  const b = req.body || {};
  const firstName = text(b.first_name);
  const lastName = text(b.last_name);
  const email = text(b.email).toLowerCase();
  const password = typeof b.password === 'string' ? b.password : '';
  const phone = text(b.phone);
  const role = b.user_type;

  if (!['student', 'staff'].includes(role))
    return res.status(400).json({ error: 'Choose student or staff' });
  if (!firstName || firstName.length > 50 || !lastName || lastName.length > 50)
    return res.status(400).json({ error: 'Enter first and last names (max 50 characters each)' });
  if (!email || email.length > 100 || !EMAIL_RE.test(email))
    return res.status(400).json({ error: 'Enter a valid email address (max 100 characters)' });
  if (role === 'student' && !email.endsWith('@g.siit.tu.ac.th'))
    return res.status(400).json({ error: 'Use the student university email domain @g.siit.tu.ac.th' });
  if (password.length < 8 || Buffer.byteLength(password, 'utf8') > 72)
    return res.status(400).json({ error: 'Password must be 8 to 72 bytes long' });
  if (phone.length > 20)
    return res.status(400).json({ error: 'Phone must be 20 characters or fewer' });

  let procedure;
  let params;
  if (role === 'student') {
    const studentId = text(b.student_id);
    const major = text(b.major);
    const yearText = text(b.year);
    const year = yearText ? Number(yearText) : null;
    if (!/^\d{10}$/.test(studentId))
      return res.status(400).json({ error: 'Student ID must contain 10 digits' });
    if (major.length > 50)
      return res.status(400).json({ error: 'Major must be 50 characters or fewer' });
    if (year !== null && (!Number.isInteger(year) || year < 1 || year > 4))
      return res.status(400).json({ error: 'Year must be from 1 to 4' });
    procedure = 'CALL sp_create_student(?,?,?,?,?,?,?,?)';
    params = [firstName, lastName, email, null, phone || null, studentId, major || null, year];
  } else {
    const staffId = text(b.staff_id);
    if (!validId(staffId))
      return res.status(400).json({ error: 'Staff ID must be a positive whole number' });
    procedure = 'CALL sp_create_staff(?,?,?,?,?,?)';
    params = [firstName, lastName, email, null, phone || null, staffId];
  }

  // Hash the password only after all field validation has passed.
  const hash = await bcrypt.hash(password, 12);
  params[3] = hash;

  try {
    await db.query(procedure, params);
    res.status(201).json({ ok: true });
  } catch (err) {
    if (err.code === 'ER_DUP_ENTRY') {
      const detail = err.sqlMessage || '';
      if (detail.includes('student_student_id_unique'))
        return res.status(409).json({ error: 'That student ID is already registered' });
      if (detail.includes('staff_staff_id_unique'))
        return res.status(409).json({ error: 'That staff ID is already registered' });
      return res.status(409).json({ error: 'That email address is already registered' });
    }
    throw err;
  }
};

exports.getCategories = async (req, res) => {
  const [rows] = await db.query(
    `SELECT c.category_id, c.category_name,
            COUNT(e.equipment_id) AS equipment_count
       FROM category c
       LEFT JOIN equipment e ON e.category_id = c.category_id AND e.deleted_at IS NULL
      GROUP BY c.category_id, c.category_name
      ORDER BY c.category_name`);
  res.json(rows);
};

exports.createCategory = async (req, res) => {
  const name = text(req.body && req.body.category_name);
  if (!name || name.length > 50)
    return res.status(400).json({ error: 'Enter a category name (max 50 characters)' });

  try {
    await db.query('INSERT INTO category (category_name) VALUES (?)', [name]);
    res.status(201).json({ ok: true });
  } catch (err) {
    if (err.code === 'ER_DUP_ENTRY')
      return res.status(409).json({ error: 'A category with that name already exists' });
    throw err;
  }
};

exports.getEquipment = async (req, res) => {
  const [rows] = await db.query(
    `SELECT e.equipment_id, e.name, e.description, e.status, e.location,
            e.total_quantity, e.available_quantity, e.deleted_at,
            (e.deleted_at IS NOT NULL) AS is_deleted,
            c.category_id, c.category_name
       FROM equipment e
       JOIN category c ON c.category_id = e.category_id
      ORDER BY e.deleted_at IS NOT NULL, e.name, e.equipment_id`);
  res.json(rows);
};

exports.addEquipment = async (req, res) => {
  const b = req.body || {};
  const name = text(b.name);
  const description = typeof b.description === 'string' ? b.description.trim() : '';
  const categoryId = Number(b.category_id);
  const location = b.location;
  const quantity = b.quantity === '' || b.quantity == null ? 1 : Number(b.quantity);

  if (!name || name.length > 100)
    return res.status(400).json({ error: 'Enter an equipment name (max 100 characters)' });
  if (!Number.isInteger(categoryId) || categoryId < 1)
    return res.status(400).json({ error: 'Choose a category' });
  if (!LOCATIONS.includes(location))
    return res.status(400).json({ error: 'Choose a campus location' });
  if (!Number.isInteger(quantity) || quantity < 1 || quantity > 100)
    return res.status(400).json({ error: 'Quantity must be a whole number from 1 to 100' });
  if (description.length > 1000)
    return res.status(400).json({ error: 'Description must be 1000 characters or fewer' });

  try {
    await db.query('CALL sp_admin_add_equipment(?,?,?,?,?,?,?)',
      [req.session.user.id, name, categoryId, description || null, quantity, 'Good', location]);
    res.status(201).json({ ok: true });
  } catch (err) {
    if (err.code === 'ER_NO_REFERENCED_ROW_2')
      return res.status(400).json({ error: 'That category does not exist' });
    if (err.sqlState === '45000')
      return res.status(400).json({ error: err.sqlMessage || 'Could not add equipment' });
    throw err;
  }
};

exports.setEquipmentStatus = async (req, res) => {
  const id = Number(req.params.id);
  const status = req.body && req.body.status;
  if (!Number.isInteger(id) || id < 1 || !EQUIPMENT_STATUSES.includes(status))
    return res.status(400).json({ error: 'Choose a valid equipment status' });

  const [result] = await db.query(
    'UPDATE equipment SET status = ? WHERE equipment_id = ? AND deleted_at IS NULL', [status, id]);
  if (!result.affectedRows) {
    const [rows] = await db.query(
      'SELECT equipment_id FROM equipment WHERE equipment_id = ? AND deleted_at IS NULL', [id]);
    if (!rows.length)
      return res.status(404).json({ error: 'Equipment not found or already deleted' });
  }
  res.json({ ok: true });
};

exports.deleteEquipment = async (req, res) => {
  const id = Number(req.params.id);
  if (!Number.isInteger(id) || id < 1)
    return res.status(400).json({ error: 'Invalid equipment' });

  try {
    await db.query('CALL sp_admin_delete_equipment(?, ?)', [id, req.session.user.id]);
    res.json({ ok: true });
  } catch (err) {
    if (err.sqlState === '45000')
      return res.status(409).json({ error: err.sqlMessage || 'Could not remove this equipment' });
    throw err;
  }
};
