let currentPlayers = [];
let selectedPlayerId = null;
let noclipActive = false;
let currentConfig = {};

const app = document.getElementById('app');

// ═══════════════════════════════════════════
// MESSAGES DEPUIS LUA
// ═══════════════════════════════════════════

window.addEventListener('message', (event) => {
  const data = event.data;

  switch (data.action) {
    case 'open':
      currentConfig = data.config || {};
      app.classList.remove('hidden');
      document.getElementById('keyDisplay').innerText = currentConfig.OpenKey || 'F6';
      buildVehicleSelect(currentConfig.QuickVehicles || []);
      break;

    case 'close':
      app.classList.add('hidden');
      closeModal();
      break;

    case 'updatePlayers':
      currentPlayers = data.players || [];
      renderPlayers(currentPlayers);
      break;

    case 'notify':
      showNotification(data.message, data.type || 'info');
      break;

    case 'announcement':
      showAnnouncement(data.message, data.admin);
      break;
  }
});

// ═══════════════════════════════════════════
// FERMETURE
// ═══════════════════════════════════════════

document.getElementById('closeBtn').addEventListener('click', closePanel);

function closePanel() {
  post('close', {});
  app.classList.add('hidden');
  closeModal();
}

document.addEventListener('keydown', (e) => {
  if (e.key === 'Escape') closePanel();
});

// ═══════════════════════════════════════════
// TABS
// ═══════════════════════════════════════════

document.querySelectorAll('.tab-btn').forEach(btn => {
  btn.addEventListener('click', () => {
    document.querySelectorAll('.tab-btn').forEach(b => b.classList.remove('active'));
    document.querySelectorAll('.tab-content').forEach(c => c.classList.remove('active'));
    btn.classList.add('active');
    document.getElementById(`tab-${btn.dataset.tab}`).classList.add('active');
  });
});

// ═══════════════════════════════════════════
// LISTE DES JOUEURS
// ═══════════════════════════════════════════

function renderPlayers(players) {
  const list = document.getElementById('playerList');
  list.innerHTML = '';

  if (players.length === 0) {
    list.innerHTML = '<div class="empty-state">Aucun joueur connecté.</div>';
    return;
  }

  players.forEach(p => {
    const row = document.createElement('div');
    row.className = 'player-row';
    row.innerHTML = `
      <div class="player-info">
        <span class="player-id">#${p.id}</span>
        <span class="player-name">${escapeHtml(p.name)}</span>
      </div>
      <span class="player-ping">${p.ping} ms</span>
    `;
    row.addEventListener('click', () => openPlayerModal(p));
    list.appendChild(row);
  });
}

document.getElementById('playerSearch').addEventListener('input', (e) => {
  const query = e.target.value.toLowerCase();
  const filtered = currentPlayers.filter(p =>
    p.name.toLowerCase().includes(query) || String(p.id).includes(query)
  );
  renderPlayers(filtered);
});

document.getElementById('refreshPlayersBtn').addEventListener('click', () => {
  post('refreshPlayers', {});
});

function escapeHtml(str) {
  const div = document.createElement('div');
  div.innerText = str;
  return div.innerHTML;
}

// ═══════════════════════════════════════════
// MODAL JOUEUR
// ═══════════════════════════════════════════

function openPlayerModal(player) {
  selectedPlayerId = player.id;
  document.getElementById('modalPlayerName').innerText = `${player.name} (#${player.id})`;
  document.getElementById('playerModal').classList.remove('hidden');
}

function closeModal() {
  document.getElementById('playerModal').classList.add('hidden');
  selectedPlayerId = null;
}

document.getElementById('modalClose').addEventListener('click', closeModal);
document.getElementById('playerModal').addEventListener('click', (e) => {
  if (e.target.id === 'playerModal') closeModal();
});

document.querySelectorAll('.action-btn').forEach(btn => {
  btn.addEventListener('click', () => {
    if (!selectedPlayerId) return;
    const action = btn.dataset.action;
    const value = btn.dataset.value;
    post(action, { targetId: selectedPlayerId, value: value === 'true' ? true : value === 'false' ? false : undefined });
    showNotification(`Action "${action}" envoyée.`, 'success');
  });
});

document.getElementById('giveMoneyBtn').addEventListener('click', () => {
  const amount = document.getElementById('giveMoneyAmount').value;
  const type = document.getElementById('giveMoneyType').value;
  if (!amount || !selectedPlayerId) return;
  post('giveMoney', { targetId: selectedPlayerId, value: amount, extra: type });
  document.getElementById('giveMoneyAmount').value = '';
});

document.getElementById('kickBtn').addEventListener('click', () => {
  const reason = document.getElementById('kickReason').value;
  if (!selectedPlayerId) return;
  post('kick', { targetId: selectedPlayerId, value: reason });
  closeModal();
});

document.getElementById('banBtn').addEventListener('click', () => {
  const reason = document.getElementById('banReason').value;
  const duration = document.getElementById('banDuration').value || 0;
  if (!selectedPlayerId) return;
  post('ban', { targetId: selectedPlayerId, value: reason, extra: duration });
  closeModal();
});

// ═══════════════════════════════════════════
// OUTILS
// ═══════════════════════════════════════════

function buildVehicleSelect(vehicles) {
  const select = document.getElementById('vehicleSelect');
  select.innerHTML = '<option value="">— Sélectionner —</option>';
  vehicles.forEach(v => {
    const opt = document.createElement('option');
    opt.value = v;
    opt.innerText = v;
    select.appendChild(opt);
  });
}

document.getElementById('noclipToggle').addEventListener('click', () => {
  noclipActive = !noclipActive;
  const btn = document.getElementById('noclipToggle');
  btn.innerText = noclipActive ? 'Désactiver' : 'Activer';
  btn.classList.toggle('active', noclipActive);
  post('noclip', { value: noclipActive });
});

document.getElementById('spawnVehicleBtn').addEventListener('click', () => {
  const select = document.getElementById('vehicleSelect').value;
  const custom = document.getElementById('vehicleCustomModel').value.trim();
  const model = custom || select;
  if (!model) {
    showNotification('Choisis un véhicule ou entre un modèle.', 'error');
    return;
  }
  post('spawnVehicle', { targetId: null, value: model });
  document.getElementById('vehicleCustomModel').value = '';
});

document.getElementById('announcementBtn').addEventListener('click', () => {
  const msg = document.getElementById('announcementInput').value.trim();
  if (!msg) return;
  post('announcement', { value: msg });
  document.getElementById('announcementInput').value = '';
});

// ═══════════════════════════════════════════
// NOTIFICATIONS / ANNONCES
// ═══════════════════════════════════════════

function showNotification(message, type = 'info') {
  const container = document.getElementById('notifications');
  const notif = document.createElement('div');
  notif.className = `notif ${type}`;
  notif.innerText = message;
  container.appendChild(notif);
  setTimeout(() => notif.remove(), 4000);
}

function showAnnouncement(message, admin) {
  const banner = document.getElementById('announcementBanner');
  banner.innerHTML = `<span class="announcement-label">ANNONCE</span>${escapeHtml(message)}`;
  banner.classList.remove('hidden');
  setTimeout(() => banner.classList.add('hidden'), 6000);
}

// ═══════════════════════════════════════════
// HELPER NUI CALLBACK
// ═══════════════════════════════════════════

function post(eventName, data) {
  // GetParentResourceName() est une fonction native injectée automatiquement par le jeu, ne pas la redéfinir
  const resourceName = (typeof GetParentResourceName === 'function') ? GetParentResourceName() : 'admin_panel';
  fetch(`https://${resourceName}/${eventName}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(data)
  }).catch(() => {});
}
