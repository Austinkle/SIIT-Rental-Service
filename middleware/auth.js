const sessions = require('./singleSession');

function requireRole(...roles) {
  return (req, res, next) => {
    const user = req.session.user;
    const isApi = req.originalUrl.includes('/api/');

    // not logged in
    if (!user) {
      return isApi ? res.status(401).json({ error: 'Please log in' })
                   : res.redirect('/login.html?login=required');
    }

    // logged in, but another browser now holds this account: end this session
    if (!sessions.check(user.id, req.sessionID)) {
      return req.session.destroy(() => {
        if (isApi) res.status(401).json({ error: 'Access denied', reason: 'other-device' });
        else res.redirect('/login.html?reason=other-device');
      });
    }

    // logged in, but the wrong role
    if (!roles.includes(user.role)) {
      return isApi ? res.status(403).json({ error: 'Not allowed' })
                   : res.status(403).send('Not allowed');
    }
    next();
  };
}

module.exports = { requireRole };