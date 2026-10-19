const menus = {
  student: [
    { label: 'Home',        href: '/student/home' },
    { label: 'Rental Catalog', href: '/student/rental_catalog' },
    { label: 'My Rental', href: '/student/my_rental' }
  ],
  staff: [
    { label: 'Home', href: '/staff' }
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