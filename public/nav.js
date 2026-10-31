const menus = {
  student: [
    { label: 'Home',        href: '/student/home' },
    { label: 'Rental Catalog', href: '/student/rental_catalog' },
    { label: 'My Rental', href: '/student/my_rental' },
    { label: 'Notifications', href: '/student/notifications' }
  ],
  staff: [
    { label: 'Requests', href: '/staff/requests' },
    { label: 'Return Desk', href: '/staff/return_desk'},
    { label: 'Inventory', href: '/staff/inventory'},
    { label: 'Overdue', href: '/staff/overdue' }
  ],
  admin: [
    { label: 'Home', href: '/admin' }
  ]
};

const nav = document.getElementById('nav');
const items = menus[document.body.dataset.role] || [];

items.forEach(item => {
  const a = document.createElement('a');
  a.textContent = item.label;
  a.href = item.href;
  if (location.pathname === item.href) a.className = 'active';   // highlight current tab
  nav.appendChild(a);
});

const logout = document.createElement('a');
logout.textContent = 'Log out';
logout.href = '/logout';
nav.appendChild(logout);

// Staff: show how many returned items are waiting at the return desk
// Counter on a menu link: staff -> Return Desk, student -> Notifications
const badges = {
  staff:   { href: '/staff/return_desk',     label: 'Return Desk',   url: '/staff/api/return-desk/count' },
  student: { href: '/student/notifications', label: 'Notifications', url: '/student/api/notifications/count' }
};
const badge = badges[document.body.dataset.role];

if (badge) {
  const link = [...nav.querySelectorAll('a')].find(a => a.getAttribute('href') === badge.href);

  const updateBadge = async () => {
    try {
      const res = await fetch(badge.url);
      if (!res.ok) return;
      const { count } = await res.json();
      link.textContent = badge.label + (count > 0 ? ' (' + count + ')' : '');
    } catch { /* ignore network errors */ }
  };

  if (link) {
    window.refreshBadge = updateBadge;      // pages can call refreshBadge() after a change
    updateBadge();
    setInterval(updateBadge, 30000);
  }
}