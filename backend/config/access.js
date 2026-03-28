function parseAdminEmails() {
  return (process.env.ADMIN_EMAILS || '')
    .split(',')
    .map((value) => value.trim().toLowerCase())
    .filter(Boolean);
}

function isAdminEmail(email) {
  if (!email) return false;
  return parseAdminEmails().includes(email.trim().toLowerCase());
}

function resolveDefaultRole({ email, source }) {
  if (source === 'admin_web' && isAdminEmail(email)) {
    return 'admin';
  }
  return 'passenger';
}

module.exports = {
  isAdminEmail,
  resolveDefaultRole,
};
