(function () {
  'use strict';

  /* ====================== НАСТРОЙКИ ====================== */
  var CURSOR_NAME = 'ChesPanel';
  var SETTINGS_URL = 'http://127.0.0.1:17890/settings';
  var SETTINGS_CHATLOG_URL = 'http://127.0.0.1:17890/settings/chatlog';
  var SCRIPTS_PATH_URL = 'http://127.0.0.1:17890/scripts/path';
  var DASH_URL = 'http://127.0.0.1:17890/hud';
  var PUN_URL = 'http://127.0.0.1:17890/punishments';
  var PM_URL = 'http://127.0.0.1:17890/pmlogs';
  var PM_CLEAR_URL = 'http://127.0.0.1:17890/pmlogs/clear';
  var NORM_URL = 'http://127.0.0.1:17890/norm';
  var NORM_SAVE_URL = 'http://127.0.0.1:17890/norm/save';
  var DAYSOFF_URL = 'http://127.0.0.1:17890/daysoff';
  var DAYSOFF_ADD_URL = 'http://127.0.0.1:17890/daysoff/add';
  var DAYSOFF_DELETE_URL = 'http://127.0.0.1:17890/daysoff/delete';
  var DAYSOFF_FORUM_URL = 'http://127.0.0.1:17890/daysoff/forum';
  var SCRIPTS_URL = 'http://127.0.0.1:17890/scripts';
  var SCRIPTS_INSTALL_URL = 'http://127.0.0.1:17890/scripts/install';
  var SCRIPTS_TOPIC_URL = 'http://127.0.0.1:17890/scripts/topic';
  var BINDS_URL = 'http://127.0.0.1:17890/binds';
  var BINDS_TOGGLE_URL = 'http://127.0.0.1:17890/binds/toggle';
  var BINDS_SAVE_URL = 'http://127.0.0.1:17890/binds/save';
  var BINDS_DELETE_URL = 'http://127.0.0.1:17890/binds/delete';
  var BINDS_ENABLE_URL = 'http://127.0.0.1:17890/binds/enable';
  var BINDS_CATEGORY_ADD_URL = 'http://127.0.0.1:17890/binds/category/add';
  var BINDS_CATEGORY_TOGGLE_URL = 'http://127.0.0.1:17890/binds/category/toggle';
  var BINDS_CATEGORY_DELETE_URL = 'http://127.0.0.1:17890/binds/category/delete';
  var TESTER_URL = 'http://127.0.0.1:17890/tester';
  var TESTER_TOGGLE_URL = 'http://127.0.0.1:17890/tester/toggle';
  var TESTER_CHECK_URL = 'http://127.0.0.1:17890/tester/check';
  var TESTER_DOWNLOAD_URL = 'http://127.0.0.1:17890/tester/download';
  var TESTER_INSTALL_URL = 'http://127.0.0.1:17890/tester/install';
  var TESTER_ROLLBACK_URL = 'http://127.0.0.1:17890/tester/rollback';
  var UPDATES_URL = 'http://127.0.0.1:17890/updates';
  var UPDATES_CHECK_URL = 'http://127.0.0.1:17890/updates/check';
  var UPDATES_SAVE_URL = 'http://127.0.0.1:17890/updates/save';
  var UPDATES_DOWNLOAD_URL = 'http://127.0.0.1:17890/updates/download';
  var UPDATES_INSTALL_URL = 'http://127.0.0.1:17890/updates/install';
  var NORM_RESET_CONFIRM_URL = 'http://127.0.0.1:17890/reset/confirm';
  var NORM_RESET_CANCEL_URL = 'http://127.0.0.1:17890/reset/cancel';
  var NOTIFICATIONS_URL = 'http://127.0.0.1:17890/notifications';
  var NOTIFICATIONS_REFRESH_URL = 'http://127.0.0.1:17890/notifications/refresh';
  var NOTIFICATIONS_READ_URL = 'http://127.0.0.1:17890/notifications/read';
  var CLOUD_URL = 'http://127.0.0.1:17890/cloud';
  var CLOUD_CHECK_URL = 'http://127.0.0.1:17890/cloud/check';
  var CLOUD_NICK_URL = 'http://127.0.0.1:17890/cloud/nick';
  var HELP_URL = 'http://127.0.0.1:17890/help';
  var HELP_OPEN_URL = 'http://127.0.0.1:17890/help/open';
  var HELP_CLEAR_URL = 'http://127.0.0.1:17890/help/clear';
  var DIAGNOSTICS_URL = 'http://127.0.0.1:17890/diagnostics';
  var DIAGNOSTICS_REFRESH_URL = 'http://127.0.0.1:17890/diagnostics/refresh';
  var AI_URL = 'http://127.0.0.1:17890/ai';
  var AI_TOGGLE_URL = 'http://127.0.0.1:17890/ai/toggle';
  var AI_PROVIDER_URL = 'http://127.0.0.1:17890/ai/provider';
  var AI_ASK_URL = 'http://127.0.0.1:17890/ai/ask';
  var AI_CLEAR_URL = 'http://127.0.0.1:17890/ai/clear';

  var domReady = false;
  var hooked = false;
  var initialized = false;
  var visible = false;
  var container = null;
  var overlay = null;
  var contentTitleEl = null;
  var contentBodyEl = null;
  var currentView = 'Dashboard';
  var navButtons = {};
  var topButtons = {};
  var topTitleEl = null;
  var betaBadgeEl = null;
  var resetConfirmEl = null;
  var resetConfirmTextEl = null;
  var resetConfirmShown = false;

  var settings = {
    nick: '',
    norm: '',
    autoResetEnabled: false,
    startWithWindows: false,
    resetTime: { hours: '00', minutes: '00' },
    binds: { panel: 'F10', normReset: 'F9', hideHud: 'F7' },
    bindEnabled: { panel: false, normReset: false, hideHud: false },
    chatlogPath: '',
    gamePath: ''
  };
  var settingsRefs = {};

  var aiProviders = [
    { id: 'gemini', label: 'Gemini', price: 'free' },
    { id: 'deepseek', label: 'DeepSeek', price: 'paid' },
    { id: 'groq', label: 'Groq', price: 'free' }
  ];
  var aiState = {
    enabled: false,
    provider: 'gemini',
    busy: false,
    limitText: '',
    limit: 0,
    used: 0,
    remaining: 0,
    history: [],
    loaded: false
  };
  var aiProviderButtons = {};
  var aiRefs = { toggle: null, statusEl: null, limitEl: null, promptsList: null, answersList: null, askIn: null, askBtn: null, clearBtn: null };


  var dashState = {
    admin: { nick: '—', norm: '—', daysOff: '—' },
    systems: { chatlog: '—', root: '—', hud: '—' }
  };
  var dashRefs = { info: {}, sys: {} };
  var dashPollBusy = false;

  var punPeriods = [
    { id: 'today', label: 'Сегодня' },
    { id: '3days', label: '3 Дня' },
    { id: '10days', label: '10 Дней' },
    { id: 'all', label: 'За все время' }
  ];
  var punTypes = [
    { id: 'all', label: 'Все' },
    { id: 'ban', label: 'Ban' },
    { id: 'gunban', label: 'Gunban' },
    { id: 'jail', label: 'Jail' },
    { id: 'kick', label: 'Kick' },
    { id: 'mute', label: 'Mute' },
    { id: 'rmute', label: 'Rmute' },
    { id: 'vmute', label: 'Vmute' },
    { id: 'warn', label: 'Warn' },
    { id: 'sban', label: 'Sban' }
  ];
  var punState = {
    period: 'today',
    type: 'all',
    counts: { all: 0, ban: 0, gunban: 0, jail: 0, kick: 0, mute: 0, rmute: 0, vmute: 0, warn: 0, sban: 0 },
    rows: [],
    loaded: false
  };
  var punRefs = { periodBtns: {}, typeBtns: {}, menu: null, search: null };

  var pmLogState = { entries: [], loaded: false };
  var pmLogRefs = { log: null, search: null };

  var normState = { rows: [], loaded: false, selectedDate: null, editing: false };
  var normRefs = { body: null, editBtn: null };

  var daysMonths = ['Январь', 'Февраль', 'Март', 'Апрель', 'Май', 'Июнь', 'Июль', 'Август', 'Сентябрь', 'Октябрь', 'Ноябрь', 'Декабрь'];
  var daysOffState = { monthIndex: 7, year: '2026', count: 0, rows: [], loaded: false, selected: null };
  var daysOffRefs = { body: null, dateIn: null, countEl: null };

  var bindTypeValues = { 0: 'hotkey', 1: 'hotstring', 2: 'macro' };
  var bindTypes = ['Клавишный бинд', 'Текстовая замена', 'Массовые сообщения'];
  var bindsState = { enabled: true, category: 'Все', categories: [], binds: [], search: '', selectedTrigger: '', loaded: false, editor: null, confirmTrigger: '', confirmCategory: '' };
  var bindsRefs = { listBody: null, previewBody: null, toggle: null, searchIn: null, catSlot: null, catBody: null, catIn: null };

  var scriptsList = [
    { id: 's1', name: 'Скрипт 1', url: 'https://example.com/script1' },
    { id: 's2', name: 'Скрипт 2', url: 'https://example.com/script2' },
    { id: 's3', name: 'Скрипт 3', url: 'https://example.com/script3' },
    { id: 's4', name: 'Скрипт 4', url: 'https://example.com/script4' },
    { id: 's5', name: 'Скрипт 5', url: 'https://example.com/script5' },
    { id: 's6', name: 'Скрипт 6', url: 'https://example.com/script6' }
  ];
  var scriptsState = { status: null, gamePath: '', gameOk: false, packages: [], loaded: false };
  var scriptsRefs = { list: null, modal: null, modalBox: null };
  /* Тексты «Инфо» по id пакета (ссылка берётся из topic с бэкенда) */
  var SCRIPT_INFO = {
    atools: {
      title: 'aTools',
      body: '\u041e\u0441\u043d\u043e\u0432\u043d\u044b\u0435 \u043a\u043e\u043c\u0430\u043d\u0434\u044b\n/wh\n/ddl\n/unl\n/trec\n\n\u041f\u043e\u043b\u043d\u0430\u044f \u0438\u043d\u0444\u043e\u0440\u043c\u0430\u0446\u0438\u044f \u043d\u0430 \u0444\u043e\u0440\u0443\u043c\u0435'
    },
    onishi: {
      title: 'Onishi',
      body: '\u041e\u0441\u043d\u043e\u0432\u043d\u044b\u0435 \u043a\u043e\u043c\u0430\u043d\u0434\u044b\n/onishi'
    },
    fpsunlocker: {
      title: 'FPS Unlocker',
      body: '\u0421\u043d\u0438\u043c\u0430\u0435\u0442 \u043e\u0433\u0440\u0430\u043d\u0438\u0447\u0438\u0442\u0435\u043b\u044c FPS'
    },
    camhunt: {
      title: 'CamHunt',
      body: '\u0421\u0432\u043e\u0431\u043e\u0434\u043d\u0430\u044f \u043a\u0430\u043c\u0435\u0440\u0430\n\u0418\u0441\u043f\u043e\u043b\u044c\u0437\u0443\u0435\u0442\u0441\u044f \u0438\u0441\u043a\u043b\u044e\u0447\u0438\u0442\u0435\u043b\u044c\u043d\u043e \u0434\u043b\u044f \u0441\u044a\u0451\u043c\u043e\u043a \u043a\u043e\u043d\u0442\u0435\u043d\u0442\u0430'
    },
    weather_time: {
      title: '\u041f\u043e\u0433\u043e\u0434\u0430/\u0412\u0440\u0435\u043c\u044f',
      body: '\u041c\u0435\u043d\u044f\u0435\u0442 \u0432\u0430\u0448\u0443 \u043f\u043e\u0433\u043e\u0434\u0443 \u0438 \u0432\u0440\u0435\u043c\u044f, \u043d\u0435 \u0437\u0430\u0442\u0440\u0430\u0433\u0438\u0432\u0430\u044f \u0441\u0435\u0440\u0432\u0435\u0440\u043d\u044b\u0435 \u043a\u043e\u043c\u0430\u043d\u0434\u044b\n\n\u041e\u0441\u043d\u043e\u0432\u043d\u044b\u0435 \u043a\u043e\u043c\u0430\u043d\u0434\u044b\n/st\n/sw'
    },
    clientside: {
      title: 'clientside.dll',
      body: '\u041b\u043e\u0433\u0438\u0440\u0443\u0435\u0442 \u0434\u043e\u043f. \u0438\u043d\u0444\u0443 \u0432 \u043a\u0440\u0430\u0448-\u043b\u043e\u0433'
    },
    tracer: {
      title: '\u0422\u0440\u0430\u0441\u0435\u0440\u0430',
      body: '\u041e\u0442\u043e\u0431\u0440\u0430\u0436\u0430\u0435\u0442 \u0442\u0440\u0430\u0441\u0435\u0440 \u043f\u0443\u043b\u044c'
    }
  };



  var testerState = { enabled: false, version: '', info: '', loaded: false };
  var testerRefs = { toggle: null, statusEl: null, infoEl: null, btnCheck: null, btnDownload: null, btnInstall: null, btnRollback: null, confirm: '' };

  var updatesState = { version: '', latest: '', hasUpdate: false, required: false, changelog: [], download: '', checkOnStartup: true, lastCheck: '', message: '', loaded: false };
  var updatesRefs = { toggle: null, statusEl: null, checkBtn: null, updateBtn: null, dlBtn: null, installBtn: null, changelogBody: null };

  var helpText = [
    'СТАРТ',
    '',
    '1. Запускайте ChesNova через лаунчер.',
    '2. В игре откройте панель командой /ches.',
    '3. Во вкладке Cloud укажите ник и дождитесь',
    '   статуса «Подтверждён».',
    '4. В «Настройках» укажите норму PM.',
    '5. Путь к игре и chatlog обычно находятся сами.',
    '   Если нет — вкладки «Настройки» / «Скрипты».',
    '',
    'Без подтверждённого Cloud счётчик PM не работает.',
    '',
    '————————————————',
    'ПАНЕЛЬ',
    '',
    '/ches — открыть или закрыть панель.',
    'Esc — закрыть панель.',
    '',
    'F7 (по умолчанию) — показать / скрыть счётчик в игре.',
    'Клавишу можно сменить в «Настройках».',
    '',
    'Сброс PM — автосброс по времени в «Настройках».',
    '',
    '————————————————',
    'СЧЁТЧИК В ИГРЕ',
    '',
    'Показывает ник, PM и статус.',
    'Можно перетащить мышью.',
    'Ответ AI появляется слева внизу на несколько секунд.',
    '',
    '————————————————',
    'НОРМА И ОТГУЛЫ',
    '',
    'История нормы — вкладка «Норма».',
    'Отгулы — вкладка «Отгулы».',
    '',
    '————————————————',
    'НАКАЗАНИЯ И PM-ЛОГИ',
    '',
    'Учитываются ваши действия из чата.',
    'Есть фильтры по периоду, типу и поиску.',
    '',
    '————————————————',
    'БИНДЫ',
    '',
    'Включите бинды на вкладке «Бинды».',
    'Можно создавать клавиши, текстовые замены и макросы.',
    '',
    'Примеры:',
    '  F1   — клавиша',
    '  +1   — Shift+1',
    '  ^F5  — Ctrl+F5',
    '  !F2  — Alt+F2',
    '',
    '————————————————',
    'AI',
    '',
    'По умолчанию выключен.',
    'Включите на вкладке AI, выберите провайдера.',
    'Лимит запросов на день выдаётся через Cloud.',
    '',
    'В чате: /ai ваш вопрос + Enter',
    'Или вкладка AI → «Спросить».',
    '',
    '————————————————',
    'ОБНОВЛЕНИЯ И СКРИПТЫ',
    '',
    '«Обновления» — проверить и установить новую версию.',
    '«Скрипты» — установка полезных дополнений к игре.',
    '«Тестировщик» — только если вам выдали доступ к beta.',
    '',
    '————————————————',
    'CLOUD',
    '',
    'Нужен для доступа и лимита AI.',
    'Если ник не найден — проверьте написание или обратитесь',
    'к тому, кто выдаёт доступ.',
    '',
    '————————————————',
    'ПОДДЕРЖКА',
    '',
    'Автор: Misha_Ches',
    'VK: vk.com/m.ches'
  ];

  var helpErrors = [];
  var helpRefs = { errBody: null, refreshBtn: null, openBtn: null, clearBtn: null };
  var helpLoaded = false;

  var cloudState = {
    status: 'pending',
    message: 'Ожидание проверки доступа',
    lastCheck: '',
    nick: '',
    loaded: false
  };
  var cloudRefs = { nickEl: null, statusRow: null, msgEl: null, lastEl: null, checkBtn: null, nickBtn: null, nickWrap: null, nickIn: null, nickSaveBtn: null };

  var diagState = {
    health: 'ok',
    healthMsg: 'Все системы работают нормально',
    text: '',
    loaded: false
  };
  var diagRefs = { healthRow: null, textBody: null, refreshBtn: null };

  var mainNav = [
    { id: 'Dashboard', label: 'Главная' },
    { id: 'Punishments', label: 'Наказания' },
    { id: 'PMLogs', label: 'PM логи' },
    { id: 'NormHistory', label: 'Норма' },
    { id: 'DaysOff', label: 'Отгулы' },
    { id: 'Binds', label: 'Бинды' },
    { id: 'Scripts', label: 'Скрипты' }
  ];

  var bottomNav = [
    { id: 'Tester', label: 'Тестировщик' },
    { id: 'Updates', label: 'Обновления' },
    { id: 'Help', label: 'Помощь' },
    { id: 'Cloud', label: 'Cloud' },
    { id: 'Diagnostics', label: 'Диагностика' }
  ];

  var topList = [
    { id: 'AI', label: 'AI' },
    { id: 'Notifications', label: 'Уведомления' },
    { id: 'Settings', label: 'Настройки' }
  ];

  var notificationsCount = 0;
  var notificationsList = [];
  var notificationsRefs = { list: null, refreshBtn: null, readBtn: null };

  /* ====================== СТИЛИ ======================
     Каждый блок стилей отдельно — легко найти и изменить.
  ======================================================= */
  var chesStyles = `
    /* ---------- Оверлей ---------- */
    .ches-overlay {
      position: fixed;
      top: 0;
      left: 0;
      width: 100vw;
      height: 100vh;
      background: rgba(0, 0, 0, .55);
      z-index: 9990;
      display: none;
    }

    /* ---------- Панель ---------- */
    .ches {
      position: fixed;
      top: 50%;
      left: 50%;
      transform: translate(-50%, -50%);
      width: 920px;
      height: 590px;
      max-height: 92vh;
      background: #0a0e14;
      border: 1px solid #232c3a;
      border-radius: 12px;
      box-shadow: 0 0 40px 10px rgba(0, 0, 0, .6);
      z-index: 9991;
      font-family: "Open Sans", Arial, sans-serif;
      color: #f5f7fb;
      display: flex;
      flex-direction: column;
      overflow: hidden;
    }

    /* ---------- Шапка ---------- */
    .ches-top {
      height: 48px;
      background: #10161f;
      border-bottom: 1px solid #232c3a;
      display: flex;
      align-items: center;
      padding: 0 20px;
      flex-shrink: 0;
    }
    .ches-top-title {
      font-size: 14px;
      font-weight: 700;
      letter-spacing: .4px;
      color: #f5f7fb;
      flex: 1;
      display: flex;
      align-items: center;
    }
    .ches-top-beta {
      margin-left: 8px;
      flex-shrink: 0;
      font-size: 10px;
      font-weight: 700;
      text-transform: uppercase;
      letter-spacing: .4px;
      border-radius: 4px;
      padding: 1px 6px;
      background: rgba(246, 166, 35, .18);
      color: #f6a623;
      border: 1px solid rgba(246, 166, 35, .45);
    }
    .ches-top-beta.hidden {
      display: none;
    }
    .ches-top-btns {
      display: flex;
      align-items: center;
    }

    /* ---------- Кнопки шапки ---------- */
    .ches-top-btn {
      height: 28px;
      line-height: 26px;
      padding: 0 14px;
      margin-left: 10px;
      background: #161d29;
      color: #aab4c5;
      font-size: 12px;
      border-radius: 6px;
      cursor: pointer;
      user-select: none;
      border: 1px solid #232c3a;
    }
    .ches-top-btn:hover {
      background: #1e2736;
      color: #f5f7fb;
    }
    .ches-top-btn.active {
      background: #22304a;
      color: #f5f7fb;
      font-weight: 600;
      border-color: #3b82f6;
    }
    .ches-top-btn.has-unread {
      background: #3a1a22;
      border-color: #ff6b8c;
      color: #ff8fa8;
      font-weight: 600;
      animation: ches-notif-pulse 1.2s ease-in-out infinite;
    }
    .ches-top-btn.has-unread:hover {
      background: #4a222c;
      color: #ffb0c0;
    }
    @keyframes ches-notif-pulse {
      0%, 100% {
        box-shadow: 0 0 0 0 rgba(255, 107, 140, .5);
      }
      50% {
        box-shadow: 0 0 0 6px rgba(255, 107, 140, 0);
      }
    }

    /* ---------- Кнопка закрытия ---------- */
    .ches-top-close {
      width: 28px;
      height: 28px;
      display: flex;
      align-items: center;
      justify-content: center;
      background: #161d29;
      color: #aab4c5;
      border-radius: 6px;
      cursor: pointer;
      user-select: none;
      border: 1px solid #232c3a;
      margin-left: 12px;
    }
    .ches-top-close:hover {
      background: #3a1e2c;
      color: #ff6b8c;
      border-color: #ff6b8c;
    }
    .ches-top-close::before {
      content: "×";
      font-weight: 700;
      font-size: 18px;
    }

    /* ---------- Тело / сайдбар ---------- */
    .ches-body {
      flex: 1;
      display: flex;
      min-height: 0;
    }
    .ches-sidebar {
      width: 220px;
      background: #0c1119;
      border-right: 1px solid #232c3a;
      padding: 14px 0;
      overflow-y: auto;
      flex-shrink: 0;
    }

    /* ---------- Навигация ---------- */
    .ches-nav {
      display: flex;
      align-items: center;
      height: 36px;
      padding: 0 14px;
      margin: 2px 10px;
      cursor: pointer;
      color: #93a0b3;
      font-size: 13px;
      position: relative;
      border-radius: 7px;
      user-select: none;
    }
    .ches-nav:hover {
      background: #141b26;
      color: #f5f7fb;
    }
    .ches-nav.active {
      background: #1a2332;
      color: #f5f7fb;
      font-weight: 600;
    }
    .ches-nav-ind {
      position: absolute;
      left: 0;
      top: 50%;
      transform: translateY(-50%);
      width: 3px;
      height: 16px;
      background: transparent;
      border-radius: 2px;
    }
    .ches-nav.active .ches-nav-ind {
      background: #3b82f6;
    }
    .ches-nav-sep {
      height: 1px;
      background: #232c3a;
      margin: 12px 16px;
    }

    /* ---------- Контент ---------- */
    .ches-content {
      flex: 1;
      background: #0a0e14;
      padding: 24px 32px;
      overflow-y: auto;
    }
    .ches-content-title {
      font-size: 22px;
      font-weight: 700;
      color: #f5f7fb;
      margin: 0 0 18px;
    }
    .ches-content-body {
      font-size: 13px;
      color: #aab4c5;
      line-height: 1.5;
      padding-bottom: 40px;
    }

    /* ---------- Формы ---------- */
    .ches-form {
      display: flex;
      flex-direction: column;
      max-width: 420px;
    }
    .ches-form > * + * {
      margin-top: 20px;
    }
    .ches-field-block {
      display: flex;
      flex-direction: column;
    }
    .ches-field-block > * + * {
      margin-top: 10px;
    }
    .ches-field-label {
      font-size: 12px;
      color: #7c8899;
      letter-spacing: .2px;
    }

    /* ---------- Поле ввода ---------- */
    .ches-inputbox {
      position: relative;
      display: inline-flex;
      align-items: center;
      width: 220px;
      height: 40px;
    }
    .ches-input {
      font-family: Roboto, "Open Sans", Arial, sans-serif;
      font-size: 1rem;
      font-weight: 600;
      border-radius: 6px;
      background-color: #2e303c;
      color: #fff;
      width: 100%;
      height: 100%;
      padding: 5px 10px 0;
      line-height: 1.5;
      margin: 0;
      border: none;
      outline: none;
      box-sizing: border-box;
    }
    .ches-input:focus {
      box-shadow: 0 0 0 1px rgba(101, 196, 102, .35);
    }
    .ches-input__placeholder {
      position: absolute;
      left: 11px;
      top: 50%;
      transform: translateY(-50%);
      color: #fff;
      font-family: Roboto, "Open Sans", Arial, sans-serif;
      font-size: 1rem;
      font-weight: 600;
      pointer-events: none;
      transition: .2s;
      opacity: .8;
    }
    .ches-input:focus + .ches-input__placeholder,
    .ches-input:not(:placeholder-shown) + .ches-input__placeholder {
      opacity: 0;
      visibility: hidden;
    }

    /* ---------- Переключатели ---------- */
    .ches-toggle-row {
      display: flex;
      align-items: center;
      justify-content: space-between;
      background: #121824;
      border: 1px solid #232c3a;
      border-radius: 10px;
      padding: 12px 14px;
    }
    .ches-toggle-row > * + * {
      margin-left: 16px;
    }
    .ches-toggle-text {
      display: flex;
      flex-direction: column;
      min-width: 0;
      flex: 1;
    }
    .ches-toggle-text > * + * {
      margin-top: 3px;
    }
    .ches-toggle-label {
      font-size: 13px;
      color: #f5f7fb;
      font-weight: 600;
    }
    .ches-toggle-hint {
      font-size: 11px;
      color: #5d6879;
      line-height: 1.35;
    }
    .ches-toggle {
      position: relative;
      flex-shrink: 0;
      width: 48px;
      height: 26px;
      padding: 0;
      border: none;
      border-radius: 13px;
      background: #2e303c;
      cursor: pointer;
      transition: background .2s;
      outline: none;
    }
    .ches-toggle.on {
      background: #3b82f6;
    }
    .ches-toggle-knob {
      position: absolute;
      top: 3px;
      left: 3px;
      width: 20px;
      height: 20px;
      border-radius: 50%;
      background: #fff;
      box-shadow: 0 1px 3px rgba(0, 0, 0, .35);
      transition: transform .2s ease;
    }
    .ches-toggle.on .ches-toggle-knob {
      transform: translateX(22px);
    }

    /* ---------- Настройки ---------- */
    .ches-settings {
      display: flex;
      flex-direction: column;
      max-width: 640px;
    }
    .ches-settings > * + * {
      margin-top: 16px;
    }
    .ches-settings-block {
      background: #121824;
      border: 1px solid #232c3a;
      border-radius: 10px;
      padding: 16px;
      display: flex;
      flex-direction: column;
    }
    .ches-settings-block > * + * {
      margin-top: 12px;
    }
    .ches-settings-block-title {
      font-size: 13px;
      font-weight: 700;
      color: #f5f7fb;
      letter-spacing: .3px;
    }
    .ches-settings-row {
      display: flex;
      align-items: center;
      flex-wrap: wrap;
    }
    .ches-settings-row > * + * {
      margin-left: 14px;
    }
    .ches-settings-field {
      display: flex;
      flex-direction: column;
    }
    .ches-settings-field > * + * {
      margin-top: 6px;
    }
    .ches-settings-label {
      font-size: 12px;
      color: #7c8899;
    }
    .ches-settings-info {
      font-size: 12px;
      color: #5d6879;
      flex: 1;
      min-width: 0;
      line-height: 1.4;
    }
    .ches-settings-time-sep {
      font-size: 18px;
      font-weight: 700;
      color: #7c8899;
    }
    .ches-settings-nickval {
      min-width: 160px;
      height: 40px;
      line-height: 40px;
      padding: 0 12px;
      background: #161d29;
      border: 1px solid #232c3a;
      border-radius: 6px;
      color: #f5f7fb;
      font-size: 14px;
      font-weight: 600;
      box-sizing: border-box;
    }
    .ches-settings-nickval.empty {
      color: #5d6879;
      font-weight: 500;
    }
    .ches-settings-save {
      align-self: flex-end;
      height: 36px;
      line-height: 34px;
      padding: 0 28px;
      background: #22304a;
      border: 1px solid #3b82f6;
      color: #f5f7fb;
      font-size: 13px;
      font-weight: 600;
      border-radius: 8px;
      cursor: pointer;
      user-select: none;
    }
    .ches-settings-save:hover {
      background: #2a3c5c;
    }
    .ches-settings-save.saved {
      background: #1c3a2a;
      border-color: #65c466;
    }

    /* ---------- Тумблеры биндов (зелёный вкл / красный выкл) ---------- */
    .ches-toggle.bind {
      background: #c0392b;
      box-shadow: inset 0 0 6px rgba(0, 0, 0, .35);
    }
    .ches-toggle.bind:hover {
      background: #d14435;
    }
    .ches-toggle.bind.on {
      background: #27ae60;
    }
    .ches-toggle.bind.on:hover {
      background: #2ec06e;
    }

    /* ---------- Вкладка AI ---------- */
    .ches-ai {
      display: flex;
      flex-direction: column;
      max-width: 700px;
    }
    .ches-ai > * + * {
      margin-top: 16px;
    }
    .ches-ai-toolbar {
      display: flex;
      flex-wrap: wrap;
    }
    .ches-ai-opt {
      display: flex;
      align-items: center;
      flex-wrap: nowrap;
      height: 34px;
      padding: 0 16px;
      margin-right: 10px;
      margin-bottom: 8px;
      background: #161d29;
      border: 1px solid #232c3a;
      color: #aab4c5;
      font-size: 12px;
      border-radius: 8px;
      cursor: pointer;
      user-select: none;
    }
    .ches-ai-opt:hover {
      background: #1e2736;
      color: #f5f7fb;
    }
    .ches-ai-opt.active {
      background: #22304a;
      color: #f5f7fb;
      font-weight: 600;
      border-color: #3b82f6;
    }
    .ches-ai-opt-badge {
      margin-left: 8px;
      flex-shrink: 0;
      font-size: 10px;
      font-weight: 700;
      text-transform: uppercase;
      letter-spacing: .4px;
      border-radius: 4px;
      padding: 1px 6px;
    }
    .ches-ai-opt-badge.free {
      background: rgba(39, 174, 96, .18);
      color: #2ec06e;
      border: 1px solid rgba(39, 174, 96, .4);
    }
    .ches-ai-opt-badge.paid {
      background: rgba(192, 57, 43, .18);
      color: #e05d4b;
      border: 1px solid rgba(192, 57, 43, .4);
    }
    .ches-ai-card {
      background: #121824;
      border: 1px solid #232c3a;
      border-radius: 10px;
      padding: 14px;
      display: flex;
      flex-direction: column;
    }
    .ches-ai-card > * + * {
      margin-top: 10px;
    }
    .ches-ai-status {
      font-size: 12px;
      font-weight: 600;
    }
    .ches-ai-status.on {
      color: #2ec06e;
    }
    .ches-ai-status.off {
      color: #7c8899;
    }
    .ches-ai-columns {
      display: flex;
      align-items: stretch;
    }
    .ches-ai-columns > * + * {
      margin-left: 16px;
    }
    .ches-ai-pane {
      flex: 1;
      min-width: 0;
      background: #121824;
      border: 1px solid #232c3a;
      border-radius: 10px;
      padding: 14px;
      display: flex;
      flex-direction: column;
    }
    .ches-ai-pane-title {
      font-size: 13px;
      font-weight: 700;
      color: #f5f7fb;
      letter-spacing: .3px;
    }
    .ches-ai-pane-title + * {
      margin-top: 10px;
    }
    .ches-ai-list {
      min-height: 220px;
      max-height: 320px;
      overflow-y: auto;
      background: #0c1119;
      border: 1px solid #1c2431;
      border-radius: 8px;
      padding: 10px;
    }
    .ches-ai-empty {
      color: #5d6879;
      font-size: 12px;
      line-height: 1.5;
      text-align: center;
      padding: 24px 0;
    }


    .ches-ai-ask {
      display: block;
      width: 100%;
      box-sizing: border-box;
    }
    .ches-ai-ask-field {
      display: block;
      width: 100%;
      box-sizing: border-box;
      margin: 0 0 12px 0;
    }
    .ches-ai-ask-field .ches-inputbox {
      display: block;
      width: 100%;
      max-width: 100%;
      box-sizing: border-box;
      margin: 0;
    }
    .ches-ai-ask-actions {
      display: block;
      width: 100%;
      box-sizing: border-box;
      overflow: hidden;
    }
    .ches-ai-ask-actions .ches-ai-btn {
      display: inline-block;
      vertical-align: middle;
      margin: 0 10px 6px 0;
      height: 28px;
      line-height: 26px;
      padding: 0 12px;
      font-size: 11px;
      border-radius: 6px;
    }
    .ches-ai-ask-actions .ches-ai-btn:last-child {
      margin-right: 0;
    }
    .ches-ai-btn {
      height: 40px;
      line-height: 38px;
      padding: 0 18px;
      background: #22304a;
      border: 1px solid #3b82f6;
      color: #f5f7fb;
      font-size: 12px;
      font-weight: 600;
      border-radius: 8px;
      cursor: pointer;
      user-select: none;
      white-space: nowrap;
    }
    .ches-ai-btn:hover { background: #2a3c5c; }
    .ches-ai-btn.ghost {
      background: #161d29;
      border-color: #232c3a;
      color: #aab4c5;
      font-weight: 500;
    }
    .ches-ai-btn.ghost:hover {
      background: #3a1e2c;
      color: #ff6b8c;
      border-color: #ff6b8c;
    }
    .ches-ai-btn.busy {
      opacity: .6;
      pointer-events: none;
    }
    .ches-ai-limit {
      font-size: 12px;
      color: #7c8899;
      line-height: 1.4;
    }
    .ches-ai-hint {
      font-size: 11px;
      color: #5d6879;
      line-height: 1.45;
    }
    .ches-ai-item {
      padding: 10px 8px;
      border-bottom: 1px solid #1b2431;
    }
    .ches-ai-item:last-child { border-bottom: none; }
    .ches-ai-item + .ches-ai-item {
      margin-top: 2px;
    }
    .ches-ai-item-time {
      font-size: 10px;
      color: #5d6879;
      margin-bottom: 5px;
    }
    .ches-ai-item-text {
      font-size: 12px;
      color: #e6ebf4;
      line-height: 1.45;
      white-space: pre-wrap;
      word-break: break-word;
    }

    /* ---------- Вкладка Главная ---------- */
    .ches-dash-columns {
      display: flex;
      align-items: stretch;
    }
    .ches-dash-columns > * + * {
      margin-left: 16px;
    }
    .ches-dash-pane {
      flex: 1;
      min-width: 0;
      background: #121824;
      border: 1px solid #232c3a;
      border-radius: 10px;
      padding: 16px;
      display: flex;
      flex-direction: column;
    }
    .ches-dash-pane-title {
      font-size: 13px;
      font-weight: 700;
      color: #f5f7fb;
      letter-spacing: .3px;
    }
    .ches-dash-pane-title + * {
      margin-top: 12px;
    }
    .ches-dash-row {
      display: flex;
      align-items: center;
      justify-content: space-between;
      min-height: 34px;
    }
    .ches-dash-row + .ches-dash-row,
    .ches-dash-sys + .ches-dash-sys {
      border-top: 1px solid #1c2431;
    }
    .ches-dash-row-label {
      font-size: 12px;
      color: #7c8899;
    }
    .ches-dash-row-value {
      font-size: 13px;
      font-weight: 600;
      color: #f5f7fb;
      max-width: 60%;
      overflow: hidden;
      text-overflow: ellipsis;
      white-space: nowrap;
      margin-left: 16px;
    }
    .ches-dash-sys {
      display: flex;
      align-items: center;
      justify-content: space-between;
      min-height: 34px;
    }
    .ches-dash-dot {
      width: 9px;
      height: 9px;
      border-radius: 50%;
      flex-shrink: 0;
      background: rgba(255, 255, 255, .22);
    }
    .ches-dash-dot.on {
      background: #41D07A;
      box-shadow: 0 0 0 2px rgba(65, 208, 122, .18);
    }
    .ches-dash-dot.off {
      background: #FF5B6B;
      box-shadow: 0 0 0 2px rgba(255, 91, 107, .18);
    }

    /* ---------- Вкладка Наказания ---------- */
    .ches-pun {
      display: flex;
      flex-direction: column;
      max-width: 760px;
    }
    .ches-pun > * + * {
      margin-top: 14px;
    }
    .ches-pun-toolbar {
      display: flex;
      align-items: center;
      flex-wrap: wrap;
    }
    .ches-pun-period {
      height: 30px;
      line-height: 28px;
      padding: 0 14px;
      margin-right: 8px;
      margin-bottom: 8px;
      background: #161d29;
      border: 1px solid #232c3a;
      color: #aab4c5;
      font-size: 12px;
      border-radius: 8px;
      cursor: pointer;
      user-select: none;
    }
    .ches-pun-period:hover {
      background: #1e2736;
      color: #f5f7fb;
    }
    .ches-pun-period.active {
      background: #22304a;
      color: #f5f7fb;
      font-weight: 600;
      border-color: #3b82f6;
    }
    .ches-pun-search {
      margin-left: auto;
    }
    .ches-pun-main {
      display: flex;
      align-items: stretch;
    }
    .ches-pun-main > * + * {
      margin-left: 16px;
    }
    .ches-pun-types {
      width: 180px;
      flex-shrink: 0;
      background: #121824;
      border: 1px solid #232c3a;
      border-radius: 10px;
      padding: 10px;
    }
    .ches-pun-type {
      display: flex;
      align-items: center;
      justify-content: space-between;
      height: 32px;
      padding: 0 10px;
      border-radius: 7px;
      cursor: pointer;
      user-select: none;
    }
    .ches-pun-type:hover {
      background: #1a2332;
    }
    .ches-pun-type.active {
      background: #22304a;
    }
    .ches-pun-type-label {
      font-size: 13px;
      color: #93a0b3;
    }
    .ches-pun-type.active .ches-pun-type-label {
      color: #f5f7fb;
      font-weight: 600;
    }
    .ches-pun-type-count {
      font-size: 12px;
      font-weight: 700;
      color: #5d6879;
      min-width: 24px;
      text-align: right;
      margin-left: 8px;
    }
    .ches-pun-type.active .ches-pun-type-count {
      color: #3b82f6;
    }
    .ches-pun-menu {
      flex: 1;
      min-width: 0;
      background: #121824;
      border: 1px solid #232c3a;
      border-radius: 10px;
      padding: 14px;
    }
    .ches-pun-empty {
      color: #5d6879;
      font-size: 12px;
      line-height: 1.5;
      text-align: center;
      padding: 32px 0;
    }
    .ches-pun-item {
      padding: 10px 12px;
      border-bottom: 1px solid #1b2431;
    }
    .ches-pun-item:last-child {
      border-bottom: none;
    }
    .ches-pun-item-head {
      display: flex;
      align-items: center;
      justify-content: space-between;
      margin-bottom: 4px;
    }
    .ches-pun-item-date {
      font-size: 12px;
      color: #5d6879;
    }
    .ches-pun-item-type {
      font-size: 11px;
      font-weight: 700;
      text-transform: uppercase;
      letter-spacing: .5px;
      padding: 2px 8px;
      border-radius: 6px;
      background: #22304a;
      color: #93a0b3;
    }
    .ches-pun-item-type.ban, .ches-pun-item-type.sban { background: #3a1e2c; color: #ff6b8c; }
    .ches-pun-item-type.gunban { background: #3a2a1e; color: #ffb36b; }
    .ches-pun-item-type.jail { background: #222e3a; color: #6ba9ff; }
    .ches-pun-item-type.kick { background: #2a2a3a; color: #b39bff; }
    .ches-pun-item-type.mute, .ches-pun-item-type.vmute, .ches-pun-item-type.rmute { background: #1e2c3a; color: #6bffd6; }
    .ches-pun-item-type.warn { background: #3a341e; color: #ffd76b; }
    .ches-pun-item-player {
      font-size: 13px;
      color: #e6ebf4;
      margin-bottom: 2px;
    }
    .ches-pun-item-reason,
    .ches-pun-item-duration {
      font-size: 12px;
      color: #7d8aa0;
      line-height: 1.45;
    }

    /* ---------- Вкладка PM логи ---------- */
    .ches-pml {
      display: flex;
      flex-direction: column;
      max-width: 760px;
    }
    .ches-pml > * + * {
      margin-top: 14px;
    }
    .ches-pml-toolbar {
      display: flex;
      align-items: center;
    }
    .ches-pml-search {
      flex: 1;
    }
    .ches-pml-clear {
      height: 40px;
      line-height: 38px;
      padding: 0 18px;
      margin-left: 12px;
      background: #161d29;
      border: 1px solid #232c3a;
      color: #aab4c5;
      font-size: 12px;
      border-radius: 8px;
      cursor: pointer;
      user-select: none;
    }
    .ches-pml-clear:hover {
      background: #3a1e2c;
      color: #ff6b8c;
      border-color: #ff6b8c;
    }
    .ches-pml-log {
      min-height: 300px;
      background: #121824;
      border: 1px solid #232c3a;
      border-radius: 10px;
      padding: 14px;
      overflow-y: auto;
    }
    .ches-pml-empty {
      color: #5d6879;
      font-size: 12px;
      line-height: 1.5;
      text-align: center;
      padding: 32px 0;
    }
    .ches-pml-item {
      padding: 10px 12px;
      border-bottom: 1px solid #1b2431;
    }
    .ches-pml-item:last-child {
      border-bottom: none;
    }
    .ches-pml-item-head {
      display: flex;
      align-items: center;
      justify-content: space-between;
      margin-bottom: 3px;
    }
    .ches-pml-item-date {
      font-size: 11px;
      color: #5d6879;
    }
    .ches-pml-item-nick {
      font-size: 12px;
      font-weight: 600;
      color: #6ba9ff;
    }
    .ches-pml-item-message {
      font-size: 13px;
      color: #e6ebf4;
      line-height: 1.45;
      word-break: break-word;
    }

    /* ---------- Вкладка Норма ---------- */
    .ches-norm {
      display: flex;
      flex-direction: column;
      max-width: 760px;
    }
    .ches-norm > * + * {
      margin-top: 14px;
    }
    .ches-norm-toolbar {
      display: flex;
      align-items: center;
    }
    .ches-norm-btn {
      height: 36px;
      line-height: 34px;
      padding: 0 18px;
      margin-right: 10px;
      background: #161d29;
      border: 1px solid #232c3a;
      color: #aab4c5;
      font-size: 12px;
      border-radius: 8px;
      cursor: pointer;
      user-select: none;
    }
    .ches-norm-btn:hover {
      background: #1e2736;
      color: #f5f7fb;
    }
    .ches-norm-btn.edit {
      background: #22304a;
      border-color: #3b82f6;
      color: #f5f7fb;
      font-weight: 600;
    }
    .ches-norm-btn.edit:hover {
      background: #2a3c5c;
    }
    .ches-norm-btn.clear:hover {
      background: #3a1e2c;
      color: #ff6b8c;
      border-color: #ff6b8c;
    }
    .ches-norm-panel {
      background: #121824;
      border: 1px solid #232c3a;
      border-radius: 10px;
      overflow: hidden;
    }
    .ches-norm-head {
      display: flex;
      align-items: center;
      background: #161d29;
      border-bottom: 1px solid #232c3a;
      padding: 10px 14px;
    }
    .ches-norm-head .ches-norm-cell {
      color: #7c8899;
      font-size: 11px;
      font-weight: 700;
      text-transform: uppercase;
      letter-spacing: .4px;
    }
    .ches-norm-body {
      min-height: 200px;
      padding: 10px 14px;
    }
    .ches-norm-row {
      background: transparent;
      border-bottom: 1px solid #1b2431;
      cursor: pointer;
    }
    .ches-norm-row:hover {
      background: #1a2332;
    }
    .ches-norm-row.selected {
      background: #22304a;
    }
    .ches-norm-row:last-child {
      border-bottom: none;
    }
    .ches-norm-input {
      width: 90px;
      height: 26px;
      padding: 0 8px;
      background: #161d29;
      border: 1px solid #232c3a;
      border-radius: 6px;
      color: #f5f7fb;
      font-size: 13px;
      font-family: inherit;
      outline: none;
    }
    .ches-norm-input:focus {
      border-color: #3b82f6;
    }
    .ches-norm-edit .ches-norm-btn {
      height: 26px;
      line-height: 24px;
      padding: 0 12px;
      margin: 0;
      font-size: 12px;
    }
    .ches-norm-cell {
      font-size: 13px;
      color: #aab4c5;
      overflow: hidden;
      text-overflow: ellipsis;
      white-space: nowrap;
    }
    .ches-norm-date {
      width: 200px;
      flex-shrink: 0;
    }
    .ches-norm-pm {
      width: 120px;
      flex-shrink: 0;
    }
    .ches-norm-norm {
      width: 120px;
      flex-shrink: 0;
    }
    .ches-norm-status {
      flex: 1;
      min-width: 0;
    }
    .ches-norm-status.ok {
      color: #2ec06e;
    }
    .ches-norm-status.fail {
      color: #ff6b8c;
    }
    .ches-norm-status.off {
      color: #f6a623;
    }
    .ches-norm-empty {
      color: #5d6879;
      font-size: 12px;
      line-height: 1.5;
      text-align: center;
      padding: 32px 0;
    }

    /* ---------- Вкладка Отгулы ---------- */
    .ches-days {
      display: flex;
      flex-direction: column;
      max-width: 640px;
    }
    .ches-days > * + * {
      margin-top: 14px;
    }
    .ches-days-toolbar {
      display: flex;
      align-items: center;
      flex-wrap: wrap;
    }
    .ches-days-toolbar > * + * {
      margin-left: 10px;
    }
    .ches-days-btn {
      height: 36px;
      line-height: 34px;
      padding: 0 18px;
      background: #161d29;
      border: 1px solid #232c3a;
      color: #aab4c5;
      font-size: 12px;
      border-radius: 8px;
      cursor: pointer;
      user-select: none;
    }
    .ches-days-btn:hover {
      background: #1e2736;
      color: #f5f7fb;
    }
    .ches-days-btn.green {
      background: #27ae60;
      border-color: #27ae60;
      color: #fff;
      font-weight: 600;
    }
    .ches-days-btn.green:hover {
      background: #2ec06e;
    }
    .ches-days-btn.red {
      background: #c0392b;
      border-color: #c0392b;
      color: #fff;
      font-weight: 600;
    }
    .ches-days-btn.red:hover {
      background: #d14435;
    }
    .ches-days-panel {
      background: #121824;
      border: 1px solid #232c3a;
      border-radius: 10px;
      padding: 14px;
      display: flex;
      flex-direction: column;
    }
    .ches-days-panel > * + * {
      margin-top: 10px;
    }
    .ches-days-pane-title {
      font-size: 13px;
      font-weight: 700;
      color: #f5f7fb;
      letter-spacing: .3px;
    }
    .ches-days-list {
      background: #121824;
      border: 1px solid #232c3a;
      border-radius: 10px;
      overflow: hidden;
    }
    .ches-days-list-head {
      display: flex;
      align-items: center;
      background: #161d29;
      border-bottom: 1px solid #232c3a;
      padding: 10px 14px;
    }
    .ches-days-list-head .ches-days-list-cell {
      color: #7c8899;
      font-size: 11px;
      font-weight: 700;
      text-transform: uppercase;
      letter-spacing: .4px;
    }
    .ches-days-list-body {
      min-height: 120px;
      padding: 10px 14px;
    }
    .ches-days-list-cell {
      font-size: 13px;
      color: #aab4c5;
      overflow: hidden;
      text-overflow: ellipsis;
      white-space: nowrap;
    }
    .ches-days-date {
      width: 200px;
      flex-shrink: 0;
    }
    .ches-days-forum {
      flex: 1;
      min-width: 0;
    }
    .ches-days-status {
      font-size: 12px;
      font-weight: 600;
      margin-top: 2px;
    }
    .ches-days-status.ok {
      color: #2ec06e;
    }
    .ches-days-status.fail {
      color: #ff6b8c;
    }
    .ches-days-empty {
      color: #5d6879;
      font-size: 12px;
      line-height: 1.5;
      text-align: center;
      padding: 24px 0;
    }
    .ches-days-list-row {
      display: flex;
      align-items: center;
      gap: 12px;
      padding: 8px 2px;
      border-bottom: 1px solid #1b2431;
      cursor: pointer;
      font-family: "Open Sans", Arial, sans-serif;
    }
    .ches-days-list-row:hover {
      background: #1a2332;
    }
    .ches-days-list-row.selected {
      background: #22304a;
    }
    .ches-days-forum.ok {
      color: #2ec06e;
      font-weight: 600;
    }
    .ches-days-forum.no {
      color: #ff6b8c;
      font-weight: 600;
    }
    .ches-days-result {
      font-size: 14px;
      font-weight: 700;
      color: #f5f7fb;
      padding: 12px 14px;
      background: #121824;
      border: 1px solid #232c3a;
      border-radius: 10px;
    }

    /* ---------- Кастомный дропдаун ---------- */
    .ches-dropdown {
      position: relative;
      display: inline-block;
      font-family: "Open Sans", Arial, sans-serif;
      font-size: 13px;
      user-select: none;
    }
    .ches-dropdown-btn {
      display: flex;
      align-items: center;
      justify-content: space-between;
      width: 100%;
      height: 40px;
      padding: 0 12px;
      background: #2e303c;
      border: none;
      border-radius: 6px;
      color: #f5f7fb;
      font-family: "Open Sans", Arial, sans-serif;
      font-size: 13px;
      cursor: pointer;
      outline: none;
      box-sizing: border-box;
    }
    .ches-dropdown-btn .ches-dd-value {
      overflow: hidden;
      text-overflow: ellipsis;
      white-space: nowrap;
      min-width: 0;
      font-family: "Open Sans", Arial, sans-serif;
      font-size: 13px;
    }
    .ches-dropdown-btn .ches-dd-arrow {
      flex-shrink: 0;
      width: 0;
      height: 0;
      margin-left: 8px;
      border-left: 5px solid transparent;
      border-right: 5px solid transparent;
      border-top: 6px solid #f5f7fb;
    }
    .ches-dropdown.open .ches-dropdown-btn .ches-dd-arrow {
      border-top: none;
      border-bottom: 6px solid #f5f7fb;
    }
    .ches-dropdown-menu {
      position: absolute;
      top: 44px;
      left: 0;
      min-width: 100%;
      max-height: 240px;
      overflow-y: auto;
      background: #161d29;
      border: 1px solid #232c3a;
      border-radius: 8px;
      z-index: 50;
      display: none;
    }
    .ches-dropdown.open .ches-dropdown-menu {
      display: block;
    }
    .ches-dd-item {
      padding: 9px 12px;
      color: #aab4c5;
      font-size: 13px;
      cursor: pointer;
      white-space: nowrap;
    }
    .ches-dd-item:hover {
      background: #1e2736;
      color: #f5f7fb;
    }
    .ches-dd-item.sel {
      color: #f5f7fb;
      font-weight: 700;
    }

    /* ---------- Вкладка Бинды ---------- */
    .ches-binds {
      display: flex;
      flex-direction: column;
      max-width: 860px;
    }
    .ches-binds > * + * {
      margin-top: 14px;
    }
    .ches-binds-card {
      background: #121824;
      border: 1px solid #232c3a;
      border-radius: 10px;
      padding: 14px 16px;
      display: flex;
      flex-direction: column;
    }
    .ches-binds-card > * + * {
      margin-top: 14px;
    }
    .ches-binds-row {
      display: flex;
      align-items: center;
      flex-wrap: wrap;
    }
    .ches-binds-row > * {
      margin-right: 10px;
      margin-bottom: 6px;
    }
    .ches-binds-filter-label {
      font-size: 12px;
      color: #7c8899;
      margin-right: 10px;
      flex-shrink: 0;
    }
    .ches-binds-toolbar {
      display: flex;
      align-items: center;
      flex-wrap: wrap;
    }
    .ches-binds-toolbar > * {
      margin-right: 16px;
      margin-bottom: 8px;
    }
    .ches-binds-toolbar-grow {
      flex: 1;
      min-width: 8px;
      margin-right: 0;
    }
    .ches-binds-head-btns {
      display: flex;
      align-items: center;
      flex-shrink: 0;
    }
    .ches-binds-head-btns > * + * {
      margin-left: 8px;
    }
    .ches-binds-btn {
      height: 32px;
      line-height: 30px;
      padding: 0 14px;
      background: #161d29;
      border: 1px solid #232c3a;
      color: #aab4c5;
      font-size: 12px;
      border-radius: 7px;
      cursor: pointer;
      user-select: none;
      white-space: nowrap;
      flex-shrink: 0;
    }
    .ches-binds-btn:hover {
      background: #1e2736;
      color: #f5f7fb;
    }
    .ches-binds-btn.primary {
      background: #22304a;
      border-color: #3b82f6;
      color: #f5f7fb;
      font-weight: 600;
    }
    .ches-binds-btn.primary:hover {
      background: #2a3c5c;
    }
    .ches-binds-main {
      display: flex;
      flex-direction: column;
      align-items: stretch;
    }
    .ches-binds-main > * + * {
      margin-top: 14px;
    }
    .ches-binds-list {
      width: 100%;
      background: #121824;
      border: 1px solid #232c3a;
      border-radius: 10px;
      overflow: hidden;
      display: flex;
      flex-direction: column;
    }
    .ches-binds-list-head {
      display: flex;
      align-items: center;
      background: #161d29;
      border-bottom: 1px solid #232c3a;
      padding: 10px 14px;
    }
    .ches-binds-list-head .ches-binds-cell {
      color: #7c8899;
      font-size: 11px;
      font-weight: 700;
      text-transform: uppercase;
      letter-spacing: 0.3px;
    }
    .ches-binds-list-body {
      padding: 0;
      flex: 0 1 auto;
      display: flex;
      flex-direction: column;
      justify-content: flex-start;
      align-items: stretch;
      overflow-y: auto;
      overflow-x: hidden;
      max-height: 340px;
    }
    .ches-binds-cell {
      font-size: 12px;
      color: #aab4c5;
      overflow: hidden;
      text-overflow: ellipsis;
      white-space: nowrap;
      margin-right: 12px;
      box-sizing: border-box;
    }
    .ches-binds-cell:last-child {
      margin-right: 0;
    }
    .ches-binds-col-type { width: 92px; flex-shrink: 0; }
    .ches-binds-col-cat { width: 150px; flex-shrink: 0; }
    .ches-binds-col-name { flex: 1; min-width: 0; }
    .ches-binds-col-trigger { width: 110px; flex-shrink: 0; }
    .ches-binds-col-status { width: 100px; flex-shrink: 0; margin-right: 0; }
    .ches-binds-preview {
      width: 100%;
      background: #121824;
      border: 1px solid #232c3a;
      border-radius: 10px;
      padding: 14px 16px;
      display: flex;
      flex-direction: column;
    }
    .ches-binds-preview.empty {
      display: none;
    }
    .ches-binds-preview-title {
      font-size: 12px;
      color: #7c8899;
      font-weight: 700;
      text-transform: uppercase;
      letter-spacing: 0.3px;
    }
    .ches-binds-preview-title + * {
      margin-top: 10px;
    }
    .ches-binds-preview-body {
      min-height: 48px;
      background: #0c1119;
      border: 1px solid #1c2431;
      border-radius: 8px;
      padding: 12px;
      color: #5d6879;
      font-size: 12px;
      line-height: 1.5;
      display: flex;
      flex-direction: column;
      justify-content: center;
    }
    .ches-binds-preview-body > * + * {
      margin-top: 8px;
    }
    .ches-binds-empty {
      color: #5d6879;
      font-size: 12px;
      line-height: 1.5;
      text-align: center;
      padding: 16px 8px;
    }
    .ches-binds-list-body.has-rows {
      justify-content: flex-start;
      padding: 0;
    }
    .ches-binds-list-body .ches-binds-empty {
      padding: 24px 12px;
      text-align: center;
    }
    .ches-binds-item {
      display: flex;
      align-items: center;
      padding: 11px 14px;
      border-bottom: 1px solid #1b2330;
      cursor: pointer;
    }
    .ches-binds-item:hover {
      background: #16202d;
    }
    .ches-binds-item.sel {
      background: #1c2a3d;
    }
    .ches-binds-item:last-child {
      border-bottom: none;
    }
    .ches-binds-status-dot {
      width: 8px;
      height: 8px;
      border-radius: 50%;
      display: inline-block;
      margin-right: 8px;
      vertical-align: middle;
      background: #ff5b6b;
    }
    .ches-binds-status-dot.on {
      background: #3ddb7a;
    }
    .ches-binds-status-dot.catoff {
      background: #f6a623;
    }
    .ches-binds-preview-content {
      white-space: pre-wrap;
      word-break: break-word;
      color: #aab4c5;
    }
    .ches-binds-preview-name {
      font-size: 14px;
      font-weight: 700;
      color: #f5f7fb;
      word-break: break-word;
    }
    .ches-binds-preview-meta {
      margin-top: 10px;
      padding: 8px 10px;
      background: #0c1119;
      border: 1px solid #1c2431;
      border-radius: 6px;
      font-size: 11px;
      color: #7c8899;
      line-height: 1.7;
      white-space: pre-line;
    }
    .ches-binds-actions {
      display: flex;
      flex-wrap: wrap;
      margin-top: 14px;
    }
    .ches-binds-actions > * {
      margin-right: 8px;
      margin-bottom: 8px;
    }
    .ches-binds-hint {
      width: 100%;
      margin-right: 0;
      font-size: 11px;
      color: #ff9fb5;
      line-height: 1.4;
    }
    .ches-binds-cat-head {
      display: flex;
      align-items: baseline;
      flex-wrap: wrap;
    }
    .ches-binds-cat-head > * + * {
      margin-left: 10px;
    }
    .ches-binds-cat-title {
      font-size: 13px;
      font-weight: 600;
      color: #f5f7fb;
    }
    .ches-binds-cat-sub {
      font-size: 11px;
      color: #5d6879;
    }
    .ches-binds-cat-body {
      display: flex;
      flex-wrap: wrap;
    }
    .ches-binds-cat-body > * {
      margin-right: 8px;
      margin-bottom: 8px;
    }
    .ches-binds-cat-row {
      display: flex;
      align-items: center;
      padding: 6px 8px 6px 12px;
      background: #0c1119;
      border: 1px solid #232c3a;
      border-radius: 7px;
    }
    .ches-binds-cat-row > * + * {
      margin-left: 10px;
    }
    .ches-binds-cat-row.off .ches-binds-cat-name {
      color: #5d6879;
      text-decoration: line-through;
    }
    .ches-binds-cat-name {
      font-size: 12px;
      color: #aab4c5;
      max-width: 200px;
      overflow: hidden;
      text-overflow: ellipsis;
      white-space: nowrap;
    }
    .ches-binds-cat-del {
      width: 22px;
      height: 22px;
      line-height: 20px;
      text-align: center;
      font-size: 12px;
      color: #7c8899;
      border-radius: 5px;
      cursor: pointer;
      user-select: none;
      flex-shrink: 0;
    }
    .ches-binds-cat-del:hover {
      background: #33202a;
      color: #ff7d9c;
    }
    .ches-binds-cat-del.confirm {
      background: #33202a;
      color: #ff7d9c;
    }
    .ches-binds-cat-add {
      display: flex;
      align-items: center;
      flex-wrap: wrap;
    }
    .ches-binds-cat-add > * {
      margin-right: 10px;
      margin-bottom: 4px;
    }
    .ches-binds-dup {
      margin-top: 8px;
      padding: 8px;
      background: #0c1119;
      border: 1px solid #5c2f3d;
      border-radius: 7px;
    }
    .ches-binds-dup-trigger {
      font-size: 12px;
      font-weight: 700;
      color: #ff9fb5;
      margin-bottom: 4px;
    }
    .ches-binds-dup-item {
      font-size: 12px;
      color: #aab4c5;
      line-height: 1.6;
    }
    .ches-binds-btn.danger {
      background: #33202a;
      border-color: #5c2f3d;
      color: #ff7d9c;
    }
    .ches-binds-btn.danger:hover {
      background: #45283a;
      color: #ff9fb5;
    }
    .ches-binds-btn.warn {
      background: #2e2a1e;
      border-color: #5c4f2f;
      color: #ffd27d;
    }
    .ches-binds-btn.warn:hover {
      background: #443c26;
      color: #ffe0a0;
    }
    .ches-binds-editor {
      display: flex;
      flex-direction: column;
      max-width: 700px;
    }
    .ches-binds-editor > * + * {
      margin-top: 12px;
    }
    .ches-binds-editor-card {
      background: #121824;
      border: 1px solid #232c3a;
      border-radius: 10px;
      padding: 14px;
      display: flex;
      flex-direction: column;
    }
    .ches-binds-editor-card > * + * {
      margin-top: 12px;
    }
    .ches-binds-editor-title {
      font-size: 14px;
      font-weight: 700;
      color: #f5f7fb;
    }
    .ches-binds-field {
      display: flex;
      flex-direction: column;
    }
    .ches-binds-field > * + * {
      margin-top: 6px;
    }
    .ches-binds-field-label {
      font-size: 11px;
      font-weight: 700;
      text-transform: uppercase;
      letter-spacing: .3px;
      color: #7c8899;
    }
    .ches-binds-textarea {
      width: 100%;
      min-height: 90px;
      box-sizing: border-box;
      background: #0c1119;
      border: 1px solid #232c3a;
      border-radius: 7px;
      padding: 8px;
      color: #e6ebf4;
      font: 12px Roboto, "Open Sans", Consolas, monospace;
      line-height: 1.5;
      resize: vertical;
      outline: none;
    }
    .ches-binds-textarea:focus {
      border-color: #3b82f6;
    }
    .ches-binds-editor-actions {
      display: flex;
      align-items: center;
      gap: 8px;
    }
    .ches-binds-error {
      color: #ff7d9c;
      font-size: 12px;
      line-height: 1.5;
    }
    .ches-binds-hint {
      color: #5d6879;
      font-size: 12px;
    }
    .ches-binds-field-hint {
      color: #5d6879;
      font-size: 12px;
      margin-top: 4px;
      line-height: 1.4;
    }

    /* ---------- Вкладка Скрипты ---------- */
    .ches-scripts {
      display: flex;
      flex-direction: column;
      max-width: 700px;
    }
    .ches-scripts > * + * {
      margin-top: 12px;
    }
    .ches-scripts-toolbar {
      display: flex;
      align-items: center;
    }
    .ches-scripts-btn {
      height: 36px;
      line-height: 34px;
      padding: 0 20px;
      background: #161d29;
      border: 1px solid #232c3a;
      color: #aab4c5;
      font-size: 13px;
      border-radius: 7px;
      cursor: pointer;
      user-select: none;
      white-space: nowrap;
    }
    .ches-scripts-btn:hover {
      background: #1e2736;
      color: #f5f7fb;
    }
    .ches-scripts-btn.primary {
      background: #22304a;
      border-color: #3b82f6;
      color: #f5f7fb;
      font-weight: 600;
    }
    .ches-scripts-btn.primary:hover {
      background: #2a3c5c;
    }
    .ches-scripts-btn.install {
      height: 30px;
      line-height: 28px;
      padding: 0 14px;
      font-size: 12px;
      flex-shrink: 0;
    }
    .ches-scripts-list {
      display: flex;
      flex-direction: column;
    }
    .ches-scripts-list > * + * {
      margin-top: 8px;
    }
    .ches-scripts-item {
      display: flex;
      align-items: center;
      background: #121824;
      border: 1px solid #232c3a;
      border-radius: 10px;
      padding: 12px 14px;
    }
    .ches-scripts-item > * + * {
      margin-left: 12px;
    }
    .ches-scripts-name {
      flex: 1;
      min-width: 0;
      font-size: 14px;
      font-weight: 700;
      color: #f5f7fb;
      overflow: hidden;
      text-overflow: ellipsis;
      white-space: nowrap;
    }
    .ches-scripts-link {
      font-size: 12px;
      color: #3b82f6;
      text-decoration: underline;
      cursor: pointer;
      user-select: none;
      white-space: nowrap;
      overflow: hidden;
      text-overflow: ellipsis;
      max-width: 260px;
    }
    .ches-scripts-link:hover {
      color: #5f9cf7;
    }
    .ches-scripts-card {
      background: #121824;
      border: 1px solid #232c3a;
      border-radius: 10px;
      padding: 14px;
    }
    .ches-scripts-card > * + * {
      margin-top: 10px;
    }
    .ches-scripts-title {
      font-size: 14px;
      font-weight: 700;
      color: #f5f7fb;
    }
    .ches-scripts-desc {
      font-size: 12px;
      color: #5d6879;
      line-height: 1.4;
    }
    .ches-scripts-pathstatus {
      font-size: 12px;
      font-weight: 600;
    }
    .ches-scripts-pathstatus.ok {
      color: #2ec06e;
    }
    .ches-scripts-pathstatus.no {
      color: #ff6b8c;
    }
    .ches-scripts-info {
      flex: 1;
      min-width: 0;
    }
    .ches-scripts-info > * + * {
      margin-top: 3px;
    }
    .ches-scripts-meta {
      font-size: 12px;
      color: #5d6879;
      overflow: hidden;
      text-overflow: ellipsis;
      white-space: nowrap;
    }
    .ches-scripts-status {
      font-size: 12px;
      font-weight: 600;
    }
    .ches-scripts-status.ok {
      color: #2ec06e;
    }
    .ches-scripts-status.no {
      color: #ff6b8c;
    }
    .ches-scripts-btn.done {
      background: #16241d;
      border-color: #2ec06e;
      color: #2ec06e;
      cursor: default;
    }
    .ches-scripts-empty {
      color: #5d6879;
      font-size: 12px;
      text-align: center;
      padding: 20px 0;
    }


    .ches-scripts-actions {
      display: flex;
      align-items: center;
      flex-shrink: 0;
    }
    .ches-scripts-actions > * + * {
      margin-left: 8px;
    }
    .ches-scripts-btn.info {
      height: 30px;
      line-height: 28px;
      padding: 0 12px;
      font-size: 12px;
      flex-shrink: 0;
    }
    .ches-scripts-modal {
      position: fixed;
      left: 0;
      top: 0;
      right: 0;
      bottom: 0;
      z-index: 10000;
      display: block;
      background: rgba(0, 0, 0, .55);
    }
    .ches-scripts-modal.hidden {
      display: none !important;
    }
    .ches-scripts-modal-box {
      position: absolute;
      left: 50%;
      top: 50%;
      transform: translate(-50%, -50%);
      width: 400px;
      max-width: 90%;
      max-height: 78%;
      overflow-y: auto;
      background: #121824;
      border: 1px solid #232c3a;
      border-radius: 12px;
      padding: 18px 20px 28px;
      box-shadow: 0 12px 32px rgba(0, 0, 0, .45);
      box-sizing: border-box;
    }
    .ches-scripts-modal-box > * + * {
      margin-top: 12px;
    }
    .ches-scripts-modal-title {
      font-size: 16px;
      font-weight: 700;
      color: #f5f7fb;
      margin: 0;
    }
    .ches-scripts-modal-row {
      font-size: 13px;
      color: #aab4c5;
      line-height: 1.55;
    }
    .ches-scripts-modal-label {
      color: #7c8899;
      font-size: 11px;
      font-weight: 700;
      text-transform: uppercase;
      letter-spacing: .3px;
      margin-bottom: 4px;
    }
    .ches-scripts-modal-close {
      display: block;
      text-align: center;
      margin-top: 18px;
      margin-bottom: 8px;
    }


    .ches-reset-modal {
      position: fixed;
      inset: 0;
      z-index: 9999;
      display: flex;
      align-items: center;
      justify-content: center;
      background: rgba(0, 0, 0, .55);
    }
    .ches-reset-modal.hidden {
      display: none;
    }
    .ches-reset-box {
      width: min(360px, 90%);
      background: #121824;
      border: 1px solid #232c3a;
      border-radius: 12px;
      padding: 18px 20px;
      box-shadow: 0 12px 32px rgba(0, 0, 0, .5);
    }
    .ches-reset-box > * + * {
      margin-top: 10px;
    }
    .ches-reset-title {
      font-size: 16px;
      font-weight: 700;
      color: #f5f7fb;
    }
    .ches-reset-text {
      font-size: 13px;
      color: #aab4c5;
      line-height: 1.45;
      white-space: pre-wrap;
    }
    .ches-reset-actions {
      display: flex;
      margin-top: 14px;
    }
    .ches-reset-actions > * + * {
      margin-left: 10px;
    }
    .ches-reset-btn {
      flex: 1;
      height: 36px;
      line-height: 34px;
      text-align: center;
      border-radius: 8px;
      border: 1px solid #232c3a;
      background: #161d29;
      color: #aab4c5;
      font-size: 13px;
      font-weight: 600;
      cursor: pointer;
      user-select: none;
    }
    .ches-reset-btn:hover {
      background: #1e2736;
      color: #f5f7fb;
    }
    .ches-reset-btn.danger {
      background: #3a1a22;
      border-color: #ff6b8c;
      color: #ff8fa8;
    }
    .ches-reset-btn.danger:hover {
      background: #4a222c;
      color: #ffb0c0;
    }

    /* ---------- Вкладка Тестировщик ---------- */
    .ches-tester {
      display: flex;
      flex-direction: column;
      max-width: 700px;
    }
    .ches-tester > * + * {
      margin-top: 12px;
    }
    .ches-tester-desc {
      font-size: 13px;
      color: #7c8899;
      line-height: 1.5;
    }
    .ches-tester-card {
      background: #121824;
      border: 1px solid #232c3a;
      border-radius: 10px;
      padding: 14px;
      display: flex;
      flex-direction: column;
    }
    .ches-tester-card > * + * {
      margin-top: 12px;
    }
    .ches-tester-title {
      font-size: 12px;
      font-weight: 700;
      color: #7c8899;
      text-transform: uppercase;
      letter-spacing: .3px;
    }
    .ches-tester-status {
      font-size: 12px;
      font-weight: 600;
    }
    .ches-tester-status.ok {
      color: #2ec06e;
    }
    .ches-tester-status.off {
      color: #7c8899;
    }
    .ches-tester-info {
      min-height: 80px;
      background: #0c1119;
      border: 1px solid #1c2431;
      border-radius: 8px;
      padding: 10px;
      color: #aab4c5;
      font-size: 12px;
      line-height: 1.5;
    }
    .ches-tester-info.empty {
      color: #5d6879;
    }
    .ches-tester-toolbar {
      display: flex;
      align-items: center;
      flex-wrap: wrap;
    }
    .ches-tester-toolbar > * + * {
      margin-left: 8px;
    }
    .ches-tester-btn {
      height: 34px;
      line-height: 32px;
      padding: 0 16px;
      margin-bottom: 6px;
      background: #161d29;
      border: 1px solid #232c3a;
      color: #aab4c5;
      font-size: 12px;
      border-radius: 7px;
      cursor: pointer;
      user-select: none;
      white-space: nowrap;
    }
    .ches-tester-btn:hover {
      background: #1e2736;
      color: #f5f7fb;
    }
    .ches-tester-btn.primary {
      background: #22304a;
      border-color: #3b82f6;
      color: #f5f7fb;
      font-weight: 600;
    }
    .ches-tester-btn.primary:hover {
      background: #2a3c5c;
    }
    .ches-tester-btn.accent {
      background: #2a3c5c;
      border-color: #3b82f6;
      color: #f5f7fb;
      font-weight: 600;
    }
    .ches-tester-btn.accent:hover {
      background: #33486e;
    }
    .ches-tester-btn.disabled {
      opacity: .45;
      cursor: not-allowed;
      pointer-events: none;
    }
    .ches-tester-btn.confirm {
      background: #33202a;
      border-color: #5c2f3d;
      color: #ff7d9c;
    }
    .ches-tester-btn.confirm:hover {
      background: #45283a;
      color: #ff9fb5;
    }
    .ches-tester-foot {
      font-size: 11px;
      color: #5d6879;
    }

    /* ---------- Вкладка Обновления ---------- */
    .hidden {
      display: none !important;
    }
    .ches-updates {
      display: flex;
      flex-direction: column;
      max-width: 700px;
    }
    .ches-updates > * + * {
      margin-top: 12px;
    }
    .ches-updates-card {
      background: #121824;
      border: 1px solid #232c3a;
      border-radius: 10px;
      padding: 14px;
      display: flex;
      flex-direction: column;
    }
    .ches-updates-card > * + * {
      margin-top: 12px;
    }
    .ches-updates-title {
      font-size: 15px;
      font-weight: 700;
      color: #f5f7fb;
    }
    .ches-updates-desc {
      font-size: 12px;
      color: #7c8899;
      line-height: 1.5;
    }
    .ches-updates-toolbar {
      display: flex;
      align-items: center;
      flex-wrap: wrap;
    }
    .ches-updates-toolbar > * + * {
      margin-left: 8px;
    }
    .ches-updates-btn {
      height: 34px;
      line-height: 32px;
      padding: 0 16px;
      margin-bottom: 6px;
      background: #161d29;
      border: 1px solid #232c3a;
      color: #aab4c5;
      font-size: 12px;
      border-radius: 7px;
      cursor: pointer;
      user-select: none;
      white-space: nowrap;
    }
    .ches-updates-btn:hover {
      background: #1e2736;
      color: #f5f7fb;
    }
    .ches-updates-btn.primary {
      background: #22304a;
      border-color: #3b82f6;
      color: #f5f7fb;
      font-weight: 600;
    }
    .ches-updates-btn.primary:hover {
      background: #2a3c5c;
    }
    .ches-updates-btn.confirm {
      background: #33202a;
      border-color: #5c2f3d;
      color: #ff7d9c;
    }
    .ches-updates-btn.confirm:hover {
      background: #45283a;
      color: #ff9fb5;
    }

    /* ---------- Вкладка Уведомления ---------- */
    .ches-notif {
      display: flex;
      flex-direction: column;
      max-width: 700px;
    }
    .ches-notif > * + * {
      margin-top: 8px;
    }
    .ches-notif-head {
      display: flex;
      align-items: center;
      margin-bottom: 4px;
    }
    .ches-notif-head > * + * {
      margin-left: 10px;
    }
    .ches-notif-title {
      font-size: 13px;
      font-weight: 700;
      color: #f5f7fb;
    }
    .ches-notif-list {
      display: flex;
      flex-direction: column;
    }
    .ches-notif-list > * + * {
      margin-top: 8px;
    }
    .ches-notif-item {
      display: flex;
      align-items: flex-start;
      background: #121824;
      border: 1px solid #232c3a;
      border-radius: 10px;
      padding: 12px 14px;
    }
    .ches-notif-item > * + * {
      margin-left: 10px;
    }
    .ches-notif-dot {
      width: 8px;
      height: 8px;
      border-radius: 50%;
      flex-shrink: 0;
      margin-top: 5px;
    }
    .ches-notif-dot.info {
      background: #3b82f6;
    }
    .ches-notif-dot.update {
      background: #2ec06e;
    }
    .ches-notif-dot.alert {
      background: #e5484d;
    }
    .ches-notif-text {
      flex: 1;
      min-width: 0;
      font-size: 13px;
      color: #aab4c5;
      line-height: 1.5;
    }
    .ches-notif-time {
      font-size: 11px;
      color: #5d6879;
      white-space: nowrap;
      margin-top: 2px;
    }
    .ches-notif-empty {
      background: #121824;
      border: 1px solid #232c3a;
      border-radius: 10px;
      padding: 24px;
      text-align: center;
      color: #5d6879;
      font-size: 12px;
    }
    .ches-notif-btn {
      height: 30px;
      line-height: 28px;
      padding: 0 14px;
      background: #161d29;
      border: 1px solid #232c3a;
      color: #aab4c5;
      font-size: 12px;
      border-radius: 7px;
      cursor: pointer;
      user-select: none;
      white-space: nowrap;
    }
    .ches-notif-btn:hover {
      background: #1e2736;
      color: #f5f7fb;
    }
    .ches-notif-item.read {
      opacity: .55;
    }

    /* ---------- Вкладка Помощь ---------- */
    .ches-help {
      display: flex;
      flex-direction: column;
      max-width: 700px;
    }
    .ches-help > * + * {
      margin-top: 12px;
    }
    .ches-help-window {
      background: #121824;
      border: 1px solid #232c3a;
      border-radius: 10px;
      overflow: hidden;
      display: flex;
      flex-direction: column;
    }
    .ches-help-window-title {
      display: flex;
      align-items: center;
      background: #161d29;
      border-bottom: 1px solid #232c3a;
      padding: 10px 14px;
    }
    .ches-help-window-title > * + * {
      margin-left: 10px;
    }
    .ches-help-window-title .ches-help-title-text {
      flex: 1;
      font-size: 12px;
      font-weight: 700;
      color: #7c8899;
      text-transform: uppercase;
      letter-spacing: .3px;
    }
    .ches-help-body {
      padding: 12px 14px;
      background: #0c1119;
      color: #aab4c5;
      font-size: 12px;
      line-height: 1.6;
      white-space: pre-wrap;
      overflow-y: auto;
      max-height: 220px;
    }
    .ches-help-btn {
      height: 30px;
      line-height: 28px;
      padding: 0 14px;
      background: #161d29;
      border: 1px solid #232c3a;
      color: #aab4c5;
      font-size: 12px;
      border-radius: 7px;
      cursor: pointer;
      user-select: none;
      white-space: nowrap;
    }
    .ches-help-btn:hover {
      background: #1e2736;
      color: #f5f7fb;
    }
    .ches-help-btn.danger {
      color: #ff6b8c;
      border-color: #6b2737;
    }
    .ches-help-btn.danger:hover {
      background: #3a1e2c;
      color: #ff6b8c;
    }
    .ches-help-errors {
      background: #121824;
      border: 1px solid #232c3a;
      border-radius: 10px;
      overflow: hidden;
      display: flex;
      flex-direction: column;
    }
    .ches-help-errors-title {
      display: flex;
      align-items: center;
      background: #161d29;
      border-bottom: 1px solid #232c3a;
      padding: 10px 14px;
    }
    .ches-help-errors-title > * + * {
      margin-left: 10px;
    }
    .ches-help-errors-title .ches-help-title-text {
      flex: 1;
      font-size: 12px;
      font-weight: 700;
      color: #7c8899;
      text-transform: uppercase;
      letter-spacing: .3px;
    }
    .ches-help-errors-body {
      padding: 10px 14px;
      min-height: 80px;
      max-height: 180px;
      overflow-y: auto;
      background: #0c1119;
      display: flex;
      flex-direction: column;
    }
    .ches-help-errors-body > * + * {
      margin-top: 8px;
    }
    .ches-help-err-item {
      font-size: 12px;
      color: #e5484d;
      line-height: 1.4;
    }
    .ches-help-err-item .ches-help-err-time {
      color: #5d6879;
      margin-right: 6px;
    }
    .ches-help-empty {
      color: #5d6879;
      font-size: 12px;
      text-align: center;
      padding: 12px 0;
    }

    /* ---------- Вкладка Cloud ---------- */
    .ches-cloud {
      display: flex;
      flex-direction: column;
      max-width: 700px;
    }
    .ches-cloud > * + * {
      margin-top: 12px;
    }
    .ches-cloud-card {
      background: #121824;
      border: 1px solid #232c3a;
      border-radius: 10px;
      padding: 14px;
      display: flex;
      flex-direction: column;
    }
    .ches-cloud-card > * + * {
      margin-top: 12px;
    }
    .ches-cloud-label {
      font-size: 12px;
      color: #7c8899;
    }
    .ches-cloud-nick {
      font-size: 15px;
      font-weight: 700;
      color: #f5f7fb;
    }
    .ches-cloud-nick.empty {
      color: #5d6879;
      font-weight: 400;
    }
    .ches-cloud-status {
      display: flex;
      align-items: center;
      font-size: 13px;
      font-weight: 600;
    }
    .ches-cloud-status .ches-cloud-dot {
      width: 10px;
      height: 10px;
      border-radius: 50%;
      flex-shrink: 0;
      margin-right: 8px;
    }
    .ches-cloud-status.ok {
      color: #2ec06e;
    }
    .ches-cloud-status.ok .ches-cloud-dot {
      background: #2ec06e;
    }
    .ches-cloud-status.pending {
      color: #f0b429;
    }
    .ches-cloud-status.pending .ches-cloud-dot {
      background: #f0b429;
    }
    .ches-cloud-status.blocked {
      color: #e5484d;
    }
    .ches-cloud-status.blocked .ches-cloud-dot {
      background: #e5484d;
    }
    .ches-cloud-toolbar {
      display: flex;
      align-items: center;
      flex-wrap: wrap;
    }
    .ches-cloud-toolbar > * + * {
      margin-left: 8px;
    }
    .ches-cloud-btn {
      height: 34px;
      line-height: 32px;
      padding: 0 16px;
      margin-bottom: 6px;
      background: #161d29;
      border: 1px solid #232c3a;
      color: #aab4c5;
      font-size: 12px;
      border-radius: 7px;
      cursor: pointer;
      user-select: none;
      white-space: nowrap;
    }
    .ches-cloud-btn:hover {
      background: #1e2736;
      color: #f5f7fb;
    }
    .ches-cloud-btn.primary {
      background: #22304a;
      border-color: #3b82f6;
      color: #f5f7fb;
      font-weight: 600;
    }
    .ches-cloud-btn.primary:hover {
      background: #2a3c5c;
    }
    .ches-cloud-nickrow {
      display: flex;
      align-items: center;
    }
    .ches-cloud-nickrow > * + * {
      margin-left: 8px;
    }
    .ches-cloud-input {
      flex: 1;
      height: 32px;
      min-width: 0;
      background: #0c1119;
      border: 1px solid #232c3a;
      border-radius: 7px;
      color: #f5f7fb;
      font-size: 13px;
      padding: 0 10px;
      box-sizing: border-box;
      outline: none;
    }
    .ches-cloud-input:focus {
      border-color: #3b82f6;
    }
    .ches-cloud-message {
      font-size: 13px;
      font-weight: 600;
    }
    .ches-cloud-message.ok {
      color: #2ec06e;
    }
    .ches-cloud-message.pending {
      color: #f0b429;
    }
    .ches-cloud-message.blocked {
      color: #e5484d;
    }
    .ches-cloud-last {
      font-size: 11px;
      color: #5d6879;
    }

    /* ---------- Вкладка Диагностика ---------- */
    .ches-diag {
      display: flex;
      flex-direction: column;
      max-width: 700px;
    }
    .ches-diag > * + * {
      margin-top: 12px;
    }
    .ches-diag-card {
      background: #121824;
      border: 1px solid #232c3a;
      border-radius: 10px;
      padding: 14px;
      display: flex;
      flex-direction: column;
    }
    .ches-diag-card > * + * {
      margin-top: 12px;
    }
    .ches-diag-health {
      display: flex;
      align-items: center;
      font-size: 14px;
      font-weight: 700;
      color: #f5f7fb;
    }
    .ches-diag-health .ches-diag-dot {
      width: 10px;
      height: 10px;
      border-radius: 50%;
      flex-shrink: 0;
      margin-right: 8px;
    }
    .ches-diag-health.ok .ches-diag-dot {
      background: #2ec06e;
    }
    .ches-diag-health.warn .ches-diag-dot {
      background: #f0b429;
    }
    .ches-diag-health.critical .ches-diag-dot {
      background: #e5484d;
    }
    .ches-diag-hint {
      font-size: 11px;
      color: #5d6879;
    }
    .ches-diag-toolbar {
      display: flex;
      align-items: center;
    }
    .ches-diag-btn {
      height: 34px;
      line-height: 32px;
      padding: 0 16px;
      background: #161d29;
      border: 1px solid #232c3a;
      color: #aab4c5;
      font-size: 12px;
      border-radius: 7px;
      cursor: pointer;
      user-select: none;
      white-space: nowrap;
    }
    .ches-diag-btn:hover {
      background: #1e2736;
      color: #f5f7fb;
    }
    .ches-diag-btn.primary {
      background: #22304a;
      border-color: #3b82f6;
      color: #f5f7fb;
      font-weight: 600;
    }
    .ches-diag-btn.primary:hover {
      background: #2a3c5c;
    }
    .ches-diag-text {
      background: #0c1119;
      border: 1px solid #1c2431;
      border-radius: 8px;
      padding: 12px 14px;
      color: #aab4c5;
      font-size: 12px;
      line-height: 1.6;
      white-space: pre-wrap;
      overflow-y: auto;
      min-height: 200px;
      max-height: 300px;
    }
  `;

  /* ====================== ВСПОМОГАТЕЛЬНОЕ ====================== */
  function el(tag, cls, text) {
    var n = document.createElement(tag);
    if (cls) n.className = cls;
    if (text != null) n.textContent = text;
    return n;
  }

  function getViewTitle(id) {
    var lists = [mainNav, bottomNav, topList];
    for (var i = 0; i < lists.length; i++) {
      for (var j = 0; j < lists[i].length; j++) {
        if (lists[i][j].id === id) return lists[i][j].label;
      }
    }
    return id;
  }

  function clearBody() {
    if (contentBodyEl) contentBodyEl.innerHTML = '';
  }

  /* ====================== UI-ЭЛЕМЕНТЫ ====================== */
  function makeOnishiInput(opts) {
    opts = opts || {};
    var box = el('div', 'ches-inputbox');
    if (opts.width) box.style.width = opts.width;

    var input = document.createElement('input');
    input.className = 'ches-input';
    input.type = opts.type || 'text';
    input.placeholder = ' ';
    if (opts.value != null) input.value = opts.value;
    if (opts.maxLength) input.maxLength = opts.maxLength;
    if (opts.inputMode) input.inputMode = opts.inputMode;

    var ph = el('div', 'ches-input__placeholder', opts.placeholder || '');
    box.appendChild(input);
    box.appendChild(ph);

    function syncPh() {
      if ((input.value || '').length > 0) {
        ph.style.opacity = '0';
        ph.style.visibility = 'hidden';
      } else {
        ph.style.opacity = '';
        ph.style.visibility = '';
      }
    }
    input.addEventListener('input', syncPh);
    input.addEventListener('focus', syncPh);
    input.addEventListener('blur', syncPh);
    syncPh();

    return { box: box, input: input };
  }

  function makeToggle(active, extraClass) {
    var btn = el('button', 'ches-toggle' + (active ? ' on' : '') + (extraClass ? ' ' + extraClass : ''));
    btn.type = 'button';
    var knob = el('span', 'ches-toggle-knob');
    btn.appendChild(knob);
    btn.addEventListener('click', function () {
      var on = btn.classList.contains('on');
      if (on) btn.classList.remove('on');
      else btn.classList.add('on');
    });
    return btn;
  }

  function makeToggleRow(label, hint, active, extraClass) {
    var row = el('div', 'ches-toggle-row');
    var text = el('div', 'ches-toggle-text');
    text.appendChild(el('div', 'ches-toggle-label', label));
    if (hint) text.appendChild(el('div', 'ches-toggle-hint', hint));
    row.appendChild(text);
    row.appendChild(makeToggle(!!active, extraClass));
    return row;
  }

  function notify(message) {
    notificationsCount++;
    updateNotifBadge();
  }

  function updateBetaBadge(enabled) {
    if (enabled == null) enabled = !!testerState.enabled;
    if (!betaBadgeEl) return;
    if (enabled) betaBadgeEl.classList.remove('hidden');
    else betaBadgeEl.classList.add('hidden');
  }

  function updateNotifBadge() {
    var btn = topButtons['Notifications'];
    if (!btn) return;
    if (notificationsCount > 0) btn.classList.add('has-unread');
    else btn.classList.remove('has-unread');
  }

  function makeDropdown(options, opts) {
    opts = opts || {};
    var selIndex = opts.selected != null ? opts.selected : 0;

    var box = el('div', 'ches-dropdown');
    if (opts.width) box.style.width = opts.width;

    var btn = el('div', 'ches-dropdown-btn');
    var valueEl = el('span', 'ches-dd-value');
    var arrowEl = el('span', 'ches-dd-arrow');
    btn.appendChild(valueEl);
    btn.appendChild(arrowEl);
    box.appendChild(btn);

    var menu = el('div', 'ches-dropdown-menu');
    box.appendChild(menu);

    function renderList() {
      menu.innerHTML = '';
      options.forEach(function (item, i) {
        var label = typeof item === 'object' ? item.label : item;
        var opt = el('div', 'ches-dd-item' + (i === selIndex ? ' sel' : ''), label);
        opt.addEventListener('click', function () {
          selIndex = i;
          renderList();
          renderValue();
          close();
          if (opts.onSelect) opts.onSelect(i, item);
        });
        menu.appendChild(opt);
      });
    }

    function renderValue() {
      var item = options[selIndex];
      valueEl.textContent = typeof item === 'object' ? item.label : item;
    }

    function close() {
      box.classList.remove('open');
    }
    function toggle() {
      if (box.classList.contains('open')) close();
      else box.classList.add('open');
    }

    btn.addEventListener('click', function (e) {
      e.stopPropagation();
      toggle();
    });
    document.addEventListener('click', function () {
      close();
    });

    renderList();
    renderValue();
    return { box: box, select: function (i) { selIndex = i; renderList(); renderValue(); }, getIndex: function () { return selIndex; } };
  }

  /* ====================== НАСТРОЙКИ ====================== */
  function pad2(v) {
    v = String(v || '').replace(/\D/g, '');
    return v.length > 1 ? v.slice(0, 2) : '0' + v;
  }

  function restrictDigits(input, maxLen) {
    input.addEventListener('input', function () {
      var v = input.value.replace(/\D/g, '').slice(0, maxLen);
      if (input.value !== v) input.value = v;
    });
  }

  function makeSettingsBlock(title) {
    var block = el('div', 'ches-settings-block');
    block.appendChild(el('div', 'ches-settings-block-title', title));
    return block;
  }

  function makeSettingsField(labelText) {
    var field = el('div', 'ches-settings-field');
    if (labelText) field.appendChild(el('div', 'ches-settings-label', labelText));
    return field;
  }

  /* ====================== ОТОБРАЖЕНИЕ КОНТЕНТА ====================== */
  function renderSettings() {
    clearBody();
    settingsRefs = {};

    var form = el('div', 'ches-settings');

    /* Блок 1 — ник (только просмотр) и норма */
    var block1 = makeSettingsBlock('Пользователь');
    var row1 = el('div', 'ches-settings-row');

    var nickField = makeSettingsField('Ник');
    var nickVal = el('div', 'ches-settings-nickval' + (settings.nick ? '' : ' empty'),
      settings.nick ? settings.nick : 'Не указан (Cloud)');
    settingsRefs.nickDisplay = nickVal;
    nickField.appendChild(nickVal);
    row1.appendChild(nickField);

    var normField = makeSettingsField('Норма');
    var normIn = makeOnishiInput({ width: '220px', value: settings.norm, placeholder: '250' });
    settingsRefs.norm = normIn.input;
    normField.appendChild(normIn.box);
    row1.appendChild(normField);

    block1.appendChild(row1);
    form.appendChild(block1);

    /* Блок 2 — автосброс нормы */
    var block2 = makeSettingsBlock('Автосброс нормы');
    var toggleRow = makeToggleRow(
      'Включить автосброс',
      'Норма будет сбрасываться каждый день в заданное время',
      settings.autoResetEnabled,
      'bind'
    );
    settingsRefs.autoReset = toggleRow.querySelector('.ches-toggle');
    block2.appendChild(toggleRow);

    var timeRow = el('div', 'ches-settings-row');
    timeRow.appendChild(el('div', 'ches-settings-label', 'Время сброса'));
    var hIn = makeOnishiInput({ width: '76px', value: settings.resetTime.hours, placeholder: '00' });
    var mIn = makeOnishiInput({ width: '76px', value: settings.resetTime.minutes, placeholder: '00' });
    restrictDigits(hIn.input, 2);
    restrictDigits(mIn.input, 2);
    settingsRefs.hours = hIn.input;
    settingsRefs.minutes = mIn.input;
    timeRow.appendChild(hIn.box);
    timeRow.appendChild(el('div', 'ches-settings-time-sep', ':'));
    timeRow.appendChild(mIn.box);
    block2.appendChild(timeRow);
    form.appendChild(block2);

    /* Блок — автозапуск Windows */
    var blockWin = makeSettingsBlock('Автозапуск');
    var winToggle = makeToggleRow(
      'Запуск вместе с Windows',
      'ChesNova будет стартовать при входе в систему',
      settings.startWithWindows,
      'bind'
    );
    settingsRefs.startWithWindows = winToggle.querySelector('.ches-toggle');
    blockWin.appendChild(winToggle);
    form.appendChild(blockWin);

    /* Блок — пути (если автоматически найден неверный) */
    var blockPaths = makeSettingsBlock('Пути');
    blockPaths.appendChild(el('div', 'ches-settings-info',
      'Если путь найден автоматически неверно (на ПК может быть несколько копий игры) — укажите верный вручную.'));
    var rowCl = el('div', 'ches-settings-row');
    var clField = makeSettingsField('Chatlog');
    var clIn = makeOnishiInput({ value: settings.chatlogPath, placeholder: 'Документы\\RADMIR CRMP User Files\\SAMP\\chatlog.txt' });
    clIn.box.style.width = '100%';
    settingsRefs.chatlogPath = clIn.input;
    clField.appendChild(clIn.box);
    rowCl.appendChild(clField);
    blockPaths.appendChild(rowCl);
    var rowGp = el('div', 'ches-settings-row');
    var gpField = makeSettingsField('Корень игры');
    var gpIn = makeOnishiInput({ value: settings.gamePath, placeholder: 'C:\\Games\\Radmir CRMP' });
    gpIn.box.style.width = '100%';
    settingsRefs.gamePath = gpIn.input;
    gpField.appendChild(gpIn.box);
    rowGp.appendChild(gpField);
    blockPaths.appendChild(rowGp);
    form.appendChild(blockPaths);

    /* Блок 3 — бинды */
    var block3 = makeSettingsBlock('Бинды');
    var binds = [
      { ref: 'panel', value: settings.binds.panel, info: 'Открыть/закрыть панель' },
      { ref: 'normReset', value: settings.binds.normReset, info: 'Сброс нормы' },
      { ref: 'hideHud', value: settings.binds.hideHud, info: 'Скрыть HUD' }
    ];
    binds.forEach(function (item) {
      var row = el('div', 'ches-settings-row');
      var bindIn = makeOnishiInput({ width: '140px', value: item.value, placeholder: 'F10' });
      settingsRefs[item.ref] = bindIn.input;
      var bindTgl = makeToggle(!!settings.bindEnabled[item.ref], 'bind');
      settingsRefs[item.ref + 'Toggle'] = bindTgl;
      row.appendChild(bindIn.box);
      row.appendChild(el('div', 'ches-settings-info', item.info));
      row.appendChild(bindTgl);
      block3.appendChild(row);
    });
    form.appendChild(block3);

    /* Кнопка сохранения */
    var saveBtn = el('div', 'ches-settings-save', '\u0421\u043e\u0445\u0440\u0430\u043d\u0438\u0442\u044c');
    saveBtn.addEventListener('click', function () {
      saveSettings();
      saveBtn.classList.add('saved');
      setTimeout(function () { saveBtn.classList.remove('saved'); }, 1200);
    });
    form.appendChild(saveBtn);

    contentBodyEl.appendChild(form);
  }

  function saveSettings() {
    settings.norm = settingsRefs.norm.value.trim();
    settings.autoResetEnabled = settingsRefs.autoReset.classList.contains('on');
    settings.startWithWindows = settingsRefs.startWithWindows
      ? settingsRefs.startWithWindows.classList.contains('on')
      : false;
    settings.resetTime.hours = pad2(settingsRefs.hours.value);
    settings.resetTime.minutes = pad2(settingsRefs.minutes.value);
    settings.binds.panel = settingsRefs.panel.value.trim() || 'F10';
    settings.binds.normReset = settingsRefs.normReset.value.trim() || 'F9';
    settings.binds.hideHud = settingsRefs.hideHud.value.trim() || 'F7';
    settings.bindEnabled.panel = settingsRefs.panelToggle.classList.contains('on');
    settings.bindEnabled.normReset = settingsRefs.normResetToggle.classList.contains('on');
    settings.bindEnabled.hideHud = settingsRefs.hideHudToggle.classList.contains('on');
    saveSettingsToBridge();
    saveSettingsPaths();
  }

  /* Сохранение путей в AHK (GET /settings/chatlog, /scripts/path) */
  function saveSettingsPaths() {
    var clp = settingsRefs.chatlogPath ? settingsRefs.chatlogPath.value.trim() : '';
    if (clp) {
      var x1 = new XMLHttpRequest();
      x1.open('GET', SETTINGS_CHATLOG_URL + '?path=' + encodeURIComponent(clp), true);
      x1.timeout = 1500;
      x1.send();
    }
    var gp = settingsRefs.gamePath ? settingsRefs.gamePath.value.trim() : '';
    if (gp) {
      var x2 = new XMLHttpRequest();
      x2.open('GET', SCRIPTS_PATH_URL + '?path=' + encodeURIComponent(gp), true);
      x2.timeout = 1500;
      x2.send();
    }
  }

  /* Загрузка настроек из AHK (GET /settings) */
  function loadSettings(cb) {
    var xhr = new XMLHttpRequest();
    xhr.open('GET', SETTINGS_URL, true);
    xhr.timeout = 1500;
    xhr.onload = function () {
      if (xhr.status >= 200 && xhr.status < 300) {
        try {
          var d = JSON.parse(xhr.responseText);
          if (d.nick != null) settings.nick = String(d.nick);
          if (d.logFile != null) settings.chatlogPath = String(d.logFile);
          if (d.gamePath != null) settings.gamePath = String(d.gamePath);
          if (d.norm != null) settings.norm = String(d.norm);
          if (d.autoReset != null) settings.autoResetEnabled = d.autoReset === 1 || d.autoReset === '1';
          if (d.startWithWindows != null) settings.startWithWindows = d.startWithWindows === 1 || d.startWithWindows === '1' || d.startWithWindows === true;
          if (d.hours != null) settings.resetTime.hours = pad2(d.hours);
          if (d.minutes != null) settings.resetTime.minutes = pad2(d.minutes);
          if (d.menuKey) settings.binds.panel = String(d.menuKey);
          if (d.resetKey) settings.binds.normReset = String(d.resetKey);
          if (d.aiKey) settings.binds.hideHud = String(d.aiKey);
          if (d.menuKeyEnabled != null) settings.bindEnabled.panel = d.menuKeyEnabled === 1 || d.menuKeyEnabled === '1';
          if (d.resetKeyEnabled != null) settings.bindEnabled.normReset = d.resetKeyEnabled === 1 || d.resetKeyEnabled === '1';
          if (d.aiKeyEnabled != null) settings.bindEnabled.hideHud = d.aiKeyEnabled === 1 || d.aiKeyEnabled === '1';
        } catch (e) {}
      }
      if (cb) cb();
    };
    xhr.onerror = function () { if (cb) cb(); };
    xhr.ontimeout = function () { if (cb) cb(); };
    xhr.send();
  }

  /* Сохранение настроек в AHK (GET /settings?k=v&...) */
  function saveSettingsToBridge() {
    var params = [];
    params.push('norm=' + encodeURIComponent(settings.norm));
    params.push('autoReset=' + (settings.autoResetEnabled ? '1' : '0'));
    params.push('startWithWindows=' + (settings.startWithWindows ? '1' : '0'));
    params.push('hours=' + encodeURIComponent(settings.resetTime.hours));
    params.push('minutes=' + encodeURIComponent(settings.resetTime.minutes));
    params.push('menuKey=' + encodeURIComponent(settings.binds.panel));
    params.push('resetKey=' + encodeURIComponent(settings.binds.normReset));
    params.push('aiKey=' + encodeURIComponent(settings.binds.hideHud));
    params.push('menuKeyEnabled=' + (settings.bindEnabled.panel ? '1' : '0'));
    params.push('resetKeyEnabled=' + (settings.bindEnabled.normReset ? '1' : '0'));
    params.push('aiKeyEnabled=' + (settings.bindEnabled.hideHud ? '1' : '0'));
    var xhr = new XMLHttpRequest();
    xhr.open('GET', SETTINGS_URL + '?' + params.join('&'), true);
    xhr.timeout = 1500;
    xhr.send();
  }

  function renderAI() {
    clearBody();
    aiProviderButtons = {};

    var wrap = el('div', 'ches-ai');

    /* Включение / выключение AI */
    var card = el('div', 'ches-ai-card');
    var toggleRow = makeToggleRow('Включить AI', 'Без сетевых запросов к API AI полностью отключён', aiState.enabled, 'bind');
    aiRefs.toggle = toggleRow.querySelector('.ches-toggle');
    aiRefs.toggle.addEventListener('click', function () {
      var on = aiRefs.toggle.classList.contains('on');
      aiState.enabled = on;
      saveAiEnabled(on ? 1 : 0);
      refreshAiStatus();
    });
    card.appendChild(toggleRow);
    var aiStatus = el('div', 'ches-ai-status ' + (aiState.enabled ? 'on' : 'off'),
      aiState.enabled ? 'AI включён' : 'AI выключен — сетевые запросы к API не выполняются');
    aiRefs.statusEl = aiStatus;
    card.appendChild(aiStatus);
    var limitEl = el('div', 'ches-ai-limit', aiState.limitText || 'Лимит: загрузка…');
    aiRefs.limitEl = limitEl;
    card.appendChild(limitEl);
    card.appendChild(el('div', 'ches-ai-hint', 'В чате игры: /ai ваш вопрос + Enter — ответ появится в HUD слева внизу.'));
    wrap.appendChild(card);

    /* Выбор провайдера */
    var toolbar = el('div', 'ches-ai-toolbar');
    aiProviders.forEach(function (p) {
      var btn = el('div', 'ches-ai-opt' + (aiState.provider === p.id ? ' active' : ''));
      btn.appendChild(el('span', null, p.label));
      btn.appendChild(el('span', 'ches-ai-opt-badge ' + p.price, p.price === 'free' ? 'free' : 'платный'));
      btn.addEventListener('click', function () {
        if (aiState.provider === p.id) return;
        aiState.provider = p.id;
        Object.keys(aiProviderButtons).forEach(function (key) {
          aiProviderButtons[key].className = 'ches-ai-opt' + (key === p.id ? ' active' : '');
        });
        saveAiProvider(p.id);
      });
      toolbar.appendChild(btn);
      aiProviderButtons[p.id] = btn;
    });
    wrap.appendChild(toolbar);

    /* Задать вопрос */
    var askCard = el('div', 'ches-ai-card');
    askCard.appendChild(el('div', 'ches-ai-pane-title', 'Спросить AI'));
    var askRow = el('div', 'ches-ai-ask');
    var askField = el('div', 'ches-ai-ask-field');
    var askIn = makeOnishiInput({ value: '', placeholder: 'Ваш вопрос…' });
    askIn.input.maxLength = 400;
    askIn.box.style.width = '100%';
    aiRefs.askIn = askIn.input;
    askField.appendChild(askIn.box);
    askRow.appendChild(askField);
    var askActions = el('div', 'ches-ai-ask-actions');
    var askBtn = el('div', 'ches-ai-btn', 'Спросить');
    aiRefs.askBtn = askBtn;
    askBtn.addEventListener('click', function () { askAiFromPanel(); });
    askActions.appendChild(askBtn);
    var clearBtn = el('div', 'ches-ai-btn ghost', 'Очистить историю');
    aiRefs.clearBtn = clearBtn;
    clearBtn.addEventListener('click', function () { clearAiHistory(); });
    askActions.appendChild(clearBtn);
    askRow.appendChild(askActions);
    askCard.appendChild(askRow);
    wrap.appendChild(askCard);

    /* Две панели: запросы и ответы */
    var columns = el('div', 'ches-ai-columns');

    var promptsPane = el('div', 'ches-ai-pane');
    promptsPane.appendChild(el('div', 'ches-ai-pane-title', 'Запросы'));
    var promptsList = el('div', 'ches-ai-list');
    aiRefs.promptsList = promptsList;
    promptsPane.appendChild(promptsList);

    var answersPane = el('div', 'ches-ai-pane');
    answersPane.appendChild(el('div', 'ches-ai-pane-title', 'Ответы AI'));
    var answersList = el('div', 'ches-ai-list');
    aiRefs.answersList = answersList;
    answersPane.appendChild(answersList);

    columns.appendChild(promptsPane);
    columns.appendChild(answersPane);
    wrap.appendChild(columns);

    contentBodyEl.appendChild(wrap);
    renderAiHistory();
    loadAi();
  }

  function refreshAiStatus() {
    if (aiRefs.statusEl) {
      aiRefs.statusEl.className = 'ches-ai-status ' + (aiState.enabled ? 'on' : 'off');
      aiRefs.statusEl.textContent = aiState.enabled
        ? 'AI включён'
        : 'AI выключен — сетевые запросы к API не выполняются';
    }
    if (aiRefs.limitEl) {
      aiRefs.limitEl.textContent = aiState.limitText || 'Лимит: —';
    }
    if (aiRefs.toggle) {
      if (aiState.enabled) aiRefs.toggle.classList.add('on');
      else aiRefs.toggle.classList.remove('on');
    }
    Object.keys(aiProviderButtons).forEach(function (key) {
      aiProviderButtons[key].className = 'ches-ai-opt' + (key === aiState.provider ? ' active' : '');
    });
    if (aiRefs.askBtn) {
      if (aiState.busy) {
        aiRefs.askBtn.classList.add('busy');
        aiRefs.askBtn.textContent = 'Думает…';
      } else {
        aiRefs.askBtn.classList.remove('busy');
        aiRefs.askBtn.textContent = 'Спросить';
      }
    }
  }

  function renderAiHistory() {
    var hist = Array.isArray(aiState.history) ? aiState.history : [];
    if (aiRefs.promptsList) {
      aiRefs.promptsList.innerHTML = '';
      if (hist.length === 0) {
        aiRefs.promptsList.appendChild(el('div', 'ches-ai-empty', 'Здесь будут твои запросы к AI'));
      } else {
        hist.forEach(function (item) {
          var row = el('div', 'ches-ai-item');
          if (item.t) row.appendChild(el('div', 'ches-ai-item-time', item.t));
          row.appendChild(el('div', 'ches-ai-item-text', item.q || ''));
          aiRefs.promptsList.appendChild(row);
        });
      }
    }
    if (aiRefs.answersList) {
      aiRefs.answersList.innerHTML = '';
      if (hist.length === 0) {
        aiRefs.answersList.appendChild(el('div', 'ches-ai-empty', 'Здесь будут ответы AI'));
      } else {
        hist.forEach(function (item) {
          var row = el('div', 'ches-ai-item');
          if (item.t) row.appendChild(el('div', 'ches-ai-item-time', item.t));
          row.appendChild(el('div', 'ches-ai-item-text', item.a || ''));
          aiRefs.answersList.appendChild(row);
        });
      }
    }
  }

  function applyAiPayload(d) {
    if (!d || !d.ok) return;
    aiState.enabled = !!(d.enabled === 1 || d.enabled === '1' || d.enabled === true);
    if (d.provider) aiState.provider = String(d.provider);
    aiState.busy = !!(d.busy === 1 || d.busy === '1' || d.busy === true);
    aiState.limitText = d.limitText || '';
    aiState.limit = d.limit != null ? parseInt(d.limit, 10) || 0 : 0;
    aiState.used = d.used != null ? parseInt(d.used, 10) || 0 : 0;
    aiState.remaining = d.remaining != null ? parseInt(d.remaining, 10) || 0 : 0;
    aiState.history = Array.isArray(d.history) ? d.history : [];
    aiState.loaded = true;
    refreshAiStatus();
    renderAiHistory();
  }

  function loadAi() {
    var xhr = new XMLHttpRequest();
    xhr.open('GET', AI_URL, true);
    xhr.timeout = 1500;
    xhr.onload = function () {
      if (xhr.status >= 200 && xhr.status < 300) {
        try {
          applyAiPayload(JSON.parse(xhr.responseText));
        } catch (e) {}
      }
    };
    xhr.onerror = function () {};
    xhr.ontimeout = function () {};
    xhr.send();
  }

  function saveAiEnabled(enabled) {
    var xhr = new XMLHttpRequest();
    xhr.open('GET', AI_TOGGLE_URL + '?enabled=' + (enabled ? 1 : 0), true);
    xhr.timeout = 1500;
    xhr.onload = function () { setTimeout(loadAi, 400); };
    xhr.onerror = function () {};
    xhr.ontimeout = function () {};
    xhr.send();
  }

  function saveAiProvider(id) {
    var xhr = new XMLHttpRequest();
    xhr.open('GET', AI_PROVIDER_URL + '?id=' + encodeURIComponent(id), true);
    xhr.timeout = 1500;
    xhr.onload = function () { setTimeout(loadAi, 400); };
    xhr.onerror = function () {};
    xhr.ontimeout = function () {};
    xhr.send();
  }

  function askAiFromPanel() {
    var q = aiRefs.askIn ? String(aiRefs.askIn.value || '').trim() : '';
    if (q.length < 2) return;
    if (aiState.busy) return;
    aiState.busy = true;
    refreshAiStatus();
    var xhr = new XMLHttpRequest();
    xhr.open('GET', AI_ASK_URL + '?q=' + encodeURIComponent(q), true);
    xhr.timeout = 3000;
    xhr.onload = function () {
      if (aiRefs.askIn) aiRefs.askIn.value = '';
      // ответ придёт асинхронно — поллим
      var tries = 0;
      var timer = setInterval(function () {
        tries += 1;
        loadAi();
        if (tries >= 20 || (!aiState.busy && tries >= 3)) clearInterval(timer);
      }, 800);
    };
    xhr.onerror = function () {
      aiState.busy = false;
      refreshAiStatus();
    };
    xhr.ontimeout = function () {
      // команда могла уйти — всё равно поллим
      var tries = 0;
      var timer = setInterval(function () {
        tries += 1;
        loadAi();
        if (tries >= 20) clearInterval(timer);
      }, 800);
    };
    xhr.send();
  }

  function clearAiHistory() {
    var xhr = new XMLHttpRequest();
    xhr.open('GET', AI_CLEAR_URL, true);
    xhr.timeout = 1500;
    xhr.onload = function () { setTimeout(loadAi, 400); };
    xhr.onerror = function () {};
    xhr.ontimeout = function () {};
    xhr.send();
  }

  function renderDashboard() {
    clearBody();
    dashRefs.info = {};
    dashRefs.sys = {};

    var columns = el('div', 'ches-dash-columns');

    /* Информационная панель */
    var infoPane = el('div', 'ches-dash-pane');
    infoPane.appendChild(el('div', 'ches-dash-pane-title', 'Информация'));
    var infoRows = [
      { key: 'nick', label: 'Ник администратора', value: dashState.admin.nick },
      { key: 'norm', label: 'Норма админа', value: dashState.admin.norm },
      { key: 'daysOff', label: 'Отгулы', value: dashState.admin.daysOff }
    ];
    infoRows.forEach(function (r) {
      var row = el('div', 'ches-dash-row');
      row.appendChild(el('div', 'ches-dash-row-label', r.label));
      var val = el('div', 'ches-dash-row-value', r.value);
      row.appendChild(val);
      dashRefs.info[r.key] = val;
      infoPane.appendChild(row);
    });
    columns.appendChild(infoPane);

    /* Системная панель */
    var sysPane = el('div', 'ches-dash-pane');
    sysPane.appendChild(el('div', 'ches-dash-pane-title', 'Системы'));
    var sysRows = [
      { key: 'chatlog', label: 'Chatlog', state: dashState.systems.chatlog },
      { key: 'root', label: 'Корень игры', state: dashState.systems.root },
      { key: 'hud', label: 'Счётчик в игре', state: dashState.systems.hud }
    ];
    sysRows.forEach(function (s) {
      var row = el('div', 'ches-dash-sys');
      row.appendChild(el('div', 'ches-dash-row-label', s.label));
      var dot = el('div', 'ches-dash-dot ' + (s.state === 'ok' ? 'on' : s.state === 'off' ? 'off' : ''));
      row.appendChild(dot);
      dashRefs.sys[s.key] = dot;
      sysPane.appendChild(row);
    });
    columns.appendChild(sysPane);

    contentBodyEl.appendChild(columns);
    pollDashboard();
  }

  function pollDashboard() {
    if (dashPollBusy) return;
    dashPollBusy = true;
    try {
      var xhr = new XMLHttpRequest();
      xhr.open('GET', DASH_URL, true);
      xhr.timeout = 1500;
      xhr.onload = function () {
        dashPollBusy = false;
        if (xhr.status >= 200 && xhr.status < 300) {
          try { applyDashState(JSON.parse(xhr.responseText)); } catch (e) {}
        }
      };
      xhr.onerror = function () { dashPollBusy = false; };
      xhr.ontimeout = function () { dashPollBusy = false; };
      xhr.send();
    } catch (e) {
      dashPollBusy = false;
    }
  }

  function applyDashState(d) {
    if (!d || typeof d !== 'object') return;
    if (d.nick != null) dashState.admin.nick = String(d.nick);
    if (d.norm != null) dashState.admin.norm = String(d.norm);
    if (d.daysOff != null) dashState.admin.daysOff = String(d.daysOff);
    if (d.chatlogOk != null) dashState.systems.chatlog = d.chatlogOk === 1 || d.chatlogOk === '1' ? 'ok' : 'off';
    if (d.gameOk != null) dashState.systems.root = d.gameOk === 1 || d.gameOk === '1' ? 'ok' : 'off';
    if (d.hudVisible != null) dashState.systems.hud = d.hudVisible === 1 || d.hudVisible === '1' ? 'ok' : 'off';
    updateDashboardDom();
  }

  function updateDashboardDom() {
    if (!contentBodyEl || currentView !== 'Dashboard') return;
    if (dashRefs.info.nick) dashRefs.info.nick.textContent = dashState.admin.nick;
    if (dashRefs.info.norm) dashRefs.info.norm.textContent = dashState.admin.norm;
    if (dashRefs.info.daysOff) dashRefs.info.daysOff.textContent = dashState.admin.daysOff;
    Object.keys(dashRefs.sys).forEach(function (key) {
      var dot = dashRefs.sys[key];
      if (!dot) return;
      var st = dashState.systems[key];
      dot.className = 'ches-dash-dot ' + (st === 'ok' ? 'on' : st === 'off' ? 'off' : '');
    });
  }

  function renderPunishments() {
    clearBody();
    punRefs.periodBtns = {};
    punRefs.typeBtns = {};

    var wrap = el('div', 'ches-pun');

    /* Период + поиск */
    var toolbar = el('div', 'ches-pun-toolbar');
    punPeriods.forEach(function (p) {
      var btn = el('div', 'ches-pun-period' + (punState.period === p.id ? ' active' : ''));
      btn.textContent = p.label;
      btn.addEventListener('click', function () {
        punState.period = p.id;
        Object.keys(punRefs.periodBtns).forEach(function (key) {
          punRefs.periodBtns[key].className = 'ches-pun-period' + (key === p.id ? ' active' : '');
        });
        refreshPunishments();
      });
      toolbar.appendChild(btn);
      punRefs.periodBtns[p.id] = btn;
    });
    var searchWrap = el('div', 'ches-pun-search');
    var searchIn = makeOnishiInput({ width: '220px' });
    punRefs.search = searchIn.input;
    searchIn.input.addEventListener('input', function () {
      refreshPunishments();
    });
    searchWrap.appendChild(searchIn.box);
    toolbar.appendChild(searchWrap);
    wrap.appendChild(toolbar);

    /* Типы + меню */
    var main = el('div', 'ches-pun-main');

    var typesPane = el('div', 'ches-pun-types');
    punTypes.forEach(function (t) {
      var row = el('div', 'ches-pun-type' + (punState.type === t.id ? ' active' : ''));
      row.appendChild(el('div', 'ches-pun-type-label', t.label));
      var countEl = el('div', 'ches-pun-type-count', String(punState.counts[t.id]));
      row.appendChild(countEl);
      punRefs.typeBtns[t.id] = { row: row, count: countEl };
      row.addEventListener('click', function () {
        punState.type = t.id;
        Object.keys(punRefs.typeBtns).forEach(function (key) {
          punRefs.typeBtns[key].row.className = 'ches-pun-type' + (key === t.id ? ' active' : '');
        });
        refreshPunishments();
      });
      typesPane.appendChild(row);
    });
    main.appendChild(typesPane);

    var menu = el('div', 'ches-pun-menu');
    punRefs.menu = menu;
    main.appendChild(menu);

    wrap.appendChild(main);
    contentBodyEl.appendChild(wrap);

    loadPunishments();
  }

  function loadPunishments() {
    var xhr = new XMLHttpRequest();
    xhr.open('GET', PUN_URL, true);
    xhr.timeout = 1500;
    xhr.onload = function () {
      if (xhr.status >= 200 && xhr.status < 300) {
        try {
          var d = JSON.parse(xhr.responseText);
          if (d && Array.isArray(d.records)) {
            punState.rows = d.records;
            punState.loaded = true;
            refreshPunishments();
          }
        } catch (e) {}
      }
    };
    xhr.onerror = function () {};
    xhr.ontimeout = function () {};
    xhr.send();
  }

  function punPeriodDays() {
    if (punState.period === 'today') return 1;
    if (punState.period === '3days') return 3;
    if (punState.period === '10days') return 10;
    return 0;
  }

  function punDateToYmd(date) {
    var p = String(date || '').split('.');
    if (p.length < 3) return '';
    return p[2] + p[1] + p[0];
  }

  function punInPeriod(date) {
    var days = punPeriodDays();
    if (!days) return true;
    var ymd = punDateToYmd(date);
    if (!ymd) return false;
    var today = new Date();
    var d = new Date(ymd.substr(0, 4), parseInt(ymd.substr(4, 2), 10) - 1, parseInt(ymd.substr(6, 2), 10));
    var diff = (today - d) / 86400000;
    return diff >= 0 && diff < days;
  }

  function punMatchesSearch(rec) {
    var q = (punRefs.search ? punRefs.search.value : '') || '';
    q = String(q).trim().toLowerCase();
    if (!q) return true;
    var hay = ((rec.player || '') + ' ' + (rec.reason || '') + ' ' + (rec.date || '') + ' ' + (rec.time || '')).toLowerCase();
    return hay.indexOf(q) >= 0;
  }

  function refreshPunishments() {
    var filtered = [];
    punState.rows.forEach(function (rec) {
      if (!punInPeriod(rec.date)) return;
      if (punState.type !== 'all' && rec.type !== punState.type) return;
      if (!punMatchesSearch(rec)) return;
      filtered.push(rec);
    });

    var counts = {};
    punTypes.forEach(function (t) {
      counts[t.id] = 0;
    });
    var total = 0;
    punState.rows.forEach(function (rec) {
      if (!punInPeriod(rec.date)) return;
      total++;
      if (counts[rec.type] != null) counts[rec.type]++;
    });
    counts.all = total;

    Object.keys(punRefs.typeBtns).forEach(function (key) {
      punRefs.typeBtns[key].count.textContent = String(counts[key] != null ? counts[key] : 0);
    });

    if (!punRefs.menu) return;
    punRefs.menu.innerHTML = '';

    if (!punState.loaded) {
      punRefs.menu.appendChild(el('div', 'ches-pun-empty', 'Загрузка…'));
      return;
    }
    if (!filtered.length) {
      var noText = punState.period === 'all' ? 'За всё время наказаний не найдено'
        : punState.period === 'today' ? 'За сегодня наказаний не найдено'
        : 'За последние дни наказаний не найдено';
      punRefs.menu.appendChild(el('div', 'ches-pun-empty', noText));
      return;
    }

    filtered.forEach(function (rec) {
      var row = el('div', 'ches-pun-item');
      var head = el('div', 'ches-pun-item-head');
      head.appendChild(el('div', 'ches-pun-item-date', (rec.date || '') + ' ' + (rec.time || '')));
      head.appendChild(el('div', 'ches-pun-item-type ' + rec.type, rec.type));
      row.appendChild(head);
      row.appendChild(el('div', 'ches-pun-item-player', 'Игрок: ' + (rec.player || '—')));
      if (rec.reason) row.appendChild(el('div', 'ches-pun-item-reason', 'Причина: ' + rec.reason));
      if (rec.duration) row.appendChild(el('div', 'ches-pun-item-duration', 'Срок: ' + rec.duration));
      punRefs.menu.appendChild(row);
    });
  }

  function renderPMLogs() {
    clearBody();

    var wrap = el('div', 'ches-pml');

    var toolbar = el('div', 'ches-pml-toolbar');
    var searchWrap = el('div', 'ches-pml-search');
    var searchIn = makeOnishiInput({ width: '100%' });
    pmLogRefs.search = searchIn.input;
    searchIn.input.addEventListener('input', function () {
      refreshPmLogs();
    });
    searchWrap.appendChild(searchIn.box);
    toolbar.appendChild(searchWrap);

    var clearBtn = el('div', 'ches-pml-clear', 'Очистить');
    clearBtn.addEventListener('click', function () {
      if (clearBtn.getAttribute('data-arm') !== '1') {
        clearBtn.setAttribute('data-arm', '1');
        clearBtn.textContent = 'Точно?';
        setTimeout(function () {
          clearBtn.setAttribute('data-arm', '0');
          clearBtn.textContent = 'Очистить';
        }, 3000);
        return;
      }
      clearBtn.setAttribute('data-arm', '0');
      clearBtn.textContent = 'Очистить';
      var xhr = new XMLHttpRequest();
      xhr.open('GET', PM_CLEAR_URL, true);
      xhr.timeout = 1500;
      xhr.onload = function () {
        pmLogState.entries = [];
        pmLogState.loaded = true;
        refreshPmLogs();
      };
      xhr.send();
    });
    toolbar.appendChild(clearBtn);
    wrap.appendChild(toolbar);

    var log = el('div', 'ches-pml-log');
    pmLogRefs.log = log;
    wrap.appendChild(log);

    contentBodyEl.appendChild(wrap);

    loadPmLogs();
  }

  function loadPmLogs() {
    var xhr = new XMLHttpRequest();
    xhr.open('GET', PM_URL, true);
    xhr.timeout = 1500;
    xhr.onload = function () {
      if (xhr.status >= 200 && xhr.status < 300) {
        try {
          var d = JSON.parse(xhr.responseText);
          if (d && Array.isArray(d.records)) {
            pmLogState.entries = d.records;
            pmLogState.loaded = true;
            refreshPmLogs();
          }
        } catch (e) {}
      }
    };
    xhr.onerror = function () {};
    xhr.ontimeout = function () {};
    xhr.send();
  }

  function refreshPmLogs() {
    if (!pmLogRefs.log) return;
    pmLogRefs.log.innerHTML = '';

    if (!pmLogState.loaded) {
      pmLogRefs.log.appendChild(el('div', 'ches-pml-empty', 'Загрузка…'));
      return;
    }

    var q = (pmLogRefs.search ? pmLogRefs.search.value : '') || '';
    q = String(q).trim().toLowerCase();

    var filtered = [];
    pmLogState.entries.forEach(function (e) {
      if (!q) { filtered.push(e); return; }
      var hay = (((e.nick || '') + ' ' + (e.message || '') + ' ' + (e.date || '') + ' ' + (e.time || ''))).toLowerCase();
      if (hay.indexOf(q) >= 0) filtered.push(e);
    });

    if (!filtered.length) {
      pmLogRefs.log.appendChild(el('div', 'ches-pml-empty', 'PM логи пока пустые.'));
      return;
    }

    filtered.forEach(function (e) {
      var item = el('div', 'ches-pml-item');
      var head = el('div', 'ches-pml-item-head');
      head.appendChild(el('div', 'ches-pml-item-date', (e.date || '') + ' ' + (e.time || '')));
      head.appendChild(el('div', 'ches-pml-item-nick', e.nick || ''));
      item.appendChild(head);
      item.appendChild(el('div', 'ches-pml-item-message', e.message || ''));
      pmLogRefs.log.appendChild(item);
    });
  }

  function renderNorm() {
    clearBody();
    normState.editing = false;
    normState.selectedDate = null;

    var wrap = el('div', 'ches-norm');

    var toolbar = el('div', 'ches-norm-toolbar');
    var editBtn = el('div', 'ches-norm-btn edit', 'Редактировать');
    normRefs.editBtn = editBtn;
    editBtn.addEventListener('click', function () {
      if (!normState.selectedDate) return;
      var rec = null;
      normState.rows.forEach(function (r) {
        if (r.raw === normState.selectedDate) rec = r;
      });
      if (!rec) return;
      normState.editing = true;
      normRefs.body.innerHTML = '';
      var row = el('div', 'ches-norm-head ches-norm-row ches-norm-edit');
      row.appendChild(el('div', 'ches-norm-cell ches-norm-date', rec.date || '—'));
      var pmInput = el('input', 'ches-norm-input');
      pmInput.type = 'text';
      pmInput.value = String(rec.pm != null ? rec.pm : '');
      pmInput.placeholder = 'PM';
      var pmCell = el('div', 'ches-norm-cell ches-norm-pm');
      pmCell.appendChild(pmInput);
      row.appendChild(pmCell);
      var normInput = el('input', 'ches-norm-input');
      normInput.type = 'text';
      normInput.value = String(rec.norm != null ? rec.norm : '');
      normInput.placeholder = 'Норма';
      var normCell = el('div', 'ches-norm-cell ches-norm-norm');
      normCell.appendChild(normInput);
      row.appendChild(normCell);
      var statusCell = el('div', 'ches-norm-cell ches-norm-status');
      var saveBtn = el('div', 'ches-norm-btn edit', 'Сохранить');
      saveBtn.addEventListener('click', function () {
        normState.editing = false;
        saveNormEdit(rec.raw, pmInput.value, normInput.value);
      });
      statusCell.appendChild(saveBtn);
      row.appendChild(statusCell);
      normRefs.body.appendChild(row);
    });
    toolbar.appendChild(editBtn);
    wrap.appendChild(toolbar);

    var panel = el('div', 'ches-norm-panel');

    var head = el('div', 'ches-norm-head');
    var cols = [
      { cls: 'ches-norm-date', label: 'Дата' },
      { cls: 'ches-norm-pm', label: 'PM' },
      { cls: 'ches-norm-norm', label: 'Норма' },
      { cls: 'ches-norm-status', label: 'Статус' }
    ];
    cols.forEach(function (c) {
      head.appendChild(el('div', 'ches-norm-cell ' + c.cls, c.label));
    });
    panel.appendChild(head);

    var body = el('div', 'ches-norm-body');
    normRefs.body = body;
    panel.appendChild(body);

    wrap.appendChild(panel);
    contentBodyEl.appendChild(wrap);

    loadNorm();
  }

  function saveNormEdit(origDate, pmRaw, normRaw) {
    var pm = String(pmRaw || '').trim();
    var norm = String(normRaw || '').trim();
    if (pm === '' || norm === '') return;
    var xhr = new XMLHttpRequest();
    xhr.open('GET', NORM_SAVE_URL
      + '?orig=' + encodeURIComponent(origDate)
      + '&date=' + encodeURIComponent(origDate)
      + '&pm=' + encodeURIComponent(pm)
      + '&norm=' + encodeURIComponent(norm), true);
    xhr.timeout = 1500;
    xhr.onload = function () {
      setTimeout(function () { loadNorm(); }, 600);
    };
    xhr.onerror = function () {};
    xhr.ontimeout = function () {};
    xhr.send();
  }

  function loadNorm() {
    var xhr = new XMLHttpRequest();
    xhr.open('GET', NORM_URL, true);
    xhr.timeout = 1500;
    xhr.onload = function () {
      if (xhr.status >= 200 && xhr.status < 300) {
        try {
          var d = JSON.parse(xhr.responseText);
          if (d && Array.isArray(d.records)) {
            normState.rows = d.records;
            normState.loaded = true;
            refreshNorm();
          }
        } catch (e) {}
      }
    };
    xhr.onerror = function () {};
    xhr.ontimeout = function () {};
    xhr.send();
  }

  function refreshNorm() {
    if (!normRefs.body) return;
    if (normState.editing) return;

    normRefs.body.innerHTML = '';

    if (!normState.loaded) {
      normRefs.body.appendChild(el('div', 'ches-norm-empty', 'Загрузка…'));
      return;
    }
    if (!normState.rows.length) {
      normRefs.body.appendChild(el('div', 'ches-norm-empty', 'Нет данных по норме'));
      return;
    }

    normState.rows.forEach(function (r) {
      var row = el('div', 'ches-norm-head ches-norm-row' + (normState.selectedDate === r.raw ? ' selected' : ''));
      row.appendChild(el('div', 'ches-norm-cell ches-norm-date', r.date || '—'));
      row.appendChild(el('div', 'ches-norm-cell ches-norm-pm', String(r.pm != null ? r.pm : '—')));
      row.appendChild(el('div', 'ches-norm-cell ches-norm-norm', String(r.norm != null ? r.norm : '—')));
      var pm = Number(r.pm) || 0;
      var norm = Number(r.norm) || 0;
      var statusText, statusCls;
      if (norm <= 0) { statusText = '—'; statusCls = 'off'; }
      else if (pm >= norm) { statusText = 'Выполнена'; statusCls = 'ok'; }
      else { statusText = 'Не выполнена'; statusCls = 'fail'; }
      var statusEl = el('div', 'ches-norm-cell ches-norm-status ' + statusCls, statusText);
      row.appendChild(statusEl);
      row.addEventListener('click', function () {
        normState.selectedDate = r.raw;
        var rows = normRefs.body.querySelectorAll('.ches-norm-row');
        for (var i = 0; i < rows.length; i++) {
          if (rows[i] === row) rows[i].className = 'ches-norm-head ches-norm-row selected';
          else rows[i].className = 'ches-norm-head ches-norm-row';
        }
      });
      normRefs.body.appendChild(row);
    });
  }

  function renderDaysOff() {
    clearBody();

    var wrap = el('div', 'ches-days');

    /* Дата + добавить/удалить + залито/не залито */
    var toolbar1 = el('div', 'ches-days-toolbar');
    var dateIn = makeOnishiInput({ width: '200px', placeholder: '2026-08-08' });
    daysOffRefs.dateIn = dateIn;
    toolbar1.appendChild(dateIn.box);

    var addBtn = el('div', 'ches-days-btn green', 'Добавить');
    addBtn.addEventListener('click', function () {
      addDayOff();
    });
    toolbar1.appendChild(addBtn);

    var delBtn = el('div', 'ches-days-btn red', 'Удалить');
    delBtn.addEventListener('click', function () {
      deleteDayOff();
    });
    toolbar1.appendChild(delBtn);

    var upBtn = el('div', 'ches-days-btn green', 'Залито');
    upBtn.addEventListener('click', function () {
      setDayOffForum(1);
    });
    toolbar1.appendChild(upBtn);

    var downBtn = el('div', 'ches-days-btn red', 'Не залито');
    downBtn.addEventListener('click', function () {
      setDayOffForum(0);
    });
    toolbar1.appendChild(downBtn);

    wrap.appendChild(toolbar1);

    /* Список: Дата | Форум */
    var list = el('div', 'ches-days-list');
    var head = el('div', 'ches-days-list-head');
    head.appendChild(el('div', 'ches-days-list-cell ches-days-date', 'Дата'));
    head.appendChild(el('div', 'ches-days-list-cell ches-days-forum', 'Форум'));
    list.appendChild(head);
    var body = el('div', 'ches-days-list-body');
    daysOffRefs.body = body;
    body.appendChild(el('div', 'ches-days-empty', 'Загрузка…'));
    list.appendChild(body);
    wrap.appendChild(list);

    /* Месяц + год + показать */
    var periodPane = el('div', 'ches-days-panel');
    periodPane.appendChild(el('div', 'ches-days-pane-title', 'Период'));
    var periodToolbar = el('div', 'ches-days-toolbar');

    var monthSel = makeDropdown(daysMonths, {
      width: '160px',
      selected: daysOffState.monthIndex,
      onSelect: function (i) {
        daysOffState.monthIndex = i;
        updateDaysOffCount();
      }
    });

    var yearIn = makeOnishiInput({ width: '100px', value: daysOffState.year, placeholder: '2026' });
    yearIn.input.addEventListener('change', function () {
      daysOffState.year = yearIn.input.value || daysOffState.year;
      updateDaysOffCount();
    });

    periodToolbar.appendChild(monthSel.box);
    periodToolbar.appendChild(yearIn.box);
    periodPane.appendChild(periodToolbar);
    wrap.appendChild(periodPane);

    /* Результат */
    var result = el('div', 'ches-days-result', 'Отгулов за ' + daysMonths[daysOffState.monthIndex] + ' — ' + daysOffState.count);
    daysOffRefs.countEl = result;
    wrap.appendChild(result);

    contentBodyEl.appendChild(wrap);

    loadDaysOff();
  }

  function loadDaysOff() {
    var xhr = new XMLHttpRequest();
    xhr.open('GET', DAYSOFF_URL, true);
    xhr.timeout = 1500;
    xhr.onload = function () {
      if (xhr.status >= 200 && xhr.status < 300) {
        try {
          var d = JSON.parse(xhr.responseText);
          if (d && Array.isArray(d.records)) {
            daysOffState.rows = d.records;
            daysOffState.loaded = true;
            refreshDaysOff();
          }
        } catch (e) {}
      }
    };
    xhr.onerror = function () {};
    xhr.ontimeout = function () {};
    xhr.send();
  }

  function refreshDaysOff() {
    if (!daysOffRefs.body) return;

    daysOffRefs.body.innerHTML = '';
    if (!daysOffState.rows.length) {
      daysOffRefs.body.appendChild(el('div', 'ches-days-empty', 'Отгулов нет'));
    }
    daysOffState.rows.forEach(function (r) {
      var row = el('div', 'ches-days-list-row' + (daysOffState.selected === r.date ? ' selected' : ''));
      var dateEl = el('div', 'ches-days-list-cell ches-days-date', r.date || '—');
      row.appendChild(dateEl);
      var forumEl = el('div', 'ches-days-list-cell ches-days-forum ' + (r.forum ? 'ok' : 'no'), r.forum ? 'Залито' : 'Не залито');
      row.appendChild(forumEl);
      row.addEventListener('click', function () {
        daysOffState.selected = r.date;
        var rows = daysOffRefs.body.querySelectorAll('.ches-days-list-row');
        for (var i = 0; i < rows.length; i++) {
          if (rows[i] === row) rows[i].className = 'ches-days-list-row selected';
          else rows[i].className = 'ches-days-list-row';
        }
      });
      daysOffRefs.body.appendChild(row);
    });
    updateDaysOffCount();
  }

  function updateDaysOffCount() {
    if (!daysOffRefs.countEl) return;
    var month = String(daysOffState.monthIndex + 1);
    if (month.length < 2) month = '0' + month;
    var year = daysOffState.year || '2026';
    var count = 0;
    daysOffState.rows.forEach(function (r) {
      var p = String(r.date || '').split('-');
      if (p.length === 3 && p[0] === year && p[1] === month) count++;
    });
    daysOffState.count = count;
    daysOffRefs.countEl.textContent = 'Отгулов за ' + daysMonths[daysOffState.monthIndex] + ' ' + year + ' — ' + count;
  }

  function addDayOff() {
    var val = daysOffRefs.dateIn ? daysOffRefs.dateIn.input.value : '';
    val = String(val || '').trim();
    if (!val) return;
    var xhr = new XMLHttpRequest();
    xhr.open('GET', DAYSOFF_ADD_URL
      + '?date=' + encodeURIComponent(val)
      + '&forum=0', true);
    xhr.timeout = 1500;
    xhr.onload = function () {
      setTimeout(function () { loadDaysOff(); }, 400);
    };
    xhr.onerror = function () {};
    xhr.ontimeout = function () {};
    xhr.send();
  }

  function deleteDayOff() {
    var date = daysOffState.selected;
    if (!date) return;
    var xhr = new XMLHttpRequest();
    xhr.open('GET', DAYSOFF_DELETE_URL
      + '?dates=' + encodeURIComponent(date), true);
    xhr.timeout = 1500;
    xhr.onload = function () {
      daysOffState.selected = null;
      setTimeout(function () { loadDaysOff(); }, 400);
    };
    xhr.onerror = function () {};
    xhr.ontimeout = function () {};
    xhr.send();
  }

  function setDayOffForum(uploaded) {
    var date = daysOffState.selected;
    if (!date) return;
    var xhr = new XMLHttpRequest();
    xhr.open('GET', DAYSOFF_FORUM_URL
      + '?dates=' + encodeURIComponent(date)
      + '&uploaded=' + (uploaded ? 1 : 0), true);
    xhr.timeout = 1500;
    xhr.onload = function () {
      setTimeout(function () { loadDaysOff(); }, 400);
    };
    xhr.onerror = function () {};
    xhr.ontimeout = function () {};
    xhr.send();
  }

  function getBindTypeLabel(type) {
    type = String(type || '').toLowerCase();
    if (type === 'hotstring') return 'Текст';
    if (type === 'macro') return 'Макрос';
    return 'Клавиша';
  }

  function getBindStatusText(bind) {
    if (bind.runtime) return bind.runtime;
    return bind.enabled ? 'Вкл' : 'Выкл';
  }

  function renderBinds() {
    clearBody();
    bindsState.search = '';
    bindsState.selectedTrigger = '';

    var wrap = el('div', 'ches-binds');

    /* Карточка: включение + действия */
    var card = el('div', 'ches-binds-card');
    var toggleRow = makeToggleRow('Бинды включены', 'Разрешить использование биндов', bindsState.enabled, 'bind');
    bindsRefs.toggle = toggleRow.querySelector('.ches-toggle');
    bindsRefs.toggle.addEventListener('click', function () {
      toggleBindsAll(bindsRefs.toggle.classList.contains('on') ? 1 : 0);
    });

    var headBtns = el('div', 'ches-binds-head-btns');
    var addBtn = el('div', 'ches-binds-btn primary', 'Добавить');
    addBtn.addEventListener('click', function () {
      openBindEditor(null);
    });
    headBtns.appendChild(addBtn);

    var importBtn = el('div', 'ches-binds-btn', 'Импорт');
    importBtn.addEventListener('click', function () {
      openBindImport();
    });
    headBtns.appendChild(importBtn);

    var exportBtn = el('div', 'ches-binds-btn', 'Экспорт');
    exportBtn.addEventListener('click', function () {
      exportBinds();
    });
    headBtns.appendChild(exportBtn);

    var dupBtn = el('div', 'ches-binds-btn', 'Дубликаты');
    dupBtn.addEventListener('click', function () {
      showBindDuplicates();
    });
    headBtns.appendChild(dupBtn);

    toggleRow.appendChild(headBtns);
    card.appendChild(toggleRow);

    /* Поиск + фильтр категории */
    var toolbar = el('div', 'ches-binds-toolbar');
    toolbar.appendChild(el('div', 'ches-binds-filter-label', 'Поиск'));
    var searchIn = makeOnishiInput({ width: '180px' });
    bindsRefs.searchIn = searchIn.input;
    searchIn.input.addEventListener('input', function () {
      bindsState.search = searchIn.input.value;
      renderBindsList();
    });
    toolbar.appendChild(searchIn.box);
    toolbar.appendChild(el('div', 'ches-binds-filter-label', 'Категория'));
    bindsRefs.catSlot = el('div', 'ches-binds-cat-slot');
    toolbar.appendChild(bindsRefs.catSlot);

    var toolGrow = el('div', 'ches-binds-toolbar-grow');
    toolbar.appendChild(toolGrow);

    card.appendChild(toolbar);
    wrap.appendChild(card);

    /* Категории */
    var catCard = el('div', 'ches-binds-card');
    var catHead = el('div', 'ches-binds-cat-head');
    catHead.appendChild(el('div', 'ches-binds-cat-title', 'Категории'));
    catHead.appendChild(el('div', 'ches-binds-cat-sub', 'выключенные не срабатывают'));
    catCard.appendChild(catHead);

    var catBody = el('div', 'ches-binds-cat-body');
    bindsRefs.catBody = catBody;
    catCard.appendChild(catBody);

    var catAddRow = el('div', 'ches-binds-cat-add');
    var catIn = makeOnishiInput({ width: '180px', placeholder: 'Новая категория' });
    bindsRefs.catIn = catIn;
    catAddRow.appendChild(catIn.box);
    var catAddBtn = el('div', 'ches-binds-btn primary', '+ Добавить');
    catAddBtn.addEventListener('click', function () {
      addBindCategory(catIn.input.value);
    });
    catAddRow.appendChild(catAddBtn);
    catCard.appendChild(catAddRow);

    wrap.appendChild(catCard);

    /* Редактор бинда */
    if (bindsState.editor) {
      wrap.appendChild(renderBindEditor());
      contentBodyEl.appendChild(wrap);
      return;
    }

    /* Список + превью */
    var main = el('div', 'ches-binds-main');

    var list = el('div', 'ches-binds-list');
    var head = el('div', 'ches-binds-list-head');
    var cols = [
      { cls: 'ches-binds-col-type', label: 'Тип' },
      { cls: 'ches-binds-col-cat', label: 'Категория' },
      { cls: 'ches-binds-col-name', label: 'Название' },
      { cls: 'ches-binds-col-trigger', label: 'Триггер' },
      { cls: 'ches-binds-col-status', label: 'Статус' }
    ];
    cols.forEach(function (c) {
      head.appendChild(el('div', 'ches-binds-cell ' + c.cls, c.label));
    });
    list.appendChild(head);

    var listBody = el('div', 'ches-binds-list-body');
    bindsRefs.listBody = listBody;
    listBody.appendChild(el('div', 'ches-binds-empty', 'Загрузка…'));
    list.appendChild(listBody);
    main.appendChild(list);

    var preview = el('div', 'ches-binds-preview empty');
    preview.appendChild(el('div', 'ches-binds-preview-title', 'Превью содержимого'));
    var previewBody = el('div', 'ches-binds-preview-body');
    bindsRefs.previewBody = previewBody;
    previewBody.appendChild(el('div', 'ches-binds-empty', 'Выберите бинд в списке'));
    preview.appendChild(previewBody);
    main.appendChild(preview);

    wrap.appendChild(main);

    contentBodyEl.appendChild(wrap);

    loadBinds();
  }

  function loadBinds() {
    var xhr = new XMLHttpRequest();
    xhr.open('GET', BINDS_URL, true);
    xhr.timeout = 1500;
    xhr.onload = function () {
      if (xhr.status >= 200 && xhr.status < 300) {
        try {
          var d = JSON.parse(xhr.responseText);
          if (d && Array.isArray(d.binds)) {
            bindsState.enabled = !!d.enabled;
            bindsState.categories = Array.isArray(d.categories) ? d.categories.map(function (c) {
              return { name: c.name, enabled: !!c.enabled };
            }) : [];
            bindsState.binds = d.binds;
            bindsState.loaded = true;
            var catNames = bindsState.categories.map(function (c) { return c.name; });
            if (bindsState.category !== 'Все' && catNames.indexOf(bindsState.category) === -1) {
              bindsState.category = 'Все';
            }
            refreshBinds();
            if (bindsState.selectedTrigger && bindsRefs.previewBody) {
              var sel = null;
              bindsState.binds.forEach(function (bb) {
                if (bb.trigger === bindsState.selectedTrigger) sel = bb;
              });
              if (sel) renderBindPreview(sel);
            }
          }
        } catch (e) {}
      }
    };
    xhr.onerror = function () {
      if (bindsRefs.listBody) {
        bindsRefs.listBody.innerHTML = '';
        bindsRefs.listBody.appendChild(el('div', 'ches-binds-empty', 'Не удалось загрузить бинды'));
      }
    };
    xhr.ontimeout = function () {};
    xhr.send();
  }

  function refreshBinds() {
    if (bindsRefs.toggle) {
      if (bindsState.enabled) bindsRefs.toggle.classList.add('on');
      else bindsRefs.toggle.classList.remove('on');
    }
    if (bindsRefs.catSlot) {
      bindsRefs.catSlot.innerHTML = '';
      var catNames = bindsState.categories.map(function (c) { return c.name; });
      var options = ['Все'].concat(catNames);
      var selIndex = Math.max(0, options.indexOf(bindsState.category));
      var catSel = makeDropdown(options, {
        width: '200px',
        selected: selIndex,
        onSelect: function (i, item) {
          bindsState.category = item;
          renderBindsList();
        }
      });
      bindsRefs.catSlot.appendChild(catSel.box);
    }
    renderBindsCategories();
    renderBindsList();
  }

  function renderBindsCategories() {
    if (!bindsRefs.catBody) return;
    bindsRefs.catBody.innerHTML = '';

    if (!bindsState.categories.length) {
      bindsRefs.catBody.appendChild(el('div', 'ches-binds-empty', 'Категорий пока нет'));
      return;
    }

    bindsState.categories.forEach(function (cat) {
      var row = el('div', 'ches-binds-cat-row' + (cat.enabled ? '' : ' off'));

      var toggle = makeToggle(!!cat.enabled);
      toggle.addEventListener('click', function () {
        setBindCategoryEnabled(cat.name, toggle.classList.contains('on') ? 1 : 0);
      });
      row.appendChild(toggle);

      var nameEl = el('div', 'ches-binds-cat-name', cat.name);
      row.appendChild(nameEl);

      var delBtn = el('div', 'ches-binds-cat-del' + (bindsState.confirmCategory === cat.name ? ' confirm' : ''), '×');
      delBtn.addEventListener('click', function () {
        if (bindsState.confirmCategory === cat.name) {
          bindsState.confirmCategory = '';
          deleteBindCategory(cat.name);
        } else {
          bindsState.confirmCategory = cat.name;
          renderBindsCategories();
        }
      });
      row.appendChild(delBtn);

      if (bindsState.confirmCategory === cat.name) {
        row.appendChild(el('div', 'ches-binds-hint', 'Ещё раз — подтвердить удаление.'));
      }

      bindsRefs.catBody.appendChild(row);
    });
  }

  function renderBindsList() {
    if (!bindsRefs.listBody) return;
    bindsRefs.listBody.innerHTML = '';

    var q = bindsState.search.toLowerCase();
    var rows = bindsState.binds.filter(function (b) {
      if (bindsState.category !== 'Все' && b.category !== bindsState.category) return false;
      if (!q) return true;
      return (String(b.name || '').toLowerCase().indexOf(q) !== -1 ||
              String(b.trigger || '').toLowerCase().indexOf(q) !== -1 ||
              String(b.content || '').toLowerCase().indexOf(q) !== -1);
    });

    if (!rows.length) {
      bindsRefs.listBody.classList.remove('has-rows');
      bindsRefs.listBody.appendChild(el('div', 'ches-binds-empty', 'Бинды не найдены'));
      return;
    }

    bindsRefs.listBody.classList.add('has-rows');
    var cellCols = [
      'ches-binds-col-type',
      'ches-binds-col-cat',
      'ches-binds-col-name',
      'ches-binds-col-trigger',
      'ches-binds-col-status'
    ];
    rows.forEach(function (b) {
      var row = el('div', 'ches-binds-item' + (b.trigger === bindsState.selectedTrigger ? ' sel' : ''));
      var cells = [getBindTypeLabel(b.type), b.category, b.name, b.trigger, getBindStatusText(b)];
      for (var ci = 0; ci < cells.length; ci++) {
        var cell = el('div', 'ches-binds-cell ' + cellCols[ci], cells[ci]);
        if (ci === 4) {
          var dot = el('span', 'ches-binds-status-dot' + (b.runtime === 'Вкл' ? ' on' : (b.runtime === 'Кат. выкл' ? ' catoff' : '')));
          cell.textContent = '';
          cell.appendChild(dot);
          cell.appendChild(document.createTextNode(cells[ci]));
        }
        row.appendChild(cell);
      }
      row.addEventListener('click', function () {
        bindsState.selectedTrigger = b.trigger;
        renderBindsList();
        renderBindPreview(b);
      });
      bindsRefs.listBody.appendChild(row);
    });
  }

  function renderBindPreview(b) {
    if (!bindsRefs.previewBody) return;
    bindsRefs.previewBody.parentNode.classList.remove('empty');
    bindsRefs.previewBody.innerHTML = '';
    bindsRefs.previewBody.style.justifyContent = 'flex-start';
    bindsRefs.previewBody.appendChild(el('div', 'ches-binds-preview-name', b.name || ''));
    bindsRefs.previewBody.appendChild(el('div', 'ches-binds-preview-content', b.content || ''));
    bindsRefs.previewBody.appendChild(el('div', 'ches-binds-preview-meta',
      'Тип: ' + getBindTypeLabel(b.type) +
      '\nКатегория: ' + (b.category || '—') +
      '\nТриггер: ' + (b.trigger || '—') +
      '\nСтатус: ' + getBindStatusText(b)));

    var actions = el('div', 'ches-binds-actions');

    var toggleBtn = el('div', 'ches-binds-btn ' + (b.enabled ? 'warn' : ''), b.enabled ? 'Выключить' : 'Включить');
    toggleBtn.addEventListener('click', function () {
      setBindEnabled([b.trigger], b.enabled ? 0 : 1);
    });
    actions.appendChild(toggleBtn);

    var editBtn = el('div', 'ches-binds-btn', 'Редактировать');
    editBtn.addEventListener('click', function () {
      openBindEditor(b);
    });
    actions.appendChild(editBtn);

    var delBtn = el('div', 'ches-binds-btn danger', 'Удалить');
    delBtn.addEventListener('click', function () {
      if (bindsState.confirmTrigger === b.trigger) {
        bindsState.confirmTrigger = '';
        deleteBinds([b.trigger]);
      } else {
        bindsState.confirmTrigger = b.trigger;
        renderBindPreview(b);
      }
    });
    actions.appendChild(delBtn);

    if (bindsState.confirmTrigger === b.trigger) {
      var confirmEl = el('div', 'ches-binds-hint', 'Нажмите «Удалить» ещё раз для подтверждения.');
      actions.appendChild(confirmEl);
    }

    bindsRefs.previewBody.appendChild(actions);
  }

  function renderBindEditor() {
    var ed = bindsState.editor;

    var wrap = el('div', 'ches-binds-editor');

    var card = el('div', 'ches-binds-editor-card');
    card.appendChild(el('div', 'ches-binds-editor-title', ed.mode === 'edit' ? 'Редактирование бинда' : 'Новый бинд'));

    /* Тип */
    var typeField = el('div', 'ches-binds-field');
    typeField.appendChild(el('div', 'ches-binds-field-label', 'Тип'));
    var typeIdx = ed.type >= 0 && ed.type <= 2 ? ed.type : 0;
    var contentExamples = [
      '/heal',
      'привет, как дела?',
      '/hi /help /start'
    ];
    var contentHint = el('div', 'ches-binds-field-hint', '');
    contentHint.textContent = 'Пример содержимого: ' + (contentExamples[typeIdx] || '');
    var typeSel = makeDropdown(bindTypes, {
      width: '240px',
      selected: typeIdx,
      onSelect: function (i) {
        ed.type = i;
        contentHint.textContent = 'Пример содержимого: ' + (contentExamples[i] || '');
      }
    });
    typeField.appendChild(typeSel.box);
    card.appendChild(typeField);

    /* Категория */
    var catField = el('div', 'ches-binds-field');
    catField.appendChild(el('div', 'ches-binds-field-label', 'Категория'));
    var catOptions = ['Все'].concat(bindsState.categories.map(function (c) { return c.name; }));
    if (catOptions.indexOf(ed.category) === -1 && ed.category) catOptions.unshift(ed.category);
    var catSel = makeDropdown(catOptions, {
      width: '240px',
      selected: Math.max(0, catOptions.indexOf(ed.category)),
      onSelect: function (i, item) {
        ed.category = item;
      }
    });
    catField.appendChild(catSel.box);
    card.appendChild(catField);

    /* Название */
    var nameField = el('div', 'ches-binds-field');
    nameField.appendChild(el('div', 'ches-binds-field-label', 'Название'));
    var nameIn = makeOnishiInput({ width: '240px', value: ed.name });
    nameIn.input.addEventListener('input', function () {
      ed.name = nameIn.input.value;
    });
    nameField.appendChild(nameIn.box);
    card.appendChild(nameField);

    /* Триггер */
    var trigField = el('div', 'ches-binds-field');
    trigField.appendChild(el('div', 'ches-binds-field-label', 'Триггер'));
    var trigIn = makeOnishiInput({ width: '240px', value: ed.trigger });
    trigIn.input.addEventListener('input', function () {
      ed.trigger = trigIn.input.value;
    });
    trigField.appendChild(trigIn.box);
    card.appendChild(trigField);

    /* Содержимое */
    var contentField = el('div', 'ches-binds-field');
    contentField.appendChild(el('div', 'ches-binds-field-label', 'Содержимое'));
    var contentTa = document.createElement('textarea');
    contentTa.className = 'ches-binds-textarea';
    contentTa.value = ed.content || '';
    contentTa.addEventListener('input', function () {
      ed.content = contentTa.value;
    });
    contentField.appendChild(contentTa);
    contentField.appendChild(contentHint);
    card.appendChild(contentField);

    /* Включен */
    var enRow = makeToggleRow('Бинд включён', '', ed.enabled, 'bind');
    var enToggle = enRow.querySelector('.ches-toggle');
    enToggle.addEventListener('click', function () {
      ed.enabled = enToggle.classList.contains('on');
    });
    card.appendChild(enRow);

    /* Ошибка */
    if (ed.error) {
      card.appendChild(el('div', 'ches-binds-error', ed.error));
    }

    /* Кнопки */
    var btns = el('div', 'ches-binds-editor-actions');
    var saveBtn = el('div', 'ches-binds-btn primary', 'Сохранить');
    saveBtn.addEventListener('click', saveBind);
    btns.appendChild(saveBtn);
    var cancelBtn = el('div', 'ches-binds-btn', 'Отмена');
    cancelBtn.addEventListener('click', closeBindEditor);
    btns.appendChild(cancelBtn);
    card.appendChild(btns);

    wrap.appendChild(card);
    return wrap;
  }

  function openBindEditor(bind) {
    var typeIdx = 0;
    var t = String(bind && bind.type || 'hotkey').toLowerCase();
    if (t === 'hotstring') typeIdx = 1;
    else if (t === 'macro') typeIdx = 2;
    bindsState.editor = bind
      ? { mode: 'edit', type: typeIdx, category: bind.category || '', name: bind.name || '', trigger: bind.trigger || '', content: bind.content || '', enabled: !!bind.enabled, originalTrigger: bind.trigger || '' }
      : { mode: 'new', type: typeIdx, category: (bindsState.categories.length ? bindsState.categories[0].name : ''), name: '', trigger: '', content: '', enabled: true, originalTrigger: '' };
    renderBinds();
  }

  function closeBindEditor() {
    bindsState.editor = null;
    bindsState.confirmTrigger = '';
    renderBinds();
  }

  function saveBind() {
    var ed = bindsState.editor;
    if (!ed) return;

    var type = bindTypeValues[ed.type] || 'hotkey';
    var category = String(ed.category || '').trim();
    var name = String(ed.name || '').trim();
    var trigger = String(ed.trigger || '').trim();
    var content = String(ed.content || '');
    var enabled = ed.enabled ? 1 : 0;

    if (!category || !name || !trigger || !content.trim()) {
      bindsState.editor.error = 'Заполните все поля: категория, название, триггер и содержимое.';
      renderBinds();
      return;
    }

    var params = []
      .concat(['type=' + encodeURIComponent(type)])
      .concat(['category=' + encodeURIComponent(category)])
      .concat(['name=' + encodeURIComponent(name)])
      .concat(['trigger=' + encodeURIComponent(trigger)])
      .concat(['content=' + encodeURIComponent(content)])
      .concat(['enabled=' + enabled])
      .concat(['originalTrigger=' + encodeURIComponent(ed.originalTrigger || '')])
      .join('&');

    var xhr = new XMLHttpRequest();
    xhr.open('GET', BINDS_SAVE_URL + '?' + params, true);
    xhr.timeout = 1500;
    xhr.onload = function () {
      bindsState.editor = null;
      bindsState.confirmTrigger = '';
      setTimeout(function () { renderBinds(); }, 300);
    };
    xhr.onerror = function () {
      bindsState.editor = null;
      setTimeout(function () { renderBinds(); }, 300);
    };
    xhr.ontimeout = function () {};
    xhr.send();
  }

  function deleteBinds(triggers) {
    if (!triggers || !triggers.length) return;
    var xhr = new XMLHttpRequest();
    xhr.open('GET', BINDS_DELETE_URL + '?triggers=' + encodeURIComponent(triggers.join(',')), true);
    xhr.timeout = 1500;
    xhr.onload = function () {
      bindsState.selectedTrigger = '';
      bindsState.confirmTrigger = '';
      if (bindsRefs.previewBody) {
        bindsRefs.previewBody.innerHTML = '';
        bindsRefs.previewBody.style.justifyContent = '';
        bindsRefs.previewBody.appendChild(el('div', 'ches-binds-empty', 'Выберите бинд в списке'));
        bindsRefs.previewBody.parentNode.classList.add('empty');
      }
      setTimeout(function () { loadBinds(); }, 300);
    };
    xhr.onerror = function () {};
    xhr.ontimeout = function () {};
    xhr.send();
  }

  function setBindEnabled(triggers, enabled) {
    if (!triggers || !triggers.length) return;
    var xhr = new XMLHttpRequest();
    xhr.open('GET', BINDS_ENABLE_URL + '?triggers=' + encodeURIComponent(triggers.join(',')) + '&enabled=' + (enabled ? 1 : 0), true);
    xhr.timeout = 1500;
    xhr.onload = function () {
      setTimeout(function () { loadBinds(); }, 300);
    };
    xhr.onerror = function () {};
    xhr.ontimeout = function () {};
    xhr.send();
  }

  function toggleBindsAll(enabled) {
    var xhr = new XMLHttpRequest();
    xhr.open('GET', BINDS_TOGGLE_URL + '?enabled=' + (enabled ? 1 : 0), true);
    xhr.timeout = 1500;
    xhr.onload = function () {
      setTimeout(function () { loadBinds(); }, 300);
    };
    xhr.onerror = function () { loadBinds(); };
    xhr.ontimeout = function () { loadBinds(); };
    xhr.send();
  }

  function addBindCategory(name) {
    name = String(name || '').trim();
    if (!name) return;
    var xhr = new XMLHttpRequest();
    xhr.open('GET', BINDS_CATEGORY_ADD_URL + '?name=' + encodeURIComponent(name), true);
    xhr.timeout = 1500;
    xhr.onload = function () {
      setTimeout(function () { loadBinds(); }, 300);
    };
    xhr.onerror = function () {};
    xhr.ontimeout = function () {};
    xhr.send();
  }

  function setBindCategoryEnabled(name, enabled) {
    if (!name) return;
    var xhr = new XMLHttpRequest();
    xhr.open('GET', BINDS_CATEGORY_TOGGLE_URL + '?name=' + encodeURIComponent(name) + '&enabled=' + (enabled ? 1 : 0), true);
    xhr.timeout = 1500;
    xhr.onload = function () {
      setTimeout(function () { loadBinds(); }, 300);
    };
    xhr.onerror = function () {};
    xhr.ontimeout = function () {};
    xhr.send();
  }

  function deleteBindCategory(name) {
    if (!name) return;
    var xhr = new XMLHttpRequest();
    xhr.open('GET', BINDS_CATEGORY_DELETE_URL + '?name=' + encodeURIComponent(name), true);
    xhr.timeout = 1500;
    xhr.onload = function () {
      setTimeout(function () { loadBinds(); }, 300);
    };
    xhr.onerror = function () {};
    xhr.ontimeout = function () {};
    xhr.send();
  }

  function openBindImport() {
    if (!bindsRefs.previewBody) return;
    bindsState.selectedTrigger = '';
    bindsRefs.previewBody.parentNode.classList.remove('empty');
    bindsRefs.previewBody.innerHTML = '';
    bindsRefs.previewBody.style.justifyContent = 'flex-start';
    bindsRefs.previewBody.appendChild(el('div', 'ches-binds-preview-content',
      'Вставьте JSON с биндами и нажмите «Импортировать». Формат: {"binds":[{"type":"hotkey","category":"Бой","name":"Аптечка","trigger":"F1","content":"/heal","enabled":true}]}'));

    var ta = document.createElement('textarea');
    ta.className = 'ches-binds-textarea';
    ta.style.minHeight = '120px';
    bindsRefs.previewBody.appendChild(ta);

    var actions = el('div', 'ches-binds-actions');
    var doBtn = el('div', 'ches-binds-btn primary', 'Импортировать');
    doBtn.addEventListener('click', function () {
      importBinds(ta.value);
    });
    actions.appendChild(doBtn);
    var cancelBtn = el('div', 'ches-binds-btn', 'Отмена');
    cancelBtn.addEventListener('click', function () {
      bindsRefs.previewBody.innerHTML = '';
      bindsRefs.previewBody.style.justifyContent = '';
      bindsRefs.previewBody.appendChild(el('div', 'ches-binds-empty', 'Выберите бинд в списке'));
      bindsRefs.previewBody.parentNode.classList.add('empty');
    });
    actions.appendChild(cancelBtn);
    bindsRefs.previewBody.appendChild(actions);
  }

  function importBinds(text) {
    var data = null;
    try {
      data = JSON.parse(text);
    } catch (e) {
      if (bindsRefs.previewBody) {
        bindsRefs.previewBody.innerHTML = '';
        bindsRefs.previewBody.appendChild(el('div', 'ches-binds-error', 'Ошибка JSON: ' + e.message));
      }
      return;
    }
    var arr = Array.isArray(data) ? data : (data && Array.isArray(data.binds) ? data.binds : null);
    if (!arr || !arr.length) {
      if (bindsRefs.previewBody) {
        bindsRefs.previewBody.innerHTML = '';
        bindsRefs.previewBody.appendChild(el('div', 'ches-binds-error', 'В JSON нет биндов.'));
      }
      return;
    }

    var queue = [];
    arr.forEach(function (b) {
      var category = String(b.category || '').trim();
      if (category && category !== 'Все') {
        var known = bindsState.categories.some(function (c) { return c.name === category; });
        if (!known && queue.indexOf('cat:' + category) === -1) queue.push('cat:' + category);
      }
    });
    arr.forEach(function (b) {
      queue.push(b);
    });

    var idx = 0;
    function next() {
      if (idx >= queue.length) {
        bindsState.selectedTrigger = '';
        setTimeout(function () { loadBinds(); }, 300);
        return;
      }
      var item = queue[idx++];
      if (typeof item === 'string' && item.indexOf('cat:') === 0) {
        addBindCategory(item.slice(4));
        setTimeout(next, 350);
        return;
      }
      var b = item;
      var type = String(b.type || 'hotkey').toLowerCase();
      if (['hotkey', 'hotstring', 'macro'].indexOf(type) === -1) type = 'hotkey';
      var params = []
        .concat(['type=' + encodeURIComponent(type)])
        .concat(['category=' + encodeURIComponent(String(b.category || 'Все').trim())])
        .concat(['name=' + encodeURIComponent(String(b.name || '').trim())])
        .concat(['trigger=' + encodeURIComponent(String(b.trigger || '').trim())])
        .concat(['content=' + encodeURIComponent(String(b.content || ''))])
        .concat(['enabled=' + (b.enabled ? 1 : 0)])
        .concat(['originalTrigger='])
        .join('&');
      var xhr = new XMLHttpRequest();
      xhr.open('GET', BINDS_SAVE_URL + '?' + params, true);
      xhr.timeout = 1500;
      xhr.onload = function () { setTimeout(next, 350); };
      xhr.onerror = function () { setTimeout(next, 350); };
      xhr.ontimeout = function () { setTimeout(next, 350); };
      xhr.send();
    }
    next();
  }

  function exportBinds() {
    var payload = bindsState.binds.map(function (b) {
      return {
        type: b.type,
        category: b.category,
        name: b.name,
        trigger: b.trigger,
        content: b.content,
        enabled: b.enabled
      };
    });
    var text = JSON.stringify({ binds: payload }, null, 2);

    if (!bindsRefs.previewBody) return;
    bindsState.selectedTrigger = '';
    bindsRefs.previewBody.innerHTML = '';
    bindsRefs.previewBody.style.justifyContent = 'flex-start';
    bindsRefs.previewBody.appendChild(el('div', 'ches-binds-preview-content',
      'Скопируйте JSON ниже (Ctrl+C), либо нажмите «Копировать»:'));

    var ta = document.createElement('textarea');
    ta.className = 'ches-binds-textarea';
    ta.style.minHeight = '120px';
    ta.value = text;
    ta.readOnly = true;
    bindsRefs.previewBody.appendChild(ta);

    var actions = el('div', 'ches-binds-actions');
    var copyBtn = el('div', 'ches-binds-btn primary', 'Копировать');
    copyBtn.addEventListener('click', function () {
      ta.select();
      try {
        document.execCommand('copy');
      } catch (e) {}
      copyBtn.textContent = 'Скопировано ✓';
    });
    actions.appendChild(copyBtn);
    bindsRefs.previewBody.appendChild(actions);
  }

  function showBindDuplicates() {
    if (!bindsRefs.previewBody) return;
    var seen = {};
    var dups = [];
    bindsState.binds.forEach(function (b) {
      var key = String(b.trigger || '').toLowerCase();
      if (!key) return;
      if (seen[key]) {
        if (!seen[key].marked) {
          seen[key].marked = true;
          dups.push(seen[key].bind);
        }
        dups.push(b);
      } else {
        seen[key] = { marked: false, bind: b };
      }
    });

    bindsState.selectedTrigger = '';
    bindsRefs.previewBody.parentNode.classList.remove('empty');
    bindsRefs.previewBody.innerHTML = '';
    bindsRefs.previewBody.style.justifyContent = 'flex-start';

    if (!dups.length) {
      bindsRefs.previewBody.appendChild(el('div', 'ches-binds-preview-content', 'Дубликатов не найдено'));
      return;
    }

    bindsRefs.previewBody.appendChild(el('div', 'ches-binds-preview-content',
      'Найдено дубликатов: ' + dups.length + ' (одинаковый триггер)'));

    var byTrigger = {};
    dups.forEach(function (b) {
      var key = String(b.trigger || '').toLowerCase();
      if (!byTrigger[key]) byTrigger[key] = [];
      byTrigger[key].push(b);
    });
    Object.keys(byTrigger).forEach(function (key) {
      var block = el('div', 'ches-binds-dup');
      block.appendChild(el('div', 'ches-binds-dup-trigger', 'Триггер: ' + byTrigger[key][0].trigger));
      byTrigger[key].forEach(function (b) {
        block.appendChild(el('div', 'ches-binds-dup-item',
          getBindTypeLabel(b.type) + ' · ' + (b.category || '—') + ' · ' + (b.name || '—')));
      });
      bindsRefs.previewBody.appendChild(block);
    });
  }

  function renderScripts() {
    clearBody();

    var wrap = el('div', 'ches-scripts');

    /* Список пакетов */
    var list = el('div', 'ches-scripts-list');
    scriptsRefs.list = list;
    wrap.appendChild(list);

    contentBodyEl.appendChild(wrap);

    loadScripts();
  }

  function loadScripts() {
    var xhr = new XMLHttpRequest();
    xhr.open('GET', SCRIPTS_URL, true);
    xhr.timeout = 1500;
    xhr.onload = function () {
      if (xhr.status >= 200 && xhr.status < 300) {
        try {
          var d = JSON.parse(xhr.responseText);
          if (d && Array.isArray(d.packages)) {
            scriptsState.packages = d.packages;
            scriptsState.loaded = true;
            refreshScripts();
          }
        } catch (e) {}
      }
    };
    xhr.onerror = function () {};
    xhr.ontimeout = function () {};
    xhr.send();
  }

  function refreshScripts() {
    if (!scriptsRefs.list) return;

    scriptsRefs.list.innerHTML = '';
    if (!scriptsState.packages.length) {
      scriptsRefs.list.appendChild(el('div', 'ches-scripts-empty', 'Загрузка…'));
      return;
    }
    scriptsState.packages.forEach(function (p) {
      var item = el('div', 'ches-scripts-item');
      var info = el('div', 'ches-scripts-info');
      info.appendChild(el('div', 'ches-scripts-name', p.title || ''));
      info.appendChild(el('div', 'ches-scripts-meta', p.author ? ('Автор: ' + p.author) : ''));
      var statusText = String(p.status || '').replace(/^[●•✓✔☑○]\s*/, '');
      info.appendChild(el('div', 'ches-scripts-status ' + (p.installed ? 'ok' : 'no'), statusText));
      item.appendChild(info);

      var actions = el('div', 'ches-scripts-actions');
      var infoBtn = el('div', 'ches-scripts-btn info', 'Инфо');
      infoBtn.addEventListener('click', function () {
        showScriptInfo(p);
      });
      actions.appendChild(infoBtn);
      var installBtn = el('div', 'ches-scripts-btn install' + (p.installed ? ' done' : ''), p.installed ? 'Установлен' : 'Установить');
      installBtn.addEventListener('click', function () {
        if (p.installed) return;
        installScript(p.id, installBtn);
      });
      actions.appendChild(installBtn);
      item.appendChild(actions);
      scriptsRefs.list.appendChild(item);
    });
  }

  function ensureScriptInfoModal() {
    if (scriptsRefs.modal) return scriptsRefs.modal;
    if (!document.body) return null;
    var modal = el('div', 'ches-scripts-modal hidden');
    var box = el('div', 'ches-scripts-modal-box');
    modal.appendChild(box);
    modal.addEventListener('click', function (e) {
      if (e.target === modal) hideScriptInfo();
    });
    document.body.appendChild(modal);
    scriptsRefs.modal = modal;
    scriptsRefs.modalBox = box;
    return modal;
  }

  function hideScriptInfo() {
    if (scriptsRefs.modal) scriptsRefs.modal.classList.add('hidden');
  }

  function showScriptInfo(p) {
    ensureScriptInfoModal();
    if (!scriptsRefs.modalBox) return;
    var box = scriptsRefs.modalBox;
    box.innerHTML = '';

    var info = (p && p.id && SCRIPT_INFO[p.id]) ? SCRIPT_INFO[p.id] : null;
    var title = (info && info.title) || p.title || p.id || 'Скрипт';
    var bodyText = (info && info.body) || p.description || p.note || '';
    var link = p.topic || '';

    box.appendChild(el('div', 'ches-scripts-modal-title', title));

    function addBlock(label, value, isLink) {
      if (!value) return;
      var row = el('div', 'ches-scripts-modal-row');
      if (label) row.appendChild(el('div', 'ches-scripts-modal-label', label));
      if (isLink) {
        var a = el('div', 'ches-scripts-link', value);
        a.style.maxWidth = '100%';
        a.style.whiteSpace = 'normal';
        a.style.wordBreak = 'break-all';
        a.addEventListener('click', function () {
          openScriptTopic(value);
        });
        row.appendChild(a);
      } else {
        var body = el('div', null, value);
        body.style.whiteSpace = 'pre-wrap';
        row.appendChild(body);
      }
      box.appendChild(row);
    }

    addBlock('', bodyText);
    addBlock('Ссылка', link, true);

    var closeBtn = el('div', 'ches-scripts-btn primary ches-scripts-modal-close', 'Закрыть');
    closeBtn.addEventListener('click', hideScriptInfo);
    box.appendChild(closeBtn);

    scriptsRefs.modal.classList.remove('hidden');
  }

  function installScript(id, btn) {
    btn.className = 'ches-scripts-btn install';
    btn.textContent = 'Установка…';
    var xhr = new XMLHttpRequest();
    xhr.open('GET', SCRIPTS_INSTALL_URL + '?id=' + encodeURIComponent(id), true);
    /* Мост только ставит команду; сама установка идёт в AHK и может занять несколько секунд */
    xhr.timeout = 8000;
    xhr.onload = function () {
      setTimeout(function () { loadScripts(); }, 2500);
    };
    xhr.onerror = function () {
      btn.textContent = 'Ошибка';
      setTimeout(function () { loadScripts(); }, 2000);
    };
    xhr.ontimeout = function () {
      /* Таймаут XHR ≠ провал установки: команда могла уйти, ждём статус */
      setTimeout(function () { loadScripts(); }, 3000);
    };
    xhr.send();
  }

  function openScriptTopic(url) {
    var xhr = new XMLHttpRequest();
    xhr.open('GET', SCRIPTS_TOPIC_URL + '?url=' + encodeURIComponent(url), true);
    xhr.timeout = 1500;
    xhr.onload = function () {};
    xhr.onerror = function () {};
    xhr.ontimeout = function () {};
    xhr.send();
  }

  function renderTester() {
    clearBody();

    var wrap = el('div', 'ches-tester');
    wrap.appendChild(el('div', 'ches-tester-desc', 'Тестовые сборки с GitHub. Включи режим, чтобы проверять и скачивать beta-версии.'));

    /* Карточка: режим тестировщика */
    var modeCard = el('div', 'ches-tester-card');
    var modeToggle = makeToggleRow('Я тестировщик', 'Показывать тестовый канал', testerState.enabled);
    testerRefs.toggle = modeToggle.querySelector('.ches-toggle');
    testerRefs.toggle.addEventListener('click', function () {
      toggleTesterMode(testerRefs.toggle.classList.contains('on') ? 1 : 0);
    });
    modeCard.appendChild(modeToggle);
    var modeStatus = el('div', 'ches-tester-status ' + (testerState.enabled ? 'ok' : 'off'),
      testerState.enabled ? 'Режим тестировщика включён' : 'Режим выключен — тестовые сборки недоступны');
    testerRefs.statusEl = modeStatus;
    modeCard.appendChild(modeStatus);
    wrap.appendChild(modeCard);

    /* Карточка: тестовый канал */
    var channelCard = el('div', 'ches-tester-card');
    channelCard.appendChild(el('div', 'ches-tester-title', 'Тестовый канал'));
    var info = el('div', 'ches-tester-info empty',
      testerState.enabled
        ? 'Нажми «Проверить», чтобы загрузить информацию о тестовой версии.'
        : 'Включи «Я тестировщик», затем нажми «Проверить».');
    testerRefs.infoEl = info;
    channelCard.appendChild(info);
    var chToolbar = el('div', 'ches-tester-toolbar');
    var checkBtn = el('div', 'ches-tester-btn accent', 'Проверить');
    testerRefs.btnCheck = checkBtn;
    checkBtn.addEventListener('click', function () {
      checkTestUpdates();
    });
    chToolbar.appendChild(checkBtn);
    var downloadBtn = el('div', 'ches-tester-btn', 'Ссылка');
    testerRefs.btnDownload = downloadBtn;
    downloadBtn.addEventListener('click', function () {
      downloadTestUpdate();
    });
    chToolbar.appendChild(downloadBtn);
    var installBtn = el('div', 'ches-tester-btn', 'Установить Beta test');
    testerRefs.btnInstall = installBtn;
    installBtn.addEventListener('click', function () {
      installTestUpdate(installBtn);
    });
    chToolbar.appendChild(installBtn);
    channelCard.appendChild(chToolbar);
    wrap.appendChild(channelCard);

    /* Карточка: стабильный релиз */
    var stableCard = el('div', 'ches-tester-card');
    stableCard.appendChild(el('div', 'ches-tester-title', 'Стабильный релиз'));
    var stableRow = el('div', 'ches-tester-toolbar');
    stableRow.appendChild(el('div', 'ches-tester-desc', 'Вернуть официальную сборку'));
    var rollbackBtn = el('div', 'ches-tester-btn accent', 'Откат на релиз');
    testerRefs.btnRollback = rollbackBtn;
    rollbackBtn.addEventListener('click', function () {
      rollbackStableRelease(rollbackBtn);
    });
    stableRow.appendChild(rollbackBtn);
    stableCard.appendChild(stableRow);
    wrap.appendChild(stableCard);


    contentBodyEl.appendChild(wrap);

    loadTester();
  }

  function loadTester() {
    var xhr = new XMLHttpRequest();
    xhr.open('GET', TESTER_URL, true);
    xhr.timeout = 1500;
    xhr.onload = function () {
      if (xhr.status >= 200 && xhr.status < 300) {
        try {
          var d = JSON.parse(xhr.responseText);
          if (d && d.ok) {
            testerState.enabled = !!d.enabled;
            testerState.version = d.version || '';
            testerState.info = d.info || '';
            testerState.loaded = true;
            refreshTester();
          }
        } catch (e) {}
      }
    };
    xhr.onerror = function () {};
    xhr.ontimeout = function () {};
    xhr.send();
  }

  function refreshTester() {
    updateBetaBadge(testerState.enabled);
    if (testerRefs.toggle) {
      testerRefs.toggle.classList.toggle('on', testerState.enabled);
    }
    if (testerRefs.statusEl) {
      testerRefs.statusEl.className = 'ches-tester-status ' + (testerState.enabled ? 'ok' : 'off');
      testerRefs.statusEl.textContent = testerState.enabled
        ? 'Режим тестировщика включён'
        : 'Режим выключен — тестовые сборки недоступны';
    }
    if (testerRefs.infoEl) {
      testerRefs.infoEl.className = 'ches-tester-info' + (testerState.info ? '' : ' empty');
      testerRefs.infoEl.textContent = testerState.info || (testerState.enabled
        ? 'Нажми «Проверить», чтобы загрузить информацию о тестовой версии.'
        : 'Включи «Я тестировщик», затем нажми «Проверить».');
    }
    if (testerRefs.btnDownload) {
      testerRefs.btnDownload.className = 'ches-tester-btn' + (testerState.enabled ? '' : ' disabled');
    }
    if (testerRefs.btnInstall) {
      testerRefs.btnInstall.className = 'ches-tester-btn' + (testerState.enabled ? '' : ' disabled');
    }
    if (testerRefs.btnRollback) {
      testerRefs.btnRollback.className = 'ches-tester-btn accent' + (testerState.enabled ? '' : ' disabled');
    }
  }

  function toggleTesterMode(enabled) {
    testerState.enabled = !!enabled;
    updateBetaBadge(testerState.enabled);
    var xhr = new XMLHttpRequest();
    xhr.open('GET', TESTER_TOGGLE_URL + '?enabled=' + (enabled ? 1 : 0), true);
    xhr.timeout = 1500;
    xhr.onload = function () {
      setTimeout(function () { loadTester(); }, 400);
    };
    xhr.onerror = function () {};
    xhr.ontimeout = function () {};
    xhr.send();
  }

  function checkTestUpdates() {
    if (!testerState.enabled) return;
    var xhr = new XMLHttpRequest();
    xhr.open('GET', TESTER_CHECK_URL, true);
    xhr.timeout = 3000;
    xhr.onload = function () {
      setTimeout(function () { loadTester(); }, 1500);
    };
    xhr.onerror = function () {};
    xhr.ontimeout = function () {};
    xhr.send();
  }

  function downloadTestUpdate() {
    if (!testerState.enabled) return;
    var xhr = new XMLHttpRequest();
    xhr.open('GET', TESTER_DOWNLOAD_URL, true);
    xhr.timeout = 3000;
    xhr.onload = function () {};
    xhr.onerror = function () {};
    xhr.ontimeout = function () {};
    xhr.send();
  }

  function installTestUpdate(btn) {
    if (!testerState.enabled) return;
    if (testerRefs.confirm !== 'install') {
      testerRefs.confirm = 'install';
      btn.textContent = 'Ещё раз для подтверждения';
      btn.className = 'ches-tester-btn confirm';
      setTimeout(function () {
        if (testerRefs.confirm === 'install') {
          testerRefs.confirm = '';
          btn.textContent = 'Установить Beta test';
          btn.className = 'ches-tester-btn' + (testerState.enabled ? '' : ' disabled');
        }
      }, 4000);
      return;
    }
    testerRefs.confirm = '';
    btn.textContent = 'Установка…';
    var xhr = new XMLHttpRequest();
    xhr.open('GET', TESTER_INSTALL_URL, true);
    xhr.timeout = 30000;
    xhr.onload = function () {
      setTimeout(function () { loadTester(); }, 800);
    };
    xhr.onerror = function () {
      btn.textContent = 'Установить Beta test';
    };
    xhr.ontimeout = function () {
      btn.textContent = 'Установить Beta test';
    };
    xhr.send();
  }

  function rollbackStableRelease(btn) {
    if (!testerState.enabled) return;
    if (testerRefs.confirm !== 'rollback') {
      testerRefs.confirm = 'rollback';
      btn.textContent = 'Ещё раз для подтверждения';
      btn.className = 'ches-tester-btn accent confirm';
      setTimeout(function () {
        if (testerRefs.confirm === 'rollback') {
          testerRefs.confirm = '';
          btn.textContent = 'Откат на релиз';
          btn.className = 'ches-tester-btn accent' + (testerState.enabled ? '' : ' disabled');
        }
      }, 4000);
      return;
    }
    testerRefs.confirm = '';
    btn.textContent = 'Откат…';
    var xhr = new XMLHttpRequest();
    xhr.open('GET', TESTER_ROLLBACK_URL, true);
    xhr.timeout = 30000;
    xhr.onload = function () {
      setTimeout(function () { loadTester(); }, 800);
    };
    xhr.onerror = function () {
      btn.textContent = 'Откат на релиз';
    };
    xhr.ontimeout = function () {
      btn.textContent = 'Откат на релиз';
    };
    xhr.send();
  }

  function renderUpdates() {
    clearBody();

    var wrap = el('div', 'ches-updates');

    /* Карточка: версия */
    var versionCard = el('div', 'ches-updates-card');
    var versionTitle = el('div', 'ches-updates-title', 'ChesNova v' + (updatesState.version || '—'));
    updatesRefs.versionTitle = versionTitle;
    versionCard.appendChild(versionTitle);
    versionCard.appendChild(el('div', 'ches-updates-desc', 'Проверяйте новые версии и управляйте обновлением приложения.'));
    var checkToggle = makeToggleRow('Проверять обновления при запуске', '', updatesState.checkOnStartup);
    updatesRefs.toggle = checkToggle.querySelector('.ches-toggle');
    updatesRefs.toggle.addEventListener('click', function () {
      saveUpdatesSettings(updatesRefs.toggle.classList.contains('on') ? 1 : 0);
    });
    versionCard.appendChild(checkToggle);
    wrap.appendChild(versionCard);

    /* Карточка: статус */
    var statusCard = el('div', 'ches-updates-card');
    var statusLine = el('div', 'ches-updates-desc', updatesState.message || 'Загрузка…');
    updatesRefs.statusEl = statusLine;
    statusCard.appendChild(statusLine);
    if (updatesState.lastCheck) {
      statusCard.appendChild(el('div', 'ches-updates-desc', 'Последняя проверка: ' + updatesState.lastCheck));
    }
    if (updatesState.hasUpdate && updatesState.changelog.length) {
      var clTitle = el('div', 'ches-updates-title', 'Что нового в v' + updatesState.latest);
      clTitle.style.marginTop = '10px';
      statusCard.appendChild(clTitle);
      var clBody = el('div', 'ches-updates-desc');
      updatesState.changelog.forEach(function (entry) {
        clBody.appendChild(el('div', null, '• ' + entry));
      });
      statusCard.appendChild(clBody);
    }
    wrap.appendChild(statusCard);

    /* Карточка: действия */
    var actionsCard = el('div', 'ches-updates-card');
    actionsCard.appendChild(el('div', 'ches-updates-title', 'Действия с обновлением'));
    var actToolbar = el('div', 'ches-updates-toolbar');
    var checkBtn = el('div', 'ches-updates-btn primary', 'Проверить обновления');
    updatesRefs.checkBtn = checkBtn;
    checkBtn.addEventListener('click', function () {
      checkUpdates();
    });
    actToolbar.appendChild(checkBtn);
    var installBtn = el('div', 'ches-updates-btn', 'Обновить ChesNova');
    updatesRefs.installBtn = installBtn;
    installBtn.addEventListener('click', function () {
      installUpdate(installBtn);
    });
    actToolbar.appendChild(installBtn);
    var dlBtn = el('div', 'ches-updates-btn', 'Скачать последнюю версию');
    updatesRefs.dlBtn = dlBtn;
    dlBtn.addEventListener('click', function () {
      downloadUpdate();
    });
    actToolbar.appendChild(dlBtn);
    actionsCard.appendChild(actToolbar);
    wrap.appendChild(actionsCard);

    contentBodyEl.appendChild(wrap);

    loadUpdates();
  }

  function loadUpdates() {
    var xhr = new XMLHttpRequest();
    xhr.open('GET', UPDATES_URL, true);
    xhr.timeout = 1500;
    xhr.onload = function () {
      if (xhr.status >= 200 && xhr.status < 300) {
        try {
          var d = JSON.parse(xhr.responseText);
          if (d && d.ok) {
            updatesState.version = d.version || '';
            updatesState.latest = d.latest || '';
            updatesState.hasUpdate = !!d.hasUpdate;
            updatesState.required = !!d.required;
            updatesState.changelog = Array.isArray(d.changelog) ? d.changelog : [];
            updatesState.download = d.download || '';
            updatesState.checkOnStartup = !!d.checkOnStartup;
            updatesState.lastCheck = d.lastCheck || '';
            updatesState.message = d.message || '';
            updatesState.loaded = true;
            refreshUpdates();
          }
        } catch (e) {}
      }
    };
    xhr.onerror = function () {};
    xhr.ontimeout = function () {};
    xhr.send();
  }

  function refreshUpdates() {
    if (updatesRefs.versionTitle) {
      updatesRefs.versionTitle.textContent = 'ChesNova v' + (updatesState.version || '—');
    }
    if (updatesRefs.toggle) {
      if (updatesState.checkOnStartup) updatesRefs.toggle.classList.add('on');
      else updatesRefs.toggle.classList.remove('on');
    }
    if (updatesRefs.statusEl) {
      updatesRefs.statusEl.textContent = updatesState.message || 'Статус неизвестен';
    }
    if (updatesRefs.checkBtn) updatesRefs.checkBtn.textContent = 'Проверить обновления';
    if (updatesRefs.installBtn) updatesRefs.installBtn.textContent = 'Обновить ChesNova';
  }

  function saveUpdatesSettings(enabled) {
    var xhr = new XMLHttpRequest();
    xhr.open('GET', UPDATES_SAVE_URL + '?checkOnStartup=' + (enabled ? 1 : 0), true);
    xhr.timeout = 1500;
    xhr.onload = function () {};
    xhr.onerror = function () {};
    xhr.ontimeout = function () {};
    xhr.send();
  }

  function checkUpdates() {
    var btn = updatesRefs.checkBtn;
    if (btn) btn.textContent = 'Проверка…';
    var xhr = new XMLHttpRequest();
    xhr.open('GET', UPDATES_CHECK_URL, true);
    xhr.timeout = 15000;
    xhr.onload = function () {
      setTimeout(function () { loadUpdates(); }, 1500);
    };
    xhr.onerror = function () {
      if (btn) btn.textContent = 'Проверить обновления';
    };
    xhr.ontimeout = function () {
      if (btn) btn.textContent = 'Проверить обновления';
    };
    xhr.send();
  }

  function downloadUpdate() {
    var xhr = new XMLHttpRequest();
    xhr.open('GET', UPDATES_DOWNLOAD_URL, true);
    xhr.timeout = 15000;
    xhr.onload = function () {};
    xhr.onerror = function () {};
    xhr.ontimeout = function () {};
    xhr.send();
  }

  function installUpdate(btn) {
    if (updatesRefs.confirm !== 'install') {
      updatesRefs.confirm = 'install';
      btn.textContent = 'Ещё раз для подтверждения';
      btn.className = 'ches-updates-btn confirm';
      setTimeout(function () {
        if (updatesRefs.confirm === 'install') {
          updatesRefs.confirm = '';
          btn.textContent = 'Обновить ChesNova';
          btn.className = 'ches-updates-btn';
        }
      }, 4000);
      return;
    }
    updatesRefs.confirm = '';
    btn.textContent = 'Обновление…';
    var xhr = new XMLHttpRequest();
    xhr.open('GET', UPDATES_INSTALL_URL, true);
    xhr.timeout = 60000;
    xhr.onload = function () {
      setTimeout(function () { loadUpdates(); }, 800);
    };
    xhr.onerror = function () {
      btn.textContent = 'Обновить ChesNova';
    };
    xhr.ontimeout = function () {
      btn.textContent = 'Обновить ChesNova';
    };
    xhr.send();
  }

  function renderNotifications() {
    clearBody();

    var wrap = el('div', 'ches-notif');

    var head = el('div', 'ches-notif-head');
    head.appendChild(el('div', 'ches-notif-title', 'Уведомления'));
    var refreshBtn = el('div', 'ches-notif-btn', 'Обновить');
    notificationsRefs.refreshBtn = refreshBtn;
    refreshBtn.addEventListener('click', function () {
      loadNotifications();
    });
    head.appendChild(refreshBtn);
    var readBtn = el('div', 'ches-notif-btn', 'Прочитать все');
    notificationsRefs.readBtn = readBtn;
    readBtn.addEventListener('click', function () {
      markNotificationsRead();
    });
    head.appendChild(readBtn);
    wrap.appendChild(head);

    var list = el('div', 'ches-notif-list');
    notificationsRefs.list = list;
    wrap.appendChild(list);

    contentBodyEl.appendChild(wrap);

    loadNotifications();
  }

  function loadNotifications() {
    if (notificationsRefs.list) {
      notificationsRefs.list.innerHTML = '';
      notificationsRefs.list.appendChild(el('div', 'ches-notif-empty', 'Загрузка…'));
    }
    var xhr = new XMLHttpRequest();
    xhr.open('GET', NOTIFICATIONS_URL, true);
    xhr.timeout = 1500;
    xhr.onload = function () {
      if (xhr.status >= 200 && xhr.status < 300) {
        try {
          var d = JSON.parse(xhr.responseText);
          if (d && d.ok) {
            notificationsList = Array.isArray(d.items) ? d.items : [];
            var unread = notificationsList.filter(function (n) { return !n.read; }).length;
            notificationsCount = unread;
            updateNotifBadge();
            renderNotificationsList();
            return;
          }
        } catch (e) {}
      }
      renderNotificationsList();
    };
    xhr.onerror = function () { renderNotificationsList(); };
    xhr.ontimeout = function () { renderNotificationsList(); };
    xhr.send();
  }

  function renderNotificationsList() {
    if (!notificationsRefs.list) return;
    var list = notificationsRefs.list;
    list.innerHTML = '';
    if (notificationsList.length === 0) {
      list.appendChild(el('div', 'ches-notif-empty', 'Уведомлений пока нет'));
      return;
    }
    notificationsList.forEach(function (n) {
      var item = el('div', 'ches-notif-item' + (n.read ? ' read' : ''));
      item.appendChild(el('div', 'ches-notif-dot ' + (n.type || 'info')));
      item.appendChild(el('div', 'ches-notif-text', n.text));
      item.appendChild(el('div', 'ches-notif-time', n.time || ''));
      list.appendChild(item);
    });
  }

  function pollNotifications() {
    var xhr = new XMLHttpRequest();
    xhr.open('GET', NOTIFICATIONS_URL, true);
    xhr.timeout = 1500;
    xhr.onload = function () {
      if (xhr.status < 200 || xhr.status >= 300) return;
      try {
        var d = JSON.parse(xhr.responseText);
        if (!d || !d.ok) return;
        var items = Array.isArray(d.items) ? d.items : [];
        var unread = items.filter(function (n) { return !n.read; }).length;
        if (unread !== notificationsCount) {
          notificationsCount = unread;
        }
        updateNotifBadge();
      } catch (e) {}
    };
    xhr.onerror = function () {};
    xhr.ontimeout = function () {};
    xhr.send();
  }

  function markNotificationsRead() {
    var xhr = new XMLHttpRequest();
    xhr.open('GET', NOTIFICATIONS_READ_URL, true);
    xhr.timeout = 1500;
    xhr.onload = function () {
      setTimeout(function () { loadNotifications(); }, 400);
    };
    xhr.onerror = function () {};
    xhr.ontimeout = function () {};
    xhr.send();
  }

  function renderHelp() {
    clearBody();

    var wrap = el('div', 'ches-help');

    /* Окно с информацией */
    var infoWindow = el('div', 'ches-help-window');
    var infoHead = el('div', 'ches-help-window-title');
    infoHead.appendChild(el('div', 'ches-help-title-text', 'Информация'));
    infoWindow.appendChild(infoHead);
    var infoBody = el('div', 'ches-help-body', helpText.join('\n'));
    infoWindow.appendChild(infoBody);
    wrap.appendChild(infoWindow);

    /* Окно с логом ошибок */
    var errorsBox = el('div', 'ches-help-errors');
    var errHead = el('div', 'ches-help-errors-title');
    errHead.appendChild(el('div', 'ches-help-title-text', 'Последние ошибки'));
    errHead.appendChild(el('div', 'ches-help-btn', 'Обновить'));
    errHead.appendChild(el('div', 'ches-help-btn', 'Открыть файл'));
    errHead.appendChild(el('div', 'ches-help-btn danger', 'Очистить лог'));

    var refreshBtn = errHead.children[1];
    var openBtn = errHead.children[2];
    var clearBtn = errHead.children[3];
    helpRefs.refreshBtn = refreshBtn;
    helpRefs.openBtn = openBtn;
    helpRefs.clearBtn = clearBtn;
    refreshBtn.addEventListener('click', function () {
      loadHelpErrors();
    });
    openBtn.addEventListener('click', function () {
      openErrorsLog();
    });
    clearBtn.addEventListener('click', function () {
      clearErrorsLog();
    });
    errorsBox.appendChild(errHead);

    var errBody = el('div', 'ches-help-errors-body');
    helpRefs.errBody = errBody;
    errorsBox.appendChild(errBody);
    wrap.appendChild(errorsBox);

    contentBodyEl.appendChild(wrap);

    loadHelpErrors();
  }

  function loadHelpErrors() {
    if (helpRefs.errBody) {
      helpRefs.errBody.innerHTML = '';
      helpRefs.errBody.appendChild(el('div', 'ches-help-empty', 'Загрузка…'));
    }
    var xhr = new XMLHttpRequest();
    xhr.open('GET', HELP_URL, true);
    xhr.timeout = 1500;
    xhr.onload = function () {
      if (xhr.status >= 200 && xhr.status < 300) {
        try {
          var d = JSON.parse(xhr.responseText);
          if (d && d.ok) {
            helpErrors = Array.isArray(d.errors) ? d.errors : [];
            renderHelpErrors();
            return;
          }
        } catch (e) {}
      }
      renderHelpErrors();
    };
    xhr.onerror = function () { renderHelpErrors(); };
    xhr.ontimeout = function () { renderHelpErrors(); };
    xhr.send();
  }

  function renderHelpErrors() {
    if (!helpRefs.errBody) return;
    var errBody = helpRefs.errBody;
    errBody.innerHTML = '';
    if (helpErrors.length === 0) {
      errBody.appendChild(el('div', 'ches-help-empty', 'Ошибок нет'));
      return;
    }
    helpErrors.forEach(function (e) {
      var item = el('div', 'ches-help-err-item');
      item.appendChild(el('span', 'ches-help-err-time', e.time));
      item.appendChild(document.createTextNode(e.msg));
      errBody.appendChild(item);
    });
  }

  function openErrorsLog() {
    var xhr = new XMLHttpRequest();
    xhr.open('GET', HELP_OPEN_URL, true);
    xhr.timeout = 1500;
    xhr.onload = function () {};
    xhr.onerror = function () {};
    xhr.ontimeout = function () {};
    xhr.send();
  }

  function clearErrorsLog() {
    var btn = helpRefs.clearBtn;
    if (helpRefs.confirm !== 'clear') {
      helpRefs.confirm = 'clear';
      if (btn) btn.textContent = 'Ещё раз для подтверждения';
      setTimeout(function () {
        if (helpRefs.confirm === 'clear') {
          helpRefs.confirm = '';
          if (btn) btn.textContent = 'Очистить лог';
        }
      }, 4000);
      return;
    }
    helpRefs.confirm = '';
    var xhr = new XMLHttpRequest();
    xhr.open('GET', HELP_CLEAR_URL, true);
    xhr.timeout = 1500;
    xhr.onload = function () {
      setTimeout(function () { loadHelpErrors(); }, 400);
    };
    xhr.onerror = function () {};
    xhr.ontimeout = function () {};
    xhr.send();
  }

  function renderCloud() {
    clearBody();

    var wrap = el('div', 'ches-cloud');

    var statusLabels = { ok: 'Подтверждён', pending: 'Ожидание', blocked: 'Заблокирован' };
    var statusText = statusLabels[cloudState.status] || 'Ожидание';

    /* Карточка: аккаунт администратора */
    var accountCard = el('div', 'ches-cloud-card');
    accountCard.appendChild(el('div', 'ches-cloud-label', 'Аккаунт администратора'));
    var nick = el('div', 'ches-cloud-nick' + (cloudState.nick ? '' : ' empty'),
      cloudState.nick ? cloudState.nick : 'Ник не указан');
    cloudRefs.nickEl = nick;
    accountCard.appendChild(nick);

    var statusRow = el('div', 'ches-cloud-status ' + cloudState.status);
    statusRow.appendChild(el('div', 'ches-cloud-dot'));
    statusRow.appendChild(el('span', null, statusText));
    cloudRefs.statusRow = statusRow;
    accountCard.appendChild(statusRow);

    var accToolbar = el('div', 'ches-cloud-toolbar');
    var checkBtn = el('div', 'ches-cloud-btn primary', 'Проверить');
    cloudRefs.checkBtn = checkBtn;
    checkBtn.addEventListener('click', function () {
      cloudCheck();
    });
    accToolbar.appendChild(checkBtn);
    var nickBtn = el('div', 'ches-cloud-btn', 'Сменить ник');
    cloudRefs.nickBtn = nickBtn;
    nickBtn.addEventListener('click', function () {
      showCloudNickInput();
    });
    accToolbar.appendChild(nickBtn);
    accountCard.appendChild(accToolbar);

    var nickWrap = el('div', 'ches-cloud-nickrow hidden');
    cloudRefs.nickWrap = nickWrap;
    var nickIn = document.createElement('input');
    nickIn.className = 'ches-cloud-input';
    nickIn.placeholder = 'Введите ник';
    nickIn.maxLength = 32;
    cloudRefs.nickIn = nickIn;
    nickWrap.appendChild(nickIn);
    var nickSaveBtn = el('div', 'ches-cloud-btn primary', 'Сохранить');
    cloudRefs.nickSaveBtn = nickSaveBtn;
    nickSaveBtn.addEventListener('click', function () {
      saveCloudNick();
    });
    nickWrap.appendChild(nickSaveBtn);
    accountCard.appendChild(nickWrap);
    wrap.appendChild(accountCard);

    /* Карточка: статус доступа */
    var accessCard = el('div', 'ches-cloud-card');
    accessCard.appendChild(el('div', 'ches-cloud-label', 'Статус доступа'));
    var message = el('div', 'ches-cloud-message ' + cloudState.status, cloudState.message);
    cloudRefs.msgEl = message;
    accessCard.appendChild(message);
    var lastCheck = el('div', 'ches-cloud-last',
      cloudState.lastCheck ? 'Последняя проверка: ' + cloudState.lastCheck : 'Проверка ещё не выполнялась');
    cloudRefs.lastEl = lastCheck;
    accessCard.appendChild(lastCheck);
    wrap.appendChild(accessCard);

    contentBodyEl.appendChild(wrap);

    loadCloud();
  }

  function loadCloud() {
    var xhr = new XMLHttpRequest();
    xhr.open('GET', CLOUD_URL, true);
    xhr.timeout = 1500;
    xhr.onload = function () {
      if (xhr.status >= 200 && xhr.status < 300) {
        try {
          var d = JSON.parse(xhr.responseText);
          if (d && d.ok) {
            cloudState.nick = d.nick || '';
            cloudState.status = d.status || 'pending';
            cloudState.message = d.message || '';
            cloudState.lastCheck = d.lastCheck || '';
            cloudState.loaded = true;
            refreshCloud();
          }
        } catch (e) {}
      }
    };
    xhr.onerror = function () {};
    xhr.ontimeout = function () {};
    xhr.send();
  }

  function refreshCloud() {
    var statusLabels = { ok: 'Подтверждён', pending: 'Ожидание', blocked: 'Заблокирован' };
    if (cloudRefs.nickEl) {
      cloudRefs.nickEl.textContent = cloudState.nick ? cloudState.nick : 'Ник не указан';
      cloudRefs.nickEl.className = 'ches-cloud-nick' + (cloudState.nick ? '' : ' empty');
    }
    if (cloudRefs.statusRow) {
      cloudRefs.statusRow.className = 'ches-cloud-status ' + cloudState.status;
      var span = cloudRefs.statusRow.querySelector('span');
      if (span) span.textContent = statusLabels[cloudState.status] || 'Ожидание';
    }
    if (cloudRefs.msgEl) {
      cloudRefs.msgEl.textContent = cloudState.message || '';
      cloudRefs.msgEl.className = 'ches-cloud-message ' + cloudState.status;
    }
    if (cloudRefs.lastEl) {
      cloudRefs.lastEl.textContent = cloudState.lastCheck ? 'Последняя проверка: ' + cloudState.lastCheck : 'Проверка ещё не выполнялась';
    }
  }

  function cloudCheck() {
    var btn = cloudRefs.checkBtn;
    if (btn) btn.textContent = 'Проверка…';
    var xhr = new XMLHttpRequest();
    xhr.open('GET', CLOUD_CHECK_URL, true);
    xhr.timeout = 15000;
    xhr.onload = function () {
      setTimeout(function () { loadCloud(); }, 800);
    };
    xhr.onerror = function () {
      if (btn) btn.textContent = 'Проверить';
    };
    xhr.ontimeout = function () {
      if (btn) btn.textContent = 'Проверить';
    };
    xhr.send();
  }

  function showCloudNickInput() {
    if (cloudRefs.nickWrap) {
      cloudRefs.nickWrap.classList.toggle('hidden');
      if (!cloudRefs.nickWrap.classList.contains('hidden') && cloudRefs.nickIn) {
        cloudRefs.nickIn.value = cloudState.nick || '';
        setTimeout(function () {
          try { cloudRefs.nickIn.focus(); } catch (e) {}
        }, 50);
      }
    }
  }

  function saveCloudNick() {
    var nick = cloudRefs.nickIn ? cloudRefs.nickIn.value : '';
    nick = (nick || '').replace(/[<>]/g, '').trim();
    if (!nick) return;
    var btn = cloudRefs.nickSaveBtn;
    if (btn) btn.textContent = 'Сохранение…';
    var xhr = new XMLHttpRequest();
    xhr.open('GET', CLOUD_NICK_URL + '?nick=' + encodeURIComponent(nick), true);
    xhr.timeout = 3000;
    xhr.onload = function () {
      if (btn) btn.textContent = 'Сохранить';
      if (cloudRefs.nickWrap) cloudRefs.nickWrap.classList.add('hidden');
      setTimeout(function () { loadCloud(); }, 600);
    };
    xhr.onerror = function () {
      if (btn) btn.textContent = 'Сохранить';
    };
    xhr.ontimeout = function () {
      if (btn) btn.textContent = 'Сохранить';
    };
    xhr.send();
  }

  function renderDiagnostics() {
    clearBody();

    var wrap = el('div', 'ches-diag');

    /* Карточка: здоровье */
    var healthCard = el('div', 'ches-diag-card');
    var healthRow = el('div', 'ches-diag-health ' + diagState.health);
    healthRow.appendChild(el('div', 'ches-diag-dot'));
    healthRow.appendChild(el('span', null, diagState.healthMsg));
    diagRefs.healthRow = healthRow;
    healthCard.appendChild(healthRow);
    healthCard.appendChild(el('div', 'ches-diag-hint', 'Проверка раз в 1 мин • автообновление на этой вкладке'));
    wrap.appendChild(healthCard);

    /* Кнопка обновить */
    var toolbar = el('div', 'ches-diag-toolbar');
    var refreshBtn = el('div', 'ches-diag-btn primary', 'Обновить');
    diagRefs.refreshBtn = refreshBtn;
    refreshBtn.addEventListener('click', function () {
      loadDiagnostics();
    });
    toolbar.appendChild(refreshBtn);
    wrap.appendChild(toolbar);

    /* Текст диагностики */
    var textBody = el('div', 'ches-diag-text', diagState.text || 'Загрузка…');
    diagRefs.textBody = textBody;
    wrap.appendChild(textBody);

    contentBodyEl.appendChild(wrap);

    loadDiagnostics();
  }

  function loadDiagnostics() {
    var btn = diagRefs.refreshBtn;
    if (btn) btn.textContent = 'Обновление…';
    var xhr = new XMLHttpRequest();
    xhr.open('GET', DIAGNOSTICS_URL, true);
    xhr.timeout = 1500;
    xhr.onload = function () {
      if (btn) btn.textContent = 'Обновить';
      if (xhr.status >= 200 && xhr.status < 300) {
        try {
          var d = JSON.parse(xhr.responseText);
          if (d && d.ok) {
            diagState.health = d.health || 'ok';
            diagState.healthMsg = d.healthMsg || '';
            diagState.text = d.text || '';
            diagState.loaded = true;
            refreshDiagnostics();
          }
        } catch (e) {}
      }
    };
    xhr.onerror = function () {
      if (btn) btn.textContent = 'Обновить';
    };
    xhr.ontimeout = function () {
      if (btn) btn.textContent = 'Обновить';
    };
    xhr.send();
  }

  function refreshDiagnostics() {
    if (diagRefs.healthRow) {
      diagRefs.healthRow.className = 'ches-diag-health ' + diagState.health;
      var span = diagRefs.healthRow.querySelector('span');
      if (span) span.textContent = diagState.healthMsg || '';
    }
    if (diagRefs.textBody) {
      diagRefs.textBody.textContent = diagState.text || 'Нет данных';
    }
  }

  function renderEmpty() {
    clearBody();
  }

  function showView(id) {
    currentView = id;
    try { if (id !== 'Scripts') hideScriptInfo(); } catch (e) {}

    Object.keys(navButtons).forEach(function (key) {
      navButtons[key].className = 'ches-nav' + (key === id ? ' active' : '');
    });
    Object.keys(topButtons).forEach(function (key) {
      topButtons[key].className = 'ches-top-btn' + (key === id ? ' active' : '');
    });
    updateNotifBadge();

    if (contentTitleEl) contentTitleEl.textContent = getViewTitle(id);

    if (id === 'Settings') loadSettings(renderSettings);
    else if (id === 'Notifications') renderNotifications();
    else if (id === 'AI') renderAI();
    else if (id === 'Dashboard') renderDashboard();
    else if (id === 'Punishments') renderPunishments();
    else if (id === 'PMLogs') renderPMLogs();
    else if (id === 'NormHistory') renderNorm();
    else if (id === 'DaysOff') renderDaysOff();
    else if (id === 'Binds') renderBinds();
    else if (id === 'Scripts') renderScripts();
    else if (id === 'Tester') renderTester();
    else if (id === 'Updates') renderUpdates();
    else if (id === 'Help') renderHelp();
    else if (id === 'Cloud') renderCloud();
    else if (id === 'Diagnostics') renderDiagnostics();
    else renderEmpty();
  }

  /* ====================== ПОКАЗ / СКРЫТИЕ ====================== */
  function show() {
    if (!container || visible) return;
    visible = true;
    container.style.display = '';
    overlay.style.display = 'block';
    try {
      if (window.setCursorStatus) window.setCursorStatus(CURSOR_NAME, true);
      if (window.setInputFocus) window.setInputFocus(true);
      window.isBluredInput = false;
    } catch (e) {}
    showView(currentView || 'Dashboard');
    loadTester();
  }

  function hide() {
    if (!container || !visible) return;
    visible = false;
    container.style.display = 'none';
    overlay.style.display = 'none';
    setTimeout(function () {
      try {
        if (window.setInputFocus) window.setInputFocus(false);
        window.isBluredInput = true;
        if (window.setCursorStatus) window.setCursorStatus(CURSOR_NAME, false);
      } catch (e) {}
    }, 40);
  }

  function toggle() {
    if (visible) hide();
    else show();
  }

  /* ====================== ПОСТРОЕНИЕ DOM ====================== */
  function createDom() {
    if (domReady) return;

    var style = document.createElement('style');
    style.id = 'ches-panel-style';
    style.textContent = chesStyles;
    document.head.appendChild(style);

    overlay = el('div', 'ches-overlay');
    overlay.addEventListener('click', hide);

    container = el('div', 'ches');
    container.style.display = 'none';

    var top = el('div', 'ches-top');
    var topTitle = el('div', 'ches-top-title');
    topTitle.appendChild(document.createTextNode('ChesNova'));
    var betaBadge = el('span', 'ches-top-beta hidden', 'Beta');
    topTitle.appendChild(betaBadge);
    topTitleEl = topTitle;
    betaBadgeEl = betaBadge;
    top.appendChild(topTitle);
    var topBtns = el('div', 'ches-top-btns');

    topList.forEach(function (item) {
      var btn = el('div', 'ches-top-btn', item.label);
      btn.addEventListener('click', function () { showView(item.id); });
      topBtns.appendChild(btn);
      topButtons[item.id] = btn;
    });

    var closeBtn = el('div', 'ches-top-close');
    closeBtn.addEventListener('click', hide);
    topBtns.appendChild(closeBtn);
    top.appendChild(topBtns);

    var body = el('div', 'ches-body');
    var sidebar = el('div', 'ches-sidebar');

    function addNav(items) {
      items.forEach(function (item) {
        var row = el('div', 'ches-nav');
        row.appendChild(el('div', 'ches-nav-ind'));
        row.appendChild(el('span', null, item.label));
        row.addEventListener('click', function () { showView(item.id); });
        sidebar.appendChild(row);
        navButtons[item.id] = row;
      });
    }

    addNav(mainNav);
    sidebar.appendChild(el('div', 'ches-nav-sep'));
    addNav(bottomNav);

    var content = el('div', 'ches-content');
    contentTitleEl = el('div', 'ches-content-title');
    contentBodyEl = el('div', 'ches-content-body');
    content.appendChild(contentTitleEl);
    content.appendChild(contentBodyEl);

    body.appendChild(sidebar);
    body.appendChild(content);
    container.appendChild(top);
    container.appendChild(body);

    var target = document.querySelector('.app') || document.body;
    target.appendChild(overlay);
    target.appendChild(container);

    document.addEventListener('keyup', function (e) {
      if (!visible) return;
      if (e.key === 'Escape' || e.keyCode === 27) {
        e.preventDefault();
        hide();
      }
    });

    showView('Dashboard');
    domReady = true;
  }

  /* ====================== ХУКИ И ИНИЦИАЛИЗАЦИЯ ====================== */
  function installHook() {
    if (hooked || !window.sendChatInput) return false;
    var orig = window.sendChatInput;
    try {
      window.sendChatInput = new Proxy(orig, {
        apply: function (target, thisArg, args) {
          var text = args[0];
          if (typeof text === 'string' && text.split(' ')[0].toLowerCase() === '/ches') {
            toggle();
            return;
          }
          return Reflect.apply(target, thisArg, args);
        }
      });
      hooked = true;
      return true;
    } catch (e) {
      return false;
    }
  }

  function init() {
    if (initialized) return;
    try {
      initialized = true;
      if (!domReady) createDom();
      if (window.OUtils && window.OUtils.registerCommand) {
        window.OUtils.registerCommand('/ches', function () { toggle(); }, 0, true);
      }
      if (window.OUtils && typeof window.OUtils.addListenerToChat === 'function' && !window.__chesPanelChatListener) {
        window.__chesPanelChatListener = true;
        try {
          window.OUtils.addListenerToChat(function (ev) {
            var text = ev && ev[0];
            if (typeof text === 'string' && text.split(' ')[0].toLowerCase() === '/ches') {
              toggle();
              return false;
            }
          });
        } catch (e) {
          window.__chesPanelChatListener = false;
        }
      }
      loadSettings();
      loadNotifications();
    } catch (e) {
      initialized = false;
    }
  }

  function tick() {
    if (!domReady && document.body) {
      try { createDom(); } catch (e) {}
    }
    if (!hooked) installHook();
    if (!initialized && window.OUtils && window.OUtils.registerCommand) init();
    if (!(domReady && hooked && initialized)) setTimeout(tick, 50);
  }

  /* ====================== ПУБЛИЧНЫЙ API ====================== */
  window.ChesPanel = {
    show: show,
    hide: hide,
    toggle: toggle,
    showView: showView,
    isOpen: function () { return visible; }
  };

  setInterval(function () {
    if (currentView === 'Dashboard') pollDashboard();
    if (currentView === 'Punishments') loadPunishments();
    if (currentView === 'PMLogs') loadPmLogs();
    if (currentView === 'NormHistory') loadNorm();
    if (currentView === 'DaysOff') loadDaysOff();
    if (currentView === 'Scripts') loadScripts();
    if (currentView === 'Tester') loadTester();
    if (currentView === 'AI') loadAi();
    if (currentView === 'Cloud') loadCloud();
    pollNotifications();
  }, 2000);

  tick();
})();


/* ============================================================
   ====  IN-GAME HUD (ches.js) — merged into panel.js  ====
   /ches opens the panel above; HUD toggled via ChesHUD.toggle() bind
   ============================================================ */
(function () {
  'use strict';

  var HUD_URL = 'http://127.0.0.1:17890/hud';
  var NORM_RESET_CONFIRM_URL = 'http://127.0.0.1:17890/reset/confirm';
  var NORM_RESET_CANCEL_URL = 'http://127.0.0.1:17890/reset/cancel';
  var POLL_MS = 750;
  var AI_SHOW_MS = 10000;
  var resetConfirmEl = null;
  var resetConfirmTextEl = null;
  var resetConfirmShown = false;
  var resetConfirmSuppressUntil = 0;
  var lastPanelToggle = 0;

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

  var noticeEl = null;
  var noticeTextEl = null;
  var noticeHideTimer = null;
  var lastScriptNoticeId = 0;

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
      /* «AI думает…» — левый низ; margin вместо gap (старый CEF) */
      '#ches-think{position:fixed;bottom:16px;left:16px;z-index:100001;display:none;align-items:center;padding:10px 14px;border-radius:12px;background:rgba(11,14,20,.88);border:1px solid #2B3443;color:#A0A8B8;font:12px/1.3 "Open Sans","Segoe UI",Arial,sans-serif;letter-spacing:.2px;pointer-events:none;box-shadow:0 8px 24px rgba(0,0,0,.35);backdrop-filter:blur(6px);opacity:0;transform:translateY(6px);transition:opacity .2s ease,transform .2s ease}',
      '#ches-think.ches-think-on{display:flex;opacity:1;transform:translateY(0)}',
      '#ches-think .ches-think-dot{width:8px;height:8px;border-radius:50%;background:#3B82F6;flex-shrink:0;margin-right:10px;box-shadow:0 0 0 2px rgba(59,130,246,.2);animation:ches-pulse 1s ease-in-out infinite}',
      '@keyframes ches-pulse{0%,100%{opacity:.35}50%{opacity:1}}',
      /* Confirm reset modal — стиль как у панели ChesNova, по центру экрана */
      '.ches-reset-modal{position:fixed;left:0;top:0;right:0;bottom:0;z-index:999999;display:block;background:rgba(0,0,0,.55);font-family:"Open Sans","Segoe UI",Arial,sans-serif}',
      '.ches-reset-modal.hidden{display:none!important}',
      '.ches-reset-box{position:absolute;left:50%;top:50%;transform:translate(-50%,-50%);width:360px;max-width:90%;background:#121824;border:1px solid #232c3a;border-radius:12px;padding:18px 20px;box-shadow:0 12px 32px rgba(0,0,0,.45);box-sizing:border-box}',
      '.ches-reset-title{font-size:15px;font-weight:700;color:#f5f7fb;letter-spacing:.2px;margin:0 0 10px}',
      '.ches-reset-text{font-size:13px;color:#aab4c5;line-height:1.5;white-space:pre-wrap;margin:0 0 16px}',
      '.ches-reset-actions{display:flex;gap:10px}',
      '.ches-reset-btn{flex:1;height:36px;line-height:34px;text-align:center;border-radius:8px;border:1px solid #232c3a;background:#161d29;color:#aab4c5;font-size:13px;font-weight:600;cursor:pointer;user-select:none;box-sizing:border-box}',
      '.ches-reset-btn:hover{background:#1e2736;color:#f5f7fb}',
      '.ches-reset-btn.primary{background:#22304a;border-color:#3b82f6;color:#f5f7fb}',
      '.ches-reset-btn.primary:hover{background:#2a3c5c}',
      '.ches-reset-btn.danger{background:#3a1a22;border-color:#ff6b8c;color:#ff8fa8}',
      '.ches-reset-btn.danger:hover{background:#4a222c;color:#ffb0c0}',
      /* Уведомление после установки скрипта — по центру экрана, ~5 сек */
      '#ches-notice{position:fixed;left:50%;top:40%;transform:translate(-50%,-50%) translateY(8px);z-index:100002;display:none;flex-direction:column;align-items:center;text-align:center;max-width:min(420px,calc(100vw - 32px));background:rgba(11,14,20,.95);border:1px solid #2B3443;border-radius:14px;padding:18px 26px;color:#F5F7FB;font:12px/1.4 "Open Sans","Segoe UI",Arial,sans-serif;pointer-events:none;box-shadow:0 12px 32px rgba(0,0,0,.45);backdrop-filter:blur(8px);opacity:0;transition:opacity .22s ease,transform .22s ease}',
      '#ches-notice.ches-notice-on{display:flex;opacity:1;transform:translate(-50%,-50%) translateY(0)}',
      '#ches-notice .ches-notice-badge{font-weight:700;font-size:11px;letter-spacing:.5px;color:#3DD97A;text-transform:uppercase;margin-bottom:8px}',
      '#ches-notice .ches-notice-text{color:#F5F7FB;font-size:13px;font-weight:500;line-height:1.5;word-break:break-word}'
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
    // /ches reserved for the panel — HUD toggles via bind (ChesHUD.toggle).
    // Deliberately does not wrap sendChatInput so the panel's proxy keeps working.
    window.__chesHudCmdRegistered = true;
    window.__chesHudChatListener = true;
    window.__chesHudCmdHooked = true;
  }

  function ensureThink() {
    if (thinkEl || !document.body) return;
    ensureStyles();
    thinkEl = document.createElement('div');
    thinkEl.id = 'ches-think';
    thinkEl.innerHTML = '<span class="ches-think-dot"></span> <span class="ches-think-text">AI думает…</span>';
    document.body.appendChild(thinkEl);
  }

  function setThinking(on) {
    ensureThink();
    if (!thinkEl) return;
    if (on) {
      thinkEl.innerHTML = '<span class="ches-think-dot"></span> <span class="ches-think-text">AI думает…</span>';
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

  function ensureNotice() {
    if (noticeEl || !document.body) return;
    ensureStyles();
    noticeEl = document.createElement('div');
    noticeEl.id = 'ches-notice';
    noticeEl.innerHTML = [
      '<div class="ches-notice-badge">Скрипт установлен</div>',
      '<div class="ches-notice-text"></div>'
    ].join('');
    document.body.appendChild(noticeEl);
    noticeTextEl = noticeEl.querySelector('.ches-notice-text');
  }

  function hideScriptNotice() {
    if (!noticeEl) return;
    noticeEl.classList.remove('ches-notice-on');
    if (noticeHideTimer) {
      clearTimeout(noticeHideTimer);
      noticeHideTimer = null;
    }
  }

  function showScriptNotice(payload) {
    ensureNotice();
    if (!noticeEl) return;
    var text = (payload && payload.text) ? String(payload.text) : '';
    if (!text) return;

    var ttl = 5000;
    if (payload && payload.ttl != null) {
      var t = parseInt(payload.ttl, 10);
      if (!isNaN(t) && t > 0) ttl = Math.min(Math.max(t, 1500), 10000);
    }

    if (noticeTextEl) noticeTextEl.textContent = text;
    noticeEl.classList.add('ches-notice-on');

    if (noticeHideTimer) clearTimeout(noticeHideTimer);
    noticeHideTimer = setTimeout(hideScriptNotice, ttl);
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


  function ensureResetConfirm() {
    if (resetConfirmEl || !document.body) return;
    ensureStyles();
    resetConfirmEl = document.createElement('div');
    resetConfirmEl.className = 'ches-reset-modal hidden';
    var box = document.createElement('div');
    box.className = 'ches-reset-box';

    var title = document.createElement('div');
    title.className = 'ches-reset-title';
    title.textContent = '\u0421\u0431\u0440\u043e\u0441 \u043d\u043e\u0440\u043c\u044b';
    box.appendChild(title);

    resetConfirmTextEl = document.createElement('div');
    resetConfirmTextEl.className = 'ches-reset-text';
    box.appendChild(resetConfirmTextEl);

    var actions = document.createElement('div');
    actions.className = 'ches-reset-actions';

    var yesBtn = document.createElement('div');
    yesBtn.className = 'ches-reset-btn danger';
    yesBtn.textContent = '\u0414\u0430, \u0441\u0431\u0440\u043e\u0441\u0438\u0442\u044c';
    yesBtn.addEventListener('click', function () {
      hideResetConfirm();
      try {
        var xhr = new XMLHttpRequest();
        xhr.open('GET', NORM_RESET_CONFIRM_URL + '?t=' + Date.now(), true);
        xhr.timeout = 1500;
        xhr.send();
      } catch (e) {}
    });

    var noBtn = document.createElement('div');
    noBtn.className = 'ches-reset-btn';
    noBtn.textContent = '\u041e\u0442\u043c\u0435\u043d\u0430';
    noBtn.addEventListener('click', function () {
      hideResetConfirm();
      try {
        var xhr = new XMLHttpRequest();
        xhr.open('GET', NORM_RESET_CANCEL_URL + '?t=' + Date.now(), true);
        xhr.timeout = 1500;
        xhr.send();
      } catch (e) {}
    });

    actions.appendChild(yesBtn);
    actions.appendChild(noBtn);
    box.appendChild(actions);
    resetConfirmEl.appendChild(box);
    document.body.appendChild(resetConfirmEl);
  }

  function showResetConfirm(pm, norm) {
    ensureResetConfirm();
    if (!resetConfirmEl) return;
    if (resetConfirmTextEl) {
      resetConfirmTextEl.textContent =
        '\u0421\u0431\u0440\u043e\u0441\u0438\u0442\u044c \u0441\u0447\u0451\u0442\u0447\u0438\u043a PM?\n' +
        '\u0422\u0435\u043a\u0443\u0449\u0435\u0435 \u0437\u043d\u0430\u0447\u0435\u043d\u0438\u0435: ' +
        (pm != null ? pm : '\u2014') + ' / ' + (norm != null ? norm : '\u2014') + '\n' +
        '\u0418\u0441\u0442\u043e\u0440\u0438\u044f \u0437\u0430 \u0434\u0435\u043d\u044c \u0431\u0443\u0434\u0435\u0442 \u0441\u043e\u0445\u0440\u0430\u043d\u0435\u043d\u0430.';
    }
    resetConfirmEl.classList.remove('hidden');
    resetConfirmShown = true;
    try {
      if (window.setCursorStatus) window.setCursorStatus('ches_reset_confirm', true);
      if (window.setInputFocus) window.setInputFocus(true);
    } catch (e) {}
  }

  function hideResetConfirm() {
    if (!resetConfirmEl) return;
    resetConfirmEl.classList.add('hidden');
    resetConfirmShown = false;
    resetConfirmSuppressUntil = Date.now() + 5000;
    try {
      if (window.setCursorStatus) window.setCursorStatus('ches_reset_confirm', false);
      if (window.setInputFocus) window.setInputFocus(false);
    } catch (e) {}
  }

  function applyState(data) {
    if (!data || typeof data !== 'object') return;
    if (data.panelToggle != null) {
      var pt = parseInt(data.panelToggle, 10);
      if (!isNaN(pt) && pt > 0) {
        if (lastPanelToggle === 0) {
          lastPanelToggle = pt;
        } else if (pt !== lastPanelToggle) {
          lastPanelToggle = pt;
          try {
            if (window.ChesPanel && typeof window.ChesPanel.toggle === 'function')
              window.ChesPanel.toggle();
          } catch (e) {}
        }
      }
    }
    if (data.confirmReset != null) {
      var needConfirm = data.confirmReset === 1 || data.confirmReset === '1' || data.confirmReset === true;
      var suppressed = Date.now() < resetConfirmSuppressUntil;
      if (needConfirm && !resetConfirmShown && !suppressed) {
        showResetConfirm(data.pm != null ? data.pm : pmCount, data.norm != null ? data.norm : normValue);
      } else if (!needConfirm && resetConfirmShown) {
        hideResetConfirm();
      }
    }
    if (data.hudVisible != null && !dragState) {
      var want = data.hudVisible === 1 || data.hudVisible === '1' || data.hudVisible === true;
      if (want !== hudVisible) setHudVisible(want);
    }
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

    if (data.scriptNotice && typeof data.scriptNotice === 'object') {
      var snId = parseInt(data.scriptNotice.id, 10);
      if (!isNaN(snId) && snId > 0 && snId !== lastScriptNoticeId) {
        lastScriptNoticeId = snId;
        showScriptNotice(data.scriptNotice);
      }
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
    try { ensureNotice(); } catch (e) {}
    try { installChatHook(); } catch (e) {}
    try { announceLoaded(); } catch (e) {}
  }

  setInterval(function () {
    ensureHud();
    ensureAiPanel();
    ensureThink();
    ensureNotice();
    installChatHook();
    pollHud();
  }, POLL_MS);

  tick();
})();
