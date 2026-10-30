(function () {
  const MAX_ADVANCE_DAYS = 14;   // keep the same numbers as the controller
  const MAX_LOAN_DAYS = 7;

  // The pop-up markup (static text only, no user data inside)
  document.body.insertAdjacentHTML('beforeend', `
    <dialog id="requestDialog">
      <form id="requestForm">
        <h3>Request rental</h3>
        <p><strong id="dlgItem"></strong><br><span id="dlgLocation"></span></p>
        <label>Borrow date <input type="date" id="borrowDate" required></label>
        <label>Due date <input type="date" id="dueDate" required></label>
        <p id="dlgHint"></p>
        <p id="dlgError" class="dlg-error" role="alert" hidden></p>
        <div class="dlg-actions">
          <button type="button" id="dlgCancel">Cancel</button>
          <button type="submit" id="dlgConfirm">Confirm request</button>
        </div>
      </form>
    </dialog>`);

  const dialog = document.getElementById('requestDialog');
  const form = document.getElementById('requestForm');
  const borrowDate = document.getElementById('borrowDate');
  const dueDate = document.getElementById('dueDate');
  const dlgError = document.getElementById('dlgError');
  const confirmBtn = document.getElementById('dlgConfirm');
  let selected = null;     // the equipment row the student clicked

  document.getElementById('dlgHint').textContent =
    'Book up to ' + MAX_ADVANCE_DAYS + ' days ahead, keep it up to ' + MAX_LOAN_DAYS + ' days.';

  // Date -> 'YYYY-MM-DD' using LOCAL time (toISOString would use UTC and can be a day off in Bangkok)
  function toYMD(d) {
    const mm = String(d.getMonth() + 1).padStart(2, '0');
    const dd = String(d.getDate()).padStart(2, '0');
    return d.getFullYear() + '-' + mm + '-' + dd;
  }
  function addDays(d, n) {
    const x = new Date(d);
    x.setDate(x.getDate() + n);
    return x;
  }

  // The due date picker only allows: borrow date ... borrow date + MAX_LOAN_DAYS
  function updateDueLimits() {
    if (!borrowDate.value) return;
    const start = new Date(borrowDate.value + 'T00:00:00');
    dueDate.min = borrowDate.value;
    dueDate.max = toYMD(addDays(start, MAX_LOAN_DAYS));
    if (!dueDate.value || dueDate.value < dueDate.min || dueDate.value > dueDate.max) {
      dueDate.value = toYMD(addDays(start, 1)).slice(0, 10) <= dueDate.max
        ? toYMD(addDays(start, 1)) : dueDate.min;
    }
  }
  borrowDate.addEventListener('change', updateDueLimits);

  // Called by the page when the student clicks "Request Rental"
  window.openRequestDialog = function (item) {
    selected = item;
    document.getElementById('dlgItem').textContent = item.name;
    document.getElementById('dlgLocation').textContent = item.location ? 'Pick up at: ' + item.location : '';
    dlgError.hidden = true;

    const today = new Date();
    borrowDate.min = toYMD(today);
    borrowDate.max = toYMD(addDays(today, MAX_ADVANCE_DAYS));
    borrowDate.value = toYMD(today);
    dueDate.value = '';
    updateDueLimits();
    dialog.showModal();
  };

  document.getElementById('dlgCancel').addEventListener('click', () => dialog.close());

  form.addEventListener('submit', async event => {
    event.preventDefault();
    dlgError.hidden = true;
    confirmBtn.disabled = true;

    try {
      const res = await fetch('/student/api/requests', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          equipment_id: selected.equipment_id,
          borrow_date: borrowDate.value,
          due_date: dueDate.value
        })
      });
      const data = await res.json().catch(() => ({}));

      if (res.ok) {
        dialog.close();
        alert('Request sent. Staff will review it.');
        return;
      }
      dlgError.textContent = data.error || 'Could not send request';
      dlgError.hidden = false;
    } catch {
      dlgError.textContent = 'Network error. Please try again.';
      dlgError.hidden = false;
    } finally {
      confirmBtn.disabled = false;
    }
  });
})();