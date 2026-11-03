// Prints every answer with a status of 400 or higher, together with the message the user saw.
module.exports = (req, res, next) => {
  const sendJson = res.json.bind(res);

  res.json = body => {
    if (res.statusCode >= 400) {
      const who = req.session && req.session.user
        ? req.session.user.role + ' #' + req.session.user.id : 'guest';
      console.warn('[' + res.statusCode + '] ' + req.method + ' ' + req.originalUrl +
                   '  (' + who + ')  ' + (body && body.error ? body.error : ''));
    }
    return sendJson(body);
  };
  next();
};