async function loadTable(url, tableId, columns) {
  const table = document.getElementById(tableId);   // check that this id exists in your HTML
  table.innerHTML = '';

  const res = await fetch(url);
  if (!res.ok) { table.createCaption().textContent = 'Could not load data'; return; }

  const rows = await res.json();
  if (rows.length === 0) { table.createCaption().textContent = 'No data'; return; }

  const head = table.createTHead().insertRow();
  columns.forEach(c => {
    const th = document.createElement('th');
    th.textContent = c.label;
    head.appendChild(th);
  });

  const body = table.createTBody();
  rows.forEach(r => {
  const tr = body.insertRow();
  columns.forEach(c => {
    const cell = tr.insertCell();
    if (c.render) cell.appendChild(c.render(r));        // custom content, e.g. a button
    else cell.textContent = c.format ? c.format(r[c.key]) : r[c.key];
  });
});
}