const menus = {
  student: [
    { label: 'Home',        href: '/student/home' },
    { label: 'Rental Catalog', href: '/student/rental_catalog' },
    { label: 'My Rental', href: '/student/my_rental' }
  ],
  staff: [
    { label: 'Requests', href: '/staff/requests' },
    { label: 'Return Desk', href: '/staff/return_desk'}
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
if (document.body.dataset.role === 'staff') {
  const deskLink = [...nav.querySelectorAll('a')]
    .find(a => a.getAttribute('href') === '/staff/return_desk');

  const updateBadge = async () => {
    try {
      const res = await fetch('/staff/api/return-desk/count');
      if (!res.ok) return;
      const { count } = await res.json();
      deskLink.textContent = 'Return Desk' + (count > 0 ? ' (' + count + ')' : '');
    } catch { /* ignore network errors */ }
  };

  if (deskLink) {
    updateBadge();
    setInterval(updateBadge, 30000);
  }
}