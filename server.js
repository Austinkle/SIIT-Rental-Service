const express = require('express');
const session = require('express-session');
const bcrypt = require('bcrypt');
const path = require('path');
const db = require('./db');
const wrap = require('./middleware/wrap');

const app = express();

// ---------- Setup ----------
app.use(express.urlencoded({ extended: true }));   // lets Express read the login form
app.use(express.json());
app.use(session({
  secret: 'change-this-to-a-long-random-text',     // signs the session cookie
  resave: false,
  saveUninitialized: false
}));
app.use(express.static(path.join(__dirname, 'public')));   // login.html + shared.js

// ---------- Home, login, logout ----------
app.get('/', (req, res) => {
  const u = req.session.user;
  res.redirect(u ? '/' + u.role : '/login.html');
});

app.post('/login', wrap(async (req, res) => {
  const { email, password } = req.body;
  if (!email || !password) return res.status(400).send('Enter email and password');

  const [rows] = await db.query(
    'SELECT user_id, password_hash, user_type FROM `user` WHERE email = ?', [email]);
  const user = rows[0];

  // Same message for "no such email" and "wrong password"
  if (!user || !(await bcrypt.compare(password, user.password_hash))) {
    return res.status(401).send('Wrong email or password');
  }

  req.session.user = { id: user.user_id, role: user.user_type };   // remember who is logged in
  res.redirect('/' + user.user_type);                              // /student, /staff or /admin
}));

app.get('/logout', (req, res) => {
  req.session.destroy(() => res.redirect('/login.html'));
});

// ---------- Role routes (page and /api routes) ----------
app.use('/student', require('./routes/studentRoutes'));
app.use('/staff',   require('./routes/staffRoutes'));
app.use('/admin',   require('./routes/adminRoutes'));


// ---------- Error handler (must be last) ----------
app.use((err, req, res, next) => {
  console.error(err);
  res.status(500).send('Server error');
});

app.listen(3000, () => console.log('Running on http://localhost:3000'));