const IDLE_MINUTES = 15;          // a session silent for this long no longer holds the account
const POLICY = 'replace-old';        // 'deny-new': a second login is refused
                                  // 'replace-old': a new login ends the older session
const IDLE_MS = IDLE_MINUTES * 60 * 1000;

const active = new Map();         // user_id -> { sid, lastSeen }

// who holds this account right now? (nobody, if the holder has been silent too long)
function holder(userId) {
  const e = active.get(userId);
  return e && Date.now() - e.lastSeen < IDLE_MS ? e : undefined;
}

// may this browser log in to the account? (sid = the session id of the browser that is logging in)
function canLogin(userId, sid) {
  if (POLICY === 'replace-old') return true;
  const e = holder(userId);
  return !e || e.sid === sid;     // free, or it is this very browser
}

function claim(userId, sid) {
  active.set(userId, { sid, lastSeen: Date.now() });
}

// called on every protected request: is this the session that holds the account?
function check(userId, sid) {
  const e = active.get(userId);
  if (!e) { claim(userId, sid); return true; }   // nobody recorded (for example after a restart)
  if (e.sid !== sid) return false;               // somebody else holds it now
  e.lastSeen = Date.now();
  return true;
}

function release(userId, sid) {
  const e = active.get(userId);
  if (e && e.sid === sid) active.delete(userId);
}

module.exports = { canLogin, claim, check, release };