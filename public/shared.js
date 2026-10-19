async function loadTable(url, tableId, columns) {
  const table = document.getElementById(tableId);
  const res = await fetch(url);
  if (!res.ok) { table.textContent = 'Could not load data'; return; }
  const rows = await res.json();

  const head = table.createTHead().insertRow();
  columns.forEach(c => {
    const th = document.createElement('th');
    th.textContent = c.label;
    head.appendChild(th);
  });

  const body = table.createTBody();
  rows.forEach(r => {
    const tr = body.insertRow();
    columns.forEach(c => { tr.insertCell().textContent = r[c.key]; });
  });
}