(function () {
  const { h, icon, fmtDateTime } = UI;
  const role = document.body.dataset.role;

  const menus = {
    student: [
      { label: 'Home',           href: '/student/home' },
      { label: 'Rental Catalog', href: '/student/rental_catalog' },
      { label: 'My Rental',      href: '/student/my_rental' }
    ],
    staff: [
      { label: 'Requests',    href: '/staff/requests' },
      { label: 'Return Desk', href: '/staff/return_desk' },
      { label: 'Inventory',   href: '/staff/inventory' },
      { label: 'Overdue',     href: '/staff/overdue' }
    ],
    admin: [
      { label: 'Home', href: '/admin' }
    ]
  };

  const items = menus[role] || [];
  let bellDot = null;   // red dot on the bell (student only)

  // Normalize route paths (/student -> /student/home, /staff -> /staff/requests)
  let path = location.pathname.replace(/\/$/, '');
  if (path === '/student') path = '/student/home';
  if (path === '/staff') path = '/staff/requests';

  // Orca mark artwork
  function orca(size) {
    const s = document.createElementNS('http://www.w3.org/2000/svg', 'svg');
    s.setAttribute('width', size); s.setAttribute('height', size); s.setAttribute('viewBox', '0 0 24 24');
    s.setAttribute('fill', 'none'); s.setAttribute('aria-hidden', 'true');
    s.innerHTML =
      '<defs><clipPath id="orcaClip' + size + '"><path d="M22.6 10.8C22.2 7.6 19 5.9 15 6.2C13.9 6.3 13.1 6.4 12.4 6.6C11.9 5 11 3.6 9.8 2.6C9.5 4.4 9.4 6.2 9.2 7.9C6.2 9 3.9 11.8 3.6 15C3.5 17.2 5 18.6 7.8 19C10.2 20.2 13.2 20.2 15.8 19C19.2 17.4 22.9 14.3 22.6 10.8Z"/></clipPath></defs>' +
      '<path d="M22.6 10.8C22.2 7.6 19 5.9 15 6.2C13.9 6.3 13.1 6.4 12.4 6.6C11.9 5 11 3.6 9.8 2.6C9.5 4.4 9.4 6.2 9.2 7.9C6.2 9 3.9 11.8 3.6 15C3.5 17.2 5 18.6 7.8 19C10.2 20.2 13.2 20.2 15.8 19C19.2 17.4 22.9 14.3 22.6 10.8Z" fill="#C4B5FD"/>' +
      '<g stroke="#0B0B14" fill="none"><circle cx="14.5" cy="10.3" r="1.6" stroke-width=".9" stroke-dasharray=".75 .75"/><circle cx="14.5" cy="10.3" r="1" stroke-width=".75"/><circle cx="10.6" cy="12.9" r="3" stroke-width="1.15" stroke-dasharray="1.05 .95"/><circle cx="10.6" cy="12.9" r="2.1" stroke-width="1.3"/></g>' +
      '<g clip-path="url(#orcaClip' + size + ')"><ellipse cx="16.2" cy="11" rx="2.4" ry="1.8" transform="rotate(-15 16.2 11)" fill="#fff"/><path d="M12 22C13 17.6 17 14.2 24 12L24 24Z" fill="#fff"/></g>';
    return s;
  }

  // ----- notification bell (student): dropdown with the latest notifications -----
  function buildBell() {
    const TYPES = {
      overdue:     { ic: 'triangle-alert', cls: 'warn' },
      late_return: { ic: 'clock',          cls: 'warn' }
    };
    bellDot = h('span', { class: 'bell-dot', hidden: true });
    const list = h('div', { class: 'notif-list' });
    const markAll = h('button', { type: 'button', class: 'notif-markall', text: 'Mark all as read' });
    const panel = h('div', { class: 'notif-panel', role: 'dialog', 'aria-label': 'Notifications', hidden: true },
      h('div', { class: 'notif-head' }, h('span', { text: 'Notifications' }), markAll),
      list,
      h('a', { class: 'notif-foot', href: '/student/notifications', text: 'View all notifications' }));
    const btn = h('button', { type: 'button', class: 'bell-btn', 'aria-label': 'Notifications',
      'aria-haspopup': 'true', 'aria-expanded': 'false' }, icon('bell', 20), bellDot);
    const wrap = h('div', { class: 'bell-wrap' }, btn, panel);

    async function load() {
      try {
        const res = await fetch('/student/api/notifications');
        if (!res.ok) throw new Error('bad status');
        const rows = (await res.json()).slice(0, 6);
        list.replaceChildren();
        if (rows.length === 0) list.append(h('div', { class: 'notif-empty', text: 'No notifications yet.' }));
        rows.forEach(r => {
          const t = TYPES[r.type] || { ic: 'mail', cls: '' };
          list.append(h('button', { type: 'button', class: 'notif-item' + (r.is_read ? '' : ' unread'), onclick: () => readOne(r) },
            h('span', { class: 'notif-ic ' + t.cls }, icon(t.ic, 16)),
            h('span', { class: 'notif-body' },
              h('span', { class: 'notif-msg', text: r.message }),
              h('span', { class: 'notif-time', text: fmtDateTime(r.created_at) })),
            r.is_read ? null : h('span', { class: 'notif-unread' })));
        });
      } catch {
        list.replaceChildren(h('div', { class: 'notif-empty', text: 'Could not load notifications.' }));
      }
    }

    async function readOne(r) {
      if (r.is_read) return;
      await fetch('/student/api/notifications/' + r.notification_id + '/read', { method: 'POST' }).catch(() => null);
      await load();
      updateBadges();
    }

    markAll.addEventListener('click', async () => {
      await fetch('/student/api/notifications/read-all', { method: 'POST' }).catch(() => null);
      await load();
      updateBadges();
    });

    function setOpen(open) {
      panel.hidden = !open;
      btn.setAttribute('aria-expanded', String(open));
      if (open) load();
    }
    btn.addEventListener('click', () => setOpen(panel.hidden));
    document.addEventListener('click', e => { if (!panel.hidden && !wrap.contains(e.target)) setOpen(false); });
    document.addEventListener('keydown', e => { if (e.key === 'Escape' && !panel.hidden) { setOpen(false); btn.focus(); } });
    return wrap;
  }

  // ----- top bar -----
  const nav = document.getElementById('nav');
  if (nav) {
    nav.className = 'navbar' + (role === 'student' ? '' : ' staff');

    const back = h('button', { type: 'button', 'aria-label': 'Go back', onclick: () => history.back() }, icon('arrow-left', 17));
    const fwd  = h('button', { type: 'button', 'aria-label': 'Go forward', onclick: () => history.forward() }, icon('arrow-right', 17));
    if (history.length <= 1) back.disabled = true;

    const mobileItems = role === 'student' ? items.concat([{ label: 'Notifications', href: '/student/notifications' }]) : items;
    const links = items.map(i => h('a', { href: i.href, class: path === i.href ? 'active' : '', 'data-href': i.href, text: i.label }));
    const mobileLinks = mobileItems.map(i => h('a', { href: i.href, class: path === i.href ? 'active' : '', 'data-href': i.href, text: i.label }));
    const mobile = h('div', { class: 'mobile-menu' }, mobileLinks, h('a', { href: '/logout', class: 'danger', text: 'Sign out' }));
    const toggle = h('button', { type: 'button', class: 'menu-toggle', 'aria-label': 'Menu', 'aria-expanded': 'false',
      onclick: () => { const o = mobile.classList.toggle('open'); toggle.setAttribute('aria-expanded', o); } }, icon('menu', 18, 2));

    nav.append(
      h('div', { class: 'nav-inner' },
        h('div', { class: 'hist' }, back, fwd),
        h('a', { class: 'brand', href: items.length ? items[0].href : '/' },
          h('div', { class: 'brand-mark' }, orca(22)),
          h('div', {},
            h('div', { class: 'brand-name font-display', text: 'SIIT Rental Service' }),
            role === 'student' ? h('div', { class: 'brand-sub', text: 'Library Equipment Rentals · Rangsit & Bangkadi' }) : null)),
        role !== 'student' ? h('span', { class: 'role-tag font-display', text: role.toUpperCase() }) : null,
        h('div', { class: 'nav-links' }, links),
        h('div', { class: 'nav-right' },
          role === 'student' ? buildBell() : null,
          h('a', { class: 'btn-signout', href: '/logout' }, icon('log-out', 14), 'Sign out'),
          toggle)),
      mobile);
  }

  // ----- badges (real numbers from API) -----
  function badgeEl(count, danger) {
    return h('span', { class: 'pill n-badge ' + (danger ? 'red' : 'violet'), style: 'margin-left:6px;padding:1px 6px;font-size:10px', text: String(count) });
  }

  function showBadge(href, count, danger) {
    document.querySelectorAll('[data-href="' + href + '"]').forEach(a => {
      a.querySelector('.n-badge')?.remove();
      if (count > 0) a.append(badgeEl(count, danger));
    });
  }

  const updateBadges = async () => {
    try {
      if (role === 'student') {
        const [txRes, notifRes] = await Promise.all([
          fetch('/student/api/Mytransaction').catch(() => null),
          fetch('/student/api/notifications/count').catch(() => null)
        ]);

        if (txRes && txRes.ok) {
          const rows = await txRes.json();
          showBadge('/student/my_rental', rows.filter(r => r.status === 'overdue').length, true);
        }
        if (notifRes && notifRes.ok) {
          const { count } = await notifRes.json();
          showBadge('/student/notifications', count, false);   // number on the mobile-menu link
          if (bellDot) bellDot.hidden = count === 0;           // red dot on the bell
        }
      } else if (role === 'staff') {
        const res = await fetch('/staff/api/return-desk/count').catch(() => null);
        if (res && res.ok) {
          const { count } = await res.json();
          showBadge('/staff/return_desk', count, false);
        }
      }
    } catch { /* ignore network errors */ }
  };

  window.refreshBadge = updateBadges;
  updateBadges();
  setInterval(updateBadges, 30000);

  // ----- footer (pages with <footer id="footer">) -----
  const foot = document.getElementById('footer');
  if (foot) {
    foot.className = 'site-footer';
    const hours = (n, t) => [h('b', { text: n }), h('span', { text: t })];
    const contact = (ic, t) => h('div', { class: 'c' }, icon(ic, 15), h('span', { text: t }));
    foot.append(h('div', { class: 'in' },
      h('div', { class: 'foot-grid' },
        h('div', {},
          h('div', { class: 'foot-brand' }, h('div', { class: 'm' }, orca(20)),
            h('div', {}, h('div', { class: 'a', text: 'SIIT Rental Service' }), h('div', { class: 'b', text: 'THAMMASAT UNIVERSITY' }))),
          h('p', { text: 'Thammasat University (SIIT) official platform for equipment borrowing across Rangsit and Bangkadi campuses.' })),
        h('div', {},
          h('div', { class: 'foot-h font-display', text: 'Platform' }),
          items.map(i => h('a', { href: i.href, style: 'display:block;font-size:13px;color:#94A3B8;padding:4px 0;text-decoration:none', text: i.label }))),
        h('div', {},
          h('div', { class: 'foot-h font-display', text: 'SIIT Campuses' }),
          h('span', { class: 'campus-pill', text: 'RANGSIT' }),
          h('div', { class: 'hrs' }, hours('Library Counter', 'Mon–Fri 08:15–19:45, Sat 08:15–16:45')),
          h('span', { class: 'campus-pill blue', text: 'BANGKADI' }),
          h('div', { class: 'hrs' }, hours('Library Counter', 'Mon–Fri 08:15–16:45'))),
        h('div', {},
          h('div', { class: 'foot-h font-display', text: 'Contact' }),
          contact('mail', 'rentals@siit.tu.ac.th'),
          contact('phone', 'Main extension: Rangsit - 1501, Bangkadi - 4501'),
          contact('map-pin', 'Rangsit: 1st Floor, SIIT Main Building, Thammasat University Rangsit Campus, Pathum Thani'),
          contact('building-2', 'Bangkadi: 3rd Floor, Sirindhorn Tower, 131 Moo 5, Tiwanon Rd, Bangkadi, Mueang, Pathum Thani'),
          h('div', { class: 'lock-note' }, icon('lock', 13), ' Restricted to verified Thammasat University (SIIT) students and staff.'))),
      h('div', { class: 'foot-bottom' }, h('span', { text: '© 2026 Thammasat University — SIIT Rental Service' }))));
  }
})();