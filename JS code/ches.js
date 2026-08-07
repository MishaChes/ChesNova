(function () {
  'use strict';

  var HUD_URL = 'http://127.0.0.1:17890/hud';
  var POLL_MS = 750;
  var AI_SHOW_MS = 10000;

  var hudEl = null;
  var hudDotEl = null;
  var hudNickEl = null;
  var hudPmEl = null;
  var hudMultEl = null;

  var aiEl = null;
  var aiTitleEl = null;
  var aiQEl = null;
  var aiAEl = null;
  var aiHideTimer = null;
  var lastAiId = 0;
  var lastThinking = false;

  var thinkEl = null;

  var settings = {
    nick: ''
  };

  var pmCount = 0;
  var normValue = 0;
  var multValue = 0;
  var healthState = 'ok';
  var pollBusy = false;
  var hudVisible = true;

  function getHealthColor() {
    if (healthState === 'critical') return '#FF5B6B';
    if (healthState === 'warn') return '#F6A623';
    return '#41D07A';
  }

  function ensureStyles() {
    if (document.getElementById('ches-hud-style')) return;
    var style = document.createElement('style');
    style.id = 'ches-hud-style';
    style.textContent = [
      '#ches-hud,#ches-hud *,#ches-ai,#ches-ai *,#ches-think,#ches-think *{box-sizing:border-box}',
      /* HUD: статус → ник → PM + xN (колонка, длинный ник не сливается с точкой) */
      '#ches-hud{position:fixed;bottom:14px;right:14px;z-index:99999;min-width:118px;max-width:200px;background:rgba(11,14,20,.88);border:1px solid #2B3443;border-radius:10px;padding:8px 12px;color:#F5F7FB;font:12px/1.35 "Open Sans","Segoe UI",Arial,sans-serif;pointer-events:auto;cursor:move;user-select:none;box-shadow:0 8px 24px rgba(0,0,0,.35);backdrop-filter:blur(6px)}',
      '#ches-hud .ches-hud-status{display:flex;align-items:center;margin-bottom:5px}',
      '#ches-hud .ches-hud-dot{width:9px;height:9px;border-radius:50%;background:#41D07A;box-shadow:0 0 0 2px rgba(65,208,122,.18);flex-shrink:0}',
      '#ches-hud .ches-hud-status-label{font-size:10px;color:#A0A8B8;letter-spacing:.3px;text-transform:uppercase;margin-left:12px}',
      '#ches-hud .ches-hud-nick{font-weight:700;font-size:12px;letter-spacing:.2px;color:#F5F7FB;max-width:176px;overflow:hidden;text-overflow:ellipsis;white-space:nowrap;margin-bottom:4px}',
      '#ches-hud .ches-hud-pm-row{display:flex;align-items:baseline;justify-content:space-between;gap:8px}',
      '#ches-hud .ches-hud-pm{color:#F5F7FB;font-weight:700;font-size:12px}',
      '#ches-hud .ches-hud-mult{color:#3B82F6;font-weight:700;font-size:12px;letter-spacing:.3px;flex-shrink:0}',
      '#ches-hud .ches-hud-mult.ches-hud-mult-off{display:none}',
      /* AI panel — левый нижний угол */
      '#ches-ai{position:fixed;bottom:16px;left:16px;z-index:100000;width:min(360px,calc(100vw - 32px));max-height:42vh;display:none;flex-direction:column;background:rgba(11,14,20,.94);border:1px solid #2B3443;border-radius:12px;padding:12px 14px;color:#F5F7FB;font:12px/1.4 "Open Sans","Segoe UI",Arial,sans-serif;pointer-events:none;box-shadow:0 10px 28px rgba(0,0,0,.4);backdrop-filter:blur(8px);opacity:0;transform:translateY(8px);transition:opacity .22s ease,transform .22s ease}',
      '#ches-ai.ches-ai-visible{display:flex;opacity:1;transform:translateY(0)}',
      '#ches-ai.ches-ai-error{border-color:#FF5B6B}',
      '#ches-ai .ches-ai-head{display:flex;align-items:center;justify-content:space-between;gap:8px;margin-bottom:8px}',
      '#ches-ai .ches-ai-badge{font-weight:700;font-size:11px;letter-spacing:.4px;color:#3B82F6;text-transform:uppercase}',
      '#ches-ai.ches-ai-error .ches-ai-badge{color:#FF5B6B}',
      '#ches-ai .ches-ai-ttl{font-size:10px;color:#A0A8B8}',
      '#ches-ai .ches-ai-q{color:#AAB4C5;font-size:11px;margin-bottom:6px;max-height:3.2em;overflow:hidden}',
      '#ches-ai .ches-ai-line{height:1px;background:#2B3443;margin:0 0 8px}',
      '#ches-ai .ches-ai-a{color:#F5F7FB;font-size:12px;font-weight:500;overflow:auto;max-height:28vh;white-space:pre-wrap;word-break:break-word}',
      /* «AI думает…» — левый низ, там же где ответ */
      '#ches-think{position:fixed;bottom:16px;left:16px;z-index:100001;display:none;align-items:center;gap:8px;padding:10px 14px;border-radius:12px;background:rgba(11,14,20,.88);border:1px solid #2B3443;color:#A0A8B8;font:12px/1.3 "Open Sans","Segoe UI",Arial,sans-serif;letter-spacing:.2px;pointer-events:none;box-shadow:0 8px 24px rgba(0,0,0,.35);backdrop-filter:blur(6px);opacity:0;transform:translateY(6px);transition:opacity .2s ease,transform .2s ease}',
      '#ches-think.ches-think-on{display:flex;opacity:1;transform:translateY(0)}',
      '#ches-think .ches-think-dot{width:8px;height:8px;border-radius:50%;background:#3B82F6;flex-shrink:0;box-shadow:0 0 0 2px rgba(59,130,246,.2);animation:ches-pulse 1s ease-in-out infinite}',
      '@keyframes ches-pulse{0%,100%{opacity:.35}50%{opacity:1}}'
    ].join('');
    document.head.appendChild(style);
  }


  var dragState = null;
  var lastAppliedHudPos = null;
  var hudPosReady = false;

  function clamp(n, min, max) {
    return Math.max(min, Math.min(max, n));
  }

  function applyHudPos(el, pos) {
    if (!el || !pos) return;
    var leftN = parseFloat(pos.left);
    var topN = parseFloat(pos.top);
    if (isNaN(leftN) || isNaN(topN)) return;
    var w = el.offsetWidth || 120;
    var h = el.offsetHeight || 60;
    var maxL = Math.max(0, window.innerWidth - w);
    var maxT = Math.max(0, window.innerHeight - h);
    var left = clamp(leftN, 0, maxL);
    var top = clamp(topN, 0, maxT);
    el.style.left = left + 'px';
    el.style.top = top + 'px';
    el.style.right = 'auto';
    el.style.bottom = 'auto';
    lastAppliedHudPos = { left: left, top: top };
    hudPosReady = true;
  }

  function saveHudPos(left, top) {
    left = Math.round(left);
    top = Math.round(top);
    lastAppliedHudPos = { left: left, top: top };
    try {
      var xhr = new XMLHttpRequest();
      xhr.open('GET', 'http://127.0.0.1:17890/pos?left=' + left + '&top=' + top, true);
      xhr.timeout = 1200;
      xhr.send();
    } catch (e) {}
  }

  function installHudDrag(el) {
    if (!el || el.__chesDragInstalled) return;
    el.__chesDragInstalled = true;

    el.addEventListener('mousedown', function (ev) {
      if (ev.button !== 0) return;
      var rect = el.getBoundingClientRect();
      dragState = {
        startX: ev.clientX,
        startY: ev.clientY,
        origLeft: rect.left,
        origTop: rect.top
      };
      ev.preventDefault();
    });

    document.addEventListener('mousemove', function (ev) {
      if (!dragState || !hudEl) return;
      var dx = ev.clientX - dragState.startX;
      var dy = ev.clientY - dragState.startY;
      var w = hudEl.offsetWidth || 120;
      var h = hudEl.offsetHeight || 60;
      var left = clamp(dragState.origLeft + dx, 0, Math.max(0, window.innerWidth - w));
      var top = clamp(dragState.origTop + dy, 0, Math.max(0, window.innerHeight - h));
      hudEl.style.left = left + 'px';
      hudEl.style.top = top + 'px';
      hudEl.style.right = 'auto';
      hudEl.style.bottom = 'auto';
    });

    document.addEventListener('mouseup', function () {
      if (!dragState || !hudEl) {
        dragState = null;
        return;
      }
      var rect = hudEl.getBoundingClientRect();
      saveHudPos(rect.left, rect.top);
      dragState = null;
    });
  }

  function ensureHud() {
    if (hudEl || !document.body) return;
    ensureStyles();

    hudEl = document.createElement('div');
    hudEl.id = 'ches-hud';
    hudEl.innerHTML = [
      '<div class="ches-hud-status">',
      '  <span class="ches-hud-dot"></span>',
      '  <span class="ches-hud-status-label">Статус</span>',
      '</div>',
      '<div class="ches-hud-nick">—</div>',
      '<div class="ches-hud-pm-row">',
      '  <span class="ches-hud-pm">PM: —</span>',
      '  <span class="ches-hud-mult ches-hud-mult-off"></span>',
      '</div>'
    ].join('');
    document.body.appendChild(hudEl);

    hudDotEl = hudEl.querySelector('.ches-hud-dot');
    hudNickEl = hudEl.querySelector('.ches-hud-nick');
    hudPmEl = hudEl.querySelector('.ches-hud-pm');
    hudMultEl = hudEl.querySelector('.ches-hud-mult');
    applyHudVisibility();
    updateHud();
    installHudDrag(hudEl);
  }

  function applyHudVisibility() {
    if (!document) return;
    var nodes = document.querySelectorAll('#ches-hud');
    for (var i = 0; i < nodes.length; i++) {
      nodes[i].style.display = hudVisible ? '' : 'none';
    }
  }

  function setHudVisible(on) {
    hudVisible = !!on;
    applyHudVisibility();
  }

  function toggleHud() {
    setHudVisible(!hudVisible);
  }

  function installChatHook() {
    if (window.OUtils && typeof window.OUtils.registerCommand === 'function' && !window.__chesHudCmdRegistered) {
      window.__chesHudCmdRegistered = true;
      try {
        window.OUtils.registerCommand('/ches', function () { toggleHud(); }, 0, true);
      } catch (e) {
        window.__chesHudCmdRegistered = false;
      }
    }
    if (window.OUtils && typeof window.OUtils.addListenerToChat === 'function' && !window.__chesHudChatListener) {
      window.__chesHudChatListener = true;
      try {
        window.OUtils.addListenerToChat(function (ev) {
          var text = ev && ev[0];
          if (typeof text === 'string' && text.split(' ')[0].toLowerCase() === '/ches') {
            toggleHud();
            return false;
          }
        });
      } catch (e) {
        window.__chesHudChatListener = false;
      }
    }
    if (typeof window.sendChatInput === 'function' && !window.__chesHudCmdHooked) {
      window.__chesHudCmdHooked = true;
      var orig = window.sendChatInput;
      try {
        window.sendChatInput = new Proxy(orig, {
          apply: function (target, thisArg, args) {
            var text = args && args[0];
            if (typeof text === 'string') {
              var cmd = text.split(' ')[0].toLowerCase();
              if (cmd === '/ches') {
                toggleHud();
                return;
              }
            }
            return Reflect.apply(target, thisArg, args);
          }
        });
      } catch (e) {
        window.__chesHudCmdHooked = false;
      }
    }
  }

  function ensureThink() {
    if (thinkEl || !document.body) return;
    ensureStyles();
    thinkEl = document.createElement('div');
    thinkEl.id = 'ches-think';
    thinkEl.innerHTML = '<span class="ches-think-dot"></span>AI думает…';
    document.body.appendChild(thinkEl);
  }

  function setThinking(on) {
    ensureThink();
    if (!thinkEl) return;
    if (on) {
      thinkEl.innerHTML = '<span class="ches-think-dot"></span><span class="ches-think-text">AI думает…</span>';
      thinkEl.classList.add('ches-think-on');
      hideAiPanel();
    } else {
      thinkEl.classList.remove('ches-think-on');
    }
    lastThinking = !!on;
  }

  function ensureAiPanel() {
    if (aiEl || !document.body) return;
    ensureStyles();

    aiEl = document.createElement('div');
    aiEl.id = 'ches-ai';
    aiEl.innerHTML = [
      '<div class="ches-ai-head">',
      '  <span class="ches-ai-badge">AI ответ</span>',
      '  <span class="ches-ai-ttl"></span>',
      '</div>',
      '<div class="ches-ai-q"></div>',
      '<div class="ches-ai-line"></div>',
      '<div class="ches-ai-a"></div>'
    ].join('');
    document.body.appendChild(aiEl);

    aiTitleEl = aiEl.querySelector('.ches-ai-ttl');
    aiQEl = aiEl.querySelector('.ches-ai-q');
    aiAEl = aiEl.querySelector('.ches-ai-a');
  }

  function hideAiPanel() {
    if (!aiEl) return;
    aiEl.classList.remove('ches-ai-visible');
    if (aiHideTimer) {
      clearTimeout(aiHideTimer);
      aiHideTimer = null;
    }
  }

  function showAiPanel(payload) {
    ensureAiPanel();
    if (!aiEl) return;

    setThinking(false);

    var q = (payload && payload.q) ? String(payload.q) : '';
    var a = (payload && payload.a) ? String(payload.a) : '';
    var isErr = !!(payload && (payload.err === true || payload.err === 'true'));
    var ttl = AI_SHOW_MS;
    if (payload && payload.ttl != null) {
      var t = parseInt(payload.ttl, 10);
      if (!isNaN(t) && t > 0) ttl = Math.min(Math.max(t, 1500), 30000);
    }

    if (aiQEl) aiQEl.textContent = q ? ('Q: ' + q) : '';
    if (aiAEl) aiAEl.textContent = a || '—';
    if (aiTitleEl) aiTitleEl.textContent = Math.round(ttl / 1000) + ' с';

    if (isErr) aiEl.classList.add('ches-ai-error');
    else aiEl.classList.remove('ches-ai-error');

    aiEl.classList.add('ches-ai-visible');

    if (aiHideTimer) clearTimeout(aiHideTimer);
    var started = Date.now();
    aiHideTimer = setTimeout(hideAiPanel, ttl);

    if (aiTitleEl) {
      var tick = setInterval(function () {
        if (!aiEl || !aiEl.classList.contains('ches-ai-visible')) {
          clearInterval(tick);
          return;
        }
        var left = Math.max(0, Math.ceil((ttl - (Date.now() - started)) / 1000));
        aiTitleEl.textContent = left + ' с';
        if (left <= 0) clearInterval(tick);
      }, 400);
    }
  }

  function calcMult(pm, norm) {
    var p = parseInt(pm, 10);
    var n = parseInt(norm, 10);
    if (isNaN(p) || isNaN(n) || n <= 0) return 0;
    return Math.floor(p / n);
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
    if (hudMultEl) {
      var m = multValue;
      if (m == null || isNaN(m)) m = 0;
      m = Math.floor(m);
      if (m >= 1) {
        hudMultEl.textContent = 'x' + m;
        hudMultEl.classList.remove('ches-hud-mult-off');
      } else {
        hudMultEl.textContent = '';
        hudMultEl.classList.add('ches-hud-mult-off');
      }
    }
  }

  function applyState(data) {
    if (!data || typeof data !== 'object') return;
    if (data.hud && typeof data.hud === 'object' && !dragState) {
      var hl = parseFloat(data.hud.left);
      var ht = parseFloat(data.hud.top);
      if (!isNaN(hl) && !isNaN(ht)) {
        var changed = !lastAppliedHudPos
          || Math.abs(lastAppliedHudPos.left - hl) > 0.5
          || Math.abs(lastAppliedHudPos.top - ht) > 0.5;
        if (changed || !hudPosReady) {
          ensureHud();
          applyHudPos(hudEl, { left: hl, top: ht });
        }
      }
    }
    if (data.nick != null) settings.nick = String(data.nick);
    if (data.pm != null) {
      var n = parseInt(data.pm, 10);
      if (!isNaN(n)) pmCount = n;
    }
    if (data.norm != null) {
      var nv = parseInt(data.norm, 10);
      if (!isNaN(nv)) normValue = nv;
    }
    if (data.mult != null) {
      var mv = parseInt(data.mult, 10);
      if (!isNaN(mv)) multValue = mv;
      else multValue = calcMult(pmCount, normValue);
    } else {
      multValue = calcMult(pmCount, normValue);
    }
    if (data.health != null) {
      var h = String(data.health);
      if (h === 'ok' || h === 'warn' || h === 'critical') healthState = h;
    }
    updateHud();

    if (data.ai && typeof data.ai === 'object') {
      var thinking = data.ai.thinking === true || data.ai.thinking === 'true';
      if (thinking) {
        setThinking(true);
        return;
      }

      if (data.ai.id != null) {
        var id = parseInt(data.ai.id, 10);
        if (!isNaN(id) && id > 0 && id !== lastAiId && data.ai.a) {
          lastAiId = id;
          showAiPanel(data.ai);
        }
      }
    } else if (lastThinking) {
      setThinking(false);
    }
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

  function showChat(msg) {
    try {
      if (typeof window.onChatMessage === 'function') {
        // 2-й аргумент — цвет времени/строки в чате (часто его красит другой скрипт в зелёный).
        // Ставим тот же голубой, что и [ChesNova]; текст после тега — белый.
        window.onChatMessage('{65C4FF}[ChesNova] {FFFFFF}' + msg, 'ff65C4FF');
        return true;
      }
    } catch (e) {}
    return false;
  }

  var loadAnnounced = false;
  function announceLoaded() {
    if (loadAnnounced) return;
    // чуть подождать, пока CEF/чат готовы
    var tries = 0;
    var timer = setInterval(function () {
      tries += 1;
      if (showChat('\u0437\u0430\u0433\u0440\u0443\u0436\u0435\u043D.') || tries >= 20) {
        loadAnnounced = true;
        clearInterval(timer);
      }
    }, 500);
  }

  window.ChesHUD = {
    showChat: showChat,
    setNick: function (nick) {
      settings.nick = (nick || '').trim();
      updateHud();
    },
    setPm: function (n) {
      pmCount = n;
      multValue = calcMult(pmCount, normValue);
      updateHud();
    },
    setNorm: function (n) {
      normValue = n;
      multValue = calcMult(pmCount, normValue);
      updateHud();
    },
    setMult: function (m) {
      multValue = m;
      updateHud();
    },
    setHealth: function (state) {
      healthState = state || 'ok';
      updateHud();
    },
    showAi: function (q, a, isError) {
      lastAiId += 1;
      showAiPanel({ id: lastAiId, q: q || '', a: a || '', err: !!isError, ttl: AI_SHOW_MS });
    },
    setThinking: setThinking,
    hideAi: hideAiPanel,
    setVisible: setHudVisible,
    toggle: toggleHud,
    update: updateHud,
    poll: pollHud,
    resetPos: function () {
      if (!hudEl) return;
      hudEl.style.left = '';
      hudEl.style.top = '';
      hudEl.style.right = '14px';
      hudEl.style.bottom = '14px';
      // сохранить дефолт как координаты после reflow
      setTimeout(function () {
        if (!hudEl) return;
        var rect = hudEl.getBoundingClientRect();
        saveHudPos(rect.left, rect.top);
      }, 30);
    }
  };

  function tick() {
    if (!document.body) {
      setTimeout(tick, 50);
      return;
    }
    try { ensureHud(); } catch (e) {}
    try { ensureAiPanel(); } catch (e) {}
    try { ensureThink(); } catch (e) {}
    try { installChatHook(); } catch (e) {}
    try { announceLoaded(); } catch (e) {}
  }

  setInterval(function () {
    ensureHud();
    ensureAiPanel();
    ensureThink();
    installChatHook();
    pollHud();
  }, POLL_MS);

  tick();
})();
