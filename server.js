const express = require('express');
const session = require('express-session');
const rateLimit = require('express-rate-limit');
const bcrypt = require('bcrypt');
const path = require('path');
const db = require('./db');
const wrap = require('./middleware/wrap');
const auth = require('./controllers/authController');

const app = express();

// ---------- Setup ----------
app.use(express.urlencoded({ extended: true }));
app.use(express.json());
app.use(session({
  secret: process.env.SESSION_SECRET || 'change-this-to-a-long-random-text',
  resave: false,
  saveUninitialized: false,
  cookie: {
    httpOnly: true,                // JavaScript in the page cannot read the cookie
    sameSite: 'lax',               // not sent with most cross-site requests
    maxAge: 1000 * 60 * 60 * 8     // 8 hours
    // secure: true                // turn on when the site runs on https
  }
}));
app.use(express.static(path.join(__dirname, 'public')));

// ---------- Rate limits (per IP, per 15 minutes) ----------
const signupLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, limit: 10,
  standardHeaders: true, legacyHeaders: false,
  message: { error: 'Too many attempts. Please try again later.' }
});
const loginLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, limit: 20,
  standardHeaders: true, legacyHeaders: false,
  message: 'Too many attempts. Please try again later.'
});

// ---------- Home, sign-up, login, logout ----------
app.get('/', (req, res) => {
  const u = req.session.user;
  res.redirect(u ? '/' + u.role : '/login.html');
});

app.post('/signup', signupLimiter, wrap(auth.signup));

app.post('/login', loginLimiter, wrap(async (req, res) => {
  const email = typeof req.body.email === 'string' ? req.body.email.trim().toLowerCase() : '';
  const password = typeof req.body.password === 'string' ? req.body.password : '';
  if (!email || !password) return res.redirect('/login.html?error=1');

  const [rows] = await db.query(
    'SELECT user_id, password_hash, user_type FROM `user` WHERE email = ?', [email]);
  const user = rows[0];

  // Same result for "no such email" and "wrong password"
  if (!user || !(await bcrypt.compare(password, user.password_hash))) {
    return res.redirect('/login.html?error=1');
  }

  req.session.user = { id: user.user_id, role: user.user_type };
  res.redirect('/' + user.user_type);
}));

app.get('/logout', (req, res) => {
  req.session.destroy(() => res.redirect('/login.html'));
});

// ---------- Role routes ----------
app.use('/student', require('./routes/studentRoutes'));
app.use('/staff',   require('./routes/staffRoutes'));
app.use('/admin',   require('./routes/adminRoutes'));

// ---------- Error handler (must be last) ----------
app.use((err, req, res, next) => {
  console.error(err);
  res.status(500).send('Server error');
});

app.listen(3000, () => console.log('Running on http://localhost:3000'));