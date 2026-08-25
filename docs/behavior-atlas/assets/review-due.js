(() => {
  const due = document.body.dataset.reviewDue;
  if (!due) return;
  const dueDate = new Date(`${due}T23:59:59Z`);
  if (Number.isNaN(dueDate.getTime())) return;
  const banner = document.querySelector('[data-expiry-banner]');
  const status = document.querySelector('[data-expiry-status]');
  const overdue = Date.now() > dueDate.getTime();
  if (status) status.textContent = overdue ? `Review overdue since ${due}` : `Assessment review due ${due}`;
  if (overdue && banner) banner.style.display = 'block';
})();
