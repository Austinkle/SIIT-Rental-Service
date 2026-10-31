const NS = 'http://www.w3.org/2000/svg';
const el = (tag, attrs = {}, parent) => {
  const e = document.createElementNS(NS, tag);
  for (const k in attrs) e.setAttribute(k, attrs[k]);
  if (parent) parent.appendChild(e);
  return e;
};
const circ = r => `M${r},0 A${r},${r} 0 1,0 ${-r},0 A${r},${r} 0 1,0 ${r},0 Z`;

/* เฟือง: plate = แผ่นเจาะรู, spokes = ก้าน */
function gearPath(R, teeth, th, hole, kind, n) {
  const Rr = R - th, p = Math.PI / teeth;
  const pt = (r, a) => (r * Math.cos(a)).toFixed(1) + ',' + (r * Math.sin(a)).toFixed(1);
  let d = '';
  for (let i = 0; i < teeth; i++) {
    const a = i * 2 * p;
    [[Rr, a - .62 * p], [R, a - .36 * p], [R, a + .36 * p], [Rr, a + .62 * p]]
      .forEach(([r, ang], j) => { d += (i === 0 && j === 0 ? 'M' : 'L') + pt(r, ang) + ' '; });
  }
  d += 'Z ';
  if (kind === 'plate') {                       // รูกลมเรียงรอบ
    const hr = Rr * .6, rr = Rr * .16;
    for (let s = 0; s < n; s++) { const a = s * 2 * Math.PI / n, cx = hr * Math.cos(a), cy = hr * Math.sin(a);
      d += `M${cx + rr},${cy} A${rr},${rr} 0 1,0 ${cx - rr},${cy} A${rr},${rr} 0 1,0 ${cx + rr},${cy} Z `; }
  } else if (kind === 'ring') {                 // วงกลวง + ก้าน
    const Ri = Rr - th * .9; d += circ(Ri) + ' ';
    for (let s = 0; s < n; s++) { const a = s * 2 * Math.PI / n, w = Ri * .06, c = Math.cos(a), sn = Math.sin(a);
      const h = hole * 1.6;
      d += `M${h * c - sn * w},${h * sn + c * w} L${Ri * c - sn * w},${Ri * sn + c * w} L${Ri * c + sn * w},${Ri * sn - c * w} L${h * c + sn * w},${h * sn - c * w} Z `; }
    return d + circ(hole * 1.6) + ' ' + circ(hole * .7);
  }
  return d + (hole ? circ(hole) : '');
}
const gearEl = (parent, o) => {
  const g = el('g', { transform: `translate(${o.x} ${o.y})` }, parent);
  const s = el('g', { class: 'tb spin' + (o.ccw ? ' ccw' : ''), style: `--dur:${o.dur || 24}s` }, g);
  const d = gearPath(o.R, o.teeth, o.th, o.hole, o.kind, o.n || 6);
  if (o.cls) el('path', { d, 'fill-rule': 'evenodd', class: o.cls }, s);
  else el('path', { d, 'fill-rule': 'evenodd', fill: o.fill, stroke: o.fill, 'stroke-width': o.round || 4, 'stroke-linejoin': 'round' }, s);
  return g;
};

/* โลโก้กลาง */
gearEl(document.getElementById('gearIn'), { x: 0, y: 0, R: 98, teeth: 8, th: 24, hole: 40, fill: 'url(#gearG)', round: 9, dur: 60 });

/* ตัวอักษรวางทีละตัวรอบวง (ไม่ใช้ textPath จึงเห็นแน่นอน) */
const ringText = document.getElementById('ringText');
const msg = [...'GEAR UP, SIIT!', '•', ' ', ...'GEAR UP, SIIT!', '•', ' '];
msg.forEach((c, i) => {
  if (c === ' ') return;
  const a = (i / msg.length) * 360, r = 138;
  const t = el('text', { class: 'ch' + (c === '•' ? ' dot' : ''), transform: `rotate(${a}) translate(0 ${-r})` }, ringText);
  t.textContent = c;
});

/* เฟืองพื้นหลัง: ใหญ่/เล็ก ตัดขอบจอ สีขาวจางๆ
   จอแนวนอนใช้พื้นที่ 1000x500, จอแนวตั้ง (มือถือ) ใช้ 500x1000 เพื่อให้เฟืองอยู่ในกรอบจอจริง */
const bg = document.getElementById('bg'), dust = document.getElementById('dust'), K = 1.4;
const bgSvg = bg.ownerSVGElement, logoSvg = document.querySelectorAll('svg')[1];
const LAYOUTS = {
  landscape: { w: 1000, h: 500, gears: [
    { x: 60,  y: 440, R: 270, teeth: 30, th: 30, hole: 38, kind: 'ring', n: 6 },
    { x: 290, y: 120, R: 70,  teeth: 12, th: 14, hole: 14, kind: 'plate', n: 5, ccw: true },
    { x: 935, y: 40,  R: 210, teeth: 26, th: 28, hole: 32, kind: 'plate', n: 8 },
    { x: 800, y: 455, R: 135, teeth: 20, th: 20, hole: 24, kind: 'ring', n: 5, ccw: true },
    { x: 705, y: 335, R: 46,  teeth: 9,  th: 10, hole: 12, n: 3 },
    { x: 130, y: 10,  R: 85,  teeth: 14, th: 15, hole: 16, kind: 'plate', n: 6, ccw: true },
    { x: 960, y: 290, R: 52,  teeth: 11, th: 11, hole: 12, ccw: true },
    { x: 40,  y: 225, R: 40,  teeth: 9,  th: 9,  hole: 10 },
    { x: 345, y: 470, R: 52,  teeth: 11, th: 11, hole: 12, ccw: true }
  ] },
  portrait: { w: 500, h: 1000, gears: [
    { x: 40,  y: 900, R: 210, teeth: 30, th: 30, hole: 38, kind: 'ring', n: 6 },
    { x: 430, y: 110, R: 150, teeth: 26, th: 24, hole: 28, kind: 'plate', n: 8 },
    { x: 95,  y: 190, R: 60,  teeth: 12, th: 12, hole: 12, kind: 'plate', n: 5, ccw: true },
    { x: 455, y: 790, R: 100, teeth: 20, th: 16, hole: 20, kind: 'ring', n: 5, ccw: true },
    { x: 340, y: 650, R: 42,  teeth: 9,  th: 9,  hole: 10, n: 3 },
    { x: 200, y: 20,  R: 70,  teeth: 14, th: 13, hole: 14, kind: 'plate', n: 6, ccw: true },
    { x: 470, y: 460, R: 46,  teeth: 11, th: 10, hole: 11, ccw: true },
    { x: 30,  y: 520, R: 38,  teeth: 9,  th: 9,  hole: 10 },
    { x: 290, y: 960, R: 48,  teeth: 11, th: 10, hole: 11, ccw: true }
  ] }
};

function buildBackground() {
  const L = innerHeight > innerWidth ? LAYOUTS.portrait : LAYOUTS.landscape;
  if (bg.dataset.layout === String(L.w)) return;       // layout เดิม ไม่ต้องสร้างใหม่
  bg.dataset.layout = String(L.w);
  bgSvg.setAttribute('viewBox', `0 0 ${L.w} ${L.h}`);
  /* โลโก้กลาง: จอแนวตั้งซูมเข้า (viewBox แคบลง) ให้วงกลมและข้อความใหญ่ขึ้น */
  logoSvg.setAttribute('viewBox', L === LAYOUTS.portrait ? '260 0 480 500' : '0 0 1000 500');
  bg.replaceChildren(); dust.replaceChildren();
  L.gears.forEach(g => gearEl(bg, { ...g, cls: 'bgear', dur: g.teeth * K }));

  /* ฝุ่น */
  for (let i = 0; i < 40; i++) {
    const c = el('circle', { cx: Math.random() * L.w, cy: Math.random() * L.h, r: (Math.random() * 1.4 + .5).toFixed(1), fill: '#fff', class: 'dust' }, dust);
    c.style.setProperty('--t', (6 + Math.random() * 8).toFixed(1) + 's');
    c.style.setProperty('--dx', (Math.random() * 30 - 15).toFixed(0) + 'px');
    c.style.setProperty('--dy', (-10 - Math.random() * 30).toFixed(0) + 'px');
    c.style.animationDelay = '0s, ' + (-Math.random() * 3).toFixed(1) + 's';
  }
}
buildBackground();
addEventListener('resize', buildBackground);           // หมุนจอ → สลับ layout

/* ---------- ไปหน้า login ---------- */
const NEXT_PAGE = '/login.html';
const PLAY_MS = 5500;                                   // เวลาที่แอนิเมชันเล่นก่อนไปหน้า login
const LOOP = new URLSearchParams(location.search).has('loop');   // เปิด Intro.html?loop เพื่อดูค้างไว้ตอนแก้งาน
let gone = false;
function go() { if (LOOP || gone) return; gone = true; location.href = NEXT_PAGE; }
setTimeout(go, PLAY_MS);
document.addEventListener('click', go);                 // คลิกที่ไหนก็ข้ามได้
document.addEventListener('keydown', go);

/* ?loop = เล่นซ้ำตั้งแต่ต้นทุก LOOP_MS (ใช้ตอนแก้งาน) */
const LOOP_MS = 9000;
if (LOOP) setInterval(() => document.getAnimations().forEach(a => { a.cancel(); a.play(); }), LOOP_MS);