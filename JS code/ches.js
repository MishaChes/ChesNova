(function () {
  'use strict';

  var HUD_URL = 'http://127.0.0.1:17890/hud';
  var POLL_MS = 750;

  var hudEl = null;
  var hudDotEl = null;
  var hudNickEl = null;
  var hudPmEl = null;

  var settings = {
    nick: ''
  };

  var pmCount = 0;
  var healthState = 'ok'; // ok | warn | critical
  var pollBusy = false;

  function getHealthColor() {
    if (healthState === 'critical') return '#FF5B6B';
    if (healthState === 'warn') return '#F6A623';
    return '#41D07A';
  }

  function ensureHud() {
    if (hudEl || !document.body) return;

    hudEl = document.createElement('div');
    hudEl.id = 'ches-hud';
    hudEl.innerHTML = [
      '<div class="ches-hud-top">',
      '  <span class="ches-hud-title">ChesNova</span>',
      '  <span class="ches-hud-dot"></span>',
      '</div>',
      '<div class="ches-hud-line"></div>',
      '<div class="ches-hud-nick">—</div>',
      '<div class="ches-hud-pm">PM: —</div>'
    ].join('');

    var style = document.createElement('style');
    style.textContent = [
      '#ches-hud,#ches-hud *{box-sizing:border-box}',
      '#ches-hud{position:fixed;bottom:14px;right:14px;z-index:99999;min-width:120px;background:rgba(11,14,20,.88);border:1px solid #2B3443;border-radius:10px;padding:8px 12px;color:#F5F7FB;font:12px/1.35 "Open Sans","Segoe UI",Arial,sans-serif;pointer-events:none;box-shadow:0 8px 24px rgba(0,0,0,.35);backdrop-filter:blur(6px)}',
      '#ches-hud .ches-hud-top{display:flex;align-items:center;justify-content:space-between;gap:10px}',
      '#ches-hud .ches-hud-title{font-weight:700;font-size:12px;letter-spacing:.3px;color:#F5F7FB}',
      '#ches-hud .ches-hud-dot{width:9px;height:9px;border-radius:50%;background:#41D07A;box-shadow:0 0 0 2px rgba(65,208,122,.18);flex-shrink:0}',
      '#ches-hud .ches-hud-line{height:1px;background:#2B3443;margin:7px 0 6px}',
      '#ches-hud .ches-hud-nick{color:#AAB4C5;font-size:11px;margin-bottom:2px;max-width:140px;overflow:hidden;text-overflow:ellipsis;white-space:nowrap}',
      '#ches-hud .ches-hud-pm{color:#F5F7FB;font-weight:700;font-size:12px}'
    ].join('');
    document.head.appendChild(style);
    document.body.appendChild(hudEl);

    hudDotEl = hudEl.querySelector('.ches-hud-dot');
    hudNickEl = hudEl.querySelector('.ches-hud-nick');
    hudPmEl = hudEl.querySelector('.ches-hud-pm');
    updateHud();
  }

  function updateHud() {
    if (!hudEl) return;
    if (hudDotEl) {
      var color = getHealthColor();
      hudDotEl.style.background = color;
      hudDotEl.style.boxShadow = '0 0 0 2px ' + color + '2E';
    }
    if (hudNickEl) hudNickEl.textContent = settings.nick || '—';
    if (hudPmEl) hudPmEl.textContent = 'PM: ' + (pmCount != null ? pmCount : '—');
  }

  function applyState(data) {
    if (!data || typeof data !== 'object') return;
    if (data.nick != null) settings.nick = String(data.nick);
    if (data.pm != null) {
      var n = parseInt(data.pm, 10);
      if (!isNaN(n)) pmCount = n;
    }
    if (data.health != null) {
      var h = String(data.health);
      if (h === 'ok' || h === 'warn' || h === 'critical') healthState = h;
    }
    updateHud();
  }

  function pollHud() {
    if (pollBusy) return;
    pollBusy = true;
    try {
      var xhr = new XMLHttpRequest();
      xhr.open('GET', HUD_URL, true);
      xhr.timeout = 1200;
      xhr.onload = function () {
        pollBusy = false;
        if (xhr.status >= 200 && xhr.status < 300) {
          try {
            applyState(JSON.parse(xhr.responseText));
          } catch (e) {}
        }
      };
      xhr.onerror = function () { pollBusy = false; };
      xhr.ontimeout = function () { pollBusy = false; };
      xhr.send();
    } catch (e) {
      pollBusy = false;
    }
  }

  window.ChesHUD = {
    setNick: function (nick) {
      settings.nick = (nick || '').trim();
      updateHud();
    },
    setPm: function (n) {
      pmCount = n;
      updateHud();
    },
    setHealth: function (state) {
      healthState = state || 'ok';
      updateHud();
    },
    update: updateHud,
    poll: pollHud
  };

  function tick() {
    if (!hudEl && document.body) {
      try { ensureHud(); } catch (e) {}
    }
    if (!hudEl) setTimeout(tick, 50);
  }

  setInterval(function () {
    ensureHud();
    pollHud();
  }, POLL_MS);

  tick();
})();
