// Prints the MySQL error code of a database error that a controller handles itself.
module.exports = function logDb(err) {
  console.warn('[MySQL ' + (err.errno || '?') + ' ' + (err.code || '') +
               ' | SQLSTATE ' + (err.sqlState || '?') + '] ' + (err.sqlMessage || err.message));
};