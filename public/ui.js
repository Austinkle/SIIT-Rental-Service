(function () {
  const SVG_NS = 'http://www.w3.org/2000/svg';

  // lucide icon by name -> <svg>
  function icon(name, size, stroke) {
    const s = document.createElementNS(SVG_NS, 'svg');
    s.setAttribute('class', 'icon');
    s.setAttribute('width', size || 16);
    s.setAttribute('height', size || 16);
    s.setAttribute('viewBox', '0 0 24 24');
    s.setAttribute('fill', 'none');
    s.setAttribute('stroke', 'currentColor');
    s.setAttribute('stroke-width', stroke || 1.75);
    s.setAttribute('stroke-linecap', 'round');
    s.setAttribute('stroke-linejoin', 'round');
    s.setAttribute('aria-hidden', 'true');
    s.innerHTML = (window.ICONS && window.ICONS[name]) || '';   // static icon markup only
    return s;
  }

  // h('div', { class: 'x', onclick: fn }, 'text', childNode, [more])
  function h(tag, attrs, ...kids) {
    const el = document.createElement(tag);
    for (const [k, v] of Object.entries(attrs || {})) {
      if (v === null || v === undefined || v === false) continue;
      if (k === 'class') el.className = v;
      else if (k === 'text') el.textContent = v;
      else if (k.startsWith('on') && typeof v === 'function') el.addEventListener(k.slice(2), v);
      else el.setAttribute(k, v === true ? '' : v);
    }
    const add = kid => {
      if (kid === null || kid === undefined || kid === false) return;
      if (Array.isArray(kid)) return kid.forEach(add);
      el.append(kid.nodeType ? kid : document.createTextNode(String(kid)));
    };
    kids.forEach(add);
    return el;
  }

  // ----- dates -----
  const fmtDate = v => new Date(v).toLocaleDateString('en-GB', { day: 'numeric', month: 'short', year: 'numeric' });
  const fmtDateTime = v => new Date(v).toLocaleString('en-GB', { day: 'numeric', month: 'short', year: 'numeric', hour: '2-digit', minute: '2-digit' });

  // ----- categories: icon + placeholder photo (picked by words in the category name) -----
  const U = id => 'https://images.unsplash.com/' + id + '?w=480&h=320&fit=crop&auto=format';
  const CATS = [
    { re: /batter/i,                    icon: 'battery-full', img: U('photo-1544725176-7c40e5a71c5e') },
    { re: /calculator/i,                icon: 'calculator',   img: U('photo-1574607383077-47ddc2dc51c4') },
    { re: /power|extension|strip/i,     icon: 'plug',         img: U('photo-1650501386688-41f6d0251875') },
    { re: /charger|cable/i,             icon: 'zap',          img: U('photo-1557767382-97b28f5488e7') },
    { re: /adapter|convert/i,           icon: 'cable',        img: U('photo-1760376789487-994070337c76') },
    { re: /stationery/i,                icon: 'pen-line',     img: U('photo-1764948620467-2b08f6843dd6') },
    { re: /umbrella/i,                  icon: 'umbrella',     img: U('photo-1532135468830-e51699205b70') }
  ];
  const catMeta = name => CATS.find(c => c.re.test(name || '')) || { icon: 'package', img: '' };

  const assetTag = id => 'EQ-' + String(id).padStart(4, '0');

  function badge(kind, label) {            // kind: available | borrowed | overdue
    return h('span', { class: 'badge ' + (kind === 'available' ? '' : kind), text: label });
  }

  // ----- toast (replaces alert) -----
  function toast(message, type) {
    let box = document.querySelector('.toast-box');
    if (!box) { box = h('div', { class: 'toast-box', role: 'status', 'aria-live': 'polite' }); document.body.append(box); }
    const t = h('div', { class: 'toast' + (type === 'error' ? ' error' : ''), text: message });
    box.append(t);
    setTimeout(() => t.remove(), 4500);
  }

  // item card used on Home and Rental Catalog
  function itemCard(r, onRequest) {
    const meta = catMeta(r.category_name);
    const free = r.available_quantity > 0;
    const img = h('div', { class: 'item-img' + (free ? '' : ' dim') });
    if (meta.img) {
      const pic = h('img', { src: meta.img, alt: '', loading: 'lazy' });
      pic.addEventListener('error', () => pic.remove());
      img.append(pic);
    }
    img.append(
      h('div', { class: 'tl' }, badge(free ? 'available' : 'borrowed', free ? 'Available' : 'Borrowed'),
        h('span', { class: 'tag', text: assetTag(r.equipment_id) })),
      h('div', { class: 'cat-chip' }, icon(meta.icon, 17)),
      h('div', { class: 'campus ' + String(r.location || '').toLowerCase(), text: r.location || '' })
    );
    return h('div', { class: 'item-card' }, img,
      h('div', { class: 'item-body' },
        h('div', { class: 'item-cat', text: r.category_name }),
        h('div', { class: 'item-title font-display', text: r.name }),
        r.description ? h('p', { class: 'item-desc', text: r.description }) : null,
        h('div', { class: 'item-meta' }, icon('map-pin', 12), r.location || '',
          ' · ', r.available_quantity + ' of ' + r.total_quantity + ' in'),
        free
          ? h('button', { class: 'btn btn-dark btn-block', type: 'button', onclick: () => onRequest(r), text: 'Request Rental' })
          : h('div', { class: 'notice-amber', text: 'Currently borrowed' })));
  }

  window.UI = { icon, h, fmtDate, fmtDateTime, catMeta, assetTag, badge, toast, itemCard };
})();

/* label table cells from their header text (used by the phone card layout in style.css) */
(function () {
  function label(table) {
    const heads = [...table.querySelectorAll('thead th')].map(th => th.textContent.trim());
    if (!heads.length) return;
    table.querySelectorAll('tbody tr').forEach(tr => {
      const cells = [...tr.children];
      cells.forEach((td, i) => {
        if (heads[i]) td.setAttribute('data-label', heads[i]);
        else if (i >= heads.length) td.classList.add('row-x');   // extra cell past the headers = delete (X) button
      });
    });
  }
  document.addEventListener('DOMContentLoaded', () => {
    document.querySelectorAll('.table-wrap table').forEach(t => {
      new MutationObserver(() => label(t)).observe(t, { childList: true, subtree: true });
      label(t);
    });
  });
})();
