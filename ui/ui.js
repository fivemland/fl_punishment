const comservEl = document.getElementById('comserv');

window.addEventListener('message', ({ data }) => {
  if (data.comserv !== undefined) {
    if (comservEl.style.visibility !== 'visible') {
      comservEl.style.visibility = 'visible';
    }

    const { comserv } = data;

    const dateObject = new Date((comserv.start || 0) * 1000);

    const formatedDate = dateObject.toLocaleString('en-GB');

    comservEl.innerHTML = `
      Jobs left: ${comserv.count}
      <br>
      Reason: ${comserv.reason || 'Unknown'}
      <br>
      Admin: ${comserv.admin.name || 'Unknown'}
      <br>
      Start Date: ${formatedDate}
    `;
  }
  if (data.hideComserv !== undefined) {
    comservEl.style.visibility = 'hidden';
  }
});
