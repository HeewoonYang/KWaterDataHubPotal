// ===== 토스트 알림 =====
function showToast(msg, type) {
  var t = document.createElement('div');
  t.textContent = msg;
  var bg = type === 'error' ? '#f44336' : type === 'success' ? '#4caf50' : '#333';
  t.style.cssText = 'position:fixed;top:20px;left:50%;transform:translateX(-50%);padding:12px 24px;background:' + bg + ';color:#fff;border-radius:8px;font-size:14px;z-index:99999;box-shadow:0 4px 12px rgba(0,0,0,.3);transition:opacity .3s';
  document.body.appendChild(t);
  setTimeout(function(){ t.style.opacity='0'; setTimeout(function(){ t.remove(); }, 300); }, 2500);
}

// ===== 모달 공통: 외부 클릭 닫기 + 드래그 이동 =====
// 모달 오버레이 클릭 시 닫기 (카드 내부 클릭은 무시, 드래그 중에는 무시)
function initModalOverlayClose(overlay) {
  overlay.addEventListener('mousedown', function(e) {
    // mousedown이 오버레이 자체에서 발생한 경우만 기록
    if (e.target === overlay) overlay._closeCandidate = true;
    else overlay._closeCandidate = false;
  });
  overlay.addEventListener('mouseup', function(e) {
    // mousedown과 mouseup 모두 오버레이에서 발생 + 드래그 중 아닌 경우만 닫기
    if (e.target === overlay && overlay._closeCandidate && !overlay._isDragging) {
      overlay.style.display = 'none';
      var card = overlay.querySelector('.modal-card');
      if (card) { card.style.transform = ''; card.style.left = ''; card.style.top = ''; card.style.position = ''; card.style.margin = ''; }
    }
    overlay._closeCandidate = false;
  });
}

// 모달 헤더 드래그로 이동
function initModalDrag(overlay) {
  var card = overlay.querySelector('.modal-card');
  var header = overlay.querySelector('.modal-header');
  if (!card || !header) return;
  header.style.cursor = 'move';
  header.style.userSelect = 'none';
  var startX = 0, startY = 0, offsetX = 0, offsetY = 0;

  header.addEventListener('mousedown', function(e) {
    if (e.target.closest('.modal-close') || e.target.closest('button')) return;
    overlay._isDragging = true;
    var rect = card.getBoundingClientRect();
    startX = e.clientX;
    startY = e.clientY;
    offsetX = rect.left;
    offsetY = rect.top;
    card.style.transition = 'none';
    card.style.margin = '0';
    card.style.position = 'fixed';
    card.style.left = offsetX + 'px';
    card.style.top = offsetY + 'px';
    card.style.transform = 'none';
    e.preventDefault();
  });

  document.addEventListener('mousemove', function(e) {
    if (!overlay._isDragging) return;
    var dx = e.clientX - startX;
    var dy = e.clientY - startY;
    card.style.left = (offsetX + dx) + 'px';
    card.style.top = (offsetY + dy) + 'px';
  });

  document.addEventListener('mouseup', function() {
    if (overlay._isDragging) {
      // 약간의 지연으로 click 이벤트가 닫기를 트리거하지 않도록 방지
      setTimeout(function() { overlay._isDragging = false; }, 50);
      card.style.transition = '';
    }
  });
}

// 모든 modal-overlay에 외부 클릭 닫기 + 드래그 적용
// (pages/*.html이 비동기 로드되므로 initAfterLoad에서 호출해야 함)
function initAllModals() {
  document.querySelectorAll('.modal-overlay').forEach(function(overlay) {
    if (overlay.dataset.modalInit) return; // 중복 방지
    overlay.dataset.modalInit = 'true';
    initModalOverlayClose(overlay);
    initModalDrag(overlay);
  });
}

// ===== 메타데이터 표준사전 API =====
var META_API_BASE = 'http://localhost:8010/api/v1';

function metaApiFetch(endpoint, options) {
  var url = META_API_BASE + endpoint;
  var opts = { headers: { 'Content-Type': 'application/json' } };
  if (options) { Object.keys(options).forEach(function(k) { opts[k] = options[k]; }); }
  return fetch(url, opts).then(function(res) {
    if (!res.ok) {
      return res.json().catch(function() { return { detail: 'HTTP ' + res.status }; }).then(function(err) {
        throw new Error(err.detail || 'API 오류 (HTTP ' + res.status + ')');
      });
    }
    return res.json();
  });
}

function buildQueryString(params) {
  var parts = [];
  Object.keys(params).forEach(function(k) {
    if (params[k] !== null && params[k] !== undefined && params[k] !== '') {
      parts.push(encodeURIComponent(k) + '=' + encodeURIComponent(params[k]));
    }
  });
  return parts.length > 0 ? '?' + parts.join('&') : '';
}

var wordApi = {
  list: function(params) { return metaApiFetch('/words' + buildQueryString(params)); },
  get: function(id) { return metaApiFetch('/words/' + id); }
};
var termApi = {
  list: function(params) { return metaApiFetch('/terms' + buildQueryString(params)); },
  get: function(id) { return metaApiFetch('/terms/' + id); }
};
var codeApiClient = {
  listGroups: function(params) { return metaApiFetch('/code-groups' + buildQueryString(params)); },
  getGroup: function(id) { return metaApiFetch('/code-groups/' + id); },
  getTree: function(groupId) { return metaApiFetch('/codes/tree/' + groupId); }
};
var domainApiClient = { listGroups: function() { return metaApiFetch('/domain-groups'); } };
var statsApiClient = {
  summary: function() { return metaApiFetch('/stats/summary'); },
  domainDistribution: function() { return metaApiFetch('/stats/domain-distribution'); }
};

// ===== 드롭다운 동적 로드 유틸 =====
// API 응답 캐시 (같은 코드그룹을 여러 select에서 사용할 때 중복 호출 방지)
var _codeCache = {};

/**
 * 도메인그룹 API → select 옵션 채우기
 * @param {HTMLSelectElement|string} selectEl - select 요소 또는 셀렉터
 * @param {Object} options - { placeholder: '전체 도메인', valueField: 'group_id'|'group_name', showIcon: true }
 */
function loadDomainOptions(selectEl, options) {
  var el = typeof selectEl === 'string' ? document.querySelector(selectEl) : selectEl;
  if (!el) return Promise.resolve();
  var opts = options || {};
  var placeholder = opts.placeholder || '';
  var valueField = opts.valueField || 'group_name';

  return metaApiFetch('/domain-groups?size=100').then(function(res) {
    var items = res.items || res;
    // 기존 option 제거 (placeholder 제외)
    while (el.options.length > 0) el.remove(0);
    // placeholder 추가
    if (placeholder) {
      var ph = document.createElement('option');
      ph.value = '';
      ph.textContent = placeholder;
      el.appendChild(ph);
    }
    // 도메인그룹 옵션 추가
    items.forEach(function(item) {
      var opt = document.createElement('option');
      opt.value = valueField === 'group_id' ? item.group_id : item.group_name;
      opt.textContent = item.group_name;
      el.appendChild(opt);
    });
    return items;
  }).catch(function(err) {
    console.warn('도메인그룹 로드 실패:', err.message);
  });
}

/**
 * 공통코드(code_id) API → select 옵션 채우기
 * @param {HTMLSelectElement|string} selectEl - select 요소 또는 셀렉터
 * @param {string} codeId - 코드그룹 code_id (예: 'SYS_COLLECT_METHOD')
 * @param {Object} options - { placeholder: '전체', valueField: 'code_value'|'code_name' }
 */
function loadCodeOptions(selectEl, codeId, options) {
  var el = typeof selectEl === 'string' ? document.querySelector(selectEl) : selectEl;
  if (!el) return Promise.resolve();
  var opts = options || {};
  var placeholder = opts.placeholder || '';
  var valueField = opts.valueField || 'code_value';

  // 캐시 확인
  var fetchPromise;
  if (_codeCache[codeId]) {
    fetchPromise = Promise.resolve(_codeCache[codeId]);
  } else {
    fetchPromise = metaApiFetch('/code-groups/by-code-id/' + codeId).then(function(res) {
      _codeCache[codeId] = res;
      return res;
    });
  }

  return fetchPromise.then(function(data) {
    var codes = data.codes || [];
    while (el.options.length > 0) el.remove(0);
    if (placeholder) {
      var ph = document.createElement('option');
      ph.value = '';
      ph.textContent = placeholder;
      el.appendChild(ph);
    }
    codes.forEach(function(code) {
      var opt = document.createElement('option');
      opt.value = valueField === 'code_name' ? code.code_name : code.code_value;
      opt.textContent = code.code_name;
      el.appendChild(opt);
    });
    return codes;
  }).catch(function(err) {
    console.warn('공통코드(' + codeId + ') 로드 실패:', err.message);
  });
}

/**
 * data-code-source 속성이 있는 모든 select 자동 초기화
 * data-code-source="domain-groups" → loadDomainOptions
 * data-code-source="SYS_COLLECT_METHOD" → loadCodeOptions
 */
function initDynamicSelects() {
  var selects = document.querySelectorAll('select[data-code-source]');
  var promises = [];
  selects.forEach(function(sel) {
    if (sel.dataset.codeLoaded) return;
    sel.dataset.codeLoaded = 'true';
    var source = sel.dataset.codeSource;
    var placeholder = sel.dataset.placeholder || '';
    var valueField = sel.dataset.valueField || '';

    if (source === 'domain-groups') {
      promises.push(loadDomainOptions(sel, {
        placeholder: placeholder,
        valueField: valueField || 'group_name'
      }));
    } else {
      promises.push(loadCodeOptions(sel, source, {
        placeholder: placeholder,
        valueField: valueField || 'code_value'
      }));
    }
  });
  return Promise.all(promises);
}

var glossaryState = {
  activeTab: 'word',
  wordPage: 1, wordSize: 50, wordSearch: '', wordStatus: '', wordTotal: 0,
  termPage: 1, termSize: 50, termSearch: '', termDomainGroupId: null, termStatus: '', termTotal: 0,
  codePage: 1, codeSize: 50, codeSearch: '', codeTotal: 0,
  domainGroups: []
};

// ===== AG GRID HELPER =====
var agGridInstances = {};

function initAGGrid(containerId, columnDefs, rowData, options) {
  var container = document.getElementById(containerId);
  if (!container) return null;
  if (agGridInstances[containerId]) {
    agGridInstances[containerId].destroy();
    delete agGridInstances[containerId];
  }
  var defaultOpts = {
    columnDefs: columnDefs,
    rowData: rowData,
    defaultColDef: {
      sortable: true,
      filter: true,
      resizable: true,
      minWidth: 120,
      cellStyle: { fontSize: '12px' }
    },
    headerHeight: 34,
    rowHeight: 32,
    domLayout: 'autoHeight',
    pagination: rowData && rowData.length > 15,
    paginationPageSize: 15,
    animateRows: true,
    suppressMovableColumns: false,
    suppressCellFocus: true
  };
  if (options) {
    Object.keys(options).forEach(function (k) { defaultOpts[k] = options[k]; });
  }
  var gridApi = agGrid.createGrid(container, defaultOpts);
  agGridInstances[containerId] = gridApi;
  return gridApi;
}

function destroyAllGrids() {
  Object.keys(agGridInstances).forEach(function (id) {
    if (agGridInstances[id]) agGridInstances[id].destroy();
  });
  agGridInstances = {};
}

function refreshGridThemes() {
  // v35 Theming API handles dark mode via CSS custom properties
  // Re-render grids if needed
}

// ===== LOGIN FUNCTIONS =====
function switchLoginType(type) {
  // 탭 활성화
  document.querySelectorAll('.login-type-btn').forEach(b => b.classList.remove('active'));
  document.querySelector('.login-type-btn[data-type="' + type + '"]').classList.add('active');
  // 폼 전환
  document.querySelectorAll('.login-form').forEach(f => f.style.display = 'none');
  document.getElementById('login-' + type).style.display = 'block';
}

// ===== RBAC 권한 매트릭스 =====
var RBAC_MATRIX = {
  '수공직원|일반사용자': {
    screens: ['home', 'process', 'quality', 'measurement', 'ai', 'gallery', 'widget-settings', 'sitemap',
      'cat-search', 'cat-detail', 'cat-graph', 'cat-lineage', 'cat-bookmark', 'cat-request',
      'dist-product', 'dist-approval', 'dist-stats',
      'comm-notice', 'comm-internal', 'comm-archive'],
    topNav: ['dashboard', 'catalog', 'distribute', 'community']
  },
  '수공직원|부서관리자': {
    screens: ['home', 'process', 'quality', 'measurement', 'ai', 'gallery', 'widget-settings', 'sitemap',
      'cat-search', 'cat-detail', 'cat-graph', 'cat-lineage', 'cat-bookmark', 'cat-request',
      'col-arch', 'col-monitor',
      'dist-product', 'dist-deidentify', 'dist-approval', 'dist-api', 'dist-external', 'dist-stats',
      'meta-glossary', 'meta-tag', 'meta-model', 'meta-dq',
      'meta-std-dashboard', 'meta-std-words', 'meta-std-domains', 'meta-std-terms', 'meta-std-codes', 'meta-std-import',
      'comm-notice', 'comm-internal', 'comm-archive'],
    topNav: ['dashboard', 'catalog', 'collect', 'distribute', 'meta', 'community']
  },
  '수공직원|데이터스튜어드': {
    screens: ['home', 'process', 'quality', 'measurement', 'ai', 'gallery', 'widget-settings', 'sitemap',
      'cat-search', 'cat-detail', 'cat-graph', 'cat-lineage', 'cat-bookmark', 'cat-request',
      'col-pipeline', 'col-register', 'col-cdc', 'col-kafka', 'col-external', 'col-arch', 'col-monitor', 'col-dbt',
      'dist-product', 'dist-deidentify', 'dist-approval', 'dist-api', 'dist-external', 'dist-stats', 'dist-chart-content',
      'meta-glossary', 'meta-tag', 'meta-model', 'meta-dq', 'meta-ontology',
      'meta-std-dashboard', 'meta-std-words', 'meta-std-domains', 'meta-std-terms', 'meta-std-codes', 'meta-std-import',
      'sys-security',
      'comm-notice', 'comm-internal', 'comm-archive'],
    topNav: ['dashboard', 'catalog', 'collect', 'distribute', 'meta', 'community', 'system']
  },
  '협력직원|데이터조회': {
    screens: ['home', 'ai', 'gallery', 'widget-settings', 'sitemap',
      'cat-search', 'cat-detail', 'cat-graph', 'cat-lineage', 'cat-bookmark', 'cat-request',
      'dist-approval',
      'comm-notice', 'comm-external', 'comm-archive'],
    topNav: ['dashboard', 'catalog', 'distribute', 'community']
  },
  '협력직원|외부개발자': {
    screens: ['home', 'ai', 'gallery', 'widget-settings', 'sitemap',
      'cat-search', 'cat-detail', 'cat-graph', 'cat-lineage', 'cat-bookmark', 'cat-request',
      'dist-approval', 'dist-api',
      'comm-notice', 'comm-external', 'comm-archive'],
    topNav: ['dashboard', 'catalog', 'distribute', 'community']
  },
  '데이터엔지니어|파이프라인관리자': {
    screens: ['home', 'process', 'quality', 'measurement', 'asset-db', 'digital-twin', 'ai', 'llmops', 'gallery', 'widget-settings', 'sitemap',
      'cat-search', 'cat-detail', 'cat-graph', 'cat-lineage', 'cat-bookmark', 'cat-request',
      'col-pipeline', 'col-register', 'col-cdc', 'col-kafka', 'col-external', 'col-arch', 'col-monitor', 'col-log', 'col-dbt',
      'meta-dq',
      'dist-product', 'dist-approval', 'dist-stats',
      'sys-interface', 'sys-k8s',
      'comm-notice', 'comm-internal', 'comm-archive'],
    topNav: ['dashboard', 'catalog', 'collect', 'distribute', 'meta', 'community', 'system']
  },
  '데이터엔지니어|ETL운영자': {
    screens: ['home', 'process', 'quality', 'measurement', 'asset-db', 'digital-twin', 'ai', 'gallery', 'widget-settings', 'sitemap',
      'cat-search', 'cat-detail', 'cat-graph', 'cat-lineage', 'cat-bookmark', 'cat-request',
      'col-pipeline', 'col-register', 'col-cdc', 'col-kafka', 'col-external', 'col-arch', 'col-monitor', 'col-log', 'col-dbt',
      'meta-dq',
      'dist-product', 'dist-approval', 'dist-stats',
      'sys-interface',
      'comm-notice', 'comm-internal', 'comm-archive'],
    topNav: ['dashboard', 'catalog', 'collect', 'distribute', 'meta', 'community', 'system']
  },
  '데이터엔지니어|DBA': {
    screens: ['home', 'process', 'quality', 'measurement', 'asset-db', 'digital-twin', 'ai', 'gallery', 'widget-settings', 'sitemap',
      'cat-search', 'cat-detail', 'cat-graph', 'cat-lineage', 'cat-bookmark', 'cat-request',
      'col-pipeline', 'col-register', 'col-cdc', 'col-kafka', 'col-external', 'col-arch', 'col-monitor', 'col-log', 'col-dbt',
      'meta-glossary', 'meta-tag', 'meta-model', 'meta-dq', 'meta-ontology',
      'meta-std-dashboard', 'meta-std-words', 'meta-std-domains', 'meta-std-terms', 'meta-std-codes', 'meta-std-import',
      'dist-product', 'dist-approval', 'dist-stats',
      'comm-notice', 'comm-internal', 'comm-archive'],
    topNav: ['dashboard', 'catalog', 'collect', 'distribute', 'meta', 'community', 'system']
  },
  '관리자|시스템관리자': {
    screens: ['home', 'process', 'quality', 'measurement', 'asset-db', 'digital-twin', 'ai', 'llmops', 'gallery', 'widget-settings', 'sitemap',
      'cat-search', 'cat-detail', 'cat-graph', 'cat-lineage', 'cat-bookmark', 'cat-request',
      'col-pipeline', 'col-register', 'col-cdc', 'col-kafka', 'col-external', 'col-arch', 'col-monitor', 'col-log', 'col-dbt',
      'dist-product', 'dist-approval', 'dist-stats', 'dist-chart-content',
      'sys-user', 'sys-role', 'sys-security', 'sys-interface', 'sys-audit', 'sys-widget-template', 'sys-perm', 'sys-engine', 'sys-k8s', 'sys-erp-sync', 'sys-ext-register', 'sys-recovery-log',
      'comm-notice', 'comm-internal', 'comm-external', 'comm-archive'],
    topNav: ['dashboard', 'catalog', 'collect', 'distribute', 'community', 'system']
  },
  '관리자|보안관리자': {
    screens: ['home', 'process', 'quality', 'measurement', 'asset-db', 'digital-twin', 'ai', 'gallery', 'widget-settings', 'sitemap',
      'cat-search', 'cat-detail', 'cat-graph', 'cat-lineage', 'cat-bookmark', 'cat-request',
      'col-arch', 'col-log',
      'dist-deidentify', 'dist-approval', 'dist-stats', 'dist-chart-content',
      'sys-user', 'sys-role', 'sys-security', 'sys-audit', 'sys-widget-template', 'sys-perm', 'sys-engine', 'sys-k8s', 'sys-erp-sync', 'sys-ext-register', 'sys-recovery-log',
      'comm-notice', 'comm-archive'],
    topNav: ['dashboard', 'catalog', 'collect', 'distribute', 'community', 'system']
  },
  '관리자|슈퍼관리자': {
    screens: 'ALL',
    topNav: 'ALL'
  }
};

// ===== 데이터 등급 체계 =====
var DATA_LEVELS = { public:1, internal:2, restricted:3, confidential:4 };
var DATA_LEVEL_LABELS = { public:'공개', internal:'내부일반', restricted:'내부중요', confidential:'기밀' };
var DATA_LEVEL_COLORS = { public:'#52c41a', internal:'#1677ff', restricted:'#fa8c16', confidential:'#f5222d' };
var DATA_LEVEL_BG = { public:'#f6ffed', internal:'#e6f7ff', restricted:'#fff7e6', confidential:'#fff1f0' };

// 역할별 최대 열람 등급
var ROLE_DATA_CLEARANCE = {
  '수공직원|일반사용자': 2,
  '수공직원|부서관리자': 3,
  '수공직원|데이터스튜어드': 4,
  '협력직원|데이터조회': 1,
  '협력직원|외부개발자': 1,
  '데이터엔지니어|파이프라인관리자': 4,
  '데이터엔지니어|ETL운영자': 4,
  '데이터엔지니어|DBA': 4,
  '관리자|시스템관리자': 4,
  '관리자|보안관리자': 4,
  '관리자|슈퍼관리자': 4
};

// ===== 화면별 액션 권한 제어 =====
var PERM_LEVELS = { read: 1, write: 2, manage: 3, admin: 4 };

var RBAC_SCREEN_PERMS = {
  '수공직원|일반사용자':           { _default: 'manage', 'dist-product': 'read', 'dist-stats': 'read' },
  '수공직원|부서관리자':           { _default: 'manage', 'dist-approval': 'admin' },
  '수공직원|데이터스튜어드':       { _default: 'manage', 'dist-approval': 'admin' },
  '협력직원|데이터조회':           { _default: 'read', 'cat-request': 'write', 'cat-bookmark': 'manage', 'dist-approval': 'read', 'comm-external': 'write' },
  '협력직원|외부개발자':           { _default: 'read', 'cat-request': 'write', 'cat-bookmark': 'manage', 'dist-approval': 'read', 'dist-api': 'read', 'comm-external': 'write' },
  '데이터엔지니어|파이프라인관리자': { _default: 'manage' },
  '데이터엔지니어|ETL운영자':      { _default: 'manage' },
  '데이터엔지니어|DBA':            { _default: 'manage' },
  '관리자|시스템관리자':           { _default: 'manage', 'sys-user': 'admin', 'sys-role': 'admin', 'sys-security': 'admin', 'sys-perm': 'admin', 'sys-erp-sync': 'admin', 'sys-ext-register': 'admin', 'sys-recovery-log': 'admin', 'dist-approval': 'read' },
  '관리자|보안관리자':             { _default: 'manage', 'sys-security': 'admin', 'sys-audit': 'admin', 'sys-ext-register': 'admin', 'sys-recovery-log': 'admin', 'dist-approval': 'read', 'dist-stats': 'read' },
  '관리자|슈퍼관리자':             { _default: 'admin' }
};

// 상세/등록 화면 → 부모 화면 매핑 (권한 상속 + 사이드바 하이라이트 공용)
var SCREEN_PARENT_MAP = {
  'col-system': 'col-pipeline', 'col-system-detail': 'col-pipeline', 'sys-interface-detail': 'sys-interface',
  'dist-register': 'dist-product', 'dist-detail': 'dist-product',
  'dist-deidentify-detail': 'dist-deidentify', 'dist-api-detail': 'dist-api',
  'meta-model-detail': 'meta-model', 'meta-dq-detail': 'meta-dq',
  'gre-office': 'measurement', 'gre-site': 'measurement',
  'cat-ontology': 'meta-ontology', 'col-dbt-detail': 'col-dbt',
  'cat-data-view': 'cat-lineage', 'cat-quality-report': 'cat-lineage',
  'new-request': 'process',
  'sys-widget-template-register': 'sys-widget-template', 'sys-widget-template-detail': 'sys-widget-template',
  'dist-chart-content-register': 'dist-chart-content', 'dist-chart-content-detail': 'dist-chart-content',
  'cat-detail': 'cat-search', 'col-register': 'col-pipeline',
  'sys-user-detail': 'sys-user',
  'sys-ext-register-detail': 'sys-ext-register'
};

function getScreenPerm(screenId) {
  var roleKey = window.currentRoleKey;
  if (!roleKey) return 'read';

  // 1) localStorage 커스텀 오버라이드 우선 확인
  var parentScreen = SCREEN_PARENT_MAP[screenId];
  var lookupId = parentScreen || screenId;
  var custom = getCustomScreenPerms();
  if (custom[roleKey] && custom[roleKey][lookupId]) {
    return custom[roleKey][lookupId];
  }

  // 2) 기본 매트릭스
  var perms = RBAC_SCREEN_PERMS[roleKey];
  if (!perms) return 'manage';
  return perms[lookupId] || perms._default || 'manage';
}

function getCustomScreenPerms() {
  try {
    return JSON.parse(localStorage.getItem('CUSTOM_SCREEN_PERMS') || '{}');
  } catch(e) { return {}; }
}

function saveCustomScreenPerms(data) {
  localStorage.setItem('CUSTOM_SCREEN_PERMS', JSON.stringify(data));
}

function getScreenPermForRole(roleKey, screenId) {
  // 커스텀 오버라이드 우선
  var custom = getCustomScreenPerms();
  if (custom[roleKey] && custom[roleKey][screenId]) {
    return custom[roleKey][screenId];
  }
  // 기본 매트릭스
  var perms = RBAC_SCREEN_PERMS[roleKey];
  if (!perms) return 'manage';
  return perms[screenId] || perms._default || 'manage';
}

function applyScreenPermissions(screenId) {
  var perm = getScreenPerm(screenId);
  var permLevel = PERM_LEVELS[perm] || 1;
  var target = document.getElementById('screen-' + screenId);
  if (!target) return;

  // 1) data-perm 속성 가진 요소 처리
  target.querySelectorAll('[data-perm]').forEach(function(el) {
    var required = PERM_LEVELS[el.dataset.perm] || 2;
    if (permLevel < required) {
      el.classList.add('perm-hidden');
    } else {
      el.classList.remove('perm-hidden');
    }
  });

  // 2) 읽기 전용 배너 표시/제거
  var existingBanner = target.querySelector('.read-only-banner');
  if (permLevel <= 1) {
    if (!existingBanner) {
      var banner = document.createElement('div');
      banner.className = 'read-only-banner';
      banner.innerHTML = '🔒 읽기 전용 모드 — 현재 권한으로는 조회만 가능합니다';
      var pageTitle = target.querySelector('.page-title');
      if (pageTitle) {
        pageTitle.parentNode.insertBefore(banner, pageTitle.nextSibling);
      } else {
        target.insertBefore(banner, target.children[1] || null);
      }
    }
  } else {
    if (existingBanner) existingBanner.remove();
  }
}

// 위젯/차트 접근 필터 (역할 그룹 + 데이터 등급)
function canAccessItem(item) {
  var roleKey = window.currentRoleKey;
  if (!roleKey) return false;
  var group = getLoginGroup(roleKey);
  if (item.roles !== 'all' && item.roles.indexOf(group) === -1) return false;
  var clearance = ROLE_DATA_CLEARANCE[roleKey] || 1;
  var level = DATA_LEVELS[item.dataLevel] || 1;
  return level <= clearance;
}

function applyRBAC(roleKey) {
  var perm = RBAC_MATRIX[roleKey];
  if (!perm) return;
  var allScreens = perm.screens === 'ALL';
  var allowed = allScreens ? [] : perm.screens;
  var allNav = perm.topNav === 'ALL';
  var allowedNav = allNav ? [] : perm.topNav;

  // 1) 사이드바 메뉴 아이템 필터링
  document.querySelectorAll('.sidebar .menu-item').forEach(function (item) {
    var scr = item.dataset.screen;
    item.style.display = (allScreens || allowed.indexOf(scr) !== -1) ? '' : 'none';
  });

  // 2) 서브 라벨: 뒤따르는 sub-item이 모두 숨겨지면 라벨도 숨김
  document.querySelectorAll('.sidebar .menu-sub-label').forEach(function (label) {
    var next = label.nextElementSibling;
    var hasVisible = false;
    while (next && next.classList.contains('sub-item')) {
      if (next.style.display !== 'none') hasVisible = true;
      next = next.nextElementSibling;
    }
    label.style.display = hasVisible ? '' : 'none';
  });

  // 3) 아코디언 섹션: 자식 메뉴가 모두 숨겨지면 섹션도 숨김
  document.querySelectorAll('.sidebar .accordion-body').forEach(function (body) {
    var visible = 0;
    body.querySelectorAll('.menu-item').forEach(function (m) {
      if (m.style.display !== 'none') visible++;
    });
    var title = document.querySelector('[data-accordion="' + body.id + '"]');
    if (visible === 0) {
      body.style.display = 'none';
      if (title) title.style.display = 'none';
    } else {
      body.style.display = '';
      if (title) title.style.display = '';
    }
  });

  // 4) Top nav 대메뉴 삭제됨
}

function resetRBAC() {
  document.querySelectorAll('.sidebar .menu-item, .sidebar .menu-sub-label, .sidebar .section-title, .sidebar .accordion-body').forEach(function (el) {
    el.style.display = '';
  });
  // top nav 대메뉴 삭제됨
}

function doLogin(type) {
  var roleSelect = document.getElementById(type + '-role');
  var parts = roleSelect.value.split('|');
  var roleName = parts[0];
  var roleDetail = parts[1];
  var userName = roleSelect.options[roleSelect.selectedIndex].text.split('—')[0].trim();
  var roleKey = roleName + '|' + roleDetail;

  // ★ 전역 상태 저장 (대시보드 개인화용)
  window.currentRoleKey = roleKey;
  window.currentUserName = userName;

  // 로그인 오버레이 숨기기
  document.getElementById('loginOverlay').style.display = 'none';
  // 메인 레이아웃 표시
  document.getElementById('topNav').style.display = '';
  document.getElementById('mainLayout').style.display = '';

  // 우상단 사용자 정보 표시
  document.getElementById('userInfo').innerHTML = '<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="#fff" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" style="display:inline-block; vertical-align:-2px; margin-right:4px;"><path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2"/><circle cx="12" cy="7" r="4"/></svg>' + userName + ' <span style="font-size:10px; opacity:.8;">(' + roleName + '/' + roleDetail + ')</span>';

  // RBAC 메뉴 필터링 적용
  applyRBAC(roleKey);

  // 홈 화면으로 이동
  navigate('home');
}

function doLogout() {
  // 로그인 화면 복귀
  document.getElementById('loginOverlay').style.display = '';
  document.getElementById('topNav').style.display = 'none';
  document.getElementById('mainLayout').style.display = 'none';
  // RBAC 초기화
  resetRBAC();
  // 전역 상태 초기화
  window.currentRoleKey = null;
  window.currentUserName = null;
  // 폼 초기화
  switchLoginType('sso');
  // 인증요청 버튼 복원
  var authBtns = document.querySelectorAll('.login-btn-small');
  authBtns.forEach(function (b) { b.textContent = '인증요청'; b.style.background = '#1967d2'; });
}

// Navigation (통합: 화면전환 + 사이드바 + TopNav + Drawer + DnD + Lineage)
function navigate(screen) {
  // ★ 메타데이터 표준사전 시스템 연동 — Vue 앱으로 리다이렉트
  if (screen.startsWith('meta-std-')) {
    var metaRouteMap = {
      'meta-std-dashboard': '/',
      'meta-std-words': '/words',
      'meta-std-domains': '/domain-groups',
      'meta-std-terms': '/terms',
      'meta-std-codes': '/code-groups',
      'meta-std-import': '/import-export'
    };
    var metaPath = metaRouteMap[screen] || '/';
    window.open('http://localhost:5174' + metaPath, '_blank');
    return;
  }

  // 0) RBAC 화면 접근 검증 — 허용되지 않은 화면 차단
  if (window.currentRoleKey) {
    var perm = RBAC_MATRIX[window.currentRoleKey];
    if (perm && perm.screens !== 'ALL') {
      var checkScreen = SCREEN_PARENT_MAP[screen] || screen;
      if (perm.screens.indexOf(checkScreen) === -1 && perm.screens.indexOf(screen) === -1) {
        showToast('접근 권한이 없는 화면입니다.', 'error');
        return;
      }
    }
  }

  // 1) Hide all screens & show target
  document.querySelectorAll('.screen').forEach(s => s.classList.remove('active'));
  const target = document.getElementById('screen-' + screen);
  if (target) {
    target.classList.add('active');
    target.classList.remove('fade-in');
    void target.offsetWidth;
    target.classList.add('fade-in');
  }

  // ★ 화면별 액션 권한 적용 (읽기전용/쓰기/관리/관리자)
  if (window.currentRoleKey) applyScreenPermissions(screen);

  // ★ 홈 화면: 역할별 대시보드 렌더링
  if (screen === 'home' && window.currentRoleKey) {
    renderHomeDashboard();
  }

  // 2) Update sidebar active state
  document.querySelectorAll('.sidebar .menu-item').forEach(m => m.classList.remove('active'));
  document.querySelectorAll('.section-title').forEach(t => t.classList.remove('open'));
  document.querySelectorAll('.accordion-body').forEach(b => b.classList.remove('open'));
  var sidebarScreen = SCREEN_PARENT_MAP[screen] || screen;
  document.querySelectorAll('.sidebar .menu-item').forEach(m => {
    if (m.dataset.screen === sidebarScreen) {
      m.classList.add('active');
      var body = m.closest('.accordion-body');
      if (body) {
        body.classList.add('open');
        var title = document.querySelector('[data-accordion="' + body.id + '"]');
        if (title) title.classList.add('open');
      }
    }
  });

  // 3) Top nav 대메뉴 삭제됨 — 별도 하이라이트 불필요

  // 4) Close process drawer & mobile sidebar
  closeProcessDrawer();
  if (window.innerWidth <= 768) {
    document.body.classList.remove('sidebar-open');
  }

  // 5) Init gallery if needed
  if (screen === 'gallery') {
    setTimeout(initGalleryScreen, 100);
  }

  // 6) Init lineage links if needed
  if (screen === 'cat-lineage') {
    setTimeout(drawLineageLinks, 100);
  }

  // 7) Init knowledge graph if needed
  if (screen === 'cat-graph') {
    setTimeout(initKnowledgeGraph, 100);
  }

  // 8) Init measurement grids
  if (screen === 'measurement') {
    setTimeout(initMeasurementGrid, 100);
  }
  if (screen === 'gre-office') {
    setTimeout(initOfficeGrid, 100);
  }
  if (screen === 'gre-site') {
    setTimeout(initSiteTagGrid, 100);
  }
  if (screen === 'widget-settings') {
    setTimeout(initWidgetSettingsGrid, 100);
  }
  if (screen === 'sys-widget-template') {
    setTimeout(initWidgetTemplateGrid, 100);
  }
  if (screen === 'dist-chart-content') {
    setTimeout(initChartContentGrid, 100);
  }
  if (screen === 'cat-search') {
    setTimeout(initCatalogSearch, 100);
  }
  if (screen === 'sitemap') {
    setTimeout(applySitemapRBAC, 100);
  }
  if (screen === 'col-log') {
    setTimeout(initLogScreen, 100);
  }
  if (screen === 'sys-perm') {
    setTimeout(initPermGrid, 100);
  }
  if (screen === 'meta-glossary') {
    setTimeout(initGlossaryScreen, 100);
  }
  if (screen === 'sys-recovery-log') {
    setTimeout(initRecoveryLogScreen, 100);
  }

  // 9) 데이터모델 목록 — 동적 ERD 미리보기 렌더링 + 모델 화면 초기화
  if (screen === 'meta-model') {
    setTimeout(function () {
      // 모델 화면 초기화 (그리드, KPI, 필터 등)
      if (typeof initMetaModelScreen === 'function') initMetaModelScreen();
      // 동적 ERD 미리보기
      var selector = document.getElementById('erd-model-selector');
      // 셀렉터 옵션이 비어있으면 MODEL_ERD_DATA 키로 채우기
      if (selector && selector.options.length === 0 && typeof MODEL_ERD_DATA !== 'undefined') {
        Object.keys(MODEL_ERD_DATA).forEach(function(key) {
          var opt = document.createElement('option');
          opt.value = key;
          opt.textContent = key;
          selector.appendChild(opt);
        });
      }
      var modelName = selector ? selector.value : '수자원관리_논리모델';
      if (typeof renderDynamicERD === 'function') renderDynamicERD('erd-preview-container', modelName);
    }, 150);
  }

  // 9-1) 분류체계·태그 화면 초기화
  if (screen === 'meta-tag') {
    setTimeout(function () {
      if (typeof initMetaTagScreen === 'function') initMetaTagScreen();
    }, 100);
  }

  // 10) 데이터모델 상세 — 동적 ERD + 논리/물리 매핑 렌더링
  if (screen === 'meta-model-detail') {
    setTimeout(function () {
      var model = window.currentDetailModel || '수자원관리_논리모델';
      if (typeof renderDynamicERD === 'function') renderDynamicERD('erd-detail-container', model);
      if (typeof renderModelMapping === 'function') renderModelMapping(model);
      if (typeof renderModelDetailContent === 'function') renderModelDetailContent();
    }, 150);
  }
}

// Process step highlight + filter table
function highlightStep(el) {
  document.querySelectorAll('.step, .pf-step').forEach(s => { s.classList.remove('active-step'); s.classList.remove('pf-active'); });
  el.classList.add(el.classList.contains('pf-step') ? 'pf-active' : 'active-step');
  // 프로세스 테이블 필터링
  var step = el.dataset && el.dataset.step;
  if (step) {
    var tbody = document.getElementById('process-tbody');
    if (tbody) {
      tbody.querySelectorAll('tr').forEach(function (row) {
        if (step === 'all' || row.dataset.step === step) {
          row.style.display = '';
        } else {
          row.style.display = 'none';
        }
      });
    }
  }
}

// ===== 계측DB 대시보드 AG Grid 초기화 =====
function initMeasurementGrid() {
  var cols = [
    { headerName: '유역/지사', field: 'region', flex: 1.2, minWidth: 120, cellStyle: { fontWeight: '600' } },
    { headerName: '사무소', field: 'offices', width: 90, type: 'numericColumn' },
    { headerName: '사업장', field: 'sites', width: 90, type: 'numericColumn' },
    { headerName: '태그 수', field: 'tags', width: 110, type: 'numericColumn',
      valueFormatter: function(p) { return p.value ? p.value.toLocaleString() : '0'; },
      cellStyle: { fontWeight: '600', color: '#1677ff' }
    },
    { headerName: '비율', field: 'ratio', width: 80,
      cellRenderer: function(p) {
        return '<div style="display:flex;align-items:center;gap:4px;"><div style="flex:1;background:#f0f0f0;border-radius:3px;height:12px;overflow:hidden;"><div style="width:' + p.value + '%;height:100%;background:#1677ff;border-radius:3px;"></div></div><span style="font-size:10px;">' + p.value + '%</span></div>';
      }
    },
    { headerName: '수집률', field: 'collectRate', width: 90,
      cellRenderer: function(p) {
        var color = p.value >= 90 ? '#52c41a' : p.value >= 80 ? '#fa8c16' : '#ff4d4f';
        return '<span style="color:' + color + '; font-weight:600;">' + p.value + '%</span>';
      }
    },
    { headerName: '데이터 건수', field: 'dataCount', width: 120,
      valueFormatter: function(p) { return p.value || '-'; }
    },
    { headerName: '상세', field: 'detail', width: 70, sortable: false, filter: false,
      cellRenderer: function() {
        return '<a href="#" onclick="navigate(\'gre-office\'); return false;" style="color:#1677ff; font-size:11px;">상세 &gt;</a>';
      }
    }
  ];
  var rows = [
    { region: '한강권역본부', offices: 11, sites: 68, tags: 15546, ratio: 21.7, collectRate: 89, dataCount: '4,820만' },
    { region: '강원지역지사', offices: 2, sites: 24, tags: 4457, ratio: 6.2, collectRate: 91, dataCount: '1,380만' },
    { region: '충청지역지사', offices: 12, sites: 85, tags: 16206, ratio: 22.6, collectRate: 92, dataCount: '5,030만' },
    { region: '금영섬권역본부', offices: 7, sites: 52, tags: 7128, ratio: 10.0, collectRate: 78, dataCount: '2,210만' },
    { region: '광주전남지역지사', offices: 10, sites: 71, tags: 6847, ratio: 9.6, collectRate: 83, dataCount: '2,120만' },
    { region: '낙동강권역본부', offices: 8, sites: 63, tags: 9108, ratio: 12.7, collectRate: 88, dataCount: '2,830만' },
    { region: '경남부산지역지사', offices: 11, sites: 100, tags: 12320, ratio: 17.2, collectRate: 85, dataCount: '3,820만' }
  ];
  initAGGrid('meas-grid', cols, rows);
}

function initOfficeGrid() {
  var cols = [
    { headerName: '사업장명', field: 'name', flex: 1, minWidth: 110, cellStyle: { fontWeight: '600' },
      cellRenderer: function(p) {
        return '<a href="#" onclick="navigate(\'gre-site\'); return false;" style="color:#1677ff;">' + p.value + '</a>';
      }
    },
    { headerName: '태그 수', field: 'tags', width: 95, type: 'numericColumn',
      valueFormatter: function(p) { return p.value ? p.value.toLocaleString() : '0'; }
    },
    { headerName: '수집률', field: 'collectRate', width: 90,
      cellRenderer: function(p) {
        var color = p.value >= 95 ? '#52c41a' : p.value >= 80 ? '#fa8c16' : '#ff4d4f';
        return '<span style="font-weight:600; color:' + color + ';">' + p.value + '%</span>';
      }
    },
    { headerName: '수집태그', field: 'collectTags', width: 90, type: 'numericColumn' },
    { headerName: '미수집', field: 'uncollect', width: 80, type: 'numericColumn',
      cellStyle: function(p) { return p.value > 50 ? { color: '#ff4d4f' } : {}; }
    },
    { headerName: '데이터건수', field: 'dataCount', width: 110,
      valueFormatter: function(p) { return p.value || '-'; }
    },
    { headerName: '상태', field: 'status', width: 80,
      cellRenderer: function(p) {
        var cls = p.value === '정상' ? 'badge-success' : p.value === '경고' ? 'badge-warning' : 'badge-error';
        return '<span class="badge ' + cls + '" style="font-size:10px;">' + p.value + '</span>';
      }
    }
  ];
  var rows = [
    { name: 'G81', tags: 2149, collectRate: 38.6, collectTags: 830, uncollect: 1319, dataCount: '8,400만', status: '경고' },
    { name: '시흥정수장', tags: 379, collectRate: 97.8, collectTags: 371, uncollect: 8, dataCount: '1,480만', status: '정상' },
    { name: '반월정수장', tags: 201, collectRate: 97.5, collectTags: 196, uncollect: 5, dataCount: '780만', status: '정상' },
    { name: '거점가압장', tags: 132, collectRate: 83.4, collectTags: 110, uncollect: 22, dataCount: '520만', status: '정상' },
    { name: '안산가압장', tags: 104, collectRate: 100, collectTags: 104, uncollect: 0, dataCount: '410만', status: '정상' },
    { name: '구천암', tags: 68, collectRate: 100, collectTags: 68, uncollect: 0, dataCount: '270만', status: '정상' },
    { name: '경인가압장', tags: 94, collectRate: 90.3, collectTags: 85, uncollect: 9, dataCount: '370만', status: '정상' }
  ];
  initAGGrid('office-site-grid', cols, rows);
}

function initSiteTagGrid() {
  var cols = [
    { headerName: '태그명', field: 'tagName', flex: 1, minWidth: 90, cellStyle: { fontWeight: '500' } },
    { headerName: '상태', field: 'status', width: 80,
      cellRenderer: function(p) {
        var color = p.value === '100%' ? '#52c41a' : p.value === '85%' ? '#fa8c16' : '#ff4d4f';
        return '<span class="badge" style="font-size:10px; background:' + color + '1a; color:' + color + '; border:1px solid ' + color + '40; padding:1px 6px; border-radius:3px;">' + p.value + '</span>';
      }
    },
    { headerName: '설명', field: 'desc', flex: 1.5, minWidth: 140 },
    { headerName: '범주', field: 'category', width: 130 },
    { headerName: '공급인', field: 'supplier', width: 80 },
    { headerName: '태그타입', field: 'tagType', width: 90 },
    { headerName: '데이터건수', field: 'dataCount', width: 95 },
    { headerName: '구간', field: 'section', width: 60, type: 'numericColumn' },
    { headerName: '단위', field: 'unit', width: 75 },
    { headerName: 'ID', field: 'id', width: 55 }
  ];
  var rows = [
    { tagName: 'TAG001', status: '100%', desc: '유량계_전류센서(합천)(10장) 수처리-1', category: 'GSCL0035-10-41270', supplier: '계측', tagType: '전류(A)', dataCount: '1시간', section: 90, unit: 'A', id: '053' },
    { tagName: 'TAG002', status: '100%', desc: '유량계_전류센서(합천)(101) 수처리-2', category: 'GSCL0035-10-41270', supplier: '계측', tagType: '전류(A)', dataCount: '1시간', section: 90, unit: 'A', id: '064' },
    { tagName: 'TAG003', status: '100%', desc: '유량계_전류센서(합천)(10) 수처리-3', category: 'GSCL0035-10-41270', supplier: '계측', tagType: '전류(A)', dataCount: '1시간', section: 90, unit: 'A', id: '005' },
    { tagName: 'TAG004', status: '100%', desc: '전력계_MCC-시설+태양광(구/시) 8호', category: 'SHNO355-10-41270', supplier: '전력', tagType: '전력(kW)', dataCount: '1시간', section: 90, unit: 'kW', id: '201' },
    { tagName: 'TAG005', status: '85%', desc: '전력계_MCC-4호 전력부(2진입) 8호', category: 'SHNO355-10-41270', supplier: '전력', tagType: '전력(kW)', dataCount: '1시간', section: 90, unit: 'kW', id: '202' },
    { tagName: 'TAG006', status: '100%', desc: '전력계_MCC-4로+태양(6진입) 8호', category: 'SHNO355-10-41270', supplier: '전력', tagType: '전력(kW)', dataCount: '1시간', section: 90, unit: 'kW', id: '203' },
    { tagName: 'TAG007', status: '100%', desc: '압력계_송수관 압력센서 FLT', category: 'BYAV1333-35-41270', supplier: '압력', tagType: '압력(MPa)', dataCount: '1시간', section: 90, unit: 'MPa', id: '204' },
    { tagName: 'TAG008', status: '100%', desc: '압력계_배수지 압력센서 FLT', category: 'BYAV1333-35-41270', supplier: '압력', tagType: '전류(A)', dataCount: '1시간', section: 90, unit: 'A', id: '205' },
    { tagName: 'TAG009', status: '100%', desc: '수위계_취수장 수위센서 L-01', category: 'WLVL2010-20-31240', supplier: '수위', tagType: '수위(m)', dataCount: '15분', section: 85, unit: 'm', id: '301' },
    { tagName: 'TAG010', status: '100%', desc: '수위계_정수지 수위센서 L-02', category: 'WLVL2010-20-31240', supplier: '수위', tagType: '수위(m)', dataCount: '15분', section: 85, unit: 'm', id: '302' },
    { tagName: 'TAG011', status: '85%', desc: '유량계_원수 유입 유량센서 F-01', category: 'FLOW3015-30-21150', supplier: '유량', tagType: '유량(m3/h)', dataCount: '1시간', section: 92, unit: 'm3/h', id: '401' },
    { tagName: 'TAG012', status: '100%', desc: '유량계_송수 유량센서 F-02', category: 'FLOW3015-30-21150', supplier: '유량', tagType: '유량(m3/h)', dataCount: '1시간', section: 92, unit: 'm3/h', id: '402' },
    { tagName: 'TAG013', status: '100%', desc: '수질계_탁도 측정센서 TU-01', category: 'QUAL4020-40-11080', supplier: '수질', tagType: '탁도(NTU)', dataCount: '15분', section: 88, unit: 'NTU', id: '501' },
    { tagName: 'TAG014', status: '100%', desc: '수질계_잔류염소 측정 CL-01', category: 'QUAL4020-40-11080', supplier: '수질', tagType: '염소(mg/L)', dataCount: '15분', section: 88, unit: 'mg/L', id: '502' },
    { tagName: 'TAG015', status: '100%', desc: '수질계_pH 측정센서 PH-01', category: 'QUAL4020-40-11080', supplier: '수질', tagType: 'pH', dataCount: '15분', section: 88, unit: 'pH', id: '503' },
    { tagName: 'TAG016', status: '85%', desc: '온도계_원수 수온센서 TE-01', category: 'TEMP5010-50-41270', supplier: '온도', tagType: '온도(C)', dataCount: '1시간', section: 90, unit: 'C', id: '601' }
  ];
  initAGGrid('site-tag-grid', cols, rows, { paginationPageSize: 50, pagination: true });
}

// ===== 통합데이터 카탈로그 =====
var CATALOG_DATASETS = [
  // ── 수자원(water) ──
  { id:'ds-001', tableName:'TB_WATER_LEVEL', name:'수위관측 데이터', icon:'🌊', desc:'전국 342개 관측소별 실시간 수위데이터. 10분 주기 CDC 수집으로 댐·하천·저수지 수위를 통합 모니터링합니다.', domain:'water', system:'RWIS', dataType:'table', collectMethod:'cdc', securityLevel:2, quality:94.2, rowCount:12345670, columnCount:12, updateCycle:'10분', lastUpdate:'2026-02-28 09:30', owner:'수자원관리부', steward:'김수자원', tags:['수위','실시간','CDC','댐','하천','관측소'], views:2456, downloads:189, bookmarks:45, createDate:'2024-06-15', certified:true, popular:true },
  { id:'ds-002', tableName:'TB_FLOW_RATE', name:'유량관측 데이터', icon:'💧', desc:'댐·하천 유량 관측데이터. 초당 CDC 수집으로 유입량·방류량을 정밀 측정합니다.', domain:'water', system:'RWIS', dataType:'table', collectMethod:'cdc', securityLevel:2, quality:92.8, rowCount:9876540, columnCount:15, updateCycle:'1초', lastUpdate:'2026-02-28 09:29', owner:'수자원관리부', steward:'김수자원', tags:['유량','실시간','댐','방류','유입량'], views:1823, downloads:134, bookmarks:38, createDate:'2024-06-15', certified:true, popular:true },
  { id:'ds-003', tableName:'TB_RAINFALL', name:'강수량 관측 데이터', icon:'🌧️', desc:'AWS 자동기상관측소 기반 강수량 데이터. 1분 단위 실시간 수집.', domain:'water', system:'KMA_API', dataType:'table', collectMethod:'api', securityLevel:1, quality:96.1, rowCount:5678900, columnCount:9, updateCycle:'1분', lastUpdate:'2026-02-28 09:28', owner:'수자원관리부', steward:'박기상', tags:['강수량','기상','AWS','실시간','기상청'], views:1567, downloads:98, bookmarks:32, createDate:'2024-08-20', certified:true, popular:false },
  { id:'ds-004', tableName:'TB_DAM_OPERATION', name:'댐 운영 현황', icon:'🏗️', desc:'전국 다목적댐 운영데이터. 수위/저수율/방류량/발전량 종합.', domain:'water', system:'HDAPS', dataType:'table', collectMethod:'batch', securityLevel:2, quality:97.3, rowCount:1234560, columnCount:22, updateCycle:'1시간', lastUpdate:'2026-02-28 09:00', owner:'댐관리부', steward:'이댐운영', tags:['댐','저수율','방류','운영','다목적댐'], views:2134, downloads:201, bookmarks:56, createDate:'2024-05-10', certified:true, popular:true },
  { id:'ds-005', tableName:'TB_GROUNDWATER', name:'지하수위 모니터링', icon:'⛲', desc:'지하수 관측정 수위 데이터. 전국 520개 관측정 30분 주기 수집.', domain:'water', system:'GIMS', dataType:'table', collectMethod:'cdc', securityLevel:2, quality:88.5, rowCount:3456780, columnCount:10, updateCycle:'30분', lastUpdate:'2026-02-28 09:00', owner:'수자원관리부', steward:'최지하수', tags:['지하수','관측정','수위','모니터링'], views:678, downloads:45, bookmarks:12, createDate:'2025-01-15', certified:false, popular:false },
  // ── 수질(quality) ──
  { id:'ds-006', tableName:'TB_WATER_QUALITY', name:'수질분석 측정 데이터', icon:'🔬', desc:'환경부 수질측정망 연계 데이터. pH/DO/BOD/COD/SS 등 30분 주기 수집.', domain:'quality', system:'ENV_API', dataType:'table', collectMethod:'api', securityLevel:2, quality:89.5, rowCount:4567890, columnCount:18, updateCycle:'30분', lastUpdate:'2026-02-28 09:15', owner:'수질관리부', steward:'홍수질', tags:['수질','pH','BOD','COD','환경부','탁도'], views:1987, downloads:156, bookmarks:41, createDate:'2024-07-01', certified:true, popular:true },
  { id:'ds-007', tableName:'TB_SEWAGE_TREATMENT', name:'하수처리장 운영 데이터', icon:'🏭', desc:'하수처리장 유입/방류수 수질·처리효율 데이터. 일별 배치 수집.', domain:'quality', system:'SWIS', dataType:'table', collectMethod:'batch', securityLevel:2, quality:91.2, rowCount:890123, columnCount:24, updateCycle:'1일', lastUpdate:'2026-02-28 06:00', owner:'하수처리부', steward:'박하수', tags:['하수처리','방류수','유입수','처리효율'], views:856, downloads:67, bookmarks:19, createDate:'2024-09-15', certified:false, popular:false },
  { id:'ds-008', tableName:'TB_PURIFICATION', name:'정수장 처리 데이터', icon:'🚰', desc:'정수장 취수/정수/송수 과정별 수질·수량 데이터.', domain:'quality', system:'PWIS', dataType:'table', collectMethod:'cdc', securityLevel:3, quality:95.8, rowCount:2345670, columnCount:20, updateCycle:'10분', lastUpdate:'2026-02-28 09:20', owner:'정수관리부', steward:'김정수', tags:['정수장','취수','정수','송수','처리'], views:1234, downloads:89, bookmarks:28, createDate:'2024-06-01', certified:true, popular:false },
  // ── 에너지(energy) ──
  { id:'ds-009', tableName:'TB_POWER_GENERATION', name:'수력발전 발전량 데이터', icon:'⚡', desc:'수력발전소별 발전량·효율·가동률 일별 집계 데이터.', domain:'energy', system:'HDAPS', dataType:'table', collectMethod:'batch', securityLevel:2, quality:97.1, rowCount:234560, columnCount:14, updateCycle:'1일', lastUpdate:'2026-02-28 01:00', owner:'에너지관리부', steward:'한에너지', tags:['발전량','수력','에너지','효율','가동률'], views:1456, downloads:112, bookmarks:35, createDate:'2024-05-10', certified:true, popular:true },
  { id:'ds-010', tableName:'TB_ENERGY_USAGE', name:'시설 에너지 사용량', icon:'🔋', desc:'전국 K-water 시설물별 전력·용수 에너지 사용량 월별 집계.', domain:'energy', system:'EMS', dataType:'table', collectMethod:'batch', securityLevel:2, quality:93.4, rowCount:156780, columnCount:11, updateCycle:'1월', lastUpdate:'2026-02-01 00:00', owner:'에너지관리부', steward:'한에너지', tags:['에너지','전력','사용량','시설','월별'], views:567, downloads:34, bookmarks:10, createDate:'2025-03-01', certified:false, popular:false },
  { id:'ds-011', tableName:'TB_SOLAR_GENERATION', name:'태양광 발전 데이터', icon:'☀️', desc:'K-water 보유 태양광 발전설비 발전량 및 일사량 데이터.', domain:'energy', system:'SEMS', dataType:'table', collectMethod:'cdc', securityLevel:1, quality:90.2, rowCount:789012, columnCount:8, updateCycle:'15분', lastUpdate:'2026-02-28 09:15', owner:'신재생에너지부', steward:'이솔라', tags:['태양광','신재생','발전','일사량'], views:423, downloads:28, bookmarks:8, createDate:'2025-06-01', certified:false, popular:false },
  // ── 인프라·시설(infra) ──
  { id:'ds-012', tableName:'TB_PIPE_NETWORK', name:'관로 네트워크 데이터', icon:'🔧', desc:'광역상수도 관로 제원·노후도·사고이력 GIS 연계 데이터.', domain:'infra', system:'FMIS', dataType:'table', collectMethod:'batch', securityLevel:3, quality:86.7, rowCount:456789, columnCount:28, updateCycle:'1주', lastUpdate:'2026-02-24 00:00', owner:'시설관리부', steward:'정관로', tags:['관로','GIS','노후도','상수도','시설'], views:934, downloads:56, bookmarks:22, createDate:'2024-04-01', certified:false, popular:false },
  { id:'ds-013', tableName:'TB_LEAK_DETECTION', name:'누수탐지 센서 데이터', icon:'💦', desc:'스마트 누수탐지 센서(음향/유량/압력) 실시간 수집 데이터.', domain:'infra', system:'LEAK_IoT', dataType:'table', collectMethod:'cdc', securityLevel:2, quality:87.3, rowCount:6789012, columnCount:14, updateCycle:'5분', lastUpdate:'2026-02-28 09:25', owner:'시설관리부', steward:'김누수', tags:['누수','탐지','IoT','센서','압력','음향'], views:1123, downloads:78, bookmarks:25, createDate:'2024-10-01', certified:false, popular:true },
  { id:'ds-014', tableName:'TB_GIS_FACILITY', name:'시설물 GIS 공간정보', icon:'🗺️', desc:'K-water 전 시설물(댐/보/관로/정수장/취수장) GIS 좌표·속성.', domain:'infra', system:'GIS_DB', dataType:'table', collectMethod:'batch', securityLevel:3, quality:92.1, rowCount:89012, columnCount:32, updateCycle:'1월', lastUpdate:'2026-02-01 00:00', owner:'공간정보부', steward:'이GIS', tags:['GIS','공간정보','좌표','시설물','지도'], views:1567, downloads:123, bookmarks:48, createDate:'2024-03-15', certified:true, popular:false },
  { id:'ds-015', tableName:'TB_SCADA_SIGNAL', name:'SCADA 제어신호 데이터', icon:'📡', desc:'정수장·취수장 SCADA 시스템 제어/계측 신호 실시간 수집.', domain:'infra', system:'SCADA', dataType:'table', collectMethod:'cdc', securityLevel:4, quality:98.5, rowCount:23456780, columnCount:16, updateCycle:'1초', lastUpdate:'2026-02-28 09:30', owner:'운영관제부', steward:'박제어', tags:['SCADA','제어','계측','정수장','실시간'], views:345, downloads:12, bookmarks:5, createDate:'2025-02-01', certified:true, popular:false },
  // ── 고객·요금(customer) ──
  { id:'ds-016', tableName:'TB_CUSTOMER_INFO', name:'고객정보 마스터', icon:'👤', desc:'광역/지방 상수도 고객 기본정보(익명처리) 및 계약 데이터.', domain:'customer', system:'CIS', dataType:'table', collectMethod:'batch', securityLevel:4, quality:99.1, rowCount:3456789, columnCount:25, updateCycle:'1일', lastUpdate:'2026-02-28 02:00', owner:'고객서비스부', steward:'이고객', tags:['고객','계약','상수도','마스터','익명화'], views:234, downloads:8, bookmarks:3, createDate:'2024-05-01', certified:true, popular:false },
  { id:'ds-017', tableName:'TB_BILLING_HISTORY', name:'요금 청구 이력', icon:'💰', desc:'월별 상수도 요금 청구·수납·미납 이력 데이터.', domain:'customer', system:'CIS', dataType:'table', collectMethod:'batch', securityLevel:4, quality:98.7, rowCount:12345678, columnCount:18, updateCycle:'1월', lastUpdate:'2026-02-01 00:00', owner:'요금관리부', steward:'박요금', tags:['요금','청구','수납','미납','이력'], views:189, downloads:5, bookmarks:2, createDate:'2024-05-01', certified:true, popular:false },
  // ── 외부연계(external) ──
  { id:'ds-018', tableName:'API_WEATHER_FORECAST', name:'기상청 기상예보 API', icon:'🌤️', desc:'기상청 단기예보/중기예보/특보 연계 API 수집 데이터.', domain:'water', system:'KMA_API', dataType:'api', collectMethod:'api', securityLevel:1, quality:91.5, rowCount:890123, columnCount:12, updateCycle:'3시간', lastUpdate:'2026-02-28 09:00', owner:'수자원관리부', steward:'박기상', tags:['기상','예보','기상청','API','날씨'], views:987, downloads:67, bookmarks:18, createDate:'2024-09-01', certified:false, popular:false },
  { id:'ds-019', tableName:'API_FLOOD_WARNING', name:'홍수예보 경보 데이터', icon:'🚨', desc:'홍수통제소 홍수예보·경보 발령 현황 및 예측 수위 데이터.', domain:'water', system:'FFC_API', dataType:'api', collectMethod:'api', securityLevel:1, quality:99.5, rowCount:34567, columnCount:10, updateCycle:'실시간', lastUpdate:'2026-02-28 09:30', owner:'재난안전부', steward:'강홍수', tags:['홍수','경보','예보','재난','긴급'], views:2345, downloads:234, bookmarks:67, createDate:'2024-04-01', certified:true, popular:true },
  // ── 파일/모델(file/view) ──
  { id:'ds-020', tableName:'FILE_SATELLITE_IMG', name:'위성영상 수질분석', icon:'🛰️', desc:'환경위성 기반 녹조·탁도 원격탐사 영상 데이터(GeoTIFF).', domain:'quality', system:'KOEM', dataType:'file', collectMethod:'batch', securityLevel:2, quality:85.3, rowCount:12345, columnCount:0, updateCycle:'1일', lastUpdate:'2026-02-28 06:00', owner:'수질관리부', steward:'홍수질', tags:['위성','영상','녹조','원격탐사','GeoTIFF'], views:456, downloads:89, bookmarks:15, createDate:'2025-04-01', certified:false, popular:false },
  { id:'ds-021', tableName:'VW_DAILY_WATER_REPORT', name:'일별 수자원 종합 리포트', icon:'📊', desc:'일별 수위/유량/수질/발전 주요지표 종합 집계 뷰(dbt 모델).', domain:'water', system:'DW', dataType:'view', collectMethod:'batch', securityLevel:2, quality:96.8, rowCount:36500, columnCount:35, updateCycle:'1일', lastUpdate:'2026-02-28 05:00', owner:'데이터분석부', steward:'김분석', tags:['리포트','종합','일별','집계','dbt','분석'], views:3456, downloads:345, bookmarks:89, createDate:'2024-07-01', certified:true, popular:true },
  { id:'ds-022', tableName:'TB_SMART_METER', name:'스마트 수도미터 데이터', icon:'📱', desc:'AMI 스마트미터 실시간 사용량 및 이상탐지 데이터.', domain:'customer', system:'AMI', dataType:'table', collectMethod:'cdc', securityLevel:3, quality:88.9, rowCount:8901234, columnCount:11, updateCycle:'15분', lastUpdate:'2026-02-28 09:15', owner:'스마트워터부', steward:'정스마트', tags:['스마트미터','AMI','사용량','이상탐지','IoT'], views:678, downloads:45, bookmarks:14, createDate:'2025-08-01', certified:false, popular:false },
  { id:'ds-023', tableName:'TB_DROUGHT_INDEX', name:'가뭄지수 산정 데이터', icon:'🏜️', desc:'SPI/PDSI/EDI 가뭄지수 산정 결과 및 원시 기상·수문 입력 데이터.', domain:'water', system:'DW', dataType:'view', collectMethod:'batch', securityLevel:1, quality:93.7, rowCount:45678, columnCount:15, updateCycle:'1주', lastUpdate:'2026-02-24 00:00', owner:'수자원관리부', steward:'김수자원', tags:['가뭄','지수','SPI','기상','수문'], views:567, downloads:34, bookmarks:11, createDate:'2025-05-15', certified:true, popular:false },
  { id:'ds-024', tableName:'TB_PIPE_PRESSURE', name:'관로 압력 모니터링', icon:'🔴', desc:'광역상수도 주요 관로 압력계 실시간 데이터. DMA 블록별 수집.', domain:'infra', system:'SCADA', dataType:'table', collectMethod:'cdc', securityLevel:3, quality:91.8, rowCount:5678901, columnCount:9, updateCycle:'1분', lastUpdate:'2026-02-28 09:29', owner:'시설관리부', steward:'정관로', tags:['압력','관로','DMA','모니터링','실시간'], views:789, downloads:56, bookmarks:16, createDate:'2025-01-10', certified:false, popular:false },
  { id:'ds-025', tableName:'TB_RESERVOIR_LEVEL', name:'저수지 수위·저수율', icon:'🏞️', desc:'농업용·다목적 저수지 수위 및 저수율 현황 데이터.', domain:'water', system:'RIMS', dataType:'table', collectMethod:'batch', securityLevel:1, quality:90.4, rowCount:567890, columnCount:8, updateCycle:'1시간', lastUpdate:'2026-02-28 09:00', owner:'수자원관리부', steward:'이댐운영', tags:['저수지','저수율','수위','농업용'], views:456, downloads:23, bookmarks:7, createDate:'2025-07-01', certified:false, popular:false },
  { id:'ds-026', tableName:'TB_WTP_CHEMICAL', name:'정수장 약품투입 데이터', icon:'🧪', desc:'정수장별 응집제/소독제/pH조정제 투입량 및 잔류농도 데이터.', domain:'quality', system:'PWIS', dataType:'table', collectMethod:'cdc', securityLevel:3, quality:94.6, rowCount:1234567, columnCount:13, updateCycle:'10분', lastUpdate:'2026-02-28 09:20', owner:'정수관리부', steward:'김정수', tags:['약품','응집제','소독','정수장','투입량'], views:345, downloads:18, bookmarks:6, createDate:'2025-04-15', certified:false, popular:false }
];

// 카탈로그 검색 상태
var catSearchState = {
  keyword: '',
  domain: 'all',
  dataType: 'all',
  collectMethod: 'all',
  securityLevel: 'all',
  qualityMin: 0,
  sort: 'relevance',
  viewMode: 'card',
  page: 1,
  pageSize: 8,
  activeTags: []
};

function initCatalogSearch() {
  catSearchState = { keyword:'', domain:'all', dataType:'all', collectMethod:'all', securityLevel:'all', qualityMin:0, sort:'relevance', viewMode:'card', page:1, pageSize:8, activeTags:[] };
  // 검색입력
  var inp = document.getElementById('catSearchInput');
  if (inp) {
    inp.value = '';
    inp.oninput = function() { catSearchState.keyword = this.value; catSearchState.page = 1; renderCatalogResults(); };
    inp.onkeydown = function(e) { if (e.key === 'Enter') { catSearchState.keyword = this.value; catSearchState.page = 1; renderCatalogResults(); } };
  }
  // 필터 select
  var domSel = document.getElementById('catFilterDomain');
  var typeSel = document.getElementById('catFilterType');
  var methSel = document.getElementById('catFilterMethod');
  var secSel = document.getElementById('catFilterSecurity');
  var sortSel = document.getElementById('catSortSelect');
  if (domSel) domSel.onchange = function() { catSearchState.domain = this.value; catSearchState.page = 1; renderCatalogResults(); };
  if (typeSel) typeSel.onchange = function() { catSearchState.dataType = this.value; catSearchState.page = 1; renderCatalogResults(); };
  if (methSel) methSel.onchange = function() { catSearchState.collectMethod = this.value; catSearchState.page = 1; renderCatalogResults(); };
  if (secSel) secSel.onchange = function() { catSearchState.securityLevel = this.value; catSearchState.page = 1; renderCatalogResults(); };
  if (sortSel) sortSel.onchange = function() { catSearchState.sort = this.value; catSearchState.page = 1; renderCatalogResults(); };
  // 품질 슬라이더
  var qSlider = document.getElementById('catQualitySlider');
  var qVal = document.getElementById('catQualityValue');
  if (qSlider) {
    qSlider.oninput = function() { catSearchState.qualityMin = parseInt(this.value); if(qVal) qVal.textContent = this.value + '%'; catSearchState.page = 1; renderCatalogResults(); };
  }
  // 태그 필
  document.querySelectorAll('.cat-tag-pill').forEach(function(pill) {
    pill.onclick = function() {
      var tag = this.dataset.tag;
      var idx = catSearchState.activeTags.indexOf(tag);
      if (idx >= 0) { catSearchState.activeTags.splice(idx, 1); this.classList.remove('active'); }
      else { catSearchState.activeTags.push(tag); this.classList.add('active'); }
      catSearchState.page = 1;
      renderCatalogResults();
    };
  });
  // 뷰 모드 토글
  document.querySelectorAll('.cat-view-btn').forEach(function(btn) {
    btn.onclick = function() {
      document.querySelectorAll('.cat-view-btn').forEach(function(b) { b.classList.remove('active'); });
      this.classList.add('active');
      catSearchState.viewMode = this.dataset.view;
      renderCatalogResults();
    };
  });
  renderCatalogResults();
}

function filterCatalogDatasets() {
  var s = catSearchState;
  var kw = s.keyword.toLowerCase().trim();
  return CATALOG_DATASETS.filter(function(d) {
    // 키워드 검색 (이름, 테이블명, 설명, 태그, 시스템, 담당자)
    if (kw) {
      var haystack = (d.tableName + ' ' + d.name + ' ' + d.desc + ' ' + d.tags.join(' ') + ' ' + d.system + ' ' + d.steward + ' ' + d.owner).toLowerCase();
      if (haystack.indexOf(kw) < 0) return false;
    }
    // 도메인
    if (s.domain !== 'all' && d.domain !== s.domain) return false;
    // 데이터유형
    if (s.dataType !== 'all' && d.dataType !== s.dataType) return false;
    // 수집방식
    if (s.collectMethod !== 'all' && d.collectMethod !== s.collectMethod) return false;
    // 보안등급
    if (s.securityLevel !== 'all' && d.securityLevel !== parseInt(s.securityLevel)) return false;
    // 품질 최소
    if (s.qualityMin > 0 && d.quality < s.qualityMin) return false;
    // 태그 필터 (OR 조건)
    if (s.activeTags.length > 0) {
      var hasTag = false;
      for (var i = 0; i < s.activeTags.length; i++) {
        if (d.tags.indexOf(s.activeTags[i]) >= 0) { hasTag = true; break; }
      }
      if (!hasTag) return false;
    }
    return true;
  });
}

function sortCatalogDatasets(arr) {
  var s = catSearchState.sort;
  var sorted = arr.slice();
  if (s === 'latest') sorted.sort(function(a, b) { return b.lastUpdate.localeCompare(a.lastUpdate); });
  else if (s === 'quality') sorted.sort(function(a, b) { return b.quality - a.quality; });
  else if (s === 'name') sorted.sort(function(a, b) { return a.name.localeCompare(b.name); });
  else if (s === 'views') sorted.sort(function(a, b) { return b.views - a.views; });
  else if (s === 'rows') sorted.sort(function(a, b) { return b.rowCount - a.rowCount; });
  else { // relevance — popular + views
    sorted.sort(function(a, b) { return (b.popular ? 1000 : 0) + b.views - (a.popular ? 1000 : 0) - a.views; });
  }
  return sorted;
}

function renderCatalogResults() {
  var filtered = filterCatalogDatasets();
  var sorted = sortCatalogDatasets(filtered);
  var s = catSearchState;
  var total = sorted.length;
  var totalPages = Math.ceil(total / s.pageSize) || 1;
  if (s.page > totalPages) s.page = totalPages;
  var start = (s.page - 1) * s.pageSize;
  var paged = sorted.slice(start, start + s.pageSize);

  // KPI 업데이트
  var kpiTotal = document.getElementById('catKpiTotal');
  var kpiRealtime = document.getElementById('catKpiRealtime');
  var kpiQuality = document.getElementById('catKpiQuality');
  var kpiCertified = document.getElementById('catKpiCertified');
  if (kpiTotal) kpiTotal.textContent = total + '건';
  if (kpiRealtime) {
    var rt = filtered.filter(function(d) { return d.collectMethod === 'cdc'; }).length;
    kpiRealtime.textContent = rt + '건';
  }
  if (kpiQuality) {
    var avg = filtered.length ? (filtered.reduce(function(sum, d) { return sum + d.quality; }, 0) / filtered.length).toFixed(1) : '0';
    kpiQuality.textContent = avg + '%';
  }
  if (kpiCertified) {
    var cert = filtered.filter(function(d) { return d.certified; }).length;
    kpiCertified.textContent = cert + '건';
  }

  // 결과 수
  var countEl = document.getElementById('catResultCount');
  if (countEl) countEl.innerHTML = '검색결과 <strong>' + total + '</strong>건' + (s.keyword ? ' &nbsp;· &nbsp;<span style="color:#1967d2;">"' + escHtml(s.keyword) + '"</span>' : '');

  // 도메인 facet 카운트
  var domainCounts = {};
  CATALOG_DATASETS.forEach(function(d) { domainCounts[d.domain] = (domainCounts[d.domain] || 0) + 1; });
  document.querySelectorAll('.cat-facet-count').forEach(function(el) {
    var key = el.dataset.domain;
    if (key && domainCounts[key] !== undefined) el.textContent = '(' + domainCounts[key] + ')';
  });

  // 결과 렌더링
  var container = document.getElementById('catResultsContainer');
  if (!container) return;
  if (paged.length === 0) {
    container.innerHTML = '<div style="text-align:center; padding:60px 20px; color:var(--text-secondary);"><div style="font-size:48px; margin-bottom:16px;">🔍</div><div style="font-size:16px; font-weight:600; margin-bottom:8px;">검색 결과가 없습니다</div><div style="font-size:13px;">검색어 또는 필터 조건을 변경해 보세요.</div></div>';
    renderCatalogPagination(total, totalPages);
    return;
  }

  var domainLabels = { water:'수자원', quality:'수질', energy:'에너지', infra:'인프라', customer:'고객', system:'시스템' };
  var domainColors = { water:'#1677ff', quality:'#52c41a', energy:'#fa8c16', infra:'#722ed1', customer:'#eb2f96', system:'#5c6bc0' };
  var domainBg = { water:'#e6f7ff', quality:'#f6ffed', energy:'#fff7e6', infra:'#f9f0ff', customer:'#fff0f6', system:'#f0f0ff' };
  var typeLabels = { table:'테이블', api:'API', file:'파일', view:'뷰/모델' };
  var methodLabels = { cdc:'실시간(CDC)', batch:'배치(ETL)', api:'API 수집', file:'파일수집' };
  var secLabels = { 1:'공개', 2:'내부일반', 3:'내부중요', 4:'기밀' };
  var secColors = { 1:'#52c41a', 2:'#1677ff', 3:'#fa8c16', 4:'#f5222d' };
  var secBg = { 1:'#f6ffed', 2:'#e6f7ff', 3:'#fff7e6', 4:'#fff1f0' };

  var html = '';
  if (s.viewMode === 'card') {
    html = '<div class="cat-results-grid">';
    paged.forEach(function(d) {
      var qColor = d.quality >= 95 ? '#52c41a' : d.quality >= 90 ? '#1677ff' : d.quality >= 85 ? '#fa8c16' : '#f5222d';
      html += '<div class="cat-dataset-card" onclick="showCatalogDetail(\'' + d.id + '\')">';
      // 헤더
      html += '<div class="cat-card-header">';
      html += '<div class="cat-card-icon" style="background:' + (domainBg[d.domain] || '#f5f5f5') + ';color:' + (domainColors[d.domain] || '#666') + ';">' + d.icon + '</div>';
      html += '<div class="cat-card-badges">';
      if (d.certified) html += '<span class="cat-badge certified" title="인증 데이터셋">✓ 인증</span>';
      if (d.popular) html += '<span class="cat-badge popular">🔥 인기</span>';
      html += '</div>';
      html += '</div>';
      // 이름 & 테이블명
      html += '<div class="cat-card-name">' + d.name + '</div>';
      html += '<div class="cat-card-table"><code>' + d.tableName + '</code></div>';
      // 설명
      html += '<div class="cat-card-desc">' + d.desc + '</div>';
      // 메타 정보
      html += '<div class="cat-card-meta">';
      html += '<span style="background:' + (domainBg[d.domain] || '#f5f5f5') + ';color:' + (domainColors[d.domain] || '#666') + ';">' + (domainLabels[d.domain] || d.domain) + '</span>';
      html += '<span style="background:var(--bg-color,#f0f2f5);color:var(--text-secondary,#555);">' + (typeLabels[d.dataType] || d.dataType) + '</span>';
      html += '<span style="background:' + (secBg[d.securityLevel] || '#f5f5f5') + ';color:' + (secColors[d.securityLevel] || '#666') + ';">' + (secLabels[d.securityLevel] || d.securityLevel + '등급') + '</span>';
      html += '</div>';
      // 통계 바
      html += '<div class="cat-card-stats">';
      html += '<div class="cat-stat"><span class="cat-stat-label">품질</span><span class="cat-stat-value" style="color:' + qColor + ';">' + d.quality + '%</span></div>';
      html += '<div class="cat-stat"><span class="cat-stat-label">건수</span><span class="cat-stat-value">' + formatRowCount(d.rowCount) + '</span></div>';
      html += '<div class="cat-stat"><span class="cat-stat-label">조회</span><span class="cat-stat-value">' + d.views.toLocaleString() + '</span></div>';
      html += '<div class="cat-stat"><span class="cat-stat-label">주기</span><span class="cat-stat-value">' + d.updateCycle + '</span></div>';
      html += '</div>';
      // 태그
      html += '<div class="cat-card-tags">';
      d.tags.slice(0, 4).forEach(function(t) { html += '<span class="cat-tag">' + t + '</span>'; });
      if (d.tags.length > 4) html += '<span class="cat-tag" style="color:#999;">+' + (d.tags.length - 4) + '</span>';
      html += '</div>';
      // 하단
      html += '<div class="cat-card-footer">';
      html += '<span>📦 ' + d.system + '</span>';
      html += '<span>👤 ' + d.steward + '</span>';
      html += '<span>🕐 ' + d.lastUpdate.substring(0, 10) + '</span>';
      html += '</div>';
      html += '</div>';
    });
    html += '</div>';
  } else {
    // 리스트 뷰
    html = '<div class="cat-results-list">';
    paged.forEach(function(d) {
      var qColor = d.quality >= 95 ? '#52c41a' : d.quality >= 90 ? '#1677ff' : d.quality >= 85 ? '#fa8c16' : '#f5222d';
      html += '<div class="cat-list-item" onclick="showCatalogDetail(\'' + d.id + '\')">';
      html += '<div class="cat-list-icon" style="background:' + (domainBg[d.domain] || '#f5f5f5') + ';color:' + (domainColors[d.domain] || '#666') + ';">' + d.icon + '</div>';
      html += '<div class="cat-list-body">';
      html += '<div class="cat-list-title">';
      html += '<span class="cat-list-name">' + d.name + '</span>';
      html += '<code class="cat-list-table">' + d.tableName + '</code>';
      if (d.certified) html += '<span class="cat-badge certified" style="font-size:10px;">✓ 인증</span>';
      if (d.popular) html += '<span class="cat-badge popular" style="font-size:10px;">🔥</span>';
      html += '</div>';
      html += '<div class="cat-list-desc">' + d.desc + '</div>';
      html += '<div class="cat-list-meta">';
      html += '<span style="background:' + (domainBg[d.domain] || '#f5f5f5') + ';color:' + (domainColors[d.domain] || '#666') + ';">' + (domainLabels[d.domain] || d.domain) + '</span>';
      html += '<span style="background:var(--bg-color,#f0f2f5);color:var(--text-secondary,#555);">' + (typeLabels[d.dataType] || d.dataType) + '</span>';
      html += '<span style="background:var(--bg-color,#f0f2f5);color:var(--text-secondary,#555);">' + (methodLabels[d.collectMethod] || d.collectMethod) + '</span>';
      html += '<span style="background:' + (secBg[d.securityLevel] || '#f5f5f5') + ';color:' + (secColors[d.securityLevel] || '#666') + ';">' + (secLabels[d.securityLevel] || '') + '</span>';
      d.tags.slice(0, 3).forEach(function(t) { html += '<span class="cat-tag">' + t + '</span>'; });
      html += '</div>';
      html += '</div>';
      html += '<div class="cat-list-right">';
      html += '<div class="cat-stat-mini"><span style="color:' + qColor + ';font-weight:700;font-size:15px;">' + d.quality + '%</span><span style="font-size:10px;color:#999;">품질</span></div>';
      html += '<div class="cat-stat-mini"><span style="font-weight:600;font-size:13px;">' + formatRowCount(d.rowCount) + '</span><span style="font-size:10px;color:#999;">건수</span></div>';
      html += '<div class="cat-stat-mini"><span style="font-size:12px;color:#888;">👁 ' + d.views.toLocaleString() + '</span></div>';
      html += '</div>';
      html += '</div>';
    });
    html += '</div>';
  }
  container.innerHTML = html;
  renderCatalogPagination(total, totalPages);
}

function renderCatalogPagination(total, totalPages) {
  var pag = document.getElementById('catPagination');
  if (!pag) return;
  if (totalPages <= 1) { pag.innerHTML = ''; return; }
  var cp = catSearchState.page;
  var html = '<div class="cat-pagination">';
  html += '<button class="cat-page-btn" ' + (cp <= 1 ? 'disabled' : '') + ' onclick="catGoPage(' + (cp - 1) + ')">‹ 이전</button>';
  var startP = Math.max(1, cp - 2);
  var endP = Math.min(totalPages, startP + 4);
  if (endP - startP < 4) startP = Math.max(1, endP - 4);
  for (var i = startP; i <= endP; i++) {
    html += '<button class="cat-page-btn' + (i === cp ? ' active' : '') + '" onclick="catGoPage(' + i + ')">' + i + '</button>';
  }
  html += '<button class="cat-page-btn" ' + (cp >= totalPages ? 'disabled' : '') + ' onclick="catGoPage(' + (cp + 1) + ')">다음 ›</button>';
  html += '<span class="cat-page-info">' + cp + ' / ' + totalPages + ' 페이지 (총 ' + total + '건)</span>';
  html += '</div>';
  pag.innerHTML = html;
}

function catGoPage(p) { catSearchState.page = p; renderCatalogResults(); window.scrollTo(0, 0); }

function catResetFilters() {
  catSearchState = { keyword:'', domain:'all', dataType:'all', collectMethod:'all', securityLevel:'all', qualityMin:0, sort:'relevance', viewMode:catSearchState.viewMode, page:1, pageSize:8, activeTags:[] };
  var inp = document.getElementById('catSearchInput');
  if (inp) inp.value = '';
  document.querySelectorAll('#screen-cat-search select').forEach(function(sel) { sel.selectedIndex = 0; });
  document.querySelectorAll('.cat-tag-pill').forEach(function(p) { p.classList.remove('active'); });
  var qs = document.getElementById('catQualitySlider');
  if (qs) { qs.value = 0; }
  var qv = document.getElementById('catQualityValue');
  if (qv) qv.textContent = '0%';
  renderCatalogResults();
}

function showCatalogDetail(id) {
  var d = CATALOG_DATASETS.find(function(x) { return x.id === id; });
  if (!d) { alert('데이터셋을 찾을 수 없습니다.'); return; }
  // navigate to cat-detail (기존 상세 화면 활용)
  navigate('cat-detail');
}

function formatRowCount(n) {
  if (n >= 10000000) return (n / 10000000).toFixed(1) + '천만';
  if (n >= 10000) return (n / 10000).toFixed(0) + '만';
  if (n >= 1000) return (n / 1000).toFixed(1) + 'K';
  return n.toString();
}

function escHtml(s) { var d = document.createElement('div'); d.textContent = s; return d.innerHTML; }

// ===== 시각화·차트 갤러리 (수공 분석 데이터 전용) =====
var GAL_CHARTS = [
  // ── 수질·수량 ──
  { id:'g-dam-level', roles:'all', dataLevel:'public', icon:'🌊', name:'댐 수위 추이 (24h)', domain:'water', type:'line', desc:'주요 댐 실시간 수위 변화 추이', author:'김수자원', date:'2026-02-25', likes:24, mine:true, recommend:true, popular:true, color:'#1677ff',
    svg:'<svg viewBox="0 0 180 50"><polyline points="0,42 25,35 50,28 75,32 100,20 125,24 150,15 180,18" fill="none" stroke="#1677ff" stroke-width="2"/><polyline points="0,45 25,40 50,35 75,38 100,30 125,32 150,25 180,28" fill="none" stroke="#91d5ff" stroke-width="1.5" stroke-dasharray="3,2"/></svg>' },
  { id:'g-water-quality', roles:'all', dataLevel:'public', icon:'💧', name:'수질 항목별 현황', domain:'water', type:'bar', desc:'pH/DO/BOD/COD 항목별 측정 현황', author:'이수질', date:'2026-02-26', likes:31, mine:true, recommend:true, popular:true, color:'#52c41a',
    svg:'<svg viewBox="0 0 180 50"><rect x="5" y="15" width="20" height="35" fill="#52c41a" rx="2"/><rect x="30" y="10" width="20" height="40" fill="#73d13d" rx="2"/><rect x="55" y="22" width="20" height="28" fill="#95de64" rx="2"/><rect x="80" y="8" width="20" height="42" fill="#52c41a" rx="2"/><rect x="105" y="18" width="20" height="32" fill="#b7eb8f" rx="2"/><rect x="130" y="12" width="20" height="38" fill="#73d13d" rx="2"/></svg>' },
  { id:'g-flow-rate', roles:'all', dataLevel:'public', icon:'🏞️', name:'유량 모니터링', domain:'water', type:'area', desc:'주요 관측소 실시간 유량 현황', author:'김수자원', date:'2026-02-24', likes:18, mine:true, recommend:false, popular:false, color:'#13c2c2',
    svg:'<svg viewBox="0 0 180 50"><path d="M0,45 Q30,30 60,35 T120,20 T180,28 V50 H0Z" fill="#e6fffb" stroke="#13c2c2" stroke-width="1.5"/></svg>' },
  { id:'g-rainfall', roles:'all', dataLevel:'public', icon:'🌧️', name:'강수량 분포', domain:'water', type:'bar', desc:'일별·지역별 강수량 분포 분석', author:'박기상', date:'2026-02-20', likes:15, mine:false, recommend:true, popular:false, color:'#2f54eb',
    svg:'<svg viewBox="0 0 180 50"><rect x="5" y="30" width="14" height="20" fill="#2f54eb" rx="2"/><rect x="23" y="20" width="14" height="30" fill="#597ef7" rx="2"/><rect x="41" y="10" width="14" height="40" fill="#2f54eb" rx="2"/><rect x="59" y="25" width="14" height="25" fill="#85a5ff" rx="2"/><rect x="77" y="15" width="14" height="35" fill="#2f54eb" rx="2"/><rect x="95" y="35" width="14" height="15" fill="#adc6ff" rx="2"/><rect x="113" y="28" width="14" height="22" fill="#597ef7" rx="2"/><rect x="131" y="5" width="14" height="45" fill="#2f54eb" rx="2"/><rect x="149" y="18" width="14" height="32" fill="#85a5ff" rx="2"/></svg>' },
  { id:'g-turbidity', roles:'all', dataLevel:'public', icon:'🔬', name:'탁도 모니터링', domain:'water', type:'line', desc:'취수장별 탁도(NTU) 실시간 추이', author:'이수질', date:'2026-02-27', likes:20, mine:true, recommend:true, popular:true, color:'#8d6e63',
    svg:'<svg viewBox="0 0 180 50"><polyline points="0,35 20,30 40,38 60,25 80,32 100,18 120,28 140,22 160,30 180,24" fill="none" stroke="#8d6e63" stroke-width="2"/><line x1="0" y1="20" x2="180" y2="20" stroke="#f5222d" stroke-width="1" stroke-dasharray="4,3"/><text x="155" y="17" font-size="6" fill="#f5222d">기준</text></svg>' },
  { id:'g-groundwater', roles:'all', dataLevel:'public', icon:'🕳️', name:'지하수 수위 변화', domain:'water', type:'area', desc:'관측정별 지하수위 월별 변화 추이', author:'김수자원', date:'2026-02-22', likes:12, mine:false, recommend:false, popular:false, color:'#006d75',
    svg:'<svg viewBox="0 0 180 50"><path d="M0,20 Q30,25 60,22 T120,30 T180,26 V50 H0Z" fill="#e6fffb" stroke="#006d75" stroke-width="1.5"/><path d="M0,28 Q30,32 60,30 T120,35 T180,32 V50 H0Z" fill="#b5f5ec80" stroke="#08979c" stroke-width="1" stroke-dasharray="3,2"/></svg>' },
  { id:'g-river-level', roles:'all', dataLevel:'public', icon:'🏔️', name:'하천 수위 추이', domain:'water', type:'line', desc:'주요 하천 수위관측소 실시간 추이', author:'박계측', date:'2026-02-26', likes:22, mine:false, recommend:true, popular:true, color:'#0050b3',
    svg:'<svg viewBox="0 0 180 50"><polyline points="0,38 25,32 50,35 75,28 100,22 125,30 150,18 180,25" fill="none" stroke="#0050b3" stroke-width="2"/><polyline points="0,42 25,38 50,40 75,35 100,30 125,36 150,26 180,32" fill="none" stroke="#69b1ff" stroke-width="1.5" stroke-dasharray="3,2"/><line x1="0" y1="15" x2="180" y2="15" stroke="#f5222d" stroke-width="1" stroke-dasharray="4,3"/><text x="150" y="13" font-size="6" fill="#f5222d">경계</text></svg>' },
  // ── 댐·저수지 ──
  { id:'g-dam-storage', roles:'all', dataLevel:'public', icon:'🏗️', name:'댐 저수율 비교', domain:'dam', type:'bar', desc:'주요 다목적댐 저수율 현황 비교', author:'김수자원', date:'2026-02-27', likes:38, mine:true, recommend:true, popular:true, color:'#1677ff',
    svg:'<svg viewBox="0 0 180 50"><rect x="5" y="5" width="20" height="45" fill="#e6f7ff" rx="2"/><rect x="5" y="12" width="20" height="38" fill="#1677ff" rx="2"/><text x="15" y="48" text-anchor="middle" font-size="5" fill="#fff">소양</text><rect x="30" y="5" width="20" height="45" fill="#e6f7ff" rx="2"/><rect x="30" y="18" width="20" height="32" fill="#40a9ff" rx="2"/><text x="40" y="48" text-anchor="middle" font-size="5" fill="#fff">충주</text><rect x="55" y="5" width="20" height="45" fill="#e6f7ff" rx="2"/><rect x="55" y="8" width="20" height="42" fill="#096dd9" rx="2"/><text x="65" y="48" text-anchor="middle" font-size="5" fill="#fff">안동</text><rect x="80" y="5" width="20" height="45" fill="#e6f7ff" rx="2"/><rect x="80" y="22" width="20" height="28" fill="#69b1ff" rx="2"/><text x="90" y="48" text-anchor="middle" font-size="5" fill="#fff">합천</text><rect x="105" y="5" width="20" height="45" fill="#e6f7ff" rx="2"/><rect x="105" y="15" width="20" height="35" fill="#1677ff" rx="2"/><text x="115" y="48" text-anchor="middle" font-size="5" fill="#fff">대청</text></svg>' },
  { id:'g-dam-discharge', roles:'all', dataLevel:'public', icon:'🌀', name:'댐 방류량 분석', domain:'dam', type:'area', desc:'댐별 방류량 실시간 추이 분석', author:'김수자원', date:'2026-02-25', likes:28, mine:true, recommend:false, popular:true, color:'#0050b3',
    svg:'<svg viewBox="0 0 180 50"><path d="M0,40 Q20,35 40,30 T80,22 T120,28 T160,15 L180,18 V50 H0Z" fill="#e6f7ff" stroke="#0050b3" stroke-width="2"/><path d="M0,44 Q20,40 40,38 T80,32 T120,36 T160,28 L180,30 V50 H0Z" fill="#bae7ff80" stroke="#40a9ff" stroke-width="1" stroke-dasharray="3,2"/></svg>' },
  { id:'g-flood-warning', roles:'all', dataLevel:'public', icon:'🚨', name:'홍수 예경보 현황', domain:'dam', type:'table', desc:'댐/하천 홍수 경보 단계 현황', author:'박기상', date:'2026-02-27', likes:45, mine:false, recommend:true, popular:true, color:'#f5222d',
    svg:'<svg viewBox="0 0 180 50"><rect x="5" y="5" width="170" height="12" fill="#f6ffed" rx="2"/><text x="10" y="14" font-size="8" fill="#52c41a">🟢 소양강댐 — 관심</text><rect x="5" y="20" width="170" height="12" fill="#fff7e6" rx="2"/><text x="10" y="29" font-size="8" fill="#fa8c16">🟡 충주댐 — 주의</text><rect x="5" y="35" width="170" height="12" fill="#fff1f0" rx="2"/><text x="10" y="44" font-size="8" fill="#f5222d">🔴 섬진강댐 — 경계</text></svg>' },
  { id:'g-dam-inflow', roles:'all', dataLevel:'public', icon:'💦', name:'댐 유입량 추이', domain:'dam', type:'line', desc:'주요 댐 유입량 실시간/예측 추이', author:'김수자원', date:'2026-02-24', likes:19, mine:false, recommend:false, popular:false, color:'#36cfc9',
    svg:'<svg viewBox="0 0 180 50"><polyline points="0,40 25,35 50,30 75,32 100,22 125,18 150,24 180,15" fill="none" stroke="#36cfc9" stroke-width="2"/><polyline points="0,40 25,38 50,36 75,38 100,34 125,30 150,32 180,28" fill="none" stroke="#36cfc9" stroke-width="1.5" stroke-dasharray="5,3" opacity="0.5"/><text x="155" y="12" font-size="6" fill="#36cfc9">예측</text></svg>' },
  { id:'g-dam-sediment', roles:['employee','engineer','admin'], dataLevel:'internal', icon:'🪨', name:'댐 퇴적량 분석', domain:'dam', type:'bar', desc:'댐별 퇴적률 및 준설 현황', author:'이수질', date:'2026-02-20', likes:10, mine:false, recommend:false, popular:false, color:'#8d6e63',
    svg:'<svg viewBox="0 0 180 50"><rect x="10" y="28" width="25" height="22" fill="#d7ccc8" rx="2"/><rect x="10" y="18" width="25" height="10" fill="#8d6e63" rx="2"/><rect x="42" y="22" width="25" height="28" fill="#d7ccc8" rx="2"/><rect x="42" y="14" width="25" height="8" fill="#8d6e63" rx="2"/><rect x="74" y="32" width="25" height="18" fill="#d7ccc8" rx="2"/><rect x="74" y="25" width="25" height="7" fill="#8d6e63" rx="2"/><rect x="106" y="20" width="25" height="30" fill="#d7ccc8" rx="2"/><rect x="106" y="10" width="25" height="10" fill="#8d6e63" rx="2"/></svg>' },
  // ── 광역상수도 ──
  { id:'g-water-supply', roles:'all', dataLevel:'public', icon:'🚰', name:'광역상수도 공급량', domain:'supply', type:'area', desc:'권역별 일일 급수량 추이 분석', author:'박계측', date:'2026-02-27', likes:30, mine:false, recommend:true, popular:true, color:'#1890ff',
    svg:'<svg viewBox="0 0 180 50"><path d="M0,38 Q30,28 60,32 T120,22 T180,25 V50 H0Z" fill="#e6f7ff" stroke="#1890ff" stroke-width="2"/><path d="M0,42 Q30,35 60,38 T120,30 T180,32 V50 H0Z" fill="#bae7ff60" stroke="#69b1ff" stroke-width="1" stroke-dasharray="3,2"/></svg>' },
  { id:'g-treatment-plant', roles:['employee','engineer','admin'], dataLevel:'internal', icon:'🏭', name:'정수장 운영 현황', domain:'supply', type:'gauge', desc:'주요 정수장 가동률/처리량 현황', author:'이수질', date:'2026-02-26', likes:25, mine:true, recommend:true, popular:true, color:'#52c41a',
    svg:'<svg viewBox="0 0 180 50"><circle cx="45" cy="32" r="18" fill="none" stroke="#f0f0f0" stroke-width="5"/><circle cx="45" cy="32" r="18" fill="none" stroke="#52c41a" stroke-width="5" stroke-dasharray="105 113" transform="rotate(-90 45 32)"/><text x="45" y="36" text-anchor="middle" font-size="9" fill="#52c41a" font-weight="700">96%</text><circle cx="130" cy="32" r="18" fill="none" stroke="#f0f0f0" stroke-width="5"/><circle cx="130" cy="32" r="18" fill="none" stroke="#1890ff" stroke-width="5" stroke-dasharray="100 113" transform="rotate(-90 130 32)"/><text x="130" y="36" text-anchor="middle" font-size="9" fill="#1890ff" font-weight="700">92%</text></svg>' },
  { id:'g-pipe-leak', roles:['employee','engineer','admin'], dataLevel:'internal', icon:'🔧', name:'관로 누수 분석', domain:'supply', type:'heatmap', desc:'구간별 누수율 및 노후관 현황', author:'관리자', date:'2026-02-23', likes:16, mine:false, recommend:false, popular:false, color:'#fa541c',
    svg:'<svg viewBox="0 0 180 50"><rect x="2" y="2" width="22" height="14" fill="#f6ffed" rx="1"/><rect x="26" y="2" width="22" height="14" fill="#f6ffed" rx="1"/><rect x="50" y="2" width="22" height="14" fill="#fff7e6" rx="1"/><rect x="74" y="2" width="22" height="14" fill="#fff2e8" rx="1"/><rect x="98" y="2" width="22" height="14" fill="#fff1f0" rx="1"/><rect x="122" y="2" width="22" height="14" fill="#f6ffed" rx="1"/><rect x="2" y="18" width="22" height="14" fill="#fff7e6" rx="1"/><rect x="26" y="18" width="22" height="14" fill="#fff1f0" rx="1"/><rect x="50" y="18" width="22" height="14" fill="#ff4d4f40" rx="1"/><rect x="74" y="18" width="22" height="14" fill="#fff7e6" rx="1"/><rect x="98" y="18" width="22" height="14" fill="#f6ffed" rx="1"/><rect x="122" y="18" width="22" height="14" fill="#fff7e6" rx="1"/><rect x="2" y="34" width="22" height="14" fill="#f6ffed" rx="1"/><rect x="26" y="34" width="22" height="14" fill="#f6ffed" rx="1"/><rect x="50" y="34" width="22" height="14" fill="#fff7e6" rx="1"/><rect x="74" y="34" width="22" height="14" fill="#f6ffed" rx="1"/><rect x="98" y="34" width="22" height="14" fill="#fff2e8" rx="1"/><rect x="122" y="34" width="22" height="14" fill="#f6ffed" rx="1"/></svg>' },
  { id:'g-water-usage', roles:'all', dataLevel:'public', icon:'📊', name:'용수 이용량 추이', domain:'supply', type:'bar', desc:'생활/공업/농업 용수 이용량 월별 추이', author:'박계측', date:'2026-02-21', likes:14, mine:false, recommend:false, popular:false, color:'#722ed1',
    svg:'<svg viewBox="0 0 180 50"><rect x="5" y="18" width="10" height="32" fill="#722ed1" rx="1"/><rect x="16" y="25" width="10" height="25" fill="#b37feb" rx="1"/><rect x="27" y="30" width="10" height="20" fill="#d3adf7" rx="1"/><rect x="45" y="15" width="10" height="35" fill="#722ed1" rx="1"/><rect x="56" y="22" width="10" height="28" fill="#b37feb" rx="1"/><rect x="67" y="28" width="10" height="22" fill="#d3adf7" rx="1"/><rect x="85" y="12" width="10" height="38" fill="#722ed1" rx="1"/><rect x="96" y="20" width="10" height="30" fill="#b37feb" rx="1"/><rect x="107" y="26" width="10" height="24" fill="#d3adf7" rx="1"/><rect x="125" y="10" width="10" height="40" fill="#722ed1" rx="1"/><rect x="136" y="18" width="10" height="32" fill="#b37feb" rx="1"/><rect x="147" y="24" width="10" height="26" fill="#d3adf7" rx="1"/></svg>' },
  { id:'g-chlorine', roles:['employee','engineer','admin'], dataLevel:'internal', icon:'🧪', name:'잔류염소 농도 추이', domain:'supply', type:'line', desc:'배수지/관말 잔류염소 농도 변화', author:'이수질', date:'2026-02-25', likes:17, mine:true, recommend:false, popular:false, color:'#faad14',
    svg:'<svg viewBox="0 0 180 50"><polyline points="0,30 25,28 50,32 75,26 100,30 125,24 150,28 180,22" fill="none" stroke="#faad14" stroke-width="2"/><line x1="0" y1="38" x2="180" y2="38" stroke="#f5222d" stroke-width="1" stroke-dasharray="4,3"/><line x1="0" y1="15" x2="180" y2="15" stroke="#1677ff" stroke-width="1" stroke-dasharray="4,3"/><text x="155" y="13" font-size="5" fill="#1677ff">상한</text><text x="155" y="45" font-size="5" fill="#f5222d">하한</text></svg>' },
  // ── 에너지·발전 ──
  { id:'g-energy-usage', roles:'all', dataLevel:'public', icon:'⚡', name:'에너지 사용량 분석', domain:'energy', type:'area', desc:'시설별 전력·용수 에너지 사용 추이', author:'한에너지', date:'2026-02-25', likes:19, mine:false, recommend:true, popular:false, color:'#fa8c16',
    svg:'<svg viewBox="0 0 180 50"><path d="M0,45 Q25,30 50,35 T100,20 T150,28 T180,15 V50 H0Z" fill="#fff7e6" stroke="#fa8c16" stroke-width="1.5"/></svg>' },
  { id:'g-hydro-gen', roles:'all', dataLevel:'public', icon:'🔋', name:'수력발전 현황', domain:'energy', type:'line', desc:'발전소별 발전량 및 효율 실시간', author:'한에너지', date:'2026-02-24', likes:17, mine:false, recommend:false, popular:true, color:'#2f54eb',
    svg:'<svg viewBox="0 0 180 50"><polyline points="0,40 30,30 60,35 90,18 120,22 150,12 180,20" fill="none" stroke="#2f54eb" stroke-width="2"/><polyline points="0,42 30,38 60,40 90,30 120,32 150,25 180,30" fill="none" stroke="#85a5ff" stroke-width="1" stroke-dasharray="3,2"/></svg>' },
  { id:'g-hydro-efficiency', roles:['employee','engineer','admin'], dataLevel:'internal', icon:'📈', name:'수력발전 효율 분석', domain:'energy', type:'gauge', desc:'발전소별 발전효율 및 이용률 비교', author:'한에너지', date:'2026-02-26', likes:21, mine:false, recommend:true, popular:true, color:'#13c2c2',
    svg:'<svg viewBox="0 0 180 50"><circle cx="45" cy="32" r="18" fill="none" stroke="#f0f0f0" stroke-width="5"/><circle cx="45" cy="32" r="18" fill="none" stroke="#13c2c2" stroke-width="5" stroke-dasharray="98 113" transform="rotate(-90 45 32)"/><text x="45" y="36" text-anchor="middle" font-size="9" fill="#13c2c2" font-weight="700">87%</text><circle cx="130" cy="32" r="18" fill="none" stroke="#f0f0f0" stroke-width="5"/><circle cx="130" cy="32" r="18" fill="none" stroke="#52c41a" stroke-width="5" stroke-dasharray="107 113" transform="rotate(-90 130 32)"/><text x="130" y="36" text-anchor="middle" font-size="9" fill="#52c41a" font-weight="700">95%</text></svg>' },
  { id:'g-solar-gen', roles:'all', dataLevel:'public', icon:'☀️', name:'태양광 발전 현황', domain:'energy', type:'area', desc:'태양광 설비 발전량/일사량 추이', author:'한에너지', date:'2026-02-23', likes:13, mine:false, recommend:false, popular:false, color:'#fadb14',
    svg:'<svg viewBox="0 0 180 50"><path d="M0,48 Q20,42 40,35 T80,20 T120,15 T160,22 L180,30 V50 H0Z" fill="#fffbe6" stroke="#fadb14" stroke-width="1.5"/><path d="M0,48 Q20,45 40,40 T80,28 T120,22 T160,30 L180,35 V50 H0Z" fill="#fff1b860" stroke="#ffc53d" stroke-width="1" stroke-dasharray="3,2"/></svg>' },
  // ── 환경·기상 ──
  { id:'g-algal-bloom', roles:'all', dataLevel:'public', icon:'🦠', name:'녹조 발생 추이', domain:'env', type:'bar', desc:'주요 호소 남조류 세포수 변화 추이', author:'이수질', date:'2026-02-27', likes:35, mine:false, recommend:true, popular:true, color:'#52c41a',
    svg:'<svg viewBox="0 0 180 50"><rect x="5" y="35" width="16" height="15" fill="#b7eb8f" rx="2"/><rect x="25" y="28" width="16" height="22" fill="#95de64" rx="2"/><rect x="45" y="18" width="16" height="32" fill="#73d13d" rx="2"/><rect x="65" y="8" width="16" height="42" fill="#52c41a" rx="2"/><rect x="85" y="12" width="16" height="38" fill="#52c41a" rx="2"/><rect x="105" y="22" width="16" height="28" fill="#73d13d" rx="2"/><rect x="125" y="30" width="16" height="20" fill="#95de64" rx="2"/><rect x="145" y="38" width="16" height="12" fill="#b7eb8f" rx="2"/><line x1="0" y1="10" x2="180" y2="10" stroke="#f5222d" stroke-width="1" stroke-dasharray="4,3"/><text x="155" y="8" font-size="5" fill="#f5222d">경보</text></svg>' },
  { id:'g-weather-data', roles:'all', dataLevel:'public', icon:'🌤️', name:'기상 데이터 분석', domain:'env', type:'line', desc:'기온/습도/풍속 종합 기상 분석', author:'박기상', date:'2026-02-26', likes:16, mine:false, recommend:false, popular:true, color:'#eb2f96',
    svg:'<svg viewBox="0 0 180 50"><polyline points="0,30 25,28 50,22 75,25 100,18 125,20 150,15 180,22" fill="none" stroke="#eb2f96" stroke-width="2"/><polyline points="0,40 25,38 50,42 75,36 100,40 125,35 150,38 180,34" fill="none" stroke="#ff85c0" stroke-width="1.5" stroke-dasharray="3,2"/><polyline points="0,45 25,44 50,46 75,44 100,45 125,43 150,46 180,44" fill="none" stroke="#ffa39e" stroke-width="1" stroke-dasharray="2,2"/></svg>' },
  { id:'g-ecosystem', roles:['employee','engineer','admin'], dataLevel:'internal', icon:'🐟', name:'수생태계 건강성', domain:'env', type:'pie', desc:'어류/저서생물/부착조류 건강성 평가', author:'이수질', date:'2026-02-22', likes:11, mine:false, recommend:false, popular:false, color:'#389e0d',
    svg:'<svg viewBox="0 0 180 50"><circle cx="90" cy="28" r="22" fill="none" stroke="#f0f0f0" stroke-width="10"/><circle cx="90" cy="28" r="22" fill="none" stroke="#389e0d" stroke-width="10" stroke-dasharray="55 138" stroke-dashoffset="0" transform="rotate(-90 90 28)"/><circle cx="90" cy="28" r="22" fill="none" stroke="#52c41a" stroke-width="10" stroke-dasharray="35 138" stroke-dashoffset="-55" transform="rotate(-90 90 28)"/><circle cx="90" cy="28" r="22" fill="none" stroke="#95de64" stroke-width="10" stroke-dasharray="28 138" stroke-dashoffset="-90" transform="rotate(-90 90 28)"/><circle cx="90" cy="28" r="22" fill="none" stroke="#b7eb8f" stroke-width="10" stroke-dasharray="20 138" stroke-dashoffset="-118" transform="rotate(-90 90 28)"/></svg>' },
  { id:'g-pollution', roles:'all', dataLevel:'public', icon:'⚠️', name:'수질 오염도 분석', domain:'env', type:'bar', desc:'권역별 수질 오염도(BOD/COD/TOC) 추이', author:'이수질', date:'2026-02-25', likes:27, mine:true, recommend:true, popular:true, color:'#fa8c16',
    svg:'<svg viewBox="0 0 180 50"><rect x="5" y="5" width="130" height="10" fill="#e6f7ff" rx="2"/><rect x="5" y="5" width="45" height="10" fill="#52c41a" rx="2"/><text x="140" y="13" font-size="7" fill="#52c41a">좋음</text><rect x="5" y="19" width="130" height="10" fill="#fff7e6" rx="2"/><rect x="5" y="19" width="85" height="10" fill="#fa8c16" rx="2"/><text x="140" y="27" font-size="7" fill="#fa8c16">보통</text><rect x="5" y="33" width="130" height="10" fill="#fff1f0" rx="2"/><rect x="5" y="33" width="110" height="10" fill="#f5222d" rx="2"/><text x="140" y="41" font-size="7" fill="#f5222d">나쁨</text></svg>' }
];

var galPlacedCharts = [];
// localStorage에서 저장된 갤러리 배치 복원
(function restoreGalLayout() {
  try {
    var saved = localStorage.getItem('portal-gal-charts');
    if (saved) {
      galPlacedCharts = JSON.parse(saved);
      var sizes = localStorage.getItem('portal-gal-sizes');
      if (sizes) {
        var sizeMap = JSON.parse(sizes);
        Object.keys(sizeMap).forEach(function(cid) {
          var c = GAL_CHARTS.find(function(x) { return x.id === cid; });
          if (c) { c._gw = sizeMap[cid].gw; c._gh = sizeMap[cid].gh; }
        });
      }
    }
  } catch (e) { /* 파싱 실패 시 기본값 유지 */ }
})();
var galCurrentTab = 'all';
var galDragSrcIdx = null;

function initGalleryScreen() {
  galRenderLibrary();
  galRenderCanvas();
}

function galSwitchTab(tabEl, tabKey) {
  galCurrentTab = tabKey;
  document.querySelectorAll('.gal-tab').forEach(function(t) {
    t.style.fontWeight = '400'; t.style.color = 'var(--text-secondary)'; t.style.borderBottom = 'none';
  });
  tabEl.style.fontWeight = '600'; tabEl.style.color = '#1677ff'; tabEl.style.borderBottom = '2px solid #1677ff';
  galRenderLibrary();
}

function galRenderLibrary() {
  var lib = document.getElementById('gal-library');
  if (!lib) return;
  lib.innerHTML = '';
  var search = (document.getElementById('gal-search') || {}).value || '';
  search = search.toLowerCase();
  var domain = (document.getElementById('gal-domain-filter') || {}).value || 'all';
  var noResult = document.getElementById('gal-no-results');
  var shown = 0;
  var typeLabel = { line:'라인', bar:'바', area:'영역', pie:'파이', gauge:'게이지', heatmap:'히트맵', table:'테이블' };
  var typeColor = { line:'#1677ff', bar:'#fa8c16', area:'#13c2c2', pie:'#722ed1', gauge:'#52c41a', heatmap:'#08979c', table:'#5c6bc0' };

  GAL_CHARTS.forEach(function(c) {
    if (galPlacedCharts.indexOf(c.id) !== -1) return;
    // RBAC + 데이터 등급 필터
    if (!canAccessItem(c)) return;
    if (domain !== 'all' && c.domain !== domain) return;
    if (galCurrentTab === 'mine' && !c.mine) return;
    if (galCurrentTab === 'recommend' && !c.recommend) return;
    if (galCurrentTab === 'popular' && !c.popular) return;
    if (search && c.name.toLowerCase().indexOf(search) === -1 && c.desc.toLowerCase().indexOf(search) === -1 && c.author.toLowerCase().indexOf(search) === -1) return;

    shown++;
    var card = document.createElement('div');
    card.setAttribute('draggable', 'true');
    card.setAttribute('data-chart-id', c.id);
    card.style.cssText = 'background:#fff; border:1.5px solid #e8e8e8; border-radius:10px; padding:12px; cursor:grab; transition:all 0.2s; user-select:none;';
    card.onmouseenter = function() { card.style.borderColor = c.color; card.style.boxShadow = '0 4px 12px ' + c.color + '18'; };
    card.onmouseleave = function() { card.style.borderColor = '#e8e8e8'; card.style.boxShadow = 'none'; };
    card.ondragstart = function(e) {
      e.dataTransfer.setData('text/plain', c.id);
      e.dataTransfer.effectAllowed = 'move';
      card.style.opacity = '0.5';
      setTimeout(function() { galHighlightCanvas(true); }, 0);
    };
    card.ondragend = function() { card.style.opacity = '1'; galHighlightCanvas(false); };
    card.ondblclick = function() {
      if (galPlacedCharts.indexOf(c.id) !== -1) return;
      galPlacedCharts.push(c.id);
      galRenderCanvas(); galRenderLibrary(); galUpdateCount();
    };

    card.innerHTML =
      '<div style="display:flex; align-items:center; gap:8px; margin-bottom:6px;">' +
        '<span style="font-size:18px;">' + c.icon + '</span>' +
        '<div style="flex:1; min-width:0;">' +
          '<div style="font-size:12px; font-weight:700; color:var(--text-color); white-space:nowrap; overflow:hidden; text-overflow:ellipsis;">' + c.name + '</div>' +
        '</div>' +
      '</div>' +
      '<div style="background:#fafafa; border-radius:6px; padding:6px; margin-bottom:6px; min-height:50px; display:flex; align-items:center; justify-content:center;">' +
        c.svg +
      '</div>' +
      '<div style="font-size:10px; color:var(--text-secondary); margin-bottom:6px; white-space:nowrap; overflow:hidden; text-overflow:ellipsis;">' + c.desc + '</div>' +
      '<div style="display:flex; justify-content:space-between; align-items:center;">' +
        '<span style="font-size:10px; background:' + typeColor[c.type] + '15; color:' + typeColor[c.type] + '; padding:1px 6px; border-radius:3px; font-weight:600;">' + (typeLabel[c.type] || c.type) + '</span>' +
        '<span style="font-size:10px; background:' + (DATA_LEVEL_BG[c.dataLevel]||'#f5f5f5') + '; color:' + (DATA_LEVEL_COLORS[c.dataLevel]||'#999') + '; padding:1px 6px; border-radius:3px; font-weight:600;">' + (DATA_LEVEL_LABELS[c.dataLevel]||'') + '</span>' +
        '<div style="display:flex; gap:6px; align-items:center; font-size:10px; color:#aaa;">' +
          '<span>' + c.author + '</span>' +
          '<span>⭐ ' + c.likes + '</span>' +
        '</div>' +
      '</div>';
    lib.appendChild(card);
  });

  if (noResult) noResult.style.display = shown === 0 ? 'block' : 'none';
  var libCount = document.getElementById('gal-lib-count');
  if (libCount) libCount.textContent = '— ' + shown + '개 사용 가능';
}

function galFilterCharts() { galRenderLibrary(); }

function galHighlightCanvas(on) {
  var canvas = document.getElementById('gal-canvas');
  if (!canvas) return;
  if (on) {
    canvas.style.borderColor = '#1677ff';
    canvas.style.background = 'repeating-linear-gradient(45deg, #f0f7ff, #f0f7ff 10px, #e8f0fe 10px, #e8f0fe 20px)';
  } else {
    canvas.style.borderColor = '#d9d9d9';
    canvas.style.background = 'repeating-linear-gradient(45deg, #fafbfc, #fafbfc 10px, #f5f7fa 10px, #f5f7fa 20px)';
  }
}

function galCanvasDragOver(e) { e.preventDefault(); e.dataTransfer.dropEffect = 'move'; }
function galCanvasDragLeave(e) { }

function galCanvasDrop(e) {
  e.preventDefault();
  var cid = e.dataTransfer.getData('text/plain');
  if (!cid || cid.indexOf('galcanvas:') === 0) return;
  galHighlightCanvas(false);
  if (galPlacedCharts.indexOf(cid) !== -1) return;
  galPlacedCharts.push(cid);
  galRenderCanvas(); galRenderLibrary(); galUpdateCount();
}

function galRenderCanvas() {
  var canvas = document.getElementById('gal-canvas');
  if (!canvas) return;
  canvas.innerHTML = '';
  var empty = document.createElement('div');
  empty.id = 'gal-canvas-empty';
  empty.style.cssText = 'grid-column:1/-1; display:flex; flex-direction:column; align-items:center; justify-content:center; padding:50px 0; color:#bbb;';
  empty.innerHTML = '<div style="font-size:44px; margin-bottom:10px;">🖼️</div><div style="font-size:15px; font-weight:600;">차트를 여기에 드래그하여 갤러리를 구성하세요</div><div style="font-size:12px; margin-top:4px;">아래 라이브러리에서 원하는 차트를 끌어 놓으면 나만의 갤러리에 추가됩니다</div>';
  if (galPlacedCharts.length === 0) { canvas.appendChild(empty); return; }

  var typeLabel = { line:'라인', bar:'바', area:'영역', pie:'파이', gauge:'게이지', heatmap:'히트맵', table:'테이블' };

  galPlacedCharts.forEach(function(cid, idx) {
    var c = GAL_CHARTS.find(function(x) { return x.id === cid; });
    if (!c) return;
    if (!canAccessItem(c)) return;
    var gw = c._gw || 1;
    var gh = c._gh || 1;
    var minH = gh === 1 ? '120px' : gh === 2 ? '250px' : '380px';
    var el = document.createElement('div');
    el.setAttribute('data-gal-id', c.id);
    el.setAttribute('data-gal-idx', idx);
    el.setAttribute('draggable', 'true');
    el.style.cssText = 'background:#fff; border:1.5px solid #e8e8e8; border-radius:10px; padding:12px; position:relative; grid-column:span ' + gw + '; grid-row:span ' + gh + '; transition:all 0.2s; min-height:' + minH + '; cursor:grab; display:flex; flex-direction:column;';

    // canvas internal drag
    el.addEventListener('dragstart', function(e) {
      galDragSrcIdx = idx;
      e.dataTransfer.setData('text/plain', 'galcanvas:' + c.id);
      e.dataTransfer.effectAllowed = 'move';
      el.style.opacity = '0.4'; el.style.border = '2px dashed #1677ff';
    });
    el.addEventListener('dragend', function() {
      el.style.opacity = '1'; el.style.border = '1.5px solid #e8e8e8'; galDragSrcIdx = null;
      canvas.querySelectorAll('[data-gal-id]').forEach(function(x) { x.style.borderLeft = ''; x.style.borderRight = ''; });
    });
    el.addEventListener('dragover', function(e) {
      e.preventDefault(); e.dataTransfer.dropEffect = 'move';
      if (galDragSrcIdx !== null && galDragSrcIdx !== idx) {
        var rect = el.getBoundingClientRect(); var midX = rect.left + rect.width / 2;
        canvas.querySelectorAll('[data-gal-id]').forEach(function(x) { x.style.borderLeft = ''; x.style.borderRight = ''; });
        if (e.clientX < midX) el.style.borderLeft = '3px solid #1677ff'; else el.style.borderRight = '3px solid #1677ff';
      }
    });
    el.addEventListener('dragleave', function() { el.style.borderLeft = ''; el.style.borderRight = ''; });
    el.addEventListener('drop', function(e) {
      e.preventDefault(); e.stopPropagation();
      var payload = e.dataTransfer.getData('text/plain');
      if (payload.indexOf('galcanvas:') === 0 && galDragSrcIdx !== null && galDragSrcIdx !== idx) {
        var rect = el.getBoundingClientRect(); var midX = rect.left + rect.width / 2;
        var insertBefore = e.clientX < midX;
        var srcId = galPlacedCharts[galDragSrcIdx];
        galPlacedCharts.splice(galDragSrcIdx, 1);
        var targetIdx = galPlacedCharts.indexOf(cid);
        if (!insertBefore) targetIdx++;
        galPlacedCharts.splice(targetIdx, 0, srcId);
        galDragSrcIdx = null; galRenderCanvas(); return;
      }
      if (payload && payload.indexOf('galcanvas:') !== 0) {
        if (galPlacedCharts.indexOf(payload) === -1) {
          var rect2 = el.getBoundingClientRect(); var midX2 = rect2.left + rect2.width / 2;
          var insertIdx = idx; if (e.clientX >= midX2) insertIdx++;
          galPlacedCharts.splice(insertIdx, 0, payload);
          galRenderCanvas(); galRenderLibrary(); galUpdateCount();
        }
      }
    });

    el.onmouseenter = function() { if (galDragSrcIdx === null) { el.style.borderColor = c.color; el.style.boxShadow = '0 2px 8px ' + c.color + '22'; } };
    el.onmouseleave = function() { if (galDragSrcIdx === null) { el.style.borderColor = '#e8e8e8'; el.style.boxShadow = 'none'; } };

    function galSBtn(fn, val, cur, label) {
      var active = val === cur;
      return '<button onclick="' + fn + '(\'' + c.id + '\',' + val + ')" style="padding:2px 7px; font-size:10px; border:1px solid ' + (active ? '#1677ff' : '#d9d9d9') + '; background:' + (active ? '#e6f0ff' : '#fff') + '; color:' + (active ? '#1677ff' : '#666') + '; border-radius:4px; cursor:pointer; font-weight:600;">' + label + '</button>';
    }

    el.innerHTML =
      '<div style="position:absolute; top:6px; right:6px; display:flex; gap:2px;">' +
        '<span title="드래그하여 순서 변경" style="cursor:grab; color:#ccc; font-size:14px; padding:2px 3px; border-radius:4px; user-select:none;" onmouseenter="this.style.color=\'#1677ff\';this.style.background=\'#f0f7ff\'" onmouseleave="this.style.color=\'#ccc\';this.style.background=\'none\'">⠿</span>' +
        '<button onclick="galRemoveChart(\'' + c.id + '\')" style="background:none; border:none; font-size:16px; cursor:pointer; color:#ccc; line-height:1; padding:2px 4px; border-radius:4px;" onmouseenter="this.style.color=\'#f44336\';this.style.background=\'#fff5f5\'" onmouseleave="this.style.color=\'#ccc\';this.style.background=\'none\'">&times;</button>' +
      '</div>' +
      '<div style="display:flex; align-items:center; gap:8px; margin-bottom:6px; padding-right:44px;">' +
        '<span style="font-size:20px;">' + c.icon + '</span>' +
        '<div style="flex:1; min-width:0;">' +
          '<div style="font-size:13px; font-weight:700; color:var(--text-color); white-space:nowrap; overflow:hidden; text-overflow:ellipsis;">' + c.name + '</div>' +
          '<div style="font-size:10px; color:var(--text-secondary);">' + (typeLabel[c.type] || c.type) + ' · ' + c.author + ' · ⭐' + c.likes + '</div>' +
        '</div>' +
      '</div>' +
      '<div style="flex:1; background:#fafafa; border-radius:6px; padding:8px; display:flex; align-items:center; justify-content:center; margin-bottom:6px; overflow:hidden;">' +
        c.svg +
      '</div>' +
      '<div style="display:flex; flex-direction:column; gap:3px;">' +
        '<div style="display:flex; gap:3px; align-items:center;">' +
          '<span style="font-size:10px; color:var(--text-secondary); min-width:28px;">가로:</span>' +
          galSBtn('galResizeW', 1, gw, '1칸') + galSBtn('galResizeW', 2, gw, '2칸') + galSBtn('galResizeW', 3, gw, '3칸') +
          '<span style="font-size:10px; color:#aaa; margin-left:auto;">순서 ' + (idx + 1) + '</span>' +
        '</div>' +
        '<div style="display:flex; gap:3px; align-items:center;">' +
          '<span style="font-size:10px; color:var(--text-secondary); min-width:28px;">세로:</span>' +
          galSBtn('galResizeH', 1, gh, '1행') + galSBtn('galResizeH', 2, gh, '2행') + galSBtn('galResizeH', 3, gh, '3행') +
        '</div>' +
      '</div>';
    canvas.appendChild(el);
  });
}

function galRemoveChart(cid) {
  galPlacedCharts = galPlacedCharts.filter(function(id) { return id !== cid; });
  var c = GAL_CHARTS.find(function(x) { return x.id === cid; });
  if (c) { delete c._gw; delete c._gh; }
  galRenderCanvas(); galRenderLibrary(); galUpdateCount();
}

function galResizeW(cid, w) {
  var c = GAL_CHARTS.find(function(x) { return x.id === cid; });
  if (c) c._gw = w;
  galRenderCanvas();
}

function galResizeH(cid, h) {
  var c = GAL_CHARTS.find(function(x) { return x.id === cid; });
  if (c) c._gh = h;
  galRenderCanvas();
}

function galChangeColumns(cols) {
  var canvas = document.getElementById('gal-canvas');
  if (canvas) { canvas.style.gridTemplateColumns = 'repeat(' + cols + ', 1fr)'; canvas.style.gridAutoRows = 'minmax(120px, auto)'; }
}

function galUpdateCount() {
  var el = document.getElementById('gal-placed-count');
  if (el) el.textContent = galPlacedCharts.length;
}

function galClearCanvas() {
  if (galPlacedCharts.length === 0) return;
  if (!confirm('갤러리의 모든 차트를 제거하시겠습니까?')) return;
  galPlacedCharts.forEach(function(cid) {
    var c = GAL_CHARTS.find(function(x) { return x.id === cid; });
    if (c) { delete c._gw; delete c._gh; }
  });
  galPlacedCharts = [];
  galRenderCanvas(); galRenderLibrary(); galUpdateCount();
}

function galLoadDefault() {
  galPlacedCharts.forEach(function(cid) {
    var c = GAL_CHARTS.find(function(x) { return x.id === cid; });
    if (c) { delete c._gw; delete c._gh; }
  });
  galPlacedCharts = ['g-dam-level', 'g-water-quality', 'g-dam-storage', 'g-flood-warning', 'g-water-supply', 'g-energy-usage'];
  // preset sizes
  var presets = { 'g-dam-level': [2,1], 'g-flood-warning': [1,1], 'g-water-supply': [2,1] };
  Object.keys(presets).forEach(function(k) {
    var c = GAL_CHARTS.find(function(x) { return x.id === k; });
    if (c) { c._gw = presets[k][0]; c._gh = presets[k][1]; }
  });
  galRenderCanvas(); galRenderLibrary(); galUpdateCount();
}

function galSaveLayout() {
  if (galPlacedCharts.length === 0) {
    alert('갤러리에 배치된 차트가 없습니다.\n차트를 먼저 배치해 주세요.');
    return;
  }
  // 차트 크기 정보도 함께 저장
  var sizeMap = {};
  galPlacedCharts.forEach(function(cid) {
    var c = GAL_CHARTS.find(function(x) { return x.id === cid; });
    if (c && (c._gw || c._gh)) {
      sizeMap[cid] = { gw: c._gw || 1, gh: c._gh || 1 };
    }
  });
  try {
    localStorage.setItem('portal-gal-charts', JSON.stringify(galPlacedCharts));
    localStorage.setItem('portal-gal-sizes', JSON.stringify(sizeMap));
  } catch (e) { /* quota 초과 무시 */ }
  showToast('차트 갤러리가 저장되었습니다. (배치 ' + galPlacedCharts.length + '개)', 'success');
}

function showProcessDetail(id) {
  var drawer = document.getElementById('process-detail-drawer');
  if (drawer) {
    document.getElementById('drawer-wf-id').innerText = id;
    drawer.style.display = 'flex';
  }
}

function closeProcessDrawer() {
  var drawer = document.getElementById('process-detail-drawer');
  if (drawer) {
    drawer.style.display = 'none';
  }
}

// ── 데이터셋 검색·추가 모달 ──────────────────────────────────────
var _dsModalSelected = {}; // { id: dataset } 선택 상태

function openDatasetSearchModal() {
  _dsModalSelected = {};
  var modal = document.getElementById('dataset-search-modal');
  if (!modal) return;
  modal.style.display = 'flex';
  // 필터 초기화
  var kw = document.getElementById('dsSearchKeyword'); if (kw) kw.value = '';
  var dom = document.getElementById('dsSearchDomain'); if (dom) dom.value = 'all';
  var sec = document.getElementById('dsSearchSecurity'); if (sec) sec.value = 'all';
  var typ = document.getElementById('dsSearchType'); if (typ) typ.value = 'all';
  searchDatasetsInModal();
}

function closeDatasetSearchModal() {
  var modal = document.getElementById('dataset-search-modal');
  if (modal) modal.style.display = 'none';
}

function searchDatasetsInModal() {
  var keyword = (document.getElementById('dsSearchKeyword')?.value || '').trim().toLowerCase();
  var domain = document.getElementById('dsSearchDomain')?.value || 'all';
  var security = document.getElementById('dsSearchSecurity')?.value || 'all';
  var dataType = document.getElementById('dsSearchType')?.value || 'all';

  var domainLabels = { water:'수자원', quality:'수질', energy:'에너지', infra:'인프라', customer:'고객', system:'시스템' };
  var secLabels = { 1:'공개', 2:'내부일반', 3:'내부중요', 4:'기밀' };
  var secColors = { 1:'#52c41a', 2:'#1677ff', 3:'#fa8c16', 4:'#ff4d4f' };
  var secIcons = { 1:'🟢', 2:'🔵', 3:'🟠', 4:'🔴' };
  var domainBadge = { water:'badge-info', quality:'badge-success', energy:'badge-warning', infra:'badge-ghost', customer:'badge-secondary' };

  var results = (typeof CATALOG_DATASETS !== 'undefined' ? CATALOG_DATASETS : []).filter(function(d) {
    if (domain !== 'all' && d.domain !== domain) return false;
    if (security !== 'all' && d.securityLevel !== parseInt(security)) return false;
    if (dataType !== 'all' && d.dataType !== dataType) return false;
    if (keyword) {
      var hay = (d.name + ' ' + d.tableName + ' ' + d.desc + ' ' + (d.tags || []).join(' ')).toLowerCase();
      if (hay.indexOf(keyword) === -1) return false;
    }
    return true;
  });

  var tbody = document.getElementById('dsSearchResultBody');
  var emptyEl = document.getElementById('dsSearchEmpty');
  var tableEl = document.getElementById('dsSearchTable');
  var countEl = document.getElementById('dsSearchCount');

  if (countEl) countEl.textContent = '검색결과 ' + results.length + '건';

  if (results.length === 0) {
    if (tbody) tbody.innerHTML = '';
    if (emptyEl) emptyEl.style.display = 'block';
    if (tableEl) tableEl.style.display = 'none';
    return;
  }
  if (emptyEl) emptyEl.style.display = 'none';
  if (tableEl) tableEl.style.display = '';

  var html = '';
  results.forEach(function(d) {
    var checked = _dsModalSelected[d.id] ? ' checked' : '';
    var rowCount = d.rowCount >= 10000000 ? (d.rowCount / 10000000).toFixed(0) + ',000만건'
      : d.rowCount >= 10000 ? Math.round(d.rowCount / 10000) + '만건'
      : d.rowCount.toLocaleString() + '건';
    html += '<tr style="cursor:pointer;" onclick="toggleDsSelect(\'' + d.id + '\')">'
      + '<td style="text-align:center;"><input type="checkbox" id="dsCk_' + d.id + '"' + checked
      + ' onclick="event.stopPropagation(); toggleDsSelect(\'' + d.id + '\')" style="cursor:pointer; width:16px; height:16px;"></td>'
      + '<td><strong>' + d.name + '</strong>'
      + '<div style="font-size:10px; color:#8c8c8c;">' + d.tableName + ' | ' + d.system + '</div></td>'
      + '<td><span class="badge ' + (domainBadge[d.domain] || 'badge-ghost') + '">' + (domainLabels[d.domain] || d.domain) + '</span></td>'
      + '<td><span style="color:' + (secColors[d.securityLevel] || '#888') + '; font-size:12px;">'
      + (secIcons[d.securityLevel] || '') + ' ' + (secLabels[d.securityLevel] || '') + '</span></td>'
      + '<td><span style="font-size:12px; font-weight:600; color:' + (d.quality >= 95 ? '#52c41a' : d.quality >= 90 ? '#1677ff' : '#fa8c16') + ';">'
      + d.quality + '%</span></td>'
      + '<td style="font-size:12px;">' + rowCount + '</td>'
      + '<td style="font-size:11px; color:#888;">' + d.updateCycle + '</td>'
      + '</tr>';
  });
  if (tbody) tbody.innerHTML = html;
  updateDsSelectedSummary();
}

function toggleDsSelect(id) {
  var ds = (typeof CATALOG_DATASETS !== 'undefined' ? CATALOG_DATASETS : []).find(function(d) { return d.id === id; });
  if (!ds) return;
  if (_dsModalSelected[id]) {
    delete _dsModalSelected[id];
  } else {
    _dsModalSelected[id] = ds;
  }
  var ck = document.getElementById('dsCk_' + id);
  if (ck) ck.checked = !!_dsModalSelected[id];
  updateDsSelectedSummary();
}

function updateDsSelectedSummary() {
  var keys = Object.keys(_dsModalSelected);
  var countEl = document.getElementById('dsSelectedCount');
  var namesEl = document.getElementById('dsSelectedNames');
  if (countEl) countEl.textContent = keys.length;
  if (namesEl) {
    var names = keys.map(function(k) { return _dsModalSelected[k].name; });
    namesEl.textContent = names.length > 0 ? names.join(', ') : '';
  }
}

function addSelectedDatasets() {
  var keys = Object.keys(_dsModalSelected);
  if (keys.length === 0) {
    alert('추가할 데이터셋을 선택해 주세요.');
    return;
  }
  var domainLabels = { water:'수자원', quality:'수질', energy:'에너지', infra:'인프라', customer:'고객' };
  var secLabels = { 1:'공개', 2:'내부일반', 3:'내부중요', 4:'기밀' };
  var secColors = { 1:'#52c41a', 2:'#1677ff', 3:'#fa8c16', 4:'#ff4d4f' };
  var secIcons = { 1:'🟢', 2:'🔵', 3:'🟠', 4:'🔴' };

  // 기존 테이블에 행 추가
  var tbody = document.querySelector('#screen-new-request .data-table tbody');
  if (!tbody) { closeDatasetSearchModal(); return; }

  var existingCount = tbody.querySelectorAll('tr').length;

  keys.forEach(function(k, i) {
    var d = _dsModalSelected[k];
    // 중복 체크 (테이블명 기준)
    var dup = false;
    tbody.querySelectorAll('tr td:nth-child(2) div').forEach(function(div) {
      if (div.textContent.indexOf(d.tableName) !== -1) dup = true;
    });
    if (dup) return;

    var rowCount = d.rowCount >= 10000000 ? (d.rowCount / 10000000).toFixed(0) + ',000만건'
      : d.rowCount >= 10000 ? Math.round(d.rowCount / 10000) + '만건'
      : d.rowCount.toLocaleString() + '건';
    var num = existingCount + i + 1;
    var tr = document.createElement('tr');
    tr.innerHTML = '<td style="text-align:center;">' + num + '</td>'
      + '<td><strong>' + d.name + '</strong>'
      + '<div style="font-size:10px; color:#8c8c8c;">' + d.tableName + ' | ' + d.updateCycle + '</div></td>'
      + '<td><span class="badge badge-info">' + (domainLabels[d.domain] || d.domain) + '</span></td>'
      + '<td><span style="color:' + (secColors[d.securityLevel] || '#888') + '; font-size:12px;">'
      + (secIcons[d.securityLevel] || '') + ' ' + (secLabels[d.securityLevel] || '') + '</span></td>'
      + '<td style="font-size:12px;">' + rowCount + '</td>'
      + '<td style="text-align:center;"><button style="background:none; border:none; color:#ff4d4f; cursor:pointer; font-size:14px;" onclick="this.closest(\'tr\').remove(); updateNewRequestSummary();">✕</button></td>';
    tbody.appendChild(tr);
  });

  updateNewRequestSummary();
  closeDatasetSearchModal();
}

function updateNewRequestSummary() {
  var tbody = document.querySelector('#screen-new-request .data-table tbody');
  if (!tbody) return;
  var rows = tbody.querySelectorAll('tr');
  var totalCount = 0;
  rows.forEach(function(row, idx) {
    // 번호 재정렬
    var numTd = row.querySelector('td:first-child');
    if (numTd) numTd.textContent = idx + 1;
    // 건수 합산 (텍스트에서 숫자 추출)
    var countTd = row.querySelector('td:nth-child(5)');
    if (countTd) {
      var txt = countTd.textContent;
      var m = txt.match(/([\d,]+)\s*만건/);
      if (m) totalCount += parseInt(m[1].replace(/,/g, '')) * 10000;
      else {
        var m2 = txt.match(/([\d,]+)\s*건/);
        if (m2) totalCount += parseInt(m2[1].replace(/,/g, ''));
      }
    }
  });
  // 요약 정보 업데이트
  var summaryDiv = document.querySelector('#screen-new-request .card-body > div[style*="background:#f6ffed"]');
  if (summaryDiv) {
    var countStr = totalCount >= 10000 ? '약 ' + (totalCount / 10000).toLocaleString() + '만건' : totalCount.toLocaleString() + '건';
    var sizeGB = (totalCount / 2700000).toFixed(1);
    summaryDiv.innerHTML = '💡 선택된 데이터셋: <strong>' + rows.length + '건</strong> | 총 데이터 건수: <strong>' + countStr + '</strong> | 예상 용량: <strong>~' + sizeGB + 'GB</strong>';
  }
}

// Top nav 대메뉴 삭제됨 — 사이드바로 전체 탐색

// Accordion toggle
function toggleAccordion(el) {
  const bodyId = el.dataset.accordion;
  const body = document.getElementById(bodyId);
  const isOpen = el.classList.contains('open');
  // 모든 아코디언 닫기
  document.querySelectorAll('.section-title').forEach(t => t.classList.remove('open'));
  document.querySelectorAll('.accordion-body').forEach(b => b.classList.remove('open'));
  // 클릭한 메뉴가 닫혀있었으면 열기
  if (!isOpen) {
    el.classList.add('open');
    body.classList.add('open');
  }
}

// ===== Interactive Knowledge Graph Engine =====
var kgState = null; // Will be initialized on navigate

function initKnowledgeGraph() {
  var canvas = document.getElementById('knowledgeGraphCanvas');
  var wrap = document.getElementById('kgCanvasWrap');
  if (!canvas || !wrap) return;

  var ctx = canvas.getContext('2d');
  var dpr = window.devicePixelRatio || 1;

  // ---- Data Model ----
  var nodeColors = {
    facility: '#4caf50', system: '#ff9800', dataset: '#42a5f5', metric: '#ec407a', domain: '#ab47bc'
  };
  var nodeIcons = {
    facility: '🏭', system: '⚙️', dataset: '📊', metric: '📈', domain: '🌐'
  };

  var nodes = [
    // Facilities
    { id: 'soyang', label: '소양강댐', type: 'facility', icon: '🏔️', detail: { ontology: 'kw:WaterFacility', desc: '다목적댐 (1973)', region: '강원 춘천', datasets: 8, grade: '2등급' } },
    { id: 'chungju', label: '충주댐', type: 'facility', icon: '🏞️', detail: { ontology: 'kw:WaterFacility', desc: '다목적댐 (1985)', region: '충북 충주', datasets: 6, grade: '2등급' } },
    // Systems
    { id: 'rwis', label: 'RWIS', type: 'system', icon: '📡', detail: { ontology: 'kw:System', desc: '실시간 수자원정보시스템', protocol: 'CDC/REST', status: '정상' } },
    { id: 'hdaps', label: 'HDAPS', type: 'system', icon: '⚡', detail: { ontology: 'kw:System', desc: '수력발전 관리시스템', protocol: 'Batch', status: '정상' } },
    { id: 'scada', label: 'SCADA', type: 'system', icon: '🖥️', detail: { ontology: 'kw:System', desc: '원격감시제어', protocol: 'OPC-UA', status: '정상' } },
    { id: 'kma', label: '기상청 API', type: 'system', icon: '🌤️', detail: { ontology: 'kw:ExternalAPI', desc: '기상청 공공데이터', protocol: 'REST API', status: '지연' } },
    // Datasets
    { id: 'ds_level', label: '수위관측', type: 'dataset', icon: '🌊', detail: { ontology: 'kw:WaterLevelObs', records: '1,234,567', quality: '94.2%', method: 'CDC 실시간' } },
    { id: 'ds_flow', label: '유량관측', type: 'dataset', icon: '💧', detail: { ontology: 'kw:FlowRateObs', records: '987,654', quality: '92.8%', method: 'CDC 실시간' } },
    { id: 'ds_weather', label: '기상데이터', type: 'dataset', icon: '🌡️', detail: { ontology: 'kw:WeatherObs', records: '365,000', quality: '91.5%', method: 'API 시간별' } },
    { id: 'ds_power', label: '발전량', type: 'dataset', icon: '⚡', detail: { ontology: 'kw:PowerGeneration', records: '23,456', quality: '97.1%', method: '배치 일별' } },
    { id: 'ds_discharge', label: '방류량', type: 'dataset', icon: '🚿', detail: { ontology: 'kw:DischargeObs', records: '456,789', quality: '89.3%', method: 'CDC 실시간' } },
    // Metrics
    { id: 'm_inflow', label: '유입량', type: 'metric', icon: '📈', detail: { ontology: 'kw:InflowMetric', unit: 'm³/s', threshold: '> 500', alert: '주의' } },
    { id: 'm_waterlvl', label: '수위', type: 'metric', icon: '📏', detail: { ontology: 'kw:WaterLevelMetric', unit: 'EL.m', threshold: '> 193.5', alert: '정상' } },
    { id: 'm_powergen', label: '발전출력', type: 'metric', icon: '🔋', detail: { ontology: 'kw:PowerMetric', unit: 'MW', threshold: '> 200', alert: '정상' } },
    // Domain
    { id: 'dom_water', label: '수자원', type: 'domain', icon: '💎', detail: { ontology: 'kw:WaterDomain', desc: '수자원 관리 도메인', subDomains: '댐, 하천, 저수지', assets: 42 } }
  ];

  var edges = [
    { source: 'dom_water', target: 'soyang', label: 'hasFacility' },
    { source: 'dom_water', target: 'chungju', label: 'hasFacility' },
    { source: 'soyang', target: 'rwis', label: 'connectedTo' },
    { source: 'soyang', target: 'hdaps', label: 'connectedTo' },
    { source: 'soyang', target: 'scada', label: 'monitoredBy' },
    { source: 'chungju', target: 'rwis', label: 'connectedTo' },
    { source: 'chungju', target: 'hdaps', label: 'connectedTo' },
    { source: 'rwis', target: 'ds_level', label: 'produces' },
    { source: 'rwis', target: 'ds_flow', label: 'produces' },
    { source: 'rwis', target: 'ds_discharge', label: 'produces' },
    { source: 'kma', target: 'ds_weather', label: 'provides' },
    { source: 'hdaps', target: 'ds_power', label: 'produces' },
    { source: 'scada', target: 'ds_level', label: 'feeds' },
    { source: 'ds_level', target: 'm_waterlvl', label: 'measures' },
    { source: 'ds_flow', target: 'm_inflow', label: 'measures' },
    { source: 'ds_power', target: 'm_powergen', label: 'measures' },
    { source: 'ds_level', target: 'm_inflow', label: 'computes' },
    { source: 'ds_weather', target: 'm_inflow', label: 'influences' }
  ];

  // ---- Initialize positions ----
  var w = wrap.clientWidth;
  var h = wrap.clientHeight;
  nodes.forEach(function (n) {
    n.x = w / 2 + (Math.random() - 0.5) * w * 0.6;
    n.y = h / 2 + (Math.random() - 0.5) * h * 0.6;
    n.vx = 0;
    n.vy = 0;
    n.radius = n.type === 'facility' ? 26 : n.type === 'domain' ? 28 : n.type === 'system' ? 22 : n.type === 'dataset' ? 20 : 18;
    n.visible = true;
    n.highlight = false;
    n.searchMatch = true;
  });

  // Edge particles
  var particles = [];
  edges.forEach(function (e, i) {
    particles.push({ edgeIdx: i, t: Math.random(), speed: 0.002 + Math.random() * 0.003 });
    if (Math.random() > 0.5) particles.push({ edgeIdx: i, t: Math.random(), speed: 0.001 + Math.random() * 0.002 });
  });

  // ---- State ----
  var state = {
    nodes: nodes, edges: edges, particles: particles,
    zoom: 1, panX: 0, panY: 0,
    selectedNode: null, hoveredNode: null,
    dragging: null, dragOffX: 0, dragOffY: 0,
    isPanning: false, panStartX: 0, panStartY: 0,
    simAlpha: 1, // simulation energy
    filters: { facility: true, system: true, dataset: true, metric: true, domain: true },
    animFrame: null
  };
  kgState = state;

  // ---- Resize ----
  function resize() {
    w = wrap.clientWidth;
    h = wrap.clientHeight;
    canvas.width = w * dpr;
    canvas.height = h * dpr;
    canvas.style.width = w + 'px';
    canvas.style.height = h + 'px';
    ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
  }
  resize();
  var resizeObs = new ResizeObserver(resize);
  resizeObs.observe(wrap);

  // ---- Physics ----
  function simulate() {
    if (state.simAlpha < 0.001) return;
    state.simAlpha *= 0.995;

    var visNodes = nodes.filter(function (n) { return n.visible; });

    // Repulsion (Coulomb)
    for (var i = 0; i < visNodes.length; i++) {
      for (var j = i + 1; j < visNodes.length; j++) {
        var a = visNodes[i], b = visNodes[j];
        var dx = b.x - a.x, dy = b.y - a.y;
        var dist = Math.sqrt(dx * dx + dy * dy) || 1;
        var force = 8000 * state.simAlpha / (dist * dist);
        var fx = dx / dist * force, fy = dy / dist * force;
        if (a !== state.dragging) { a.vx -= fx; a.vy -= fy; }
        if (b !== state.dragging) { b.vx += fx; b.vy += fy; }
      }
    }

    // Spring (edges)
    var idealLen = 120;
    edges.forEach(function (e) {
      var a = nodes.find(function (n) { return n.id === e.source; });
      var b = nodes.find(function (n) { return n.id === e.target; });
      if (!a || !b || !a.visible || !b.visible) return;
      var dx = b.x - a.x, dy = b.y - a.y;
      var dist = Math.sqrt(dx * dx + dy * dy) || 1;
      var force = (dist - idealLen) * 0.04 * state.simAlpha;
      var fx = dx / dist * force, fy = dy / dist * force;
      if (a !== state.dragging) { a.vx += fx; a.vy += fy; }
      if (b !== state.dragging) { b.vx -= fx; b.vy -= fy; }
    });

    // Center gravity
    visNodes.forEach(function (n) {
      if (n === state.dragging) return;
      n.vx += (w / 2 - n.x) * 0.0005 * state.simAlpha;
      n.vy += (h / 2 - n.y) * 0.0005 * state.simAlpha;
    });

    // Velocity damping + position update
    visNodes.forEach(function (n) {
      if (n === state.dragging) return;
      n.vx *= 0.85;
      n.vy *= 0.85;
      n.x += n.vx;
      n.y += n.vy;
      // Keep in bounds
      n.x = Math.max(n.radius, Math.min(w - n.radius, n.x));
      n.y = Math.max(n.radius, Math.min(h - n.radius, n.y));
    });
  }

  // ---- Rendering ----
  function render() {
    ctx.save();
    ctx.clearRect(0, 0, w, h);
    ctx.translate(state.panX, state.panY);
    ctx.scale(state.zoom, state.zoom);

    // Draw edges
    edges.forEach(function (e) {
      var a = nodes.find(function (n) { return n.id === e.source; });
      var b = nodes.find(function (n) { return n.id === e.target; });
      if (!a || !b || !a.visible || !b.visible) return;

      var isHighlighted = state.selectedNode && (e.source === state.selectedNode.id || e.target === state.selectedNode.id);
      var isHovered = state.hoveredNode && (e.source === state.hoveredNode.id || e.target === state.hoveredNode.id);

      ctx.beginPath();
      ctx.moveTo(a.x, a.y);
      // Slight curve
      var mx = (a.x + b.x) / 2 + (b.y - a.y) * 0.08;
      var my = (a.y + b.y) / 2 - (b.x - a.x) * 0.08;
      ctx.quadraticCurveTo(mx, my, b.x, b.y);

      if (isHighlighted || isHovered) {
        ctx.strokeStyle = 'rgba(100, 181, 246, 0.6)';
        ctx.lineWidth = 2;
      } else {
        ctx.strokeStyle = 'rgba(255, 255, 255, 0.08)';
        ctx.lineWidth = 1;
      }
      ctx.stroke();

      // Arrowhead
      var angle = Math.atan2(b.y - my, b.x - mx);
      var arrowLen = 8;
      var ax1 = b.x - b.radius * Math.cos(angle);
      var ay1 = b.y - b.radius * Math.sin(angle);
      ctx.beginPath();
      ctx.moveTo(ax1, ay1);
      ctx.lineTo(ax1 - arrowLen * Math.cos(angle - 0.35), ay1 - arrowLen * Math.sin(angle - 0.35));
      ctx.lineTo(ax1 - arrowLen * Math.cos(angle + 0.35), ay1 - arrowLen * Math.sin(angle + 0.35));
      ctx.closePath();
      ctx.fillStyle = isHighlighted || isHovered ? 'rgba(100, 181, 246, 0.5)' : 'rgba(255,255,255,0.06)';
      ctx.fill();

      // Edge label (only when highlighted)
      if (isHighlighted) {
        ctx.font = '9px Inter, sans-serif';
        ctx.fillStyle = 'rgba(100, 181, 246, 0.7)';
        ctx.textAlign = 'center';
        ctx.fillText(e.label, mx, my - 6);
      }
    });

    // Draw particles
    particles.forEach(function (p) {
      var e = edges[p.edgeIdx];
      var a = nodes.find(function (n) { return n.id === e.source; });
      var b = nodes.find(function (n) { return n.id === e.target; });
      if (!a || !b || !a.visible || !b.visible) return;

      p.t += p.speed;
      if (p.t > 1) p.t = 0;
      var t = p.t;
      var mx = (a.x + b.x) / 2 + (b.y - a.y) * 0.08;
      var my = (a.y + b.y) / 2 - (b.x - a.x) * 0.08;
      // Quadratic bezier point
      var px = (1 - t) * (1 - t) * a.x + 2 * (1 - t) * t * mx + t * t * b.x;
      var py = (1 - t) * (1 - t) * a.y + 2 * (1 - t) * t * my + t * t * b.y;

      ctx.beginPath();
      ctx.arc(px, py, 1.5, 0, Math.PI * 2);
      ctx.fillStyle = 'rgba(100,181,246,0.4)';
      ctx.fill();
    });

    // Draw nodes
    nodes.forEach(function (n) {
      if (!n.visible) return;
      var col = nodeColors[n.type];
      var isSelected = state.selectedNode === n;
      var isHovered = state.hoveredNode === n;
      var dimmed = !n.searchMatch;

      // Glow
      if (isSelected || isHovered) {
        ctx.beginPath();
        ctx.arc(n.x, n.y, n.radius + 12, 0, Math.PI * 2);
        var glow = ctx.createRadialGradient(n.x, n.y, n.radius, n.x, n.y, n.radius + 12);
        glow.addColorStop(0, col + '40');
        glow.addColorStop(1, col + '00');
        ctx.fillStyle = glow;
        ctx.fill();
      }

      // Outer ring (selected)
      if (isSelected) {
        ctx.beginPath();
        ctx.arc(n.x, n.y, n.radius + 3, 0, Math.PI * 2);
        ctx.strokeStyle = col;
        ctx.lineWidth = 2;
        ctx.stroke();
      }

      // Main circle
      ctx.beginPath();
      ctx.arc(n.x, n.y, n.radius, 0, Math.PI * 2);
      var grad = ctx.createRadialGradient(n.x - n.radius * 0.3, n.y - n.radius * 0.3, 0, n.x, n.y, n.radius);
      grad.addColorStop(0, lightenColor(col, 30));
      grad.addColorStop(1, col);
      ctx.fillStyle = dimmed ? 'rgba(60,70,80,0.5)' : grad;
      ctx.fill();

      // Subtle border
      ctx.strokeStyle = dimmed ? 'rgba(255,255,255,0.05)' : 'rgba(255,255,255,0.15)';
      ctx.lineWidth = 1;
      ctx.stroke();

      // Icon
      ctx.font = (n.radius * 0.65) + 'px serif';
      ctx.textAlign = 'center';
      ctx.textBaseline = 'middle';
      ctx.globalAlpha = dimmed ? 0.3 : 1;
      ctx.fillText(n.icon, n.x, n.y - 1);
      ctx.globalAlpha = 1;

      // Label
      ctx.font = '600 10px Inter, "Noto Sans KR", sans-serif';
      ctx.textAlign = 'center';
      ctx.textBaseline = 'top';
      ctx.fillStyle = dimmed ? 'rgba(255,255,255,0.15)' : 'rgba(255,255,255,0.85)';
      ctx.fillText(n.label, n.x, n.y + n.radius + 5);
    });

    ctx.restore();
    simulate();
    state.animFrame = requestAnimationFrame(render);
  }

  function lightenColor(hex, pct) {
    var r = parseInt(hex.slice(1, 3), 16), g = parseInt(hex.slice(3, 5), 16), b = parseInt(hex.slice(5, 7), 16);
    r = Math.min(255, r + pct); g = Math.min(255, g + pct); b = Math.min(255, b + pct);
    return '#' + ((1 << 24) + (r << 16) + (g << 8) + b).toString(16).slice(1);
  }

  // ---- Mouse Interactions ----
  function toGraphCoords(mx, my) {
    return { x: (mx - state.panX) / state.zoom, y: (my - state.panY) / state.zoom };
  }

  function findNodeAt(mx, my) {
    var p = toGraphCoords(mx, my);
    for (var i = nodes.length - 1; i >= 0; i--) {
      var n = nodes[i];
      if (!n.visible) continue;
      var dx = p.x - n.x, dy = p.y - n.y;
      if (dx * dx + dy * dy <= (n.radius + 4) * (n.radius + 4)) return n;
    }
    return null;
  }

  canvas.addEventListener('mousedown', function (e) {
    var rect = canvas.getBoundingClientRect();
    var mx = e.clientX - rect.left, my = e.clientY - rect.top;
    var node = findNodeAt(mx, my);
    if (node) {
      var p = toGraphCoords(mx, my);
      state.dragging = node;
      state.dragOffX = p.x - node.x;
      state.dragOffY = p.y - node.y;
      state.simAlpha = 0.3;
    } else {
      state.isPanning = true;
      state.panStartX = mx - state.panX;
      state.panStartY = my - state.panY;
    }
  });

  canvas.addEventListener('mousemove', function (e) {
    var rect = canvas.getBoundingClientRect();
    var mx = e.clientX - rect.left, my = e.clientY - rect.top;
    if (state.dragging) {
      var p = toGraphCoords(mx, my);
      state.dragging.x = p.x - state.dragOffX;
      state.dragging.y = p.y - state.dragOffY;
      state.dragging.vx = 0;
      state.dragging.vy = 0;
    } else if (state.isPanning) {
      state.panX = mx - state.panStartX;
      state.panY = my - state.panStartY;
    } else {
      state.hoveredNode = findNodeAt(mx, my);
      canvas.style.cursor = state.hoveredNode ? 'pointer' : 'grab';
    }
  });

  canvas.addEventListener('mouseup', function (e) {
    if (state.dragging) {
      var rect = canvas.getBoundingClientRect();
      var mx = e.clientX - rect.left, my = e.clientY - rect.top;
      var clickedNode = findNodeAt(mx, my);
      if (clickedNode === state.dragging) {
        selectKgNode(clickedNode);
      }
    }
    state.dragging = null;
    state.isPanning = false;
  });

  canvas.addEventListener('mouseleave', function () {
    state.dragging = null;
    state.isPanning = false;
    state.hoveredNode = null;
  });

  canvas.addEventListener('wheel', function (e) {
    e.preventDefault();
    var rect = canvas.getBoundingClientRect();
    var mx = e.clientX - rect.left, my = e.clientY - rect.top;
    var factor = e.deltaY > 0 ? 0.9 : 1.1;
    var newZoom = Math.max(0.3, Math.min(4, state.zoom * factor));
    // Zoom around cursor
    state.panX = mx - (mx - state.panX) * (newZoom / state.zoom);
    state.panY = my - (my - state.panY) * (newZoom / state.zoom);
    state.zoom = newZoom;
  }, { passive: false });

  // ---- Node selection ----
  function selectKgNode(node) {
    state.selectedNode = node;
    var placeholder = document.getElementById('kgPanelPlaceholder');
    var content = document.getElementById('kgPanelContent');
    if (!node) {
      placeholder.style.display = '';
      content.style.display = 'none';
      return;
    }
    placeholder.style.display = 'none';
    content.style.display = '';

    document.getElementById('kgPanelIcon').textContent = node.icon;
    document.getElementById('kgPanelTitle').textContent = node.label;
    document.getElementById('kgPanelSubtitle').textContent = (node.detail.ontology || node.type);

    // Info rows
    var infoHtml = '';
    var d = node.detail;
    Object.keys(d).forEach(function (key) {
      if (key === 'ontology') return;
      var labelMap = {
        desc: '설명', region: '지역', datasets: '데이터셋', grade: '보안등급',
        protocol: '프로토콜', status: '상태', records: '레코드 수', quality: '품질점수',
        method: '수집방식', unit: '단위', threshold: '임계치', alert: '알림',
        subDomains: '하위도메인', assets: '데이터자산'
      };
      infoHtml += '<div class="kg-info-row"><span class="kg-info-label">' + (labelMap[key] || key) + '</span><span class="kg-info-value">' + d[key] + '</span></div>';
    });
    document.getElementById('kgPanelInfo').innerHTML = infoHtml;

    // Connections
    var connHtml = '';
    edges.forEach(function (e) {
      var otherId = null, rel = e.label;
      if (e.source === node.id) otherId = e.target;
      else if (e.target === node.id) otherId = e.source;
      if (!otherId) return;
      var other = nodes.find(function (n) { return n.id === otherId; });
      if (!other) return;
      connHtml += '<div class="kg-connection-item" onclick="focusKgNode(\'' + otherId + '\')">'
        + '<span class="kg-connection-dot" style="background:' + nodeColors[other.type] + ';"></span>'
        + '<span>' + other.label + '</span>'
        + '<span class="kg-connection-rel">' + rel + '</span>'
        + '</div>';
    });
    document.getElementById('kgPanelConnections').innerHTML = connHtml;

    // Actions
    var actHtml = '<button class="kg-panel-btn" onclick="navigate(\'cat-detail\')">📋 데이터셋 상세보기</button>';
    actHtml += '<button class="kg-panel-btn" onclick="navigate(\'cat-ontology\')">🌳 온톨로지 클래스탐색</button>';
    document.getElementById('kgPanelActions').innerHTML = actHtml;
  }

  // Start
  render();

  // Update stats
  document.getElementById('kgStats').textContent = '노드 ' + nodes.length + ' · 엣지 ' + edges.length;
}

// ---- Public API (called from HTML) ----
function selectGraphNode(name) {
  if (!kgState) return;
  var node = kgState.nodes.find(function (n) { return n.label === name; });
  if (node) {
    kgState.selectedNode = node;
  }
}

function focusKgNode(nodeId) {
  if (!kgState) return;
  var node = kgState.nodes.find(function (n) { return n.id === nodeId; });
  if (!node || !node.visible) return;
  kgState.selectedNode = node;
  // Rebuild panel
  var canvas = document.getElementById('knowledgeGraphCanvas');
  if (canvas) {
    // Re-select to update panel
    var evt = new CustomEvent('kgSelectNode', { detail: node });
    canvas.dispatchEvent(evt);
  }
  // Center on node
  var wrap = document.getElementById('kgCanvasWrap');
  if (wrap) {
    kgState.panX = wrap.clientWidth / 2 - node.x * kgState.zoom;
    kgState.panY = wrap.clientHeight / 2 - node.y * kgState.zoom;
  }
  // Re-fire init panel
  var placeholder = document.getElementById('kgPanelPlaceholder');
  var content = document.getElementById('kgPanelContent');
  placeholder.style.display = 'none';
  content.style.display = '';
  // Rebuild manually
  selectGraphNodeById(nodeId);
}

function selectGraphNodeById(nodeId) {
  if (!kgState) return;
  var node = kgState.nodes.find(function (n) { return n.id === nodeId; });
  if (!node) return;
  kgState.selectedNode = node;

  var nodeColors = { facility: '#4caf50', system: '#ff9800', dataset: '#42a5f5', metric: '#ec407a', domain: '#ab47bc' };
  document.getElementById('kgPanelIcon').textContent = node.icon;
  document.getElementById('kgPanelTitle').textContent = node.label;
  document.getElementById('kgPanelSubtitle').textContent = (node.detail.ontology || node.type);

  var infoHtml = '';
  var d = node.detail;
  var labelMap = {
    desc: '설명', region: '지역', datasets: '데이터셋', grade: '보안등급',
    protocol: '프로토콜', status: '상태', records: '레코드 수', quality: '품질점수',
    method: '수집방식', unit: '단위', threshold: '임계치', alert: '알림',
    subDomains: '하위도메인', assets: '데이터자산'
  };
  Object.keys(d).forEach(function (key) {
    if (key === 'ontology') return;
    infoHtml += '<div class="kg-info-row"><span class="kg-info-label">' + (labelMap[key] || key) + '</span><span class="kg-info-value">' + d[key] + '</span></div>';
  });
  document.getElementById('kgPanelInfo').innerHTML = infoHtml;

  var connHtml = '';
  kgState.edges.forEach(function (e) {
    var otherId = null, rel = e.label;
    if (e.source === node.id) otherId = e.target;
    else if (e.target === node.id) otherId = e.source;
    if (!otherId) return;
    var other = kgState.nodes.find(function (n) { return n.id === otherId; });
    if (!other) return;
    connHtml += '<div class="kg-connection-item" onclick="focusKgNode(\'' + otherId + '\')">'
      + '<span class="kg-connection-dot" style="background:' + nodeColors[other.type] + ';"></span>'
      + '<span>' + other.label + '</span>'
      + '<span class="kg-connection-rel">' + rel + '</span>'
      + '</div>';
  });
  document.getElementById('kgPanelConnections').innerHTML = connHtml;

  var actHtml = '<button class="kg-panel-btn" onclick="navigate(\'cat-detail\')">📋 데이터셋 상세보기</button>';
  actHtml += '<button class="kg-panel-btn" onclick="navigate(\'cat-ontology\')">🌳 온톨로지 클래스탐색</button>';
  document.getElementById('kgPanelActions').innerHTML = actHtml;
}

function searchKnowledgeGraphNodes(query) {
  if (!kgState) return;
  var q = query.toLowerCase().trim();
  kgState.nodes.forEach(function (n) {
    n.searchMatch = !q || n.label.toLowerCase().indexOf(q) !== -1 || n.id.toLowerCase().indexOf(q) !== -1;
  });
}

function toggleKgFilter(btn) {
  if (!kgState) return;
  btn.classList.toggle('active');
  var type = btn.dataset.type;
  kgState.filters[type] = btn.classList.contains('active');
  kgState.nodes.forEach(function (n) {
    n.visible = kgState.filters[n.type];
  });
  kgState.simAlpha = 0.5;
  // Update stats
  var visN = kgState.nodes.filter(function (n) { return n.visible; }).length;
  var visE = kgState.edges.filter(function (e) {
    var a = kgState.nodes.find(function (n) { return n.id === e.source; });
    var b = kgState.nodes.find(function (n) { return n.id === e.target; });
    return a && b && a.visible && b.visible;
  }).length;
  document.getElementById('kgStats').textContent = '노드 ' + visN + ' · 엣지 ' + visE;
}

function zoomKnowledgeGraph(factor) {
  if (!kgState) return;
  var wrap = document.getElementById('kgCanvasWrap');
  var cx = wrap.clientWidth / 2, cy = wrap.clientHeight / 2;
  var newZoom = Math.max(0.3, Math.min(4, kgState.zoom * factor));
  kgState.panX = cx - (cx - kgState.panX) * (newZoom / kgState.zoom);
  kgState.panY = cy - (cy - kgState.panY) * (newZoom / kgState.zoom);
  kgState.zoom = newZoom;
}

function fitKnowledgeGraph() {
  if (!kgState) return;
  var wrap = document.getElementById('kgCanvasWrap');
  var visNodes = kgState.nodes.filter(function (n) { return n.visible; });
  if (visNodes.length === 0) return;
  var minX = Infinity, maxX = -Infinity, minY = Infinity, maxY = -Infinity;
  visNodes.forEach(function (n) {
    minX = Math.min(minX, n.x - n.radius);
    maxX = Math.max(maxX, n.x + n.radius);
    minY = Math.min(minY, n.y - n.radius);
    maxY = Math.max(maxY, n.y + n.radius);
  });
  var graphW = maxX - minX + 60, graphH = maxY - minY + 60;
  var zoom = Math.min(wrap.clientWidth / graphW, wrap.clientHeight / graphH, 2);
  kgState.zoom = zoom;
  kgState.panX = (wrap.clientWidth - (minX + maxX) * zoom) / 2;
  kgState.panY = (wrap.clientHeight - (minY + maxY) * zoom) / 2;
}

function resetKnowledgeGraph() {
  if (!kgState) return;
  kgState.zoom = 1;
  kgState.panX = 0;
  kgState.panY = 0;
  kgState.simAlpha = 1;
  kgState.selectedNode = null;
  // Reset filters
  document.querySelectorAll('.kg-chip').forEach(function (c) { c.classList.add('active'); });
  kgState.nodes.forEach(function (n) { n.visible = true; n.searchMatch = true; });
  Object.keys(kgState.filters).forEach(function (k) { kgState.filters[k] = true; });
  // Clear search
  var input = document.getElementById('kgSearchInput');
  if (input) input.value = '';
  // Reset panel
  document.getElementById('kgPanelPlaceholder').style.display = '';
  document.getElementById('kgPanelContent').style.display = 'none';
  // Randomize positions
  var wrap = document.getElementById('kgCanvasWrap');
  var w = wrap.clientWidth, h = wrap.clientHeight;
  kgState.nodes.forEach(function (n) {
    n.x = w / 2 + (Math.random() - 0.5) * w * 0.6;
    n.y = h / 2 + (Math.random() - 0.5) * h * 0.6;
    n.vx = 0; n.vy = 0;
  });
  // Update stats
  document.getElementById('kgStats').textContent = '노드 ' + kgState.nodes.length + ' · 엣지 ' + kgState.edges.length;
}

// ===== 상태변경 모달 =====
var statusMap = {
  active: { text: '활성', color: '#4caf50', badge: 'status-active' },
  paused: { text: '일시중지', color: '#ff9800', badge: 'status-paused' },
  restricted: { text: '제한', color: '#c62828', badge: 'status-restricted' },
  deprecated: { text: '폐기', color: '#888', badge: 'status-deprecated' }
};
function openStatusModal() {
  document.getElementById('statusModal').style.display = 'flex';
}
function closeStatusModal() {
  document.getElementById('statusModal').style.display = 'none';
}
function applyStatusChange() {
  var sel = document.querySelector('input[name="newStatus"]:checked');
  if (!sel) return;
  var info = statusMap[sel.value];
  // 상세화면 유통상태 텍스트·색상 변경
  var el = document.getElementById('distDetailStatus');
  if (el) { el.textContent = info.text; el.style.color = info.color; }
  // 모달 내 현재상태 뱃지도 동기화
  var badge = document.querySelector('#statusModal .status-badge');
  if (badge) { badge.textContent = info.text; badge.className = 'status-badge ' + info.badge; }
  closeStatusModal();
}
// ===== API 문서 모달 =====
function openApiDocModal() {
  document.getElementById('apiDocModal').style.display = 'flex';
}
function closeApiDocModal() {
  document.getElementById('apiDocModal').style.display = 'none';
}

// ===== API Key 발급 모달 =====
function issueApiKey() {
  // 현재 시각으로 발급일시 표시
  var now = new Date();
  var ts = now.getFullYear() + '-' + String(now.getMonth() + 1).padStart(2, '0') + '-' + String(now.getDate()).padStart(2, '0')
    + ' ' + String(now.getHours()).padStart(2, '0') + ':' + String(now.getMinutes()).padStart(2, '0') + ':' + String(now.getSeconds()).padStart(2, '0');
  var el = document.getElementById('apiKeyIssuedAt');
  if (el) el.textContent = ts;
  document.getElementById('apiKeyModal').style.display = 'flex';
}
function closeApiKeyModal() {
  document.getElementById('apiKeyModal').style.display = 'none';
}
function copyApiKey() {
  var v = document.getElementById('apiKeyValue').textContent;
  navigator.clipboard.writeText(v);
  alert('API Key가 클립보드에 복사되었습니다.');
}
function copyApiSecret() {
  var v = document.getElementById('apiSecretValue').textContent;
  navigator.clipboard.writeText(v);
  alert('Secret이 클립보드에 복사되었습니다.');
}

// ===== Data Lineage Interaction =====
var allLineageGraphs = {
  'water_level': {
    'node-src-1': { title: 'RWIS 수위센서', icon: '📡', type: 'FA', desc: 'IoT 센서 (FA망)', owner: '원격계측팀 박수원', sql: 'SELECT water_lvl FROM sensor_rwis WHERE stn_id = \'042\'', records: '1,234,567건', status: '정상 작동중', statusColor: '#52c41a', downstream: ['node-ing-1'] },
    'node-src-2': { title: '기상청 API', icon: '🔋', type: 'EXT', desc: '공공데이터포털 날씨 API', owner: '데이터융합팀 김철수', sql: 'GET https://api.kma.go.kr/weather/v2', records: '365,000건', status: '응답 지연 (2.1s)', statusColor: '#faad14', downstream: ['node-ing-1'] },
    'node-ing-1': { title: 'CDC 수집엔진', icon: '⚙️', type: 'APP', desc: '실시간 변경 데이터 캡처', owner: '플랫폼운영팀 이영희', sql: 'INSERT INTO stg_rwis_water_level SELECT * FROM src_rwis', records: '1,198,000건', status: '동기화중', statusColor: '#52c41a', downstream: ['node-tr-1'] },
    'node-tr-1': { title: 'stg_rwis_level', icon: '🔧', type: 'SQL', desc: 'Staging Layer 정제', owner: '데이터스튜어드 최민수', sql: 'SELECT ROUND(water_lvl, 2) AS m FROM src WHERE water_lvl > 0', records: '1,195,000건', status: 'Pass', statusColor: '#52c41a', downstream: ['node-tr-2'] },
    'node-tr-2': { title: 'fct_water_report', icon: '🧱', type: 'SQL', desc: 'Mart Layer 일별 리포트', owner: '데이터스튜어드 최민수', sql: 'SELECT stn_id, AVG(m) FROM stg GROUP BY 1', records: '24,000건', status: 'Pass', statusColor: '#52c41a', downstream: ['node-srv-1', 'node-srv-2'] },
    'node-srv-1': { title: '수위현황 대시보드', icon: '📊', type: 'VIZ', desc: '통합 대시보드 위젯', owner: '부서관리자 홍길동', sql: 'Visualization (Chart.js)', records: 'N/A', status: '정상 서비스', statusColor: '#52c41a', downstream: [] },
    'node-srv-2': { title: 'Water Level API', icon: '🔌', type: 'API', desc: '대내외 연계 Open API', owner: '시스템관리자 정공단', sql: 'REST /api/v1/water-level', records: '45,210건', status: '정상', statusColor: '#52c41a', downstream: [] }
  },
  'flow_rate': {
    'node-src-1': { title: '유량 관측 센서', icon: '🌊', type: 'FA', desc: '하천 유량 계측 장치', owner: '원격계측팀 박수원', sql: 'SELECT flow_rate FROM sensor_flow', records: '987,654건', status: '정상', statusColor: '#52c41a', downstream: ['node-ing-1'] },
    'node-src-2': { title: '댐 수위 데이터', icon: '🏔️', type: 'DB', desc: '상류 댐 저수위 정보', owner: '수자원운영팀 이강물', sql: 'SELECT water_lvl FROM tb_dam_status', records: '85,000건', status: '정상', statusColor: '#52c41a', downstream: ['node-ing-1'] },
    'node-ing-1': { title: 'Kafka 수집기', icon: '🚀', type: 'APP', desc: '대용량 스트림 수집', owner: '플랫폼운영팀 이영희', sql: 'KSQL: CREATE STREAM flow_stream WITH (KAFKA_TOPIC=\'flow_data\')', records: '980,000건', status: 'Running', statusColor: '#52c41a', downstream: ['node-tr-1'] },
    'node-tr-1': { title: 'stg_flow_rate', icon: '🧪', type: 'SQL', desc: '유량 단위 환산', owner: '데이터스튜어드 최민수', sql: 'SELECT flow * 0.0283 AS cms FROM raw', records: '975,000건', status: 'Pass', statusColor: '#52c41a', downstream: ['node-tr-2'] },
    'node-tr-2': { title: 'fct_hourly_flow', icon: '⏰', type: 'SQL', desc: '시간별 유량 집계', owner: '데이터스튜어드 최민수', sql: 'SELECT hour, AVG(cms) FROM stg GROUP BY 1', records: '42,000건', status: 'Pass', statusColor: '#52c41a', downstream: ['node-srv-1', 'node-srv-2'] },
    'node-srv-1': { title: '실시간 유량 맵', icon: '📍', type: 'VIZ', desc: '전국 하천 유량 지도', owner: '홍수통제소 김지도', sql: 'Leaflet GIS View', records: 'N/A', status: '서비스중', statusColor: '#52c41a', downstream: [] },
    'node-srv-2': { title: 'Flow Statistics API', icon: '📈', type: 'API', desc: '유량 통계 조회 서비스', owner: '시스템관리자 정공단', sql: 'REST /api/v1/flow-stats', records: '12,500건', status: '정상', statusColor: '#52c41a', downstream: [] }
  },
  'water_quality': {
    'node-src-1': { title: '환경부 수질 API', icon: '🏥', type: 'EXT', desc: '국가 수질 측정망 데이터', owner: '수질관리팀 최맑음', sql: 'GET http://apis.data.go.kr/water-quality', records: '456,789건', status: '정상', statusColor: '#52c41a', downstream: ['node-ing-1'] },
    'node-src-2': { title: '현장 시료 데이터', icon: '🧪', type: 'FILE', desc: '수정 업로드 엑셀 파일', owner: '수질연구소 나분석', sql: 'Excel Upload (CSV)', records: '1,200건', status: '점검필요', statusColor: '#faad14', downstream: ['node-ing-1'] },
    'node-ing-1': { title: '수집 도구(Python)', icon: '🐍', type: 'APP', desc: 'API/File 통합 수집기', owner: '데이터융합팀 김철수', sql: 'python ingest_quality.py', records: '450,000건', status: 'Idle', statusColor: '#1677ff', downstream: ['node-tr-1'] },
    'node-tr-1': { title: 'stg_quality_val', icon: '🔍', type: 'SQL', desc: '수질 항목 유효성 체크', owner: '데이터스튜어드 최민수', sql: 'SELECT * FROM raw WHERE ph BETWEEN 0 AND 14', records: '448,000건', status: 'Pass', statusColor: '#52c41a', downstream: ['node-tr-2'] },
    'node-tr-2': { title: 'fct_quality_alert', icon: '🚨', type: 'SQL', desc: '수질 이상치 탐지 모델', owner: '데이터과학자 이인공', sql: 'ML: Isolation Forest Inference', records: '5,000건', status: 'Pass', statusColor: '#52c41a', downstream: ['node-srv-1', 'node-srv-2'] },
    'node-srv-1': { title: '수질 이상 알람창', icon: '🔔', type: 'VIZ', desc: '품질 저하 알림 모니터', owner: '종합상황실 박경보', sql: 'Real-time WebSocket Alert', records: 'N/A', status: '대기중', statusColor: '#52c41a', downstream: [] },
    'node-srv-2': { title: 'Quality Report API', icon: '📄', type: 'API', desc: '주간 수질 보고서 데이터', owner: '수질관리팀 최맑음', sql: 'REST /api/v1/quality-report', records: '2,300건', status: '정상', statusColor: '#52c41a', downstream: [] }
  }
};

var currentLineageTarget = 'water_level';
var lineageData = allLineageGraphs[currentLineageTarget];
var isImpactMode = false;

function changeLineageTarget(val) {
  currentLineageTarget = val;
  lineageData = allLineageGraphs[val];

  // Close panel and reset mode
  closeLineagePanel();
  if (isImpactMode) toggleImpactAnalysis();

  // Update Node DOM
  Object.keys(lineageData).forEach(nodeId => {
    const nodeEl = document.getElementById(nodeId);
    if (!nodeEl) return;

    const data = lineageData[nodeId];
    nodeEl.querySelector('.node-icon-pro').innerText = data.icon;
    nodeEl.querySelector('.node-title-pro').innerText = data.title;
    nodeEl.querySelector('.node-type-pro').innerText = data.type;
    nodeEl.querySelector('.node-meta-pro').innerHTML = `${data.desc}<br>데이터량: ${data.records}`;

    const statusEl = nodeEl.querySelector('.node-status-pro');
    statusEl.querySelector('.status-indicator').style.background = data.statusColor;
    statusEl.querySelector('span:last-child').style.color = data.statusColor;
    statusEl.querySelector('span:last-child').innerText = data.status;
  });

  // Redraw links
  setTimeout(drawLineageLinks, 100);
}

function selectLineageNode(id) {
  // Reset previous selection
  document.querySelectorAll('.lineage-node-pro').forEach(n => n.classList.remove('selected'));

  const nodeEl = document.getElementById(id);
  if (nodeEl) nodeEl.classList.add('selected');

  const data = lineageData[id];
  if (!data) return;

  // Update Detail Panel
  document.getElementById('lineageSidePanel').classList.add('open');
  document.getElementById('panel-icon').innerText = data.icon;
  document.getElementById('panel-title').innerText = data.title;

  let html = `
    <div style="margin-bottom:16px;">
      <div style="font-size:11px; color:#8c8c8c; margin-bottom:4px;">기본 정보</div>
      <div style="background:#f5f5f5; border-radius:6px; padding:12px;">
        <div style="display:flex; justify-content:space-between; margin-bottom:8px; font-size:12px;">
          <span style="color:#8c8c8c;">유형</span><span style="font-weight:600;">${data.type}</span>
        </div>
        <div style="display:flex; justify-content:space-between; margin-bottom:8px; font-size:12px;">
          <span style="color:#8c8c8c;">설명</span><span style="font-weight:600;">${data.desc}</span>
        </div>
        <div style="display:flex; justify-content:space-between; font-size:12px;">
          <span style="color:#8c8c8c;">데이터량</span><span style="font-weight:600;">${data.records}</span>
        </div>
      </div>
    </div>
    <div style="margin-bottom:16px;">
      <div style="font-size:11px; color:#8c8c8c; margin-bottom:4px;">담당자</div>
      <div style="font-size:13px; font-weight:600;">👤 ${data.owner}</div>
    </div>
    <div style="margin-bottom:16px;">
      <div style="font-size:11px; color:#8c8c8c; margin-bottom:4px;">정의 (SQL/Endpoint)</div>
      <div style="background:#1a2744; color:#fff; border-radius:6px; padding:12px; font-family:monospace; font-size:11px; word-break:break-all;">
        ${data.sql}
      </div>
    </div>
    <div style="display:flex; gap:8px;">
      <button class="btn btn-outline" onclick="openLineageDataView('${id}')" style="flex:1; font-size:11px; padding:6px;">데이터 보기</button>
      <button class="btn btn-outline" onclick="openLineageQualityReport('${id}')" style="flex:1; font-size:11px; padding:6px;">품질 보고서</button>
    </div>
  `;
  document.getElementById('panel-content').innerHTML = html;

  // Impact Mode logic
  if (isImpactMode) {
    simulateImpact(id);
  } else {
    highlightLinks(id);
  }
}

function openLineageDataView(id) {
  const data = lineageData[id];
  if (!data) return;

  // Update header elements
  var icons = { 'DB':'🗄️', 'APP':'⚙️', 'API':'🔌', 'VIZ':'📊', 'SQL':'📋', 'SENSOR':'📡' };
  var titleEl = document.getElementById('dv-asset-title');
  var iconEl = document.getElementById('dv-asset-icon');
  var descEl = document.getElementById('dv-asset-desc');
  if (titleEl) titleEl.innerText = data.title + ' (' + data.type + ')';
  if (iconEl) iconEl.innerText = icons[data.type] || '📡';
  if (descEl) descEl.innerText = '리니지 노드 [' + data.title + ']의 실제 데이터를 샘플링하여 구조와 품질을 확인합니다.';

  // Refresh AG Grid if exists
  if (window.agGridInstances && window.agGridInstances['ag-grid-cat-dataview']) {
    window.agGridInstances['ag-grid-cat-dataview'].api.refreshCells();
  }

  navigate('cat-data-view');
}

function openLineageQualityReport(id) {
  const data = lineageData[id];
  if (!data) return;

  document.getElementById('qr-asset-title').innerText = `${data.title} 품질 진단 보고서`;

  // Create mock metrics
  const metrics = [
    { label: '완전성', score: 98.2, color: '#52c41a' },
    { label: '유효성', score: 92.5, color: '#1890ff' },
    { label: '일관성', score: 88.7, color: '#fa8c16' },
    { label: '정확성', score: 94.1, color: '#52c41a' }
  ];

  let metricsHtml = '';
  metrics.forEach(m => {
    metricsHtml += `
      <div style="background:#f9f9f9; padding:12px; border-radius:8px; border-left:4px solid ${m.color};">
        <div style="font-size:12px; color:#8c8c8c;">${m.label}</div>
        <div style="font-size:18px; font-weight:700; color:${m.color};">${m.score}%</div>
      </div>
    `;
  });
  document.getElementById('qr-metrics-grid').innerHTML = metricsHtml;

  // Create mock violations
  let violationsHtml = `
    <tr><td>NULL 체크</td><td>WATER_LVL is NULL</td><td>2025-11-12 09:15</td><td><span class="badge" style="background:#ff4d4f;">심각</span></td><td>데이터 재수집 요청</td></tr>
    <tr><td>형식 체크</td><td>OBSV_DT invalid format</td><td>2025-11-11 18:30</td><td><span class="badge" style="background:#faad14;">주의</span></td><td>로그 확인 및 보정</td></tr>
    <tr><td>범위 체크</td><td>VALUE > 100.0</td><td>2025-11-10 14:22</td><td><span class="badge" style="background:#faad14;">주의</span></td><td>비즈니스 로직 검토</td></tr>
  `;
  document.getElementById('qr-violation-list').innerHTML = violationsHtml;

  navigate('cat-quality-report');
}

function closeLineagePanel() {
  document.getElementById('lineageSidePanel').classList.remove('open');
  document.querySelectorAll('.lineage-node-pro').forEach(n => n.classList.remove('selected'));
}

function highlightLinks(nodeId) {
  document.querySelectorAll('.lineage-link-pro').forEach(l => l.classList.remove('highlight', 'impact'));
  document.querySelectorAll('.lineage-node-pro').forEach(n => n.classList.remove('impacted'));

  const downstreams = lineageData[nodeId].downstream;
  if (!downstreams) return;
  downstreams.forEach(dsId => {
    const linkId = `link-${nodeId}-${dsId}`;
    const linkEl = document.getElementById(linkId);
    if (linkEl) linkEl.classList.add('highlight');
  });
}

function toggleImpactAnalysis() {
  isImpactMode = !isImpactMode;
  const btn = document.getElementById('btn-impact-analysis');
  if (isImpactMode) {
    btn.classList.add('active');
    btn.innerHTML = '🎯 영향 분석 중 (ON)';
  } else {
    btn.classList.remove('active');
    btn.innerHTML = '🎯 영향 분석 모드';
    document.querySelectorAll('.lineage-link-pro').forEach(l => l.classList.remove('highlight', 'impact'));
    document.querySelectorAll('.lineage-node-pro').forEach(n => n.classList.remove('impacted'));
  }
}

function simulateQualityFilter() {
  // Simulate UI loading
  const container = document.getElementById('screen-quality');
  container.style.opacity = '0.5';
  container.style.pointerEvents = 'none';

  setTimeout(() => {
    container.style.opacity = '1';
    container.style.pointerEvents = 'auto';

    // Randomize some scores to show dynamic change
    const scoringElements = document.querySelectorAll('.qmb-score');
    scoringElements.forEach(el => {
      const current = parseFloat(el.innerText);
      const change = (Math.random() * 2 - 1).toFixed(1);
      const next = (current + parseFloat(change)).toFixed(1);
      el.innerHTML = `${next}<small>%</small>`;

      // Update bars
      const bar = el.nextElementSibling.firstElementChild;
      if (bar) bar.style.width = `${next}%`;
    });

    console.log('Quality dashboard filter applied: simulating real-time data fetch.');
  }, 400);
}

function simulateImpact(startNodeId) {
  // Clear previous
  document.querySelectorAll('.lineage-node-pro').forEach(n => n.classList.remove('impacted'));
  document.querySelectorAll('.lineage-link-pro').forEach(l => l.classList.remove('impact', 'highlight'));

  let impactedNodes = new Set();
  let queue = [startNodeId];

  while (queue.length > 0) {
    let curr = queue.shift();
    if (impactedNodes.has(curr)) continue;
    impactedNodes.add(curr);

    let downstreams = lineageData[curr].downstream;
    if (downstreams) {
      downstreams.forEach(ds => {
        if (!impactedNodes.has(ds)) {
          queue.push(ds);
          const link = document.getElementById(`link-${curr}-${ds}`);
          if (link) link.classList.add('impact');
        }
      });
    }
  }

  impactedNodes.forEach(id => {
    if (id !== startNodeId) {
      const el = document.getElementById(id);
      if (el) el.classList.add('impacted');
    }
  });
}

function drawLineageLinks() {
  const svg = document.getElementById('lineageSvg');
  if (!svg) return;
  svg.innerHTML = ''; // Clear

  Object.keys(lineageData).forEach(srcId => {
    const srcEl = document.getElementById(srcId);
    if (!srcEl) return;

    const srcDownstreams = lineageData[srcId].downstream;
    if (!srcDownstreams) return;

    srcDownstreams.forEach(tgtId => {
      const tgtEl = document.getElementById(tgtId);
      if (!tgtEl) return;

      const srcRect = srcEl.getBoundingClientRect();
      const tgtRect = tgtEl.getBoundingClientRect();
      const canvasRect = document.getElementById('lineageCanvas').getBoundingClientRect();

      // Relative coordinates
      const x1 = srcRect.right - canvasRect.left + document.getElementById('lineageCanvas').scrollLeft;
      const y1 = srcRect.top - canvasRect.top + srcRect.height / 2 + document.getElementById('lineageCanvas').scrollTop;
      const x2 = tgtRect.left - canvasRect.left + document.getElementById('lineageCanvas').scrollLeft;
      const y2 = tgtRect.top - canvasRect.top + tgtRect.height / 2 + document.getElementById('lineageCanvas').scrollTop;

      // Bezier curve
      const cp1x = x1 + (x2 - x1) / 2;
      const cp2x = x1 + (x2 - x1) / 2;

      const path = document.createElementNS('http://www.w3.org/2000/svg', 'path');
      path.setAttribute('d', `M ${x1} ${y1} C ${cp1x} ${y1}, ${cp2x} ${y2}, ${x2} ${y2}`);
      path.setAttribute('class', 'lineage-link-pro');
      path.setAttribute('id', `link-${srcId}-${tgtId}`);
      svg.appendChild(path);
    });
  });
}

// Window resize handler for links
window.addEventListener('resize', drawLineageLinks);

// (Lineage init is now handled inside navigate())

function toggleSidebar() {
  var isMobile = window.innerWidth <= 768;
  if (isMobile) {
    document.body.classList.toggle('sidebar-open');
    document.body.classList.remove('sidebar-collapsed');
  } else {
    document.body.classList.toggle('sidebar-collapsed');
    document.body.classList.remove('sidebar-open');
  }

  // Redraw lineage links if in lineage screen after layout transition (300ms)
  var currentScreen = document.querySelector('.screen.active');
  if (currentScreen && currentScreen.id === 'screen-cat-lineage') {
    setTimeout(drawLineageLinks, 310);
  }
}

function toggleTheme() {
  const html = document.documentElement;
  const currentTheme = html.getAttribute('data-theme') || 'light';
  const newTheme = currentTheme === 'light' ? 'dark' : 'light';

  html.setAttribute('data-theme', newTheme);
  localStorage.setItem('portal-theme', newTheme);

  updateThemeIcon(newTheme);
  refreshGridThemes();
}

function updateThemeIcon(theme) {
  const btn = document.getElementById('theme-toggle');
  if (btn) {
    btn.innerHTML = theme === 'light'
      ? '<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="#fff" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" style="display:block;"><circle cx="12" cy="12" r="5"/><line x1="12" y1="1" x2="12" y2="3"/><line x1="12" y1="21" x2="12" y2="23"/><line x1="4.22" y1="4.22" x2="5.64" y2="5.64"/><line x1="18.36" y1="18.36" x2="19.78" y2="19.78"/><line x1="1" y1="12" x2="3" y2="12"/><line x1="21" y1="12" x2="23" y2="12"/><line x1="4.22" y1="19.78" x2="5.64" y2="18.36"/><line x1="18.36" y1="5.64" x2="19.78" y2="4.22"/></svg>'
      : '<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="#fff" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" style="display:block;"><path d="M21 12.79A9 9 0 1 1 11.21 3 7 7 0 0 0 21 12.79z"/></svg>';
  }
}

// Initialize Theme
(function initTheme() {
  const savedTheme = localStorage.getItem('portal-theme') || 'light';
  document.documentElement.setAttribute('data-theme', savedTheme);
  // Wait for DOM to finish loading to update icon
  window.addEventListener('DOMContentLoaded', () => {
    updateThemeIcon(savedTheme);
  });
})();

// AI Chat Functions
function setAIQuery(query) {
  const input = document.getElementById('ai-chat-input');
  if (input) {
    input.value = query;
    input.focus();
  }
}

function resetAIChat() {
  const flow = document.getElementById('ai-chat-flow');
  if (flow) {
    flow.innerHTML = `
      <div style="text-align: center; margin-top: 100px; color: var(--text-secondary);">
        <div style="font-size: 48px; margin-bottom: 20px; opacity: 0.5;">🤖</div>
        <div style="font-size: 18px; font-weight: 600; color: var(--text-color);">안녕하세요! K-water 데이터 지능형 비서입니다.</div>
        <div style="font-size: 13px; margin-top: 8px;">데이터 검색, 품질 확인, 통계 분석 등 무엇이든 물어보세요.</div>
      </div>
    `;
  }
}

function sendAIChat() {
  const input = document.getElementById('ai-chat-input');
  const flow = document.getElementById('ai-chat-flow');
  if (!input || !input.value.trim()) return;

  const query = input.value;
  input.value = '';

  // Remove welcome guide if exists
  if (flow.querySelector('div[style*="text-align: center"]')) {
    flow.innerHTML = '';
  }

  // Add User Bubble
  const now = new Date();
  const timeStr = now.getHours() + ':' + (now.getMinutes() < 10 ? '0' : '') + now.getMinutes();

  const userBubble = document.createElement('div');
  userBubble.className = 'chat-bubble user-bubble';
  userBubble.innerHTML = `
    <div class="bubble-content">${query}</div>
    <div class="bubble-meta">${timeStr}</div>
  `;
  flow.appendChild(userBubble);
  flow.scrollTop = flow.scrollHeight;

  // Simulate AI Response
  simulateAIResponse(query);
}

function simulateAIResponse(query) {
  const flow = document.getElementById('ai-chat-flow');

  // Add AI Bubble with Thinking state
  const aiBubble = document.createElement('div');
  aiBubble.className = 'chat-bubble ai-bubble';
  aiBubble.innerHTML = `
    <div class="ai-avatar">🤖</div>
    <div class="bubble-content" id="temp-ai-resp">
      <div class="thought-process-container" id="thought-proc">
        <div class="thought-step" id="step-1">🔍 질문 의도 파악 중...</div>
      </div>
      <div class="typing-indicator" style="display:flex; gap:4px; padding:10px 0;">
        <span style="width:6px; height:6px; background:var(--primary-color); border-radius:50%; animation: bounce 1s infinite 0.1s;"></span>
        <span style="width:6px; height:6px; background:var(--primary-color); border-radius:50%; animation: bounce 1s infinite 0.2s;"></span>
        <span style="width:6px; height:6px; background:var(--primary-color); border-radius:50%; animation: bounce 1s infinite 0.3s;"></span>
      </div>
    </div>
    <div class="bubble-meta">방금 전</div>
  `;
  flow.appendChild(aiBubble);
  flow.scrollTop = flow.scrollHeight;

  // Step-by-step thinking animation
  setTimeout(() => {
    const step1 = document.getElementById('step-1');
    if (step1) step1.innerHTML = '<span>✔</span> 관련 메타데이터 및 카탈로그 조회 완료';
    step1.classList.add('completed');
    const proc = document.getElementById('thought-proc');
    const step2 = document.createElement('div');
    step2.className = 'thought-step';
    step2.id = 'step-2';
    step2.innerHTML = '⚙️ 데이터 통계 쿼리 생성 및 실행 중...';
    proc.appendChild(step2);
    flow.scrollTop = flow.scrollHeight;
  }, 1000);

  setTimeout(() => {
    const step2 = document.getElementById('step-2');
    if (step2) step2.innerHTML = '<span>✔</span> 소양강댐/발전량 데이터 분석 완료';
    step2.classList.add('completed');
    const proc = document.getElementById('thought-proc');
    const step3 = document.createElement('div');
    step3.className = 'thought-step';
    step3.id = 'step-3';
    step3.innerHTML = '📊 결과 시각화 및 답변 요약 작성 중...';
    proc.appendChild(step3);
    flow.scrollTop = flow.scrollHeight;
  }, 2300);

  setTimeout(() => {
    const step3 = document.getElementById('step-3');
    if (step3) step3.innerHTML = '<span>✔</span> 데이터 통찰 도출 완료';
    step3.classList.add('completed');

    // Finalizing response
    const resp = document.getElementById('temp-ai-resp');
    resp.querySelector('.typing-indicator').remove();

    const content = document.createElement('div');
    content.innerHTML = `
      <p style="margin: 10px 0;">질의하신 <strong>소양강댐</strong>의 최근 추세를 분석했습니다. 현재 수위는 안정적인 상승 곡선을 그리며 계획 홍수위 이내를 유지하고 있습니다.</p>
      <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 10px; margin: 12px 0;">
        <div class="inner-stat-card">
          <div class="is-label">분석 데이터 기간</div>
          <div class="is-value">최근 7일</div>
        </div>
        <div class="inner-stat-card">
          <div class="is-label">주요 이슈</div>
          <div class="is-value" style="color:#52c41a;">정상 가동 중</div>
        </div>
      </div>
      <div class="ai-inline-chart" style="background: var(--bg-color); border: 1px solid var(--border-color); border-radius: 8px; padding: 12px;">
        <div style="font-size: 11px; font-weight: 600; margin-bottom: 6px;">수위 변화 추이 시각화</div>
        <svg viewBox="0 0 300 80" style="width: 100%;">
          <polyline points="0,60 50,55 100,58 150,45 200,42 250,30 300,25" fill="none" stroke="#1677ff" stroke-width="2" />
        </svg>
      </div>
      <div style="margin-top: 12px; font-size: 12px; color: var(--text-secondary);">자세한 내용은 <span style="color:var(--primary-color); cursor:pointer; text-decoration:underline;">데이터 상세 보기</span>를 통해 확인하실 수 있습니다.</div>
    `;
    resp.appendChild(content);
    flow.scrollTop = flow.scrollHeight;
  }, 3500);
}

// Enter key support for AI chat
document.addEventListener('DOMContentLoaded', () => {
  const aiInput = document.getElementById('ai-chat-input');
  if (aiInput) {
    aiInput.addEventListener('keypress', (e) => {
      if (e.key === 'Enter') sendAIChat();
    });
  }
});

// ===== AG GRID PAGE INITIALIZERS =====
function tagRenderer(color, bg) {
  return function (p) {
    return '<span style="background:' + bg + ';color:' + color + ';padding:1px 8px;border-radius:4px;font-size:11px;">' + p.value + '</span>';
  };
}

function initAllGrids() {
  initCommunityGrids();
  initSystemGrids();
  initCatalogGrids();
  initCollectGrids();
  initDistributeGrids();
  initMetadataGrids();
  initWidgetSettingsGrid();
  initMonitoringGrids();
  initExtRegisterGrid();
}

function initMonitoringGrids() {
  // 디지털 트윈 연계 상세
  initAGGrid('ag-grid-digital-twin', [
    { field: 'dtSystem', headerName: 'DT 시스템', width: 110, cellRenderer: function(p) {
      var icons = { '정수장':'🏭', '관로':'🔧', '댐':'🏔️', '발전':'⚡', '스마트':'📡' };
      return '<strong>' + (icons[p.value]||'') + ' ' + p.value + ' DT</strong>';
    }},
    { field: 'dataset', headerName: '데이터셋', flex: 1 },
    { field: 'type', headerName: '연계방식', width: 90, cellRenderer: function(p) {
      var m = { '실시간': { bg:'#e6f7ff', c:'#1677ff' }, '배치': { bg:'#f6ffed', c:'#52c41a' }, 'CDC': { bg:'#f3e8ff', c:'#722ed1' } };
      var s = m[p.value] || { bg:'#f5f5f5', c:'#666' };
      return '<span style="background:'+s.bg+';color:'+s.c+';padding:2px 8px;border-radius:4px;font-size:11px;">'+p.value+'</span>';
    }},
    { field: 'cycle', headerName: '수신주기', width: 80 },
    { field: 'lastSync', headerName: '최근 동기화', width: 100 },
    { field: 'todayCount', headerName: '금일 수신', width: 90, type:'numericColumn', cellRenderer: function(p) { return '<span style="font-weight:600; color:#1677ff;">'+p.value+'</span>'; } },
    { field: 'status', headerName: '상태', width: 80, cellRenderer: function(p) {
      var m = { '정상': { bg:'#e8f5e9', c:'#2e7d32', dot:'#52c41a' }, '지연': { bg:'#fff8e1', c:'#d48806', dot:'#faad14' }, '오류': { bg:'#ffebee', c:'#c62828', dot:'#ff4d4f' } };
      var s = m[p.value] || { bg:'#f5f5f5', c:'#666', dot:'#999' };
      return '<span style="display:inline-flex;align-items:center;gap:4px;background:'+s.bg+';color:'+s.c+';padding:2px 8px;border-radius:4px;font-size:11px;"><span style="width:6px;height:6px;border-radius:50%;background:'+s.dot+';"></span>'+p.value+'</span>';
    }},
    { field: 'availability', headerName: '가용률', width: 80, cellRenderer: function(p) {
      var v = parseFloat(p.value);
      var c = v >= 99 ? '#52c41a' : v >= 97 ? '#fa8c16' : '#ff4d4f';
      return '<span style="color:'+c+'; font-weight:600;">'+p.value+'</span>';
    }}
  ], [
    { dtSystem:'정수장', dataset:'수질자동측정 (pH/탁도/잔류염소)', type:'실시간', cycle:'5분', lastSync:'11:45:02', todayCount:'312,540', status:'정상', availability:'99.2%' },
    { dtSystem:'정수장', dataset:'유량계측 (원수/정수/배수)', type:'실시간', cycle:'5분', lastSync:'11:45:02', todayCount:'285,120', status:'정상', availability:'99.4%' },
    { dtSystem:'정수장', dataset:'약품투입량 (PAC/NaOH/Cl2)', type:'배치', cycle:'1시간', lastSync:'11:00:00', todayCount:'244,340', status:'정상', availability:'99.1%' },
    { dtSystem:'관로', dataset:'관망 압력센서 데이터', type:'실시간', cycle:'10분', lastSync:'11:32:18', todayCount:'124,200', status:'지연', availability:'96.8%' },
    { dtSystem:'관로', dataset:'유량·누수감지 데이터', type:'실시간', cycle:'10분', lastSync:'11:32:18', todayCount:'98,450', status:'지연', availability:'97.2%' },
    { dtSystem:'관로', dataset:'관로 GIS 속성정보', type:'배치', cycle:'일1회', lastSync:'06:00:00', todayCount:'89,350', status:'정상', availability:'99.5%' },
    { dtSystem:'댐', dataset:'수위·저수율 실시간 데이터', type:'실시간', cycle:'5분', lastSync:'11:46:30', todayCount:'245,680', status:'정상', availability:'99.8%' },
    { dtSystem:'댐', dataset:'방류량·유입량 데이터', type:'실시간', cycle:'5분', lastSync:'11:46:30', todayCount:'198,400', status:'정상', availability:'99.7%' },
    { dtSystem:'댐', dataset:'댐체 계측(변위/침하/양압력)', type:'CDC', cycle:'10분', lastSync:'11:40:15', todayCount:'184,332', status:'정상', availability:'99.9%' },
    { dtSystem:'발전', dataset:'발전량·출력 실시간', type:'실시간', cycle:'3분', lastSync:'11:47:55', todayCount:'204,500', status:'정상', availability:'99.5%' },
    { dtSystem:'발전', dataset:'터빈 진동·온도 센서', type:'실시간', cycle:'3분', lastSync:'11:47:55', todayCount:'186,200', status:'정상', availability:'99.3%' },
    { dtSystem:'발전', dataset:'발전설비 가동이력', type:'배치', cycle:'1시간', lastSync:'11:00:00', todayCount:'133,300', status:'정상', availability:'99.6%' },
    { dtSystem:'스마트', dataset:'스마트미터링 (광역TM)', type:'실시간', cycle:'1분', lastSync:'11:48:10', todayCount:'284,600', status:'정상', availability:'99.1%' },
    { dtSystem:'스마트', dataset:'IoT센서 통합 데이터', type:'실시간', cycle:'1분', lastSync:'11:48:10', todayCount:'209,400', status:'정상', availability:'99.0%' }
  ], {
    getRowStyle: function(p) {
      if (p.data.status === '지연') return { background: '#fffbe6' };
      if (p.data.status === '오류') return { background: '#fff5f5' };
    }
  });

  // LLMOps 배포·학습 이력
  initAGGrid('ag-grid-llmops', [
    { field: 'date', headerName: '일시', width: 110 },
    { field: 'model', headerName: '모델', width: 130, cellRenderer: function(p) { return '<strong>'+p.value+'</strong>'; } },
    { field: 'action', headerName: '작업', width: 100, cellRenderer: function(p) {
      var m = { '배포': { bg:'#e8f5e9', c:'#2e7d32' }, '학습': { bg:'#e8f0fe', c:'#1967d2' }, '롤백': { bg:'#fff3e0', c:'#ef6c00' }, '테스트': { bg:'#f3e8ff', c:'#722ed1' } };
      var s = m[p.value] || { bg:'#f5f5f5', c:'#666' };
      return '<span style="background:'+s.bg+';color:'+s.c+';padding:2px 8px;border-radius:4px;font-size:11px;">'+p.value+'</span>';
    }},
    { field: 'env', headerName: '환경', width: 90 },
    { field: 'metrics', headerName: '성능 지표', flex: 1 },
    { field: 'duration', headerName: '소요시간', width: 90 },
    { field: 'status', headerName: '상태', width: 80, cellRenderer: function(p) {
      var m = { '성공': '#52c41a', '실패': '#ff4d4f', '진행중': '#1677ff' };
      var c = m[p.value] || '#666';
      return '<span style="color:'+c+'; font-weight:600;">'+p.value+'</span>';
    }},
    { field: 'operator', headerName: '담당자', width: 80 }
  ], [
    { date:'2026-03-03 09:20', model:'DH-Chat v3.3-rc1', action:'테스트', env:'Staging', metrics:'정확도 94.1% / F1 0.91', duration:'2h 15m', status:'진행중', operator:'이AI' },
    { date:'2026-02-28 14:00', model:'DH-Chat v3.2', action:'배포', env:'Production', metrics:'정확도 92.4% / F1 0.89', duration:'45m', status:'성공', operator:'이AI' },
    { date:'2026-02-25 10:00', model:'DH-Predict v1.5', action:'학습', env:'GPU서버', metrics:'RMSE 0.034 / MAE 0.021', duration:'6h 30m', status:'성공', operator:'김분석' },
    { date:'2026-02-20 16:30', model:'DH-Chat v3.2-rc2', action:'테스트', env:'Staging', metrics:'정확도 91.8% / F1 0.88', duration:'1h 50m', status:'성공', operator:'이AI' },
    { date:'2026-02-15 09:00', model:'DH-Embed v2.1', action:'배포', env:'Production', metrics:'검색정확도 89.1% / MRR 0.82', duration:'30m', status:'성공', operator:'박검색' },
    { date:'2026-02-10 11:00', model:'DH-Chat v3.1', action:'롤백', env:'Production', metrics:'정확도 저하 감지 → v3.0 롤백', duration:'15m', status:'성공', operator:'이AI' },
    { date:'2026-02-08 08:00', model:'DH-Predict v1.4', action:'학습', env:'GPU서버', metrics:'RMSE 0.042 / MAE 0.028', duration:'8h 10m', status:'실패', operator:'김분석' }
  ], {
    getRowStyle: function(p) {
      if (p.data.status === '실패') return { background: '#fff5f5' };
      if (p.data.status === '진행중') return { background: '#f0f7ff' };
    }
  });
}

function initCommunityGrids() {
  // 공지사항
  initAGGrid('ag-grid-comm-notice', [
    { field: 'no', headerName: '번호', width: 70, cellRenderer: function (p) { return p.data.urgent ? '<span style="color:#f44336;font-weight:700;">긴급</span>' : p.value; } },
    { field: 'category', headerName: '분류', width: 90, cellRenderer: function (p) { return '<span style="background:' + p.data.catBg + ';color:' + p.data.catColor + ';padding:1px 8px;border-radius:4px;font-size:11px;">' + p.value + '</span>'; } },
    { field: 'title', headerName: '제목', flex: 2, cellRenderer: function (p) { return p.data.urgent ? '<strong>' + p.value + '</strong>' : p.value; } },
    { field: 'author', headerName: '작성자', width: 90 },
    { field: 'date', headerName: '등록일', width: 90 },
    { field: 'views', headerName: '조회', width: 70, type: 'numericColumn' },
    { field: 'attach', headerName: '첨부', width: 70, cellRenderer: function (p) { return p.value ? '📎' : ''; } }
  ], [
    { no: '', urgent: true, category: '긴급공지', catBg: '#fff1f0', catColor: '#cf1322', title: '[긴급] 2/28(금) 시스템 정기점검 안내 (22:00~06:00)', author: '시스템관리팀', date: '2026-02-25', views: 342, attach: true },
    { no: '', urgent: true, category: '긴급공지', catBg: '#fff1f0', catColor: '#cf1322', title: '[긴급] 외부연계 API 인증키 갱신 안내 (3월 1일까지)', author: '데이터관리팀', date: '2026-02-24', views: 218, attach: true },
    { no: 126, urgent: false, category: '데이터정책', catBg: '#e8f5e9', catColor: '#2e7d32', title: '2026년 데이터 품질관리 계획 변경 안내', author: '품질관리팀', date: '2026-02-22', views: 189, attach: true },
    { no: 125, urgent: false, category: '시스템안내', catBg: '#e6f7ff', catColor: '#1677ff', title: '데이터허브 포털 v2.1 업데이트 안내 (신규 기능 추가)', author: '시스템관리팀', date: '2026-02-20', views: 275, attach: true },
    { no: 124, urgent: false, category: '교육·세미나', catBg: '#f3e8ff', catColor: '#7c3aed', title: '3월 데이터 리터러시 교육 참가자 모집 (3/10~3/14)', author: '교육기획팀', date: '2026-02-18', views: 156, attach: true },
    { no: 123, urgent: false, category: '데이터정책', catBg: '#e8f5e9', catColor: '#2e7d32', title: '비식별화 처리 가이드라인 개정 안내 (v3.2)', author: '보안관리팀', date: '2026-02-15', views: 134, attach: true },
    { no: 122, urgent: false, category: '시스템안내', catBg: '#e6f7ff', catColor: '#1677ff', title: 'Kafka 스트리밍 클러스터 증설 완료 안내', author: '인프라팀', date: '2026-02-13', views: 98, attach: false },
    { no: 121, urgent: false, category: '일반공지', catBg: '#fff7e6', catColor: '#d48806', title: '2026년 1분기 데이터 활용 우수사례 공모', author: '데이터전략팀', date: '2026-02-10', views: 203, attach: true },
    { no: 120, urgent: false, category: '교육·세미나', catBg: '#f3e8ff', catColor: '#7c3aed', title: 'dbt 활용 실습 워크숍 후기 및 자료 공유', author: '교육기획팀', date: '2026-02-08', views: 167, attach: true },
    { no: 119, urgent: false, category: '시스템안내', catBg: '#e6f7ff', catColor: '#1677ff', title: 'AI 검색 엔진 모델 업그레이드 안내 (Claude 4.0 적용)', author: 'AI개발팀', date: '2026-02-05', views: 312, attach: false }
  ], { getRowStyle: function (p) { if (p.data.urgent) return { background: '#fff8f0' }; } });

  // 내부게시판
  initAGGrid('ag-grid-comm-internal', [
    { field: 'category', headerName: '분류', width: 90, cellRenderer: function (p) { return '<span style="background:' + p.data.catBg + ';color:' + p.data.catColor + ';padding:1px 8px;border-radius:4px;font-size:11px;">' + p.value + '</span>'; } },
    { field: 'title', headerName: '제목', flex: 2, cellRenderer: function (p) { var hot = p.data.hot ? ' <span style="color:#f44336;font-size:10px;font-weight:600;">HOT</span>' : ''; return '<strong>' + p.value + '</strong>' + hot; } },
    { field: 'author', headerName: '작성자', width: 90 },
    { field: 'dept', headerName: '부서', width: 90 },
    { field: 'date', headerName: '등록일', width: 90 },
    { field: 'views', headerName: '조회', width: 70, type: 'numericColumn' },
    { field: 'comments', headerName: '댓글', width: 70, type: 'numericColumn', cellStyle: function (p) { return p.value >= 7 ? { color: '#1677ff', fontWeight: '600' } : {}; } }
  ], [
    { category: '기술Q&A', catBg: '#e6f7ff', catColor: '#1677ff', title: 'CDC 연계 시 LOB 컬럼 처리 방법 문의', hot: true, author: '김데이터', dept: '데이터분석팀', date: '2026-02-26', views: 89, comments: 7 },
    { category: '활용 팁', catBg: '#f3e8ff', catColor: '#7c3aed', title: 'AI 검색으로 복합 조건 데이터 찾는 꿀팁 공유', hot: false, author: '박분석', dept: '수질관리팀', date: '2026-02-25', views: 156, comments: 12 },
    { category: '프로젝트', catBg: '#e8f5e9', catColor: '#2e7d32', title: '수질예측 모델 고도화 프로젝트 중간보고', hot: false, author: '이엔지', dept: 'AI개발팀', date: '2026-02-24', views: 134, comments: 5 },
    { category: '자유게시판', catBg: '#fff7e6', catColor: '#d48806', title: '신입사원 데이터허브 온보딩 후기 (feat. 이 기능 꼭 써보세요)', hot: false, author: '최신입', dept: '경영지원팀', date: '2026-02-23', views: 201, comments: 15 },
    { category: '기술Q&A', catBg: '#e6f7ff', catColor: '#1677ff', title: 'dbt 모델에서 incremental 전략 선택 기준이 궁금합니다', hot: false, author: '정디비', dept: '인프라팀', date: '2026-02-22', views: 67, comments: 4 },
    { category: '활용 팁', catBg: '#f3e8ff', catColor: '#7c3aed', title: '리니지 뷰에서 영향도 분석 활용하기', hot: false, author: '박수원', dept: '수자원관리팀', date: '2026-02-21', views: 98, comments: 6 },
    { category: '프로젝트', catBg: '#e8f5e9', catColor: '#2e7d32', title: '광역상수도 IoT 센서 데이터 통합 진행현황', hot: false, author: '김센서', dept: '계측운영팀', date: '2026-02-20', views: 112, comments: 8 },
    { category: '자유게시판', catBg: '#fff7e6', catColor: '#d48806', title: '데이터 품질 점수 올리기 대작전 (우리 부서 후기)', hot: false, author: '홍길동', dept: '수자원관리팀', date: '2026-02-19', views: 178, comments: 21 }
  ]);

  // 외부게시판
  initAGGrid('ag-grid-comm-external', [
    { field: 'category', headerName: '분류', width: 90, cellRenderer: function (p) { return '<span style="background:' + p.data.catBg + ';color:' + p.data.catColor + ';padding:1px 8px;border-radius:4px;font-size:11px;">' + p.value + '</span>'; } },
    { field: 'title', headerName: '제목', flex: 2, cellRenderer: function (p) { return '<strong>' + p.value + '</strong>'; } },
    { field: 'author', headerName: '작성자', width: 90 },
    { field: 'org', headerName: '소속기관', width: 100 },
    {
      field: 'status', headerName: '상태', width: 90, cellRenderer: function (p) {
        var colors = { '답변대기': '#fa8c16', '검토중': '#1677ff', '답변완료': '#52c41a', '반영완료': '#52c41a', '승인완료': '#52c41a' };
        var c = colors[p.value] || '#999';
        return '<span style="display:inline-flex;align-items:center;gap:4px;font-size:11px;"><span style="width:6px;height:6px;border-radius:50%;background:' + c + ';display:inline-block;"></span>' + p.value + '</span>';
      }
    },
    { field: 'date', headerName: '등록일', width: 90 },
    { field: 'comments', headerName: '댓글', width: 70, type: 'numericColumn' }
  ], [
    { category: 'API 문의', catBg: '#e6f7ff', catColor: '#1677ff', title: '유량 데이터 실시간 API 연동 시 인증 오류 문의', author: '박외부', org: '㈜워터테크', status: '답변대기', date: '2026-02-26', comments: 0 },
    { category: '데이터요청', catBg: '#f3e8ff', catColor: '#7c3aed', title: '2025년 월별 수력발전 통계 데이터 제공 요청', author: '김연구', org: '한국환경연구원', status: '검토중', date: '2026-02-25', comments: 2 },
    { category: '기술지원', catBg: '#e8f5e9', catColor: '#2e7d32', title: 'Kafka 컨슈머 그룹 연결 설정 가이드 요청', author: '이개발', org: '㈜스마트워터', status: '답변완료', date: '2026-02-24', comments: 3 },
    { category: '제안·건의', catBg: '#fff7e6', catColor: '#d48806', title: '외부 개발자 포털 API 문서 개선 건의', author: '최개발', org: '㈜데이터브릿지', status: '반영완료', date: '2026-02-22', comments: 5 },
    { category: 'API 문의', catBg: '#e6f7ff', catColor: '#1677ff', title: '수질 모니터링 데이터 Batch API Rate Limit 문의', author: '박외부', org: '㈜워터테크', status: '답변완료', date: '2026-02-20', comments: 4 },
    { category: '데이터요청', catBg: '#f3e8ff', catColor: '#7c3aed', title: '댐 방류량 예측 데이터 학술 연구 목적 이용 신청', author: '정교수', org: '서울대 환경학과', status: '승인완료', date: '2026-02-18', comments: 1 },
    { category: '기술지원', catBg: '#e8f5e9', catColor: '#2e7d32', title: 'REST API vs GraphQL 엔드포인트 선택 가이드', author: '김협력', org: '㈜에코데이터', status: '답변완료', date: '2026-02-15', comments: 6 }
  ]);

  // 자료실
  initAGGrid('ag-grid-comm-archive', [
    { field: 'category', headerName: '분류', width: 90, cellRenderer: function (p) { return '<span style="background:' + p.data.catBg + ';color:' + p.data.catColor + ';padding:1px 8px;border-radius:4px;font-size:11px;">' + p.value + '</span>'; } },
    { field: 'title', headerName: '자료명', flex: 2, cellRenderer: function (p) { return '<strong>' + p.value + '</strong>'; } },
    { field: 'author', headerName: '작성자', width: 90 },
    {
      field: 'fileType', headerName: '형식', width: 70, cellRenderer: function (p) {
        var colors = { PDF: '#cf1322', PPTX: '#1677ff', XLSX: '#2e7d32', ZIP: '#d48806' };
        var bgs = { PDF: '#fff1f0', PPTX: '#e6f7ff', XLSX: '#e8f5e9', ZIP: '#fff7e6' };
        return '<span style="background:' + (bgs[p.value] || '#f5f5f5') + ';color:' + (colors[p.value] || '#666') + ';padding:2px 6px;border-radius:3px;font-size:11px;">' + p.value + '</span>';
      }
    },
    { field: 'size', headerName: '용량', width: 75 },
    { field: 'date', headerName: '등록일', width: 90 },
    { field: 'downloads', headerName: '다운', width: 70, type: 'numericColumn' },
    { field: 'action', headerName: '받기', width: 70, sortable: false, filter: false, cellRenderer: function () { return '<button class="btn btn-outline" style="padding:1px 6px;font-size:11px;">📥</button>'; } }
  ], [
    { category: '가이드', catBg: '#e6f7ff', catColor: '#1677ff', title: '데이터허브 포털 사용자 가이드 v2.1', author: '시스템관리팀', fileType: 'PDF', size: '12.4MB', date: '2026-02-25', downloads: 156 },
    { category: '교육자료', catBg: '#f3e8ff', catColor: '#7c3aed', title: '2026년 데이터 리터러시 교육교재 (초급~중급)', author: '교육기획팀', fileType: 'PPTX', size: '28.7MB', date: '2026-02-22', downloads: 89 },
    { category: '정책·규정', catBg: '#e8f5e9', catColor: '#2e7d32', title: '데이터 거버넌스 운영 지침서 (2026년 개정)', author: '데이터전략팀', fileType: 'PDF', size: '5.2MB', date: '2026-02-20', downloads: 234 },
    { category: '양식·서식', catBg: '#fff7e6', catColor: '#d48806', title: '데이터 제공 신청서 양식 (2026년)', author: '데이터관리팀', fileType: 'XLSX', size: '0.3MB', date: '2026-02-18', downloads: 312 },
    { category: '가이드', catBg: '#e6f7ff', catColor: '#1677ff', title: 'API 연동 개발자 가이드 (REST/GraphQL)', author: 'AI개발팀', fileType: 'PDF', size: '8.1MB', date: '2026-02-15', downloads: 178 },
    { category: '교육자료', catBg: '#f3e8ff', catColor: '#7c3aed', title: 'dbt 실습 워크숍 교재 및 실습 코드', author: '교육기획팀', fileType: 'ZIP', size: '45.3MB', date: '2026-02-12', downloads: 67 },
    { category: '정책·규정', catBg: '#e8f5e9', catColor: '#2e7d32', title: '비식별화 처리 가이드라인 v3.2', author: '보안관리팀', fileType: 'PDF', size: '3.8MB', date: '2026-02-10', downloads: 145 },
    { category: '기술문서', catBg: '#e6f7ff', catColor: '#1677ff', title: '데이터 파이프라인 아키텍처 설계서', author: '인프라팀', fileType: 'PDF', size: '15.6MB', date: '2026-02-08', downloads: 98 }
  ]);
}

function initCatalogGrids() {
  // 컬럼 스키마 (cat-detail)
  initAGGrid('ag-grid-cat-schema', [
    { field: 'colName', headerName: '컬럼명', width: 90, cellRenderer: function (p) { return '<strong>' + p.value + '</strong>'; } },
    { field: 'colNameEn', headerName: '영문명', width: 115, cellStyle: { fontFamily: 'monospace', fontSize: '11px' } },
    { field: 'type', headerName: '타입', width: 100, cellStyle: { fontFamily: 'monospace', fontSize: '11px' } },
    { field: 'pk', headerName: 'PK', width: 55, cellRenderer: function (p) { return p.value ? '✅' : ''; } },
    { field: 'notNull', headerName: 'NOT NULL', width: 80, cellRenderer: function (p) { return p.value ? '✅' : ''; } },
    { field: 'stdTerm', headerName: '표준용어', width: 96 },
    { field: 'desc', headerName: '설명', flex: 1 },
    { field: 'profile', headerName: '프로파일링', width: 110 }
  ], [
    { colName: '관측소ID', colNameEn: 'OBSV_STN_ID', type: 'VARCHAR(20)', pk: true, notNull: true, stdTerm: '관측소코드', desc: '관측소 식별자', profile: '342 고유값' },
    { colName: '관측일시', colNameEn: 'OBSV_DT', type: 'TIMESTAMP', pk: true, notNull: true, stdTerm: '관측일시', desc: '측정시각', profile: '100% 채움' },
    { colName: '수위값', colNameEn: 'WATER_LVL', type: 'FLOAT', pk: false, notNull: true, stdTerm: '수위', desc: '수면높이(m)', profile: '평균 23.47' },
    { colName: '측정방법', colNameEn: 'MEAS_MTHD', type: 'VARCHAR(10)', pk: false, notNull: false, stdTerm: '측정방법코드', desc: '자동/수동 구분', profile: '3 고유값' },
    { colName: '품질등급', colNameEn: 'QA_GRADE_CD', type: 'CHAR(1)', pk: false, notNull: false, stdTerm: '품질등급', desc: 'A/B/C/D 등급', profile: '4 고유값' }
  ]);

  // 즐겨찾기 (cat-bookmark)
  initAGGrid('ag-grid-cat-bookmark', [
    { field: 'name', headerName: '데이터 자산명', flex: 2, cellRenderer: function (p) { return '<strong>' + p.value + '</strong>'; } },
    { field: 'type', headerName: '유형', width: 80 },
    { field: 'system', headerName: '시스템', width: 90 },
    { field: 'domain', headerName: '도메인', width: 90 },
    { field: 'addDate', headerName: '추가일', width: 90 },
    {
      field: 'quality', headerName: '품질', width: 70, cellRenderer: function (p) {
        if (!p.value) return '-';
        var c = parseFloat(p.value) >= 92 ? '#4caf50' : '#ff9800';
        return '<span style="color:' + c + ';">' + p.value + '</span>';
      }
    },
    {
      field: 'action', headerName: '관리', width: 90, sortable: false, filter: false, cellRenderer: function () {
        return '<button class="btn btn-outline" style="padding:1px 6px;font-size:11px;">공유</button> <button class="btn btn-outline" style="padding:1px 6px;font-size:11px;">📥</button>';
      }
    }
  ], [
    { name: 'TB_WATER_LEVEL (수위관측)', type: '테이블', system: 'RWIS', domain: '수자원', addDate: '2025-10-15', quality: '94.2%' },
    { name: 'TB_FLOW_RATE (유량관측)', type: '테이블', system: 'RWIS', domain: '수자원', addDate: '2025-10-15', quality: '92.8%' },
    { name: '소양강댐 수위 대시보드', type: '대시보드', system: 'Serve Layer', domain: '수자원', addDate: '2025-10-20', quality: null },
    { name: '수질분석_온톨로지_뷰', type: '그래프뷰', system: 'Neo4j', domain: '수질', addDate: '2025-11-01', quality: null },
    { name: 'TB_POWER_GENERATION (발전량)', type: '테이블', system: 'HDAPS', domain: '에너지', addDate: '2025-11-05', quality: '97.1%' },
    { name: '일별수위리포트 (fct_daily)', type: 'dbt 모델', system: 'dbt', domain: '수자원', addDate: '2025-11-10', quality: '91.5%' }
  ]);

  // 데이터 요청 (cat-request)
  initAGGrid('ag-grid-cat-request', [
    { field: 'reqNo', headerName: '요청번호', width: 90, cellStyle: { fontFamily: 'monospace', fontSize: '11px', color: '#1967d2' } },
    { field: 'type', headerName: '유형', width: 80, cellRenderer: function(p) {
      var m = {'활용요청':{bg:'#e6f7ff',c:'#0958d9'},'권한요청':{bg:'#fff7e6',c:'#d48806'},'품질신고':{bg:'#fff1f0',c:'#cf1322'},'메타수정':{bg:'#f9f0ff',c:'#722ed1'}};
      var s = m[p.value]||{bg:'#f5f5f5',c:'#666'};
      return '<span style="background:'+s.bg+';color:'+s.c+';padding:1px 8px;border-radius:4px;font-size:11px;font-weight:600;">'+p.value+'</span>';
    }},
    { field: 'content', headerName: '요청내용', flex: 2 },
    { field: 'target', headerName: '대상데이터', width: 120, cellStyle: { fontFamily: 'monospace', fontSize: '11px' } },
    { field: 'requester', headerName: '요청자', width: 70 },
    { field: 'dept', headerName: '부서', width: 80 },
    { field: 'date', headerName: '요청일', width: 82 },
    { field: 'status', headerName: '상태', width: 80, cellRenderer: function(p) {
      var st = {'승인대기':{bg:'#fff7e6',c:'#d48806',dot:'#faad14'},'처리중':{bg:'#e6f7ff',c:'#0958d9',dot:'#1677ff'},'승인완료':{bg:'#f6ffed',c:'#389e0d',dot:'#52c41a'},'반려':{bg:'#fff1f0',c:'#cf1322',dot:'#ff4d4f'},'보완요청':{bg:'#fffbe6',c:'#d48806',dot:'#fa8c16'}};
      var s = st[p.value]||{bg:'#f5f5f5',c:'#666',dot:'#999'};
      return '<span style="display:inline-flex;align-items:center;gap:4px;background:'+s.bg+';color:'+s.c+';padding:2px 8px;border-radius:4px;font-size:11px;font-weight:600;"><span style="width:6px;height:6px;background:'+s.dot+';border-radius:50%;"></span>'+p.value+'</span>';
    }},
    { field: 'handler', headerName: '처리자', width: 70 },
    { field: 'action', headerName: '관리', width: 55, sortable: false, filter: false, cellRenderer: function() { return '<button class="btn btn-outline" style="padding:1px 6px;font-size:11px;">상세</button>'; }}
  ], [
    { reqNo:'REQ-046', type:'활용요청', content:'소양강댐 수위데이터 실시간 API 활용', target:'TB_WATER_LEVEL', requester:'김데이터', dept:'수질관리부', date:'02-28', status:'승인대기', handler:'-' },
    { reqNo:'REQ-045', type:'권한요청', content:'고객정보 1등급 접근권한 신청', target:'TB_CUSTOMER', requester:'박요금', dept:'수도사업부', date:'02-27', status:'보완요청', handler:'이보안' },
    { reqNo:'REQ-044', type:'활용요청', content:'관망 GIS + 수질 조인 데이터셋 요청', target:'TB_WATER_QUAL', requester:'최공간', dept:'시설관리부', date:'02-26', status:'처리중', handler:'정관리' },
    { reqNo:'REQ-043', type:'품질신고', content:'수질DB NULL값 다수 발견 (pH 컬럼)', target:'TB_QUALITY_RAW', requester:'홍수질', dept:'수질관리부', date:'02-25', status:'처리중', handler:'김품질' },
    { reqNo:'REQ-042', type:'활용요청', content:'발전량 데이터 CSV 다운로드 요청', target:'TB_POWER_GEN', requester:'이분석', dept:'정보화부', date:'02-24', status:'승인완료', handler:'정관리' },
    { reqNo:'REQ-041', type:'메타수정', content:'수위관측소 좌표정보 오류 수정 요청', target:'DIM_STATION', requester:'강지리', dept:'시설관리부', date:'02-23', status:'승인완료', handler:'김메타' },
    { reqNo:'REQ-040', type:'권한요청', content:'개인정보 포함 데이터셋 열람 신청', target:'TB_PERSONAL', requester:'윤인사', dept:'환경부서', date:'02-22', status:'반려', handler:'이보안' },
    { reqNo:'REQ-039', type:'활용요청', content:'광역상수도 유량 분석용 데이터 요청', target:'TB_FLOW_STAT', requester:'박분석', dept:'수도사업부', date:'02-20', status:'승인완료', handler:'정관리' },
    { reqNo:'REQ-038', type:'품질신고', content:'환경부 API 수질측정 데이터 누락 신고', target:'환경부 API', requester:'홍수질', dept:'수질관리부', date:'02-18', status:'승인완료', handler:'김품질' },
    { reqNo:'REQ-037', type:'메타수정', content:'댐방류량 테이블 컬럼 설명 보완 요청', target:'TB_DAM_RELEASE', requester:'이댐', dept:'수질관리부', date:'02-15', status:'승인완료', handler:'김메타' }
  ], {
    domLayout: 'autoHeight',
    getRowStyle: function(p) {
      if (p.data.status === '반려') return { background: '#fff5f5' };
      if (p.data.status === '보완요청') return { background: '#fffbe6' };
    }
  });

  // Cypher 질의 결과 (cat-ontology)
  initAGGrid('ag-grid-cat-cypher', [
    { field: 'facility', headerName: '시설명', width: 110, cellRenderer: function(p) { return '<strong>' + p.value + '</strong>'; }},
    { field: 'type', headerName: '시설유형', width: 80, cellRenderer: function(p) {
      var m = {'댐':{bg:'#e6f7ff',c:'#0958d9'},'보':{bg:'#f6ffed',c:'#389e0d'},'정수장':{bg:'#fff7e6',c:'#d48806'},'하천':{bg:'#f9f0ff',c:'#722ed1'}};
      var s = m[p.value]||{bg:'#f5f5f5',c:'#666'};
      return '<span style="background:'+s.bg+';color:'+s.c+';padding:1px 8px;border-radius:4px;font-size:11px;font-weight:600;">'+p.value+'</span>';
    }},
    { field: 'system', headerName: '시스템', width: 90, cellStyle: { fontFamily: 'monospace', fontSize: '11px' } },
    { field: 'dataset', headerName: '데이터셋', flex: 1 },
    { field: 'records', headerName: '레코드수', width: 100, type:'numericColumn' },
    { field: 'quality', headerName: '품질점수', width: 80, cellRenderer: function(p) {
      var v = parseFloat(p.value);
      var c = v >= 90 ? '#389e0d' : v >= 85 ? '#d48806' : '#cf1322';
      return '<span style="color:'+c+';font-weight:700;">'+p.value+'</span>';
    }},
    { field: 'lastUpdate', headerName: '최종갱신', width: 90 },
    { field: 'status', headerName: '상태', width: 70, cellRenderer: function(p) {
      var st = {'활성':{bg:'#f6ffed',c:'#389e0d',dot:'#52c41a'},'비활성':{bg:'#f5f5f5',c:'#999',dot:'#bbb'},'점검중':{bg:'#fff7e6',c:'#d48806',dot:'#faad14'}};
      var s = st[p.value]||{bg:'#f5f5f5',c:'#666',dot:'#999'};
      return '<span style="display:inline-flex;align-items:center;gap:4px;background:'+s.bg+';color:'+s.c+';padding:2px 8px;border-radius:4px;font-size:11px;font-weight:600;"><span style="width:6px;height:6px;background:'+s.dot+';border-radius:50%;"></span>'+p.value+'</span>';
    }}
  ], [
    { facility:'소양강댐', type:'댐', system:'RWIS', dataset:'수위관측 시계열', records:'1,234,567', quality:'94.2%', lastUpdate:'11:45:02', status:'활성' },
    { facility:'소양강댐', type:'댐', system:'RWIS', dataset:'유량관측 데이터', records:'987,654', quality:'92.8%', lastUpdate:'11:45:01', status:'활성' },
    { facility:'소양강댐', type:'댐', system:'기상청API', dataset:'기상관측 데이터', records:'365,000', quality:'91.5%', lastUpdate:'11:30:00', status:'활성' },
    { facility:'소양강댐', type:'댐', system:'HDAPS', dataset:'발전량 통계', records:'23,456', quality:'97.1%', lastUpdate:'11:44:50', status:'활성' },
    { facility:'충주댐', type:'댐', system:'RWIS', dataset:'수위관측 시계열', records:'1,102,340', quality:'93.5%', lastUpdate:'11:45:00', status:'활성' },
    { facility:'세종보', type:'보', system:'SCADA', dataset:'수문 개도율', records:'456,789', quality:'89.3%', lastUpdate:'11:42:15', status:'점검중' },
    { facility:'구미정수장', type:'정수장', system:'IoT센서', dataset:'수질측정 자동화', records:'2,340,120', quality:'88.1%', lastUpdate:'11:44:30', status:'활성' },
    { facility:'낙동강하천', type:'하천', system:'RWIS', dataset:'방류량 관측', records:'678,900', quality:'84.7%', lastUpdate:'09:00:00', status:'비활성' }
  ], {
    domLayout: 'autoHeight',
    getRowStyle: function(p) {
      if (p.data.status === '비활성') return { background: '#fafafa' };
      if (p.data.status === '점검중') return { background: '#fffbe6' };
    }
  });

  // 데이터 리니지 노드 상세 (cat-lineage)
  initAGGrid('ag-grid-cat-lineage', [
    { field: 'stage', headerName: '단계', width: 90, cellRenderer: function(p) {
      var m = {'SOURCE':{bg:'#e6f7ff',c:'#0958d9'},'INGESTION':{bg:'#f6ffed',c:'#389e0d'},'TRANSFORM':{bg:'#fff7e6',c:'#d48806'},'SERVING':{bg:'#f9f0ff',c:'#722ed1'}};
      var s = m[p.value]||{bg:'#f5f5f5',c:'#666'};
      return '<span style="background:'+s.bg+';color:'+s.c+';padding:1px 8px;border-radius:4px;font-size:11px;font-weight:600;">'+p.value+'</span>';
    }},
    { field: 'node', headerName: '노드명', width: 140, cellRenderer: function(p) { return '<strong>' + p.value + '</strong>'; }},
    { field: 'type', headerName: '유형', width: 60, cellStyle: { fontSize: '11px', color: '#8c8c8c' } },
    { field: 'desc', headerName: '설명', flex: 1 },
    { field: 'owner', headerName: '담당자', width: 120 },
    { field: 'records', headerName: '데이터량', width: 100, type:'numericColumn' },
    { field: 'quality', headerName: '품질', width: 60, cellRenderer: function(p) {
      var v = parseFloat(p.value);
      var c = v >= 90 ? '#389e0d' : v >= 85 ? '#d48806' : '#cf1322';
      return '<span style="color:'+c+';font-weight:700;">'+p.value+'</span>';
    }},
    { field: 'latency', headerName: '지연', width: 70, cellRenderer: function(p) {
      var v = parseFloat(p.value);
      var c = v <= 10 ? '#389e0d' : v <= 60 ? '#d48806' : '#cf1322';
      return '<span style="color:'+c+';font-weight:600;">'+p.value+'</span>';
    }},
    { field: 'status', headerName: '상태', width: 80, cellRenderer: function(p) {
      var st = {'정상':{bg:'#f6ffed',c:'#389e0d',dot:'#52c41a'},'지연':{bg:'#fff7e6',c:'#d48806',dot:'#faad14'},'오류':{bg:'#fff1f0',c:'#cf1322',dot:'#ff4d4f'},'대기':{bg:'#e6f7ff',c:'#0958d9',dot:'#1677ff'}};
      var s = st[p.value]||{bg:'#f5f5f5',c:'#666',dot:'#999'};
      return '<span style="display:inline-flex;align-items:center;gap:4px;background:'+s.bg+';color:'+s.c+';padding:2px 8px;border-radius:4px;font-size:11px;font-weight:600;"><span style="width:6px;height:6px;background:'+s.dot+';border-radius:50%;"></span>'+p.value+'</span>';
    }}
  ], [
    { stage:'SOURCE', node:'RWIS 수위센서', type:'FA', desc:'IoT 센서 (FA망) · 수집주기 1분', owner:'원격계측팀 박수원', records:'1,234,567', quality:'96.8%', latency:'0.5s', status:'정상' },
    { stage:'SOURCE', node:'기상청 API', type:'EXT', desc:'공공데이터포털 날씨 API · 1시간', owner:'데이터융합팀 김철수', records:'365,000', quality:'95.1%', latency:'2.1s', status:'지연' },
    { stage:'INGESTION', node:'CDC 수집엔진', type:'APP', desc:'실시간 변경 데이터 캡처 · 1.2k/sec', owner:'플랫폼운영팀 이영희', records:'1,198,000', quality:'95.2%', latency:'8s', status:'정상' },
    { stage:'TRANSFORM', node:'stg_rwis_level', type:'SQL', desc:'Staging Layer · 정제 및 타입캐스팅', owner:'데이터스튜어드 최민수', records:'1,195,000', quality:'95.0%', latency:'1.2s', status:'정상' },
    { stage:'TRANSFORM', node:'fct_water_report', type:'SQL', desc:'Mart Layer · 일별 리포트 집계', owner:'데이터스튜어드 최민수', records:'24,000', quality:'94.8%', latency:'4.1s', status:'정상' },
    { stage:'SERVING', node:'수위현황 대시보드', type:'VIZ', desc:'통합 대시보드 위젯 · 활성 사용자 124명', owner:'부서관리자 홍길동', records:'N/A', quality:'94.2%', latency:'< 1s', status:'정상' },
    { stage:'SERVING', node:'Water Level API', type:'API', desc:'대내외 Open API · 호출 45K/일', owner:'시스템관리자 정공단', records:'45,210', quality:'94.2%', latency:'15ms', status:'정상' }
  ], {
    domLayout: 'autoHeight',
    getRowStyle: function(p) {
      if (p.data.status === '오류') return { background: '#fff5f5' };
      if (p.data.status === '지연') return { background: '#fffbe6' };
    }
  });

  // 데이터 미리보기 (cat-data-view)
  initAGGrid('ag-grid-cat-dataview', [
    { field: 'id', headerName: 'ID', width: 70, cellRenderer: function(p) { return '<span style="font-family:monospace;font-size:11px;color:#8c8c8c;">' + p.value + '</span>'; }},
    { field: 'stn', headerName: '관측소', width: 120, cellRenderer: function(p) { return '<strong>' + p.value + '</strong>'; }},
    { field: 'dt', headerName: '측정시간', width: 145, cellRenderer: function(p) { return '<span style="font-family:monospace;font-size:11px;">' + p.value + '</span>'; }},
    { field: 'level', headerName: '수위(m)', width: 90, type:'numericColumn', cellRenderer: function(p) {
      var v = parseFloat(p.value); var c = v >= 15 ? '#f5222d' : v >= 12 ? '#fa8c16' : '#52c41a';
      return '<span style="font-weight:700;color:' + c + ';">' + p.value + '</span>';
    }},
    { field: 'flow', headerName: '유량(㎥/s)', width: 100, type:'numericColumn', cellRenderer: function(p) { return '<span style="font-weight:600;">' + p.value + '</span>'; }},
    { field: 'threshold', headerName: '임계치(m)', width: 90, type:'numericColumn' },
    { field: 'quality', headerName: '품질플래그', width: 95, cellRenderer: function(p) {
      var q = { 'GOOD':{ bg:'#f6ffed', c:'#389e0d' }, 'SUSPECT':{ bg:'#fffbe6', c:'#d48806' }, 'MISSING':{ bg:'#fff1f0', c:'#cf1322' }, 'VALID':{ bg:'#e6f7ff', c:'#1677ff' } };
      var s = q[p.value] || { bg:'#f5f5f5', c:'#666' };
      return '<span style="background:' + s.bg + ';color:' + s.c + ';padding:1px 8px;border-radius:4px;font-size:11px;font-weight:600;">' + p.value + '</span>';
    }},
    { field: 'status', headerName: '상태', width: 80, cellRenderer: function(p) {
      var s = { '정상':{ bg:'#f6ffed', c:'#389e0d', dot:'#52c41a' }, '주의':{ bg:'#fffbe6', c:'#d48806', dot:'#faad14' }, '경보':{ bg:'#fff1f0', c:'#cf1322', dot:'#ff4d4f' } };
      var st = s[p.value] || s['정상'];
      return '<span style="display:inline-flex;align-items:center;gap:4px;background:' + st.bg + ';color:' + st.c + ';padding:2px 8px;border-radius:4px;font-size:11px;font-weight:600;"><span style="width:6px;height:6px;background:' + st.dot + ';border-radius:50%;"></span>' + p.value + '</span>';
    }}
  ], [
    { id:'WL-0001', stn:'소양강댐', dt:'2026-02-28 11:00:00', level:'11.45', flow:'142.3', threshold:'15.0', quality:'GOOD', status:'정상' },
    { id:'WL-0002', stn:'소양강댐', dt:'2026-02-28 11:01:00', level:'11.48', flow:'143.1', threshold:'15.0', quality:'GOOD', status:'정상' },
    { id:'WL-0003', stn:'충주댐', dt:'2026-02-28 11:00:00', level:'13.82', flow:'285.7', threshold:'15.0', quality:'SUSPECT', status:'주의' },
    { id:'WL-0004', stn:'충주댐', dt:'2026-02-28 11:01:00', level:'13.91', flow:'288.2', threshold:'15.0', quality:'SUSPECT', status:'주의' },
    { id:'WL-0005', stn:'합천댐', dt:'2026-02-28 11:00:00', level:'9.23', flow:'87.4', threshold:'14.0', quality:'GOOD', status:'정상' },
    { id:'WL-0006', stn:'안동댐', dt:'2026-02-28 11:00:00', level:'15.21', flow:'412.6', threshold:'15.0', quality:'VALID', status:'경보' },
    { id:'WL-0007', stn:'대청댐', dt:'2026-02-28 11:00:00', level:'10.77', flow:'156.8', threshold:'14.5', quality:'GOOD', status:'정상' },
    { id:'WL-0008', stn:'임하댐', dt:'2026-02-28 11:00:00', level:'8.95', flow:'63.2', threshold:'13.0', quality:'GOOD', status:'정상' },
    { id:'WL-0009', stn:'횡성댐', dt:'2026-02-28 11:00:00', level:'14.67', flow:'198.5', threshold:'15.0', quality:'SUSPECT', status:'주의' },
    { id:'WL-0010', stn:'밀양댐', dt:'2026-02-28 11:00:00', level:'', flow:'', threshold:'13.5', quality:'MISSING', status:'정상' }
  ], {
    domLayout: 'autoHeight',
    getRowStyle: function(p) {
      if (p.data.status === '경보') return { background: '#fff5f5' };
      if (p.data.status === '주의') return { background: '#fffbe6' };
    }
  });
}

function initCollectGrids() {
  // 파이프라인 관리 (col-pipeline)
  initAGGrid('ag-grid-col-pipeline', [
    { field: 'name', headerName: '파이프라인명', flex: 1, cellRenderer: function (p) { return '<strong>' + p.value + '</strong>'; } },
    { field: 'source', headerName: '원본시스템', width: 115 },
    {
      field: 'method', headerName: '수집방식', width: 105, cellRenderer: function (p) {
        var m = { '배치(ETL)': { bg: '#e8f0fe', c: '#1967d2' }, '실시간(CDC)': { bg: '#e8f5e9', c: '#2e7d32' }, 'API 호출': { bg: '#fce4ec', c: '#c62828' }, '스트리밍': { bg: '#e6f7ff', c: '#1677ff' } };
        var s = m[p.value] || { bg: '#f5f5f5', c: '#666' };
        return '<span style="background:' + s.bg + ';color:' + s.c + ';padding:1px 8px;border-radius:4px;font-size:11px;">' + p.value + '</span>';
      }
    },
    { field: 'schedule', headerName: '스케줄', width: 84 },
    {
      field: 'status', headerName: '상태', width: 70, cellRenderer: function (p) {
        var c = { '정상': '#4caf50', '지연': '#ff9800', '오류': '#f44336' };
        return '<span style="display:inline-flex;align-items:center;gap:4px;font-size:11px;"><span style="width:6px;height:6px;border-radius:50%;background:' + (c[p.value] || '#999') + ';display:inline-block;"></span>' + p.value + '</span>';
      }
    },
    { field: 'throughput', headerName: '처리량', width: 84 },
    { field: 'pii', headerName: 'PII', width: 70, cellRenderer: function (p) {
        if (!p.value || p.value === '-') return '<span style="color:#ccc; font-size:11px;">—</span>';
        return '<span style="background:#fff1f0; color:#cf1322; padding:1px 6px; border-radius:3px; font-size:10px; font-weight:600;">🔒 ' + p.value + '</span>';
      }
    },
    { field: 'lastRun', headerName: '최근실행', width: 96 },
    { field: 'action', headerName: '관리', width: 70, sortable: false, filter: false, cellRenderer: function () { return '<button class="btn btn-outline" style="padding:1px 6px;font-size:11px;">상세</button>'; } }
  ], [
    { name: 'SAP 재무수집', source: 'SAP HANA', method: '배치(ETL)', schedule: '매일 06:00', status: '정상', throughput: '48.2K/일', pii: '-', lastRun: '06:02:15' },
    { name: 'RWIS 실시간수위', source: 'RWIS DB (FA)', method: '실시간(CDC)', schedule: '상시', status: '정상', throughput: '12K/분', pii: '-', lastRun: '실시간' },
    { name: '환경부수질연계', source: '환경부 API', method: 'API 호출', schedule: '매30분', status: '정상', throughput: '2.4K/회', pii: '-', lastRun: '11:30:00' },
    { name: '스마트미터 검침', source: '계측 DB', method: '실시간(CDC)', schedule: '상시', status: '지연', throughput: '28K/분', pii: '3컬럼', lastRun: '11:41:22' },
    { name: 'Oracle 인사데이터', source: 'Oracle ERP', method: '배치(ETL)', schedule: '매일 02:00', status: '정상', throughput: '8.7K/일', pii: '4컬럼', lastRun: '02:05:33' },
    { name: 'GIS 공간정보 수집', source: 'arcGIS Server', method: '배치(ETL)', schedule: '매주월', status: '정상', throughput: '1.2K/회', pii: '-', lastRun: '월 03:00' },
    { name: '기상청날씨 API', source: '기상청 API', method: 'API 호출', schedule: '매시간', status: '오류', throughput: '0/회', pii: '-', lastRun: '09:00:00' }
  ], {
    getRowStyle: function (p) {
      if (p.data.status === '오류') return { background: '#fff5f5' };
      if (p.data.status === '지연') return { background: '#fffbe6' };
    }
  });

  // 수집현황 모니터링 - 원천시스템별 수집 상태 (col-monitor)
  initAGGrid('ag-grid-col-monitor', [
    { field: 'zone', headerName: '구간', width: 70, cellRenderer: function(p) {
      var z = {'FA':'#1677ff','OA':'#52c41a','DMZ':'#fa8c16','IoT':'#722ed1'};
      return '<span style="background:'+( z[p.value]||'#999')+';color:#fff;padding:1px 8px;border-radius:4px;font-size:10px;font-weight:600;">'+p.value+'</span>';
    }},
    { field: 'system', headerName: '원천시스템', flex: 1, cellRenderer: function(p) { return '<strong>'+p.value+'</strong>'; }},
    { field: 'db', headerName: '원천DB', width: 100 },
    { field: 'method', headerName: '수집방식', width: 90, cellRenderer: function(p) {
      var m = {'CDC':{bg:'#e8f5e9',c:'#2e7d32'},'스트리밍':{bg:'#e6f7ff',c:'#1677ff'},'API':{bg:'#fce4ec',c:'#c62828'},'배치':{bg:'#fff3e0',c:'#ef6c00'}};
      var s = m[p.value]||{bg:'#f5f5f5',c:'#666'};
      return '<span style="background:'+s.bg+';color:'+s.c+';padding:1px 8px;border-radius:4px;font-size:11px;">'+p.value+'</span>';
    }},
    { field: 'throughput', headerName: '처리량(/min)', width: 110, type:'numericColumn', cellRenderer: function(p) { return '<span style="font-weight:600;">'+p.value+'</span>'; }},
    { field: 'latency', headerName: 'Latency', width: 85 },
    { field: 'status', headerName: '상태', width: 80, cellRenderer: function(p) {
      var s = {'정상':{bg:'#f6ffed',c:'#389e0d',dot:'#52c41a'},'지연':{bg:'#fffbe6',c:'#d48806',dot:'#faad14'},'오류':{bg:'#fff1f0',c:'#cf1322',dot:'#ff4d4f'}};
      var st = s[p.value]||s['정상'];
      return '<span style="display:inline-flex;align-items:center;gap:4px;background:'+st.bg+';color:'+st.c+';padding:2px 8px;border-radius:4px;font-size:11px;font-weight:600;"><span style="width:6px;height:6px;background:'+st.dot+';border-radius:50%;"></span>'+p.value+'</span>';
    }},
    { field: 'today', headerName: '금일 처리', width: 100, type:'numericColumn' },
    { field: 'lastSync', headerName: '최종 동기화', width: 100 }
  ], [
    { zone:'FA', system:'RWIS (수위관측)', db:'계측DB', method:'스트리밍', throughput:'8,420', latency:'0.3s', status:'정상', today:'4,850,000', lastSync:'11:45:02' },
    { zone:'FA', system:'HDAPS (댐관측)', db:'계측DB', method:'스트리밍', throughput:'5,230', latency:'0.5s', status:'정상', today:'3,120,000', lastSync:'11:45:01' },
    { zone:'FA', system:'GIOS (지하수)', db:'계측DB', method:'스트리밍', throughput:'2,100', latency:'0.4s', status:'정상', today:'1,240,000', lastSync:'11:45:03' },
    { zone:'OA', system:'자산DB (SAP HANA)', db:'자산DB', method:'CDC', throughput:'12,450', latency:'0.8s', status:'정상', today:'5,680,000', lastSync:'11:45:02' },
    { zone:'OA', system:'시설DB (SAP HANA)', db:'시설DB', method:'CDC', throughput:'8,900', latency:'1.1s', status:'정상', today:'4,120,000', lastSync:'11:45:01' },
    { zone:'OA', system:'수질DB (ORACLE)', db:'수질DB', method:'CDC', throughput:'4,200', latency:'2.3s', status:'지연', today:'1,890,000', lastSync:'11:42:15' },
    { zone:'OA', system:'운영통합DB (SAP)', db:'운영DB', method:'CDC', throughput:'6,800', latency:'0.5s', status:'정상', today:'3,450,000', lastSync:'11:45:03' },
    { zone:'OA', system:'관망DB (티베로)', db:'관망DB', method:'배치', throughput:'1,200', latency:'3.2s', status:'정상', today:'340,200', lastSync:'11:08:12' },
    { zone:'DMZ', system:'기상청 API', db:'기상DB', method:'API', throughput:'80', latency:'Timeout', status:'오류', today:'2,400', lastSync:'11:30:15' },
    { zone:'DMZ', system:'양방향전송 (환경부)', db:'수질DB', method:'배치', throughput:'450', latency:'5.1s', status:'지연', today:'86,000', lastSync:'11:40:00' },
    { zone:'IoT', system:'스마트미터 (광역)', db:'계측DB', method:'CDC', throughput:'3,800', latency:'1.2s', status:'정상', today:'1,680,000', lastSync:'11:44:55' },
    { zone:'IoT', system:'스마트미터 (지방)', db:'계측DB', method:'CDC', throughput:'1,450', latency:'1.5s', status:'정상', today:'720,000', lastSync:'11:44:50' }
  ], { domLayout: 'autoHeight' });

  // CDC 연계현황 - 원천DB별 동기화 상태 (col-cdc)
  initAGGrid('ag-grid-col-cdc', [
    { field: 'db', headerName: '원천DB', width: 100, cellRenderer: function(p) { return '<strong>' + p.value + '</strong>'; }},
    { field: 'dbms', headerName: 'DBMS', width: 95, cellRenderer: function(p) {
      var m = {'SAP HANA':{bg:'#e6f7ff',c:'#0958d9'},'ORACLE':{bg:'#fff1f0',c:'#cf1322'},'티베로':{bg:'#f6ffed',c:'#389e0d'}};
      var s = m[p.value]||{bg:'#f5f5f5',c:'#666'};
      return '<span style="background:'+s.bg+';color:'+s.c+';padding:1px 8px;border-radius:4px;font-size:11px;font-weight:600;">'+p.value+'</span>';
    }},
    { field: 'tables', headerName: '테이블수', width: 80, type:'numericColumn' },
    { field: 'connector', headerName: '커넥터', width: 85 },
    { field: 'eventsMin', headerName: 'Events/min', width: 100, type:'numericColumn', cellRenderer: function(p) { return '<span style="font-weight:600; font-family:monospace; font-size:12px;">' + p.value + '</span>'; }},
    { field: 'lag', headerName: 'Lag', width: 70, cellRenderer: function(p) {
      var v = parseFloat(p.value);
      var c = v >= 2.0 ? '#ff4d4f' : v >= 1.5 ? '#fa8c16' : '#52c41a';
      return '<span style="color:'+c+';font-weight:700;">'+p.value+'</span>';
    }},
    { field: 'status', headerName: '상태', width: 80, cellRenderer: function(p) {
      var s = {'정상':{bg:'#f6ffed',c:'#389e0d',dot:'#52c41a'},'지연':{bg:'#fffbe6',c:'#d48806',dot:'#faad14'},'오류':{bg:'#fff1f0',c:'#cf1322',dot:'#ff4d4f'}};
      var st = s[p.value]||s['정상'];
      return '<span style="display:inline-flex;align-items:center;gap:4px;background:'+st.bg+';color:'+st.c+';padding:2px 8px;border-radius:4px;font-size:11px;font-weight:600;"><span style="width:6px;height:6px;background:'+st.dot+';border-radius:50%;"></span>'+p.value+'</span>';
    }},
    { field: 'today', headerName: '금일 처리', width: 90, type:'numericColumn' },
    { field: 'lastSync', headerName: '최종동기화', width: 90 },
    { field: 'action', headerName: '관리', width: 60, sortable: false, filter: false, cellRenderer: function() { return '<button class="btn btn-outline" style="padding:1px 6px;font-size:11px;">상세</button>'; }}
  ], [
    { db:'자산DB', dbms:'SAP HANA', tables:24, connector:'cdc-sap-asset', eventsMin:'4,250', lag:'0.8s', status:'정상', today:'680,000', lastSync:'11:45:02' },
    { db:'시설DB', dbms:'SAP HANA', tables:31, connector:'cdc-sap-facil', eventsMin:'3,180', lag:'1.1s', status:'정상', today:'410,000', lastSync:'11:45:01' },
    { db:'수질DB', dbms:'ORACLE', tables:28, connector:'cdc-ora-water', eventsMin:'2,640', lag:'2.3s', status:'지연', today:'340,000', lastSync:'11:42:15' },
    { db:'운영DB', dbms:'SAP HANA', tables:42, connector:'cdc-sap-oper', eventsMin:'4,020', lag:'0.5s', status:'정상', today:'520,000', lastSync:'11:45:03' },
    { db:'관망통합DB', dbms:'ORACLE', tables:23, connector:'cdc-ora-pipe', eventsMin:'1,920', lag:'0.9s', status:'정상', today:'250,000', lastSync:'11:44:58' },
    { db:'수도요금DB', dbms:'SAP HANA', tables:18, connector:'cdc-sap-bill', eventsMin:'1,480', lag:'0.6s', status:'정상', today:'82,000', lastSync:'11:45:00' },
    { db:'인사DB', dbms:'ORACLE', tables:12, connector:'cdc-ora-hr', eventsMin:'620', lag:'0.4s', status:'정상', today:'38,000', lastSync:'11:44:55' },
    { db:'수위관측DB', dbms:'티베로', tables:8, connector:'cdc-tib-obs', eventsMin:'890', lag:'1.8s', status:'정상', today:'96,000', lastSync:'11:44:50' }
  ], {
    domLayout: 'autoHeight',
    getRowStyle: function(p) {
      if (p.data.status === '오류') return { background: '#fff5f5' };
      if (p.data.status === '지연') return { background: '#fffbe6' };
    }
  });

  // 외부연계 현황 (col-external)
  initAGGrid('ag-grid-col-external', [
    { field: 'system', headerName: '연계시스템', width: 120, cellRenderer: function(p) { return '<strong>' + p.value + '</strong>'; }},
    { field: 'org', headerName: '연계기관', width: 100 },
    { field: 'method', headerName: '방식', width: 90, cellRenderer: function(p) {
      var m = {'REST API':{bg:'#e6f7ff',c:'#0958d9'},'SFTP':{bg:'#f6ffed',c:'#389e0d'},'DB Link':{bg:'#fff7e6',c:'#d48806'},'양방향전송':{bg:'#f9f0ff',c:'#722ed1'},'파일전송':{bg:'#fff1f0',c:'#cf1322'}};
      var s = m[p.value]||{bg:'#f5f5f5',c:'#666'};
      return '<span style="background:'+s.bg+';color:'+s.c+';padding:1px 8px;border-radius:4px;font-size:11px;font-weight:600;">'+p.value+'</span>';
    }},
    { field: 'protocol', headerName: '프로토콜', width: 95 },
    { field: 'cycle', headerName: '주기', width: 70 },
    { field: 'status', headerName: '상태', width: 70, cellRenderer: function(p) {
      var st = {'정상':{bg:'#f6ffed',c:'#389e0d',dot:'#52c41a'},'오류':{bg:'#fff1f0',c:'#cf1322',dot:'#ff4d4f'},'지연':{bg:'#fffbe6',c:'#d48806',dot:'#faad14'},'중단':{bg:'#f5f5f5',c:'#999',dot:'#bbb'}};
      var s = st[p.value]||{bg:'#f5f5f5',c:'#666',dot:'#999'};
      return '<span style="display:inline-flex;align-items:center;gap:4px;background:'+s.bg+';color:'+s.c+';padding:2px 8px;border-radius:4px;font-size:11px;font-weight:600;"><span style="width:6px;height:6px;background:'+s.dot+';border-radius:50%;"></span>'+p.value+'</span>';
    }},
    { field: 'responseTime', headerName: '응답시간', width: 80, type:'numericColumn' },
    { field: 'todayCount', headerName: '금일수신', width: 85, type:'numericColumn' },
    { field: 'successRate', headerName: '성공률', width: 70, cellRenderer: function(p) {
      var v = parseFloat(p.value);
      var c = v >= 99 ? '#389e0d' : v >= 95 ? '#d48806' : '#cf1322';
      return '<span style="color:'+c+';font-weight:600;">'+p.value+'</span>';
    }},
    { field: 'lastSync', headerName: '최종연계', width: 90 },
    { field: 'action', headerName: '관리', width: 60, sortable: false, filter: false, cellRenderer: function() { return '<button class="btn btn-outline" style="padding:1px 6px;font-size:11px;">상세</button>'; }}
  ], [
    { system:'기상청 날씨API', org:'기상청', method:'REST API', protocol:'REST/HTTPS', cycle:'1시간', status:'정상', responseTime:'245ms', todayCount:'12,480', successRate:'99.8%', lastSync:'11:45:02' },
    { system:'수질측정 데이터', org:'환경부', method:'REST API', protocol:'REST/HTTPS', cycle:'3시간', status:'정상', responseTime:'380ms', todayCount:'4,120', successRate:'99.5%', lastSync:'11:30:00' },
    { system:'댐수위 관측', org:'수자원공사', method:'SFTP', protocol:'SFTP/SSH', cycle:'6시간', status:'정상', responseTime:'1.2s', todayCount:'1,840', successRate:'100%', lastSync:'06:15:00' },
    { system:'수질보정 데이터', org:'수자원공사', method:'DB Link', protocol:'JDBC/Oracle', cycle:'일 1회', status:'정상', responseTime:'520ms', todayCount:'860', successRate:'99.2%', lastSync:'03:00:00' },
    { system:'FA망 양방향전송', org:'내부(FA→OA)', method:'양방향전송', protocol:'TCP/Custom', cycle:'실시간', status:'정상', responseTime:'85ms', todayCount:'342,600', successRate:'99.9%', lastSync:'11:45:05' },
    { system:'티베로 보정데이터', org:'내부시스템', method:'DB Link', protocol:'JDBC/Tibero', cycle:'일 2회', status:'지연', responseTime:'1.8s', todayCount:'2,400', successRate:'97.3%', lastSync:'09:00:00' },
    { system:'arcGIS 공간정보', org:'내부시스템', method:'REST API', protocol:'REST/HTTPS', cycle:'일 1회', status:'정상', responseTime:'620ms', todayCount:'1,200', successRate:'99.1%', lastSync:'03:00:00' },
    { system:'IoT 센서 수집', org:'내부(IoT망)', method:'파일전송', protocol:'MQTT/SFTP', cycle:'5분', status:'정상', responseTime:'120ms', todayCount:'86,400', successRate:'99.6%', lastSync:'11:44:50' },
    { system:'한국환경공단', org:'환경공단', method:'REST API', protocol:'REST/HTTPS', cycle:'12시간', status:'오류', responseTime:'Timeout', todayCount:'0', successRate:'0%', lastSync:'09:00 실패' },
    { system:'기상위성 영상', org:'기상청', method:'SFTP', protocol:'SFTP/SSH', cycle:'3시간', status:'정상', responseTime:'2.1s', todayCount:'960', successRate:'98.8%', lastSync:'09:00:00' }
  ], {
    domLayout: 'autoHeight',
    getRowStyle: function(p) {
      if (p.data.status === '오류') return { background: '#fff5f5' };
      if (p.data.status === '지연') return { background: '#fffbe6' };
    }
  });

  // 대내외시스템 연계관리 (col-system)
  initAGGrid('ag-grid-col-system', [
    { field: 'name', headerName: '연계시스템', flex: 1, cellRenderer: function (p) { return '<strong>' + p.value + '</strong>'; } },
    { field: 'type', headerName: '구분', width: 75 },
    { field: 'method', headerName: '연계방식', width: 102 },
    { field: 'protocol', headerName: '프로토콜', width: 105 },
    {
      field: 'status', headerName: '상태', width: 70, cellRenderer: function (p) {
        var m = { '정상': '#4caf50', '오류': '#f44336', '진행중': '#1677ff' };
        return '<span style="display:inline-flex;align-items:center;gap:4px;font-size:11px;"><span style="width:6px;height:6px;border-radius:50%;background:' + (m[p.value] || '#999') + ';display:inline-block;"></span>' + p.value + '</span>';
      }
    },
    { field: 'lastSync', headerName: '최근동기화', width: 110 },
    { field: 'records', headerName: '레코드수', width: 96, type: 'numericColumn' },
    { field: 'action', headerName: '관리', width: 70, sortable: false, filter: false, cellRenderer: function () { return '<button class="btn btn-outline" style="padding:1px 6px;font-size:11px;" onclick="navigate(\'col-system-detail\')">상세</button>'; } }
  ], [
    { name: '환경부 (수질데이터)', type: '외부기관', method: 'API 연계', protocol: 'REST/HTTPS', status: '정상', lastSync: '11:30', records: '2.4K' },
    { name: '수자원공사 (댐수위)', type: '외부기관', method: 'SFTP 전송', protocol: 'SFTP/SSH', status: '정상', lastSync: '06:15', records: '1.8K' },
    { name: 'arcGIS (공간정보)', type: '내부시스템', method: 'DB Link', protocol: 'JDBC', status: '정상', lastSync: '03:00', records: '12K' },
    { name: 'FA망 RWIS (실시간)', type: '내부시스템', method: 'CDC', protocol: 'FA→OA 단방향', status: '정상', lastSync: '실시간', records: '342K' },
    { name: '기상청 (날씨 API)', type: '외부기관', method: 'API 연계', protocol: 'REST/HTTPS', status: '오류', lastSync: '09:00 실패', records: '0' },
    { name: 'FA망 DB 이전', type: '내부시스템', method: '마이그레이션', protocol: '벌크전송', status: '진행중', lastSync: '42% 완료', records: '1.2M' }
  ], {
    getRowStyle: function (p) {
      if (p.data.status === '오류') return { background: '#fff5f5' };
    }
  });

  // dbt 모델 목록 (col-dbt)
  initAGGrid('ag-grid-col-dbt', [
    {
      field: 'layer', headerName: '레이어', width: 90, cellRenderer: function (p) {
        var m = { 'staging': { bg: '#e8f0fe', c: '#1967d2' }, 'intermediate': { bg: '#fff3e0', c: '#ef6c00' }, 'mart': { bg: '#e8f5e9', c: '#2e7d32' } };
        var s = m[p.value] || { bg: '#f5f5f5', c: '#666' };
        return '<span style="background:' + s.bg + ';color:' + s.c + ';padding:1px 8px;border-radius:4px;font-size:11px;">' + p.value + '</span>';
      }
    },
    { field: 'model', headerName: '모델명', flex: 1, cellRenderer: function (p) { return '<strong>' + p.value + '</strong>'; } },
    { field: 'source', headerName: '소스', width: 85 },
    { field: 'rule', headerName: '정제·변환 규칙', flex: 1 },
    {
      field: 'status', headerName: '상태', width: 70, cellRenderer: function (p) {
        var c = { '성공': '#4caf50', '경고': '#ff9800', '실패': '#f44336' };
        return '<span style="display:inline-flex;align-items:center;gap:4px;font-size:11px;"><span style="width:6px;height:6px;border-radius:50%;background:' + (c[p.value] || '#999') + ';display:inline-block;"></span>' + p.value + '</span>';
      }
    },
    { field: 'time', headerName: '실행시간', width: 96 },
    { field: 'action', headerName: '관리', width: 70, sortable: false, filter: false, cellRenderer: function () { return '<button class="btn btn-outline" style="padding:1px 6px;font-size:11px;" onclick="navigate(\'col-dbt-detail\')">상세</button>'; } }
  ], [
    { layer: 'staging', model: 'stg_sap_journal', source: 'SAP HANA', rule: 'NULL 제거, 타입캐스팅', status: '성공', time: '1.2s' },
    { layer: 'staging', model: 'stg_rwis_water_level', source: 'RWIS DB', rule: '이상치 제거(3σ), 단위변환', status: '성공', time: '0.8s' },
    { layer: 'staging', model: 'stg_env_water_quality', source: '환경부 API', rule: 'NULL 보간, 코드→텍스트 변환', status: '성공', time: '1.5s' },
    { layer: 'intermediate', model: 'int_water_monitoring', source: 'stg_rwis + stg_env', rule: '수위+수질 조인, 관측소 매핑', status: '성공', time: '3.2s' },
    { layer: 'mart', model: 'fct_daily_water_report', source: 'int_water_monitoring', rule: '일별 집계, KPI 산출', status: '경고', time: '4.1s' },
    { layer: 'mart', model: 'fct_customer_billing', source: 'stg_sap + stg_meter', rule: '요금산정, 고객매핑', status: '성공', time: '2.8s' },
    { layer: 'mart', model: 'dim_observation_station', source: 'stg_rwis + GIS', rule: '좌표변환, 메타보강', status: '실패', time: 'ERR' }
  ], {
    getRowStyle: function (p) {
      if (p.data.status === '실패') return { background: '#fff5f5' };
      if (p.data.status === '경고') return { background: '#fffbe6' };
    }
  });

  // Kafka 토픽 목록 (col-kafka)
  initAGGrid('ag-grid-kafka-topics', [
    { field: 'name', headerName: '토픽명', flex: 1, cellRenderer: function (p) { return '<strong style="font-family:monospace; font-size:12px;">' + p.value + '</strong>'; } },
    { field: 'partitions', headerName: '파티션', width: 90, type: 'numericColumn' },
    { field: 'replication', headerName: '복제팩터', width: 102, type: 'numericColumn' },
    {
      field: 'inRate', headerName: 'In(msg/s)', width: 110, type: 'numericColumn',
      cellStyle: { color: '#1677ff', fontWeight: '600', fontFamily: 'monospace', fontSize: '12px' }
    },
    {
      field: 'outRate', headerName: 'Out(msg/s)', width: 115, type: 'numericColumn',
      cellStyle: { color: '#52c41a', fontWeight: '600', fontFamily: 'monospace', fontSize: '12px' }
    },
    {
      field: 'lag', headerName: 'Lag', width: 80, type: 'numericColumn',
      cellRenderer: function (p) {
        if (p.value >= 500) return '<span style="color:#f44336; font-weight:700;">' + p.value.toLocaleString() + '</span>';
        if (p.value >= 100) return '<span style="color:#fa8c16; font-weight:600;">' + p.value.toLocaleString() + '</span>';
        return '<span style="color:#4caf50;">' + p.value.toLocaleString() + '</span>';
      }
    },
    { field: 'retention', headerName: '보존기간', width: 102 },
    {
      field: 'status', headerName: '상태', width: 80, cellRenderer: function (p) {
        var m = { '정상': 'badge-success', '경고': 'badge-warning', '비활성': 'badge-ghost' };
        return '<span class="badge ' + (m[p.value] || 'badge-ghost') + '" style="font-size:11px;">' + p.value + '</span>';
      }
    },
    { field: 'action', headerName: '관리', width: 80, sortable: false, filter: false, cellRenderer: function () { return '<button class="btn btn-outline" style="padding:1px 6px;font-size:11px;">설정</button>'; } }
  ], [
    { name: 'rwis_water_level', partitions: 6, replication: 3, inRate: '3.2K', outRate: '3.2K', lag: 112, retention: '168h (7d)', status: '정상' },
    { name: 'hdaps_power_gen', partitions: 4, replication: 3, inRate: '2.8K', outRate: '2.8K', lag: 45, retention: '168h (7d)', status: '정상' },
    { name: 'smart_meter_read', partitions: 12, replication: 3, inRate: '5.0K', outRate: '4.7K', lag: 328, retention: '72h (3d)', status: '경고' },
    { name: 'env_water_quality', partitions: 4, replication: 3, inRate: '0.8K', outRate: '0.8K', lag: 78, retention: '336h (14d)', status: '정상' },
    { name: 'gios_groundwater', partitions: 4, replication: 3, inRate: '1.4K', outRate: '1.4K', lag: 12, retention: '168h (7d)', status: '정상' },
    { name: 'kwater_alert_event', partitions: 3, replication: 3, inRate: '0.2K', outRate: '0.2K', lag: 0, retention: '720h (30d)', status: '정상' },
    { name: 'cdc_sap_journal', partitions: 6, replication: 3, inRate: '1.2K', outRate: '0.9K', lag: 542, retention: '336h (14d)', status: '경고' },
    { name: 'iot_sensor_raw', partitions: 8, replication: 3, inRate: '4.8K', outRate: '4.6K', lag: 187, retention: '24h (1d)', status: '정상' }
  ], {
    getRowStyle: function (p) {
      if (p.data.lag >= 500) return { background: '#fff5f5' };
      if (p.data.lag >= 300) return { background: '#fffbe6' };
    }
  });

  // 아키텍처 서버 인벤토리 (col-arch)
  initAGGrid('ag-grid-arch-systems', [
    { field: 'name', headerName: '서버그룹', flex: 1, cellRenderer: function (p) { return '<a href="#" onclick="openArchModal(\'archDetailModal\');return false;" style="color:#1677ff;font-weight:600;text-decoration:none;">' + p.value + '</a>'; } },
    { field: 'layer', headerName: '계층', width: 150, cellRenderer: function (p) {
      var m = { '수집계': '#42a5f5', '분석계': '#ec407a', '온톨로지/메타데이터': '#5c6bc0', '연계': '#26a69a', '서비스/모니터링': '#7e57c2', '카프카': '#00acc1' };
      return '<span style="color:' + (m[p.value] || '#666') + '; font-weight:600;">' + p.value + '</span>';
    }},
    { field: 'type', headerName: '유형', width: 80, cellRenderer: function (p) {
      var m = { 'K8S': { bg: '#e3f2fd', c: '#1565c0', bdr: '#2196f3' }, 'VM': { bg: '#e3f2fd', c: '#1565c0', bdr: '' }, 'PM': { bg: '#f3e5f5', c: '#7b1fa2', bdr: '' }, 'GPU': { bg: '#fff3e0', c: '#e65100', bdr: '' } };
      var s = m[p.value] || { bg: '#f5f5f5', c: '#666', bdr: '' };
      return '<span style="background:' + s.bg + ';color:' + s.c + ';padding:2px 10px;border-radius:4px;font-size:11px;font-weight:600;' + (s.bdr ? 'border:1px solid ' + s.bdr + ';' : '') + '">' + p.value + '</span>';
    }},
    { field: 'instances', headerName: '인스턴스', width: 102, type: 'numericColumn' },
    { field: 'cpu', headerName: 'CPU', width: 90 },
    { field: 'mem', headerName: '메모리', width: 90 },
    { field: 'disk', headerName: '디스크', width: 160 },
    { field: 'gpu', headerName: 'GPU', width: 90 },
    { field: 'status', headerName: '상태', width: 80, cellRenderer: function (p) {
      var m = { '정상': 'badge-success', '점검': 'badge-warning', '중단': 'badge-error' };
      return '<span class="badge ' + (m[p.value] || 'badge-ghost') + '" style="font-size:11px;">' + p.value + '</span>';
    }},
    { field: 'action', headerName: '관리', width: 80, sortable: false, filter: false, cellRenderer: function () { return '<button class="btn btn-outline" style="padding:1px 6px;font-size:11px;" onclick="openArchModal(\'archDetailModal\')">상세</button>'; } }
  ], [
    { name: 'Portal Server', layer: '서비스/모니터링', type: 'VM', instances: '8대', cpu: '4 Core', mem: '8GB', disk: 'SSD', gpu: '-', status: '정상' },
    { name: 'Platform Server', layer: '서비스/모니터링', type: 'K8S', instances: '-', cpu: 'Auto', mem: 'Auto', disk: 'PVC', gpu: '-', status: '정상' },
    { name: '모니터링서버', layer: '서비스/모니터링', type: 'VM', instances: '4대', cpu: '4 Core', mem: '8GB', disk: 'SSD', gpu: '-', status: '정상' },
    { name: 'Analysis Server', layer: '분석/AI', type: 'GPU', instances: '1대', cpu: '64 Core', mem: '1TB', disk: '3x30TB NVMe + 3x30TB SSD', gpu: 'B300', status: '정상' },
    { name: 'Ontology Server', layer: '분석/AI', type: 'K8S', instances: '-', cpu: 'Auto', mem: 'Auto', disk: 'PVC', gpu: '-', status: '정상' },
    { name: 'Analysis DB', layer: '분석/AI', type: 'PM', instances: '4대', cpu: '64 Core', mem: '1TB', disk: '3x30TB NVMe + 3x30TB SSD', gpu: '-', status: '정상' },
    { name: 'ODS DB', layer: '분석/AI', type: 'PM', instances: '3대', cpu: '64 Core', mem: '1TB', disk: '3x30TB NVMe + 3x30TB SSD', gpu: '-', status: '정상' },
    { name: '마인즈DB', layer: '분석/AI', type: 'VM', instances: '4대', cpu: '4 Core', mem: '8GB', disk: 'SSD', gpu: '-', status: '정상' },
    { name: '그래프DB', layer: '분석/AI', type: 'PM', instances: '1대', cpu: '64 Core', mem: '1TB', disk: '3x30TB NVMe + 3x30TB SSD', gpu: '-', status: '정상' },
    { name: 'Integration Server', layer: '연계', type: 'VM', instances: '8대', cpu: '4 Core', mem: '8GB', disk: 'SSD', gpu: '-', status: '정상' },
    { name: 'Agent Server', layer: '수집계', type: 'K8S', instances: '-', cpu: 'Auto', mem: 'Auto', disk: 'PVC', gpu: '-', status: '정상' },
    { name: 'Collection DB', layer: '수집계', type: 'PM', instances: '3대', cpu: '64 Core', mem: '1TB', disk: '3x30TB NVMe + 3x30TB SSD', gpu: '-', status: '정상' },
    { name: 'CDC Server', layer: '수집계', type: 'VM', instances: '4대', cpu: '4 Core', mem: '8GB', disk: 'SSD', gpu: '-', status: '점검' },
    { name: 'ETL Server', layer: '수집계', type: 'VM', instances: '4대', cpu: '4 Core', mem: '8GB', disk: 'SSD', gpu: '-', status: '정상' },
    { name: '프로듀서', layer: '수집계', type: 'VM', instances: '4대', cpu: '4 Core', mem: '8GB', disk: 'SSD', gpu: '-', status: '정상' },
    { name: 'Data Highway', layer: '수집계', type: 'PM', instances: '6대', cpu: '64 Core', mem: '1TB', disk: '3x30TB NVMe + 3x30TB SSD', gpu: '-', status: '정상' }
  ], {
    getRowStyle: function (p) {
      if (p.data.type === 'GPU') return { background: '#fff8e1' };
      if (p.data.type === 'K8S') return { background: '#e8f4fd' };
      if (p.data.type === 'PM') return { background: '#faf5ff' };
      if (p.data.status === '점검') return { background: '#fffbe6' };
    }
  });
}

function initDistributeGrids() {
  // Data Product 목록 (dist-product)
  initAGGrid('ag-grid-dist-product', [
    { field: 'name', headerName: 'Data Product', flex: 1, cellRenderer: function (p) { return '<strong>' + p.value + '</strong>'; } },
    { field: 'domain', headerName: '도메인', width: 90 },
    { field: 'format', headerName: '포맷', width: 85 },
    {
      field: 'grade', headerName: '등급', width: 70, cellRenderer: function (p) {
        if (p.value === '1등급') return '<span style="color:#c62828;font-weight:600;">' + p.value + '</span>';
        return p.value;
      }
    },
    {
      field: 'status', headerName: '유통상태', width: 96, cellRenderer: function (p) {
        var m = { '활성': { bg: '#e8f5e9', c: '#2e7d32' }, '준비중': { bg: '#fff7e6', c: '#d48806' }, '제한': { bg: '#ffebee', c: '#c62828' } };
        var s = m[p.value] || { bg: '#f5f5f5', c: '#666' };
        return '<span style="background:' + s.bg + ';color:' + s.c + ';padding:2px 8px;border-radius:4px;font-size:11px;">' + p.value + '</span>';
      }
    },
    { field: 'api', headerName: 'API', width: 80 },
    { field: 'deident', headerName: '비식별', width: 90, cellRenderer: function (p) {
        if (!p.value || p.value === '-') return '<span style="color:#ccc; font-size:11px;">—</span>';
        var m = { '적용':'#2e7d32', '부분':'#ef6c00', '미적용':'#cf1322' };
        var bg = { '적용':'#e8f5e9', '부분':'#fff3e0', '미적용':'#fff1f0' };
        return '<span style="background:'+(bg[p.value]||'#f5f5f5')+';color:'+(m[p.value]||'#666')+';padding:2px 8px;border-radius:4px;font-size:11px;font-weight:600;">'+p.value+'</span>';
      }
    },
    { field: 'dailyCalls', headerName: '일간호출', width: 96 },
    { field: 'lastUpdate', headerName: '최종갱신', width: 96 },
    { field: 'action', headerName: '관리', width: 70, sortable: false, filter: false, cellRenderer: function () { return '<button class="btn btn-outline" style="padding:1px 6px;font-size:11px;" onclick="navigate(\'dist-detail\')">상세</button>'; } }
  ], [
    { name: '광역상수도 유량실시간', domain: '상수도', format: 'JSON/CSV', grade: '2등급', status: '활성', api: 'REST', deident: '-', dailyCalls: '12.4K', lastUpdate: '실시간' },
    { name: '수력발전 일간통계', domain: '에너지', format: 'CSV/엑셀', grade: '2등급', status: '활성', api: 'REST', deident: '-', dailyCalls: '3.2K', lastUpdate: '매일 06시' },
    { name: '원격검침 사용량분석', domain: '고객', format: 'JSON', grade: '3등급', status: '활성', api: 'Kafka', deident: '적용', dailyCalls: '892K', lastUpdate: '실시간' },
    { name: '정수장운영실적', domain: '정수', format: 'CSV/엑셀', grade: '2등급', status: '준비중', api: '-', deident: '-', dailyCalls: '-', lastUpdate: '준비중' },
    { name: 'IoT 센서원시데이터', domain: '계측', format: 'Parquet', grade: '1등급', status: '제한', api: '내부전용', deident: '부분', dailyCalls: '내부', lastUpdate: '실시간' },
    { name: '수질측정데이터 (환경부)', domain: '수질', format: 'JSON/CSV', grade: '2등급', status: '활성', api: 'REST', deident: '적용', dailyCalls: '5.8K', lastUpdate: '30분주기' },
    { name: '댐수위·방류량종합', domain: '수자원', format: 'JSON', grade: '2등급', status: '활성', api: 'REST/Kafka', deident: '-', dailyCalls: '18.7K', lastUpdate: '실시간' }
  ]);

  // 비식별화 정책 (dist-deidentify) — 10컬럼×10행
  initAGGrid('ag-grid-dist-deidentify', [
    { field: 'name', headerName: '정책명', flex: 1, minWidth: 160, cellRenderer: function(p) { return '<a href="#" onclick="navigate(\'dist-deidentify-detail\');return false;" style="color:#1a1a2e;text-decoration:none;"><strong>'+p.value+'</strong></a>'; } },
    { field: 'target', headerName: '대상필드', width: 140 },
    { field: 'method', headerName: '처리기법', width: 110, cellRenderer: function(p) {
      var c = { '마스킹':'#1967d2', 'SHA-256 해싱':'#7b1fa2', '지역단위 일반화':'#00897b', '가명치환':'#ef6c00', 'AES-256 암호화':'#c62828', 'k-익명성':'#2e7d32', '라운딩':'#5c6bc0', '토큰화':'#00838f', '총계처리':'#6d4c41', '범주화':'#546e7a' };
      var cl = c[p.value] || '#666';
      return '<span style="color:'+cl+';font-weight:600;font-size:11px;">'+p.value+'</span>';
    }},
    { field: 'grade', headerName: '적용등급', width: 90, cellRenderer: function(p) {
      var m = { '1등급':{bg:'#fce4ec',c:'#c62828'}, '2등급':{bg:'#fff3e0',c:'#ef6c00'}, '3등급':{bg:'#e8f5e9',c:'#2e7d32'}, '전체':{bg:'#e8f0fe',c:'#1967d2'} };
      var s = m[p.value] || {bg:'#f5f5f5',c:'#666'};
      return '<span style="background:'+s.bg+';color:'+s.c+';padding:2px 8px;border-radius:4px;font-size:11px;font-weight:600;">'+p.value+'</span>';
    }},
    { field: 'deidentType', headerName: '비식별유형', width: 90, cellRenderer: function(p) {
      return '<span style="color:#555;font-size:11px;">'+p.value+'</span>';
    }},
    { field: 'totalCnt', headerName: '대상건수', width: 90, cellStyle: { textAlign:'right', fontFamily:'monospace', fontSize:'12px' } },
    { field: 'procCnt', headerName: '처리건수', width: 90, cellStyle: { textAlign:'right', fontFamily:'monospace', fontSize:'12px' } },
    { field: 'procRate', headerName: '처리율', width: 80, cellRenderer: function(p) {
      var v = parseFloat(p.value); var c = v >= 95 ? '#4caf50' : v >= 80 ? '#ff9800' : '#f44336';
      return '<span style="font-weight:600;color:'+c+';">'+p.value+'%</span>';
    }},
    { field: 'status', headerName: '상태', width: 80, cellRenderer: function(p) {
      var m = { '적용중':{bg:'#e8f5e9',c:'#2e7d32',d:'#52c41a'}, '검토중':{bg:'#fff7e6',c:'#d48806',d:'#faad14'}, '중지':{bg:'#fff1f0',c:'#cf1322',d:'#ff4d4f'} };
      var s = m[p.value] || {bg:'#f5f5f5',c:'#666',d:'#999'};
      return '<span style="display:inline-flex;align-items:center;gap:4px;background:'+s.bg+';color:'+s.c+';padding:2px 8px;border-radius:4px;font-size:11px;font-weight:600;"><span style="width:6px;height:6px;background:'+s.d+';border-radius:50%;"></span>'+p.value+'</span>';
    }},
    { field: 'action', headerName: '관리', width: 70, sortable: false, filter: false, cellRenderer: function() { return '<button class="btn btn-outline" style="padding:1px 6px;font-size:11px;" onclick="navigate(\'dist-deidentify-detail\')">상세</button>'; } }
  ], [
    { name: '고객개인정보 마스킹', target: '고객명, 전화번호, 주소', method: '마스킹', grade: '전체', deidentType: '가명처리', totalCnt: '1,245,000', procCnt: '1,245,000', procRate: '100.0', status: '적용중' },
    { name: '주민번호 가명처리', target: '주민등록번호', method: 'SHA-256 해싱', grade: '전체', deidentType: '가명처리', totalCnt: '892,400', procCnt: '892,400', procRate: '100.0', status: '적용중' },
    { name: '위치정보 일반화', target: 'GPS좌표, 주소', method: '지역단위 일반화', grade: '3등급', deidentType: '총계처리', totalCnt: '2,100,000', procCnt: '2,100,000', procRate: '100.0', status: '적용중' },
    { name: '이메일 치환처리', target: '이메일', method: '가명치환', grade: '전체', deidentType: '가명처리', totalCnt: '456,800', procCnt: '456,800', procRate: '100.0', status: '적용중' },
    { name: '금융정보 암호화', target: '계좌번호, 카드번호', method: 'AES-256 암호화', grade: '1등급', deidentType: '데이터삭제', totalCnt: '180,200', procCnt: '168,500', procRate: '93.5', status: '검토중' },
    { name: 'AI 학습용 데이터처리', target: '고객명, 위치', method: 'k-익명성', grade: '2등급', deidentType: '가명처리', totalCnt: '345,600', procCnt: '312,000', procRate: '90.3', status: '검토중' },
    { name: '수질측정 민감정보', target: '측정자ID, 위치', method: '토큰화', grade: '2등급', deidentType: '가명처리', totalCnt: '567,000', procCnt: '567,000', procRate: '100.0', status: '적용중' },
    { name: '인사정보 범주화', target: '직급, 급여구간', method: '범주화', grade: '1등급', deidentType: '총계처리', totalCnt: '5,200', procCnt: '5,200', procRate: '100.0', status: '적용중' },
    { name: 'IoT 센서 라운딩', target: '센서값, 좌표', method: '라운딩', grade: '3등급', deidentType: '데이터마스킹', totalCnt: '3,400,000', procCnt: '3,400,000', procRate: '100.0', status: '적용중' },
    { name: '외부제공 데이터셋', target: '전체 개인식별', method: 'k-익명성', grade: '전체', deidentType: '가명처리', totalCnt: '78,900', procCnt: '65,200', procRate: '82.6', status: '검토중' }
  ], {
    domLayout: 'autoHeight',
    getRowStyle: function(p) {
      if (p.data.status === '검토중') return { background: '#fffbe6' };
    }
  });
}

// ========== 003: 동적 ERD 렌더링 + 논리/물리 매핑 + 버전 비교 ==========
var MODEL_ERD_DATA = {
  '수자원관리_논리모델': {
    tables: [
      { name: '댐_기본정보', physName: 'TB_DAM_BASIC', color: '#1677ff', cols: [
        { name: '댐ID', type: 'VARCHAR(10)', pk: true }, { name: '댐명', type: 'VARCHAR(100)' },
        { name: '유역코드', type: 'VARCHAR(10)', fk: true, fkRef: '유역_정보.유역코드' }, { name: '준공년도', type: 'INTEGER' }, { name: '총저수량', type: 'DECIMAL(15,2)' }
      ]},
      { name: '수위_관측', physName: 'TB_WATER_LVL', color: '#1677ff', cols: [
        { name: '관측ID', type: 'BIGINT', pk: true }, { name: '댐ID', type: 'VARCHAR(10)', fk: true, fkRef: '댐_기본정보.댐ID' },
        { name: '관측일시', type: 'TIMESTAMP' }, { name: '수위', type: 'DECIMAL(8,3)' }, { name: '유입량', type: 'DECIMAL(12,2)' }
      ]},
      { name: '유역_정보', physName: 'TB_BASIN_INFO', color: '#52c41a', cols: [
        { name: '유역코드', type: 'VARCHAR(10)', pk: true }, { name: '유역명', type: 'VARCHAR(100)' },
        { name: '유역면적', type: 'DECIMAL(12,2)' }, { name: '관할지사', type: 'VARCHAR(50)' }
      ]},
      { name: '강우_관측', physName: 'TB_RAINFALL', color: '#1677ff', cols: [
        { name: '관측ID', type: 'BIGINT', pk: true }, { name: '유역코드', type: 'VARCHAR(10)', fk: true, fkRef: '유역_정보.유역코드' },
        { name: '관측일시', type: 'TIMESTAMP' }, { name: '강우량', type: 'DECIMAL(8,2)' }
      ]},
      { name: '방류_이력', physName: 'TB_DISCHARGE', color: '#fa8c16', cols: [
        { name: '방류ID', type: 'BIGINT', pk: true }, { name: '댐ID', type: 'VARCHAR(10)', fk: true, fkRef: '댐_기본정보.댐ID' },
        { name: '방류일시', type: 'TIMESTAMP' }, { name: '방류량', type: 'DECIMAL(12,2)' }, { name: '방류사유', type: 'VARCHAR(200)' }
      ]}
    ],
    relations: [
      { from: '수위_관측', fromCol: '댐ID', to: '댐_기본정보', toCol: '댐ID' },
      { from: '댐_기본정보', fromCol: '유역코드', to: '유역_정보', toCol: '유역코드' },
      { from: '강우_관측', fromCol: '유역코드', to: '유역_정보', toCol: '유역코드' },
      { from: '방류_이력', fromCol: '댐ID', to: '댐_기본정보', toCol: '댐ID' }
    ]
  },
  '수자원관리_물리모델': {
    tables: [
      { name: 'TB_DAM_BASIC', physName: 'TB_DAM_BASIC', color: '#fa8c16', cols: [
        { name: 'DAM_ID', type: 'VARCHAR(10)', pk: true }, { name: 'DAM_NM', type: 'VARCHAR(100)' },
        { name: 'BSN_CD', type: 'VARCHAR(10)', fk: true, fkRef: 'TB_BASIN_INFO.BSN_CD' }, { name: 'CMPL_YR', type: 'INTEGER' }, { name: 'TOT_STRG_QTY', type: 'DECIMAL(15,2)' }
      ]},
      { name: 'TB_WATER_LVL', physName: 'TB_WATER_LVL', color: '#fa8c16', cols: [
        { name: 'OBSRV_ID', type: 'BIGINT', pk: true }, { name: 'DAM_ID', type: 'VARCHAR(10)', fk: true, fkRef: 'TB_DAM_BASIC.DAM_ID' },
        { name: 'OBSRV_DT', type: 'TIMESTAMP' }, { name: 'WTR_LVL', type: 'DECIMAL(8,3)' }, { name: 'INFLW_QTY', type: 'DECIMAL(12,2)' }
      ]},
      { name: 'TB_BASIN_INFO', physName: 'TB_BASIN_INFO', color: '#52c41a', cols: [
        { name: 'BSN_CD', type: 'VARCHAR(10)', pk: true }, { name: 'BSN_NM', type: 'VARCHAR(100)' },
        { name: 'BSN_AREA', type: 'DECIMAL(12,2)' }, { name: 'JRSD_OFFC', type: 'VARCHAR(50)' }
      ]},
      { name: 'TB_RAINFALL', physName: 'TB_RAINFALL', color: '#fa8c16', cols: [
        { name: 'OBSRV_ID', type: 'BIGINT', pk: true }, { name: 'BSN_CD', type: 'VARCHAR(10)', fk: true, fkRef: 'TB_BASIN_INFO.BSN_CD' },
        { name: 'OBSRV_DT', type: 'TIMESTAMP' }, { name: 'RNFL_QTY', type: 'DECIMAL(8,2)' }
      ]},
      { name: 'TB_DISCHARGE', physName: 'TB_DISCHARGE', color: '#fa8c16', cols: [
        { name: 'DSCHRG_ID', type: 'BIGINT', pk: true }, { name: 'DAM_ID', type: 'VARCHAR(10)', fk: true, fkRef: 'TB_DAM_BASIC.DAM_ID' },
        { name: 'DSCHRG_DT', type: 'TIMESTAMP' }, { name: 'DSCHRG_QTY', type: 'DECIMAL(12,2)' }, { name: 'DSCHRG_RSN', type: 'VARCHAR(200)' }
      ]}
    ],
    relations: [
      { from: 'TB_WATER_LVL', fromCol: 'DAM_ID', to: 'TB_DAM_BASIC', toCol: 'DAM_ID' },
      { from: 'TB_DAM_BASIC', fromCol: 'BSN_CD', to: 'TB_BASIN_INFO', toCol: 'BSN_CD' },
      { from: 'TB_RAINFALL', fromCol: 'BSN_CD', to: 'TB_BASIN_INFO', toCol: 'BSN_CD' },
      { from: 'TB_DISCHARGE', fromCol: 'DAM_ID', to: 'TB_DAM_BASIC', toCol: 'DAM_ID' }
    ]
  },
  '상수도관리_논리모델': {
    tables: [
      { name: '관로_기본정보', physName: 'TB_PIPE_BASIC', color: '#1677ff', cols: [
        { name: '관로ID', type: 'VARCHAR(15)', pk: true }, { name: '관로명', type: 'VARCHAR(100)' },
        { name: '관경', type: 'DECIMAL(8,2)' }, { name: '관종', type: 'VARCHAR(20)' }, { name: '매설년도', type: 'INTEGER' }
      ]},
      { name: '수압_관측', physName: 'TB_PRESSURE', color: '#1677ff', cols: [
        { name: '관측ID', type: 'BIGINT', pk: true }, { name: '관로ID', type: 'VARCHAR(15)', fk: true, fkRef: '관로_기본정보.관로ID' },
        { name: '관측일시', type: 'TIMESTAMP' }, { name: '수압', type: 'DECIMAL(8,3)' }
      ]},
      { name: '밸브_정보', physName: 'TB_VALVE', color: '#52c41a', cols: [
        { name: '밸브ID', type: 'VARCHAR(15)', pk: true }, { name: '관로ID', type: 'VARCHAR(15)', fk: true, fkRef: '관로_기본정보.관로ID' },
        { name: '밸브종류', type: 'VARCHAR(20)' }, { name: '설치일', type: 'DATE' }
      ]}
    ],
    relations: [
      { from: '수압_관측', fromCol: '관로ID', to: '관로_기본정보', toCol: '관로ID' },
      { from: '밸브_정보', fromCol: '관로ID', to: '관로_기본정보', toCol: '관로ID' }
    ]
  }
};

function renderDynamicERD(containerId, modelName) {
  var container = document.getElementById(containerId);
  if (!container) return;
  var data = MODEL_ERD_DATA[modelName];
  if (!data) {
    container.innerHTML = '<div style="text-align:center;padding:40px;color:#888;">선택한 모델의 ERD 데이터가 없습니다.</div>';
    return;
  }
  // 레이아웃 계산: 3열 그리드 배치
  var tableWidth = 200;
  var tableGap = 40;
  var colCount = Math.min(3, data.tables.length);
  var positions = [];
  data.tables.forEach(function(t, i) {
    var col = i % colCount;
    var row = Math.floor(i / colCount);
    positions.push({ x: col * (tableWidth + tableGap) + 20, y: row * 220 + 20 });
  });
  var totalW = colCount * (tableWidth + tableGap) + 20;
  var totalH = (Math.ceil(data.tables.length / colCount)) * 220 + 40;

  var html = '<div style="position:relative; width:' + totalW + 'px; min-height:' + totalH + 'px;">';
  // SVG 관계선 오버레이
  html += '<svg class="erd-svg-overlay" style="position:absolute;top:0;left:0;width:100%;height:100%;pointer-events:none;z-index:1;">';
  html += '<defs><marker id="arrowhead-' + containerId + '" markerWidth="10" markerHeight="7" refX="10" refY="3.5" orient="auto"><polygon points="0 0, 10 3.5, 0 7" fill="#999"/></marker></defs>';
  // 관계선 렌더링
  data.relations.forEach(function(rel) {
    var fromIdx = -1, toIdx = -1;
    data.tables.forEach(function(t, i) { if (t.name === rel.from) fromIdx = i; if (t.name === rel.to) toIdx = i; });
    if (fromIdx < 0 || toIdx < 0) return;
    var fp = positions[fromIdx];
    var tp = positions[toIdx];
    // FK 컬럼 인덱스로 Y 오프셋 계산
    var fromColIdx = 0;
    data.tables[fromIdx].cols.forEach(function(c, ci) { if (c.name === rel.fromCol) fromColIdx = ci; });
    var toColIdx = 0;
    data.tables[toIdx].cols.forEach(function(c, ci) { if (c.name === rel.toCol) toColIdx = ci; });
    var x1 = fp.x + tableWidth;
    var y1 = fp.y + 36 + fromColIdx * 26 + 13;
    var x2 = tp.x;
    var y2 = tp.y + 36 + toColIdx * 26 + 13;
    // 같은 열이면 좌측으로 우회
    if (Math.abs(fp.x - tp.x) < 10) {
      x1 = fp.x;
      x2 = tp.x;
      html += '<path d="M' + x1 + ',' + y1 + ' C' + (x1 - 60) + ',' + y1 + ' ' + (x2 - 60) + ',' + y2 + ' ' + x2 + ',' + y2 + '" fill="none" stroke="#999" stroke-width="1.5" stroke-dasharray="4,3" marker-end="url(#arrowhead-' + containerId + ')"/>';
    } else {
      var midX = (x1 + x2) / 2;
      html += '<path d="M' + x1 + ',' + y1 + ' C' + midX + ',' + y1 + ' ' + midX + ',' + y2 + ' ' + x2 + ',' + y2 + '" fill="none" stroke="#999" stroke-width="1.5" stroke-dasharray="4,3" marker-end="url(#arrowhead-' + containerId + ')"/>';
    }
  });
  html += '</svg>';
  // 테이블 박스 렌더링
  data.tables.forEach(function(t, i) {
    var pos = positions[i];
    html += '<div class="erd-table" style="position:absolute;left:' + pos.x + 'px;top:' + pos.y + 'px;width:' + tableWidth + 'px;z-index:2;">';
    html += '<div class="erd-header" style="background:' + (t.color || '#1677ff') + ';">' + t.name + '</div>';
    html += '<div class="erd-cols">';
    t.cols.forEach(function(c) {
      html += '<div class="erd-col">';
      if (c.pk) html += '<span class="pk">PK</span>';
      else if (c.fk) html += '<span class="fk">FK</span>';
      else html += '<span style="display:inline-block;width:24px;"></span>';
      html += '<span style="flex:1;">' + c.name + '</span>';
      html += '<span style="color:#999;font-size:10px;">' + c.type + '</span>';
      html += '</div>';
    });
    html += '</div></div>';
  });
  html += '</div>';
  container.innerHTML = html;
}

function updateERDPreview(modelName) {
  var titleEl = document.getElementById('erd-preview-title');
  if (titleEl) titleEl.textContent = modelName;
  renderDynamicERD('erd-preview-container', modelName);
}

// 모델 상세 진입 시 ERD 렌더링
var currentDetailModel = '수자원관리_논리모델';
function openModelDetail(modelNameOrId) {
  // modelId (MDL-xxx) 형식이면 modelData에서 조회
  var model = null;
  if (typeof modelData !== 'undefined' && modelNameOrId && modelNameOrId.indexOf('MDL-') === 0) {
    model = modelData.find(function(d) { return d.id === modelNameOrId; });
    if (model) {
      selectedModelId = modelNameOrId;
      currentDetailModel = model.name;
    }
  }
  if (!model) {
    currentDetailModel = modelNameOrId || '수자원관리_논리모델';
  }
  navigate('meta-model-detail');
  setTimeout(function() {
    // 기존 동적 ERD 렌더링
    if (typeof renderDynamicERD === 'function') renderDynamicERD('erd-detail-container', currentDetailModel);
    if (typeof renderModelMapping === 'function') renderModelMapping(currentDetailModel);
    // 새 모델 상세 콘텐츠 렌더링
    if (model && typeof renderModelDetailContent === 'function') renderModelDetailContent(model);
  }, 100);
}

// ========== 논리/물리 매핑 ==========
var MODEL_MAPPING_DATA = {
  '수자원관리_논리모델': [
    { logical: '댐_기본정보', physical: 'TB_DAM_BASIC', status: 'full', matchRate: 100, diff: '-' },
    { logical: '수위_관측', physical: 'TB_WATER_LVL', status: 'full', matchRate: 100, diff: '-' },
    { logical: '유역_정보', physical: 'TB_BASIN_INFO', status: 'full', matchRate: 100, diff: '-' },
    { logical: '강우_관측', physical: 'TB_RAINFALL', status: 'partial', matchRate: 85, diff: '물리모델에 인덱스 컬럼 추가' },
    { logical: '방류_이력', physical: 'TB_DISCHARGE', status: 'full', matchRate: 100, diff: '-' }
  ]
};

function renderModelMapping(modelName) {
  var container = document.getElementById('model-mapping-container');
  if (!container) return;
  var data = MODEL_MAPPING_DATA[modelName] || MODEL_MAPPING_DATA['수자원관리_논리모델'];
  var html = '<table class="data-table"><thead><tr>';
  html += '<th>논리 엔티티명</th><th>물리 테이블명</th><th>매핑 상태</th><th>컬럼 일치율</th><th>차이점 요약</th>';
  html += '</tr></thead><tbody>';
  data.forEach(function(row) {
    var statusBadge = row.status === 'full'
      ? '<span class="badge badge-success" style="font-size:11px;">완전일치</span>'
      : row.status === 'partial'
        ? '<span class="badge badge-warning" style="font-size:11px;">부분일치</span>'
        : '<span class="badge badge-error" style="font-size:11px;">미매핑</span>';
    var rateColor = row.matchRate >= 95 ? '#2e7d32' : row.matchRate >= 80 ? '#f57c00' : '#c62828';
    html += '<tr>';
    html += '<td><strong>' + row.logical + '</strong></td>';
    html += '<td><code style="background:#f5f5f5;padding:2px 6px;border-radius:3px;font-size:12px;">' + row.physical + '</code></td>';
    html += '<td>' + statusBadge + '</td>';
    html += '<td style="text-align:center;"><span style="font-weight:700;color:' + rateColor + ';">' + row.matchRate + '%</span></td>';
    html += '<td style="font-size:12px;color:#666;">' + row.diff + '</td>';
    html += '</tr>';
  });
  html += '</tbody></table>';
  container.innerHTML = html;
}

// ========== 버전 비교 ==========
var MODEL_VERSION_DATA = {
  '수자원관리_논리모델': {
    versions: ['v3.1', 'v3.0', 'v2.5', 'v2.0'],
    diffs: {
      'v3.1_v3.0': [
        { type: 'add', entity: '방류_이력', detail: '신규 엔티티 추가' },
        { type: 'modify', entity: '수위_관측', detail: '유입량 컬럼 데이터타입 변경 (DECIMAL(10,2)→DECIMAL(12,2))' }
      ],
      'v3.0_v2.5': [
        { type: 'modify', entity: '댐_기본정보', detail: '총저수량 컬럼 추가' },
        { type: 'delete', entity: '임시_관측', detail: '불필요 엔티티 삭제' }
      ],
      'v2.5_v2.0': [
        { type: 'add', entity: '강우_관측', detail: '신규 엔티티 추가' },
        { type: 'modify', entity: '유역_정보', detail: '관할지사 컬럼 추가' },
        { type: 'modify', entity: '댐_기본정보', detail: '유역코드 FK 관계 추가' }
      ]
    }
  }
};

function openVersionCompareModal() {
  var modal = document.getElementById('version-compare-modal');
  if (!modal) return;
  modal.style.display = 'flex';
  var data = MODEL_VERSION_DATA[currentDetailModel] || MODEL_VERSION_DATA['수자원관리_논리모델'];
  var sel1 = document.getElementById('version-select-from');
  var sel2 = document.getElementById('version-select-to');
  if (sel1 && sel2) {
    sel1.innerHTML = '';
    sel2.innerHTML = '';
    data.versions.forEach(function(v, i) {
      sel1.innerHTML += '<option value="' + v + '"' + (i === 0 ? ' selected' : '') + '>' + v + '</option>';
      sel2.innerHTML += '<option value="' + v + '"' + (i === 1 ? ' selected' : '') + '>' + v + '</option>';
    });
  }
  compareModelVersions();
}

function compareModelVersions() {
  var sel1 = document.getElementById('version-select-from');
  var sel2 = document.getElementById('version-select-to');
  var resultEl = document.getElementById('version-diff-result');
  if (!sel1 || !sel2 || !resultEl) return;
  var v1 = sel1.value;
  var v2 = sel2.value;
  var data = MODEL_VERSION_DATA[currentDetailModel] || MODEL_VERSION_DATA['수자원관리_논리모델'];
  var diffKey = v1 + '_' + v2;
  var diffs = data.diffs[diffKey] || [];
  if (diffs.length === 0) {
    resultEl.innerHTML = '<div style="text-align:center;padding:30px;color:#888;">선택한 두 버전 간 차이가 없거나 비교 데이터가 없습니다.</div>';
    return;
  }
  var html = '<table class="data-table"><thead><tr><th style="width:80px;">변경유형</th><th style="width:150px;">엔티티</th><th>변경 내용</th></tr></thead><tbody>';
  diffs.forEach(function(d) {
    var typeStyle = '', typeLabel = '';
    if (d.type === 'add') { typeStyle = 'background:#e8f5e9;color:#2e7d32;'; typeLabel = '➕ 추가'; }
    else if (d.type === 'delete') { typeStyle = 'background:#ffebee;color:#c62828;'; typeLabel = '🗑️ 삭제'; }
    else { typeStyle = 'background:#fff8e1;color:#f57c00;'; typeLabel = '✏️ 변경'; }
    html += '<tr style="' + typeStyle + '">';
    html += '<td style="font-weight:600;">' + typeLabel + '</td>';
    html += '<td><strong>' + d.entity + '</strong></td>';
    html += '<td style="font-size:12px;">' + d.detail + '</td>';
    html += '</tr>';
  });
  html += '</tbody></table>';
  resultEl.innerHTML = html;
}

// ========== 004: 데이터 분류 관리 — 자동 분류 / 벌크 분류 / 승인 워크플로우 ==========
var AUTO_CLASSIFY_RESULTS = [
  { asset: 'TB_DAM_BASIC_INFO', currentDomain: '미분류', suggestDomain: '수자원', confidence: 95, rule: '수자원 도메인 자동분류', selected: true },
  { asset: 'TB_RIVER_FLOW_DATA', currentDomain: '미분류', suggestDomain: '수자원', confidence: 92, rule: '수자원 도메인 자동분류', selected: true },
  { asset: 'TB_PIPE_PRESSURE', currentDomain: '미분류', suggestDomain: '상수도', confidence: 88, rule: '상수도 도메인 분류', selected: true },
  { asset: 'TB_CUST_PERSONAL', currentDomain: '3등급', suggestDomain: '1등급', confidence: 98, rule: 'PII 보안등급 자동설정', selected: true },
  { asset: 'TB_ENERGY_PROD', currentDomain: '미분류', suggestDomain: '에너지', confidence: 85, rule: '키워드 기반 분류', selected: false },
  { asset: 'TB_VALVE_STATUS', currentDomain: '미분류', suggestDomain: '상수도', confidence: 78, rule: '상수도 도메인 분류', selected: false },
  { asset: 'TB_WATER_QUALITY_RAW', currentDomain: '미분류', suggestDomain: '수질', confidence: 91, rule: '키워드 기반 분류', selected: true },
  { asset: 'TB_SENSOR_CONFIG', currentDomain: '미분류', suggestDomain: '계측', confidence: 86, rule: '계측 업무영역 태그', selected: true }
];

function runAutoClassify() {
  var resultDiv = document.getElementById('auto-classify-result');
  if (!resultDiv) return;
  resultDiv.style.display = 'block';
  var colDefs = [
    { headerCheckboxSelection: true, checkboxSelection: true, width: 50, headerCheckboxSelectionFilteredOnly: true },
    { headerName: '데이터 자산', field: 'asset', flex: 1.5, cellRenderer: function(p) { return '<strong>' + p.value + '</strong>'; } },
    { headerName: '현재 분류', field: 'currentDomain', width: 100, cellRenderer: function(p) { return '<span class="badge badge-ghost" style="font-size:11px;">' + p.value + '</span>'; } },
    { headerName: '제안 분류', field: 'suggestDomain', width: 100, cellRenderer: function(p) { return '<span class="badge badge-info" style="font-size:11px;">' + p.value + '</span>'; } },
    { headerName: '신뢰도', field: 'confidence', width: 90, cellRenderer: function(p) {
      var color = p.value >= 90 ? '#2e7d32' : p.value >= 80 ? '#f57c00' : '#c62828';
      return '<span style="font-weight:700; color:' + color + ';">' + p.value + '%</span>';
    }},
    { headerName: '근거 규칙', field: 'rule', flex: 1, cellStyle: { fontSize: '12px', color: '#666' } }
  ];
  initAGGrid('ag-grid-auto-classify', colDefs, AUTO_CLASSIFY_RESULTS, {
    pagination: false, domLayout: 'autoHeight',
    rowSelection: 'multiple', suppressRowClickSelection: true
  });
  showToast('자동 분류 분석이 완료되었습니다. (' + AUTO_CLASSIFY_RESULTS.length + '건)', 'success');
}

function applyClassifyResults() {
  var grid = agGridInstances['ag-grid-auto-classify'];
  var selected = grid ? grid.getSelectedRows() : [];
  if (selected.length === 0) { showToast('적용할 항목을 선택해 주세요.', 'error'); return; }
  showToast(selected.length + '건의 분류가 적용되었습니다.', 'success');
  document.getElementById('auto-classify-result').style.display = 'none';
}

var UNCLASSIFIED_ASSETS = [
  { no:1, asset:'TB_UNKNOWN_DATA_01', source:'RWIS', tables:12, cols:87, lastMod:'2026-03-15' },
  { no:2, asset:'TB_LEGACY_BACKUP', source:'SAP', tables:1, cols:23, lastMod:'2026-03-10' },
  { no:3, asset:'TB_TEMP_IMPORT_2025', source:'기상청', tables:3, cols:45, lastMod:'2026-02-28' },
  { no:4, asset:'TB_RAW_SENSOR_BUF', source:'RWIS', tables:1, cols:15, lastMod:'2026-03-16' },
  { no:5, asset:'TB_WATER_TEST_RESULT', source:'수질DB', tables:5, cols:62, lastMod:'2026-03-14' },
  { no:6, asset:'TB_PUMP_CTRL_LOG', source:'SCADA', tables:2, cols:31, lastMod:'2026-03-12' },
  { no:7, asset:'TB_BILLING_RAW', source:'SAP', tables:4, cols:58, lastMod:'2026-03-11' },
  { no:8, asset:'TB_GIS_LAYER_TEMP', source:'GIS', tables:1, cols:19, lastMod:'2026-03-09' },
  { no:9, asset:'TB_ENERGY_MONITOR', source:'발전', tables:2, cols:28, lastMod:'2026-03-13' },
  { no:10, asset:'TB_RAINFALL_STAGE', source:'기상청', tables:1, cols:11, lastMod:'2026-03-17' }
];

function openBulkClassifyModal() {
  var modal = document.getElementById('bulk-classify-modal');
  if (!modal) return;
  modal.style.display = 'flex';
  var colDefs = [
    { headerCheckboxSelection: true, checkboxSelection: true, width: 50 },
    { headerName: '#', field: 'no', width: 50 },
    { headerName: '데이터 자산', field: 'asset', flex: 1.5, cellRenderer: function(p) { return '<strong style="color:#1967d2;">' + p.value + '</strong>'; } },
    { headerName: '소스', field: 'source', width: 80 },
    { headerName: '테이블', field: 'tables', width: 70, cellStyle: { textAlign: 'center' } },
    { headerName: '컬럼', field: 'cols', width: 70, cellStyle: { textAlign: 'center' } },
    { headerName: '최종 수정', field: 'lastMod', width: 110 }
  ];
  setTimeout(function() {
    initAGGrid('ag-grid-bulk-classify', colDefs, UNCLASSIFIED_ASSETS, {
      pagination: false, rowSelection: 'multiple', suppressRowClickSelection: true,
      onSelectionChanged: function(event) {
        var cnt = event.api.getSelectedRows().length;
        var el = document.getElementById('bulk-selected-count');
        if (el) el.textContent = '선택: ' + cnt + '건';
        validateBulkClassification();
      }
    });
  }, 100);
}

function validateBulkClassification() {
  var domain = (document.getElementById('bulk-domain') || {}).value;
  var security = (document.getElementById('bulk-security') || {}).value;
  var warningEl = document.getElementById('bulk-conflict-warning');
  if (!warningEl) return;
  if (!domain && security) {
    warningEl.style.display = 'block';
    warningEl.innerHTML = '⚠️ 충돌 규칙 위반: 도메인 미할당 자산은 보안등급 설정 불가';
  } else {
    warningEl.style.display = 'none';
  }
}

function applyBulkClassify() {
  var grid = agGridInstances['ag-grid-bulk-classify'];
  var selected = grid ? grid.getSelectedRows() : [];
  if (selected.length === 0) { showToast('적용할 자산을 선택해 주세요.', 'error'); return; }
  var domain = (document.getElementById('bulk-domain') || {}).value;
  var security = (document.getElementById('bulk-security') || {}).value;
  var area = (document.getElementById('bulk-area') || {}).value;
  if (!domain && !security && !area) { showToast('최소 하나의 분류를 선택해 주세요.', 'error'); return; }
  // 충돌 검증
  if (!domain && security) { showToast('충돌 규칙 위반: 도메인 미할당 자산은 보안등급 설정 불가', 'error'); return; }
  showToast(selected.length + '건의 자산에 분류가 일괄 적용되었습니다.', 'success');
  closeModalHelper('bulk-classify-modal');
}

function approveClassifyChange(btn) {
  var row = btn.closest('tr');
  if (!row) return;
  var statusCell = row.querySelector('.badge');
  if (statusCell) { statusCell.className = 'badge badge-success'; statusCell.style.fontSize = '11px'; statusCell.textContent = '승인 완료'; }
  btn.disabled = true;
  btn.nextElementSibling.disabled = true;
  btn.textContent = '완료';
  btn.style.opacity = '0.5';
  btn.nextElementSibling.style.opacity = '0.5';
  showToast('분류 변경이 승인되었습니다.', 'success');
}

function rejectClassifyChange(btn) {
  var row = btn.closest('tr');
  if (!row) return;
  var statusCell = row.querySelector('.badge');
  if (statusCell) { statusCell.className = 'badge badge-error'; statusCell.style.fontSize = '11px'; statusCell.textContent = '반려'; }
  btn.disabled = true;
  btn.previousElementSibling.disabled = true;
  btn.textContent = '반려됨';
  btn.style.opacity = '0.5';
  btn.previousElementSibling.style.opacity = '0.5';
  showToast('분류 변경이 반려되었습니다.', 'error');
}

var glossaryInitialized = false;
function initGlossaryScreen() {
  if (glossaryInitialized) return;
  glossaryInitialized = true;
  loadGlossaryStats();
  loadDomainGroups();
  loadDomainDistribution();
  initGlossaryFilters();
  loadSyncStatus();
  initAdvancedSearchDomains();
  if (typeof loadGlossaryChangeEvents === 'function') loadGlossaryChangeEvents();
  switchGlossaryTab('word');
}

function initMetadataGrids() {
  // 표준사전 API 연동은 화면 진입 시 initGlossaryScreen()에서 처리

  // 도메인 분류 (meta-domain)
  initAGGrid('ag-grid-meta-domain', [
    { field: 'no', headerName: '#', width: 45 },
    { field: 'name', headerName: '도메인명', width: 102, cellRenderer: function (p) { return '<strong>' + p.value + '</strong>'; } },
    { field: 'desc', headerName: '설명', flex: 1 },
    { field: 'assets', headerName: '연결 자산', width: 96, type: 'numericColumn', cellStyle: { fontWeight: '700' } },
    { field: 'color', headerName: '색상', width: 70, cellRenderer: function (p) { return '<span style="display:inline-block;width:24px;height:14px;background:' + p.value + ';border-radius:4px;"></span>'; } },
    { field: 'manager', headerName: '관리자', width: 84 },
    { field: 'status', headerName: '상태', width: 70, cellRenderer: function (p) { return '<span style="background:#e8f5e9;color:#2e7d32;padding:2px 8px;border-radius:4px;font-size:11px;">' + p.value + '</span>'; } },
    { field: 'action', headerName: '액션', width: 70, sortable: false, filter: false, cellRenderer: function () { return '<button style="padding:3px 8px;border:1px solid #ddd;background:#fff;border-radius:6px;font-size:11px;cursor:pointer;margin-right:4px;">✏️</button><button style="padding:3px 8px;border:1px solid #fcc;background:#fff;border-radius:6px;font-size:11px;cursor:pointer;color:#f44336;">🗑</button>'; } }
  ], [
    { no: 1, name: '수자원', desc: '댐·하천·지하수 등 수자원 관련 데이터', assets: '2,847', color: '#1976d2', manager: '김수자원', status: '활성' },
    { no: 2, name: '에너지', desc: '수력발전·태양광·ESS 에너지 관련 데이터', assets: '1,256', color: '#ff9800', manager: '한에너지', status: '활성' },
    { no: 3, name: '상수도', desc: '정수장·배수지·광역관로 상수도 운영 데이터', assets: '3,421', color: '#00bcd4', manager: '김수도', status: '활성' },
    { no: 4, name: '수질', desc: '수질측정·분석·등급판정 관련 데이터', assets: '1,892', color: '#4caf50', manager: '최수질', status: '활성' },
    { no: 5, name: '고객', desc: '요금·고객관리·민원 관련 데이터', assets: '986', color: '#9c27b0', manager: '이관리', status: '활성' },
    { no: 6, name: '계측', desc: 'TM/TC·IoT 센서·원격계측 시스템 데이터', assets: '4,531', color: '#e91e63', manager: '박계측', status: '활성' }
  ]);

  // 태그 할당·변경 이력 (meta-tag-history)
  initAGGrid('ag-grid-meta-tag-history', [
    { field: 'asset', headerName: '데이터 자산', flex: 1, cellRenderer: function (p) { return '<strong>' + p.value + '</strong>'; } },
    { field: 'domain', headerName: '도메인', width: 90, cellRenderer: function (p) { return '<span style="background:' + p.data.domBg + ';color:' + p.data.domColor + ';padding:2px 8px;border-radius:4px;font-size:11px;">' + p.value + '</span>'; } },
    {
      field: 'grade', headerName: '보안등급', width: 102, cellRenderer: function (p) {
        var m = { '1등급': { bg: '#ffebee', c: '#c62828' }, '2등급': { bg: '#fff3e0', c: '#f57c00' }, '3등급': { bg: '#e8f5e9', c: '#2e7d32' } };
        var s = m[p.value] || { bg: '#f5f5f5', c: '#666' };
        return '<span style="background:' + s.bg + ';color:' + s.c + ';padding:2px 6px;border-radius:4px;font-size:11px;">' + p.value + '</span>';
      }
    },
    { field: 'area', headerName: '업무영역', width: 102 },
    {
      field: 'changeType', headerName: '변경 유형', width: 102, cellRenderer: function (p) {
        var m = { '변경': { bg: '#fff3e0', c: '#e65100', icon: '🔄' }, '신규': { bg: '#e8f5e9', c: '#2e7d32', icon: '✅' }, '삭제': { bg: '#ffebee', c: '#c62828', icon: '🔴' } };
        var s = m[p.value] || { bg: '#f5f5f5', c: '#666', icon: '' };
        return '<span style="background:' + s.bg + ';color:' + s.c + ';padding:2px 8px;border-radius:10px;font-size:11px;">' + s.icon + ' ' + p.value + '</span>';
      }
    },
    { field: 'detail', headerName: '변경내용', flex: 1 },
    { field: 'changer', headerName: '변경자', width: 84 },
    { field: 'date', headerName: '일시', width: 90 }
  ], [
    { asset: '광역상수도 유량실시간', domain: '상수도', domBg: '#e0f7fa', domColor: '#00838f', grade: '2등급', area: '계측', changeType: '변경', detail: '보안등급 3→2 상향', changer: '김수도', date: '02-25 14:30' },
    { asset: 'RWIS 수위센서데이터', domain: '수자원', domBg: '#e3f2fd', domColor: '#1565c0', grade: '3등급', area: '계측', changeType: '신규', detail: '업무영역 태그 추가', changer: '박계측', date: '02-24 11:20' },
    { asset: 'SAP 재무 일일마감', domain: '고객', domBg: '#f3e5f5', domColor: '#7b1fa2', grade: '1등급', area: '재무', changeType: '변경', detail: '도메인 행정→고객 이관', changer: '이관리', date: '02-23 16:45' },
    { asset: '수력발전 일간통계', domain: '에너지', domBg: '#fff8e1', domColor: '#f57f17', grade: '2등급', area: '운영', changeType: '신규', detail: '신규 태그 할당', changer: '한에너지', date: '02-22 09:15' },
    { asset: '정수장 약품투입량', domain: '상수도', domBg: '#e0f7fa', domColor: '#00838f', grade: '2등급', area: '기술', changeType: '변경', detail: '업무영역 운영→기술 변경', changer: '김수도', date: '02-21 13:50' },
    { asset: '고객 요금 청구내역', domain: '고객', domBg: '#f3e5f5', domColor: '#7b1fa2', grade: '1등급', area: '행정', changeType: '삭제', detail: '업무영역 재무 태그 제거', changer: '이관리', date: '02-20 15:30' },
    { asset: '댐 수위관측 원시데이터', domain: '수자원', domBg: '#e3f2fd', domColor: '#1565c0', grade: '3등급', area: '계측', changeType: '신규', detail: '도메인·보안·업무 태그 일괄 할당', changer: '박계측', date: '02-19 10:00' },
    { asset: 'IoT 센서 상태모니터링', domain: '계측', domBg: '#fce4ec', domColor: '#c62828', grade: '2등급', area: '기술', changeType: '변경', detail: '보안등급 3→2 상향 조정', changer: '최수질', date: '02-18 11:40' }
  ]);

  // 데이터모델 목록 (meta-model)
  initAGGrid('ag-grid-meta-model', [
    { field: 'name', headerName: '모델명', flex: 1, cellRenderer: function (p) { return '<a href="#" onclick="openModelDetail(\'' + p.value + '\');return false;" style="color:#1a1a2e;text-decoration:none;font-weight:700;cursor:pointer;">' + p.value + '</a>'; } },
    {
      field: 'type', headerName: '유형', width: 80, cellRenderer: function (p) {
        var m = { '논리': { bg: '#e8f0fe', c: '#1967d2' }, '물리': { bg: '#fff3e0', c: '#ef6c00' } };
        var s = m[p.value] || { bg: '#f5f5f5', c: '#666' };
        return '<span style="background:' + s.bg + ';color:' + s.c + ';padding:2px 8px;border-radius:4px;font-size:11px;font-weight:600;">' + p.value + '</span>';
      }
    },
    {
      field: 'domain', headerName: '도메인', width: 90, cellRenderer: function (p) {
        var m = { '수자원': { bg: '#e3f2fd', c: '#1565c0' }, '상수도': { bg: '#e0f7fa', c: '#00838f' }, '수질': { bg: '#e8f5e9', c: '#2e7d32' }, '에너지': { bg: '#fff8e1', c: '#f57f17' }, '고객': { bg: '#f3e5f5', c: '#7b1fa2' }, '계측': { bg: '#fce4ec', c: '#c62828' } };
        var s = m[p.value] || { bg: '#f5f5f5', c: '#666' };
        return '<span style="background:' + s.bg + ';color:' + s.c + ';padding:2px 8px;border-radius:4px;font-size:11px;">' + p.value + '</span>';
      }
    },
    { field: 'tables', headerName: '테이블수', width: 90, type: 'numericColumn', cellStyle: { fontWeight: '600', fontFamily: 'monospace' } },
    { field: 'columns', headerName: '컬럼수', width: 85, type: 'numericColumn', cellStyle: { fontWeight: '600', fontFamily: 'monospace' } },
    { field: 'piiCols', headerName: 'PII', width: 60, cellRenderer: function (p) {
        if (!p.value || p.value === 0) return '<span style="color:#ccc; font-size:11px;">—</span>';
        return '<span style="background:#fff1f0; color:#cf1322; padding:1px 6px; border-radius:3px; font-size:10px; font-weight:600;">🔒 ' + p.value + '</span>';
      }
    },
    { field: 'pkfk', headerName: 'PK/FK', width: 80, cellStyle: { fontFamily: 'monospace', textAlign: 'center' } },
    {
      field: 'compliance', headerName: '표준준수율', width: 100, cellRenderer: function (p) {
        var v = parseFloat(p.value);
        var c = v >= 95 ? '#2e7d32' : v >= 90 ? '#ef6c00' : '#c62828';
        var bg = v >= 95 ? '#e8f5e9' : v >= 90 ? '#fff3e0' : '#ffebee';
        return '<span style="background:' + bg + ';color:' + c + ';padding:2px 8px;border-radius:4px;font-size:11px;font-weight:700;">' + p.value + '%</span>';
      }
    },
    {
      field: 'status', headerName: '상태', width: 90, cellRenderer: function (p) {
        var m = { '승인': { bg: '#e8f5e9', c: '#2e7d32', dot: '#52c41a' }, '검토중': { bg: '#e8f0fe', c: '#1967d2', dot: '#1677ff' }, '초안': { bg: '#fff8e1', c: '#d48806', dot: '#faad14' }, '반려': { bg: '#ffebee', c: '#c62828', dot: '#ff4d4f' } };
        var s = m[p.value] || { bg: '#f5f5f5', c: '#666', dot: '#999' };
        return '<span style="display:inline-flex;align-items:center;gap:4px;background:' + s.bg + ';color:' + s.c + ';padding:2px 8px;border-radius:4px;font-size:11px;"><span style="width:6px;height:6px;border-radius:50%;background:' + s.dot + ';"></span>' + p.value + '</span>';
      }
    },
    { field: 'lastMod', headerName: '최종수정', width: 96 },
    { field: 'manager', headerName: '담당자', width: 80 }
  ], [
    { name: '수자원관리_논리모델', type: '논리', domain: '수자원', tables: 48, columns: 412, piiCols: 0, pkfk: '48/96', compliance: '95.2', status: '승인', lastMod: '2026-02-28', manager: '김수자원' },
    { name: '수자원관리_물리모델', type: '물리', domain: '수자원', tables: 52, columns: 468, piiCols: 0, pkfk: '52/104', compliance: '93.8', status: '승인', lastMod: '2026-02-27', manager: '김수자원' },
    { name: '상수도관리_논리모델', type: '논리', domain: '상수도', tables: 38, columns: 324, piiCols: 0, pkfk: '38/72', compliance: '96.1', status: '승인', lastMod: '2026-02-26', manager: '김수도' },
    { name: '상수도관리_물리모델', type: '물리', domain: '상수도', tables: 42, columns: 378, piiCols: 6, pkfk: '42/86', compliance: '91.5', status: '검토중', lastMod: '2026-02-25', manager: '김수도' },
    { name: '고객관리_물리모델', type: '물리', domain: '고객', tables: 28, columns: 256, piiCols: 12, pkfk: '28/52', compliance: '94.3', status: '승인', lastMod: '2026-02-24', manager: '이관리' },
    { name: '발전관리_논리모델', type: '논리', domain: '에너지', tables: 32, columns: 284, piiCols: 0, pkfk: '32/64', compliance: '92.7', status: '승인', lastMod: '2026-02-23', manager: '한에너지' },
    { name: '수질관리_물리모델', type: '물리', domain: '수질', tables: 44, columns: 396, piiCols: 4, pkfk: '44/92', compliance: '89.4', status: '초안', lastMod: '2026-02-22', manager: '최수질' },
    { name: '계측통합_물리모델', type: '물리', domain: '계측', tables: 56, columns: 512, piiCols: 3, pkfk: '56/118', compliance: '90.6', status: '검토중', lastMod: '2026-02-21', manager: '박계측' },
    { name: 'GIS공간_논리모델', type: '논리', domain: '수자원', tables: 36, columns: 298, piiCols: 0, pkfk: '36/68', compliance: '97.2', status: '승인', lastMod: '2026-02-20', manager: '김수자원' },
    { name: 'IoT센서_물리모델', type: '물리', domain: '계측', tables: 46, columns: 519, piiCols: 2, pkfk: '46/98', compliance: '87.1', status: '반려', lastMod: '2026-02-19', manager: '박계측' }
  ], {
    domLayout: 'autoHeight',
    getRowStyle: function (params) {
      if (params.data.status === '반려') return { background: '#fff5f5' };
      if (params.data.status === '초안') return { background: '#fffbe6' };
      return null;
    }
  });

  // DQ 검증·프로파일링 (meta-dq) — 10컬럼×10행
  initAGGrid('ag-grid-meta-dq', [
    { field: 'rule', headerName: '규칙명', flex: 1, minWidth: 180, cellRenderer: function(p) { return '<a href="#" onclick="navigate(\'meta-dq-detail\');return false;" style="color:#1a1a2e;text-decoration:none;"><strong>'+p.value+'</strong></a>'; } },
    { field: 'type', headerName: '유형', width: 80, cellRenderer: function(p) {
      var c = { '완전성':'#1967d2', '유효성':'#4caf50', '정합성':'#ff9800', '적시성':'#00897b', '유일성':'#7b1fa2' };
      return '<span style="color:'+(c[p.value]||'#666')+';font-weight:600;font-size:11px;">'+p.value+'</span>';
    }},
    { field: 'target', headerName: '대상', width: 110 },
    { field: 'result', headerName: '결과', width: 72, cellRenderer: function(p) {
      var m = { '통과':{bg:'#e8f5e9',c:'#2e7d32',d:'#52c41a'}, '경고':{bg:'#fff7e6',c:'#d48806',d:'#faad14'}, '실패':{bg:'#fff1f0',c:'#cf1322',d:'#ff4d4f'} };
      var s = m[p.value] || {bg:'#f5f5f5',c:'#666',d:'#999'};
      return '<span style="display:inline-flex;align-items:center;gap:4px;background:'+s.bg+';color:'+s.c+';padding:2px 8px;border-radius:4px;font-size:11px;font-weight:600;"><span style="width:6px;height:6px;background:'+s.d+';border-radius:50%;"></span>'+p.value+'</span>';
    }},
    { field: 'violations', headerName: '위반건수', width: 85, cellRenderer: function(p) {
      var v = parseInt(p.value); var c = v === 0 ? '#4caf50' : v <= 5 ? '#ff9800' : '#f44336';
      return '<span style="font-weight:600;color:'+c+';">'+p.value+'건</span>';
    }},
    { field: 'threshold', headerName: '임계값', width: 80, cellStyle: { fontSize:'12px', color:'#666' } },
    { field: 'trend', headerName: '추이', width: 60, cellRenderer: function(p) {
      var up = p.value.indexOf('▲') >= 0; var flat = p.value.indexOf('—') >= 0;
      var c = flat ? '#999' : (up ? '#f44336' : '#4caf50');
      return '<span style="color:'+c+';font-weight:600;">'+p.value+'</span>';
    }},
    { field: 'lastRun', headerName: '최종실행', width: 80, cellStyle: { fontSize:'12px', color:'#888' } },
    { field: 'owner', headerName: '담당자', width: 80 },
    { field: 'action', headerName: '관리', width: 70, sortable: false, filter: false, cellRenderer: function() { return '<button class="btn btn-outline" style="padding:1px 6px;font-size:11px;" onclick="navigate(\'meta-dq-detail\')">상세</button>'; } }
  ], [
    { rule: '결측치검사 (NULL ≤ 1%)', type: '완전성', target: 'RWIS 수위', result: '통과', violations: '0', threshold: '≤ 1%', trend: '▼', lastRun: '11:42', owner: '박수원' },
    { rule: '범위검사 (0~200m)', type: '유효성', target: 'RWIS 수위', result: '통과', violations: '0', threshold: '0~200m', trend: '—', lastRun: '11:42', owner: '박수원' },
    { rule: '유효값검사 (코드일치)', type: '유효성', target: 'SAP 재무', result: '통과', violations: '0', threshold: '100%', trend: '—', lastRun: '06:15', owner: '이분석' },
    { rule: '정합성검사 (FK 참조)', type: '정합성', target: 'Oracle 인사', result: '경고', violations: '3', threshold: '≤ 5건', trend: '▲', lastRun: '02:30', owner: '최관리' },
    { rule: '이상치탐지 (3σ 이탈)', type: '유효성', target: '스마트미터', result: '경고', violations: '12', threshold: '≤ 10건', trend: '▲', lastRun: '11:40', owner: '박수원' },
    { rule: '적시성검사 (지연 ≤ 5분)', type: '적시성', target: 'GIOS 센서', result: '통과', violations: '0', threshold: '≤ 5분', trend: '▼', lastRun: '11:45', owner: '김데이터' },
    { rule: '중복검사 (PK 유일성)', type: '유일성', target: '수질측정', result: '실패', violations: '28', threshold: '0건', trend: '▲', lastRun: '11:30', owner: '김데이터' },
    { rule: 'NULL 비율검사 (COST_CTR)', type: '완전성', target: 'SAP 재무', result: '실패', violations: '8640', threshold: '≤ 1%', trend: '▲', lastRun: '06:15', owner: '이분석' },
    { rule: '패턴검사 (전화번호)', type: '유효성', target: '고객정보', result: '통과', violations: '2', threshold: '≤ 5건', trend: '▼', lastRun: '11:00', owner: '최관리' },
    { rule: '참조무결성 (부서코드)', type: '정합성', target: 'HR 인사', result: '통과', violations: '0', threshold: '0건', trend: '—', lastRun: '09:00', owner: '최관리' }
  ], {
    domLayout: 'autoHeight',
    getRowStyle: function(p) {
      if (p.data.result === '실패') return { background: '#fff5f5' };
      if (p.data.result === '경고') return { background: '#fffbe6' };
    }
  });
}

// ===== 표준사전 Glossary API 연동 함수 =====

// 상태 셀 렌더러
function glossaryStatusRenderer(p) {
  if (!p.value) return '';
  var m = { active: { c: '#2e7d32', bg: '#e8f5e9', lbl: '활성' }, inactive: { c: '#ed6c02', bg: '#fff3e0', lbl: '비활성' }, deprecated: { c: '#c62828', bg: '#ffebee', lbl: '폐기' } };
  var s = m[p.value] || { c: '#666', bg: '#f5f5f5', lbl: p.value };
  return '<span style="display:inline-flex;align-items:center;gap:4px;font-size:11px;color:' + s.c + ';"><span style="width:6px;height:6px;border-radius:50%;background:' + s.c + ';display:inline-block;"></span>' + s.lbl + '</span>';
}

function getWordColumnDefs() {
  var q = typeof getGlossarySearchTerm === 'function' ? getGlossarySearchTerm() : '';
  return [
    { field: 'word_id', headerName: 'ID', width: 60, hide: true },
    { field: 'logical_name', headerName: '논리명', width: 140, cellRenderer: function(p) { return '<a href="#" onclick="openWordDetail(' + p.data.word_id + ');return false;" style="color:#1677ff;font-weight:600;text-decoration:none;">' + highlightSearchText(p.value, q) + '</a>'; } },
    { field: 'physical_name', headerName: '물리명', width: 120, cellRenderer: function(p) { return '<span style="font-family:monospace;font-size:12px;">' + highlightSearchText(p.value, q) + '</span>'; } },
    { field: 'physical_desc', headerName: '물리의미', flex: 1, cellRenderer: function(p) { return '<span style="font-size:12px;">' + highlightSearchText(p.value, q) + '</span>'; } },
    { field: 'is_class_word', headerName: '분류어', width: 70, cellRenderer: function(p) { return p.value ? '<span style="color:#1967d2;font-weight:600;">Y</span>' : '<span style="color:#aaa;">N</span>'; } },
    { field: 'synonym', headerName: '동의어', width: 100 },
    { field: 'description', headerName: '설명', flex: 1 },
    { field: 'status', headerName: '상태', width: 70, cellRenderer: glossaryStatusRenderer }
  ];
}

function getTermColumnDefs() {
  var q = typeof getGlossarySearchTerm === 'function' ? getGlossarySearchTerm() : '';
  return [
    { field: 'term_id', headerName: 'ID', width: 60, hide: true },
    { field: 'logical_name', headerName: '논리명', width: 140, cellRenderer: function(p) { return '<a href="#" onclick="openTermDetail(' + p.data.term_id + ');return false;" style="color:#1677ff;font-weight:600;text-decoration:none;">' + highlightSearchText(p.value, q) + '</a>'; } },
    { field: 'physical_name', headerName: '물리명', width: 140, cellRenderer: function(p) { return '<span style="font-family:monospace;font-size:12px;">' + highlightSearchText(p.value, q) + '</span>'; } },
    { field: 'english_name', headerName: '영문의미', flex: 1, cellRenderer: function(p) { return '<span style="font-size:12px;">' + highlightSearchText(p.value, q) + '</span>'; } },
    { field: 'group_name', headerName: '도메인그룹', width: 110 },
    { field: 'data_type', headerName: '데이터타입', width: 100, cellStyle: { fontFamily: 'monospace', fontSize: '11px' } },
    { field: 'data_length', headerName: '길이', width: 60, type: 'numericColumn' },
    { field: 'description', headerName: '설명', flex: 1 },
    { field: 'is_personal_info', headerName: '개인정보', width: 75, cellRenderer: function(p) { return p.value ? '<span style="color:#c62828;font-weight:600;">Y</span>' : '<span style="color:#aaa;">N</span>'; } },
    { field: 'status', headerName: '상태', width: 70, cellRenderer: glossaryStatusRenderer }
  ];
}

function getCodeGroupColumnDefs() {
  var q = typeof getGlossarySearchTerm === 'function' ? getGlossarySearchTerm() : '';
  return [
    { field: 'group_id', headerName: 'ID', width: 60, hide: true },
    { field: 'system_prefix', headerName: '시스템', width: 80, cellStyle: { fontFamily: 'monospace', fontSize: '11px', color: '#7b1fa2' } },
    { field: 'logical_name', headerName: '코드그룹명', width: 150, cellRenderer: function(p) { return '<a href="#" onclick="openCodeGroupDetail(' + p.data.group_id + ');return false;" style="color:#1677ff;font-weight:600;text-decoration:none;">' + highlightSearchText(p.value, q) + '</a>'; } },
    { field: 'physical_name', headerName: '물리명', width: 150, cellRenderer: function(p) { return '<span style="font-family:monospace;font-size:12px;">' + highlightSearchText(p.value, q) + '</span>'; } },
    { field: 'code_id', headerName: '코드ID', width: 120, cellStyle: { fontFamily: 'monospace', fontSize: '11px' } },
    { field: 'code_count', headerName: '코드 수', width: 80, type: 'numericColumn', cellStyle: { fontWeight: '700' } },
    { field: 'description', headerName: '설명', flex: 1 },
    { field: 'status', headerName: '상태', width: 70, cellRenderer: glossaryStatusRenderer }
  ];
}

// 단어 그리드 로드
function loadWordGrid(page) {
  glossaryState.wordPage = page || glossaryState.wordPage;
  var params = {
    page: glossaryState.wordPage,
    size: glossaryState.wordSize,
    search: glossaryState.wordSearch || null,
    status: glossaryState.wordStatus || null
  };
  var container = document.getElementById('ag-grid-glossary-word');
  if (container) container.style.opacity = '0.5';
  wordApi.list(params).then(function(data) {
    glossaryState.wordTotal = data.total;
    initAGGrid('ag-grid-glossary-word', getWordColumnDefs(), data.items, { pagination: false, domLayout: 'autoHeight' });
    updateGlossaryPagination('word-pagination', data.page, data.pages, data.total, data.size, 'word');
    var lbl = document.getElementById('word-count-label');
    if (lbl) lbl.textContent = '총 ' + data.total.toLocaleString() + '건 중 ' + data.items.length + '건 표시';
    if (container) container.style.opacity = '1';
  }).catch(function(err) {
    showToast('단어 목록 조회 실패: ' + err.message, 'error');
    if (container) container.style.opacity = '1';
  });
}

// 용어 그리드 로드
function loadTermGrid(page) {
  glossaryState.termPage = page || glossaryState.termPage;
  var params = {
    page: glossaryState.termPage,
    size: glossaryState.termSize,
    search: glossaryState.termSearch || null,
    domain_group_id: glossaryState.termDomainGroupId || null,
    status: glossaryState.termStatus || null
  };
  var container = document.getElementById('ag-grid-glossary-term');
  if (container) container.style.opacity = '0.5';
  termApi.list(params).then(function(data) {
    glossaryState.termTotal = data.total;
    initAGGrid('ag-grid-glossary-term', getTermColumnDefs(), data.items, { pagination: false, domLayout: 'autoHeight' });
    updateGlossaryPagination('term-pagination', data.page, data.pages, data.total, data.size, 'term');
    var lbl = document.getElementById('term-count-label');
    if (lbl) lbl.textContent = '총 ' + data.total.toLocaleString() + '건 중 ' + data.items.length + '건 표시';
    if (container) container.style.opacity = '1';
  }).catch(function(err) {
    showToast('용어 목록 조회 실패: ' + err.message, 'error');
    if (container) container.style.opacity = '1';
  });
}

// 코드그룹 그리드 로드
function loadCodeGroupGrid(page) {
  glossaryState.codePage = page || glossaryState.codePage;
  var params = {
    page: glossaryState.codePage,
    size: glossaryState.codeSize,
    search: glossaryState.codeSearch || null
  };
  var container = document.getElementById('ag-grid-glossary-code');
  if (container) container.style.opacity = '0.5';
  codeApiClient.listGroups(params).then(function(data) {
    glossaryState.codeTotal = data.total;
    initAGGrid('ag-grid-glossary-code', getCodeGroupColumnDefs(), data.items, { pagination: false, domLayout: 'autoHeight' });
    updateGlossaryPagination('code-pagination', data.page, data.pages, data.total, data.size, 'code');
    var lbl = document.getElementById('code-count-label');
    if (lbl) lbl.textContent = '총 ' + data.total.toLocaleString() + '건 중 ' + data.items.length + '건 표시';
    if (container) container.style.opacity = '1';
  }).catch(function(err) {
    showToast('코드그룹 목록 조회 실패: ' + err.message, 'error');
    if (container) container.style.opacity = '1';
  });
}

// 탭 전환
function switchGlossaryTab(tab) {
  glossaryState.activeTab = tab;
  document.querySelectorAll('.glossary-tab-btn').forEach(function(btn) {
    btn.classList.toggle('active', btn.getAttribute('data-tab') === tab);
  });
  var ws = document.getElementById('glossary-word-section');
  var ts = document.getElementById('glossary-term-section');
  var cs = document.getElementById('glossary-code-section');
  if (ws) ws.style.display = tab === 'word' ? 'block' : 'none';
  if (ts) ts.style.display = tab === 'term' ? 'block' : 'none';
  if (cs) cs.style.display = tab === 'code' ? 'block' : 'none';
  // 도메인그룹 필터는 용어탭에서만 표시
  var df = document.getElementById('glossary-domain-filter');
  if (df) df.style.display = tab === 'term' ? 'inline-block' : 'none';
  // 해당 탭 데이터 로드
  if (tab === 'word') loadWordGrid(1);
  else if (tab === 'term') loadTermGrid(1);
  else if (tab === 'code') loadCodeGroupGrid(1);
}

// 필터 이벤트 바인딩
function initGlossaryFilters() {
  var searchInput = document.getElementById('glossary-search-input');
  var debounceTimer;
  if (searchInput) {
    searchInput.addEventListener('input', function() {
      clearTimeout(debounceTimer);
      var val = this.value.trim();
      debounceTimer = setTimeout(function() {
        if (glossaryState.activeTab === 'word') { glossaryState.wordSearch = val; glossaryState.wordPage = 1; loadWordGrid(); }
        else if (glossaryState.activeTab === 'term') { glossaryState.termSearch = val; glossaryState.termPage = 1; loadTermGrid(); }
        else { glossaryState.codeSearch = val; glossaryState.codePage = 1; loadCodeGroupGrid(); }
      }, 300);
    });
  }
  // 상태 pill 클릭
  document.querySelectorAll('.glossary-status-pill').forEach(function(pill) {
    pill.addEventListener('click', function() {
      document.querySelectorAll('.glossary-status-pill').forEach(function(p) { p.classList.remove('active'); });
      this.classList.add('active');
      var status = this.getAttribute('data-status') || '';
      if (glossaryState.activeTab === 'word') { glossaryState.wordStatus = status; glossaryState.wordPage = 1; loadWordGrid(); }
      else if (glossaryState.activeTab === 'term') { glossaryState.termStatus = status; glossaryState.termPage = 1; loadTermGrid(); }
      else { glossaryState.codePage = 1; loadCodeGroupGrid(); }
    });
  });
  // 도메인그룹 필터 (용어 전용)
  var domainSelect = document.getElementById('glossary-domain-filter');
  if (domainSelect) {
    domainSelect.addEventListener('change', function() {
      glossaryState.termDomainGroupId = this.value || null;
      glossaryState.termPage = 1;
      loadTermGrid();
    });
  }
}

// ========== 고급 검색 기능 ==========
function toggleAdvancedSearch() {
  var panel = document.getElementById('advanced-search-panel');
  var btn = document.getElementById('advanced-search-toggle');
  if (!panel) return;
  var isOpen = panel.style.display !== 'none';
  panel.style.display = isOpen ? 'none' : 'block';
  if (btn) btn.textContent = isOpen ? '🔍 고급 검색' : '🔍 고급 검색 ▲';
}

function initAdvancedSearchDomains() {
  var sel = document.getElementById('adv-domain-group');
  if (!sel) return;
  var groups = glossaryState.domainGroups || [];
  if (groups.length > 0) {
    groups.forEach(function(g) {
      var opt = document.createElement('option');
      opt.value = g.group_id || g.id;
      opt.textContent = g.group_name || g.name;
      sel.appendChild(opt);
    });
  } else {
    // 목업 데이터 추가
    ['수자원', '에너지', '상수도', '수질', '고객', '계측'].forEach(function(name) {
      var opt = document.createElement('option');
      opt.value = name;
      opt.textContent = name;
      sel.appendChild(opt);
    });
  }
}

function collectAdvancedFilters() {
  return {
    logicalName: (document.getElementById('adv-logical-name') || {}).value || '',
    physicalName: (document.getElementById('adv-physical-name') || {}).value || '',
    dataType: (document.getElementById('adv-data-type') || {}).value || '',
    domainGroup: (document.getElementById('adv-domain-group') || {}).value || '',
    dateFrom: (document.getElementById('adv-date-from') || {}).value || '',
    dateTo: (document.getElementById('adv-date-to') || {}).value || ''
  };
}

function applyAdvancedSearch() {
  var filters = collectAdvancedFilters();
  glossaryState.advancedFilters = filters;
  // 기존 검색어에 논리명+물리명을 합쳐서 적용
  var combinedSearch = [filters.logicalName, filters.physicalName].filter(Boolean).join(' ');
  var tab = glossaryState.activeTab;
  if (tab === 'word') {
    glossaryState.wordSearch = combinedSearch;
    glossaryState.wordPage = 1;
    loadWordGrid();
  } else if (tab === 'term') {
    glossaryState.termSearch = combinedSearch;
    if (filters.domainGroup) glossaryState.termDomainGroupId = filters.domainGroup;
    glossaryState.termPage = 1;
    loadTermGrid();
  } else {
    glossaryState.codeSearch = combinedSearch;
    glossaryState.codePage = 1;
    loadCodeGroupGrid();
  }
  showToast('고급 검색 조건이 적용되었습니다.', 'success');
}

function resetAdvancedSearch() {
  ['adv-logical-name', 'adv-physical-name'].forEach(function(id) {
    var el = document.getElementById(id); if (el) el.value = '';
  });
  ['adv-data-type', 'adv-domain-group'].forEach(function(id) {
    var el = document.getElementById(id); if (el) el.selectedIndex = 0;
  });
  ['adv-date-from', 'adv-date-to'].forEach(function(id) {
    var el = document.getElementById(id); if (el) el.value = '';
  });
  glossaryState.advancedFilters = null;
  var searchInput = document.getElementById('glossary-search-input');
  if (searchInput) searchInput.value = '';
  var tab = glossaryState.activeTab;
  if (tab === 'word') { glossaryState.wordSearch = ''; glossaryState.wordPage = 1; loadWordGrid(); }
  else if (tab === 'term') { glossaryState.termSearch = ''; glossaryState.termDomainGroupId = null; glossaryState.termPage = 1; loadTermGrid(); }
  else { glossaryState.codeSearch = ''; glossaryState.codePage = 1; loadCodeGroupGrid(); }
  showToast('검색 조건이 초기화되었습니다.', 'success');
}

// ========== 동기화 상태 표시 ==========
function loadSyncStatus() {
  // 프로토타입 목업 - 동기화 상태 데이터
  var syncData = {
    status: 'normal', // normal | syncing | error
    lastSync: '2026-03-17 09:00:15',
    systems: [
      { name: 'RWIS', status: 'ok' },
      { name: 'SAP', status: 'ok' },
      { name: '기상청API', status: 'ok' },
      { name: '수질DB', status: 'syncing' }
    ]
  };
  var bar = document.getElementById('sync-status-bar');
  if (!bar) return;
  var badge = document.getElementById('sync-status-badge');
  var timeEl = document.getElementById('sync-last-time');
  if (badge) {
    if (syncData.status === 'normal') { badge.className = 'badge badge-success'; badge.textContent = '● 정상'; }
    else if (syncData.status === 'syncing') { badge.className = 'badge badge-warning'; badge.textContent = '● 동기화 중'; }
    else { badge.className = 'badge badge-error'; badge.textContent = '● 오류'; }
  }
  if (timeEl) timeEl.textContent = '마지막 동기화: ' + syncData.lastSync;
}

function runSyncNow() {
  var badge = document.getElementById('sync-status-badge');
  if (badge) { badge.className = 'badge badge-warning'; badge.textContent = '● 동기화 중...'; }
  showToast('동기화를 실행합니다...', 'success');
  setTimeout(function() {
    if (badge) { badge.className = 'badge badge-success'; badge.textContent = '● 정상'; }
    var timeEl = document.getElementById('sync-last-time');
    if (timeEl) timeEl.textContent = '마지막 동기화: ' + new Date().toISOString().replace('T', ' ').substring(0, 19);
    showToast('동기화가 완료되었습니다.', 'success');
  }, 2000);
}

// 커스텀 페이지네이션 UI
function updateGlossaryPagination(containerId, currentPage, totalPages, totalItems, pageSize, tabKey) {
  var el = document.getElementById(containerId);
  if (!el) return;
  if (totalPages <= 1) { el.innerHTML = '<div style="font-size:12px;color:#888;">전체 ' + totalItems.toLocaleString() + '건</div>'; return; }
  var startItem = (currentPage - 1) * pageSize + 1;
  var endItem = Math.min(currentPage * pageSize, totalItems);
  var html = '<div style="font-size:12px;color:#888;">전체 ' + totalItems.toLocaleString() + '건 중 ' + startItem + '~' + endItem + '건</div>';
  html += '<div style="display:flex;gap:2px;align-items:center;">';
  html += '<button class="glossary-page-btn" onclick="onGlossaryPageChange(\'' + tabKey + '\',' + Math.max(1, currentPage - 1) + ')" ' + (currentPage <= 1 ? 'disabled' : '') + '>&lt;</button>';
  var pages = [];
  if (totalPages <= 9) { for (var i = 1; i <= totalPages; i++) pages.push(i); }
  else {
    pages.push(1);
    if (currentPage > 4) pages.push('...');
    for (var j = Math.max(2, currentPage - 2); j <= Math.min(totalPages - 1, currentPage + 2); j++) pages.push(j);
    if (currentPage < totalPages - 3) pages.push('...');
    pages.push(totalPages);
  }
  pages.forEach(function(pg) {
    if (pg === '...') { html += '<span style="padding:0 4px;color:#aaa;">…</span>'; }
    else { html += '<button class="glossary-page-btn' + (pg === currentPage ? ' active' : '') + '" onclick="onGlossaryPageChange(\'' + tabKey + '\',' + pg + ')">' + pg + '</button>'; }
  });
  html += '<button class="glossary-page-btn" onclick="onGlossaryPageChange(\'' + tabKey + '\',' + Math.min(totalPages, currentPage + 1) + ')" ' + (currentPage >= totalPages ? 'disabled' : '') + '>&gt;</button>';
  html += '</div>';
  el.innerHTML = html;
}

function onGlossaryPageChange(tab, page) {
  if (tab === 'word') loadWordGrid(page);
  else if (tab === 'term') loadTermGrid(page);
  else loadCodeGroupGrid(page);
}

// KPI 통계 로드
function loadGlossaryStats() {
  statsApiClient.summary().then(function(data) {
    var dicts = data.dictionaries || [];
    dicts.forEach(function(d) {
      if (d.type === 'word') updateGlossaryKpi('glossary-kpi-words', d.count.toLocaleString() + '건');
      if (d.type === 'term') updateGlossaryKpi('glossary-kpi-terms', d.count.toLocaleString() + '건');
      if (d.type === 'code') updateGlossaryKpi('glossary-kpi-codes', d.count.toLocaleString() + '건');
    });
    updateGlossaryKpi('glossary-kpi-changes', (data.total_changes || 0).toLocaleString() + '건');
  }).catch(function(err) {
    console.error('[통계 로드 실패]', err);
  });
}

function updateGlossaryKpi(cardId, value) {
  var card = document.getElementById(cardId);
  if (!card) return;
  var valEl = card.querySelector('.kpi-value');
  if (valEl) valEl.innerHTML = value;
}

// 도메인그룹 목록 로드 (용어 필터용)
function loadDomainGroups() {
  domainApiClient.listGroups().then(function(data) {
    var items = Array.isArray(data) ? data : (data.items || []);
    glossaryState.domainGroups = items;
    var select = document.getElementById('glossary-domain-filter');
    if (select) {
      select.innerHTML = '<option value="">전체 도메인</option>';
      items.forEach(function(g) {
        select.innerHTML += '<option value="' + g.group_id + '">' + g.group_name + '</option>';
      });
    }
  }).catch(function(err) {
    console.error('[도메인그룹 로드 실패]', err);
  });
}

// 도메인 분포 렌더링
function loadDomainDistribution() {
  var container = document.getElementById('glossary-domain-distribution');
  if (!container) return;
  var colors = ['#1967d2', '#2e7d32', '#7b1fa2', '#e65100', '#c62828', '#00695c', '#546e7a', '#5c6bc0', '#00838f', '#d48806', '#6d4c41'];
  statsApiClient.domainDistribution().then(function(data) {
    if (!data || data.length === 0) { container.innerHTML = '<div style="text-align:center;padding:16px;color:#888;grid-column:1/-1;">분포 데이터 없음</div>'; return; }
    var maxTermCount = Math.max.apply(null, data.map(function(d) { return d.term_count || 0; }));
    var html = '';
    data.forEach(function(d, idx) {
      var c = colors[idx % colors.length];
      var termCount = d.term_count || 0;
      var pct = maxTermCount > 0 ? Math.round((termCount / maxTermCount) * 100) : 0;
      html += '<div class="domain-dist-card" data-group-id="' + d.group_id + '" data-domain="' + d.group_name + '" style="text-align:center;padding:16px 8px;background:#f8f9fb;border-radius:10px;cursor:pointer;transition:all 0.2s;border:2px solid transparent;" title="클릭하면 \'' + d.group_name + '\' 용어 목록을 조회합니다">';
      html += '<div style="font-size:22px;font-weight:700;color:' + c + ';">' + termCount.toLocaleString() + '</div>';
      html += '<div style="font-size:11px;color:#888;margin-top:4px;">' + d.group_name + '</div>';
      html += '<div style="font-size:10px;color:#aaa;margin-top:2px;">도메인 ' + d.domain_count + '건</div>';
      html += '<div style="height:4px;background:#eceff1;border-radius:2px;margin-top:6px;"><div style="width:' + pct + '%;height:100%;background:' + c + ';border-radius:2px;"></div></div>';
      html += '</div>';
    });
    container.innerHTML = html;
    // 도메인 카드 클릭 → 용어탭 전환 + domain_group_id 필터 적용
    container.querySelectorAll('.domain-dist-card').forEach(function(card) {
      card.addEventListener('click', function() {
        var groupId = this.getAttribute('data-group-id');
        var groupName = this.getAttribute('data-domain');
        filterByDomainGroup(groupId, groupName);
      });
    });
  }).catch(function(err) {
    console.error('[도메인 분포 로드 실패]', err);
    container.innerHTML = '<div style="text-align:center;padding:16px;color:#f44336;grid-column:1/-1;">분포 데이터 로드 실패</div>';
  });
}

// 도메인 카드 클릭 → 용어탭으로 전환 + domain_group_id 필터 적용
function filterByDomainGroup(groupId, groupName) {
  var searchInput = document.getElementById('glossary-search-input');
  if (searchInput) searchInput.value = '';
  glossaryState.termSearch = '';
  glossaryState.termDomainGroupId = groupId;
  glossaryState.termPage = 1;
  var domainSelect = document.getElementById('glossary-domain-filter');
  if (domainSelect) domainSelect.value = groupId;
  switchGlossaryTab('term');
  var filterBar = document.querySelector('.filter-bar');
  if (filterBar) filterBar.scrollIntoView({ behavior: 'smooth', block: 'center' });
  if (domainSelect) {
    domainSelect.style.boxShadow = '0 0 0 3px rgba(25,103,210,0.3)';
    setTimeout(function() { domainSelect.style.boxShadow = ''; }, 1500);
  }
}

// ===== 표준사전 상세 모달 =====
function closeGlossaryDetailModal(modalId) {
  var modal = document.getElementById(modalId);
  modal.style.display = 'none';
  // 드래그 위치 초기화
  var card = modal.querySelector('.modal-card');
  if (card) { card.style.transform = ''; card.style.left = ''; card.style.top = ''; card.style.position = ''; card.style.margin = ''; }
}

function formatDateTime(dt) {
  if (!dt) return '-';
  var d = new Date(dt);
  return d.getFullYear() + '-' + String(d.getMonth()+1).padStart(2,'0') + '-' + String(d.getDate()).padStart(2,'0') + ' ' + String(d.getHours()).padStart(2,'0') + ':' + String(d.getMinutes()).padStart(2,'0');
}

function glossaryDetailStatusBadge(status) {
  var m = { active: { bg: '#e8f5e9', c: '#2e7d32', t: '활성' }, inactive: { bg: '#fff3e0', c: '#f57c00', t: '비활성' }, deprecated: { bg: '#ffebee', c: '#c62828', t: '폐기' } };
  var s = m[status] || { bg: '#f5f5f5', c: '#666', t: status || '-' };
  return '<span style="display:inline-block;padding:3px 10px;border-radius:6px;font-size:12px;font-weight:600;background:' + s.bg + ';color:' + s.c + ';">' + s.t + '</span>';
}

function buildInfoRow(label, value) {
  return '<div class="modal-info-row"><span class="modal-info-label">' + label + '</span><span class="modal-info-value">' + (value !== null && value !== undefined && value !== '' ? value : '-') + '</span></div>';
}

function openWordDetail(wordId) {
  var modal = document.getElementById('glossary-word-detail-modal');
  var body = document.getElementById('word-detail-body');
  var subtitle = document.getElementById('word-detail-subtitle');
  body.innerHTML = '<div style="text-align:center;padding:20px;color:#888;">로딩중...</div>';
  subtitle.textContent = '';
  modal.style.display = 'flex';
  wordApi.get(wordId).then(function(data) {
    subtitle.textContent = data.physical_name || '';
    var html = '';
    html += buildInfoRow('논리명', data.logical_name);
    html += buildInfoRow('물리명', '<code style="background:#f0f2f5;padding:1px 6px;border-radius:3px;font-size:12px;">' + (data.physical_name || '-') + '</code>');
    html += buildInfoRow('물리의미', data.physical_desc);
    html += buildInfoRow('분류어 여부', data.is_class_word ? '<span style="color:#1967d2;font-weight:600;">Y (분류어)</span>' : '<span style="color:#888;">N</span>');
    html += buildInfoRow('동의어', data.synonym);
    html += buildInfoRow('설명', data.description);
    html += buildInfoRow('상태', glossaryDetailStatusBadge(data.status));
    html += '<div class="detail-divider"></div>';
    html += buildInfoRow('등록일시', formatDateTime(data.created_at));
    html += buildInfoRow('수정일시', formatDateTime(data.updated_at));
    if (typeof buildSyncInfoSection === 'function') html += buildSyncInfoSection('word');
    body.innerHTML = html;
  }).catch(function(err) {
    body.innerHTML = '<div style="text-align:center;padding:20px;color:#f44336;">조회 실패: ' + err.message + '</div>';
  });
}

function openTermDetail(termId) {
  var modal = document.getElementById('glossary-term-detail-modal');
  var body = document.getElementById('term-detail-body');
  var subtitle = document.getElementById('term-detail-subtitle');
  body.innerHTML = '<div style="text-align:center;padding:20px;color:#888;">로딩중...</div>';
  subtitle.textContent = '';
  modal.style.display = 'flex';
  termApi.get(termId).then(function(data) {
    subtitle.textContent = data.physical_name || '';
    var html = '';
    html += '<div class="detail-section-title">기본 정보</div>';
    html += buildInfoRow('논리명', data.logical_name);
    html += buildInfoRow('물리명', '<code style="background:#f0f2f5;padding:1px 6px;border-radius:3px;font-size:12px;">' + (data.physical_name || '-') + '</code>');
    html += buildInfoRow('영문의미', data.english_name);
    html += buildInfoRow('도메인그룹', data.group_name);
    html += buildInfoRow('도메인', data.domain_logical_name);
    html += buildInfoRow('도메인약어', data.domain_abbr);
    html += buildInfoRow('설명', data.description);
    html += buildInfoRow('상태', glossaryDetailStatusBadge(data.status));
    html += '<div class="detail-section-title">데이터 속성</div>';
    html += buildInfoRow('데이터타입', data.data_type ? '<code style="background:#f0f2f5;padding:1px 6px;border-radius:3px;font-size:12px;">' + data.data_type + '</code>' : '-');
    html += buildInfoRow('길이', data.data_length);
    html += buildInfoRow('소수점', data.data_scale);
    html += '<div class="detail-section-title">보안 정보</div>';
    html += buildInfoRow('개인정보', data.is_personal_info ? '<span style="color:#c62828;font-weight:600;">Y (개인정보 포함)</span>' : '<span style="color:#888;">N</span>');
    html += buildInfoRow('암호화', data.is_encrypted ? '<span style="color:#c62828;font-weight:600;">Y (암호화 대상)</span>' : '<span style="color:#888;">N</span>');
    html += buildInfoRow('스크램블 유형', data.scramble_type);
    html += '<div class="detail-divider"></div>';
    html += buildInfoRow('등록일시', formatDateTime(data.created_at));
    html += buildInfoRow('수정일시', formatDateTime(data.updated_at));
    if (typeof buildSyncInfoSection === 'function') html += buildSyncInfoSection('term');
    body.innerHTML = html;
  }).catch(function(err) {
    body.innerHTML = '<div style="text-align:center;padding:20px;color:#f44336;">조회 실패: ' + err.message + '</div>';
  });
}

function openCodeGroupDetail(groupId) {
  var modal = document.getElementById('glossary-code-detail-modal');
  var body = document.getElementById('code-group-detail-body');
  var subtitle = document.getElementById('code-detail-subtitle');
  body.innerHTML = '<div style="text-align:center;padding:20px;color:#888;">로딩중...</div>';
  subtitle.textContent = '';
  modal.style.display = 'flex';
  Promise.all([
    codeApiClient.getGroup(groupId),
    codeApiClient.getTree(groupId).catch(function() { return []; })
  ]).then(function(results) {
    var data = results[0];
    var codes = results[1];
    subtitle.textContent = data.code_id || '';
    var html = '';
    html += '<div class="detail-section-title">코드그룹 정보</div>';
    html += buildInfoRow('시스템', '<span style="color:#7b1fa2;font-weight:600;">' + (data.system_prefix || '-') + '</span>' + (data.system_name ? ' (' + data.system_name + ')' : ''));
    html += buildInfoRow('논리명', data.logical_name);
    html += buildInfoRow('물리명', '<code style="background:#f0f2f5;padding:1px 6px;border-radius:3px;font-size:12px;">' + (data.physical_name || '-') + '</code>');
    html += buildInfoRow('코드ID', '<code style="background:#f0f2f5;padding:1px 6px;border-radius:3px;font-size:12px;">' + (data.code_id || '-') + '</code>');
    html += buildInfoRow('코드구분', data.code_type);
    html += buildInfoRow('길이', data.data_length);
    html += buildInfoRow('설명', data.code_desc);
    html += buildInfoRow('상태', glossaryDetailStatusBadge(data.status));
    html += buildInfoRow('코드 수', '<span style="font-weight:700;color:#1967d2;">' + (data.code_count || 0) + '건</span>');
    html += '<div class="detail-divider"></div>';
    html += buildInfoRow('등록일시', formatDateTime(data.created_at));
    html += buildInfoRow('수정일시', formatDateTime(data.updated_at));
    // 하위 코드 목록
    if (codes && codes.length > 0) {
      html += '<div class="detail-section-title" style="margin-top:10px;">하위 코드 목록 (' + codes.length + '건)</div>';
      html += '<div style="max-height:280px;overflow-y:auto;border:1px solid #e8e8e8;border-radius:6px;">';
      html += '<table class="data-table" style="width:100%;margin:0;">';
      html += '<thead><tr><th style="width:36px;">#</th><th>코드값</th><th>코드값명</th><th>설명</th><th style="width:50px;">상태</th></tr></thead>';
      html += '<tbody>';
      codes.forEach(function(code, idx) {
        html += '<tr><td>' + (idx + 1) + '</td>';
        html += '<td><code style="background:#f0f2f5;padding:1px 5px;border-radius:3px;font-size:11px;">' + (code.code_value || '') + '</code></td>';
        html += '<td>' + (code.code_name || '') + '</td>';
        html += '<td style="color:#666;">' + (code.description || '') + '</td>';
        html += '<td>' + glossaryDetailStatusBadge(code.status) + '</td></tr>';
      });
      html += '</tbody></table></div>';
    }
    if (typeof buildSyncInfoSection === 'function') html += buildSyncInfoSection('code');
    body.innerHTML = html;
  }).catch(function(err) {
    body.innerHTML = '<div style="text-align:center;padding:20px;color:#f44336;">조회 실패: ' + err.message + '</div>';
  });
}

// ===== 분류체계·태그관리 데이터 =====

var tagDomainData = [
  { no: 1, name: '수자원', desc: '댐·하천·지하수 등 수자원 관련 데이터', assets: '2,847', color: '#1976d2', manager: '김수자원', status: '활성' },
  { no: 2, name: '에너지', desc: '수력발전·태양광·ESS 에너지 관련 데이터', assets: '1,256', color: '#ff9800', manager: '한에너지', status: '활성' },
  { no: 3, name: '상수도', desc: '정수장·배수지·광역관로 상수도 운영 데이터', assets: '3,421', color: '#00bcd4', manager: '김수도', status: '활성' },
  { no: 4, name: '수질', desc: '수질측정·분석·등급판정 관련 데이터', assets: '1,892', color: '#4caf50', manager: '최수질', status: '활성' },
  { no: 5, name: '고객', desc: '요금·고객관리·민원 관련 데이터', assets: '986', color: '#9c27b0', manager: '이관리', status: '활성' },
  { no: 6, name: '계측', desc: 'TM/TC·IoT 센서·원격계측 시스템 데이터', assets: '4,531', color: '#e91e63', manager: '박계측', status: '활성' }
];

var tagBusinessAreas = [
  { name: '계측', count: 4531, bg: '#e3f2fd', border: '#90caf9', color: '#1565c0', subColor: '#42a5f5' },
  { name: '행정', count: 1823, bg: '#fce4ec', border: '#f48fb1', color: '#c62828', subColor: '#e57373' },
  { name: '재무', count: 952, bg: '#fff3e0', border: '#ffcc80', color: '#e65100', subColor: '#ff9800' },
  { name: '기술', count: 3127, bg: '#e8f5e9', border: '#a5d6a7', color: '#2e7d32', subColor: '#66bb6a' },
  { name: '운영', count: 2456, bg: '#ede7f6', border: '#b39ddb', color: '#4527a0', subColor: '#7e57c2' }
];

var tagHistoryData = [
  { asset: '광역상수도 유량실시간', domain: '상수도', domBg: '#e0f7fa', domColor: '#00838f', grade: '2등급', area: '계측', changeType: '변경', detail: '보안등급 3→2 상향', changer: '김수도', date: '02-25 14:30' },
  { asset: 'RWIS 수위센서데이터', domain: '수자원', domBg: '#e3f2fd', domColor: '#1565c0', grade: '3등급', area: '계측', changeType: '신규', detail: '업무영역 태그 추가', changer: '박계측', date: '02-24 11:20' },
  { asset: 'SAP 재무 일일마감', domain: '고객', domBg: '#f3e5f5', domColor: '#7b1fa2', grade: '1등급', area: '재무', changeType: '변경', detail: '도메인 행정→고객 이관', changer: '이관리', date: '02-23 16:45' },
  { asset: '수력발전 일간통계', domain: '에너지', domBg: '#fff8e1', domColor: '#f57f17', grade: '2등급', area: '운영', changeType: '신규', detail: '신규 태그 할당', changer: '한에너지', date: '02-22 09:15' },
  { asset: '정수장 약품투입량', domain: '상수도', domBg: '#e0f7fa', domColor: '#00838f', grade: '2등급', area: '기술', changeType: '변경', detail: '업무영역 운영→기술 변경', changer: '김수도', date: '02-21 13:50' },
  { asset: '고객 요금 청구내역', domain: '고객', domBg: '#f3e5f5', domColor: '#7b1fa2', grade: '1등급', area: '행정', changeType: '삭제', detail: '업무영역 재무 태그 제거', changer: '이관리', date: '02-20 15:30' },
  { asset: '댐 수위관측 원시데이터', domain: '수자원', domBg: '#e3f2fd', domColor: '#1565c0', grade: '3등급', area: '계측', changeType: '신규', detail: '도메인·보안·업무 태그 일괄 할당', changer: '박계측', date: '02-19 10:00' },
  { asset: 'IoT 센서 상태모니터링', domain: '계측', domBg: '#fce4ec', domColor: '#c62828', grade: '2등급', area: '기술', changeType: '변경', detail: '보안등급 3→2 상향 조정', changer: '최수질', date: '02-18 11:40' }
];

var tagUnassignedCount = 127;

// ===== 동기화 상태 표시 =====

function manualSync() {
  var bar = document.getElementById('glossary-sync-bar');
  var icon = document.getElementById('sync-status-icon');
  var text = document.getElementById('sync-status-text');
  var detail = document.getElementById('sync-status-detail');
  if (!bar) return;
  bar.classList.add('syncing');
  if (icon) icon.textContent = '⏳';
  if (text) text.textContent = 'K-water 표준사전 동기화 진행 중...';
  if (detail) detail.textContent = '서버와 연결 중입니다. 잠시만 기다려주세요.';
  setTimeout(function () {
    bar.classList.remove('syncing');
    if (icon) icon.textContent = '✅';
    if (text) text.textContent = 'K-water 표준사전 동기화 완료';
    var now = new Date();
    var ts = now.getFullYear() + '-' + String(now.getMonth() + 1).padStart(2, '0') + '-' + String(now.getDate()).padStart(2, '0') + ' ' + String(now.getHours()).padStart(2, '0') + ':' + String(now.getMinutes()).padStart(2, '0');
    if (detail) detail.textContent = '마지막 동기화: ' + ts + ' · 소스: K-water 표준사전 v3.2 · 변경사항 없음';
    var conflictBadge = document.getElementById('sync-badge-conflict');
    if (conflictBadge) {
      conflictBadge.innerHTML = '충돌 <strong>0</strong>';
      conflictBadge.className = 'sync-badge sync-badge-success';
    }
    showToast('K-water 표준사전 동기화가 완료되었습니다', 'success');
    setTimeout(function () {
      if (icon) icon.textContent = '🔄';
      if (text) text.textContent = 'K-water 표준사전 연동 상태';
    }, 3000);
  }, 2000);
}

// ===== 변경 이벤트 알림 =====

var glossaryChangeEvents = [
  { id: 'EVT-001', type: '단어 추가', desc: '"탄소중립(CRBN_NTRL)" 표준단어 신규 등록', time: '10분 전', read: false, icon: '🆕' },
  { id: 'EVT-002', type: '용어 변경', desc: '"수질등급" 용어 정의 변경 (환경부 기준 반영)', time: '25분 전', read: false, icon: '✏️' },
  { id: 'EVT-003', type: '코드 폐기', desc: '"WQ_OLD_GRADE" 코드그룹 비활성 처리', time: '1시간 전', read: false, icon: '🗑️' },
  { id: 'EVT-004', type: '동기화', desc: 'K-water 표준사전 v3.2 자동 동기화 완료 (변경 12건)', time: '3시간 전', read: true, icon: '🔄' },
  { id: 'EVT-005', type: '충돌 감지', desc: '"유량(FLRT)" 약어가 기존 "FLOW_RT"와 충돌', time: '5시간 전', read: true, icon: '⚠️' }
];

function loadGlossaryChangeEvents() {
  var container = document.getElementById('change-event-list');
  if (!container) return;
  var html = '';
  for (var i = 0; i < glossaryChangeEvents.length; i++) {
    var e = glossaryChangeEvents[i];
    var bg = e.read ? 'transparent' : '#fffde7';
    var fw = e.read ? '400' : '600';
    html += '<div class="change-event-item" style="display:flex; align-items:center; gap:8px; padding:6px 10px; border-radius:6px; background:' + bg + '; cursor:pointer;" onclick="markChangeEventRead(\'' + e.id + '\')">';
    html += '  <span style="font-size:14px; flex-shrink:0;">' + e.icon + '</span>';
    html += '  <span style="font-size:11px; font-weight:' + fw + '; color:var(--text-color); flex:1;">' + e.desc + '</span>';
    html += '  <span style="font-size:10px; color:#888; flex-shrink:0; white-space:nowrap;">' + e.time + '</span>';
    if (!e.read) html += '  <span style="width:6px; height:6px; background:#f44336; border-radius:50%; flex-shrink:0;"></span>';
    html += '</div>';
  }
  container.innerHTML = html;
}

function markChangeEventRead(id) {
  for (var i = 0; i < glossaryChangeEvents.length; i++) {
    if (glossaryChangeEvents[i].id === id) {
      glossaryChangeEvents[i].read = true;
      loadGlossaryChangeEvents();
      return;
    }
  }
}

function markAllChangeEventsRead() {
  for (var i = 0; i < glossaryChangeEvents.length; i++) {
    glossaryChangeEvents[i].read = true;
  }
  loadGlossaryChangeEvents();
  showToast('모든 변경 알림을 읽음 처리했습니다', 'success');
}

// ===== 분류체계·태그 화면 초기화 =====

function initMetaTagScreen() {
  renderDomainGrid();
  renderTagHistoryGrid();
  renderBusinessTags();
  renderAutoClassification();
  renderClassificationReviews();
  updateTagKPIs();
}

function renderDomainGrid() {
  initAGGrid('ag-grid-meta-domain', [
    { field: 'no', headerName: '#', width: 45 },
    { field: 'name', headerName: '도메인명', width: 102, cellRenderer: function (p) { return '<strong>' + p.value + '</strong>'; } },
    { field: 'desc', headerName: '설명', flex: 1 },
    { field: 'assets', headerName: '연결 자산', width: 96, type: 'numericColumn', cellStyle: { fontWeight: '700' } },
    { field: 'color', headerName: '색상', width: 70, cellRenderer: function (p) { return '<span style="display:inline-block;width:24px;height:14px;background:' + p.value + ';border-radius:4px;"></span>'; } },
    { field: 'manager', headerName: '관리자', width: 84 },
    { field: 'status', headerName: '상태', width: 70, cellRenderer: function (p) { return '<span style="background:#e8f5e9;color:#2e7d32;padding:2px 8px;border-radius:4px;font-size:11px;">' + p.value + '</span>'; } },
    { field: 'action', headerName: '액션', width: 70, sortable: false, filter: false, cellRenderer: function (p) {
      return '<button onclick="editDomain(' + p.data.no + ')" style="padding:3px 8px;border:1px solid #ddd;background:#fff;border-radius:6px;font-size:11px;cursor:pointer;margin-right:4px;">✏️</button>' +
        '<button onclick="deleteDomain(' + p.data.no + ')" style="padding:3px 8px;border:1px solid #fcc;background:#fff;border-radius:6px;font-size:11px;cursor:pointer;color:#f44336;">🗑</button>';
    }}
  ], tagDomainData);

  var summary = document.getElementById('domain-summary');
  var totalAssets = tagDomainData.reduce(function(s, d) { return s + parseInt(String(d.assets).replace(/,/g, '')); }, 0);
  if (summary) summary.textContent = '총 ' + tagDomainData.length + '개 도메인 · 연결 자산 합계: ' + totalAssets.toLocaleString() + '건';
}

function renderTagHistoryGrid() {
  initAGGrid('ag-grid-meta-tag-history', [
    { field: 'asset', headerName: '데이터 자산', flex: 1, cellRenderer: function (p) { return '<strong>' + p.value + '</strong>'; } },
    { field: 'domain', headerName: '도메인', width: 90, cellRenderer: function (p) { return '<span style="background:' + p.data.domBg + ';color:' + p.data.domColor + ';padding:2px 8px;border-radius:4px;font-size:11px;">' + p.value + '</span>'; } },
    { field: 'grade', headerName: '보안등급', width: 102, cellRenderer: function (p) {
        var m = { '1등급': { bg: '#ffebee', c: '#c62828' }, '2등급': { bg: '#fff3e0', c: '#f57c00' }, '3등급': { bg: '#e8f5e9', c: '#2e7d32' } };
        var s = m[p.value] || { bg: '#f5f5f5', c: '#666' };
        return '<span style="background:' + s.bg + ';color:' + s.c + ';padding:2px 6px;border-radius:4px;font-size:11px;">' + p.value + '</span>';
      }
    },
    { field: 'area', headerName: '업무영역', width: 102 },
    { field: 'changeType', headerName: '변경 유형', width: 102, cellRenderer: function (p) {
        var m = { '변경': { bg: '#fff3e0', c: '#e65100', icon: '🔄' }, '신규': { bg: '#e8f5e9', c: '#2e7d32', icon: '✅' }, '삭제': { bg: '#ffebee', c: '#c62828', icon: '🔴' } };
        var s = m[p.value] || { bg: '#f5f5f5', c: '#666', icon: '' };
        return '<span style="background:' + s.bg + ';color:' + s.c + ';padding:2px 8px;border-radius:10px;font-size:11px;">' + s.icon + ' ' + p.value + '</span>';
      }
    },
    { field: 'detail', headerName: '변경내용', flex: 1 },
    { field: 'changer', headerName: '변경자', width: 84 },
    { field: 'date', headerName: '일시', width: 90 }
  ], tagHistoryData);
}

function renderBusinessTags() {
  var container = document.getElementById('business-tag-container');
  if (!container) return;
  var html = '';
  tagBusinessAreas.forEach(function(tag, idx) {
    html += '<div style="display:flex;align-items:center;gap:8px;background:' + tag.bg + ';border:1px solid ' + tag.border + ';padding:8px 16px;border-radius:20px;">' +
      '<span style="font-weight:600;color:' + tag.color + ';">' + tag.name + '</span>' +
      '<span style="font-size:11px;color:' + tag.subColor + ';">' + tag.count.toLocaleString() + '건</span>' +
      '<button onclick="removeBusinessTag(' + idx + ')" style="background:none;border:none;color:' + tag.border + ';cursor:pointer;font-size:14px;padding:0 2px;" title="삭제">✕</button>' +
      '</div>';
  });
  html += '<div style="display:flex;align-items:center;gap:6px;border:1px dashed #1967d2;padding:6px 14px;border-radius:20px;cursor:pointer;background:#f0f5ff;">' +
    '<input id="new-business-tag-input" type="text" placeholder="새 태그명 입력" style="border:none;background:transparent;font-size:12px;width:100px;outline:none;color:#1967d2;">' +
    '<button onclick="addBusinessTag()" style="background:#1967d2;border:none;color:#fff;border-radius:12px;width:22px;height:22px;font-size:14px;cursor:pointer;display:flex;align-items:center;justify-content:center;">+</button></div>';
  container.innerHTML = html;

  var totalAssets = tagBusinessAreas.reduce(function(s, t) { return s + t.count; }, 0);
  var summary = document.getElementById('business-tag-summary');
  if (summary) summary.innerHTML = '<span>총 ' + tagBusinessAreas.length + '개 업무영역 태그 · 연결 자산 합계: <strong>' + totalAssets.toLocaleString() + '건</strong></span>' +
    '<span>미분류 자산: <strong style="color:#f44336;">' + tagUnassignedCount + '건</strong> (도메인 할당 필요)</span>';
}

function addBusinessTag() {
  var input = document.getElementById('new-business-tag-input');
  if (!input || !input.value.trim()) return;
  var name = input.value.trim();
  var colors = ['#0277bd', '#558b2f', '#6a1b9a', '#bf360c', '#00695c', '#4e342e'];
  var ci = tagBusinessAreas.length % colors.length;
  tagBusinessAreas.push({ name: name, count: 0, bg: '#f5f5f5', border: '#bdbdbd', color: colors[ci], subColor: '#999' });
  renderBusinessTags();
  updateTagKPIs();
  showToast('"' + name + '" 업무영역 태그가 추가되었습니다', 'success');
}

function removeBusinessTag(idx) {
  if (!confirm('"' + tagBusinessAreas[idx].name + '" 태그를 삭제하시겠습니까?')) return;
  var removed = tagBusinessAreas.splice(idx, 1)[0];
  tagUnassignedCount += removed.count;
  renderBusinessTags();
  updateTagKPIs();
  showToast('"' + removed.name + '" 태그가 삭제되었습니다', 'success');
}

function addDomain() {
  var nameEl = document.getElementById('domain-add-name');
  var descEl = document.getElementById('domain-add-desc');
  var managerEl = document.getElementById('domain-add-manager');
  var colorEl = document.querySelector('input[name="domain-color"]:checked');
  if (!nameEl || !nameEl.value.trim()) { showToast('도메인명을 입력해주세요', 'error'); return; }

  tagDomainData.push({
    no: tagDomainData.length + 1,
    name: nameEl.value.trim(),
    desc: descEl ? descEl.value.trim() : '',
    assets: '0',
    color: colorEl ? colorEl.value : '#607d8b',
    manager: managerEl ? managerEl.value.trim() : '-',
    status: '활성'
  });

  renderDomainGrid();
  updateTagKPIs();
  var modal = document.getElementById('domain-add-modal');
  if (modal) modal.style.display = 'none';
  showToast('"' + nameEl.value.trim() + '" 도메인이 추가되었습니다', 'success');
  if (nameEl) nameEl.value = '';
  if (descEl) descEl.value = '';
  if (managerEl) managerEl.value = '';
  var idEl = document.getElementById('domain-add-id');
  if (idEl) idEl.value = '';
}

function editDomain(no) {
  showToast('도메인 편집 기능 — 프로토타입에서는 추가 모달을 활용하세요', 'success');
}

function deleteDomain(no) {
  var idx = tagDomainData.findIndex(function(d) { return d.no === no; });
  if (idx < 0) return;
  if (!confirm('"' + tagDomainData[idx].name + '" 도메인을 삭제하시겠습니까?')) return;
  tagDomainData.splice(idx, 1);
  tagDomainData.forEach(function(d, i) { d.no = i + 1; });
  renderDomainGrid();
  updateTagKPIs();
  showToast('도메인이 삭제되었습니다', 'success');
}

function updateTagKPIs() {
  var totalTags = tagDomainData.length + 3 + tagBusinessAreas.length;
  var el;
  el = document.getElementById('tag-kpi-total');
  if (el) el.textContent = totalTags + '개';
  el = document.getElementById('tag-kpi-total-sub');
  if (el) el.textContent = '도메인 ' + tagDomainData.length + ' + 보안 3 + 업무 ' + tagBusinessAreas.length;
  el = document.getElementById('tag-kpi-unassigned');
  if (el) el.textContent = tagUnassignedCount + '건';
}

// ===== 자동 분류 제안 =====

var autoClassifyData = [
  { id: 'AC-001', asset: 'RAW_SENSOR_LOG_2026', type: 'table', suggestDomain: '계측', suggestSecurity: '내부', suggestArea: 'IoT센서', confidence: 94.2, reason: '센서(SENSOR), 로그(LOG) 키워드 + 컬럼 패턴 매칭' },
  { id: 'AC-002', asset: 'EXT_WEATHER_API_RESP', type: 'api', suggestDomain: '수자원', suggestSecurity: '공개', suggestArea: '기상', confidence: 88.7, reason: '기상(WEATHER), API 응답 패턴 + 외부 연동 스키마 일치' },
  { id: 'AC-003', asset: 'CUST_COMPLAINT_HIST', type: 'table', suggestDomain: '고객', suggestSecurity: '제한', suggestArea: '고객지원', confidence: 91.3, reason: '고객(CUST), 민원(COMPLAINT) 키워드 + PII 컬럼 감지' },
  { id: 'AC-004', asset: 'WQ_SAMPLING_RESULT', type: 'table', suggestDomain: '수질', suggestSecurity: '내부', suggestArea: '수질검사', confidence: 76.5, reason: '수질(WQ) 접두사 + 샘플링 관련 컬럼 구조' },
  { id: 'AC-005', asset: 'PIPE_MAINT_SCHEDULE', type: 'file', suggestDomain: '상수도', suggestSecurity: '내부', suggestArea: '시설관리', confidence: 86.1, reason: '관로(PIPE), 유지보수(MAINT) 키워드 + 시설코드 참조' }
];

function renderAutoClassification() {
  var container = document.getElementById('auto-classify-list');
  if (!container) return;
  if (autoClassifyData.length === 0) {
    container.innerHTML = '<div style="text-align:center; padding:24px; color:#888; font-size:13px;">분류 대기 중인 자산이 없습니다</div>';
    updateAutoClassifySummary();
    return;
  }
  var typeIcon = { table: '🗃️', api: '🔗', file: '📄', view: '👁️', stream: '📡' };
  var secColor = { '공개': '#4caf50', '내부': '#1976d2', '제한': '#ff9800', '기밀': '#f44336' };
  var html = '';
  for (var i = 0; i < autoClassifyData.length; i++) {
    var item = autoClassifyData[i];
    var icon = typeIcon[item.type] || '📦';
    var sc = secColor[item.suggestSecurity] || '#666';
    var confColor = item.confidence >= 90 ? '#4caf50' : item.confidence >= 80 ? '#1976d2' : '#ff9800';
    html += '<div class="auto-classify-row" id="ac-row-' + item.id + '" style="display:flex; align-items:center; gap:12px; padding:12px 16px; background:#fafbfc; border-radius:10px; border:1px solid #e8e8e8;">';
    html += '  <div style="font-size:20px;">' + icon + '</div>';
    html += '  <div style="flex:1; min-width:0;">';
    html += '    <div style="font-weight:600; font-size:13px; color:var(--text-color);">' + item.asset + '</div>';
    html += '    <div style="font-size:11px; color:#888; margin-top:2px;">' + item.reason + '</div>';
    html += '  </div>';
    html += '  <div style="display:flex; gap:6px; align-items:center; flex-shrink:0;">';
    html += '    <span class="badge badge-info" style="font-size:10px;">' + item.suggestDomain + '</span>';
    html += '    <span class="badge" style="font-size:10px; background:' + sc + '20; color:' + sc + '; border:1px solid ' + sc + '40;">' + item.suggestSecurity + '</span>';
    html += '    <span class="badge badge-ghost" style="font-size:10px;">' + item.suggestArea + '</span>';
    html += '  </div>';
    html += '  <div style="width:80px; flex-shrink:0; text-align:center;">';
    html += '    <div style="font-size:13px; font-weight:700; color:' + confColor + ';">' + item.confidence + '%</div>';
    html += '    <div class="confidence-gauge" style="margin-top:4px;"><div class="confidence-fill" style="width:' + item.confidence + '%; background:' + confColor + ';"></div></div>';
    html += '  </div>';
    html += '  <div style="display:flex; gap:4px; flex-shrink:0;">';
    html += '    <button class="btn btn-primary" style="font-size:10px; padding:3px 10px;" data-perm="write" onclick="applyClassification(\'' + item.id + '\')">적용</button>';
    html += '    <button class="btn btn-outline" style="font-size:10px; padding:3px 10px;" onclick="rejectClassification(\'' + item.id + '\')">거부</button>';
    html += '  </div>';
    html += '</div>';
  }
  container.innerHTML = html;
  updateAutoClassifySummary();
}

function applyClassification(id) {
  for (var i = 0; i < autoClassifyData.length; i++) {
    if (autoClassifyData[i].id === id) {
      var item = autoClassifyData[i];
      autoClassifyData.splice(i, 1);
      tagUnassignedCount = Math.max(0, tagUnassignedCount - 1);
      renderAutoClassification();
      updateTagKPIs();
      showToast('"' + item.asset + '" → ' + item.suggestDomain + '/' + item.suggestSecurity + ' 분류 적용 완료', 'success');
      tagHistoryData.unshift({ date: '2026-03-18', asset: item.asset, change: '자동분류 적용', from: '미분류', to: item.suggestDomain + ' > ' + item.suggestSecurity + ' > ' + item.suggestArea, user: '시스템(AI)' });
      renderTagHistoryGrid();
      return;
    }
  }
}

function rejectClassification(id) {
  for (var i = 0; i < autoClassifyData.length; i++) {
    if (autoClassifyData[i].id === id) {
      var item = autoClassifyData[i];
      autoClassifyData.splice(i, 1);
      renderAutoClassification();
      showToast('"' + item.asset + '" 분류 제안 거부됨', 'error');
      tagHistoryData.unshift({ date: '2026-03-18', asset: item.asset, change: '자동분류 거부', from: item.suggestDomain + '(제안)', to: '미분류 유지', user: '시스템(AI)' });
      renderTagHistoryGrid();
      return;
    }
  }
}

function applyAllClassifications() {
  if (autoClassifyData.length === 0) { showToast('적용할 제안이 없습니다', 'error'); return; }
  var count = autoClassifyData.length;
  for (var i = 0; i < count; i++) {
    tagHistoryData.unshift({ date: '2026-03-18', asset: autoClassifyData[i].asset, change: '자동분류 일괄적용', from: '미분류', to: autoClassifyData[i].suggestDomain + ' > ' + autoClassifyData[i].suggestSecurity + ' > ' + autoClassifyData[i].suggestArea, user: '시스템(AI)' });
  }
  tagUnassignedCount = Math.max(0, tagUnassignedCount - count);
  autoClassifyData = [];
  renderAutoClassification();
  renderTagHistoryGrid();
  updateTagKPIs();
  showToast(count + '건 자동 분류 일괄 적용 완료', 'success');
}

function updateAutoClassifySummary() {
  var el;
  el = document.getElementById('ac-total-count');
  if (el) el.textContent = autoClassifyData.length;
  var avg = 0;
  if (autoClassifyData.length > 0) {
    var sum = 0;
    for (var i = 0; i < autoClassifyData.length; i++) sum += autoClassifyData[i].confidence;
    avg = (sum / autoClassifyData.length).toFixed(1);
  }
  el = document.getElementById('ac-avg-confidence');
  if (el) el.textContent = avg;
}

// ===== 분류 설계 협의 =====

var classificationReviews = [
  { id: 'REV-001', title: '환경모니터링 도메인 신설', type: '도메인 신설', requester: '한에너지', date: '2026-03-15', status: '검토중', reviewers: '김수자원, 이관리', scope: '수자원 도메인 하위 43건 자산 이관', desc: '신재생에너지 관련 데이터가 증가하여 별도 도메인 필요' },
  { id: 'REV-002', title: '고객정보 보안등급 상향', type: '보안등급 변경', requester: '이관리', date: '2026-03-12', status: '승인', reviewers: '정보보안팀장, 김수자원', scope: '고객 도메인 전체 256건', desc: '개인정보보호법 개정에 따른 보안등급 재분류' },
  { id: 'REV-003', title: '계측·IoT 도메인 통합', type: '도메인 통합', requester: '박계측', date: '2026-03-10', status: '반려', reviewers: '김수자원, 한에너지', scope: '계측 + IoT 도메인 합산 312건', desc: '중복 센서 데이터 관리 효율화를 위한 도메인 통합 제안' }
];

function renderClassificationReviews() {
  var container = document.getElementById('classification-reviews');
  if (!container) return;
  if (classificationReviews.length === 0) {
    container.innerHTML = '<div style="text-align:center; padding:24px; color:#888; font-size:13px;">진행 중인 협의가 없습니다</div>';
    return;
  }
  var statusStyle = {
    '검토중': { bg: '#fff8e1', c: '#f57f17', icon: '⏳' },
    '승인': { bg: '#e8f5e9', c: '#2e7d32', icon: '✅' },
    '반려': { bg: '#ffebee', c: '#c62828', icon: '❌' }
  };
  var html = '';
  for (var i = 0; i < classificationReviews.length; i++) {
    var r = classificationReviews[i];
    var ss = statusStyle[r.status] || { bg: '#f5f5f5', c: '#666', icon: '📋' };
    html += '<div class="review-row" style="display:flex; align-items:center; gap:12px; padding:14px 16px; background:#fafbfc; border-radius:10px; border:1px solid #e8e8e8;">';
    html += '  <div style="font-size:20px;">' + ss.icon + '</div>';
    html += '  <div style="flex:1; min-width:0;">';
    html += '    <div style="display:flex; gap:8px; align-items:center; margin-bottom:4px;">';
    html += '      <span style="font-weight:600; font-size:13px; color:var(--text-color);">' + r.title + '</span>';
    html += '      <span class="badge badge-ghost" style="font-size:10px;">' + r.type + '</span>';
    html += '      <span style="background:' + ss.bg + '; color:' + ss.c + '; padding:2px 8px; border-radius:4px; font-size:10px; font-weight:600;">' + r.status + '</span>';
    html += '    </div>';
    html += '    <div style="font-size:11px; color:#888;">요청: ' + r.requester + ' · ' + r.date + ' · 영향 범위: ' + r.scope + '</div>';
    html += '    <div style="font-size:11px; color:#888; margin-top:2px;">검토자: ' + r.reviewers + '</div>';
    html += '  </div>';
    if (r.status === '검토중') {
      html += '  <div style="display:flex; gap:4px; flex-shrink:0;">';
      html += '    <button class="btn btn-primary" style="font-size:10px; padding:3px 10px;" data-perm="manage" onclick="approveReview(\'' + r.id + '\')">승인</button>';
      html += '    <button class="btn btn-outline" style="font-size:10px; padding:3px 10px;" onclick="rejectReview(\'' + r.id + '\')">반려</button>';
      html += '  </div>';
    }
    html += '</div>';
  }
  container.innerHTML = html;
}

function approveReview(id) {
  for (var i = 0; i < classificationReviews.length; i++) {
    if (classificationReviews[i].id === id) {
      classificationReviews[i].status = '승인';
      renderClassificationReviews();
      showToast('"' + classificationReviews[i].title + '" 협의 승인 완료', 'success');
      return;
    }
  }
}

function rejectReview(id) {
  for (var i = 0; i < classificationReviews.length; i++) {
    if (classificationReviews[i].id === id) {
      classificationReviews[i].status = '반려';
      renderClassificationReviews();
      showToast('"' + classificationReviews[i].title + '" 협의 반려', 'error');
      return;
    }
  }
}

function createReviewRequest() {
  var title = document.getElementById('review-req-title');
  var type = document.getElementById('review-req-type');
  var scope = document.getElementById('review-req-scope');
  var desc = document.getElementById('review-req-desc');
  var reviewer = document.getElementById('review-req-reviewer');
  if (!title || !title.value.trim()) { showToast('제목을 입력해주세요', 'error'); return; }
  if (!desc || !desc.value.trim()) { showToast('설명을 입력해주세요', 'error'); return; }
  var newReview = {
    id: 'REV-' + String(classificationReviews.length + 1).padStart(3, '0'),
    title: title.value.trim(),
    type: type ? type.value : '도메인 신설',
    requester: window.currentRoleKey === 'admin' ? '관리자' : '현재 사용자',
    date: '2026-03-18',
    status: '검토중',
    reviewers: reviewer ? reviewer.value.trim() || '미지정' : '미지정',
    scope: scope ? scope.value.trim() || '-' : '-',
    desc: desc.value.trim()
  };
  classificationReviews.unshift(newReview);
  renderClassificationReviews();
  var modal = document.getElementById('review-request-modal');
  if (modal) {
    modal.style.display = 'none';
    var card = modal.querySelector('.modal-card');
    if (card) { card.style.transform = ''; card.style.left = ''; card.style.top = ''; card.style.position = ''; card.style.margin = ''; }
  }
  if (title) title.value = '';
  if (scope) scope.value = '';
  if (desc) desc.value = '';
  if (reviewer) reviewer.value = '';
  showToast('협의 요청 "' + newReview.title + '" 등록 완료', 'success');
}

// ===== 데이터모델 관리 =====

var modelData = [
  { id: 'MDL-001', name: '수자원관리_논리모델', type: '논리', domain: '수자원', tables: 48, columns: 412, piiCols: 0, pkfk: '48/96', compliance: '95.2', status: '승인', lastMod: '2026-02-28', manager: '김수자원' },
  { id: 'MDL-002', name: '수자원관리_물리모델', type: '물리', domain: '수자원', tables: 52, columns: 468, piiCols: 0, pkfk: '52/104', compliance: '93.8', status: '승인', lastMod: '2026-02-27', manager: '김수자원' },
  { id: 'MDL-003', name: '상수도관리_논리모델', type: '논리', domain: '상수도', tables: 38, columns: 324, piiCols: 0, pkfk: '38/72', compliance: '96.1', status: '승인', lastMod: '2026-02-26', manager: '김수도' },
  { id: 'MDL-004', name: '상수도관리_물리모델', type: '물리', domain: '상수도', tables: 42, columns: 378, piiCols: 6, pkfk: '42/86', compliance: '91.5', status: '검토중', lastMod: '2026-02-25', manager: '김수도' },
  { id: 'MDL-005', name: '고객관리_물리모델', type: '물리', domain: '고객', tables: 28, columns: 256, piiCols: 12, pkfk: '28/52', compliance: '94.3', status: '승인', lastMod: '2026-02-24', manager: '이관리' },
  { id: 'MDL-006', name: '발전관리_논리모델', type: '논리', domain: '에너지', tables: 32, columns: 284, piiCols: 0, pkfk: '32/64', compliance: '92.7', status: '승인', lastMod: '2026-02-23', manager: '한에너지' },
  { id: 'MDL-007', name: '수질관리_물리모델', type: '물리', domain: '수질', tables: 44, columns: 396, piiCols: 4, pkfk: '44/92', compliance: '89.4', status: '초안', lastMod: '2026-02-22', manager: '최수질' },
  { id: 'MDL-008', name: '계측통합_물리모델', type: '물리', domain: '계측', tables: 56, columns: 512, piiCols: 3, pkfk: '56/118', compliance: '90.6', status: '검토중', lastMod: '2026-02-21', manager: '박계측' },
  { id: 'MDL-009', name: 'GIS공간_논리모델', type: '논리', domain: '수자원', tables: 36, columns: 298, piiCols: 0, pkfk: '36/68', compliance: '97.2', status: '승인', lastMod: '2026-02-20', manager: '김수자원' },
  { id: 'MDL-010', name: 'IoT센서_물리모델', type: '물리', domain: '계측', tables: 46, columns: 519, piiCols: 2, pkfk: '46/98', compliance: '87.1', status: '반려', lastMod: '2026-02-19', manager: '박계측' }
];

var selectedModelId = null;

function getModelColumnDefs() {
  return [
    { field: 'name', headerName: '모델명', flex: 1, cellRenderer: function (p) { return '<strong style="cursor:pointer;">' + p.value + '</strong>'; } },
    { field: 'type', headerName: '유형', width: 80, cellRenderer: function (p) {
        var m = { '논리': { bg: '#e8f0fe', c: '#1967d2' }, '물리': { bg: '#fff3e0', c: '#ef6c00' } };
        var s = m[p.value] || { bg: '#f5f5f5', c: '#666' };
        return '<span style="background:' + s.bg + ';color:' + s.c + ';padding:2px 8px;border-radius:4px;font-size:11px;font-weight:600;">' + p.value + '</span>';
      }
    },
    { field: 'domain', headerName: '도메인', width: 90, cellRenderer: function (p) {
        var m = { '수자원': { bg: '#e3f2fd', c: '#1565c0' }, '상수도': { bg: '#e0f7fa', c: '#00838f' }, '수질': { bg: '#e8f5e9', c: '#2e7d32' }, '에너지': { bg: '#fff8e1', c: '#f57f17' }, '고객': { bg: '#f3e5f5', c: '#7b1fa2' }, '계측': { bg: '#fce4ec', c: '#c62828' } };
        var s = m[p.value] || { bg: '#f5f5f5', c: '#666' };
        return '<span style="background:' + s.bg + ';color:' + s.c + ';padding:2px 8px;border-radius:4px;font-size:11px;">' + p.value + '</span>';
      }
    },
    { field: 'tables', headerName: '테이블수', width: 90, type: 'numericColumn', cellStyle: { fontWeight: '600', fontFamily: 'monospace' } },
    { field: 'columns', headerName: '컬럼수', width: 85, type: 'numericColumn', cellStyle: { fontWeight: '600', fontFamily: 'monospace' } },
    { field: 'piiCols', headerName: 'PII', width: 60, cellRenderer: function (p) {
        if (!p.value || p.value === 0) return '<span style="color:#ccc; font-size:11px;">—</span>';
        return '<span style="background:#fff1f0; color:#cf1322; padding:1px 6px; border-radius:3px; font-size:10px; font-weight:600;">🔒 ' + p.value + '</span>';
      }
    },
    { field: 'pkfk', headerName: 'PK/FK', width: 80, cellStyle: { fontFamily: 'monospace', textAlign: 'center' } },
    { field: 'compliance', headerName: '표준준수율', width: 100, cellRenderer: function (p) {
        var v = parseFloat(p.value);
        var c = v >= 95 ? '#2e7d32' : v >= 90 ? '#ef6c00' : '#c62828';
        var bg = v >= 95 ? '#e8f5e9' : v >= 90 ? '#fff3e0' : '#ffebee';
        return '<span style="background:' + bg + ';color:' + c + ';padding:2px 8px;border-radius:4px;font-size:11px;font-weight:700;">' + p.value + '%</span>';
      }
    },
    { field: 'status', headerName: '상태', width: 90, cellRenderer: function (p) {
        var m = { '승인': { bg: '#e8f5e9', c: '#2e7d32', dot: '#52c41a' }, '검토중': { bg: '#e8f0fe', c: '#1967d2', dot: '#1677ff' }, '초안': { bg: '#fff8e1', c: '#d48806', dot: '#faad14' }, '반려': { bg: '#ffebee', c: '#c62828', dot: '#ff4d4f' } };
        var s = m[p.value] || { bg: '#f5f5f5', c: '#666', dot: '#999' };
        return '<span style="display:inline-flex;align-items:center;gap:4px;background:' + s.bg + ';color:' + s.c + ';padding:2px 8px;border-radius:4px;font-size:11px;"><span style="width:6px;height:6px;border-radius:50%;background:' + s.dot + ';"></span>' + p.value + '</span>';
      }
    },
    { field: 'lastMod', headerName: '최종수정', width: 96 },
    { field: 'manager', headerName: '담당자', width: 80 }
  ];
}

function initMetaModelScreen() {
  filterMetaModelGrid();
  var firstModel = modelData[0];
  if (firstModel) {
    var entities = modelEntityData[firstModel.id] || [];
    var relations = modelRelations[firstModel.id] || [];
    if (entities.length) {
      renderModelERD('model-erd-preview', entities, relations);
      var titleEl = document.getElementById('model-erd-title');
      if (titleEl) titleEl.textContent = '🗂️ ERD 미리보기 — ' + firstModel.name;
      var subEl = document.getElementById('model-erd-subtitle');
      if (subEl) subEl.textContent = entities.length + ' 테이블 · ' + entities.reduce(function(s,e){return s+e.attrs;},0) + ' 컬럼';
    }
  }
}

function filterMetaModelGrid() {
  var typeFilter = document.getElementById('model-type-filter');
  var domainFilter = document.getElementById('model-domain-filter');
  var searchInput = document.getElementById('model-search-input');
  var typeVal = typeFilter ? typeFilter.value : '';
  var domainVal = domainFilter ? domainFilter.value : '';
  var searchVal = searchInput ? searchInput.value.trim().toLowerCase() : '';

  var filtered = modelData.filter(function(d) {
    if (typeVal && typeVal !== '전체 유형' && d.type !== typeVal) return false;
    if (domainVal && domainVal !== '전체 도메인' && d.domain !== domainVal) return false;
    if (searchVal && d.name.toLowerCase().indexOf(searchVal) < 0) return false;
    return true;
  });

  initAGGrid('ag-grid-meta-model', getModelColumnDefs(), filtered, {
    domLayout: 'autoHeight',
    getRowStyle: function (params) {
      if (params.data.status === '반려') return { background: '#fff5f5' };
      if (params.data.status === '초안') return { background: '#fffbe6' };
      return null;
    },
    onRowClicked: function(event) {
      selectedModelId = event.data.id;
      openModelDetail(event.data.id);
    }
  });

  updateModelKPIs(filtered);
}

function updateModelKPIs(data) {
  var total = data.length;
  var logical = data.filter(function(d) { return d.type === '논리'; }).length;
  var physical = data.filter(function(d) { return d.type === '물리'; }).length;
  var approved = data.filter(function(d) { return d.status === '승인'; }).length;

  var el;
  el = document.getElementById('model-kpi-total');
  if (el) el.innerHTML = total + '<span style="font-size:12px; font-weight:400;">개</span>';
  el = document.getElementById('model-kpi-total-sub');
  if (el) el.textContent = '논리 ' + logical + ' · 물리 ' + physical;
}

// 모델별 엔티티 데이터
var modelEntityData = {
  'MDL-001': [
    { name: '댐_기본정보', physical: 'DM_DAM_INFO', subject: '댐관리', attrs: 8, pk: 1, fk: 0, desc: '전국 다목적댐·용수댐 기본 정보', std: '100%' },
    { name: '수위_관측', physical: 'DM_WATER_LEVEL', subject: '수문관측', attrs: 5, pk: 1, fk: 1, desc: '실시간 수위 관측 데이터', std: '100%' },
    { name: '유량_측정', physical: 'DM_FLOW_RATE', subject: '수문관측', attrs: 4, pk: 1, fk: 1, desc: '유입량/방류량 측정 기록', std: '100%' },
    { name: '방류_이력', physical: 'DM_DISCHARGE', subject: '방류관리', attrs: 5, pk: 1, fk: 1, desc: '방류 시행 및 계획 이력', std: '80%' },
    { name: '수질_측정', physical: 'DM_WATER_QUALITY', subject: '수질관리', attrs: 9, pk: 1, fk: 1, desc: '수질 항목별 분석 결과', std: '100%' },
    { name: '기상_관측', physical: 'DM_WEATHER_OBS', subject: '기상연계', attrs: 7, pk: 1, fk: 0, desc: '기상청 관측소별 기온/강수량', std: '100%' },
    { name: '관측소_정보', physical: 'DM_STATION_INFO', subject: '수문관측', attrs: 10, pk: 1, fk: 0, desc: '수문 관측소 위치 및 장비 정보', std: '90%' },
    { name: '저수량_일통계', physical: 'DM_STORAGE_DAILY', subject: '댐관리', attrs: 6, pk: 1, fk: 1, desc: '댐별 일일 저수량 집계', std: '100%' }
  ],
  'MDL-003': [
    { name: '정수장_기본정보', physical: 'WS_PLANT_INFO', subject: '정수관리', attrs: 12, pk: 1, fk: 0, desc: '정수장 시설 기본 정보', std: '96%' },
    { name: '배수지_현황', physical: 'WS_RESERVOIR', subject: '배수관리', attrs: 8, pk: 1, fk: 1, desc: '배수지 용량 및 현황', std: '100%' },
    { name: '관로_정보', physical: 'WS_PIPELINE', subject: '관로관리', attrs: 10, pk: 1, fk: 0, desc: '광역관로 노선 및 사양', std: '94%' },
    { name: '약품투입_이력', physical: 'WS_CHEMICAL', subject: '정수관리', attrs: 7, pk: 1, fk: 1, desc: '약품 투입량 및 시간 기록', std: '100%' }
  ],
  'MDL-006': [
    { name: '발전소_기본정보', physical: 'EN_PLANT_INFO', subject: '발전관리', attrs: 11, pk: 1, fk: 0, desc: '수력발전소 시설 정보', std: '95%' },
    { name: '발전량_실적', physical: 'EN_GENERATION', subject: '발전실적', attrs: 6, pk: 1, fk: 1, desc: '일별/시간별 발전량 기록', std: '100%' },
    { name: 'ESS_운영현황', physical: 'EN_ESS_STATUS', subject: 'ESS', attrs: 8, pk: 1, fk: 1, desc: '에너지 저장 시스템 충방전 현황', std: '88%' }
  ]
};

// 모델별 관계 정보
var modelRelations = {
  'MDL-001': [
    { from: '수위_관측', to: '댐_기본정보', type: '1:N', fkCol: 'dam_id' },
    { from: '유량_측정', to: '댐_기본정보', type: '1:N', fkCol: 'dam_id' },
    { from: '방류_이력', to: '댐_기본정보', type: '1:N', fkCol: 'dam_id' },
    { from: '수질_측정', to: '댐_기본정보', type: '1:N', fkCol: 'dam_id' },
    { from: '저수량_일통계', to: '댐_기본정보', type: '1:N', fkCol: 'dam_id' }
  ],
  'MDL-003': [
    { from: '배수지_현황', to: '정수장_기본정보', type: '1:N', fkCol: 'plant_id' },
    { from: '약품투입_이력', to: '정수장_기본정보', type: '1:N', fkCol: 'plant_id' }
  ],
  'MDL-006': [
    { from: '발전량_실적', to: '발전소_기본정보', type: '1:N', fkCol: 'plant_id' },
    { from: 'ESS_운영현황', to: '발전소_기본정보', type: '1:N', fkCol: 'plant_id' }
  ]
};

// ERD 시각화 렌더링 (동적 카드 + SVG 관계선)
function renderModelERD(containerId, entities, relations) {
  var container = document.getElementById(containerId);
  if (!container) return;

  var html = '';
  entities.forEach(function(entity, idx) {
    var headerColor = idx === 0 ? '#1967d2' : '#556b8d';
    var cols = [];
    cols.push('<div class="erd-col"><span class="pk">PK</span> ' + entity.physical.toLowerCase() + '_id</div>');
    if (entity.fk > 0) {
      var rel = relations.find(function(r) { return r.from === entity.name; });
      if (rel) cols.push('<div class="erd-col"><span class="fk">FK</span> ' + rel.fkCol + '</div>');
    }
    var remaining = entity.attrs - cols.length;
    if (remaining > 0) cols.push('<div class="erd-col" style="color:#999;font-size:10px;">... 외 ' + remaining + '개 속성</div>');

    html += '<div class="erd-table" data-entity="' + entity.name + '" style="border-color:' + headerColor + ';">' +
      '<div class="erd-header" style="background:' + headerColor + ';">' + entity.name + ' (' + entity.physical + ')</div>' +
      '<div class="erd-cols">' + cols.join('') + '</div></div>';
  });

  html += '<svg class="erd-svg-overlay" style="position:absolute;top:0;left:0;width:100%;height:100%;pointer-events:none;z-index:1;">' +
    '<defs><marker id="arrowhead-' + containerId + '" markerWidth="8" markerHeight="6" refX="8" refY="3" orient="auto"><polygon points="0 0, 8 3, 0 6" fill="#ff9800"/></marker></defs></svg>';

  container.innerHTML = html;
  container.style.position = 'relative';

  setTimeout(function() {
    var svg = container.querySelector('.erd-svg-overlay');
    if (!svg || !relations.length) return;

    var containerRect = container.getBoundingClientRect();
    var paths = '';

    relations.forEach(function(rel) {
      var fromEl = container.querySelector('[data-entity="' + rel.from + '"]');
      var toEl = container.querySelector('[data-entity="' + rel.to + '"]');
      if (!fromEl || !toEl) return;

      var fromRect = fromEl.getBoundingClientRect();
      var toRect = toEl.getBoundingClientRect();

      var x1 = fromRect.left + fromRect.width / 2 - containerRect.left;
      var y1 = fromRect.top - containerRect.top;
      var x2 = toRect.left + toRect.width / 2 - containerRect.left;
      var y2 = toRect.bottom - containerRect.top;

      var midY = (y1 + y2) / 2;
      paths += '<path d="M' + x1 + ',' + y1 + ' C' + x1 + ',' + midY + ' ' + x2 + ',' + midY + ' ' + x2 + ',' + y2 + '" ' +
        'fill="none" stroke="#ff9800" stroke-width="1.5" stroke-dasharray="4,3" ' +
        'marker-end="url(#arrowhead-' + containerId + ')"/>';

      var labelX = (x1 + x2) / 2;
      var labelY = midY - 4;
      paths += '<text x="' + labelX + '" y="' + labelY + '" text-anchor="middle" fill="#ff9800" font-size="9" font-weight="600">' + rel.type + '</text>';
    });

    svg.innerHTML = svg.innerHTML + paths;
  }, 200);
}

// 모델 상세 화면 콘텐츠 렌더링
function renderModelDetailContent(model) {
  if (!model && selectedModelId) {
    model = modelData.find(function(d) { return d.id === selectedModelId; });
  }
  if (!model) return;

  var titleEl = document.getElementById('model-detail-title');
  if (titleEl) {
    var typeMap = { '논리': { bg: '#e8f0fe', c: '#1967d2' }, '물리': { bg: '#fff3e0', c: '#ef6c00' } };
    var statusMap = { '승인': 'approved', '검토중': 'pending', '초안': 'draft', '반려': 'rejected' };
    var ts = typeMap[model.type] || { bg: '#f5f5f5', c: '#666' };
    titleEl.innerHTML = model.name +
      ' <span class="ds-tag" style="background:' + ts.bg + ';color:' + ts.c + ';font-size:12px;">' + model.type + '</span>' +
      ' <span class="glossary-status ' + (statusMap[model.status] || '') + '" style="font-size:12px;"><span class="gs-dot"></span>' + model.status + '</span>';
  }

  var setEl = function(id, val) { var e = document.getElementById(id); if (e) e.textContent = val; };
  var setHtml = function(id, val) { var e = document.getElementById(id); if (e) e.innerHTML = val; };
  setEl('md-info-id', model.id);
  setEl('md-info-name', model.name);
  var ts2 = { '논리': { bg: '#e8f0fe', c: '#1967d2' }, '물리': { bg: '#fff3e0', c: '#ef6c00' } }[model.type] || { bg: '#f5f5f5', c: '#666' };
  setHtml('md-info-type', '<span class="ds-tag" style="background:' + ts2.bg + ';color:' + ts2.c + ';">' + model.type + '모델</span>');
  setEl('md-info-domain', model.domain);
  setEl('md-info-version', 'v1.0');
  setEl('md-info-created', '2024-09-01');
  setEl('md-info-modified', model.lastMod);
  setEl('md-info-manager', model.manager);
  setEl('md-info-desc', model.name + ' — ' + model.domain + ' 도메인의 ' + model.type + ' 데이터 모델');

  var linkedType = model.type === '논리' ? '물리' : '논리';
  var linked = modelData.find(function(d) { return d.domain === model.domain && d.type === linkedType; });
  if (linked) {
    setHtml('md-info-linked', '<a href="#" onclick="openModelDetail(\'' + linked.id + '\');return false;" style="color:#1967d2;text-decoration:none;">' + linked.name + ' →</a>');
  } else {
    setEl('md-info-linked', '-');
  }

  var entities = modelEntityData[model.id] || [];
  var totalAttrs = entities.reduce(function(s, e) { return s + e.attrs; }, 0);
  var totalFks = entities.reduce(function(s, e) { return s + e.fk; }, 0);
  var subjects = {};
  entities.forEach(function(e) { subjects[e.subject] = true; });
  setEl('md-stat-entities', entities.length || model.tables);
  setEl('md-stat-attrs', totalAttrs || model.columns);
  setEl('md-stat-fks', totalFks || model.pkfk.split('/')[1]);
  setEl('md-stat-subjects', Object.keys(subjects).length || '-');

  var tbody = document.getElementById('md-entity-tbody');
  if (tbody && entities.length > 0) {
    var html = '';
    entities.forEach(function(e) {
      var stdColor = parseFloat(e.std) >= 95 ? '#4caf50' : parseFloat(e.std) >= 90 ? '#ff9800' : '#f44336';
      html += '<tr><td><strong>' + e.name + '</strong></td>' +
        '<td style="font-family:monospace;font-size:11px;">' + e.physical + '</td>' +
        '<td>' + e.subject + '</td>' +
        '<td>' + e.attrs + '</td><td>' + e.pk + '</td><td>' + e.fk + '</td>' +
        '<td style="font-size:11px;">' + e.desc + '</td>' +
        '<td><span style="color:' + stdColor + ';font-weight:600;">' + e.std + '</span></td></tr>';
    });
    tbody.innerHTML = html;
    var countEl = document.getElementById('md-entity-count');
    if (countEl) countEl.innerHTML = '총 <strong>' + entities.length + '</strong>개 엔티티 · <strong>' + totalAttrs + '</strong>개 속성';
  }

  var erdContainer = document.getElementById('model-detail-erd');
  if (erdContainer && entities.length > 0) {
    renderModelERD('model-detail-erd', entities, modelRelations[model.id] || []);
  }
}

// ===== 연동 시스템 정보 (상세 모달용) =====

function buildSyncInfoSection(type) {
  var systems = {
    word: { source: 'K-water 표준사전 시스템', syncTime: '2026-03-18 09:15', match: true, version: 'v3.2.1' },
    term: { source: 'K-water 표준사전 시스템', syncTime: '2026-03-18 09:15', match: true, version: 'v3.2.1' },
    code: { source: 'K-water 공통코드 관리', syncTime: '2026-03-17 22:00', match: false, version: 'v2.8.4' }
  };
  var info = systems[type] || systems.word;
  var matchBadge = info.match
    ? '<span style="background:#e8f5e9;color:#2e7d32;padding:2px 8px;border-radius:4px;font-size:11px;font-weight:600;">일치</span>'
    : '<span style="background:#fff3e0;color:#e65100;padding:2px 8px;border-radius:4px;font-size:11px;font-weight:600;">차이 있음</span>';
  var html = '<div class="detail-section-title" style="margin-top:10px;">🔗 연동 시스템 정보</div>';
  html += buildInfoRow('소스 시스템', info.source);
  html += buildInfoRow('시스템 버전', '<code style="background:#f0f2f5;padding:1px 6px;border-radius:3px;font-size:12px;">' + info.version + '</code>');
  html += buildInfoRow('최종 동기화', info.syncTime);
  html += buildInfoRow('데이터 일치 여부', matchBadge);
  return html;
}

// ===== 검색 하이라이트 =====

function highlightSearchText(text, searchTerm) {
  if (!text || !searchTerm) return text || '';
  var escaped = searchTerm.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
  return String(text).replace(new RegExp('(' + escaped + ')', 'gi'), '<mark style="background:#fff176;padding:0 1px;border-radius:2px;">$1</mark>');
}

function getGlossarySearchTerm() {
  var tab = glossaryState.activeTab;
  if (tab === 'word') return glossaryState.wordSearch || '';
  if (tab === 'term') return glossaryState.termSearch || '';
  return glossaryState.codeSearch || '';
}

// ===== 위젯 템플릿 등록 — 실시간 미리보기 =====
function updateWidgetRegPreview() {
  var name = (document.getElementById('wtr-name') || {}).value || '';
  var icon = (document.getElementById('wtr-icon') || {}).value || '🧩';
  var cat = (document.getElementById('wtr-category') || {}).value || '';
  var desc = (document.getElementById('wtr-desc') || {}).value || '';
  var color = (document.getElementById('wtr-color-hex') || {}).value || '#1677ff';
  var dataLevel = (document.getElementById('wtr-data-level') || {}).value || '';
  var emptyEl = document.getElementById('wtr-preview-empty');
  var widgetEl = document.getElementById('wtr-preview-widget');
  if (!emptyEl || !widgetEl) return;

  // 접근 역할 수집
  var allChk = document.getElementById('wt-role-all');
  var roleChks = document.querySelectorAll('.wtr-role-chk:checked');
  var roles = [];
  if (allChk && allChk.checked) { roles = ['전체']; }
  else {
    var roleMap = { employee: '수공직원', partner: '협력직원', engineer: '엔지니어', admin: '관리자' };
    roleChks.forEach(function(c) { roles.push(roleMap[c.value] || c.value); });
  }

  // 데이터등급 라벨
  var lvlMap = { public: '공개', internal: '내부일반', restricted: '내부중요', confidential: '기밀' };
  var lvlLabel = lvlMap[dataLevel] || '—';
  var catLabel = { kpi: 'KPI', card: '카드', list: '리스트', chart: '차트' }[cat] || '—';

  // 메타 정보 업데이트
  var metaCat = document.getElementById('wtr-meta-cat');
  var metaRoles = document.getElementById('wtr-meta-roles');
  var metaLevel = document.getElementById('wtr-meta-level');
  if (metaCat) metaCat.textContent = catLabel;
  if (metaRoles) metaRoles.textContent = roles.length ? roles.join(', ') : '—';
  if (metaLevel) metaLevel.textContent = lvlLabel;

  if (!cat) {
    emptyEl.style.display = 'block';
    widgetEl.style.display = 'none';
    return;
  }
  emptyEl.style.display = 'none';
  widgetEl.style.display = 'block';

  // 카테고리별 샘플 SVG 생성
  var svgContent = _generatePreviewSVG(cat, color, name || '새 위젯');

  // 데이터등급 배지
  var lvlBadge = '';
  if (dataLevel) {
    var lvlColors = { public: { bg: '#e8f5e9', c: '#2e7d32' }, internal: { bg: '#e3f2fd', c: '#1565c0' }, restricted: { bg: '#fff3e0', c: '#ef6c00' }, confidential: { bg: '#ffebee', c: '#c62828' } };
    var lc = lvlColors[dataLevel] || { bg: '#f5f5f5', c: '#666' };
    lvlBadge = '<span style="background:' + lc.bg + ';color:' + lc.c + ';padding:2px 6px;border-radius:3px;font-size:10px;font-weight:600;">' + lvlLabel + '</span>';
  }

  // 위젯 카드 렌더링
  var html = '<div class="wtr-preview-card" style="border:1px solid #e5e7eb; border-radius:10px; overflow:hidden; background:#fff;">';
  // 헤더
  html += '<div style="display:flex; align-items:center; justify-content:space-between; padding:10px 14px; border-bottom:1px solid #f0f0f0;">';
  html += '<div style="display:flex; align-items:center; gap:8px;">';
  html += '<span style="font-size:18px;">' + icon + '</span>';
  html += '<span style="font-size:13px; font-weight:700; color:#1a1a2e;">' + (name || '위젯명 미입력') + '</span>';
  html += '</div>';
  html += lvlBadge;
  html += '</div>';
  // SVG 미리보기 본문
  html += '<div style="padding:12px 14px; min-height:80px;">' + svgContent + '</div>';
  // 설명 + 카테고리 태그
  if (desc || cat) {
    html += '<div style="padding:8px 14px 12px; border-top:1px solid #f0f0f0; display:flex; align-items:center; justify-content:space-between;">';
    html += '<span style="font-size:11px; color:#94a3b8; max-width:70%; overflow:hidden; text-overflow:ellipsis; white-space:nowrap;">' + (desc || '') + '</span>';
    var catBg = { kpi: '#e8f0fe', card: '#fff7e6', list: '#e6fffb', chart: '#f9f0ff' };
    var catC = { kpi: '#1967d2', card: '#d48806', list: '#13c2c2', chart: '#722ed1' };
    html += '<span style="background:' + (catBg[cat] || '#f5f5f5') + ';color:' + (catC[cat] || '#666') + ';padding:2px 8px;border-radius:4px;font-size:10px;font-weight:600;">' + catLabel + '</span>';
    html += '</div>';
  }
  html += '</div>';

  // 대시보드 배치 미리보기 (축소판)
  html += '<div style="margin-top:14px;">';
  html += '<div style="font-size:11px; color:#94a3b8; font-weight:500; margin-bottom:6px;">대시보드 배치 미리보기</div>';
  html += '<div style="background:#f8fafc; border:1px solid #e5e7eb; border-radius:8px; padding:10px; display:grid; grid-template-columns:repeat(3,1fr); gap:6px;">';
  // 3x2 그리드 중 하나를 색상 표시
  for (var gi = 0; gi < 6; gi++) {
    if (gi === 0) {
      html += '<div style="background:' + color + '15; border:2px solid ' + color + '; border-radius:6px; padding:8px; text-align:center;">';
      html += '<span style="font-size:14px;">' + icon + '</span>';
      html += '<div style="font-size:9px; color:' + color + '; font-weight:600; margin-top:2px; overflow:hidden; text-overflow:ellipsis; white-space:nowrap;">' + (name || '새 위젯') + '</div>';
      html += '</div>';
    } else {
      html += '<div style="background:#f0f0f0; border:1px dashed #d1d5db; border-radius:6px; padding:8px; text-align:center;">';
      html += '<div style="font-size:9px; color:#bbb;">빈 슬롯</div>';
      html += '</div>';
    }
  }
  html += '</div>';
  html += '</div>';

  widgetEl.innerHTML = html;
}

// 카테고리별 샘플 SVG 생성 (미리보기용)
function _generatePreviewSVG(cat, color, name) {
  var lighten = color + '33';
  if (cat === 'kpi') {
    return '<svg viewBox="0 0 280 70" style="width:100%;height:auto;">'
      + '<text x="10" y="28" font-size="26" font-weight="700" fill="' + color + '">1,247</text>'
      + '<text x="10" y="48" font-size="12" fill="#52c41a">▲ 12.5%</text>'
      + '<text x="85" y="48" font-size="10" fill="#888">전일 대비</text>'
      + '<polyline points="140,55 165,48 190,52 215,38 240,42 265,30" fill="none" stroke="' + color + '" stroke-width="2"/>'
      + '<circle cx="265" cy="30" r="3" fill="' + color + '"/>'
      + '</svg>';
  }
  if (cat === 'card') {
    return '<svg viewBox="0 0 280 70" style="width:100%;height:auto;">'
      + '<text x="8" y="16" font-size="10" fill="' + color + '" font-weight="600">항목 A</text>'
      + '<rect x="65" y="8" width="80" height="10" fill="' + lighten + '" rx="3"/><rect x="65" y="8" width="60" height="10" fill="' + color + '" rx="3"/><text x="150" y="17" font-size="9" fill="#666">24건</text>'
      + '<text x="8" y="36" font-size="10" fill="' + color + '" font-weight="600">항목 B</text>'
      + '<rect x="65" y="28" width="80" height="10" fill="' + lighten + '" rx="3"/><rect x="65" y="28" width="48" height="10" fill="' + color + '" rx="3"/><text x="150" y="37" font-size="9" fill="#666">18건</text>'
      + '<text x="8" y="56" font-size="10" fill="' + color + '" font-weight="600">항목 C</text>'
      + '<rect x="65" y="48" width="80" height="10" fill="' + lighten + '" rx="3"/><rect x="65" y="48" width="72" height="10" fill="' + color + '" rx="3"/><text x="150" y="57" font-size="9" fill="#666">32건</text>'
      + '</svg>';
  }
  if (cat === 'list') {
    return '<svg viewBox="0 0 280 70" style="width:100%;height:auto;">'
      + '<rect x="4" y="4" width="272" height="16" fill="' + lighten + '" rx="3"/>'
      + '<text x="10" y="15" font-size="9" fill="' + color + '">● 샘플 항목 1 — 최근 업데이트됨</text>'
      + '<rect x="4" y="24" width="272" height="16" fill="#f8fafc" rx="3"/>'
      + '<text x="10" y="35" font-size="9" fill="#475569">● 샘플 항목 2 — 정상 처리 완료</text>'
      + '<rect x="4" y="44" width="272" height="16" fill="' + lighten + '" rx="3"/>'
      + '<text x="10" y="55" font-size="9" fill="' + color + '">● 샘플 항목 3 — 검토 대기중</text>'
      + '</svg>';
  }
  if (cat === 'chart') {
    return '<svg viewBox="0 0 280 70" style="width:100%;height:auto;">'
      + '<rect x="20" y="40" width="24" height="25" fill="' + lighten + '" rx="2"/><rect x="20" y="48" width="24" height="17" fill="' + color + '" rx="2"/>'
      + '<rect x="52" y="30" width="24" height="35" fill="' + lighten + '" rx="2"/><rect x="52" y="38" width="24" height="27" fill="' + color + '" rx="2"/>'
      + '<rect x="84" y="20" width="24" height="45" fill="' + lighten + '" rx="2"/><rect x="84" y="30" width="24" height="35" fill="' + color + '" rx="2"/>'
      + '<rect x="116" y="35" width="24" height="30" fill="' + lighten + '" rx="2"/><rect x="116" y="42" width="24" height="23" fill="' + color + '" rx="2"/>'
      + '<rect x="148" y="15" width="24" height="50" fill="' + lighten + '" rx="2"/><rect x="148" y="22" width="24" height="43" fill="' + color + '" rx="2"/>'
      + '<rect x="180" y="25" width="24" height="40" fill="' + lighten + '" rx="2"/><rect x="180" y="32" width="24" height="33" fill="' + color + '" rx="2"/>'
      + '<rect x="212" y="10" width="24" height="55" fill="' + lighten + '" rx="2"/><rect x="212" y="18" width="24" height="47" fill="' + color + '" rx="2"/>'
      + '<line x1="12" y1="65" x2="244" y2="65" stroke="#e5e7eb" stroke-width="1"/>'
      + '</svg>';
  }
  return '<div style="text-align:center;padding:20px;color:#94a3b8;">미리보기 없음</div>';
}

// ===== 위젯 템플릿 관리 AG Grid =====
function initWidgetTemplateGrid() {
  var catLabels = { kpi:'KPI', card:'카드', list:'리스트', chart:'차트' };
  var catColors = { kpi:{ bg:'#e8f0fe', c:'#1967d2' }, card:{ bg:'#fff7e6', c:'#d48806' }, list:{ bg:'#e6fffb', c:'#13c2c2' }, chart:{ bg:'#f9f0ff', c:'#722ed1' } };
  var roleLabels = { employee:'수공직원', partner:'협력직원', engineer:'엔지니어', admin:'관리자' };
  var rows = WS_WIDGETS.map(function(w) {
    return { id:w.id, icon:w.icon, name:w.name, cat:w.cat, desc:w.desc, roles:w.roles, dataLevel:w.dataLevel, color:w.color };
  });
  initAGGrid('ag-grid-sys-widget-template', [
    { field:'name', headerName:'위젯명', flex:1, cellRenderer: function(p) { return '<a href="#" onclick="showWidgetDetail(\''+p.data.id+'\'); return false;" style="color:#1967d2; text-decoration:none; font-weight:700;">' + p.data.icon + ' ' + p.value + '</a>'; } },
    { field:'cat', headerName:'카테고리', width:90, cellRenderer: function(p) {
        var s = catColors[p.value] || { bg:'#f5f5f5', c:'#666' };
        return '<span style="background:'+s.bg+';color:'+s.c+';padding:2px 8px;border-radius:4px;font-size:11px;">'+( catLabels[p.value]||p.value )+'</span>';
      }
    },
    { field:'desc', headerName:'설명', flex:1.5 },
    { field:'roles', headerName:'접근 역할', width:160, cellRenderer: function(p) {
        if (p.value === 'all') return '<span style="background:#f6ffed;color:#52c41a;padding:2px 8px;border-radius:4px;font-size:11px;">전체</span>';
        return p.value.map(function(r) { return '<span style="background:#f0f0f0;color:#555;padding:1px 6px;border-radius:3px;font-size:10px;margin-right:2px;">'+(roleLabels[r]||r)+'</span>'; }).join('');
      }
    },
    { field:'dataLevel', headerName:'데이터등급', width:100, cellRenderer: function(p) {
        var lbl = DATA_LEVEL_LABELS[p.value] || p.value;
        var bg = DATA_LEVEL_BG[p.value] || '#f5f5f5';
        var c = DATA_LEVEL_COLORS[p.value] || '#666';
        return '<span style="background:'+bg+';color:'+c+';padding:2px 8px;border-radius:4px;font-size:11px;font-weight:600;">'+lbl+'</span>';
      }
    },
    { field:'color', headerName:'색상', width:60, cellRenderer: function(p) {
        return '<span style="display:inline-block;width:18px;height:18px;border-radius:50%;background:'+p.value+';border:1px solid #ddd;vertical-align:middle;"></span>';
      }
    },
    { field:'action', headerName:'관리', width:70, sortable:false, filter:false, cellRenderer: function(p) {
        return '<button class="btn btn-outline" style="padding:1px 6px;font-size:11px;" onclick="showWidgetDetail(\''+p.data.id+'\')">상세</button>';
      }
    }
  ], rows);
}

// ===== 시각화 차트 콘텐츠 AG Grid =====
function initChartContentGrid() {
  var domainLabels = { water:'수질·수량', dam:'댐·저수지', supply:'광역상수도', energy:'에너지·발전', env:'환경·기상' };
  var domainColors = { water:{ bg:'#e6f7ff', c:'#1677ff' }, dam:{ bg:'#e6f7ff', c:'#0050b3' }, supply:{ bg:'#e6fffb', c:'#13c2c2' }, energy:{ bg:'#fff7e6', c:'#d48806' }, env:{ bg:'#f6ffed', c:'#389e0d' } };
  var typeLabels = { line:'라인', bar:'바', area:'영역', pie:'파이', gauge:'게이지', heatmap:'히트맵', table:'테이블', donut:'도넛' };
  var roleLabels = { employee:'수공직원', partner:'협력직원', engineer:'엔지니어', admin:'관리자' };
  var rows = GAL_CHARTS.map(function(c) {
    return { id:c.id, icon:c.icon, name:c.name, domain:c.domain, type:c.type, desc:c.desc, roles:c.roles, dataLevel:c.dataLevel, author:c.author||'-', color:c.color };
  });
  initAGGrid('ag-grid-dist-chart-content', [
    { field:'name', headerName:'차트명', flex:1, cellRenderer: function(p) { return '<a href="#" onclick="showChartDetail(\''+p.data.id+'\'); return false;" style="color:#1967d2; text-decoration:none; font-weight:700;">' + p.data.icon + ' ' + p.value + '</a>'; } },
    { field:'domain', headerName:'도메인', width:90, cellRenderer: function(p) {
        var s = domainColors[p.value] || { bg:'#f5f5f5', c:'#666' };
        return '<span style="background:'+s.bg+';color:'+s.c+';padding:2px 8px;border-radius:4px;font-size:11px;">'+(domainLabels[p.value]||p.value)+'</span>';
      }
    },
    { field:'type', headerName:'유형', width:75, cellRenderer: function(p) {
        return '<span style="background:#f5f5f5;color:#666;padding:2px 8px;border-radius:4px;font-size:11px;">'+(typeLabels[p.value]||p.value)+'</span>';
      }
    },
    { field:'desc', headerName:'설명', flex:1.5 },
    { field:'roles', headerName:'접근 역할', width:160, cellRenderer: function(p) {
        if (p.value === 'all') return '<span style="background:#f6ffed;color:#52c41a;padding:2px 8px;border-radius:4px;font-size:11px;">전체</span>';
        return p.value.map(function(r) { return '<span style="background:#f0f0f0;color:#555;padding:1px 6px;border-radius:3px;font-size:10px;margin-right:2px;">'+(roleLabels[r]||r)+'</span>'; }).join('');
      }
    },
    { field:'dataLevel', headerName:'데이터등급', width:100, cellRenderer: function(p) {
        var lbl = DATA_LEVEL_LABELS[p.value] || p.value;
        var bg = DATA_LEVEL_BG[p.value] || '#f5f5f5';
        var c = DATA_LEVEL_COLORS[p.value] || '#666';
        return '<span style="background:'+bg+';color:'+c+';padding:2px 8px;border-radius:4px;font-size:11px;font-weight:600;">'+lbl+'</span>';
      }
    },
    { field:'author', headerName:'작성자', width:80, cellRenderer: function(p) { return '<strong>' + p.value + '</strong>'; } },
    { field:'action', headerName:'관리', width:70, sortable:false, filter:false, cellRenderer: function(p) {
        return '<button class="btn btn-outline" style="padding:1px 6px;font-size:11px;" onclick="showChartDetail(\''+p.data.id+'\')">상세</button>';
      }
    }
  ], rows);

  // 데이터 유통통계 (dist-stats)
  initAGGrid('ag-grid-dist-stats', [
    { field: 'name', headerName: '데이터셋명', flex: 1, cellRenderer: function(p) { return '<strong>' + p.value + '</strong>'; }},
    { field: 'domain', headerName: '도메인', width: 80, cellRenderer: function(p) {
      var m = { '수자원':{bg:'#e6f7ff',c:'#0958d9'}, '상수도':{bg:'#e8f5e9',c:'#2e7d32'}, '수질':{bg:'#fff7e6',c:'#d48806'}, '발전':{bg:'#fce4ec',c:'#c62828'}, '기상':{bg:'#f9f0ff',c:'#722ed1'} };
      var s = m[p.value]||{bg:'#f5f5f5',c:'#666'};
      return '<span style="background:'+s.bg+';color:'+s.c+';padding:1px 8px;border-radius:4px;font-size:11px;font-weight:600;">'+p.value+'</span>';
    }},
    { field: 'type', headerName: '유형', width: 78, cellRenderer: function(p) {
      var m = { 'REST':{bg:'#e6f7ff',c:'#0958d9'}, 'Kafka':{bg:'#e8f5e9',c:'#2e7d32'}, 'MCP':{bg:'#fff7e6',c:'#d48806'}, 'GIS':{bg:'#f0f0f0',c:'#607d8b'} };
      var s = m[p.value]||{bg:'#f5f5f5',c:'#666'};
      return '<span style="background:'+s.bg+';color:'+s.c+';padding:1px 8px;border-radius:4px;font-size:11px;">'+p.value+'</span>';
    }},
    { field: 'monthly', headerName: '월간호출', width: 88, type:'numericColumn', cellRenderer: function(p) { return '<span style="font-weight:700;">'+p.value+'</span>'; }},
    { field: 'daily', headerName: '일평균', width: 78, type:'numericColumn' },
    { field: 'users', headerName: '사용자', width: 68, type:'numericColumn' },
    { field: 'latency', headerName: '응답(ms)', width: 82, type:'numericColumn', cellRenderer: function(p) {
      var v = parseInt(p.value); var c = v <= 50 ? '#52c41a' : v <= 100 ? '#fa8c16' : '#f5222d';
      return '<span style="font-weight:600;color:'+c+';">'+p.value+'ms</span>';
    }},
    { field: 'quality', headerName: '품질', width: 68, cellRenderer: function(p) {
      var v = parseFloat(p.value); var c = v >= 95 ? '#52c41a' : v >= 90 ? '#fa8c16' : '#f5222d';
      return '<span style="font-weight:600;color:'+c+';">'+p.value+'%</span>';
    }},
    { field: 'trend', headerName: '트렌드', width: 78, cellRenderer: function(p) {
      var up = p.value.indexOf('▲') >= 0;
      return '<span style="color:'+(up?'#52c41a':'#f5222d')+';font-weight:600;font-size:11px;">'+p.value+'</span>';
    }},
    { field: 'status', headerName: '상태', width: 80, cellRenderer: function(p) {
      var s = { '활성':{bg:'#f6ffed',c:'#389e0d',dot:'#52c41a'}, '준비중':{bg:'#fffbe6',c:'#d48806',dot:'#faad14'}, '제한':{bg:'#fff1f0',c:'#cf1322',dot:'#ff4d4f'} };
      var st = s[p.value]||s['활성'];
      return '<span style="display:inline-flex;align-items:center;gap:4px;background:'+st.bg+';color:'+st.c+';padding:2px 8px;border-radius:4px;font-size:11px;font-weight:600;"><span style="width:6px;height:6px;background:'+st.dot+';border-radius:50%;"></span>'+p.value+'</span>';
    }}
  ], [
    { name:'원격검침 사용량분석 API', domain:'수자원', type:'REST', monthly:'892K', daily:'29.7K', users:'42', latency:'23', quality:'96.8', trend:'▲ 15%', status:'활성' },
    { name:'댐수위·방류량 종합 API', domain:'수자원', type:'Kafka', monthly:'561K', daily:'18.7K', users:'38', latency:'12', quality:'97.2', trend:'▲ 22%', status:'활성' },
    { name:'광역상수도 유량실시간', domain:'상수도', type:'Kafka', monthly:'372K', daily:'12.4K', users:'31', latency:'8', quality:'95.1', trend:'▲ 8%', status:'활성' },
    { name:'수질측정데이터 (환경부)', domain:'수질', type:'REST', monthly:'174K', daily:'5.8K', users:'25', latency:'45', quality:'93.5', trend:'▲ 5%', status:'활성' },
    { name:'수력발전 일간통계', domain:'발전', type:'REST', monthly:'96K', daily:'3.2K', users:'18', latency:'67', quality:'91.2', trend:'▼ 3%', status:'활성' },
    { name:'GIS 공간정보 서비스', domain:'수자원', type:'GIS', monthly:'84K', daily:'2.8K', users:'15', latency:'120', quality:'94.0', trend:'▲ 12%', status:'활성' },
    { name:'기상관측 연계 데이터', domain:'기상', type:'MCP', monthly:'62K', daily:'2.1K', users:'12', latency:'88', quality:'92.4', trend:'▲ 3%', status:'활성' },
    { name:'IoT 센서 스트리밍', domain:'수자원', type:'Kafka', monthly:'45K', daily:'1.5K', users:'8', latency:'5', quality:'98.1', trend:'▲ 28%', status:'활성' },
    { name:'수도요금 분석 (내부)', domain:'상수도', type:'REST', monthly:'28K', daily:'933', users:'6', latency:'54', quality:'89.7', trend:'▼ 1%', status:'준비중' },
    { name:'환경영향평가 원시데이터', domain:'수질', type:'MCP', monthly:'12K', daily:'400', users:'4', latency:'142', quality:'87.3', trend:'▼ 5%', status:'제한' }
  ], {
    domLayout: 'autoHeight',
    getRowStyle: function(p) {
      if (p.data.status === '제한') return { background: '#fff5f5' };
      if (p.data.status === '준비중') return { background: '#fffbe6' };
    }
  });
}

// ===== 위젯 상세보기 =====
var _wdCurrentWidget = null; // 현재 상세보기 중인 위젯

function showWidgetDetail(id) {
  var w = WS_WIDGETS.find(function(x) { return x.id === id; });
  if (!w) { alert('위젯을 찾을 수 없습니다.'); return; }
  _wdCurrentWidget = w;

  // 읽기 모드로 초기화
  wdCancelEdit();
  wdRenderView(w);
  wdRenderPreview(w);
  document.getElementById('widget-detail-title').textContent = w.icon + ' ' + w.name + ' — 위젯 상세';
  navigate('sys-widget-template-detail');
}

// 읽기전용 뷰 렌더링
function wdRenderView(w) {
  var catLabels = { kpi:'KPI', card:'카드', list:'리스트', chart:'차트' };
  var catColors = { kpi:{ bg:'#e8f0fe', c:'#1967d2' }, card:{ bg:'#fff7e6', c:'#d48806' }, list:{ bg:'#e6fffb', c:'#13c2c2' }, chart:{ bg:'#f9f0ff', c:'#722ed1' } };
  var roleLabels = { employee:'수공직원', partner:'협력직원', engineer:'엔지니어', admin:'관리자' };
  var cs = catColors[w.cat] || { bg:'#f5f5f5', c:'#666' };
  var rolesHtml = w.roles === 'all'
    ? '<span style="background:#f6ffed;color:#52c41a;padding:2px 10px;border-radius:4px;font-size:12px;">전체</span>'
    : w.roles.map(function(r) { return '<span style="background:#f0f0f0;color:#555;padding:2px 8px;border-radius:4px;font-size:12px;margin-right:4px;">'+(roleLabels[r]||r)+'</span>'; }).join('');
  var dlLbl = DATA_LEVEL_LABELS[w.dataLevel] || w.dataLevel;
  var dlBg = DATA_LEVEL_BG[w.dataLevel] || '#f5f5f5';
  var dlC = DATA_LEVEL_COLORS[w.dataLevel] || '#666';
  document.getElementById('widget-detail-content').innerHTML = ''
    + '<div class="detail-info-item"><div class="dil">위젯 ID</div><div class="div"><code style="background:#f5f5f5;padding:2px 8px;border-radius:4px;font-size:12px;">'+w.id+'</code></div></div>'
    + '<div class="detail-info-item"><div class="dil">위젯명</div><div class="div"><strong>'+w.icon+' '+w.name+'</strong></div></div>'
    + '<div class="detail-info-item"><div class="dil">카테고리</div><div class="div"><span style="background:'+cs.bg+';color:'+cs.c+';padding:2px 10px;border-radius:4px;font-size:12px;">'+(catLabels[w.cat]||w.cat)+'</span></div></div>'
    + '<div class="detail-info-item"><div class="dil">설명</div><div class="div">'+w.desc+'</div></div>'
    + '<div class="detail-info-item"><div class="dil">접근 역할</div><div class="div">'+rolesHtml+'</div></div>'
    + '<div class="detail-info-item"><div class="dil">데이터등급</div><div class="div"><span style="background:'+dlBg+';color:'+dlC+';padding:2px 10px;border-radius:4px;font-size:12px;font-weight:600;">'+dlLbl+'</span></div></div>'
    + '<div class="detail-info-item"><div class="dil">색상</div><div class="div"><span style="display:inline-block;width:20px;height:20px;border-radius:50%;background:'+w.color+';border:1px solid #ddd;vertical-align:middle;margin-right:6px;"></span>'+w.color+'</div></div>'
    + '<div class="detail-info-item"><div class="dil">등록일</div><div class="div">2026-01-15</div></div>'
    + '<div class="detail-info-item"><div class="dil">최종수정</div><div class="div">2026-02-28</div></div>';
}

// 미리보기 렌더링 (실시간)
function wdRenderPreview(w) {
  var box = document.getElementById('wd-preview-box');
  if (!box) return;
  // contentMap에서 실제 콘텐츠 가져오기 (renderHomeWidgets와 동일)
  var content = wdGetWidgetContent(w.id);
  var borderColor = w.color || '#1677ff';
  box.innerHTML = '<div class="card" style="padding:0; overflow:hidden; border-top:3px solid ' + borderColor + ';">'
    + '<div class="card-head" style="padding:10px 16px; display:flex; justify-content:space-between; align-items:center;">'
    + '  <div class="card-title" style="font-size:13px; font-weight:600;">' + (w.icon || '') + ' ' + (w.name || '') + '</div>'
    + '  <span style="font-size:9px; background:#f5f5f5; color:#888; padding:2px 6px; border-radius:3px;">' + ({ kpi:'KPI', card:'카드', list:'리스트', chart:'차트' }[w.cat] || w.cat) + '</span>'
    + '</div>'
    + '<div class="card-body" style="padding:12px 16px;">' + content + '</div>'
    + '<div style="padding:6px 16px; border-top:1px solid var(--border-color); font-size:9px; color:var(--text-secondary); display:flex; justify-content:space-between;">'
    + '  <span>' + (w.desc || '') + '</span>'
    + '  <span style="display:inline-block;width:10px;height:10px;border-radius:50%;background:' + borderColor + ';"></span>'
    + '</div></div>';
}

// 위젯 콘텐츠 가져오기 (renderHomeWidgets의 contentMap 재활용)
function wdGetWidgetContent(wid) {
  var contentMap = {
    'w-active-users': function() { return '<div style="font-size:28px; font-weight:700; color:#1677ff;">847</div><div style="font-size:10px; color:var(--text-secondary); margin-top:4px;">전일 대비 +3.2% · 동시접속 156</div>'; },
    'w-availability': function() { return '<div style="font-size:28px; font-weight:700; color:#52c41a;">99.97%</div><div style="font-size:10px; color:var(--text-secondary); margin-top:4px;">월간 SLA 충족</div>'; },
    'w-security': function() { return '<div style="font-size:28px; font-weight:700; color:#ff4d4f;">12</div><div style="font-size:10px; color:var(--text-secondary); margin-top:4px;">금주 탐지 · 비정상접근 3</div>'; },
    'w-storage': function() { return '<div style="font-size:28px; font-weight:700; color:#722ed1;">78.4%</div><div style="font-size:10px; color:var(--text-secondary); margin-top:4px;">4.7TB / 6.0TB</div>'; },
    'w-pipeline': function() { return '<div style="font-size:28px; font-weight:700; color:#00acc1;">97.8%</div><div style="font-size:10px; color:var(--text-secondary); margin-top:4px;">142/145 성공</div>'; },
    'w-collection': function() { return '<div style="font-size:28px; font-weight:700; color:#26a69a;">1.24M</div><div style="font-size:10px; color:var(--text-secondary); margin-top:4px;">전일 대비 +8.3%</div>'; },
    'w-quality': function() { return '<div style="font-size:28px; font-weight:700; color:#52c41a;">94.2</div><div style="font-size:10px; color:var(--text-secondary); margin-top:4px;">완전성 96.8 · 정합성 93.1</div>'; },
    'w-api-calls': function() { return '<div style="font-size:28px; font-weight:700; color:#42a5f5;">1,840</div><div style="font-size:10px; color:var(--text-secondary); margin-top:4px;">일평균 · 응답률 99.2%</div>'; },
    'w-quality-bar': function() { return buildQualityBars([{label:"완전성",value:96.8,color:"#52c41a"},{label:"정합성",value:93.1,color:"#1677ff"},{label:"유효성",value:92.7,color:"#fa8c16"},{label:"적시성",value:94.8,color:"#722ed1"}]); },
    'w-resource': function() { return buildQualityBars([{label:"CPU",value:62,color:"#52c41a"},{label:"메모리",value:78,color:"#fa8c16"},{label:"디스크",value:45,color:"#1677ff"},{label:"네트워크",value:33,color:"#722ed1"}]); },
    'w-link-progress': function() { return buildQualityBars([{label:"SAP-ETL",value:90,color:"#1677ff"},{label:"RWIS-CDC",value:80,color:"#40a9ff"},{label:"SCADA",value:96,color:"#096dd9"},{label:"기상청API",value:70,color:"#fa8c16"},{label:"환경부API",value:88,color:"#52c41a"}]); },
    'w-link-error': function() { return '<div style="font-size:11px;"><div style="display:flex; justify-content:space-between; margin-bottom:6px;"><span style="color:#f5222d; font-weight:700; font-size:16px;">14<span style="font-size:10px; font-weight:400;"> 건</span></span><span style="background:#fff1f0; color:#cf1322; padding:2px 6px; border-radius:3px; font-size:9px;">실시간</span></div><div style="padding:3px 0; border-bottom:1px solid var(--border-color); font-size:10px;"><span style="color:#cf1322;">●</span> SAP-ETL 타임아웃 <span style="float:right; color:#888;">5건</span></div><div style="padding:3px 0; border-bottom:1px solid var(--border-color); font-size:10px;"><span style="color:#cf1322;">●</span> RWIS 인증오류 <span style="float:right; color:#888;">3건</span></div><div style="padding:3px 0; font-size:10px;"><span style="color:#fa8c16;">▲</span> 기상청API 응답지연 <span style="float:right; color:#888;">4건</span></div></div>'; },
    'w-load-stage': function() { return '<div style="font-size:11px;"><div style="margin-bottom:4px;"><span style="color:#13c2c2; font-size:9px;">수집</span><div style="display:flex; align-items:center; gap:4px;"><div style="flex:1; height:6px; background:#e6fffb; border-radius:3px;"><div style="width:95%; height:100%; background:#13c2c2; border-radius:3px;"></div></div><span style="font-size:9px; color:#13c2c2; min-width:36px;">1.24M</span></div></div><div style="margin-bottom:4px;"><span style="color:#36cfc9; font-size:9px;">정제</span><div style="display:flex; align-items:center; gap:4px;"><div style="flex:1; height:6px; background:#e6fffb; border-radius:3px;"><div style="width:83%; height:100%; background:#36cfc9; border-radius:3px;"></div></div><span style="font-size:9px; color:#36cfc9; min-width:36px;">1.08M</span></div></div><div style="margin-bottom:4px;"><span style="color:#08979c; font-size:9px;">적재</span><div style="display:flex; align-items:center; gap:4px;"><div style="flex:1; height:6px; background:#e6fffb; border-radius:3px;"><div style="width:75%; height:100%; background:#08979c; border-radius:3px;"></div></div><span style="font-size:9px; color:#08979c; min-width:36px;">982K</span></div></div><div><span style="color:#006d75; font-size:9px;">분석</span><div style="display:flex; align-items:center; gap:4px;"><div style="flex:1; height:6px; background:#e6fffb; border-radius:3px;"><div style="width:67%; height:100%; background:#006d75; border-radius:3px;"></div></div><span style="font-size:9px; color:#006d75; min-width:36px;">874K</span></div></div></div>'; },
    'w-load-error': function() { return '<div style="font-size:11px;"><div style="display:flex; gap:8px; margin-bottom:6px;"><div style="flex:1; text-align:center; padding:4px; background:#fff1f0; border-radius:4px;"><div style="font-size:14px; font-weight:700; color:#cf1322;">23</div><div style="font-size:8px; color:#888;">수집오류</div></div><div style="flex:1; text-align:center; padding:4px; background:#fff7e6; border-radius:4px;"><div style="font-size:14px; font-weight:700; color:#fa8c16;">15</div><div style="font-size:8px; color:#888;">정제오류</div></div><div style="flex:1; text-align:center; padding:4px; background:#fff1f0; border-radius:4px;"><div style="font-size:14px; font-weight:700; color:#cf1322;">8</div><div style="font-size:8px; color:#888;">적재오류</div></div><div style="flex:1; text-align:center; padding:4px; background:#e6f7ff; border-radius:4px;"><div style="font-size:14px; font-weight:700; color:#1677ff;">4</div><div style="font-size:8px; color:#888;">스키마</div></div></div><div style="font-size:9px; color:#52c41a;">↘ 전주 대비 -18% 감소세</div></div>'; },
    'w-system-data': function() { return '<div style="font-size:11px;"><div style="padding:3px 0; border-bottom:1px solid var(--border-color); display:flex; justify-content:space-between;"><span>🗄️ 수문DB</span><span><strong style="color:#2f54eb;">842K</strong> <span style="font-size:9px; color:#52c41a;">▲2.1%</span></span></div><div style="padding:3px 0; border-bottom:1px solid var(--border-color); display:flex; justify-content:space-between;"><span>🧪 수질DB</span><span><strong style="color:#597ef7;">621K</strong> <span style="font-size:9px; color:#52c41a;">▲1.5%</span></span></div><div style="padding:3px 0; border-bottom:1px solid var(--border-color); display:flex; justify-content:space-between;"><span>🌤️ 기상DB</span><span><strong style="color:#85a5ff;">487K</strong> <span style="font-size:9px; color:#fa8c16;">-0.3%</span></span></div><div style="padding:3px 0; display:flex; justify-content:space-between;"><span>⚡ 에너지DB</span><span><strong style="color:#adc6ff;">356K</strong> <span style="font-size:9px; color:#52c41a;">▲3.8%</span></span></div></div>'; }
  };
  var fn = contentMap[wid];
  if (fn) return fn();
  // SVG 미리보기 fallback
  var w = WS_WIDGETS.find(function(x) { return x.id === wid; });
  if (w && w.svg) return w.svg;
  return '<div style="font-size:12px; color:var(--text-secondary); text-align:center; padding:16px;">미리보기 데이터</div>';
}

// 수정 모드 토글
function wdToggleEditMode() {
  var w = _wdCurrentWidget;
  if (!w) return;
  var viewEl = document.getElementById('wd-view-mode');
  var editEl = document.getElementById('wd-edit-mode');
  var saveBtns = document.getElementById('wd-save-btns');
  var toggleBtn = document.getElementById('wd-edit-toggle-btn');

  viewEl.style.display = 'none';
  editEl.style.display = '';
  saveBtns.style.display = 'flex';
  toggleBtn.style.display = 'none';

  // 폼에 현재 값 채우기
  document.getElementById('wd-edit-id').value = w.id;
  document.getElementById('wd-edit-name').value = w.name;
  document.getElementById('wd-edit-icon').value = w.icon;
  document.getElementById('wd-edit-cat').value = w.cat;
  document.getElementById('wd-edit-desc').value = w.desc;
  document.getElementById('wd-edit-color').value = w.color;
  document.getElementById('wd-edit-color-picker').value = w.color;
  document.getElementById('wd-edit-level').value = w.dataLevel;

  // 역할 체크박스
  var allChk = document.getElementById('wd-role-all');
  var roleChks = document.querySelectorAll('.wd-role-chk');
  if (w.roles === 'all') {
    allChk.checked = true;
    roleChks.forEach(function(c) { c.checked = false; c.disabled = true; });
  } else {
    allChk.checked = false;
    roleChks.forEach(function(c) { c.checked = w.roles.indexOf(c.value) !== -1; c.disabled = false; });
  }
}

// 수정 취소 → 읽기 모드
function wdCancelEdit() {
  var viewEl = document.getElementById('wd-view-mode');
  var editEl = document.getElementById('wd-edit-mode');
  var saveBtns = document.getElementById('wd-save-btns');
  var toggleBtn = document.getElementById('wd-edit-toggle-btn');
  if (viewEl) viewEl.style.display = '';
  if (editEl) editEl.style.display = 'none';
  if (saveBtns) saveBtns.style.display = 'none';
  if (toggleBtn) toggleBtn.style.display = '';

  // 원래 위젯으로 미리보기 복원
  if (_wdCurrentWidget) wdRenderPreview(_wdCurrentWidget);
}

// 전체 역할 체크박스 토글
function wdRoleAllToggle(el) {
  var roleChks = document.querySelectorAll('.wd-role-chk');
  roleChks.forEach(function(c) { c.checked = false; c.disabled = el.checked; });
}

// 실시간 미리보기 업데이트 (입력 시마다 호출)
function wdPreviewUpdate() {
  var w = _wdCurrentWidget;
  if (!w) return;
  // 임시 위젯 객체 생성
  var temp = {
    id: w.id,
    name: document.getElementById('wd-edit-name').value || w.name,
    icon: document.getElementById('wd-edit-icon').value || w.icon,
    cat: document.getElementById('wd-edit-cat').value || w.cat,
    desc: document.getElementById('wd-edit-desc').value || w.desc,
    color: document.getElementById('wd-edit-color').value || w.color,
    svg: w.svg
  };
  wdRenderPreview(temp);
  document.getElementById('widget-detail-title').textContent = temp.icon + ' ' + temp.name + ' — 위젯 상세';
}

// 저장: WS_WIDGETS 배열에 반영
function wdSaveWidget() {
  var w = _wdCurrentWidget;
  if (!w) return;
  w.name = document.getElementById('wd-edit-name').value;
  w.icon = document.getElementById('wd-edit-icon').value;
  w.cat = document.getElementById('wd-edit-cat').value;
  w.desc = document.getElementById('wd-edit-desc').value;
  w.color = document.getElementById('wd-edit-color').value;
  w.dataLevel = document.getElementById('wd-edit-level').value;

  // 역할 수집
  var allChk = document.getElementById('wd-role-all');
  if (allChk.checked) {
    w.roles = 'all';
  } else {
    var roles = [];
    document.querySelectorAll('.wd-role-chk:checked').forEach(function(c) { roles.push(c.value); });
    w.roles = roles.length > 0 ? roles : 'all';
  }

  // 읽기 모드로 전환 & 뷰 갱신
  wdCancelEdit();
  wdRenderView(w);
  wdRenderPreview(w);
  document.getElementById('widget-detail-title').textContent = w.icon + ' ' + w.name + ' — 위젯 상세';
  showToast('위젯 "' + w.name + '"이 수정되었습니다. 대시보드에 즉시 반영됩니다.', 'success');
}

// 삭제
function wdDeleteWidget() {
  var w = _wdCurrentWidget;
  if (!w) return;
  if (!confirm('"' + w.name + '" 위젯을 삭제하시겠습니까?')) return;
  var idx = WS_WIDGETS.indexOf(w);
  if (idx !== -1) WS_WIDGETS.splice(idx, 1);
  wsPlacedWidgets = wsPlacedWidgets.filter(function(id) { return id !== w.id; });
  _wdCurrentWidget = null;
  showToast('위젯이 삭제되었습니다.', 'success');
  navigate('sys-widget-template');
}

// ===== 차트 상세보기 =====
function showChartDetail(id) {
  var c = GAL_CHARTS.find(function(x) { return x.id === id; });
  if (!c) { alert('차트를 찾을 수 없습니다.'); return; }
  var domainLabels = { water:'수질·수량', dam:'댐·저수지', supply:'광역상수도', energy:'에너지·발전', env:'환경·기상' };
  var domainColors = { water:{ bg:'#e6f7ff', c:'#1677ff' }, dam:{ bg:'#e6f7ff', c:'#0050b3' }, supply:{ bg:'#e6fffb', c:'#13c2c2' }, energy:{ bg:'#fff7e6', c:'#d48806' }, env:{ bg:'#f6ffed', c:'#389e0d' } };
  var typeLabels = { line:'라인', bar:'바', area:'영역', pie:'파이', gauge:'게이지', heatmap:'히트맵', table:'테이블', donut:'도넛' };
  var roleLabels = { employee:'수공직원', partner:'협력직원', engineer:'엔지니어', admin:'관리자' };
  var ds = domainColors[c.domain] || { bg:'#f5f5f5', c:'#666' };
  var rolesHtml = c.roles === 'all'
    ? '<span style="background:#f6ffed;color:#52c41a;padding:2px 10px;border-radius:4px;font-size:12px;">전체</span>'
    : c.roles.map(function(r) { return '<span style="background:#f0f0f0;color:#555;padding:2px 8px;border-radius:4px;font-size:12px;margin-right:4px;">'+(roleLabels[r]||r)+'</span>'; }).join('');
  var dlLbl = DATA_LEVEL_LABELS[c.dataLevel] || c.dataLevel;
  var dlBg = DATA_LEVEL_BG[c.dataLevel] || '#f5f5f5';
  var dlC = DATA_LEVEL_COLORS[c.dataLevel] || '#666';
  var html = ''
    + '<div class="detail-info-item"><div class="dil">차트 ID</div><div class="div"><code style="background:#f5f5f5;padding:2px 8px;border-radius:4px;font-size:12px;">'+c.id+'</code></div></div>'
    + '<div class="detail-info-item"><div class="dil">차트명</div><div class="div"><strong>'+c.icon+' '+c.name+'</strong></div></div>'
    + '<div class="detail-info-item"><div class="dil">도메인</div><div class="div"><span style="background:'+ds.bg+';color:'+ds.c+';padding:2px 10px;border-radius:4px;font-size:12px;">'+(domainLabels[c.domain]||c.domain)+'</span></div></div>'
    + '<div class="detail-info-item"><div class="dil">차트 유형</div><div class="div"><span style="background:#f5f5f5;color:#666;padding:2px 10px;border-radius:4px;font-size:12px;">'+(typeLabels[c.type]||c.type)+'</span></div></div>'
    + '<div class="detail-info-item"><div class="dil">설명</div><div class="div">'+c.desc+'</div></div>'
    + '<div class="detail-info-item"><div class="dil">접근 역할</div><div class="div">'+rolesHtml+'</div></div>'
    + '<div class="detail-info-item"><div class="dil">데이터등급</div><div class="div"><span style="background:'+dlBg+';color:'+dlC+';padding:2px 10px;border-radius:4px;font-size:12px;font-weight:600;">'+dlLbl+'</span></div></div>'
    + '<div class="detail-info-item"><div class="dil">색상</div><div class="div"><span style="display:inline-block;width:20px;height:20px;border-radius:50%;background:'+c.color+';border:1px solid #ddd;vertical-align:middle;margin-right:6px;"></span>'+c.color+'</div></div>'
    + '<div class="detail-info-item"><div class="dil">작성자</div><div class="div">'+(c.author||'-')+'</div></div>'
    + '<div class="detail-info-item"><div class="dil">등록일</div><div class="div">'+(c.date||'-')+'</div></div>'
    + '<div class="detail-info-item"><div class="dil">좋아요</div><div class="div" style="color:#1967d2;">'+(c.likes||0)+'</div></div>'
    + '<div class="detail-info-item"><div class="dil">추천</div><div class="div">'+(c.recommend ? '✅ 추천 차트' : '—')+'</div></div>'
    + '<div class="detail-info-item"><div class="dil">인기</div><div class="div">'+(c.popular ? '🔥 인기 차트' : '—')+'</div></div>';
  document.getElementById('chart-detail-content').innerHTML = html;
  document.getElementById('chart-detail-title').textContent = c.icon + ' ' + c.name + ' — 차트 상세';
  document.getElementById('chart-detail-edit-btn').onclick = function() { alert('차트 수정: ' + c.id); };
  document.getElementById('chart-detail-delete-btn').onclick = function() { alert('차트 삭제: ' + c.id); };
  // SVG 미리보기
  var previewCard = document.getElementById('chart-detail-preview-card');
  var previewDiv = document.getElementById('chart-detail-preview');
  if (c.svg) {
    previewCard.style.display = '';
    previewDiv.innerHTML = '<div style="max-width:360px;margin:0 auto;border:1px solid #eee;border-radius:8px;padding:16px;background:#fafafa;">' + c.svg + '</div>';
  } else {
    previewCard.style.display = 'none';
  }
  navigate('dist-chart-content-detail');
}

function openUserDetail(data) {
  var roleColors = {
    '시스템관리자': { bg: '#e8f0fe', c: '#1967d2' }, '데이터관리자': { bg: '#e0f7fa', c: '#00838f' },
    '데이터엔지니어': { bg: '#fff3e0', c: '#ef6c00' }, '일반사용자': { bg: '#f3e5f5', c: '#7b1fa2' },
    '외부사용자': { bg: '#fce4ec', c: '#c62828' }
  };
  var rc = roleColors[data.role] || { bg: '#f5f5f5', c: '#666' };
  var statusMap = { '활성': 'badge-success', '비활성': 'badge-ghost', '잠김': 'badge-error' };
  var statusCls = statusMap[data.status] || 'badge-ghost';
  var ssoLabel = data.sso === 'Y' ? '<span style="background:#e8f5e9;color:#2e7d32;padding:2px 8px;border-radius:4px;font-size:11px;font-weight:600;">연동완료</span>' : '<span style="background:#ffebee;color:#c62828;padding:2px 8px;border-radius:4px;font-size:11px;font-weight:600;">미연동</span>';
  var firstChar = data.name.charAt(0);

  var el = function(id) { return document.getElementById(id); };
  el('ud-name').textContent = data.name;
  el('ud-empNo').textContent = data.empNo;
  el('ud-dept').textContent = data.dept;
  el('ud-grade').textContent = data.grade;
  el('ud-email').textContent = data.empNo.toLowerCase() + '@kwater.or.kr';
  el('ud-joinDate').textContent = data.joinDate;
  el('ud-sso').innerHTML = ssoLabel;
  el('ud-name2').textContent = data.name;
  el('ud-dept2').textContent = data.dept + ' · ' + data.grade;
  el('ud-statusBadge').className = 'badge ' + statusCls;
  el('ud-statusBadge').style.fontSize = '11px';
  el('ud-statusBadge').textContent = data.status;
  el('ud-lastLogin').textContent = data.lastLogin === '-' ? '-' : '2026-' + data.lastLogin;

  // 아바타 첫글자
  var avatar = document.querySelector('#screen-sys-user-detail [style*="border-radius:50%"][style*="64px"]');
  if (avatar) avatar.textContent = firstChar;

  // 역할 테이블 (해제 버튼에 onclick 바인딩)
  window._currentUserDetail = data;
  var roleLevel = data.role === '시스템관리자' ? '5' : data.role === '데이터관리자' ? '4' : data.role === '데이터엔지니어' ? '3' : data.role === '외부사용자' ? '1' : '2';
  el('ud-roles').innerHTML =
    '<tr><td><span style="background:' + rc.bg + ';color:' + rc.c + ';padding:2px 8px;border-radius:4px;font-size:11px;font-weight:600;">' + data.role + '</span></td>' +
    '<td>Level ' + roleLevel + '</td>' +
    '<td>' + data.joinDate + '</td><td>관리자</td>' +
    '<td><button class="btn btn-outline btn-sm" style="font-size:10px;padding:1px 6px;color:#ef4444;border-color:#ef4444;" data-perm="admin" onclick="removeUserRole(this,\'' + data.role + '\')">해제</button></td></tr>' +
    '<tr><td><span style="background:#f3e5f5;color:#7b1fa2;padding:2px 8px;border-radius:4px;font-size:11px;font-weight:600;">일반사용자</span></td>' +
    '<td>Level 1</td><td>' + data.joinDate + '</td><td>SYSTEM</td><td><span style="font-size:10px;color:#999;">기본역할</span></td></tr>';

  navigate('sys-user-detail');
}

function initSystemGrids() {
  // 사용자관리
  initAGGrid('ag-grid-sys-user', [
    { field: 'name', headerName: '이름', flex: 1, cellRenderer: function (p) { return '<strong>' + p.value + '</strong>'; } },
    { field: 'empNo', headerName: '사번', width: 80, cellStyle: { fontFamily: 'monospace', color: '#666' } },
    { field: 'dept', headerName: '부서', width: 110 },
    { field: 'grade', headerName: '직급', width: 70 },
    {
      field: 'role', headerName: '역할', width: 105, cellRenderer: function (p) {
        var m = { '시스템관리자': { bg: '#e8f0fe', c: '#1967d2' }, '데이터관리자': { bg: '#e0f7fa', c: '#00838f' }, '데이터엔지니어': { bg: '#fff3e0', c: '#ef6c00' }, '일반사용자': { bg: '#f3e5f5', c: '#7b1fa2' }, '외부사용자': { bg: '#fce4ec', c: '#c62828' } };
        var s = m[p.value] || { bg: '#f5f5f5', c: '#666' };
        return '<span style="background:' + s.bg + ';color:' + s.c + ';padding:2px 8px;border-radius:4px;font-size:11px;font-weight:600;">' + p.value + '</span>';
      }
    },
    {
      field: 'access', headerName: '접근등급', width: 90, cellRenderer: function (p) {
        var m = { '전체': { bg: '#e8f5e9', c: '#2e7d32' }, '할당됨': { bg: '#e8f0fe', c: '#1967d2' }, '등급별': { bg: '#fff3e0', c: '#ef6c00' }, '3등급만': { bg: '#ffebee', c: '#c62828' }, '대기': { bg: '#f5f5f5', c: '#999' } };
        var s = m[p.value] || { bg: '#f5f5f5', c: '#666' };
        return '<span style="background:' + s.bg + ';color:' + s.c + ';padding:2px 6px;border-radius:4px;font-size:11px;">' + p.value + '</span>';
      }
    },
    {
      field: 'status', headerName: '상태', width: 85, cellRenderer: function (p) {
        var m = { '활성': { bg: '#e8f5e9', c: '#2e7d32', dot: '#52c41a' }, '비활성': { bg: '#f5f5f5', c: '#999', dot: '#bbb' }, '승인대기': { bg: '#fff8e1', c: '#d48806', dot: '#faad14' }, '잠김': { bg: '#ffebee', c: '#c62828', dot: '#ff4d4f' } };
        var s = m[p.value] || { bg: '#f5f5f5', c: '#666', dot: '#999' };
        return '<span style="display:inline-flex;align-items:center;gap:4px;background:' + s.bg + ';color:' + s.c + ';padding:2px 8px;border-radius:4px;font-size:11px;"><span style="width:6px;height:6px;border-radius:50%;background:' + s.dot + ';"></span>' + p.value + '</span>';
      }
    },
    {
      field: 'sso', headerName: 'SSO', width: 55, cellRenderer: function (p) {
        if (p.value === 'Y') return '<span style="background:#e8f5e9;color:#2e7d32;padding:1px 6px;border-radius:3px;font-size:10px;font-weight:700;">Y</span>';
        if (p.value === 'N') return '<span style="background:#ffebee;color:#c62828;padding:1px 6px;border-radius:3px;font-size:10px;font-weight:700;">N</span>';
        return '<span style="color:#ccc;font-size:10px;">-</span>';
      }
    },
    { field: 'lastLogin', headerName: '최종로그인', width: 100 },
    { field: 'joinDate', headerName: '가입일', width: 90 },
    {
      field: 'action', headerName: '관리', width: 65, sortable: false, filter: false, cellRenderer: function (p) {
        if (p.data.status === '승인대기') return '<button class="btn btn-primary" style="padding:1px 6px;font-size:11px;">승인</button>';
        return '<button class="btn btn-outline" style="padding:1px 6px;font-size:11px;">⚙</button>';
      }
    }
  ], [
    { name: '관리자 (admin)', empNo: 'KW0001', dept: '정보화추진단', grade: '부장', role: '시스템관리자', access: '전체', status: '활성', sso: 'Y', lastLogin: '02-28 11:42', joinDate: '2024-01-01' },
    { name: '박수원', empNo: 'KW1024', dept: '수자원관리팀', grade: '차장', role: '데이터관리자', access: '전체', status: '활성', sso: 'Y', lastLogin: '02-28 10:15', joinDate: '2024-03-15' },
    { name: '김데이터', empNo: 'KW2048', dept: '데이터분석팀', grade: '대리', role: '데이터엔지니어', access: '할당됨', status: '활성', sso: 'Y', lastLogin: '02-28 09:30', joinDate: '2024-05-20' },
    { name: '이분석', empNo: 'KW1536', dept: '경영기획팀', grade: '과장', role: '일반사용자', access: '등급별', status: '활성', sso: 'Y', lastLogin: '02-27 16:45', joinDate: '2024-07-01' },
    { name: '최외부', empNo: 'EX0012', dept: '외부 (환경부)', grade: '-', role: '외부사용자', access: '3등급만', status: '활성', sso: 'N', lastLogin: '02-26 14:20', joinDate: '2025-01-10' },
    { name: '한에너지', empNo: 'KW3072', dept: '수력발전팀', grade: '대리', role: '데이터엔지니어', access: '할당됨', status: '활성', sso: 'Y', lastLogin: '02-28 08:50', joinDate: '2024-09-01' },
    { name: '장수질', empNo: 'KW2560', dept: '수질관리팀', grade: '과장', role: '데이터관리자', access: '전체', status: '활성', sso: 'Y', lastLogin: '02-27 17:30', joinDate: '2024-04-15' },
    { name: '오계측', empNo: 'KW4096', dept: '인프라운영팀', grade: '주임', role: '데이터엔지니어', access: '할당됨', status: '활성', sso: 'Y', lastLogin: '02-28 07:20', joinDate: '2025-02-01' },
    { name: '윤상수', empNo: 'KW1792', dept: '수도사업팀', grade: '차장', role: '일반사용자', access: '등급별', status: '활성', sso: 'Y', lastLogin: '02-25 15:10', joinDate: '2024-06-01' },
    { name: '정탈퇴', empNo: 'KW0512', dept: '수도사업팀', grade: '대리', role: '일반사용자', access: '-', status: '비활성', sso: 'Y', lastLogin: '12-01 08:00', joinDate: '2024-02-01' },
    { name: '홍신규', empNo: 'KW5120', dept: 'AI연구팀', grade: '주임', role: '데이터엔지니어', access: '대기', status: '승인대기', sso: '-', lastLogin: '-', joinDate: '신청중' },
    { name: '서인프라', empNo: 'KW4608', dept: '인프라운영팀', grade: '사원', role: '일반사용자', access: '대기', status: '승인대기', sso: '-', lastLogin: '-', joinDate: '신청중' }
  ], {
    domLayout: 'autoHeight',
    getRowStyle: function (params) {
      if (params.data.status === '승인대기') return { background: '#fffbe6' };
      if (params.data.status === '비활성' || params.data.status === '잠김') return { background: '#fafafa' };
      return null;
    },
    onCellClicked: function (e) {
      if (e.colDef.field === 'action') {
        if (e.data.status === '승인대기') {
          openApproveModal(e.data);
        } else {
          openUserDetail(e.data);
        }
      }
    }
  });

  // 데이터등급·보안정책 자산 목록
  initAGGrid('ag-grid-sys-security', [
    { field: 'name', headerName: '자산명', flex: 1, cellRenderer: function (p) { return '<strong>' + p.value + '</strong>'; } },
    {
      field: 'grade', headerName: '등급', width: 90, cellRenderer: function (p) {
        var m = { '1등급': { bg: '#ffebee', c: '#c62828' }, '2등급': { bg: '#fff3e0', c: '#ef6c00' }, '3등급': { bg: '#e8f5e9', c: '#2e7d32' } };
        var s = m[p.value] || { bg: '#f5f5f5', c: '#666' };
        return '<span style="background:' + s.bg + ';color:' + s.c + ';padding:2px 8px;border-radius:4px;font-size:11px;font-weight:700;">' + p.value + '</span>';
      }
    },
    {
      field: 'category', headerName: '분류', width: 75, cellRenderer: function (p) {
        var m = { '테이블': { bg: '#e8f0fe', c: '#1967d2' }, 'API': { bg: '#f9f0ff', c: '#722ed1' }, '파일': { bg: '#fff8e1', c: '#d48806' }, '스트림': { bg: '#e0f7fa', c: '#00838f' } };
        var s = m[p.value] || { bg: '#f5f5f5', c: '#666' };
        return '<span style="background:' + s.bg + ';color:' + s.c + ';padding:2px 6px;border-radius:4px;font-size:11px;">' + p.value + '</span>';
      }
    },
    {
      field: 'domain', headerName: '도메인', width: 80, cellRenderer: function (p) {
        var m = { '수자원': { bg: '#e3f2fd', c: '#1565c0' }, '상수도': { bg: '#e0f7fa', c: '#00838f' }, '수질': { bg: '#e8f5e9', c: '#2e7d32' }, '에너지': { bg: '#fff8e1', c: '#f57f17' }, '고객': { bg: '#f3e5f5', c: '#7b1fa2' }, '계측': { bg: '#fce4ec', c: '#c62828' } };
        var s = m[p.value] || { bg: '#f5f5f5', c: '#666' };
        return '<span style="background:' + s.bg + ';color:' + s.c + ';padding:2px 6px;border-radius:4px;font-size:11px;">' + p.value + '</span>';
      }
    },
    {
      field: 'encryption', headerName: '암호화', width: 85, cellRenderer: function (p) {
        if (p.value === 'AES-256') return '<span style="background:#ffebee;color:#c62828;padding:2px 6px;border-radius:4px;font-size:10px;font-weight:700;">AES-256</span>';
        if (p.value === 'TLS') return '<span style="background:#e8f0fe;color:#1967d2;padding:2px 6px;border-radius:4px;font-size:10px;font-weight:700;">TLS</span>';
        return '<span style="color:#ccc;font-size:10px;">-</span>';
      }
    },
    { field: 'accessRole', headerName: '접근역할', width: 110, cellStyle: { fontSize: '11px' } },
    {
      field: 'accessCount', headerName: '금월접근', width: 80, type: 'numericColumn', cellRenderer: function (p) {
        var v = parseInt(p.value);
        var c = v > 500 ? '#c62828' : v > 100 ? '#ef6c00' : '#2e7d32';
        return '<span style="color:' + c + ';font-weight:700;font-family:monospace;">' + p.value + '</span>';
      }
    },
    { field: 'lastAccess', headerName: '최근접근', width: 90 },
    {
      field: 'violation', headerName: '위반', width: 55, cellRenderer: function (p) {
        if (p.value > 0) return '<span style="background:#ffebee;color:#c62828;padding:1px 6px;border-radius:4px;font-size:11px;font-weight:700;">' + p.value + '</span>';
        return '<span style="color:#ccc;font-size:10px;">0</span>';
      }
    },
    {
      field: 'status', headerName: '상태', width: 80, cellRenderer: function (p) {
        var m = { '정상': { bg: '#e8f5e9', c: '#2e7d32', dot: '#52c41a' }, '주의': { bg: '#fff8e1', c: '#d48806', dot: '#faad14' }, '위반': { bg: '#ffebee', c: '#c62828', dot: '#ff4d4f' }, '검토중': { bg: '#e8f0fe', c: '#1967d2', dot: '#1677ff' } };
        var s = m[p.value] || { bg: '#f5f5f5', c: '#666', dot: '#999' };
        return '<span style="display:inline-flex;align-items:center;gap:4px;background:' + s.bg + ';color:' + s.c + ';padding:2px 8px;border-radius:4px;font-size:11px;"><span style="width:6px;height:6px;border-radius:50%;background:' + s.dot + ';"></span>' + p.value + '</span>';
      }
    }
  ], [
    { name: 'SAP 인사급여 테이블', grade: '1등급', category: '테이블', domain: '고객', encryption: 'AES-256', accessRole: '시스템관리자', accessCount: '24', lastAccess: '02-28 14:20', violation: 1, status: '주의' },
    { name: '고객 개인정보 DB', grade: '1등급', category: '테이블', domain: '고객', encryption: 'AES-256', accessRole: '시스템관리자', accessCount: '18', lastAccess: '02-28 11:05', violation: 0, status: '정상' },
    { name: '보안감사 로그파일', grade: '1등급', category: '파일', domain: '계측', encryption: 'AES-256', accessRole: '시스템관리자', accessCount: '8', lastAccess: '02-27 16:30', violation: 0, status: '정상' },
    { name: '수자원관측 실시간DB', grade: '2등급', category: '테이블', domain: '수자원', encryption: 'TLS', accessRole: '데이터관리자↑', accessCount: '842', lastAccess: '02-28 15:00', violation: 1, status: '주의' },
    { name: '상수도 운영 API', grade: '2등급', category: 'API', domain: '상수도', encryption: 'TLS', accessRole: '데이터관리자↑', accessCount: '1,256', lastAccess: '02-28 14:58', violation: 0, status: '정상' },
    { name: '발전량 실시간 스트림', grade: '2등급', category: '스트림', domain: '에너지', encryption: 'TLS', accessRole: '데이터엔지니어↑', accessCount: '3,480', lastAccess: '02-28 15:01', violation: 0, status: '정상' },
    { name: '수질측정 운영 데이터', grade: '2등급', category: '테이블', domain: '수질', encryption: 'TLS', accessRole: '데이터관리자↑', accessCount: '624', lastAccess: '02-28 13:40', violation: 1, status: '위반' },
    { name: '공개 수문통계 API', grade: '3등급', category: 'API', domain: '수자원', encryption: '-', accessRole: '전체 (외부)', accessCount: '4,210', lastAccess: '02-28 15:02', violation: 0, status: '정상' },
    { name: '환경측정 공개 데이터', grade: '3등급', category: '파일', domain: '수질', encryption: '-', accessRole: '전체 (외부)', accessCount: '2,890', lastAccess: '02-28 14:50', violation: 0, status: '정상' },
    { name: 'IoT 센서현황 대시보드', grade: '3등급', category: '스트림', domain: '계측', encryption: '-', accessRole: '전체 (외부)', accessCount: '1,520', lastAccess: '02-28 14:45', violation: 0, status: '검토중' }
  ], {
    domLayout: 'autoHeight',
    getRowStyle: function (params) {
      if (params.data.status === '위반') return { background: '#fff5f5' };
      if (params.data.status === '주의') return { background: '#fffbe6' };
      return null;
    }
  });

  // 연계인터페이스 모니터링
  initAGGrid('ag-grid-sys-interface', [
    { field: 'name', headerName: '인터페이스', flex: 1, cellRenderer: function (p) { return '<strong>' + p.value + '</strong>'; } },
    { field: 'type', headerName: '유형', width: 80, cellRenderer: function (p) { return '<span style="background:' + p.data.typeBg + ';color:' + p.data.typeColor + ';padding:1px 8px;border-radius:4px;font-size:11px;">' + p.value + '</span>'; } },
    {
      field: 'status', headerName: '상태', width: 80, cellRenderer: function (p) {
        var c = p.value === '정상' ? '#4caf50' : '#f44336';
        return '<span style="display:inline-flex;align-items:center;gap:4px;font-size:11px;"><span style="width:6px;height:6px;border-radius:50%;background:' + c + ';display:inline-block;"></span>' + p.value + '</span>';
      }
    },
    { field: 'latency', headerName: 'Latency', width: 85 },
    { field: 'uptime', headerName: 'Uptime', width: 75 },
    { field: 'lastSync', headerName: '최근 동기화', width: 110 },
    { field: 'action', headerName: '관리', width: 70, sortable: false, filter: false, cellRenderer: function () { return '<button class="btn btn-outline" style="padding:1px 6px;font-size:11px;" onclick="navigate(\'sys-interface-detail\')">상세</button>'; } }
  ], [
    { name: 'MCP 연동', type: 'MCP', typeBg: '#e8f0fe', typeColor: '#1967d2', status: '정상', latency: '120ms', uptime: '99.5%', lastSync: '11:42' },
    { name: '내부 API 게이트웨이', type: 'REST', typeBg: '#e8f5e9', typeColor: '#2e7d32', status: '정상', latency: '35ms', uptime: '99.9%', lastSync: '11:42' },
    { name: '외부 API 게이트웨이', type: 'REST', typeBg: '#e8f5e9', typeColor: '#2e7d32', status: '정상', latency: '85ms', uptime: '99.8%', lastSync: '11:42' },
    { name: 'SSO 인증서버', type: 'SAML', typeBg: '#f3e5f5', typeColor: '#7b1fa2', status: '정상', latency: '45ms', uptime: '99.99%', lastSync: '11:42' },
    { name: 'DMZ 프록시', type: 'Proxy', typeBg: '#fff3e0', typeColor: '#ef6c00', status: '정상', latency: '12ms', uptime: '99.95%', lastSync: '11:42' },
    { name: 'Kafka Broker', type: 'Kafka', typeBg: '#fce4ec', typeColor: '#c62828', status: '정상', latency: '8ms', uptime: '99.99%', lastSync: '11:42' }
  ]);

  // API 호출 이력
  initAGGrid('ag-grid-sys-api-log', [
    { field: 'time', headerName: '시각', width: 80 },
    {
      field: 'method', headerName: 'Method', width: 105, cellRenderer: function (p) {
        var c = p.value === 'GET' ? '#1967d2' : '#4caf50';
        return '<span style="color:' + c + ';font-weight:600;">' + p.value + '</span>';
      }
    },
    { field: 'endpoint', headerName: 'Endpoint', flex: 1, cellStyle: { fontFamily: 'monospace', fontSize: '11px' } },
    {
      field: 'statusCode', headerName: 'Status', width: 75, cellRenderer: function (p) {
        var c = p.value >= 400 ? '#f44336' : '#333';
        return '<span style="color:' + c + ';font-weight:' + (p.value >= 400 ? '700' : '400') + ';">' + p.value + '</span>';
      }
    },
    { field: 'latency', headerName: 'Latency', width: 85 },
    { field: 'size', headerName: '응답크기', width: 96 },
    {
      field: 'result', headerName: '결과', width: 75, cellRenderer: function (p) {
        if (p.value === '성공') return '<span style="color:#4caf50;">✅ 성공</span>';
        return '<span style="color:#f44336;">❌ ' + p.value + '</span>';
      }
    }
  ], [
    { time: '11:42:15', method: 'GET', endpoint: '/api/v2/resources/list', statusCode: 200, latency: '118ms', size: '24.5KB', result: '성공' },
    { time: '11:42:10', method: 'POST', endpoint: '/api/v2/tools/execute', statusCode: 200, latency: '245ms', size: '8.2KB', result: '성공' },
    { time: '11:41:58', method: 'GET', endpoint: '/api/v2/prompts/search', statusCode: 200, latency: '89ms', size: '12.1KB', result: '성공' },
    { time: '11:41:42', method: 'POST', endpoint: '/api/v2/tools/execute', statusCode: 200, latency: '312ms', size: '15.7KB', result: '성공' },
    { time: '11:41:30', method: 'GET', endpoint: '/api/v2/health', statusCode: 200, latency: '12ms', size: '0.3KB', result: '성공' },
    { time: '11:40:55', method: 'POST', endpoint: '/api/v2/tools/execute', statusCode: 504, latency: '30,012ms', size: '0KB', result: '타임아웃' },
    { time: '11:40:20', method: 'GET', endpoint: '/api/v2/resources/list', statusCode: 200, latency: '105ms', size: '24.5KB', result: '성공' },
    { time: '11:39:58', method: 'POST', endpoint: '/api/v2/tools/execute', statusCode: 200, latency: '198ms', size: '6.4KB', result: '성공' }
  ], { getRowStyle: function (p) { if (p.data.statusCode >= 400) return { background: '#fff5f5' }; } });

  // 감사로그 (sys-audit) — 10컬럼×12행
  initAGGrid('ag-grid-sys-audit', [
    { field: 'time', headerName: '시간', width: 80, cellStyle: { fontSize:'12px', color:'#888', fontFamily:'monospace' } },
    { field: 'user', headerName: '사용자', width: 80, cellRenderer: function(p) { return '<strong>'+p.value+'</strong>'; } },
    { field: 'dept', headerName: '부서', width: 80, cellStyle: { fontSize:'11px', color:'#888' } },
    { field: 'type', headerName: '유형', width: 72, cellRenderer: function(p) {
      var m = { '데이터':{bg:'#e8f0fe',c:'#1967d2'}, '수집':{bg:'#e8f5e9',c:'#2e7d32'}, '유통':{bg:'#fff3e0',c:'#ef6c00'}, '접속':{bg:'#f3e5f5',c:'#7b1fa2'}, '시스템':{bg:'#e0f7fa',c:'#00838f'}, '권한':{bg:'#fce4ec',c:'#c62828'}, '배치':{bg:'#f1f8e9',c:'#558b2f'}, 'API':{bg:'#e8eaf6',c:'#3949ab'} };
      var s = m[p.value] || {bg:'#f5f5f5',c:'#666'};
      return '<span style="background:'+s.bg+';color:'+s.c+';padding:1px 8px;border-radius:4px;font-size:11px;font-weight:600;">'+p.value+'</span>';
    }},
    { field: 'activity', headerName: '활동 내용', flex: 2, minWidth: 200 },
    { field: 'entity', headerName: '대상 엔티티', width: 130, cellRenderer: function(p) {
      if (!p.value || p.value === '-') return '<span style="color:#ccc;">-</span>';
      return '<code style="background:#f5f5f5;padding:1px 6px;border-radius:3px;font-size:11px;">'+p.value+'</code>';
    }},
    { field: 'ip', headerName: 'IP', width: 90, cellStyle: { fontFamily:'monospace', fontSize:'11px', color:'#888' } },
    { field: 'result', headerName: '결과', width: 70, cellRenderer: function(p) {
      if (p.value === '성공') return '<span style="color:#4caf50;font-weight:600;font-size:11px;">✅ 성공</span>';
      if (p.value === '차단') return '<span style="color:#f44336;font-weight:600;font-size:11px;">🚫 차단</span>';
      if (p.value === '경고') return '<span style="color:#ff9800;font-weight:600;font-size:11px;">⚠️ 경고</span>';
      return p.value;
    }},
    { field: 'risk', headerName: '위험도', width: 72, cellRenderer: function(p) {
      var m = { '높음':{bg:'#fff1f0',c:'#cf1322'}, '보통':{bg:'#fff7e6',c:'#d48806'}, '낮음':{bg:'#f6ffed',c:'#389e0d'} };
      var s = m[p.value] || {bg:'#f5f5f5',c:'#666'};
      return '<span style="background:'+s.bg+';color:'+s.c+';padding:2px 8px;border-radius:4px;font-size:10px;font-weight:600;">'+p.value+'</span>';
    }},
    { field: 'detail', headerName: '상세', width: 60, sortable: false, filter: false, cellRenderer: function() { return '<button class="btn btn-outline" style="padding:1px 5px;font-size:10px;">보기</button>'; } }
  ], [
    { time: '11:42:30', user: '박수원', dept: '수자원부', type: '데이터', activity: 'TB_WATER_LEVEL 메타데이터 수정 (설명필드 업데이트)', entity: 'TB_WATER_LEVEL', ip: '10.x.x.42', result: '성공', risk: '낮음' },
    { time: '11:41:22', user: '김데이터', dept: '정보화팀', type: '수집', activity: '스마트미터 CDC 파이프라인 스케줄 변경 (1초→3초)', entity: 'CDC_SMART_METER', ip: '10.x.x.15', result: '성공', risk: '보통' },
    { time: '11:40:55', user: '박수원', dept: '수자원부', type: 'API', activity: 'REST API /api/v2/water-level 호출 (데이터 조회)', entity: 'API_WATER_LEVEL', ip: '10.x.x.42', result: '성공', risk: '낮음' },
    { time: '11:30:00', user: '이분석', dept: '분석팀', type: '유통', activity: '수질데이터 API 활용신청 (REQ-042)', entity: 'TB_QUALITY_MEAS', ip: '10.x.x.88', result: '성공', risk: '낮음' },
    { time: '11:15:45', user: '최외부', dept: '환경부(외)', type: '접속', activity: '외부사용자 로그인 (환경부, IP: 211.x.x.55)', entity: '-', ip: '211.x.x.55', result: '성공', risk: '보통' },
    { time: '10:58:12', user: 'admin', dept: '시스템', type: '시스템', activity: 'Neo4j 클러스터 메모리캐시 설정변경 (TTL: 1h→30m)', entity: 'NEO4J_CLUSTER', ip: '10.x.x.1', result: '성공', risk: '보통' },
    { time: '10:45:00', user: '정탈퇴', dept: '-', type: '접속', activity: '비활성 계정 로그인 시도 (차단됨)', entity: '-', ip: '10.x.x.99', result: '차단', risk: '높음' },
    { time: '10:30:15', user: 'admin', dept: '시스템', type: '권한', activity: '홍신규 계정생성 요청 검토 → 승인처리', entity: 'USER_ACCOUNT', ip: '10.x.x.1', result: '성공', risk: '보통' },
    { time: '10:15:00', user: '김데이터', dept: '정보화팀', type: '데이터', activity: 'TB_WATER_LEVEL 컬럼 3개 추가 (WARN_LV, ALT_LV, CHK_DT)', entity: 'TB_WATER_LEVEL', ip: '10.x.x.15', result: '성공', risk: '보통' },
    { time: '09:30:00', user: 'admin', dept: '시스템', type: '데이터', activity: 'TB_WATER_LEVEL 인덱스 재구성', entity: 'TB_WATER_LEVEL', ip: '10.x.x.1', result: '성공', risk: '낮음' },
    { time: '09:00:00', user: 'system', dept: '시스템', type: '배치', activity: 'SAP 재무 일배치 수집 완료: 48,231건 처리', entity: 'TB_SAP_FI_DOC', ip: 'system', result: '성공', risk: '낮음' },
    { time: '08:00:00', user: 'system', dept: '시스템', type: '배치', activity: 'DQ 품질검증 자동실행 (48규칙, 156회)', entity: 'DQ_ENGINE', ip: 'system', result: '경고', risk: '보통' }
  ], {
    domLayout: 'autoHeight',
    getRowStyle: function(p) {
      if (p.data.result === '차단') return { background: '#fff5f5' };
      if (p.data.risk === '높음') return { background: '#fff5f5' };
    },
    onCellClicked: function(e) {
      if (e.colDef.field === 'detail') openAuditDetail(e.data);
    }
  });

  // K8S 인프라 모니터링
  initAGGrid('ag-grid-sys-k8s', [
    { field: 'pod', headerName: 'Pod 이름', flex: 1.5, cellRenderer: function(p) { return '<span style="font-family:monospace; font-size:11px; font-weight:600;">' + p.value + '</span>'; } },
    { field: 'namespace', headerName: 'Namespace', width: 130, cellRenderer: function(p) {
      var m = { 'datahub-agent': { bg:'#e8f0fe', c:'#1967d2' }, 'datahub-platform': { bg:'#e8f5e9', c:'#2e7d32' }, 'datahub-ontology': { bg:'#fff3e0', c:'#ef6c00' } };
      var s = m[p.value] || { bg:'#f5f5f5', c:'#666' };
      return '<span style="background:'+s.bg+';color:'+s.c+';padding:2px 8px;border-radius:4px;font-size:11px;">'+p.value+'</span>';
    }},
    { field: 'status', headerName: '상태', width: 110, cellRenderer: function(p) {
      var m = { 'Running': { bg:'#e8f5e9', c:'#2e7d32', dot:'#52c41a' }, 'Pending': { bg:'#fff8e1', c:'#d48806', dot:'#faad14' }, 'CrashLoopBackOff': { bg:'#ffebee', c:'#c62828', dot:'#ff4d4f' }, 'Completed': { bg:'#f5f5f5', c:'#666', dot:'#bbb' } };
      var s = m[p.value] || { bg:'#f5f5f5', c:'#666', dot:'#999' };
      return '<span style="display:inline-flex;align-items:center;gap:4px;background:'+s.bg+';color:'+s.c+';padding:2px 8px;border-radius:4px;font-size:11px;"><span style="width:6px;height:6px;border-radius:50%;background:'+s.dot+';"></span>'+p.value+'</span>';
    }},
    { field: 'cpu', headerName: 'CPU', width: 75, cellRenderer: function(p) {
      var c = parseInt(p.value) > 70 ? '#ff4d4f' : parseInt(p.value) > 50 ? '#fa8c16' : '#52c41a';
      return '<span style="color:'+c+';font-weight:600;">'+p.value+'</span>';
    }},
    { field: 'mem', headerName: 'Memory', width: 80, cellRenderer: function(p) {
      var c = parseInt(p.value) > 70 ? '#ff4d4f' : parseInt(p.value) > 50 ? '#fa8c16' : '#52c41a';
      return '<span style="color:'+c+';font-weight:600;">'+p.value+'</span>';
    }},
    { field: 'restarts', headerName: 'Restarts', width: 80, cellRenderer: function(p) {
      return p.value > 0 ? '<span style="color:#fa8c16; font-weight:600;">'+p.value+'</span>' : '<span style="color:#52c41a;">0</span>';
    }},
    { field: 'age', headerName: 'Age', width: 80 },
    { field: 'node', headerName: 'Node', width: 100, cellStyle: { fontSize:'11px', color:'#888' } }
  ], [
    { pod: 'agent-api-6f8d4b-xk2m1', namespace: 'datahub-agent', status: 'Running', cpu: '35%', mem: '52%', restarts: 0, age: '12h', node: 'k8s-node-01' },
    { pod: 'agent-api-6f8d4b-np3q2', namespace: 'datahub-agent', status: 'Running', cpu: '41%', mem: '58%', restarts: 0, age: '12h', node: 'k8s-node-02' },
    { pod: 'agent-worker-7a9e3c-jt4r5', namespace: 'datahub-agent', status: 'Running', cpu: '28%', mem: '44%', restarts: 0, age: '12h', node: 'k8s-node-03' },
    { pod: 'platform-api-5d2c1a-mv8k3', namespace: 'datahub-platform', status: 'Running', cpu: '55%', mem: '68%', restarts: 0, age: '1d', node: 'k8s-node-01' },
    { pod: 'platform-api-5d2c1a-bw6n4', namespace: 'datahub-platform', status: 'Running', cpu: '48%', mem: '65%', restarts: 0, age: '1d', node: 'k8s-node-02' },
    { pod: 'platform-api-5d2c1a-qs9p7', namespace: 'datahub-platform', status: 'Running', cpu: '52%', mem: '71%', restarts: 1, age: '1d', node: 'k8s-node-03' },
    { pod: 'platform-worker-8b4f2e-ht5m6', namespace: 'datahub-platform', status: 'Running', cpu: '44%', mem: '59%', restarts: 0, age: '1d', node: 'k8s-node-04' },
    { pod: 'platform-scheduler-3c7a1d-lr2k8', namespace: 'datahub-platform', status: 'Running', cpu: '18%', mem: '32%', restarts: 0, age: '1d', node: 'k8s-node-04' },
    { pod: 'ontology-api-9e6b3f-wm4j1', namespace: 'datahub-ontology', status: 'Running', cpu: '32%', mem: '68%', restarts: 0, age: '4d', node: 'k8s-node-05' },
    { pod: 'ontology-api-9e6b3f-dx7h2', namespace: 'datahub-ontology', status: 'Running', cpu: '38%', mem: '74%', restarts: 0, age: '4d', node: 'k8s-node-06' },
    { pod: 'ontology-worker-2c8a5g-fy3n9', namespace: 'datahub-ontology', status: 'CrashLoopBackOff', cpu: '0%', mem: '0%', restarts: 3, age: '4d', node: 'k8s-node-05' },
    { pod: 'ontology-indexer-4d1e7h-zp6m3', namespace: 'datahub-ontology', status: 'Pending', cpu: '0%', mem: '0%', restarts: 0, age: '2m', node: '-' }
  ], {
    getRowStyle: function(p) {
      if (p.data.status === 'CrashLoopBackOff') return { background: '#fff5f5' };
      if (p.data.status === 'Pending') return { background: '#fffbe6' };
    }
  });

  // ===== ERP 인사정보 동기화 - 동기화 이력 =====
  initAGGrid('ag-grid-sys-erp-sync', [
    { field: 'syncId', headerName: '동기화ID', width: 110, cellStyle: { fontFamily: 'monospace', color: '#666' } },
    { field: 'execTime', headerName: '실행시각', width: 130 },
    { field: 'syncType', headerName: '유형', width: 90, cellRenderer: function(p) {
        var m = { '전체': { bg:'#e8f0fe', c:'#1967d2' }, '증분': { bg:'#e0f7fa', c:'#00838f' }, 'CDC': { bg:'#f9f0ff', c:'#722ed1' } };
        var s = m[p.value] || { bg:'#f5f5f5', c:'#666' };
        return '<span style="background:'+s.bg+';color:'+s.c+';padding:2px 8px;border-radius:4px;font-size:11px;font-weight:600;">'+p.value+'</span>';
      }
    },
    { field: 'target', headerName: '대상', width: 80, cellRenderer: function(p) {
        var m = { '인사': { bg:'#e8f5e9', c:'#2e7d32' }, '조직': { bg:'#fff3e0', c:'#ef6c00' }, '겸직': { bg:'#fce4ec', c:'#c62828' } };
        var s = m[p.value] || { bg:'#f5f5f5', c:'#666' };
        return '<span style="background:'+s.bg+';color:'+s.c+';padding:2px 6px;border-radius:4px;font-size:11px;">'+p.value+'</span>';
      }
    },
    { field: 'totalCount', headerName: '처리건수', width: 80, type: 'numericColumn', cellStyle: { fontWeight: '600' } },
    { field: 'newCount', headerName: '신규', width: 60, type: 'numericColumn', cellRenderer: function(p) {
        return p.value > 0 ? '<span style="color:#1677ff;font-weight:600;">+'+p.value+'</span>' : '<span style="color:#ccc;">0</span>';
      }
    },
    { field: 'changeCount', headerName: '변경', width: 60, type: 'numericColumn', cellRenderer: function(p) {
        return p.value > 0 ? '<span style="color:#fa8c16;font-weight:600;">'+p.value+'</span>' : '<span style="color:#ccc;">0</span>';
      }
    },
    { field: 'retireCount', headerName: '퇴직', width: 60, type: 'numericColumn', cellRenderer: function(p) {
        return p.value > 0 ? '<span style="color:#f5222d;font-weight:600;">'+p.value+'</span>' : '<span style="color:#ccc;">0</span>';
      }
    },
    { field: 'duration', headerName: '소요시간', width: 85 },
    { field: 'status', headerName: '상태', width: 85, cellRenderer: function(p) {
        var m = { '성공': { bg:'#e8f5e9', c:'#2e7d32', dot:'#52c41a' }, '부분성공': { bg:'#fff8e1', c:'#d48806', dot:'#faad14' }, '실패': { bg:'#ffebee', c:'#c62828', dot:'#ff4d4f' } };
        var s = m[p.value] || { bg:'#f5f5f5', c:'#666', dot:'#999' };
        return '<span style="display:inline-flex;align-items:center;gap:4px;background:'+s.bg+';color:'+s.c+';padding:2px 8px;border-radius:4px;font-size:11px;"><span style="width:6px;height:6px;border-radius:50%;background:'+s.dot+';"></span>'+p.value+'</span>';
      }
    },
    { field: 'detail', headerName: '상세', width: 60, sortable: false, filter: false, cellRenderer: function() {
        return '<button class="btn btn-outline" style="padding:1px 6px;font-size:11px;">상세</button>';
      },
      onCellClicked: function(params) { openErpSyncDetailModal(params.data); }
    }
  ], [
    { syncId: 'SYNC-0305-01', execTime: '2026-03-05 02:00', syncType: '전체', target: '인사', totalCount: 249, newCount: 0, changeCount: 2, retireCount: 0, duration: '2분 34초', status: '성공' },
    { syncId: 'SYNC-0305-02', execTime: '2026-03-05 02:01', syncType: '전체', target: '조직', totalCount: 24, newCount: 1, changeCount: 0, retireCount: 0, duration: '18초', status: '성공' },
    { syncId: 'SYNC-0305-03', execTime: '2026-03-05 02:01', syncType: '전체', target: '겸직', totalCount: 12, newCount: 0, changeCount: 1, retireCount: 0, duration: '8초', status: '성공' },
    { syncId: 'SYNC-0304-01', execTime: '2026-03-04 14:00', syncType: '증분', target: '인사', totalCount: 3, newCount: 0, changeCount: 2, retireCount: 1, duration: '12초', status: '성공' },
    { syncId: 'SYNC-0304-02', execTime: '2026-03-04 14:00', syncType: '증분', target: '겸직', totalCount: 1, newCount: 0, changeCount: 1, retireCount: 0, duration: '4초', status: '부분성공' },
    { syncId: 'SYNC-0304-03', execTime: '2026-03-04 02:00', syncType: '전체', target: '인사', totalCount: 249, newCount: 1, changeCount: 1, retireCount: 1, duration: '2분 41초', status: '성공' },
    { syncId: 'SYNC-0304-04', execTime: '2026-03-04 02:01', syncType: '전체', target: '조직', totalCount: 24, newCount: 0, changeCount: 0, retireCount: 0, duration: '15초', status: '성공' },
    { syncId: 'SYNC-0303-01', execTime: '2026-03-03 14:00', syncType: '증분', target: '인사', totalCount: 2, newCount: 1, changeCount: 1, retireCount: 0, duration: '9초', status: '성공' },
    { syncId: 'SYNC-0303-02', execTime: '2026-03-03 02:00', syncType: '전체', target: '인사', totalCount: 248, newCount: 0, changeCount: 0, retireCount: 0, duration: '2분 18초', status: '성공' },
    { syncId: 'SYNC-0301-01', execTime: '2026-03-01 14:00', syncType: '증분', target: '인사', totalCount: 0, newCount: 0, changeCount: 0, retireCount: 0, duration: '-', status: '실패' }
  ], {
    domLayout: 'autoHeight',
    getRowStyle: function(params) {
      if (params.data.status === '실패') return { background: '#fff5f5' };
      if (params.data.status === '부분성공') return { background: '#fffbe6' };
      return null;
    }
  });

  // ===== ERP 인사정보 동기화 - 금일 인사변동 내역 =====
  initAGGrid('ag-grid-sys-erp-changes', [
    { field: 'empNo', headerName: '사번', width: 80, cellStyle: { fontFamily: 'monospace', color: '#666' } },
    { field: 'name', headerName: '이름', width: 80, cellRenderer: function(p) { return '<strong>'+p.value+'</strong>'; } },
    { field: 'changeType', headerName: '변동유형', width: 90, cellRenderer: function(p) {
        var m = { '신규입사': { bg:'#e8f0fe', c:'#1967d2' }, '부서이동': { bg:'#fff3e0', c:'#ef6c00' }, '직급변경': { bg:'#f9f0ff', c:'#722ed1' }, '퇴직': { bg:'#ffebee', c:'#c62828' } };
        var s = m[p.value] || { bg:'#f5f5f5', c:'#666' };
        return '<span style="background:'+s.bg+';color:'+s.c+';padding:2px 8px;border-radius:4px;font-size:11px;font-weight:600;">'+p.value+'</span>';
      }
    },
    { field: 'before', headerName: '변동전', flex: 1 },
    { field: 'after', headerName: '변동후', flex: 1, cellStyle: { fontWeight: '600', color: '#1967d2' } },
    { field: 'processTime', headerName: '처리시각', width: 75 },
    { field: 'status', headerName: '상태', width: 70, cellRenderer: function(p) {
        var m = { '완료': { bg:'#e8f5e9', c:'#2e7d32' }, '처리중': { bg:'#fff8e1', c:'#d48806' }, '검토필요': { bg:'#ffebee', c:'#c62828' } };
        var s = m[p.value] || { bg:'#f5f5f5', c:'#666' };
        return '<span style="background:'+s.bg+';color:'+s.c+';padding:2px 6px;border-radius:4px;font-size:11px;">'+p.value+'</span>';
      }
    }
  ], [
    { empNo: 'KW2048', name: '김데이터', changeType: '부서이동', before: '데이터분석팀', after: 'AI연구팀', processTime: '02:00', status: '완료' },
    { empNo: 'KW1792', name: '윤상수', changeType: '직급변경', before: '과장', after: '차장', processTime: '02:00', status: '완료' },
    { empNo: 'KW3072', name: '한에너지', changeType: '부서이동', before: '수력발전팀', after: '신재생팀(겸직)', processTime: '14:00', status: '완료' }
  ], { domLayout: 'autoHeight', onRowClicked: function(params) { openErpChangeDetailModal(params.data); } });

  // ===== ERP 인사정보 동기화 - 필드 매핑 설정 =====
  initAGGrid('ag-grid-sys-erp-mapping', [
    { field: 'erpTable', headerName: 'ERP 테이블', width: 140, cellStyle: { fontFamily: 'monospace', fontSize: '11px' } },
    { field: 'erpColumn', headerName: 'ERP 컬럼', width: 130, cellStyle: { fontFamily: 'monospace', fontSize: '11px' } },
    { field: 'dhField', headerName: 'DataHub 필드', width: 140, cellRenderer: function(p) { return '<strong style="font-family:monospace;font-size:11px;">'+p.value+'</strong>'; } },
    { field: 'transform', headerName: '변환규칙', flex: 1, cellRenderer: function(p) {
        if (!p.value || p.value === '-') return '<span style="color:#ccc;">직접매핑</span>';
        return '<span style="background:#f0f7ff;color:#1967d2;padding:2px 6px;border-radius:3px;font-size:10px;font-family:monospace;">'+p.value+'</span>';
      }
    },
    { field: 'mappingStatus', headerName: '상태', width: 80, cellRenderer: function(p) {
        var m = { '활성': { bg:'#e8f5e9', c:'#2e7d32', dot:'#52c41a' }, '비활성': { bg:'#f5f5f5', c:'#999', dot:'#bbb' }, '신규': { bg:'#e8f0fe', c:'#1967d2', dot:'#1677ff' } };
        var s = m[p.value] || { bg:'#f5f5f5', c:'#666', dot:'#999' };
        return '<span style="display:inline-flex;align-items:center;gap:4px;background:'+s.bg+';color:'+s.c+';padding:2px 8px;border-radius:4px;font-size:11px;"><span style="width:6px;height:6px;border-radius:50%;background:'+s.dot+';"></span>'+p.value+'</span>';
      }
    }
  ], [
    { erpTable: 'HR.PER_ALL_PEOPLE', erpColumn: 'EMPLOYEE_NUMBER', dhField: 'emp_no', transform: 'PREFIX("KW")', mappingStatus: '활성' },
    { erpTable: 'HR.PER_ALL_PEOPLE', erpColumn: 'FULL_NAME', dhField: 'user_name', transform: '-', mappingStatus: '활성' },
    { erpTable: 'HR.PER_ALL_PEOPLE', erpColumn: 'EMAIL_ADDRESS', dhField: 'email', transform: 'LOWER()', mappingStatus: '활성' },
    { erpTable: 'HR.PER_ASSIGNMENTS', erpColumn: 'ORGANIZATION_ID', dhField: 'dept_code', transform: 'LOOKUP(ORG_MAP)', mappingStatus: '활성' },
    { erpTable: 'HR.PER_ASSIGNMENTS', erpColumn: 'JOB_ID', dhField: 'grade', transform: 'LOOKUP(JOB_MAP)', mappingStatus: '활성' },
    { erpTable: 'HR.PER_ASSIGNMENTS', erpColumn: 'ASSIGNMENT_STATUS', dhField: 'status', transform: 'MAP(A→활성,T→퇴직)', mappingStatus: '활성' },
    { erpTable: 'HR.PER_PHONES', erpColumn: 'PHONE_NUMBER', dhField: 'phone', transform: 'FORMAT(###-####-####)', mappingStatus: '활성' },
    { erpTable: 'HR.HR_ORGANIZATIONS', erpColumn: 'ORG_ID', dhField: 'org_code', transform: '-', mappingStatus: '활성' },
    { erpTable: 'HR.HR_ORGANIZATIONS', erpColumn: 'ORG_NAME', dhField: 'org_name', transform: '-', mappingStatus: '활성' },
    { erpTable: 'HR.HR_ORGANIZATIONS', erpColumn: 'PARENT_ORG_ID', dhField: 'parent_org_code', transform: 'LOOKUP(ORG_MAP)', mappingStatus: '활성' },
    { erpTable: 'HR.PER_ASSIGNMENTS', erpColumn: 'SECONDARY_ASG', dhField: 'concurrent_dept', transform: 'LOOKUP(ORG_MAP)', mappingStatus: '활성' },
    { erpTable: 'HR.PER_ALL_PEOPLE', erpColumn: 'HIRE_DATE', dhField: 'join_date', transform: 'DATE(YYYY-MM-DD)', mappingStatus: '활성' },
    { erpTable: 'HR.PER_ALL_PEOPLE', erpColumn: 'TERMINATION_DATE', dhField: 'retire_date', transform: 'DATE(YYYY-MM-DD)', mappingStatus: '활성' },
    { erpTable: 'HR.PER_ALL_PEOPLE', erpColumn: 'SSO_ACCOUNT', dhField: 'sso_linked', transform: 'BOOL(Y/N)', mappingStatus: '신규' }
  ], { domLayout: 'autoHeight' });
}

// ===== ERP 동기화 모달 함수 =====
function closeModalHelper(modalId) {
  var modal = document.getElementById(modalId);
  if (!modal) return;
  modal.style.display = 'none';
  var card = modal.querySelector('.modal-card');
  if (card) { card.style.transform = ''; card.style.left = ''; card.style.top = ''; card.style.position = ''; card.style.margin = ''; }
}

// -- 동기화 이력 상세 모달 --
function openErpSyncDetailModal(data) {
  if (!data) return;
  document.getElementById('erpSyncDetail-syncId').textContent = data.syncId;
  document.getElementById('erpSyncDetail-execTime').textContent = data.execTime;
  document.getElementById('erpSyncDetail-syncType').textContent = data.syncType;
  document.getElementById('erpSyncDetail-target').textContent = data.target;
  var statusEl = document.getElementById('erpSyncDetail-status');
  var sc = { '성공': '#52c41a', '부분성공': '#faad14', '실패': '#ff4d4f' };
  statusEl.textContent = data.status;
  statusEl.style.color = sc[data.status] || '#666';
  document.getElementById('erpSyncDetail-totalCount').textContent = data.totalCount;
  document.getElementById('erpSyncDetail-newCount').textContent = data.newCount;
  document.getElementById('erpSyncDetail-changeCount').textContent = data.changeCount;
  document.getElementById('erpSyncDetail-retireCount').textContent = data.retireCount;
  document.getElementById('erpSyncDetail-duration').textContent = data.duration;
  document.getElementById('erpSyncDetail-trigger').textContent = data.execTime.includes('02:00') || data.execTime.includes('14:00') ? '스케줄 (cron)' : '수동 실행';
  document.getElementById('erpSyncDetailModal').style.display = 'flex';
}
function closeErpSyncDetailModal() { closeModalHelper('erpSyncDetailModal'); }

// -- 동기화 설정 모달 --
function openErpSyncSettingModal() { document.getElementById('erpSyncSettingModal').style.display = 'flex'; }
function closeErpSyncSettingModal() { closeModalHelper('erpSyncSettingModal'); }

// -- 수동 동기화 실행 모달 --
function openErpSyncRunModal() {
  document.getElementById('erpSyncRun-confirm').style.display = '';
  document.getElementById('erpSyncRun-progress').style.display = 'none';
  document.getElementById('erpSyncRun-complete').style.display = 'none';
  document.getElementById('erpSyncRun-execBtn').style.display = '';
  document.getElementById('erpSyncRun-cancelBtn').textContent = '취소';
  document.getElementById('erpSyncRunModal').style.display = 'flex';
}
function closeErpSyncRunModal() { closeModalHelper('erpSyncRunModal'); }

function executeErpManualSync() {
  document.getElementById('erpSyncRun-confirm').style.display = 'none';
  document.getElementById('erpSyncRun-progress').style.display = '';
  document.getElementById('erpSyncRun-execBtn').style.display = 'none';
  document.getElementById('erpSyncRun-cancelBtn').textContent = '닫기';
  var bar = document.getElementById('erpSyncRun-progressBar');
  var stepEl = document.getElementById('erpSyncRun-progressStep');
  var logEl = document.getElementById('erpSyncRun-progressLog');
  logEl.innerHTML = '';
  var steps = [
    { pct: 15, step: 'ERP 소스 연결 확인 중...', log: '[OK] Oracle ERP HR 연결 성공 (42ms)' },
    { pct: 40, step: '변경 데이터 추출 중...', log: '[OK] 285건 레코드 추출 완료' },
    { pct: 70, step: 'DataHub 사용자DB 반영 중...', log: '[OK] 신규 0건, 변경 3건, 퇴직 0건 반영' },
    { pct: 90, step: '후처리 및 무결성 검증 중...', log: '[OK] 무결성 검증 통과' }
  ];
  var i = 0;
  function nextStep() {
    if (i < steps.length) {
      bar.style.width = steps[i].pct + '%';
      stepEl.textContent = steps[i].step;
      var logLine = document.createElement('div');
      logLine.style.cssText = 'color:#52c41a; font-family:monospace;';
      logLine.textContent = steps[i].log;
      logEl.appendChild(logLine);
      i++;
      setTimeout(nextStep, 800);
    } else {
      bar.style.width = '100%';
      setTimeout(function() {
        document.getElementById('erpSyncRun-progress').style.display = 'none';
        document.getElementById('erpSyncRun-complete').style.display = '';
      }, 400);
    }
  }
  setTimeout(nextStep, 500);
}

// -- 인사변동 상세 모달 --
function openErpChangeDetailModal(data) {
  if (!data) return;
  document.getElementById('erpChangeDetail-avatar').textContent = data.name.charAt(0);
  document.getElementById('erpChangeDetail-name').textContent = data.name;
  document.getElementById('erpChangeDetail-empNo').textContent = data.empNo;
  document.getElementById('erpChangeDetail-email').textContent = data.empNo.toLowerCase() + '@kwater.or.kr';
  var badge = document.getElementById('erpChangeDetail-changeTypeBadge');
  var cm = { '신규입사': { bg:'#e8f0fe', c:'#1967d2' }, '부서이동': { bg:'#fff3e0', c:'#ef6c00' }, '직급변경': { bg:'#f9f0ff', c:'#722ed1' }, '퇴직': { bg:'#ffebee', c:'#c62828' } };
  var cs = cm[data.changeType] || { bg:'#f5f5f5', c:'#666' };
  badge.textContent = data.changeType;
  badge.style.background = cs.bg;
  badge.style.color = cs.c;
  document.getElementById('erpChangeDetail-before').textContent = data.before;
  document.getElementById('erpChangeDetail-after').textContent = data.after;
  document.getElementById('erpChangeDetail-processTime').textContent = '2026-03-05 ' + data.processTime;
  document.getElementById('erpChangeDetail-status').textContent = data.status;
  // 연관 영향 동적 생성
  var impactsEl = document.getElementById('erpChangeDetail-impacts');
  impactsEl.innerHTML = '';
  var impacts = [];
  if (data.changeType === '부서이동') {
    impacts = [
      { icon: '🔑', text: '데이터 접근 권한이 새 부서 기준으로 자동 갱신됨', color: '#1677ff' },
      { icon: '📂', text: '기존 부서 데이터셋 접근 권한 30일 유지 후 해제 예정', color: '#fa8c16' },
      { icon: '👥', text: '새 부서 팀장에게 승인 권한 이관 완료', color: '#52c41a' }
    ];
  } else if (data.changeType === '직급변경') {
    impacts = [
      { icon: '🔑', text: '승인 권한 레벨이 새 직급 기준으로 갱신됨', color: '#722ed1' },
      { icon: '📊', text: '대시보드 접근 범위 변경 없음', color: '#52c41a' }
    ];
  } else if (data.changeType === '퇴직') {
    impacts = [
      { icon: '🔒', text: 'SSO 토큰 즉시 무효화 처리됨', color: '#ff4d4f' },
      { icon: '📂', text: '소유 데이터셋 관리자 이관 필요', color: '#fa8c16' },
      { icon: '🔑', text: 'API 키 전체 비활성화됨', color: '#ff4d4f' }
    ];
  } else {
    impacts = [
      { icon: '🔑', text: '초기 접근 권한 설정 완료', color: '#52c41a' },
      { icon: '📧', text: '포털 가입 안내 메일 발송됨', color: '#1677ff' }
    ];
  }
  impacts.forEach(function(imp) {
    var div = document.createElement('div');
    div.style.cssText = 'display:flex;align-items:center;gap:8px;padding:8px 12px;background:#f8f9fa;border-radius:6px;border-left:3px solid ' + imp.color + ';';
    div.innerHTML = '<span>' + imp.icon + '</span><span>' + imp.text + '</span>';
    impactsEl.appendChild(div);
  });
  document.getElementById('erpChangeDetailModal').style.display = 'flex';
}
function closeErpChangeDetailModal() { closeModalHelper('erpChangeDetailModal'); }

// -- 매핑 편집 모달 --
function openErpMappingEditModal() { document.getElementById('erpMappingEditModal').style.display = 'flex'; }
function closeErpMappingEditModal() { closeModalHelper('erpMappingEditModal'); }

// ===== 역할별 홈 대시보드 =====
function getLoginGroup(roleKey) {
  if (!roleKey) return 'employee';
  var group = roleKey.split('|')[0];
  if (group === '협력직원') return 'partner';
  if (group === '데이터엔지니어') return 'engineer';
  if (group === '관리자') return 'admin';
  return 'employee';
}

function renderHomeDashboard() {
  var container = document.getElementById('screen-home');
  if (!container) return;
  var group = getLoginGroup(window.currentRoleKey);
  var userName = window.currentUserName || '사용자';
  var roleDetail = (window.currentRoleKey || '').split('|')[1] || '';

  // 1) 고정: 헤더 + 검색창
  var html = buildDashboardHeader(group, userName, roleDetail);

  // 2) 고정: 역할별 4칸 KPI 카드
  if (group === 'partner') html += buildPartnerCards();
  else if (group === 'engineer') html += buildEngineerCards();
  else if (group === 'admin') html += buildAdminCards();
  else html += buildEmployeeCards();

  // 3) 나의 위젯 영역 (위젯설정에서 배치한 위젯들 그대로 표출)
  html += '<div style="margin-top:16px;">'
    + '<div style="display:flex; justify-content:space-between; align-items:center; margin-bottom:10px;">'
    + '<div style="font-size:14px; font-weight:700; color:var(--text-color);">🧩 나의 위젯</div>'
    + '<span style="font-size:11px; color:#1677ff; cursor:pointer;" onclick="navigate(\'widget-settings\')">위젯 설정 →</span>'
    + '</div>'
    + '<div id="home-widget-area" style="display:grid; grid-template-columns:repeat(3, 1fr); gap:10px; grid-auto-rows:minmax(100px, auto);"></div>'
    + '</div>';

  // 4) 나의 시각화 갤러리 (갤러리에서 배치한 차트 그대로 표출)
  html += '<div style="margin-top:18px;">'
    + '<div style="display:flex; justify-content:space-between; align-items:center; margin-bottom:10px;">'
    + '<div style="font-size:14px; font-weight:700; color:var(--text-color);">📊 나의 시각화 갤러리</div>'
    + '<span style="font-size:11px; color:#1677ff; cursor:pointer;" onclick="navigate(\'gallery\')">차트 갤러리 →</span>'
    + '</div>'
    + '<div id="home-gallery-area" style="display:grid; grid-template-columns:repeat(3, 1fr); gap:10px; grid-auto-rows:minmax(120px, auto);"></div>'
    + '</div>';

  container.innerHTML = html;

  // 5) 위젯/갤러리 영역에 콘텐츠 채우기
  setTimeout(function() { renderHomeWidgets(); renderHomeGallery(); }, 50);
}

function buildDashboardHeader(group, userName, roleDetail) {
  var subtitleMap = { employee: '업무 활용형', partner: '데이터 탐색형', engineer: '엔지니어링형', admin: '시스템 관리형' };
  var iconMap = { employee: '📋', partner: '🔍', engineer: '⚙️', admin: '🛡️' };
  var subtitle = subtitleMap[group] || '개인화 대시보드';
  var icon = iconMap[group] || '📋';

  return '<div class="breadcrumb"><a href="#" onclick="navigate(\'home\')">개인 대시보드</a> &gt; <strong>개인대시보드</strong></div>'
    + '<div style="display:flex; justify-content:space-between; align-items:center; margin-bottom:12px;">'
    + '  <div>'
    + '    <div style="font-size:18px; font-weight:700; color:#1a2744;">' + icon + ' 안녕하세요, ' + userName + '님</div>'
    + '    <div style="font-size:12px; color:rgba(0,0,0,.45); margin-top:2px;">' + subtitle + ' 대시보드 · ' + roleDetail + '</div>'
    + '  </div>'
    + '  <div></div>'
    + '</div>'
    + '<div class="ai-box">'
    + '  <div style="font-size:13px; font-weight:600; margin-bottom:6px;">🤖 AI 검색 및 질의응답</div>'
    + '  <input type="text" placeholder="자연어로 데이터를 검색하세요... (예: 소양강댐 수위와 발전량)" onclick="navigate(\'ai\')">'
    + '</div>';
}

function buildQualityBars(items) {
  var html = '';
  items.forEach(function (item, idx) {
    var mb = idx < items.length - 1 ? 'margin-bottom:8px;' : '';
    html += '<div style="' + mb + '">'
      + '<div style="display:flex; justify-content:space-between; font-size:11px; margin-bottom:2px;">'
      + '<span>' + item.label + '</span><span style="font-weight:600;">' + item.value + '%</span></div>'
      + '<div class="progress-track"><div class="progress-bar-bg">'
      + '<div class="progress-bar-fill" style="width:' + item.value + '%; background:' + item.color + ';"></div>'
      + '</div></div></div>';
  });
  return html;
}

function buildNoticeSection() {
  return '<div class="card" style="padding:0;">'
    + '<div class="card-head" style="display:flex; justify-content:space-between; align-items:center;">'
    + '<div class="card-title">📢 공지사항</div>'
    + '<span style="font-size:11px; color:#1677ff; cursor:pointer;" onclick="navigate(\'comm-notice\')">더보기 →</span></div>'
    + '<div class="card-body" style="padding:0;">'
    + '<table style="width:100%; border-collapse:collapse; font-size:12px;"><tbody>'
    + '<tr style="border-bottom:1px solid #f0f0f0; background:#fff8f0; cursor:pointer;" onclick="navigate(\'comm-notice\')">'
    + '<td style="padding:8px 14px; width:80px; white-space:nowrap;"><span style="background:#fff1f0; color:#cf1322; padding:2px 8px; border-radius:3px; font-size:10px; font-weight:600;">긴급</span></td>'
    + '<td style="padding:8px 4px; font-weight:600;">[긴급] 2/28(금) 시스템 정기점검 안내 (22:00~06:00)</td>'
    + '<td style="padding:8px 14px; color:#8c8c8c; text-align:right; width:80px;">02-25</td></tr>'
    + '<tr style="border-bottom:1px solid #f0f0f0; background:#fff8f0; cursor:pointer;" onclick="navigate(\'comm-notice\')">'
    + '<td style="padding:8px 14px; width:80px; white-space:nowrap;"><span style="background:#fff1f0; color:#cf1322; padding:2px 8px; border-radius:3px; font-size:10px; font-weight:600;">긴급</span></td>'
    + '<td style="padding:8px 4px; font-weight:600;">[긴급] 외부연계 API 인증키 갱신 안내 (3월 1일까지)</td>'
    + '<td style="padding:8px 14px; color:#8c8c8c; text-align:right;">02-24</td></tr>'
    + '<tr style="border-bottom:1px solid #f0f0f0; cursor:pointer;" onclick="navigate(\'comm-notice\')">'
    + '<td style="padding:8px 14px; width:80px; white-space:nowrap;"><span style="background:#e8f5e9; color:#2e7d32; padding:2px 8px; border-radius:3px; font-size:10px;">정책</span></td>'
    + '<td style="padding:8px 4px;">2026년 데이터 품질관리 계획 변경 안내</td>'
    + '<td style="padding:8px 14px; color:#8c8c8c; text-align:right;">02-22</td></tr>'
    + '<tr style="border-bottom:1px solid #f0f0f0; cursor:pointer;" onclick="navigate(\'comm-notice\')">'
    + '<td style="padding:8px 14px; width:80px; white-space:nowrap;"><span style="background:#e6f7ff; color:#1677ff; padding:2px 8px; border-radius:3px; font-size:10px;">시스템</span></td>'
    + '<td style="padding:8px 4px;">데이터허브 포털 v2.1 업데이트 안내 (신규 기능 추가)</td>'
    + '<td style="padding:8px 14px; color:#8c8c8c; text-align:right;">02-20</td></tr>'
    + '<tr style="cursor:pointer;" onclick="navigate(\'comm-notice\')">'
    + '<td style="padding:8px 14px; width:80px; white-space:nowrap;"><span style="background:#f3e8ff; color:#7c3aed; padding:2px 8px; border-radius:3px; font-size:10px;">교육</span></td>'
    + '<td style="padding:8px 4px;">3월 데이터 리터러시 교육 참가자 모집 (3/10~3/14)</td>'
    + '<td style="padding:8px 14px; color:#8c8c8c; text-align:right;">02-18</td></tr>'
    + '</tbody></table></div></div>';
}

// === 역할별 4칸 KPI 카드만 (개인대시보드 고정 영역) ===
function buildEmployeeCards() {
  return '<div class="stat-row stat-row-4">'
    + '<div class="stat-card" style="text-align:left; padding:14px 16px; border-left:3px solid #1677ff;"><div class="stat-title" style="text-align:left;">나의 데이터 활용</div><div class="stat-value" style="font-size:26px; text-align:left; color:#1677ff;">47건</div><div style="font-size:10px; color:var(--text-secondary); margin-top:4px;">이번 달 (전월 대비 +12%)</div></div>'
    + '<div class="stat-card" style="text-align:left; padding:14px 16px; border-left:3px solid #fa8c16;"><div class="stat-title" style="text-align:left;">승인대기</div><div class="stat-value" style="font-size:26px; text-align:left; color:#fa8c16;">3건</div><div style="font-size:10px; color:var(--text-secondary); margin-top:4px;">평균 처리 2.4h</div></div>'
    + '<div class="stat-card" style="text-align:left; padding:14px 16px; border-left:3px solid #52c41a;"><div class="stat-title" style="text-align:left;">데이터 품질점수</div><div class="stat-value" style="font-size:26px; text-align:left; color:#52c41a;">94.2</div><div style="font-size:10px; color:#52c41a; margin-top:4px;">&#9650; 전월 대비 +1.8p</div></div>'
    + '<div class="stat-card" style="text-align:left; padding:14px 16px; border-left:3px solid #722ed1;"><div class="stat-title" style="text-align:left;">즐겨찾기</div><div class="stat-value" style="font-size:26px; text-align:left;">12</div><div style="font-size:10px; color:var(--text-secondary); margin-top:4px;">등록 데이터셋</div></div>'
    + '</div>';
}

function buildPartnerCards() {
  return '<div class="stat-row stat-row-4">'
    + '<div class="stat-card" style="text-align:left; padding:14px 16px; border-left:3px solid #1677ff;"><div class="stat-title" style="text-align:left;">이용가능 데이터셋</div><div class="stat-value" style="font-size:26px; text-align:left; color:#1677ff;">1,247</div><div style="font-size:10px; color:var(--text-secondary); margin-top:4px;">공개 데이터 기준</div></div>'
    + '<div class="stat-card" style="text-align:left; padding:14px 16px; border-left:3px solid #fa8c16;"><div class="stat-title" style="text-align:left;">나의 요청</div><div class="stat-value" style="font-size:26px; text-align:left; color:#fa8c16;">5건</div><div style="font-size:10px; color:var(--text-secondary); margin-top:4px;">승인대기 2 · 완료 3</div></div>'
    + '<div class="stat-card" style="text-align:left; padding:14px 16px; border-left:3px solid #52c41a;"><div class="stat-title" style="text-align:left;">이번달 다운로드</div><div class="stat-value" style="font-size:26px; text-align:left; color:#52c41a;">23회</div><div style="font-size:10px; color:var(--text-secondary); margin-top:4px;">전월 대비 +15%</div></div>'
    + '<div class="stat-card" style="text-align:left; padding:14px 16px; border-left:3px solid #722ed1;"><div class="stat-title" style="text-align:left;">API 호출(일평균)</div><div class="stat-value" style="font-size:26px; text-align:left;">1,840</div><div style="font-size:10px; color:var(--text-secondary); margin-top:4px;">정상 응답률 99.2%</div></div>'
    + '</div>';
}

function buildEngineerCards() {
  return '<div class="stat-row stat-row-4">'
    + '<div class="stat-card" style="text-align:left; padding:14px 16px; border-left:3px solid #52c41a;"><div class="stat-title" style="text-align:left;">파이프라인 성공률</div><div class="stat-value" style="font-size:26px; text-align:left; color:#52c41a;">97.8%</div><div style="font-size:10px; color:var(--text-secondary); margin-top:4px;">24h 기준 (142/145)</div></div>'
    + '<div class="stat-card" style="text-align:left; padding:14px 16px; border-left:3px solid #1677ff;"><div class="stat-title" style="text-align:left;">금일 수집건수</div><div class="stat-value" style="font-size:26px; text-align:left; color:#1677ff;">1.24M</div><div style="font-size:10px; color:#52c41a; margin-top:4px;">&#9650; 전일 대비 +8.3%</div></div>'
    + '<div class="stat-card" style="text-align:left; padding:14px 16px; border-left:3px solid #cf1322;"><div class="stat-title" style="text-align:left;">오류 / 경고</div><div class="stat-value" style="font-size:26px; text-align:left; color:#cf1322;">3 <span style="font-size:16px; color:#fa8c16;">/ 7</span></div><div style="font-size:10px; color:var(--text-secondary); margin-top:4px;">즉시 대응 필요</div></div>'
    + '<div class="stat-card" style="text-align:left; padding:14px 16px; border-left:3px solid #722ed1;"><div class="stat-title" style="text-align:left;">평균 처리시간</div><div class="stat-value" style="font-size:26px; text-align:left;">2.4s</div><div style="font-size:10px; color:#52c41a; margin-top:4px;">SLA 충족 (목표 5s)</div></div>'
    + '</div>';
}

function buildAdminCards() {
  return '<div class="stat-row stat-row-4">'
    + '<div class="stat-card" style="text-align:left; padding:14px 16px; border-left:3px solid #1677ff;"><div class="stat-title" style="text-align:left;">금일 활성 사용자</div><div class="stat-value" style="font-size:26px; text-align:left; color:#1677ff;">847</div><div style="font-size:10px; color:var(--text-secondary); margin-top:4px;">전일 대비 +3.2%</div></div>'
    + '<div class="stat-card" style="text-align:left; padding:14px 16px; border-left:3px solid #52c41a;"><div class="stat-title" style="text-align:left;">시스템 가용률</div><div class="stat-value" style="font-size:26px; text-align:left; color:#52c41a;">99.97%</div><div style="font-size:10px; color:var(--text-secondary); margin-top:4px;">월간 SLA 충족</div></div>'
    + '<div class="stat-card" style="text-align:left; padding:14px 16px; border-left:3px solid #cf1322;"><div class="stat-title" style="text-align:left;">보안 이벤트</div><div class="stat-value" style="font-size:26px; text-align:left; color:#cf1322;">12</div><div style="font-size:10px; color:var(--text-secondary); margin-top:4px;">금주 탐지 건수</div></div>'
    + '<div class="stat-card" style="text-align:left; padding:14px 16px; border-left:3px solid #fa8c16;"><div class="stat-title" style="text-align:left;">스토리지 사용</div><div class="stat-value" style="font-size:26px; text-align:left;">78.4%</div><div style="font-size:10px; color:#fa8c16; margin-top:4px;">4.7TB / 6.0TB</div></div>'
    + '</div>';
}

// === 홈 위젯 영역: 위젯설정에서 배치한 위젯을 읽기전용으로 표시 ===
function renderHomeWidgets() {
  var area = document.getElementById('home-widget-area');
  if (!area) return;
  // 위젯설정에서 배치한 위젯 목록 가져옴 (없으면 기본값)
  var defaultWidgets = {
    employee: ['w-my-work','w-quality','w-quality-bar','w-notices','w-popular','w-collection-trend','w-system-data'],
    partner:  ['w-quality','w-popular','w-notices','w-download-stats','w-data-catalog','w-system-data'],
    engineer: ['w-pipeline','w-collection','w-link-progress','w-link-error','w-load-stage','w-load-error','w-system-data','w-error-log','w-collection-trend'],
    admin:    ['w-active-users','w-availability','w-security','w-storage','w-link-progress','w-link-error','w-system-data','w-load-stage','w-quality-bar']
  };
  var group = getLoginGroup(window.currentRoleKey);
  var placed = wsPlacedWidgets.length > 0 ? wsPlacedWidgets.slice() : (defaultWidgets[group] || defaultWidgets.employee);
  if (placed.length === 0) {
    area.innerHTML = '<div style="grid-column:1/-1; text-align:center; padding:30px; color:var(--text-secondary); font-size:12px; border:2px dashed var(--border-color); border-radius:10px;">위젯이 없습니다. <a href="#" onclick="navigate(\'widget-settings\'); return false;" style="color:#1677ff;">위젯 설정</a>에서 위젯을 추가하세요.</div>';
    return;
  }
  area.innerHTML = '';
  var contentMap = {
    'w-active-users': function() { return '<div style="font-size:28px; font-weight:700; color:#1677ff;">847</div><div style="font-size:10px; color:var(--text-secondary); margin-top:4px;">전일 대비 +3.2% · 동시접속 156</div>'; },
    'w-availability': function() { return '<div style="font-size:28px; font-weight:700; color:#52c41a;">99.97%</div><div style="font-size:10px; color:var(--text-secondary); margin-top:4px;">월간 SLA 충족</div>'; },
    'w-security': function() { return '<div style="font-size:28px; font-weight:700; color:#ff4d4f;">12</div><div style="font-size:10px; color:var(--text-secondary); margin-top:4px;">금주 탐지 · 비정상접근 3</div>'; },
    'w-storage': function() { return '<div style="font-size:28px; font-weight:700; color:#722ed1;">78.4%</div><div style="font-size:10px; color:var(--text-secondary); margin-top:4px;">4.7TB / 6.0TB</div>'; },
    'w-pipeline': function() { return '<div style="font-size:28px; font-weight:700; color:#00acc1;">97.8%</div><div style="font-size:10px; color:var(--text-secondary); margin-top:4px;">142/145 성공</div>'; },
    'w-collection': function() { return '<div style="font-size:28px; font-weight:700; color:#26a69a;">1.24M</div><div style="font-size:10px; color:var(--text-secondary); margin-top:4px;">전일 대비 +8.3%</div>'; },
    'w-quality': function() { return '<div style="font-size:28px; font-weight:700; color:#52c41a;">94.2</div><div style="font-size:10px; color:var(--text-secondary); margin-top:4px;">완전성 96.8 · 정합성 93.1</div>'; },
    'w-api-calls': function() { return '<div style="font-size:28px; font-weight:700; color:#42a5f5;">1,840</div><div style="font-size:10px; color:var(--text-secondary); margin-top:4px;">일평균 · 응답률 99.2%</div>'; },
    'w-my-work': function() { return '<ul class="mini-list" style="margin:0; font-size:12px;"><li onclick="navigate(\'process\')" style="cursor:pointer"><span>● 승인대기</span><span style="color:#1677ff; font-weight:600;">3건</span></li><li><span>★ 즐겨찾기</span><span>12건</span></li><li><span>◎ 최근 항목</span><span>8건</span></li><li onclick="navigate(\'process\')" style="cursor:pointer"><span>▶ 진행중 요청</span><span style="color:#fa8c16; font-weight:600;">5건</span></li></ul>'; },
    'w-user-status': function() { return '<ul class="mini-list" style="margin:0; font-size:12px;"><li><span>수공직원</span><span style="font-weight:600;">523명</span></li><li><span>협력직원</span><span style="font-weight:600;">189명</span></li><li><span>엔지니어</span><span style="font-weight:600;">98명</span></li><li><span>관리자</span><span style="font-weight:600;">37명</span></li></ul>'; },
    'w-sys-monitor': function() { return buildQualityBars([{label:"Portal",value:99.9,color:"#52c41a"},{label:"DB",value:98.7,color:"#52c41a"},{label:"Kafka",value:97.5,color:"#1677ff"},{label:"Spark",value:95.2,color:"#fa8c16"}]); },
    'w-audit-log': function() { return '<ul class="mini-list" style="margin:0; font-size:12px;"><li><span style="color:#cf1322;">● 비정상 접근</span><span style="color:#cf1322; font-weight:600;">3건</span></li><li><span style="color:#fa8c16;">● 권한 변경</span><span style="color:#fa8c16; font-weight:600;">8건</span></li><li><span>● 정상 로그</span><span>2,340건</span></li></ul>'; },
    'w-notices': function() { return '<div style="font-size:11px;"><div style="padding:4px 0; border-bottom:1px solid var(--border-color);"><span style="background:#fff1f0; color:#cf1322; padding:1px 5px; border-radius:2px; font-size:9px; margin-right:4px;">긴급</span>시스템 정기점검 안내</div><div style="padding:4px 0; border-bottom:1px solid var(--border-color);"><span style="background:#e8f5e9; color:#2e7d32; padding:1px 5px; border-radius:2px; font-size:9px; margin-right:4px;">정책</span>품질관리 계획 변경</div><div style="padding:4px 0;"><span style="background:#e6f7ff; color:#1677ff; padding:1px 5px; border-radius:2px; font-size:9px; margin-right:4px;">시스템</span>v2.1 업데이트 안내</div></div>'; },
    'w-popular': function() { return '<ul class="mini-list" style="margin:0; font-size:12px;"><li><span><span class="rank-badge" style="background:#1677ff;">1</span>광역상수도 유량</span></li><li><span><span class="rank-badge" style="background:#1677ff;">2</span>수력발전 통계</span></li><li><span><span class="rank-badge" style="background:#1677ff;">3</span>RWIS 수위데이터</span></li></ul>'; },
    'w-recent-update': function() { return '<ul class="mini-list" style="margin:0; font-size:12px;"><li><span><span class="badge-dot" style="background:#52c41a;"></span> RWIS 수위 갱신</span><span style="font-size:10px; color:var(--text-secondary);">11:42</span></li><li><span><span class="badge-dot" style="background:#1677ff;"></span> SAP 수집완료</span><span style="font-size:10px; color:var(--text-secondary);">06:15</span></li><li><span><span class="badge-dot" style="background:#fa8c16;"></span> 스마트미터</span><span style="font-size:10px; color:var(--text-secondary);">상시</span></li></ul>'; },
    'w-quality-bar': function() { return buildQualityBars([{label:"완전성",value:96.8,color:"#52c41a"},{label:"정합성",value:93.1,color:"#1677ff"},{label:"유효성",value:92.7,color:"#fa8c16"},{label:"적시성",value:94.8,color:"#722ed1"}]); },
    'w-resource': function() { return buildQualityBars([{label:"CPU",value:62,color:"#52c41a"},{label:"메모리",value:78,color:"#fa8c16"},{label:"디스크",value:45,color:"#1677ff"},{label:"네트워크",value:33,color:"#722ed1"}]); },
    'w-approval': function() { return '<ul class="mini-list" style="margin:0; font-size:12px;"><li onclick="navigate(\'process\')" style="cursor:pointer"><span style="color:#fa8c16;">● 결재대기</span><span style="color:#fa8c16; font-weight:600;">2건</span></li><li><span style="color:#52c41a;">● 승인완료</span><span>15건</span></li><li><span style="color:#cf1322;">● 반려</span><span style="color:#cf1322;">1건</span></li></ul>'; },
    'w-collection-trend': function() { return '<svg viewBox="0 0 200 60" style="width:100%;"><defs><linearGradient id="hct" x1="0" y1="0" x2="0" y2="1"><stop offset="0%" stop-color="#1677ff" stop-opacity="0.15"/><stop offset="100%" stop-color="#1677ff" stop-opacity="0.02"/></linearGradient></defs><polygon points="5,30 25,22 45,28 65,18 85,24 105,20 125,15 145,22 165,12 185,18 200,14 200,55 5,55" fill="url(#hct)"/><polyline points="5,30 25,22 45,28 65,18 85,24 105,20 125,15 145,22 165,12 185,18 200,14" fill="none" stroke="#1677ff" stroke-width="1.5"/></svg>'; },
    'w-link-progress': function() { return buildQualityBars([{label:"SAP-ETL",value:90,color:"#1677ff"},{label:"RWIS-CDC",value:80,color:"#40a9ff"},{label:"SCADA",value:96,color:"#096dd9"},{label:"기상청API",value:70,color:"#fa8c16"},{label:"환경부API",value:88,color:"#52c41a"}]); },
    'w-link-error': function() { return '<div style="font-size:11px;"><div style="display:flex; justify-content:space-between; margin-bottom:6px;"><span style="color:#f5222d; font-weight:700; font-size:16px;">14<span style="font-size:10px; font-weight:400;"> 건</span></span><span style="background:#fff1f0; color:#cf1322; padding:2px 6px; border-radius:3px; font-size:9px;">실시간</span></div><div style="padding:3px 0; border-bottom:1px solid var(--border-color); font-size:10px;"><span style="color:#cf1322;">●</span> SAP-ETL 타임아웃 <span style="float:right; color:#888;">5건</span></div><div style="padding:3px 0; border-bottom:1px solid var(--border-color); font-size:10px;"><span style="color:#cf1322;">●</span> RWIS 인증오류 <span style="float:right; color:#888;">3건</span></div><div style="padding:3px 0; border-bottom:1px solid var(--border-color); font-size:10px;"><span style="color:#fa8c16;">▲</span> 기상청API 응답지연 <span style="float:right; color:#888;">4건</span></div><div style="padding:3px 0; font-size:10px;"><span style="color:#fa8c16;">▲</span> SCADA 연결끊김 <span style="float:right; color:#888;">2건</span></div></div>'; },
    'w-load-stage': function() { return '<div style="font-size:11px;"><div style="margin-bottom:4px;"><span style="color:#13c2c2; font-size:9px;">수집</span><div style="display:flex; align-items:center; gap:4px;"><div style="flex:1; height:6px; background:#e6fffb; border-radius:3px;"><div style="width:95%; height:100%; background:#13c2c2; border-radius:3px;"></div></div><span style="font-size:9px; color:#13c2c2; min-width:36px;">1.24M</span></div></div><div style="margin-bottom:4px;"><span style="color:#36cfc9; font-size:9px;">정제</span><div style="display:flex; align-items:center; gap:4px;"><div style="flex:1; height:6px; background:#e6fffb; border-radius:3px;"><div style="width:83%; height:100%; background:#36cfc9; border-radius:3px;"></div></div><span style="font-size:9px; color:#36cfc9; min-width:36px;">1.08M</span></div></div><div style="margin-bottom:4px;"><span style="color:#08979c; font-size:9px;">적재</span><div style="display:flex; align-items:center; gap:4px;"><div style="flex:1; height:6px; background:#e6fffb; border-radius:3px;"><div style="width:75%; height:100%; background:#08979c; border-radius:3px;"></div></div><span style="font-size:9px; color:#08979c; min-width:36px;">982K</span></div></div><div><span style="color:#006d75; font-size:9px;">분석</span><div style="display:flex; align-items:center; gap:4px;"><div style="flex:1; height:6px; background:#e6fffb; border-radius:3px;"><div style="width:67%; height:100%; background:#006d75; border-radius:3px;"></div></div><span style="font-size:9px; color:#006d75; min-width:36px;">874K</span></div></div></div>'; },
    'w-load-error': function() { return '<div style="font-size:11px;"><div style="display:flex; gap:8px; margin-bottom:6px;"><div style="flex:1; text-align:center; padding:4px; background:#fff1f0; border-radius:4px;"><div style="font-size:14px; font-weight:700; color:#cf1322;">23</div><div style="font-size:8px; color:#888;">수집오류</div></div><div style="flex:1; text-align:center; padding:4px; background:#fff7e6; border-radius:4px;"><div style="font-size:14px; font-weight:700; color:#fa8c16;">15</div><div style="font-size:8px; color:#888;">정제오류</div></div><div style="flex:1; text-align:center; padding:4px; background:#fff1f0; border-radius:4px;"><div style="font-size:14px; font-weight:700; color:#cf1322;">8</div><div style="font-size:8px; color:#888;">적재오류</div></div><div style="flex:1; text-align:center; padding:4px; background:#e6f7ff; border-radius:4px;"><div style="font-size:14px; font-weight:700; color:#1677ff;">4</div><div style="font-size:8px; color:#888;">스키마</div></div></div><div style="font-size:9px; color:#52c41a;">↘ 전주 대비 -18% 감소세</div></div>'; },
    'w-system-data': function() { return '<div style="font-size:11px;"><div style="padding:3px 0; border-bottom:1px solid var(--border-color); display:flex; justify-content:space-between;"><span>🗄️ 수문DB</span><span><strong style="color:#2f54eb;">842K</strong> <span style="font-size:9px; color:#52c41a;">▲2.1%</span></span></div><div style="padding:3px 0; border-bottom:1px solid var(--border-color); display:flex; justify-content:space-between;"><span>🧪 수질DB</span><span><strong style="color:#597ef7;">621K</strong> <span style="font-size:9px; color:#52c41a;">▲1.5%</span></span></div><div style="padding:3px 0; border-bottom:1px solid var(--border-color); display:flex; justify-content:space-between;"><span>🌤️ 기상DB</span><span><strong style="color:#85a5ff;">487K</strong> <span style="font-size:9px; color:#fa8c16;">-0.3%</span></span></div><div style="padding:3px 0; display:flex; justify-content:space-between;"><span>⚡ 에너지DB</span><span><strong style="color:#adc6ff;">356K</strong> <span style="font-size:9px; color:#52c41a;">▲3.8%</span></span></div></div>'; }
  };
  placed.forEach(function(wid) {
    var w = WS_WIDGETS.find(function(x) { return x.id === wid; });
    if (!w) return;
    if (!canAccessItem(w)) return;
    var size = w._size || 1;
    var hSize = w._height || 1;
    var card = document.createElement('div');
    card.className = 'card';
    card.style.cssText = 'padding:0; grid-column:span ' + size + '; grid-row:span ' + hSize + '; overflow:hidden;';
    var content = contentMap[wid] ? contentMap[wid]() : '<div style="font-size:12px; color:var(--text-secondary);">데이터 로딩 중...</div>';
    card.innerHTML = '<div class="card-head" style="padding:8px 14px;"><div class="card-title" style="font-size:12px;">' + w.icon + ' ' + w.name + '</div></div>'
      + '<div class="card-body" style="padding:8px 14px;">' + content + '</div>';
    area.appendChild(card);
  });
}

// === 홈 갤러리 영역: 갤러리에서 배치한 차트를 읽기전용으로 표시 ===
function renderHomeGallery() {
  var area = document.getElementById('home-gallery-area');
  if (!area) return;
  var placed = galPlacedCharts.length > 0 ? galPlacedCharts.slice() : ['g-dam-level','g-water-quality','g-server-health','g-quality-score','g-kafka-throughput','g-collect-daily'];
  if (placed.length === 0) {
    area.innerHTML = '<div style="grid-column:1/-1; text-align:center; padding:30px; color:var(--text-secondary); font-size:12px; border:2px dashed var(--border-color); border-radius:10px;">차트가 없습니다. <a href="#" onclick="navigate(\'gallery\'); return false;" style="color:#1677ff;">차트 갤러리</a>에서 차트를 추가하세요.</div>';
    return;
  }
  area.innerHTML = '';
  placed.forEach(function(cid) {
    var c = GAL_CHARTS.find(function(x) { return x.id === cid; });
    if (!c) return;
    if (!canAccessItem(c)) return;
    var gw = c._gw || 1;
    var gh = c._gh || 1;
    var card = document.createElement('div');
    card.className = 'card';
    card.style.cssText = 'padding:0; grid-column:span ' + gw + '; grid-row:span ' + gh + '; overflow:hidden;';
    card.innerHTML = '<div class="card-head" style="padding:8px 14px; display:flex; justify-content:space-between; align-items:center;">'
      + '<div class="card-title" style="font-size:12px;">' + c.icon + ' ' + c.name + '</div>'
      + '<span style="font-size:9px; color:var(--text-secondary);">' + c.author + '</span>'
      + '</div>'
      + '<div class="card-body" style="padding:10px 14px; display:flex; align-items:center; justify-content:center; min-height:80px;">' + c.svg + '</div>';
    area.appendChild(card);
  });
}

// ===== 알림 패널 토글 =====
function toggleNotiPanel(e) {
  e.stopPropagation();
  var panel = document.getElementById('notiPanel');
  if (panel) panel.classList.toggle('open');
}

function markAllRead() {
  document.querySelectorAll('.noti-item.noti-unread').forEach(function (item) {
    item.classList.remove('noti-unread');
  });
  var badge = document.querySelector('.noti-unread-badge');
  if (badge) badge.textContent = '0건 읽지 않음';
  var count = document.querySelector('.noti-count');
  if (count) count.style.display = 'none';
}

// 바깥 클릭 시 알림 패널 닫기
document.addEventListener('click', function (e) {
  var panel = document.getElementById('notiPanel');
  var wrapper = document.querySelector('.noti-wrapper');
  if (panel && wrapper && !wrapper.contains(e.target)) {
    panel.classList.remove('open');
  }
});

// ===== 온톨로지 관리 모달 =====
function openOntoModal(id) {
  document.getElementById(id).style.display = 'flex';
}
function closeOntoModal(id) {
  document.getElementById(id).style.display = 'none';
}
function ontoImportAction() {
  alert('OWL 가져오기가 완료되었습니다.\n\n• 클래스 12개 추가\n• 속성 48개 추가\n• 충돌 3건 건너뜀');
  closeOntoModal('ontoImportModal');
}
function ontoExportAction() {
  alert('OWL 파일이 다운로드됩니다.\n\n파일명: kwater-ontology-20260227.owl\n크기: 약 2.4 MB');
  closeOntoModal('ontoExportModal');
}
function ontoAddClassAction() {
  alert('새 클래스가 등록되었습니다.');
  closeOntoModal('ontoAddClassModal');
}
function ontoEditClassAction() {
  alert('클래스 정보가 수정되었습니다.');
  closeOntoModal('ontoEditClassModal');
}
function ontoDeleteAction() {
  alert('클래스가 삭제되었습니다.\n(Neo4j 스냅샷에서 복구 가능)');
  closeOntoModal('ontoDeleteModal');
}
function ontoAddPropAction() {
  alert('데이터 속성이 추가되었습니다.');
  closeOntoModal('ontoAddPropModal');
}
function ontoAddRelAction() {
  alert('관계 속성이 추가되었습니다.');
  closeOntoModal('ontoAddRelModal');
}

/* ── 역할 관리 함수 ── */
function openRoleModal(id) {
  document.getElementById(id).style.display = 'flex';
}
function closeRoleModal(id) {
  document.getElementById(id).style.display = 'none';
}
function selectRole(el, roleKey) {
  document.querySelectorAll('.role-list-item').forEach(function(item) {
    item.classList.remove('role-selected');
  });
  el.classList.add('role-selected');
}
function roleAddAction() {
  alert('새 역할이 생성되었습니다.\n\n• 역할명: 데이터분석가\n• 코드: ROLE_DATA_ANALYST\n• 레벨: Level 5');
  closeRoleModal('roleAddModal');
}
function roleEditAction() {
  alert('역할 설정이 저장되었습니다.');
  closeRoleModal('roleEditModal');
}
function roleAssignAction() {
  alert('사용자 할당이 적용되었습니다.\n\n• 기존 유지: 2명\n• 신규 할당: 0명');
  closeRoleModal('roleAssignModal');
}
function roleBulkAction() {
  alert('권한이 일괄 적용되었습니다.\n\n• 대상: 3개 역할 × 8개 메뉴\n• 변경 항목: 24건');
  closeRoleModal('roleBulkModal');
}
function roleAuditAction() {
  closeRoleModal('roleAuditModal');
}

// ===== 비밀번호 변경 모달 (셀프서비스) =====
function openPasswordChangeModal() {
  document.getElementById('pwChangeModal').style.display = 'flex';
}
function closePasswordChangeModal() {
  document.getElementById('pwChangeModal').style.display = 'none';
  const ids = ['pwc-current', 'pwc-new', 'pwc-confirm'];
  ids.forEach(function(id) { var el = document.getElementById(id); if (el) el.value = ''; });
  var m = document.getElementById('pwc-match'); if (m) m.textContent = '';
}
function passwordChangeAction() {
  var cur = document.getElementById('pwc-current').value;
  var nw = document.getElementById('pwc-new').value;
  var cf = document.getElementById('pwc-confirm').value;
  if (!cur || !nw || !cf) { alert('모든 항목을 입력해주세요.'); return; }
  if (nw.length < 8) { alert('새 비밀번호는 8자 이상이어야 합니다.'); return; }
  if (nw !== cf) { alert('새 비밀번호가 일치하지 않습니다.'); return; }
  alert('비밀번호가 성공적으로 변경되었습니다.\n\n다음 로그인 시 새 비밀번호를 사용해주세요.');
  closePasswordChangeModal();
}

// ===== Kafka 모달 =====
function openKafkaModal(id) {
  document.getElementById(id).style.display = 'flex';
}
function closeKafkaModal(id) {
  document.getElementById(id).style.display = 'none';
}
function kafkaTopicAction() {
  alert('토픽이 생성되었습니다.\n\n' +
    '\u2022 토픽명: new_topic_name\n' +
    '\u2022 파티션: 6\n' +
    '\u2022 복제 팩터: 3\n' +
    '\u2022 보존기간: 168h (7일)');
  closeKafkaModal('kafkaTopicModal');
}
function kafkaConsumerAction() {
  closeKafkaModal('kafkaConsumerModal');
}

// ===== Architecture 모달 =====
function openArchModal(id) {
  document.getElementById(id).style.display = 'flex';
}
function closeArchModal(id) {
  document.getElementById(id).style.display = 'none';
}
function archSystemAction() {
  alert('서버가 등록되었습니다.\n\n리소스 모니터링에서 정상 연결 여부를 확인하세요.');
  closeArchModal('archSystemModal');
}

// ===== Widget Settings: Drag & Drop Builder (포탈·시스템 위젯) =====
var WS_WIDGETS = [
  // ── KPI 지표 ──
  { id: 'w-active-users', icon: '👥', name: '금일 활성 사용자', cat: 'kpi', desc: '실시간 접속자 수 및 추이', color: '#1677ff', roles: ['admin'], dataLevel: 'restricted',
    svg:'<svg viewBox="0 0 180 50"><text x="10" y="20" font-size="20" font-weight="700" fill="#1677ff">1,247</text><text x="10" y="35" font-size="9" fill="#52c41a">▲ 12.5%</text><polyline points="80,38 100,32 120,35 140,28 160,22 180,18" fill="none" stroke="#1677ff" stroke-width="1.5"/></svg>' },
  { id: 'w-availability', icon: '🟢', name: '시스템 가용률', cat: 'kpi', desc: 'SLA 가용률 실시간 모니터링', color: '#4caf50', roles: ['employee','engineer','admin'], dataLevel: 'internal',
    svg:'<svg viewBox="0 0 180 50"><text x="10" y="20" font-size="20" font-weight="700" fill="#4caf50">99.8%</text><text x="10" y="35" font-size="9" fill="#888">SLA 목표: 99.5%</text><rect x="100" y="10" width="70" height="6" fill="#e8f5e9" rx="3"/><rect x="100" y="10" width="68" height="6" fill="#4caf50" rx="3"/></svg>' },
  { id: 'w-security', icon: '🛡️', name: '보안 이벤트', cat: 'kpi', desc: '비정상 접근/보안 알림 건수', color: '#ff5722', roles: ['admin'], dataLevel: 'confidential',
    svg:'<svg viewBox="0 0 180 50"><text x="10" y="20" font-size="20" font-weight="700" fill="#ff5722">3</text><text x="10" y="35" font-size="9" fill="#ff5722">● 긴급 1 · 주의 2</text><circle cx="150" cy="25" r="15" fill="none" stroke="#ffccbc" stroke-width="3"/><circle cx="150" cy="25" r="15" fill="none" stroke="#ff5722" stroke-width="3" stroke-dasharray="28 94" transform="rotate(-90 150 25)"/></svg>' },
  { id: 'w-storage', icon: '💾', name: '스토리지 사용률', cat: 'kpi', desc: 'HDFS/DB/Kafka 디스크 사용량', color: '#7e57c2', roles: ['engineer','admin'], dataLevel: 'restricted',
    svg:'<svg viewBox="0 0 180 50"><text x="10" y="20" font-size="20" font-weight="700" fill="#7e57c2">72.4%</text><text x="10" y="35" font-size="9" fill="#888">3.2TB / 4.4TB</text><rect x="100" y="8" width="70" height="6" fill="#ede7f6" rx="3"/><rect x="100" y="8" width="50" height="6" fill="#7e57c2" rx="3"/><rect x="100" y="20" width="70" height="6" fill="#ede7f6" rx="3"/><rect x="100" y="20" width="62" height="6" fill="#9575cd" rx="3"/><rect x="100" y="32" width="70" height="6" fill="#ede7f6" rx="3"/><rect x="100" y="32" width="45" height="6" fill="#b39ddb" rx="3"/></svg>' },
  { id: 'w-pipeline', icon: '🔄', name: '파이프라인 성공률', cat: 'kpi', desc: '24시간 수집 파이프라인 가동률', color: '#00acc1', roles: ['employee','engineer','admin'], dataLevel: 'internal',
    svg:'<svg viewBox="0 0 180 50"><text x="10" y="20" font-size="20" font-weight="700" fill="#00acc1">96.2%</text><text x="10" y="35" font-size="9" fill="#52c41a">정상 48 · </text><text x="68" y="35" font-size="9" fill="#f5222d">실패 2</text><circle cx="150" cy="25" r="15" fill="none" stroke="#e0f7fa" stroke-width="4"/><circle cx="150" cy="25" r="15" fill="none" stroke="#00acc1" stroke-width="4" stroke-dasharray="90 94" transform="rotate(-90 150 25)"/></svg>' },
  { id: 'w-collection', icon: '📥', name: '금일 수집건수', cat: 'kpi', desc: '당일 데이터 수집 총량', color: '#26a69a', roles: ['employee','engineer','admin'], dataLevel: 'internal',
    svg:'<svg viewBox="0 0 180 50"><text x="10" y="20" font-size="20" font-weight="700" fill="#26a69a">84,521</text><text x="10" y="35" font-size="9" fill="#52c41a">▲ 8.3% vs 어제</text><rect x="105" y="30" width="8" height="18" fill="#b2dfdb" rx="1"/><rect x="116" y="22" width="8" height="26" fill="#80cbc4" rx="1"/><rect x="127" y="26" width="8" height="22" fill="#b2dfdb" rx="1"/><rect x="138" y="18" width="8" height="30" fill="#26a69a" rx="1"/><rect x="149" y="14" width="8" height="34" fill="#26a69a" rx="1"/><rect x="160" y="20" width="8" height="28" fill="#80cbc4" rx="1"/></svg>' },
  { id: 'w-quality', icon: '✅', name: '데이터 품질점수', cat: 'kpi', desc: '완전성/정합성/유효성 종합', color: '#66bb6a', roles: 'all', dataLevel: 'public',
    svg:'<svg viewBox="0 0 180 50"><text x="10" y="20" font-size="20" font-weight="700" fill="#66bb6a">94.2</text><text x="55" y="20" font-size="10" fill="#888">/100</text><text x="10" y="35" font-size="9" fill="#52c41a">▲ 1.3p</text><rect x="100" y="10" width="70" height="6" fill="#e8f5e9" rx="3"/><rect x="100" y="10" width="66" height="6" fill="#66bb6a" rx="3"/></svg>' },
  { id: 'w-api-calls', icon: '📡', name: 'API 호출량', cat: 'kpi', desc: '일평균 REST/GraphQL 호출', color: '#42a5f5', roles: ['employee','engineer','admin'], dataLevel: 'internal',
    svg:'<svg viewBox="0 0 180 50"><text x="10" y="20" font-size="20" font-weight="700" fill="#42a5f5">12.4K</text><text x="10" y="35" font-size="9" fill="#888">일평균 호출수</text><polyline points="100,40 115,35 130,38 145,28 160,30 175,20" fill="none" stroke="#42a5f5" stroke-width="1.5"/></svg>' },
  { id: 'w-login-stats', icon: '🔑', name: '로그인 통계', cat: 'kpi', desc: '금일 로그인 횟수/성공률', color: '#5c6bc0', roles: ['admin'], dataLevel: 'restricted',
    svg:'<svg viewBox="0 0 180 50"><text x="10" y="20" font-size="20" font-weight="700" fill="#5c6bc0">342</text><text x="10" y="35" font-size="9" fill="#52c41a">성공률 99.4%</text><rect x="100" y="12" width="70" height="6" fill="#e8eaf6" rx="3"/><rect x="100" y="12" width="69" height="6" fill="#5c6bc0" rx="3"/><text x="105" y="35" font-size="8" fill="#888">SSO 312 · ID/PW 30</text></svg>' },
  { id: 'w-session-count', icon: '🔗', name: '현재 세션수', cat: 'kpi', desc: '동시 접속 세션 수 모니터링', color: '#f57c00', roles: ['admin'], dataLevel: 'restricted',
    svg:'<svg viewBox="0 0 180 50"><text x="10" y="20" font-size="20" font-weight="700" fill="#f57c00">87</text><text x="10" y="35" font-size="9" fill="#888">피크: 143 (14시)</text><polyline points="90,35 105,30 120,32 135,22 150,25 165,28 180,24" fill="none" stroke="#f57c00" stroke-width="1.5"/></svg>' },
  // ── 정보 카드 ──
  { id: 'w-user-status', icon: '👤', name: '사용자 현황', cat: 'card', desc: '역할별 사용자 분포 및 접속 현황', color: '#5c6bc0', roles: ['admin'], dataLevel: 'confidential',
    svg:'<svg viewBox="0 0 180 50"><text x="5" y="12" font-size="8" fill="#5c6bc0">관리자</text><rect x="45" y="5" width="40" height="8" fill="#5c6bc0" rx="2"/><text x="90" y="12" font-size="7" fill="#666">12명</text><text x="5" y="26" font-size="8" fill="#42a5f5">엔지니어</text><rect x="45" y="19" width="65" height="8" fill="#42a5f5" rx="2"/><text x="115" y="26" font-size="7" fill="#666">24명</text><text x="5" y="40" font-size="8" fill="#26a69a">일반</text><rect x="45" y="33" width="100" height="8" fill="#26a69a" rx="2"/><text x="150" y="40" font-size="7" fill="#666">86명</text></svg>' },
  { id: 'w-sys-monitor', icon: '🖥️', name: '시스템 모니터링', cat: 'card', desc: 'Portal/DB/Kafka/Spark 서버 헬스', color: '#26a69a', roles: ['engineer','admin'], dataLevel: 'restricted',
    svg:'<svg viewBox="0 0 180 50"><text x="5" y="12" font-size="8" fill="#52c41a">● Portal</text><text x="55" y="12" font-size="7" fill="#52c41a">정상</text><text x="95" y="12" font-size="8" fill="#52c41a">● DB</text><text x="125" y="12" font-size="7" fill="#52c41a">정상</text><text x="5" y="28" font-size="8" fill="#52c41a">● Kafka</text><text x="55" y="28" font-size="7" fill="#52c41a">정상</text><text x="95" y="28" font-size="8" fill="#fa8c16">▲ Spark</text><text x="138" y="28" font-size="7" fill="#fa8c16">주의</text><text x="5" y="44" font-size="8" fill="#52c41a">● NiFi</text><text x="55" y="44" font-size="7" fill="#52c41a">정상</text><text x="95" y="44" font-size="8" fill="#52c41a">● HDFS</text><text x="138" y="44" font-size="7" fill="#52c41a">정상</text></svg>' },
  { id: 'w-audit-log', icon: '📋', name: '보안/감사 로그', cat: 'card', desc: '접근이력, 권한변경, 감사 로그', color: '#ef5350', roles: ['admin'], dataLevel: 'confidential',
    svg:'<svg viewBox="0 0 180 50"><rect x="3" y="3" width="174" height="12" fill="#fff1f0" rx="2"/><text x="8" y="12" font-size="7" fill="#ef5350">10:32 비정상 접근 시도 — 외부IP</text><rect x="3" y="18" width="174" height="12" fill="#f6ffed" rx="2"/><text x="8" y="27" font-size="7" fill="#52c41a">10:15 권한변경 — 김수자원 → 관리자</text><rect x="3" y="33" width="174" height="12" fill="#e6f7ff" rx="2"/><text x="8" y="42" font-size="7" fill="#1677ff">09:58 데이터 내보내기 — 박계측</text></svg>' },
  { id: 'w-my-work', icon: '📋', name: '나의 업무현황', cat: 'card', desc: '승인대기/즐겨찾기/최근항목/진행현황', color: '#1677ff', roles: ['employee','engineer','admin'], dataLevel: 'internal',
    svg:'<svg viewBox="0 0 180 50"><text x="5" y="12" font-size="8" fill="#1677ff" font-weight="600">승인대기</text><text x="55" y="12" font-size="10" fill="#1677ff" font-weight="700">3</text><text x="85" y="12" font-size="8" fill="#fa8c16" font-weight="600">즐겨찾기</text><text x="135" y="12" font-size="10" fill="#fa8c16" font-weight="700">12</text><text x="5" y="30" font-size="8" fill="#52c41a" font-weight="600">진행중</text><text x="55" y="30" font-size="10" fill="#52c41a" font-weight="700">5</text><text x="85" y="30" font-size="8" fill="#888" font-weight="600">완료</text><text x="135" y="30" font-size="10" fill="#888" font-weight="700">28</text><text x="5" y="46" font-size="7" fill="#aaa">최근: 수질데이터 품질검증 (10분전)</text></svg>' },
  { id: 'w-sys-alert', icon: '🔔', name: '시스템 알림', cat: 'card', desc: '실시간 시스템/장애/점검 알림', color: '#ff9800', roles: ['employee','engineer','admin'], dataLevel: 'internal',
    svg:'<svg viewBox="0 0 180 50"><rect x="3" y="3" width="174" height="12" fill="#fff7e6" rx="2"/><text x="8" y="12" font-size="7" fill="#fa8c16">🟡 Spark Worker 메모리 85% 도달</text><rect x="3" y="18" width="174" height="12" fill="#e6f7ff" rx="2"/><text x="8" y="27" font-size="7" fill="#1677ff">🔵 정기점검 예정: 03/05 02:00~06:00</text><rect x="3" y="33" width="174" height="12" fill="#f6ffed" rx="2"/><text x="8" y="42" font-size="7" fill="#52c41a">🟢 DB백업 완료: 03/03 03:00</text></svg>' },
  { id: 'w-batch-status', icon: '⏱️', name: '배치 작업 현황', cat: 'card', desc: '일간/주간 배치 작업 실행 현황', color: '#00897b', roles: ['engineer','admin'], dataLevel: 'restricted',
    svg:'<svg viewBox="0 0 180 50"><text x="5" y="12" font-size="8" fill="#52c41a">● 성공 45</text><text x="65" y="12" font-size="8" fill="#f5222d">● 실패 2</text><text x="120" y="12" font-size="8" fill="#fa8c16">● 실행중 3</text><rect x="5" y="18" width="170" height="8" fill="#e0f2f1" rx="3"/><rect x="5" y="18" width="153" height="8" fill="#00897b" rx="3"/><rect x="158" y="18" width="7" height="8" fill="#f5222d" rx="1"/><text x="5" y="40" font-size="7" fill="#888">다음 배치: ETL-수질수량 (15분 후)</text></svg>' },
  { id: 'w-data-catalog', icon: '🗂️', name: '데이터 카탈로그', cat: 'card', desc: '등록 데이터셋/메타데이터 현황', color: '#7b1fa2', roles: ['employee','engineer','admin'], dataLevel: 'internal',
    svg:'<svg viewBox="0 0 180 50"><text x="5" y="14" font-size="9" fill="#7b1fa2" font-weight="700">총 2,847개</text><text x="75" y="14" font-size="8" fill="#888">데이터셋</text><text x="5" y="28" font-size="7" fill="#52c41a">● 공개 1,240</text><text x="70" y="28" font-size="7" fill="#1677ff">● 내부 1,102</text><text x="140" y="28" font-size="7" fill="#fa8c16">● 제한 505</text><text x="5" y="42" font-size="7" fill="#888">메타 커버리지: </text><rect x="75" y="36" width="60" height="6" fill="#f3e5f5" rx="3"/><rect x="75" y="36" width="48" height="6" fill="#7b1fa2" rx="3"/><text x="140" y="42" font-size="7" fill="#7b1fa2">82%</text></svg>' },
  { id: 'w-scheduler', icon: '📅', name: '스케줄러 현황', cat: 'card', desc: 'Airflow/NiFi 스케줄 작업 상태', color: '#1565c0', roles: ['engineer','admin'], dataLevel: 'restricted',
    svg:'<svg viewBox="0 0 180 50"><text x="5" y="12" font-size="8" fill="#52c41a">● Airflow</text><text x="60" y="12" font-size="7" fill="#52c41a">정상 (DAG 32개)</text><text x="5" y="26" font-size="8" fill="#52c41a">● NiFi</text><text x="60" y="26" font-size="7" fill="#52c41a">정상 (Flow 18개)</text><text x="5" y="40" font-size="8" fill="#fa8c16">▲ Cron</text><text x="60" y="40" font-size="7" fill="#fa8c16">지연 1건 (ETL-03)</text></svg>' },
  // ── 목록/테이블 ──
  { id: 'w-notices', icon: '📢', name: '공지사항', cat: 'list', desc: '긴급/정책/시스템/교육 공지 목록', color: '#ffa726', roles: 'all', dataLevel: 'public',
    svg:'<svg viewBox="0 0 180 50"><text x="5" y="12" font-size="7" fill="#f5222d">🔴 [긴급] 시스템 정기점검 안내 (3/5)</text><text x="5" y="24" font-size="7" fill="#fa8c16">🟡 [정책] 데이터 보존 규정 변경</text><text x="5" y="36" font-size="7" fill="#1677ff">🔵 [안내] 신규 API v2.1 배포</text><text x="5" y="48" font-size="7" fill="#888">🔘 [교육] 데이터 분석 교육 3기 모집</text></svg>' },
  { id: 'w-popular', icon: '🏆', name: '인기 데이터 TOP', cat: 'list', desc: '가장 많이 조회된 데이터셋 순위', color: '#ec407a', roles: 'all', dataLevel: 'public',
    svg:'<svg viewBox="0 0 180 50"><text x="5" y="12" font-size="8" fill="#ec407a">🥇 광역상수도 유량 데이터 (2.4k)</text><text x="5" y="26" font-size="8" fill="#fa8c16">🥈 수력발전 일간통계 (1.8k)</text><text x="5" y="40" font-size="8" fill="#faad14">🥉 댐 수위 실시간 (1.2k)</text></svg>' },
  { id: 'w-recent-update', icon: '🕐', name: '최근 업데이트', cat: 'list', desc: '최근 갱신된 데이터 목록', color: '#78909c', roles: ['employee','engineer','admin'], dataLevel: 'internal',
    svg:'<svg viewBox="0 0 180 50"><text x="5" y="12" font-size="7" fill="#78909c">10분전</text><text x="40" y="12" font-size="7" fill="#333">수질측정 - 낙동강 2지점</text><text x="5" y="24" font-size="7" fill="#78909c">25분전</text><text x="40" y="24" font-size="7" fill="#333">댐 수위 - 소양강댐</text><text x="5" y="36" font-size="7" fill="#78909c">42분전</text><text x="40" y="36" font-size="7" fill="#333">기상관측 - 전국 AWS</text><text x="5" y="48" font-size="7" fill="#78909c">1시간전</text><text x="40" y="48" font-size="7" fill="#333">에너지 - 수력발전 현황</text></svg>' },
  { id: 'w-approval', icon: '📝', name: '결재/승인 현황', cat: 'list', desc: '나의 결재대기 및 승인이력 요약', color: '#fa8c16', roles: ['employee','engineer','admin'], dataLevel: 'internal',
    svg:'<svg viewBox="0 0 180 50"><text x="5" y="12" font-size="7" fill="#fa8c16">⏳ 데이터 다운로드 요청 — 대기중</text><text x="5" y="24" font-size="7" fill="#fa8c16">⏳ API 키 발급 신청 — 대기중</text><text x="5" y="36" font-size="7" fill="#52c41a">✅ 권한 변경 요청 — 승인완료</text><text x="5" y="48" font-size="7" fill="#52c41a">✅ 데이터셋 등록 — 승인완료</text></svg>' },
  { id: 'w-error-log', icon: '🐛', name: '에러 로그', cat: 'list', desc: '최근 시스템 에러/예외 로그 목록', color: '#d32f2f', roles: ['engineer','admin'], dataLevel: 'confidential',
    svg:'<svg viewBox="0 0 180 50"><rect x="3" y="3" width="174" height="12" fill="#fff1f0" rx="2"/><text x="8" y="12" font-size="7" fill="#d32f2f">10:31 NullPointerException — ETL-03</text><rect x="3" y="18" width="174" height="12" fill="#fff1f0" rx="2"/><text x="8" y="27" font-size="7" fill="#d32f2f">10:15 TimeoutException — API Gateway</text><rect x="3" y="33" width="174" height="12" fill="#fff7e6" rx="2"/><text x="8" y="42" font-size="7" fill="#fa8c16">09:58 SlowQuery Warning — 수질DB</text></svg>' },
  { id: 'w-download-stats', icon: '💿', name: '데이터 다운로드 현황', cat: 'list', desc: '금일 데이터 다운로드 이력 현황', color: '#0277bd', roles: ['employee','engineer','admin'], dataLevel: 'internal',
    svg:'<svg viewBox="0 0 180 50"><text x="5" y="12" font-size="7" fill="#0277bd">📥 김수자원 — 댐수위데이터 (24MB)</text><text x="5" y="24" font-size="7" fill="#0277bd">📥 이수질 — 수질측정 전국 (156MB)</text><text x="5" y="36" font-size="7" fill="#0277bd">📥 박계측 — 유량관측 월보 (38MB)</text><text x="5" y="48" font-size="8" fill="#888">금일 총 47건 · 2.1GB</text></svg>' },
  // ── 차트 ──
  { id: 'w-quality-bar', icon: '📊', name: '품질 현황 차트', cat: 'chart', desc: '완전성/정합성/유효성/적시성 바', color: '#66bb6a', roles: 'all', dataLevel: 'public',
    svg:'<svg viewBox="0 0 180 50"><text x="5" y="10" font-size="6" fill="#888">완전성</text><rect x="40" y="4" width="130" height="7" fill="#e8f5e9" rx="2"/><rect x="40" y="4" width="122" height="7" fill="#66bb6a" rx="2"/><text x="5" y="22" font-size="6" fill="#888">정합성</text><rect x="40" y="16" width="130" height="7" fill="#e8f5e9" rx="2"/><rect x="40" y="16" width="115" height="7" fill="#81c784" rx="2"/><text x="5" y="34" font-size="6" fill="#888">유효성</text><rect x="40" y="28" width="130" height="7" fill="#e8f5e9" rx="2"/><rect x="40" y="28" width="105" height="7" fill="#a5d6a7" rx="2"/><text x="5" y="46" font-size="6" fill="#888">적시성</text><rect x="40" y="40" width="130" height="7" fill="#e8f5e9" rx="2"/><rect x="40" y="40" width="128" height="7" fill="#66bb6a" rx="2"/></svg>' },
  { id: 'w-resource', icon: '⚙️', name: '시스템 리소스', cat: 'chart', desc: 'CPU/메모리/디스크/네트워크 게이지', color: '#8d6e63', roles: ['engineer','admin'], dataLevel: 'confidential',
    svg:'<svg viewBox="0 0 180 50"><text x="8" y="12" font-size="7" fill="#888">CPU</text><rect x="35" y="5" width="100" height="8" fill="#f0f0f0" rx="3"/><rect x="35" y="5" width="72" height="8" fill="#52c41a" rx="3"/><text x="140" y="12" font-size="7" fill="#666">72%</text><text x="8" y="28" font-size="7" fill="#888">MEM</text><rect x="35" y="21" width="100" height="8" fill="#f0f0f0" rx="3"/><rect x="35" y="21" width="85" height="8" fill="#fa8c16" rx="3"/><text x="140" y="28" font-size="7" fill="#666">85%</text><text x="8" y="44" font-size="7" fill="#888">DISK</text><rect x="35" y="37" width="100" height="8" fill="#f0f0f0" rx="3"/><rect x="35" y="37" width="63" height="8" fill="#1677ff" rx="3"/><text x="140" y="44" font-size="7" fill="#666">63%</text></svg>' },
  { id: 'w-collection-trend', icon: '📈', name: '수집 추이 차트', cat: 'chart', desc: '일별/시간별 데이터 수집 추이 그래프', color: '#00acc1', roles: ['employee','engineer','admin'], dataLevel: 'internal',
    svg:'<svg viewBox="0 0 180 50"><polyline points="5,42 25,38 45,40 65,30 85,32 105,22 125,25 145,18 165,20" fill="none" stroke="#00acc1" stroke-width="2"/><path d="M5,42 L25,38 L45,40 L65,30 L85,32 L105,22 L125,25 L145,18 L165,20 V48 H5Z" fill="#e0f7fa" opacity="0.5"/></svg>' },
  { id: 'w-api-latency', icon: '⏱️', name: 'API 응답시간', cat: 'chart', desc: 'API 엔드포인트별 평균 응답시간', color: '#e91e63', roles: ['engineer','admin'], dataLevel: 'restricted',
    svg:'<svg viewBox="0 0 180 50"><polyline points="5,30 25,28 45,35 65,22 85,25 105,18 125,32 145,15 165,20" fill="none" stroke="#e91e63" stroke-width="2"/><line x1="5" y1="35" x2="175" y2="35" stroke="#f5222d" stroke-width="1" stroke-dasharray="4,3"/><text x="140" y="44" font-size="6" fill="#f5222d">SLA 200ms</text></svg>' },
  { id: 'w-disk-trend', icon: '💽', name: '디스크 사용 추이', cat: 'chart', desc: 'HDFS/DB 디스크 사용량 변화 추이', color: '#6d4c41', roles: ['engineer','admin'], dataLevel: 'restricted',
    svg:'<svg viewBox="0 0 180 50"><path d="M5,42 Q30,40 55,38 T105,32 T155,24 L175,22 V48 H5Z" fill="#efebe9" stroke="#6d4c41" stroke-width="1.5"/><path d="M5,46 Q30,44 55,43 T105,40 T155,36 L175,34 V48 H5Z" fill="#d7ccc850" stroke="#8d6e63" stroke-width="1" stroke-dasharray="3,2"/><line x1="5" y1="15" x2="175" y2="15" stroke="#f5222d" stroke-width="1" stroke-dasharray="4,3"/><text x="140" y="13" font-size="6" fill="#f5222d">임계 90%</text></svg>' },
  // ── 연계·적재 모니터링 (Sub_No 001~005 보강) ──
  { id: 'w-link-progress', icon: '🔗', name: '연계 데이터 진행상태', cat: 'chart', desc: '시스템별 데이터 수집/처리 상태 실시간 집계', color: '#1677ff', roles: ['employee','engineer','admin'], dataLevel: 'internal',
    svg:'<svg viewBox="0 0 180 50"><text x="5" y="10" font-size="6" fill="#888">SAP</text><rect x="28" y="4" width="70" height="7" fill="#e6f7ff" rx="2"/><rect x="28" y="4" width="63" height="7" fill="#1677ff" rx="2"/><text x="102" y="10" font-size="6" fill="#52c41a">90%</text><text x="5" y="22" font-size="6" fill="#888">RWIS</text><rect x="28" y="16" width="70" height="7" fill="#e6f7ff" rx="2"/><rect x="28" y="16" width="56" height="7" fill="#40a9ff" rx="2"/><text x="102" y="22" font-size="6" fill="#52c41a">80%</text><text x="5" y="34" font-size="6" fill="#888">SCADA</text><rect x="28" y="28" width="70" height="7" fill="#e6f7ff" rx="2"/><rect x="28" y="28" width="67" height="7" fill="#096dd9" rx="2"/><text x="102" y="34" font-size="6" fill="#52c41a">96%</text><text x="5" y="46" font-size="6" fill="#888">기상청</text><rect x="28" y="40" width="70" height="7" fill="#e6f7ff" rx="2"/><rect x="28" y="40" width="49" height="7" fill="#69b1ff" rx="2"/><text x="102" y="46" font-size="6" fill="#fa8c16">70%</text></svg>' },
  { id: 'w-link-error', icon: '🚨', name: '연계 데이터 오류현황', cat: 'chart', desc: '연계 시스템별 오류 발생 건수 및 실시간 알림', color: '#f5222d', roles: ['employee','engineer','admin'], dataLevel: 'internal',
    svg:'<svg viewBox="0 0 180 50"><text x="5" y="10" font-size="7" fill="#f5222d" font-weight="600">오류 합계: 14건</text><text x="100" y="10" font-size="6" fill="#fa8c16">경고: 8건</text><rect x="5" y="15" width="170" height="10" fill="#fff1f0" rx="2"/><text x="8" y="23" font-size="6" fill="#cf1322">SAP-ETL 타임아웃 5건 · RWIS 인증오류 3건</text><rect x="5" y="28" width="170" height="10" fill="#fff7e6" rx="2"/><text x="8" y="36" font-size="6" fill="#ad6800">기상청API 응답지연 4건 · SCADA 연결끊김 2건</text><text x="5" y="47" font-size="6" fill="#888">최근발생: 11:42 SAP-ETL NullPointerException</text></svg>' },
  { id: 'w-load-stage', icon: '📦', name: '적재 단계별 진행현황', cat: 'chart', desc: '데이터 수집→정제→적재→분석 단계별 처리 실적 시각화', color: '#13c2c2', roles: ['employee','engineer','admin'], dataLevel: 'internal',
    svg:'<svg viewBox="0 0 180 50"><text x="5" y="10" font-size="6" fill="#888">수집</text><rect x="28" y="4" width="55" height="7" fill="#e6fffb" rx="2"/><rect x="28" y="4" width="52" height="7" fill="#13c2c2" rx="2"/><text x="88" y="10" font-size="6" fill="#13c2c2">1.24M</text><text x="5" y="22" font-size="6" fill="#888">정제</text><rect x="28" y="16" width="55" height="7" fill="#e6fffb" rx="2"/><rect x="28" y="16" width="46" height="7" fill="#36cfc9" rx="2"/><text x="88" y="22" font-size="6" fill="#36cfc9">1.08M</text><text x="5" y="34" font-size="6" fill="#888">적재</text><rect x="28" y="28" width="55" height="7" fill="#e6fffb" rx="2"/><rect x="28" y="28" width="42" height="7" fill="#08979c" rx="2"/><text x="88" y="34" font-size="6" fill="#08979c">982K</text><text x="5" y="46" font-size="6" fill="#888">분석</text><rect x="28" y="40" width="55" height="7" fill="#e6fffb" rx="2"/><rect x="28" y="40" width="38" height="7" fill="#006d75" rx="2"/><text x="88" y="46" font-size="6" fill="#006d75">874K</text><polyline points="120,8 135,8 135,20" fill="none" stroke="#ccc" stroke-width="1" marker-end="url(#arr)"/><polyline points="120,20 135,20 135,32" fill="none" stroke="#ccc" stroke-width="1"/><polyline points="120,32 135,32 135,44" fill="none" stroke="#ccc" stroke-width="1"/></svg>' },
  { id: 'w-load-error', icon: '⚠️', name: '적재 오류 시각화', cat: 'chart', desc: '적재 단계별 오류 발생 현황 모니터링 및 시각적 알림', color: '#eb2f96', roles: ['engineer','admin'], dataLevel: 'restricted',
    svg:'<svg viewBox="0 0 180 50"><text x="5" y="10" font-size="6" fill="#888">수집오류</text><rect x="42" y="4" width="12" height="7" fill="#ff4d4f" rx="1"/><text x="58" y="10" font-size="6" fill="#cf1322">23</text><text x="80" y="10" font-size="6" fill="#888">정제오류</text><rect x="115" y="4" width="8" height="7" fill="#ff7875" rx="1"/><text x="127" y="10" font-size="6" fill="#cf1322">15</text><text x="5" y="24" font-size="6" fill="#888">적재오류</text><rect x="42" y="18" width="5" height="7" fill="#ffa39e" rx="1"/><text x="51" y="24" font-size="6" fill="#cf1322">8</text><text x="80" y="24" font-size="6" fill="#888">스키마</text><rect x="115" y="18" width="3" height="7" fill="#ffccc7" rx="1"/><text x="122" y="24" font-size="6" fill="#cf1322">4</text><polyline points="5,34 30,38 55,32 80,36 105,30 130,34 155,28 180,32" fill="none" stroke="#eb2f96" stroke-width="1.5"/><text x="5" y="48" font-size="6" fill="#eb2f96">7일 추이 ↘ 감소세 (전주 대비 -18%)</text></svg>' },
  { id: 'w-system-data', icon: '🗄️', name: '시스템별 보유 데이터', cat: 'chart', desc: '시스템(분류)별 보유 데이터 양 및 최근 변동 내역 통계', color: '#2f54eb', roles: ['employee','engineer','admin'], dataLevel: 'internal',
    svg:'<svg viewBox="0 0 180 50"><text x="5" y="10" font-size="6" fill="#888">수문DB</text><rect x="38" y="4" width="50" height="7" fill="#2f54eb" rx="2"/><text x="92" y="10" font-size="6" fill="#2f54eb">842K</text><text x="120" y="10" font-size="6" fill="#52c41a">▲2.1%</text><text x="5" y="22" font-size="6" fill="#888">수질DB</text><rect x="38" y="16" width="42" height="7" fill="#597ef7" rx="2"/><text x="84" y="22" font-size="6" fill="#597ef7">621K</text><text x="120" y="22" font-size="6" fill="#52c41a">▲1.5%</text><text x="5" y="34" font-size="6" fill="#888">기상DB</text><rect x="38" y="28" width="35" height="7" fill="#85a5ff" rx="2"/><text x="77" y="34" font-size="6" fill="#85a5ff">487K</text><text x="120" y="34" font-size="6" fill="#fa8c16">-0.3%</text><text x="5" y="46" font-size="6" fill="#888">에너지DB</text><rect x="38" y="40" width="28" height="7" fill="#adc6ff" rx="2"/><text x="70" y="46" font-size="6" fill="#adc6ff">356K</text><text x="120" y="46" font-size="6" fill="#52c41a">▲3.8%</text></svg>' }
];

var wsPlacedWidgets = []; // IDs of widgets on canvas
// localStorage에서 저장된 위젯 배치 복원
(function restoreWsLayout() {
  try {
    var saved = localStorage.getItem('portal-ws-widgets');
    if (saved) {
      wsPlacedWidgets = JSON.parse(saved);
      var sizes = localStorage.getItem('portal-ws-sizes');
      if (sizes) {
        var sizeMap = JSON.parse(sizes);
        Object.keys(sizeMap).forEach(function(wid) {
          var w = WS_WIDGETS.find(function(x) { return x.id === wid; });
          if (w) { w._size = sizeMap[wid].size; w._height = sizeMap[wid].height; }
        });
      }
    }
  } catch (e) { /* 파싱 실패 시 기본값 유지 */ }
})();

function initWidgetSettingsGrid() {
  // no AG Grid needed; render widget library instead
  wsRenderLibrary();
  wsRenderTemplates();
}

function wsRenderLibrary() {
  var lib = document.getElementById('ws-library');
  if (!lib) return;
  lib.innerHTML = '';
  var search = (document.getElementById('ws-search') || {}).value || '';
  search = search.toLowerCase();
  var cat = (document.getElementById('ws-category-filter') || {}).value || 'all';
  var noResult = document.getElementById('ws-no-results');
  var shown = 0;

  WS_WIDGETS.forEach(function(w) {
    // skip if already on canvas
    if (wsPlacedWidgets.indexOf(w.id) !== -1) return;
    // RBAC + 데이터 등급 필터
    if (!canAccessItem(w)) return;
    // filter
    if (cat !== 'all' && w.cat !== cat) return;
    if (search && w.name.toLowerCase().indexOf(search) === -1 && w.desc.toLowerCase().indexOf(search) === -1) return;

    shown++;
    var card = document.createElement('div');
    card.setAttribute('draggable', 'true');
    card.setAttribute('data-widget-id', w.id);
    card.style.cssText = 'border:1.5px solid #e8e8e8; border-radius:10px; padding:14px; cursor:grab; transition:all 0.2s; user-select:none;';
    card.onmouseenter = function() { card.style.borderColor = '#1677ff'; card.style.boxShadow = '0 2px 8px rgba(22,119,255,0.15)'; };
    card.onmouseleave = function() { card.style.borderColor = '#e8e8e8'; card.style.boxShadow = 'none'; };
    card.ondragstart = function(e) {
      e.dataTransfer.setData('text/plain', w.id);
      e.dataTransfer.effectAllowed = 'move';
      card.style.opacity = '0.5';
      setTimeout(function() { wsHighlightCanvas(true); }, 0);
    };
    card.ondragend = function() {
      card.style.opacity = '1';
      wsHighlightCanvas(false);
    };
    card.ondblclick = function() {
      if (wsPlacedWidgets.indexOf(w.id) !== -1) return;
      wsPlacedWidgets.push(w.id);
      wsRenderCanvas(); wsRenderLibrary(); wsUpdateCount();
    };

    var catLabel = { kpi: 'KPI', card: '카드', chart: '차트', list: '목록' }[w.cat] || w.cat;
    var catColor = { kpi: '#1565c0', card: '#7b1fa2', chart: '#2e7d32', list: '#e65100' }[w.cat] || '#666';
    var catBg = { kpi: '#e3f2fd', card: '#f3e5f5', chart: '#e8f5e9', list: '#fff3e0' }[w.cat] || '#f5f5f5';

    var svgHtml = w.svg ? '<div style="background:#fafafa; border-radius:6px; padding:6px; margin-bottom:8px; overflow:hidden;">' + w.svg + '</div>' : '';

    card.innerHTML =
      '<div style="display:flex; align-items:center; gap:10px; margin-bottom:8px;">' +
        '<div style="width:38px; height:38px; border-radius:10px; background:' + w.color + '15; display:flex; align-items:center; justify-content:center; font-size:20px;">' + w.icon + '</div>' +
        '<div style="flex:1; min-width:0;">' +
          '<div style="font-size:13px; font-weight:700; color:var(--text-color); white-space:nowrap; overflow:hidden; text-overflow:ellipsis;">' + w.name + '</div>' +
          '<div style="font-size:11px; color:var(--text-secondary); white-space:nowrap; overflow:hidden; text-overflow:ellipsis;">' + w.desc + '</div>' +
        '</div>' +
      '</div>' +
      svgHtml +
      '<div style="display:flex; gap:4px; align-items:center;">' +
        '<span style="font-size:10px; background:' + catBg + '; color:' + catColor + '; padding:1px 8px; border-radius:3px; font-weight:600;">' + catLabel + '</span>' +
        '<span style="font-size:10px; background:' + (DATA_LEVEL_BG[w.dataLevel]||'#f5f5f5') + '; color:' + (DATA_LEVEL_COLORS[w.dataLevel]||'#999') + '; padding:1px 8px; border-radius:3px; font-weight:600;">' + (DATA_LEVEL_LABELS[w.dataLevel]||'') + '</span>' +
        '<span style="font-size:10px; color:#aaa; margin-left:auto;">드래그/더블클릭 ↑</span>' +
      '</div>';

    lib.appendChild(card);
  });

  if (noResult) noResult.style.display = shown === 0 ? 'block' : 'none';
  var libCount = document.getElementById('ws-lib-count');
  if (libCount) libCount.textContent = '— ' + shown + '개 위젯 사용 가능';
}

function wsFilterWidgets() { wsRenderLibrary(); }

function wsHighlightCanvas(on) {
  var canvas = document.getElementById('ws-canvas');
  if (!canvas) return;
  if (on) {
    canvas.style.borderColor = '#1677ff';
    canvas.style.background = 'repeating-linear-gradient(45deg, #f0f7ff, #f0f7ff 10px, #e8f0fe 10px, #e8f0fe 20px)';
  } else {
    canvas.style.borderColor = '#d9d9d9';
    canvas.style.background = 'repeating-linear-gradient(45deg, #fafbfc, #fafbfc 10px, #f5f7fa 10px, #f5f7fa 20px)';
  }
}

function wsCanvasDragOver(e) {
  e.preventDefault();
  e.dataTransfer.dropEffect = 'move';
}

function wsCanvasDragLeave(e) {
  // only if leaving the canvas entirely
}

function wsCanvasDrop(e) {
  e.preventDefault();
  var wid = e.dataTransfer.getData('text/plain');
  if (!wid) return;
  wsHighlightCanvas(false);
  // don't add duplicates
  if (wsPlacedWidgets.indexOf(wid) !== -1) return;
  wsPlacedWidgets.push(wid);
  wsRenderCanvas();
  wsRenderLibrary();
  wsUpdateCount();
}

var wsDragSrcIdx = null; // index of widget being dragged inside canvas

function wsRenderCanvas() {
  var canvas = document.getElementById('ws-canvas');
  if (!canvas) return;
  canvas.innerHTML = '';
  var empty = document.createElement('div');
  empty.id = 'ws-canvas-empty';
  empty.style.cssText = 'grid-column:1/-1; display:flex; flex-direction:column; align-items:center; justify-content:center; padding:60px 0; color:#bbb;';
  empty.innerHTML = '<div style="font-size:48px; margin-bottom:12px;">📦</div><div style="font-size:15px; font-weight:600;">위젯을 여기에 드래그하여 배치하세요</div><div style="font-size:12px; margin-top:4px;">아래 위젯 라이브러리에서 원하는 위젯을 끌어 놓으면 대시보드에 추가됩니다</div>';
  if (wsPlacedWidgets.length === 0) {
    canvas.appendChild(empty);
    return;
  }

  wsPlacedWidgets.forEach(function(wid, idx) {
    var w = WS_WIDGETS.find(function(x) { return x.id === wid; });
    if (!w) return;
    if (!canAccessItem(w)) return;
    var size = w._size || 1;
    var hSize = w._height || 1;
    var el = document.createElement('div');
    el.setAttribute('data-placed-id', w.id);
    el.setAttribute('data-placed-idx', idx);
    el.setAttribute('draggable', 'true');
    var minH = hSize === 1 ? '80px' : hSize === 2 ? '180px' : '280px';
    el.style.cssText = 'background:#fff; border:1.5px solid #e8e8e8; border-radius:10px; padding:12px; position:relative; grid-column:span ' + size + '; grid-row:span ' + hSize + '; transition:all 0.2s; min-height:' + minH + '; cursor:grab; display:flex; flex-direction:column;';

    // --- canvas internal drag events ---
    el.addEventListener('dragstart', function(e) {
      wsDragSrcIdx = idx;
      e.dataTransfer.setData('text/plain', 'canvas:' + w.id);
      e.dataTransfer.effectAllowed = 'move';
      el.style.opacity = '0.4';
      el.style.border = '2px dashed #1677ff';
    });
    el.addEventListener('dragend', function() {
      el.style.opacity = '1';
      el.style.border = '1.5px solid #e8e8e8';
      wsDragSrcIdx = null;
      // clear all drop indicators
      canvas.querySelectorAll('[data-placed-id]').forEach(function(c) {
        c.style.boxShadow = 'none';
        c.style.borderLeft = '';
        c.style.borderRight = '';
      });
    });
    el.addEventListener('dragover', function(e) {
      e.preventDefault();
      e.dataTransfer.dropEffect = 'move';
      // show drop indicator
      var data = e.dataTransfer.types.indexOf('text/plain') !== -1;
      if (wsDragSrcIdx !== null && wsDragSrcIdx !== idx) {
        var rect = el.getBoundingClientRect();
        var midX = rect.left + rect.width / 2;
        canvas.querySelectorAll('[data-placed-id]').forEach(function(c) {
          c.style.borderLeft = ''; c.style.borderRight = '';
        });
        if (e.clientX < midX) {
          el.style.borderLeft = '3px solid #1677ff';
        } else {
          el.style.borderRight = '3px solid #1677ff';
        }
      }
    });
    el.addEventListener('dragleave', function() {
      el.style.borderLeft = ''; el.style.borderRight = '';
    });
    el.addEventListener('drop', function(e) {
      e.preventDefault();
      e.stopPropagation();
      var payload = e.dataTransfer.getData('text/plain');
      // handle canvas-to-canvas reorder
      if (payload.indexOf('canvas:') === 0 && wsDragSrcIdx !== null && wsDragSrcIdx !== idx) {
        var rect = el.getBoundingClientRect();
        var midX = rect.left + rect.width / 2;
        var insertBefore = e.clientX < midX;
        var srcId = wsPlacedWidgets[wsDragSrcIdx];
        // remove from old position
        wsPlacedWidgets.splice(wsDragSrcIdx, 1);
        // find new target index (it may have shifted after removal)
        var targetIdx = wsPlacedWidgets.indexOf(wid);
        if (!insertBefore) targetIdx++;
        wsPlacedWidgets.splice(targetIdx, 0, srcId);
        wsDragSrcIdx = null;
        wsRenderCanvas();
        return;
      }
      // handle library-to-canvas drop (existing logic via wsCanvasDrop)
      if (payload && payload.indexOf('canvas:') !== 0) {
        if (wsPlacedWidgets.indexOf(payload) === -1) {
          // insert at this position instead of end
          var rect2 = el.getBoundingClientRect();
          var midX2 = rect2.left + rect2.width / 2;
          var insertIdx = idx;
          if (e.clientX >= midX2) insertIdx++;
          wsPlacedWidgets.splice(insertIdx, 0, payload);
          wsRenderCanvas();
          wsRenderLibrary();
          wsUpdateCount();
        }
      }
    });

    el.onmouseenter = function() {
      if (wsDragSrcIdx === null) { el.style.borderColor = w.color; el.style.boxShadow = '0 2px 8px ' + w.color + '22'; }
    };
    el.onmouseleave = function() {
      if (wsDragSrcIdx === null) { el.style.borderColor = '#e8e8e8'; el.style.boxShadow = 'none'; }
    };

    var catLabel = { kpi: 'KPI', card: '카드', chart: '차트', list: '목록' }[w.cat] || w.cat;

    // helper: generate size button HTML
    function sizeBtn(fn, val, cur, label) {
      var active = val === cur;
      return '<button onclick="' + fn + '(\'' + w.id + '\',' + val + ')" style="padding:2px 8px; font-size:10px; border:1px solid ' + (active ? '#1677ff' : '#d9d9d9') + '; background:' + (active ? '#e6f0ff' : '#fff') + '; color:' + (active ? '#1677ff' : '#666') + '; border-radius:4px; cursor:pointer; font-weight:600;">' + label + '</button>';
    }

    el.innerHTML =
      // drag handle + remove button
      '<div style="position:absolute; top:6px; right:6px; display:flex; gap:2px;">' +
        '<span title="드래그하여 순서 변경" style="cursor:grab; color:#ccc; font-size:14px; padding:2px 3px; border-radius:4px; user-select:none;" onmouseenter="this.style.color=\'#1677ff\';this.style.background=\'#f0f7ff\'" onmouseleave="this.style.color=\'#ccc\';this.style.background=\'none\'">⠿</span>' +
        '<button onclick="wsRemoveWidget(\'' + w.id + '\')" style="background:none; border:none; font-size:16px; cursor:pointer; color:#ccc; line-height:1; padding:2px 4px; border-radius:4px;" onmouseenter="this.style.color=\'#f44336\';this.style.background=\'#fff5f5\'" onmouseleave="this.style.color=\'#ccc\';this.style.background=\'none\'">&times;</button>' +
      '</div>' +
      // content
      '<div style="display:flex; align-items:center; gap:10px; margin-bottom:8px; padding-right:44px;">' +
        '<div style="width:36px; height:36px; border-radius:8px; background:' + w.color + '20; display:flex; align-items:center; justify-content:center; font-size:18px;">' + w.icon + '</div>' +
        '<div>' +
          '<div style="font-size:13px; font-weight:700; color:var(--text-color);">' + w.name + '</div>' +
          '<div style="font-size:11px; color:var(--text-secondary);">' + catLabel + ' · ' + w.desc.substring(0, 20) + '</div>' +
        '</div>' +
      '</div>' +
      // SVG preview content
      (w.svg ? '<div style="flex:1; background:#fafafa; border-radius:6px; padding:8px; display:flex; align-items:center; justify-content:center; margin-bottom:6px; overflow:hidden;">' + w.svg + '</div>' : '<div style="flex:1;"></div>') +
      // size controls area
      '<div style="display:flex; flex-direction:column; gap:4px; margin-top:4px;">' +
        // width row
        '<div style="display:flex; gap:4px; align-items:center;">' +
          '<span style="font-size:10px; color:var(--text-secondary); min-width:28px;">가로:</span>' +
          sizeBtn('wsResizeWidget', 1, size, '1칸') +
          sizeBtn('wsResizeWidget', 2, size, '2칸') +
          sizeBtn('wsResizeWidget', 3, size, '3칸') +
          '<span style="font-size:10px; color:#aaa; margin-left:auto;">순서 ' + (idx + 1) + '</span>' +
        '</div>' +
        // height row
        '<div style="display:flex; gap:4px; align-items:center;">' +
          '<span style="font-size:10px; color:var(--text-secondary); min-width:28px;">세로:</span>' +
          sizeBtn('wsResizeWidgetHeight', 1, hSize, '1행') +
          sizeBtn('wsResizeWidgetHeight', 2, hSize, '2행') +
          sizeBtn('wsResizeWidgetHeight', 3, hSize, '3행') +
        '</div>' +
      '</div>';

    canvas.appendChild(el);
  });
}

function wsRemoveWidget(wid) {
  wsPlacedWidgets = wsPlacedWidgets.filter(function(id) { return id !== wid; });
  // reset size
  var w = WS_WIDGETS.find(function(x) { return x.id === wid; });
  if (w) { delete w._size; delete w._height; }
  wsRenderCanvas();
  wsRenderLibrary();
  wsUpdateCount();
}

function wsResizeWidget(wid, size) {
  var w = WS_WIDGETS.find(function(x) { return x.id === wid; });
  if (w) w._size = size;
  wsRenderCanvas();
}

function wsResizeWidgetHeight(wid, h) {
  var w = WS_WIDGETS.find(function(x) { return x.id === wid; });
  if (w) w._height = h;
  wsRenderCanvas();
}

function wsChangeColumns(cols) {
  var canvas = document.getElementById('ws-canvas');
  if (canvas) {
    canvas.style.gridTemplateColumns = 'repeat(' + cols + ', 1fr)';
    canvas.style.gridAutoRows = 'minmax(100px, auto)';
  }
}

function wsUpdateCount() {
  var el = document.getElementById('ws-placed-count');
  if (el) el.textContent = wsPlacedWidgets.length;
}

function wsClearCanvas() {
  if (wsPlacedWidgets.length === 0) return;
  if (!confirm('배치된 모든 위젯을 제거하시겠습니까?')) return;
  wsPlacedWidgets.forEach(function(wid) {
    var w = WS_WIDGETS.find(function(x) { return x.id === wid; });
    if (w) { delete w._size; delete w._height; }
  });
  wsPlacedWidgets = [];
  wsRenderCanvas();
  wsRenderLibrary();
  wsUpdateCount();
}

/* ===== 위젯 템플릿 정의 ===== */
var WS_TEMPLATES = [
  {
    id: 'tpl-basic',
    name: '기본형',
    icon: '📊',
    desc: '주요 KPI 지표와 기본 정보 카드로 구성된 범용 대시보드',
    color: '#1677ff',
    widgets: ['w-active-users', 'w-availability', 'w-security', 'w-storage', 'w-user-status', 'w-sys-monitor', 'w-audit-log']
  },
  {
    id: 'tpl-stats',
    name: '통계형',
    icon: '📈',
    desc: '데이터 품질·수집 추이·활용 통계 중심의 분석 대시보드',
    color: '#52c41a',
    widgets: ['w-quality', 'w-quality-bar', 'w-collection-trend', 'w-popular', 'w-download-stats', 'w-data-catalog', 'w-system-data']
  },
  {
    id: 'tpl-monitor',
    name: '모니터링형',
    icon: '🖥️',
    desc: '파이프라인·연계·적재 현황을 실시간 모니터링하는 대시보드',
    color: '#fa8c16',
    widgets: ['w-pipeline', 'w-collection', 'w-link-progress', 'w-link-error', 'w-load-stage', 'w-load-error', 'w-error-log', 'w-collection-trend']
  },
  {
    id: 'tpl-admin',
    name: '관리형',
    icon: '🛡️',
    desc: '보안·사용자·감사·시스템 관리 중심의 운영 대시보드',
    color: '#722ed1',
    widgets: ['w-active-users', 'w-security', 'w-availability', 'w-storage', 'w-audit-log', 'w-sys-monitor', 'w-user-status', 'w-notices']
  }
];

function wsLoadDefault() {
  wsShowTemplateSelector();
}

/* 템플릿 선택 UI 토글 */
function wsShowTemplateSelector() {
  var box = document.getElementById('ws-template-box');
  if (box) { box.style.display = box.style.display === 'none' ? 'block' : 'none'; }
}

/* 템플릿 적용 */
function wsApplyTemplate(tplId) {
  var tpl = WS_TEMPLATES.find(function(t) { return t.id === tplId; });
  if (!tpl) return;
  // 기존 위젯 초기화
  wsPlacedWidgets.forEach(function(wid) {
    var w = WS_WIDGETS.find(function(x) { return x.id === wid; });
    if (w) { delete w._size; delete w._height; }
  });
  // 유효한 위젯만 필터
  wsPlacedWidgets = tpl.widgets.filter(function(wid) {
    return WS_WIDGETS.some(function(x) { return x.id === wid; });
  });
  wsRenderCanvas();
  wsRenderLibrary();
  wsUpdateCount();
  // 템플릿 선택 UI에서 선택 표시 업데이트
  wsHighlightTemplate(tplId);
  showToast('\"' + tpl.name + '\" 템플릿이 적용되었습니다. 원하는 대로 수정 후 저장하세요.', 'success');
}

/* 템플릿 카드 선택 상태 표시 */
function wsHighlightTemplate(tplId) {
  var cards = document.querySelectorAll('.ws-tpl-card');
  cards.forEach(function(c) {
    if (c.dataset.tplId === tplId) {
      c.style.borderColor = '#1677ff';
      c.style.background = '#f0f7ff';
      c.querySelector('.ws-tpl-check').style.display = 'flex';
    } else {
      c.style.borderColor = '#e8e8e8';
      c.style.background = '#fff';
      c.querySelector('.ws-tpl-check').style.display = 'none';
    }
  });
}

/* 템플릿 선택 영역 렌더링 */
function wsRenderTemplates() {
  var container = document.getElementById('ws-template-grid');
  if (!container) return;
  container.innerHTML = '';
  WS_TEMPLATES.forEach(function(tpl) {
    var widgetNames = tpl.widgets.map(function(wid) {
      var w = WS_WIDGETS.find(function(x) { return x.id === wid; });
      return w ? w.name : wid;
    }).slice(0, 5);
    var more = tpl.widgets.length > 5 ? ' 외 ' + (tpl.widgets.length - 5) + '개' : '';
    var card = document.createElement('div');
    card.className = 'ws-tpl-card';
    card.dataset.tplId = tpl.id;
    card.style.cssText = 'border:2px solid #e8e8e8; border-radius:12px; padding:16px; cursor:pointer; transition:all 0.2s; position:relative; background:#fff;';
    card.onmouseenter = function() { if (this.style.borderColor !== 'rgb(22, 119, 255)') this.style.borderColor = '#91caff'; };
    card.onmouseleave = function() { if (this.style.borderColor !== 'rgb(22, 119, 255)') this.style.borderColor = '#e8e8e8'; };
    card.onclick = function() { wsApplyTemplate(tpl.id); };
    card.innerHTML =
      '<div class="ws-tpl-check" style="display:none; position:absolute; top:8px; right:8px; width:22px; height:22px; background:#1677ff; border-radius:50%; align-items:center; justify-content:center; color:#fff; font-size:13px; font-weight:700;">✓</div>' +
      '<div style="display:flex; align-items:center; gap:10px; margin-bottom:10px;">' +
        '<div style="width:40px; height:40px; background:' + tpl.color + '15; border-radius:10px; display:flex; align-items:center; justify-content:center; font-size:22px;">' + tpl.icon + '</div>' +
        '<div>' +
          '<div style="font-size:15px; font-weight:700; color:var(--text-color);">' + tpl.name + '</div>' +
          '<div style="font-size:11px; color:' + tpl.color + '; font-weight:600;">' + tpl.widgets.length + '개 위젯</div>' +
        '</div>' +
      '</div>' +
      '<div style="font-size:12px; color:var(--text-secondary); margin-bottom:10px; line-height:1.5;">' + tpl.desc + '</div>' +
      '<div style="display:flex; flex-wrap:wrap; gap:4px;">' +
        widgetNames.map(function(n) { return '<span style="font-size:10px; background:#f5f5f5; color:#666; padding:2px 7px; border-radius:10px; white-space:nowrap;">' + n + '</span>'; }).join('') +
        (more ? '<span style="font-size:10px; color:#999; padding:2px 4px;">' + more + '</span>' : '') +
      '</div>';
    container.appendChild(card);
  });
}

function wsSaveLayout() {
  if (wsPlacedWidgets.length === 0) {
    alert('배치된 위젯이 없습니다.\n위젯을 먼저 배치해 주세요.');
    return;
  }
  // 위젯 크기 정보도 함께 저장
  var sizeMap = {};
  wsPlacedWidgets.forEach(function(wid) {
    var w = WS_WIDGETS.find(function(x) { return x.id === wid; });
    if (w && (w._size || w._height)) {
      sizeMap[wid] = { size: w._size || 1, height: w._height || 1 };
    }
  });
  try {
    localStorage.setItem('portal-ws-widgets', JSON.stringify(wsPlacedWidgets));
    localStorage.setItem('portal-ws-sizes', JSON.stringify(sizeMap));
  } catch (e) { /* quota 초과 무시 */ }
  showToast('위젯 레이아웃이 저장되었습니다. (배치 ' + wsPlacedWidgets.length + '개)', 'success');
}

// ===== 실시간 로그·알림 =====
var LOG_SOURCES = [
  { id: 'SAP-ETL', label: 'SAP 재무 ETL', icon: '💼', color: '#1677ff' },
  { id: 'RWIS-CDC', label: '수위관측 CDC', icon: '🌊', color: '#13c2c2' },
  { id: 'METER-CDC', label: '스마트미터 CDC', icon: '📱', color: '#722ed1' },
  { id: 'KMA-API', label: '기상청 API', icon: '🌤️', color: '#fa8c16' },
  { id: 'ENV-API', label: '환경부 수질 API', icon: '🔬', color: '#52c41a' },
  { id: 'SCADA', label: 'SCADA 제어신호', icon: '📡', color: '#eb2f96' },
  { id: 'LEAK-IoT', label: '누수탐지 IoT', icon: '💦', color: '#2f54eb' },
  { id: 'DBT-RUN', label: 'dbt 변환엔진', icon: '⚙️', color: '#fa541c' }
];

var LOG_ENTRIES = [
  { ts: '2026-02-28 11:42:34.789', level: 'INFO', source: 'SAP-ETL', msg: '배치완료: 소요시간 4.67s, 성공률 100%', detail: 'BKPF → stg_sap_journal → fct_journal 파이프라인 정상종료' },
  { ts: '2026-02-28 11:42:33.456', level: 'INFO', source: 'SAP-ETL', msg: 'dbt 변환시작: stg_sap_journal → fct_journal', detail: 'dbt model run --select fct_journal' },
  { ts: '2026-02-28 11:42:33.012', level: 'INFO', source: 'RWIS-CDC', msg: '온톨로지 매핑: WaterLevel → obs:hasValue', detail: 'RDF 트리플 생성 완료, Neo4j 적재 대기' },
  { ts: '2026-02-28 11:42:32.345', level: 'INFO', source: 'SAP-ETL', msg: 'Neo4j 적재완료: 2,341건 노드/엣지 생성', detail: '그래프DB 적재 정상, 데이터 리니지 갱신' },
  { ts: '2026-02-28 11:42:32.001', level: 'ERROR', source: 'KMA-API', msg: '기상청 API 호출실패: HTTP 503 (재시도 3/3)', detail: 'Service Unavailable - 기상청 서버 점검 중 추정. 자동 일시정지 처리됨. 다음 재시도: 11:47:32' },
  { ts: '2026-02-28 11:42:31.567', level: 'WARN', source: 'METER-CDC', msg: '커넥션 지연: 응답시간 4.2s (임계 3s 초과)', detail: 'AMI 게이트웨이 DMA-042 지연 감지. 최근 5분 평균 3.8s' },
  { ts: '2026-02-28 11:42:31.234', level: 'INFO', source: 'RWIS-CDC', msg: '수위데이터 수신: STN_042, 12.34m', detail: '소양강댐 수위관측소 정상 수신, 전일 대비 +0.12m' },
  { ts: '2026-02-28 11:42:31.012', level: 'INFO', source: 'SAP-ETL', msg: 'MindsDB 메타추출 완료 → 컬럼 12개 매핑', detail: '자동 스키마 감지 완료, DQ rule 3건 자동 생성' },
  { ts: '2026-02-28 11:42:30.456', level: 'INFO', source: 'SAP-ETL', msg: '48,231 레코드 감지, 변경분 2,341건 추출', detail: 'CDC watermark: 2026-02-28 11:30:00 → 11:42:00' },
  { ts: '2026-02-28 11:42:30.123', level: 'INFO', source: 'SAP-ETL', msg: '배치시작: BKPF 테이블 스캔중...', detail: 'SAP → Kafka → Staging → DW 파이프라인 시작' },
  { ts: '2026-02-28 11:41:58.900', level: 'WARN', source: 'LEAK-IoT', msg: '센서 DMA-017 신호 약화: RSSI -85dBm', detail: '신호 강도 임계치(-80dBm) 미만. 센서 배터리 또는 통신환경 점검 필요' },
  { ts: '2026-02-28 11:41:45.321', level: 'INFO', source: 'ENV-API', msg: '환경부 수질측정 2,400건 수집 완료', detail: 'pH/DO/BOD/COD/SS 30분 주기 정상 수집. 품질점수 94.2' },
  { ts: '2026-02-28 11:41:30.654', level: 'INFO', source: 'SCADA', msg: '정수장A PLC 신호 정상: 취수펌프 #1~#3 가동', detail: 'SCADA 제어루프 정상, 취수량 42,000㎥/day' },
  { ts: '2026-02-28 11:41:15.100', level: 'ERROR', source: 'METER-CDC', msg: 'DMA-089 미터기 10대 데이터 누락', detail: '15분 주기 수신 실패. 게이트웨이 통신 장애 의심. 현장 점검 요청 발송' },
  { ts: '2026-02-28 11:40:58.777', level: 'INFO', source: 'DBT-RUN', msg: 'dbt run 완료: 12/12 모델 성공', detail: 'stg→int→fct 전체 레이어 변환 정상. 소요 23.4s' },
  { ts: '2026-02-28 11:40:42.333', level: 'INFO', source: 'RWIS-CDC', msg: '충주댐 수위 142.7m, 저수율 78.3%', detail: '전일 대비 +0.5m. 홍수기 제한수위(145m) 대비 여유 2.3m' },
  { ts: '2026-02-28 11:40:30.200', level: 'WARN', source: 'ENV-API', msg: '낙동강 11-1 지점 탁도 이상: 42.8 NTU', detail: '평소 수준(5~15 NTU) 대비 3배 상승. 상류 공사 영향 추정' },
  { ts: '2026-02-28 11:40:15.111', level: 'INFO', source: 'SAP-ETL', msg: 'SAP FI/CO 인터페이스 정상 연결', detail: 'RFC 커넥션 pool: 8/10 사용중, 응답시간 0.8s' },
  { ts: '2026-02-28 11:39:58.999', level: 'INFO', source: 'SCADA', msg: '소양강댐 방류 게이트 #2 개도율 15%', detail: '자동제어모드. 방류량 120㎥/s, 하류수위 정상 범위' },
  { ts: '2026-02-28 11:39:45.555', level: 'ERROR', source: 'KMA-API', msg: '기상청 API 호출실패: HTTP 503 (재시도 2/3)', detail: 'Service Unavailable - 자동 재시도 대기 30초' },
  { ts: '2026-02-28 11:39:30.222', level: 'INFO', source: 'LEAK-IoT', msg: 'DMA-023 압력 이상 없음: 3.2~3.5 bar', detail: '야간 최소유량 분석 정상, 누수 의심 구간 없음' },
  { ts: '2026-02-28 11:39:15.888', level: 'INFO', source: 'DBT-RUN', msg: 'dbt test 완료: 48/48 통과', detail: 'not_null: 20, unique: 15, accepted_values: 8, relationships: 5' },
  { ts: '2026-02-28 11:38:58.444', level: 'WARN', source: 'SCADA', msg: '정수장B 잔류염소 0.18mg/L (하한 근접)', detail: '기준범위 0.1~4.0mg/L. 하한 경고(0.2mg/L) 미만. 약품 투입량 조정 권고' },
  { ts: '2026-02-28 11:38:42.000', level: 'INFO', source: 'RWIS-CDC', msg: '대청댐 유입량 85㎥/s, 방류량 60㎥/s', detail: '저수량 증가 추세. 현재 저수율 82.1%' },
  { ts: '2026-02-28 11:38:30.666', level: 'INFO', source: 'ENV-API', msg: '한강 수질 pH 7.2 / DO 9.8mg/L', detail: '팔당댐 하류 수질 양호. 모든 항목 기준 이내' },
  { ts: '2026-02-28 11:38:15.333', level: 'INFO', source: 'SAP-ETL', msg: 'SAP HR 인사정보 배치 19,423건 완료', detail: '익명화 처리 후 DW 적재. 소요시간 2.1s' },
  { ts: '2026-02-28 11:37:58.100', level: 'ERROR', source: 'KMA-API', msg: '기상청 API 호출실패: HTTP 503 (재시도 1/3)', detail: 'endpoint: /1360000/VilageFcstInfoService_2.0. 자동 재시도 대기 10초' },
  { ts: '2026-02-28 11:37:42.777', level: 'INFO', source: 'METER-CDC', msg: '스마트미터 DMA-042 15분 수신: 342건', detail: 'AMI 데이터 정상 수집. 결측 0건' },
  { ts: '2026-02-28 11:37:30.444', level: 'INFO', source: 'SCADA', msg: '취수펌프 #4 예비 대기모드 전환', detail: '부하 분산을 위한 자동 로테이션. 가동시간 누적 4,320h' },
  { ts: '2026-02-28 11:37:15.111', level: 'WARN', source: 'DBT-RUN', msg: 'dbt 모델 stg_meter_usage 경고: 소스 freshness 지연', detail: '마지막 업데이트: 18분 전 (임계: 15분). CDC 지연 확인 필요' }
];

var ALERT_ITEMS = [
  { id: 'ALT-001', ts: '2026-02-28 11:42:32', severity: 'critical', source: 'KMA-API', title: '기상청 API 3회 연속 실패', desc: 'HTTP 503 에러. 자동 일시정지 처리됨. 수동 재개 필요.', status: 'open', assignee: '박기상' },
  { id: 'ALT-002', ts: '2026-02-28 11:41:15', severity: 'critical', source: 'METER-CDC', title: 'DMA-089 미터기 10대 데이터 누락', desc: '15분 주기 수신 실패. 게이트웨이 통신 장애 의심.', status: 'open', assignee: '정스마트' },
  { id: 'ALT-003', ts: '2026-02-28 11:42:31', severity: 'warning', source: 'METER-CDC', title: '스마트미터 Latency 4.2s', desc: 'DMA-042 게이트웨이 응답 지연. 임계치 3s 초과.', status: 'open', assignee: '정스마트' },
  { id: 'ALT-004', ts: '2026-02-28 11:41:58', severity: 'warning', source: 'LEAK-IoT', title: '센서 DMA-017 신호 약화', desc: 'RSSI -85dBm. 배터리 또는 통신환경 점검 필요.', status: 'acknowledged', assignee: '김누수' },
  { id: 'ALT-005', ts: '2026-02-28 11:40:30', severity: 'warning', source: 'ENV-API', title: '낙동강 탁도 이상: 42.8 NTU', desc: '평소 3배 수준 상승. 상류 공사 영향 추정.', status: 'acknowledged', assignee: '홍수질' },
  { id: 'ALT-006', ts: '2026-02-28 11:38:58', severity: 'warning', source: 'SCADA', title: '정수장B 잔류염소 하한 근접', desc: '0.18mg/L. 하한 경고(0.2mg/L) 미만.', status: 'open', assignee: '김정수' },
  { id: 'ALT-007', ts: '2026-02-28 11:37:15', severity: 'info', source: 'DBT-RUN', title: 'dbt 소스 freshness 경고', desc: 'stg_meter_usage 마지막 업데이트 18분 전.', status: 'resolved', assignee: '김분석' },
  { id: 'ALT-008', ts: '2026-02-28 11:30:00', severity: 'info', source: 'ENV-API', title: '환경부 수질 수집 정상 완료', desc: '2,400건 수집 정상. 품질점수 94.2', status: 'resolved', assignee: '홍수질' },
  { id: 'ALT-009', ts: '2026-02-28 06:02:00', severity: 'info', source: 'SAP-ETL', title: 'SAP 재무 일배치 정상 완료', desc: '48,231건 수집·변환·적재 완료', status: 'resolved', assignee: '이재무' },
  { id: 'ALT-010', ts: '2026-02-28 05:30:00', severity: 'info', source: 'DBT-RUN', title: 'dbt 일일 변환 전체 완료', desc: '36개 모델 성공, 0건 실패, 0건 스킵', status: 'resolved', assignee: '김분석' }
];

// 로그 화면 상태
var logScreenState = {
  levelFilter: 'all',
  sourceFilter: 'all',
  keyword: '',
  autoScroll: true,
  alertFilter: 'all',
  alertStatusFilter: 'all',
  page: 1,
  pageSize: 15
};

function initLogScreen() {
  // 상태 초기화
  logScreenState = { levelFilter:'all', sourceFilter:'all', keyword:'', autoScroll:true, alertFilter:'all', alertStatusFilter:'all', page:1, pageSize:15 };

  // 로그 레벨 필터 버튼
  document.querySelectorAll('.log-level-btn').forEach(function(btn) {
    btn.onclick = function() {
      document.querySelectorAll('.log-level-btn').forEach(function(b) { b.classList.remove('active'); });
      btn.classList.add('active');
      logScreenState.levelFilter = btn.dataset.level;
      logScreenState.page = 1;
      renderLogEntries();
    };
  });

  // 소스 필터
  var srcSelect = document.getElementById('logSourceFilter');
  if (srcSelect) {
    srcSelect.value = 'all';
    srcSelect.onchange = function() { logScreenState.sourceFilter = this.value; logScreenState.page = 1; renderLogEntries(); };
  }

  // 검색
  var searchInput = document.getElementById('logSearchInput');
  if (searchInput) {
    searchInput.value = '';
    searchInput.oninput = function() { logScreenState.keyword = this.value; logScreenState.page = 1; renderLogEntries(); };
  }

  // 알림 필터
  var alertSevSelect = document.getElementById('alertSeverityFilter');
  if (alertSevSelect) {
    alertSevSelect.value = 'all';
    alertSevSelect.onchange = function() { logScreenState.alertFilter = this.value; renderAlertItems(); };
  }
  var alertStatSelect = document.getElementById('alertStatusFilter');
  if (alertStatSelect) {
    alertStatSelect.value = 'all';
    alertStatSelect.onchange = function() { logScreenState.alertStatusFilter = this.value; renderAlertItems(); };
  }

  // KPI 업데이트
  updateLogKPI();
  renderLogEntries();
  renderAlertItems();
  startLogSimulation();
}

function updateLogKPI() {
  var total = LOG_ENTRIES.length;
  var errors = LOG_ENTRIES.filter(function(e) { return e.level === 'ERROR'; }).length;
  var warns = LOG_ENTRIES.filter(function(e) { return e.level === 'WARN'; }).length;
  var openAlerts = ALERT_ITEMS.filter(function(a) { return a.status === 'open'; }).length;

  var el1 = document.getElementById('log-kpi-total');
  var el2 = document.getElementById('log-kpi-error');
  var el3 = document.getElementById('log-kpi-warn');
  var el4 = document.getElementById('log-kpi-alert');
  if (el1) el1.textContent = total.toLocaleString();
  if (el2) el2.textContent = errors;
  if (el3) el3.textContent = warns;
  if (el4) el4.textContent = openAlerts;
}

function filterLogEntries() {
  var lv = logScreenState.levelFilter;
  var src = logScreenState.sourceFilter;
  var kw = logScreenState.keyword.toLowerCase().trim();

  return LOG_ENTRIES.filter(function(e) {
    if (lv !== 'all' && e.level !== lv) return false;
    if (src !== 'all' && e.source !== src) return false;
    if (kw && e.msg.toLowerCase().indexOf(kw) === -1 && e.source.toLowerCase().indexOf(kw) === -1 && e.detail.toLowerCase().indexOf(kw) === -1) return false;
    return true;
  });
}

function renderLogEntries() {
  var container = document.getElementById('log-entries-container');
  if (!container) return;

  var filtered = filterLogEntries();
  var start = (logScreenState.page - 1) * logScreenState.pageSize;
  var paged = filtered.slice(start, start + logScreenState.pageSize);

  // 결과 카운트
  var countEl = document.getElementById('log-result-count');
  if (countEl) countEl.textContent = filtered.length;

  if (paged.length === 0) {
    container.innerHTML = '<div style="text-align:center; padding:40px; color:#888;">조건에 맞는 로그가 없습니다.</div>';
  } else {
    var html = '';
    paged.forEach(function(e) {
      var timeParts = e.ts.split(' ');
      var timeStr = timeParts[1] || e.ts;
      var lvClass = e.level === 'ERROR' ? 'log-lv-error' : e.level === 'WARN' ? 'log-lv-warn' : 'log-lv-info';
      var srcInfo = LOG_SOURCES.find(function(s) { return s.id === e.source; });
      var srcColor = srcInfo ? srcInfo.color : '#888';
      html += '<div class="log-entry ' + lvClass + '">'
        + '<span class="log-ts">' + timeStr + '</span>'
        + '<span class="log-level log-level-' + e.level.toLowerCase() + '">' + e.level + '</span>'
        + '<span class="log-src" style="color:' + srcColor + '">[' + e.source + ']</span>'
        + '<span class="log-msg">' + escHtml(e.msg) + '</span>'
        + '<div class="log-detail">' + escHtml(e.detail) + '</div>'
        + '</div>';
    });
    container.innerHTML = html;
  }

  // 페이지네이션
  renderLogPagination(filtered.length);

  // 자동 스크롤
  if (logScreenState.autoScroll && logScreenState.page === 1) {
    container.scrollTop = 0;
  }
}

function renderLogPagination(total) {
  var container = document.getElementById('log-pagination');
  if (!container) return;
  var totalPages = Math.ceil(total / logScreenState.pageSize);
  if (totalPages <= 1) { container.innerHTML = ''; return; }
  var cp = logScreenState.page;
  var html = '<button class="log-page-btn" onclick="logGoPage(' + (cp - 1) + ')" ' + (cp === 1 ? 'disabled' : '') + '>‹</button>';
  var startP = Math.max(1, cp - 2);
  var endP = Math.min(totalPages, startP + 4);
  if (endP - startP < 4) startP = Math.max(1, endP - 4);
  for (var i = startP; i <= endP; i++) {
    html += '<button class="log-page-btn' + (i === cp ? ' active' : '') + '" onclick="logGoPage(' + i + ')">' + i + '</button>';
  }
  html += '<button class="log-page-btn" onclick="logGoPage(' + (cp + 1) + ')" ' + (cp === totalPages ? 'disabled' : '') + '>›</button>';
  html += '<span style="font-size:11px; color:var(--text-secondary); margin-left:8px;">' + cp + '/' + totalPages + ' (' + total + '건)</span>';
  container.innerHTML = html;
}

function logGoPage(p) {
  var total = filterLogEntries().length;
  var totalPages = Math.ceil(total / logScreenState.pageSize);
  if (p < 1 || p > totalPages) return;
  logScreenState.page = p;
  renderLogEntries();
}

function filterAlertItems() {
  var sev = logScreenState.alertFilter;
  var stat = logScreenState.alertStatusFilter;
  return ALERT_ITEMS.filter(function(a) {
    if (sev !== 'all' && a.severity !== sev) return false;
    if (stat !== 'all' && a.status !== stat) return false;
    return true;
  });
}

function renderAlertItems() {
  var container = document.getElementById('alert-items-container');
  if (!container) return;
  var filtered = filterAlertItems();
  var alertCountEl = document.getElementById('alert-result-count');
  if (alertCountEl) alertCountEl.textContent = filtered.length;

  if (filtered.length === 0) {
    container.innerHTML = '<div style="text-align:center; padding:30px; color:#888;">조건에 맞는 알림이 없습니다.</div>';
    return;
  }
  var html = '';
  filtered.forEach(function(a) {
    var sevClass = a.severity === 'critical' ? 'alert-sev-critical' : a.severity === 'warning' ? 'alert-sev-warning' : 'alert-sev-info';
    var sevLabel = a.severity === 'critical' ? '긴급' : a.severity === 'warning' ? '주의' : '정보';
    var statClass = a.status === 'open' ? 'alert-stat-open' : a.status === 'acknowledged' ? 'alert-stat-ack' : 'alert-stat-resolved';
    var statLabel = a.status === 'open' ? '미처리' : a.status === 'acknowledged' ? '확인됨' : '해결됨';
    var timeParts = a.ts.split(' ');
    var timeStr = timeParts[1] ? timeParts[1].substring(0, 5) : a.ts;
    var srcInfo = LOG_SOURCES.find(function(s) { return s.id === a.source; });
    var srcIcon = srcInfo ? srcInfo.icon : '📌';

    html += '<div class="alert-item ' + sevClass + '">'
      + '<div class="alert-item-header">'
      + '<div class="alert-item-left">'
      + '<span class="alert-sev-badge ' + sevClass + '">' + sevLabel + '</span>'
      + '<span class="alert-item-title">' + srcIcon + ' ' + escHtml(a.title) + '</span>'
      + '</div>'
      + '<div class="alert-item-right">'
      + '<span class="alert-stat-badge ' + statClass + '">' + statLabel + '</span>'
      + '<span class="alert-item-time">' + timeStr + '</span>'
      + '</div>'
      + '</div>'
      + '<div class="alert-item-body">'
      + '<span class="alert-item-desc">' + escHtml(a.desc) + '</span>'
      + '</div>'
      + '<div class="alert-item-footer">'
      + '<span class="alert-item-meta">📍 ' + a.source + '</span>'
      + '<span class="alert-item-meta">👤 ' + a.assignee + '</span>'
      + '<span class="alert-item-meta">🔖 ' + a.id + '</span>'
      + (a.status === 'open' ? '<button class="alert-ack-btn" onclick="ackAlert(\'' + a.id + '\')">확인처리</button>' : '')
      + '</div>'
      + '</div>';
  });
  container.innerHTML = html;
}

function ackAlert(id) {
  var item = ALERT_ITEMS.find(function(a) { return a.id === id; });
  if (item) {
    item.status = 'acknowledged';
    updateLogKPI();
    renderAlertItems();
  }
}

// 실시간 시뮬레이션 (5초마다 새 로그 추가)
var logSimInterval = null;
var logSimMessages = [
  { level:'INFO', source:'RWIS-CDC', msg:'수위데이터 수신 정상: {station}', detail:'관측소 정상 수신' },
  { level:'INFO', source:'SAP-ETL', msg:'배치 진행중: {count}건 처리', detail:'ETL 파이프라인 진행' },
  { level:'INFO', source:'SCADA', msg:'정수장 PLC 상태 정상', detail:'SCADA 모니터링 정상' },
  { level:'INFO', source:'ENV-API', msg:'수질데이터 {count}건 수집', detail:'환경부 API 정상 응답' },
  { level:'INFO', source:'LEAK-IoT', msg:'DMA-{dma} 압력 정상: {pressure} bar', detail:'누수탐지 센서 정상' },
  { level:'WARN', source:'METER-CDC', msg:'DMA-{dma} 지연 감지: {latency}s', detail:'게이트웨이 응답 지연' },
  { level:'INFO', source:'DBT-RUN', msg:'dbt 모델 {model} 변환 완료', detail:'dbt 변환 정상' },
  { level:'INFO', source:'RWIS-CDC', msg:'대청댐 유입량 {flow}㎥/s', detail:'유량 관측 정상' }
];
var logSimStations = ['STN_042','STN_015','STN_078','STN_101','STN_055'];
var logSimModels = ['stg_water_level','fct_daily_report','int_meter_agg','stg_weather','fct_billing'];

function startLogSimulation() {
  if (logSimInterval) clearInterval(logSimInterval);
  logSimInterval = setInterval(function() {
    if (!document.getElementById('screen-col-log') || !document.getElementById('screen-col-log').classList.contains('active')) {
      clearInterval(logSimInterval);
      logSimInterval = null;
      return;
    }
    var template = logSimMessages[Math.floor(Math.random() * logSimMessages.length)];
    var now = new Date();
    var ts = now.getFullYear() + '-' + String(now.getMonth()+1).padStart(2,'0') + '-' + String(now.getDate()).padStart(2,'0')
      + ' ' + String(now.getHours()).padStart(2,'0') + ':' + String(now.getMinutes()).padStart(2,'0') + ':' + String(now.getSeconds()).padStart(2,'0')
      + '.' + String(now.getMilliseconds()).padStart(3,'0');
    var msg = template.msg
      .replace('{station}', logSimStations[Math.floor(Math.random()*logSimStations.length)])
      .replace('{count}', String(Math.floor(Math.random()*5000)+100))
      .replace('{dma}', String(Math.floor(Math.random()*100)+1).padStart(3,'0'))
      .replace('{pressure}', (Math.random()*2+2).toFixed(1))
      .replace('{latency}', (Math.random()*3+1.5).toFixed(1))
      .replace('{model}', logSimModels[Math.floor(Math.random()*logSimModels.length)])
      .replace('{flow}', String(Math.floor(Math.random()*200)+30));
    var newEntry = { ts:ts, level:template.level, source:template.source, msg:msg, detail:template.detail };
    LOG_ENTRIES.unshift(newEntry);
    if (LOG_ENTRIES.length > 200) LOG_ENTRIES.pop();
    updateLogKPI();
    if (logScreenState.page === 1) renderLogEntries();
  }, 5000);
}

// ===== 사이트맵 =====
// 사이트맵 링크에서 screen ID 추출
function getSitemapScreenId(link) {
  var oc = link.getAttribute('onclick') || '';
  var m = oc.match(/navigate\('([^']+)'\)/);
  return m ? m[1] : null;
}

// 사이트맵 RBAC 적용 — 권한 없는 메뉴 숨김
function applySitemapRBAC() {
  var roleKey = window.currentRoleKey;
  if (!roleKey) return;
  var perm = RBAC_MATRIX[roleKey];
  if (!perm) return;
  var allScreens = perm.screens === 'ALL';
  var allowed = allScreens ? [] : perm.screens;

  var sections = document.querySelectorAll('#sitemap-grid .sitemap-section');
  var totalVisible = 0;

  sections.forEach(function(section) {
    var sectionLinks = section.querySelectorAll('.sitemap-link');
    var sectionVisible = 0;

    sectionLinks.forEach(function(link) {
      var screenId = getSitemapScreenId(link);
      var canAccess = allScreens || (screenId && allowed.indexOf(screenId) !== -1);
      link.dataset.rbacHidden = canAccess ? '' : '1';
      link.style.display = canAccess ? '' : 'none';
      if (canAccess) sectionVisible++;
    });

    // 서브아이템 컨테이너: 내부 링크가 모두 숨겨지면 컨테이너도 숨김
    section.querySelectorAll('div[style*="padding-left"]').forEach(function(container) {
      var subLinks = container.querySelectorAll('.sitemap-link');
      var anyVisible = false;
      subLinks.forEach(function(sl) { if (sl.dataset.rbacHidden !== '1') anyVisible = true; });
      container.style.display = anyVisible ? '' : 'none';
    });

    section.style.display = sectionVisible > 0 ? '' : 'none';
    totalVisible += sectionVisible;
  });

  var totalEl = document.getElementById('sitemap-total');
  if (totalEl) totalEl.textContent = totalVisible;
}

function filterSitemap() {
  var query = (document.getElementById('sitemap-search').value || '').toLowerCase().trim();
  var sections = document.querySelectorAll('#sitemap-grid .sitemap-section');
  var noResults = document.getElementById('sitemap-no-results');
  var totalShown = 0;

  if (!query) {
    // RBAC 상태 복원 — 권한 없는 항목은 숨긴 채 유지
    sections.forEach(function(s) {
      var sLinks = s.querySelectorAll('.sitemap-link');
      var secVis = 0;
      sLinks.forEach(function(l) {
        if (l.dataset.rbacHidden === '1') { l.style.display = 'none'; }
        else { l.style.display = ''; secVis++; totalShown++; }
      });
      // 서브아이템 컨테이너 복원
      s.querySelectorAll('div[style*="padding-left"]').forEach(function(c) {
        var anyVis = false;
        c.querySelectorAll('.sitemap-link').forEach(function(sl) { if (sl.dataset.rbacHidden !== '1') anyVis = true; });
        c.style.display = anyVis ? '' : 'none';
      });
      s.style.display = secVis > 0 ? '' : 'none';
    });
    if (noResults) noResults.style.display = 'none';
    var totalEl = document.getElementById('sitemap-total');
    if (totalEl) totalEl.textContent = totalShown;
    return;
  }

  sections.forEach(function(section) {
    var sectionLinks = section.querySelectorAll('.sitemap-link');
    var sectionVisible = 0;
    sectionLinks.forEach(function(link) {
      // RBAC로 숨겨진 항목은 검색에서도 제외
      if (link.dataset.rbacHidden === '1') { link.style.display = 'none'; return; }
      var text = link.textContent.toLowerCase();
      if (text.indexOf(query) !== -1) {
        link.style.display = '';
        sectionVisible++;
        totalShown++;
      } else {
        link.style.display = 'none';
      }
    });
    // 섹션 헤더 매칭
    var header = section.querySelector('[style*="font-size:15px"]');
    var headerText = header ? header.textContent.toLowerCase() : '';
    if (headerText.indexOf(query) !== -1) {
      sectionLinks.forEach(function(l) {
        if (l.dataset.rbacHidden !== '1') { l.style.display = ''; totalShown++; sectionVisible++; }
      });
    }
    // 서브아이템 컨테이너
    section.querySelectorAll('div[style*="padding-left"]').forEach(function(c) {
      var anyVis = false;
      c.querySelectorAll('.sitemap-link').forEach(function(sl) { if (sl.style.display !== 'none') anyVis = true; });
      c.style.display = anyVis ? '' : 'none';
    });
    section.style.display = sectionVisible > 0 ? '' : 'none';
  });

  if (noResults) noResults.style.display = totalShown === 0 ? 'block' : 'none';
  var totalEl = document.getElementById('sitemap-total');
  if (totalEl) totalEl.textContent = totalShown;
}

// ===== 화면별 CRUD 권한 설정 관리 (sys-perm) =====

// 화면 그룹 매핑
var SCREEN_GROUP_MAP = {
  'home': '대시보드', 'process': '대시보드', 'quality': '대시보드', 'measurement': '대시보드',
  'asset-db': '대시보드', 'ai': '대시보드', 'gallery': '대시보드', 'widget-settings': '대시보드', 'sitemap': '대시보드',
  'cat-search': '데이터 카탈로그', 'cat-detail': '데이터 카탈로그', 'cat-graph': '데이터 카탈로그',
  'cat-lineage': '데이터 카탈로그', 'cat-bookmark': '데이터 카탈로그', 'cat-request': '데이터 카탈로그',
  'col-pipeline': '데이터 수집·통합', 'col-register': '데이터 수집·통합', 'col-cdc': '데이터 수집·통합', 'col-kafka': '데이터 수집·통합',
  'col-external': '데이터 수집·통합', 'col-oneway': '데이터 수집·통합', 'col-arch': '데이터 수집·통합', 'col-monitor': '데이터 수집·통합',
  'col-log': '데이터 수집·통합', 'col-dbt': '데이터 수집·통합',
  'dist-product': '데이터 유통·활용', 'dist-deidentify': '데이터 유통·활용', 'dist-approval': '데이터 유통·활용',
  'dist-api': '데이터 유통·활용', 'dist-external': '데이터 유통·활용', 'dist-stats': '데이터 유통·활용',
  'dist-chart-content': '대시보드',
  'meta-glossary': '메타데이터', 'meta-tag': '메타데이터', 'meta-model': '메타데이터',
  'meta-dq': '메타데이터', 'meta-ontology': '메타데이터',
  'sys-user': '시스템관리', 'sys-role': '시스템관리', 'sys-security': '시스템관리',
  'sys-interface': '시스템관리', 'sys-audit': '시스템관리', 'sys-perm': '시스템관리', 'sys-engine': '시스템관리', 'sys-erp-sync': '시스템관리', 'sys-recovery-log': '시스템관리', 'llmops': '시스템관리',
  'sys-widget-template': '대시보드',
  'comm-notice': '커뮤니티', 'comm-internal': '커뮤니티', 'comm-external': '커뮤니티', 'comm-archive': '커뮤니티'
};

// 화면 라벨 매핑
var SCREEN_LABEL_MAP = {
  'home': '홈 대시보드', 'process': '데이터 프로세스', 'quality': '품질 현황', 'measurement': '관측소 모니터링',
  'asset-db': 'DB 자산관리', 'ai': 'AI 인사이트', 'gallery': '차트 갤러리', 'widget-settings': '위젯 설정', 'sitemap': '사이트맵',
  'cat-search': '데이터 검색', 'cat-detail': '카탈로그 상세', 'cat-graph': '지식그래프',
  'cat-lineage': '데이터 리니지', 'cat-bookmark': '북마크', 'cat-request': '데이터 요청',
  'col-pipeline': '파이프라인 관리', 'col-register': '신규 등록', 'col-cdc': 'CDC 시스템',
  'col-kafka': 'Kafka 메시지', 'col-external': '외부연계',
  'col-arch': '수집 아키텍처', 'col-monitor': '수집 모니터링', 'col-log': '수집 로그', 'col-dbt': 'dbt 모델',
  'dist-product': '데이터 제품', 'dist-deidentify': '비식별화', 'dist-approval': '배포승인',
  'dist-api': 'API 카탈로그', 'dist-external': '외부유통', 'dist-stats': '이용통계', 'dist-chart-content': '차트 콘텐츠',
  'meta-glossary': '표준용어사전', 'meta-tag': '태그 관리', 'meta-model': '메타모델',
  'meta-dq': '데이터 품질', 'meta-ontology': '온톨로지',
  'sys-user': '조직 및 사용자관리', 'sys-role': '권한 및 역할관리', 'sys-security': '데이터등급·보안정책',
  'sys-interface': '연계인터페이스 모니터링', 'sys-audit': '접속통계·감사로그',
  'sys-widget-template': '위젯 템플릿 관리', 'sys-perm': '화면별 권한설정', 'sys-engine': '데이터허브 엔진관리', 'sys-erp-sync': 'ERP 인사정보 동기화', 'sys-ext-register': '외부사용자 관리', 'sys-recovery-log': '복구 로그 조회', 'llmops': 'LLMOps 관리',
  'comm-notice': '공지사항', 'comm-internal': '내부게시판', 'comm-external': '외부협력게시판', 'comm-archive': '자료실'
};

function getScreenGroup(sid) {
  return SCREEN_GROUP_MAP[sid] || '기타';
}

function getScreenLabel(sid) {
  return SCREEN_LABEL_MAP[sid] || sid;
}

function getAllScreenIds() {
  return Object.keys(SCREEN_LABEL_MAP);
}

// PERM_LEVEL 한글 라벨
var PERM_LEVEL_LABELS = { read: '조회', write: '조회+등록', manage: '조회+등록+수정+삭제', admin: '전체(관리자)' };

function initPermGrid() {
  var select = document.getElementById('perm-role-select');
  if (!select) return;

  // 역할 드롭다운 초기화 (한번만)
  if (select.options.length <= 1) {
    var roleKeys = Object.keys(RBAC_MATRIX);
    roleKeys.forEach(function(rk) {
      var opt = document.createElement('option');
      opt.value = rk;
      opt.textContent = rk;
      select.appendChild(opt);
    });
  }

  var roleKey = select.value;
  if (!roleKey) {
    // KPI 초기값 설정
    updatePermKPIs(null);
    return;
  }
  renderPermGrid(roleKey);
}

function renderPermGrid(roleKey) {
  var rbac = RBAC_MATRIX[roleKey];
  if (!rbac) return;

  var screens = rbac.screens === 'ALL' ? getAllScreenIds() : rbac.screens;
  // 상세/등록 화면 제외 (SCREEN_PARENT_MAP에 있는 것들)
  screens = screens.filter(function(sid) { return !SCREEN_PARENT_MAP[sid]; });

  var custom = getCustomScreenPerms();
  var rowData = screens.map(function(sid) {
    var currentPerm = getScreenPermForRole(roleKey, sid);
    var customPerm = (custom[roleKey] && custom[roleKey][sid]) || '';
    var lvl = PERM_LEVELS[currentPerm] || 1;
    return {
      group: getScreenGroup(sid),
      name: getScreenLabel(sid),
      screenId: sid,
      read: lvl >= 1,
      create: lvl >= 2,
      update: lvl >= 3,
      delete: lvl >= 3,
      currentPerm: currentPerm,
      customPerm: customPerm || currentPerm,
      isCustom: !!customPerm
    };
  });

  // 그룹별 정렬
  var groupOrder = ['대시보드', '데이터 카탈로그', '데이터 수집·통합', '데이터 유통·활용', '메타데이터', '시스템관리', '커뮤니티'];
  rowData.sort(function(a, b) {
    var ai = groupOrder.indexOf(a.group), bi = groupOrder.indexOf(b.group);
    if (ai === -1) ai = 99; if (bi === -1) bi = 99;
    return ai - bi;
  });

  var columnDefs = [
    { field: 'group', headerName: '메뉴그룹', width: 130,
      cellStyle: function(params) { return { fontWeight: '600', color: '#546e7a' }; }
    },
    { field: 'name', headerName: '화면명', width: 180 },
    { field: 'screenId', headerName: 'Screen ID', width: 150,
      cellStyle: { color: '#999', fontSize: '12px' }
    },
    { field: 'read', headerName: '조회(R)', width: 80, cellRenderer: permCheckRenderer },
    { field: 'create', headerName: '등록(C)', width: 80, cellRenderer: permCheckRenderer },
    { field: 'update', headerName: '수정(U)', width: 80, cellRenderer: permCheckRenderer },
    { field: 'delete', headerName: '삭제(D)', width: 80, cellRenderer: permCheckRenderer },
    { field: 'currentPerm', headerName: '현재권한', width: 120, cellRenderer: permBadgeRenderer },
    { field: 'customPerm', headerName: '권한설정', width: 150, cellRenderer: permSelectRenderer }
  ];

  initAGGrid('ag-grid-sys-perm', columnDefs, rowData, { domLayout: 'autoHeight' });
  updatePermKPIs(roleKey);
  updatePermHistory();
}

function permCheckRenderer(params) {
  if (params.value) {
    return '<span style="color:#4caf50; font-weight:bold;">✓</span>';
  }
  return '<span style="color:#ccc;">—</span>';
}

function permBadgeRenderer(params) {
  var perm = params.value;
  var colors = {
    read: { bg: '#f5f5f5', color: '#999', border: '#e0e0e0' },
    write: { bg: '#e3f2fd', color: '#1565c0', border: '#90caf9' },
    manage: { bg: '#fff3e0', color: '#e65100', border: '#ffcc80' },
    admin: { bg: '#fce4ec', color: '#c62828', border: '#ef9a9a' }
  };
  var c = colors[perm] || colors.read;
  var label = PERM_LEVEL_LABELS[perm] || perm;
  return '<span style="display:inline-block; padding:2px 10px; border-radius:12px; font-size:11px; font-weight:600; background:' + c.bg + '; color:' + c.color + '; border:1px solid ' + c.border + ';">' + label + '</span>';
}

function permSelectRenderer(params) {
  var current = params.value || 'manage';
  var isCustom = params.data && params.data.isCustom;
  var sid = params.data ? params.data.screenId : '';
  var options = ['read', 'write', 'manage', 'admin'];
  var html = '<select onchange="onPermSelectChange(this, \'' + sid + '\')" style="width:100%; padding:3px 6px; border:1px solid ' + (isCustom ? '#ff9800' : '#ddd') + '; border-radius:4px; font-size:12px; background:' + (isCustom ? '#fff8e1' : '#fff') + '; cursor:pointer;">';
  options.forEach(function(opt) {
    var sel = opt === current ? ' selected' : '';
    html += '<option value="' + opt + '"' + sel + '>' + (PERM_LEVEL_LABELS[opt] || opt) + '</option>';
  });
  html += '</select>';
  return html;
}

function onPermSelectChange(el, screenId) {
  var roleKey = document.getElementById('perm-role-select').value;
  if (!roleKey) return;

  var newPerm = el.value;
  var custom = getCustomScreenPerms();
  if (!custom[roleKey]) custom[roleKey] = {};

  // 기본값과 같으면 커스텀에서 제거
  var defaultPerm = (RBAC_SCREEN_PERMS[roleKey] && (RBAC_SCREEN_PERMS[roleKey][screenId] || RBAC_SCREEN_PERMS[roleKey]._default)) || 'manage';
  if (newPerm === defaultPerm) {
    delete custom[roleKey][screenId];
    if (Object.keys(custom[roleKey]).length === 0) delete custom[roleKey];
  } else {
    custom[roleKey][screenId] = newPerm;
  }

  saveCustomScreenPerms(custom);

  // 그리드 새로고침
  renderPermGrid(roleKey);

  // 변경 이력 기록
  addPermHistory(roleKey, screenId, defaultPerm, newPerm);
}

function updatePermKPIs(roleKey) {
  var totalRoles = Object.keys(RBAC_MATRIX).length;
  var totalScreens = 0;
  var customCount = 0;
  var custom = getCustomScreenPerms();

  if (roleKey && RBAC_MATRIX[roleKey]) {
    var rbac = RBAC_MATRIX[roleKey];
    var screens = rbac.screens === 'ALL' ? getAllScreenIds() : rbac.screens;
    totalScreens = screens.filter(function(s) { return !SCREEN_PARENT_MAP[s]; }).length;
  }

  // 전체 커스텀 설정 수
  Object.keys(custom).forEach(function(rk) {
    customCount += Object.keys(custom[rk] || {}).length;
  });

  var el1 = document.getElementById('perm-kpi-roles');
  var el2 = document.getElementById('perm-kpi-screens');
  var el3 = document.getElementById('perm-kpi-custom');
  var el4 = document.getElementById('perm-kpi-lastmod');

  if (el1) el1.textContent = totalRoles + '개';
  if (el2) el2.textContent = totalScreens > 0 ? totalScreens + '개' : '-';
  if (el3) el3.textContent = customCount > 0 ? customCount + '건' : '없음';

  // 마지막 수정일
  var lastMod = localStorage.getItem('PERM_LAST_MODIFIED') || '-';
  if (el4) el4.textContent = lastMod;
}

function addPermHistory(roleKey, screenId, oldPerm, newPerm) {
  try {
    var history = JSON.parse(localStorage.getItem('PERM_HISTORY') || '[]');
    var now = new Date();
    var dateStr = now.getFullYear() + '-' + String(now.getMonth()+1).padStart(2,'0') + '-' + String(now.getDate()).padStart(2,'0') + ' ' + String(now.getHours()).padStart(2,'0') + ':' + String(now.getMinutes()).padStart(2,'0');
    history.unshift({
      date: dateStr,
      role: roleKey,
      screen: screenId,
      screenName: getScreenLabel(screenId),
      from: oldPerm,
      to: newPerm
    });
    // 최근 20건만 보관
    if (history.length > 20) history = history.slice(0, 20);
    localStorage.setItem('PERM_HISTORY', JSON.stringify(history));
    localStorage.setItem('PERM_LAST_MODIFIED', dateStr);
  } catch(e) {}
  updatePermHistory();
}

function updatePermHistory() {
  var container = document.getElementById('perm-history-list');
  if (!container) return;

  try {
    var history = JSON.parse(localStorage.getItem('PERM_HISTORY') || '[]');
    if (history.length === 0) {
      container.innerHTML = '<div style="text-align:center; padding:20px; color:#bbb;">변경 이력이 없습니다</div>';
      return;
    }
    var html = '';
    var show = Math.min(history.length, 5);
    for (var i = 0; i < show; i++) {
      var h = history[i];
      html += '<div style="display:flex; align-items:center; gap:12px; padding:10px 0; border-bottom:1px solid #f0f0f0;">';
      html += '<div style="min-width:120px; font-size:12px; color:#999;">' + h.date + '</div>';
      html += '<div style="flex:1;">';
      html += '<span style="font-weight:600; font-size:13px;">' + (h.screenName || h.screen) + '</span>';
      html += '<span style="color:#999; font-size:12px; margin-left:6px;">(' + h.screen + ')</span>';
      html += '<br><span style="font-size:12px; color:#666;">' + h.role + '</span>';
      html += '</div>';
      html += '<div style="font-size:12px;">';
      html += '<span style="color:#999;">' + (PERM_LEVEL_LABELS[h.from] || h.from) + '</span>';
      html += ' <span style="color:#1967d2;">→</span> ';
      html += '<span style="font-weight:600; color:#e65100;">' + (PERM_LEVEL_LABELS[h.to] || h.to) + '</span>';
      html += '</div>';
      html += '</div>';
    }
    container.innerHTML = html;
  } catch(e) {
    container.innerHTML = '<div style="text-align:center; padding:20px; color:#bbb;">이력 로드 실패</div>';
  }
}

function savePermChanges() {
  var roleKey = document.getElementById('perm-role-select').value;
  if (!roleKey) { alert('역할을 선택해주세요.'); return; }

  // 변경 사항 확인
  var custom = getCustomScreenPerms();
  var rolePerms = custom[roleKey];
  if (!rolePerms || Object.keys(rolePerms).length === 0) {
    showToast('변경된 권한 설정이 없습니다.', 'error');
    return;
  }

  // 승인 요청 모달 열기
  var modal = document.getElementById('perm-approve-modal');
  if (!modal) {
    // 모달이 없으면 기존 방식으로 저장
    showToast(roleKey + ' 역할의 권한 설정이 저장되었습니다.', 'success');
    return;
  }

  // 변경 내역 테이블 구성
  var tbody = document.getElementById('pam-changes-tbody');
  if (tbody) {
    var html = '';
    var defaultPerms = (RBAC_SCREEN_PERMS && RBAC_SCREEN_PERMS[roleKey]) || {};
    var defaultPerm = defaultPerms._default || 'read';
    Object.keys(rolePerms).forEach(function(screenId) {
      var newPerm = rolePerms[screenId];
      var oldPerm = defaultPerms[screenId] || defaultPerm;
      var permLabels = { 'read':'조회', 'write':'조회+등록', 'manage':'관리', 'admin':'전체관리' };
      html += '<tr><td style="font-size:11px;"><code>' + screenId + '</code></td>' +
        '<td style="font-size:11px;">' + (permLabels[oldPerm] || oldPerm) + '</td>' +
        '<td style="font-size:11px; font-weight:600; color:#1967d2;">' + (permLabels[newPerm] || newPerm) + '</td></tr>';
    });
    tbody.innerHTML = html;
  }
  document.getElementById('pam-role-name').textContent = roleKey;
  document.getElementById('pam-change-count').textContent = Object.keys(rolePerms).length + '건';
  document.getElementById('pam-reason').value = '';
  modal.style.display = 'flex';
}

function resetPermChanges() {
  var roleKey = document.getElementById('perm-role-select').value;
  if (!roleKey) { alert('역할을 선택해주세요.'); return; }
  if (!confirm('⚠️ ' + roleKey + ' 역할의 커스텀 권한 설정을 모두 초기화하시겠습니까?\n기본 권한(manage)으로 복원됩니다.')) return;

  var custom = getCustomScreenPerms();
  delete custom[roleKey];
  saveCustomScreenPerms(custom);

  addPermHistory(roleKey, '(전체 초기화)', '-', 'manage');
  renderPermGrid(roleKey);
  alert('✅ ' + roleKey + ' 역할의 권한이 기본값으로 초기화되었습니다.');
}

function resetAllPermChanges() {
  if (!confirm('⚠️ 모든 역할의 커스텀 권한 설정을 초기화하시겠습니까?\n이 작업은 되돌릴 수 없습니다.')) return;
  localStorage.removeItem('CUSTOM_SCREEN_PERMS');
  localStorage.removeItem('PERM_HISTORY');
  localStorage.removeItem('PERM_LAST_MODIFIED');

  var roleKey = document.getElementById('perm-role-select').value;
  if (roleKey) renderPermGrid(roleKey);
  else updatePermKPIs(null);
  alert('✅ 모든 커스텀 권한 설정이 초기화되었습니다.');
}

/* ═══════════════════════════════════════════════════════════════
   시각화 차트 콘텐츠 등록 – Step Workflow & Preview
   ═══════════════════════════════════════════════════════════════ */
var _chartRegState = {
  step: 1,
  schema: '',
  table: '',
  columns: [],      // selected column objects [{name, type}]
  allColumns: [],    // all available columns
  queryData: [],     // fetched row data
  chartType: 'line'
};

// ── Mock 테이블 / 컬럼 데이터 (분석 DB 시뮬레이션) ──
var _chartDbMeta = {
  DW_WATER: {
    tables: ['TB_WATER_QUALITY_DAILY', 'TB_WATER_LEVEL_HOURLY', 'TB_WATER_FLOW_MONTHLY', 'VW_WATER_QUALITY_STATS'],
    cols: {
      TB_WATER_QUALITY_DAILY: [
        {name:'MEASURE_DATE', type:'DATE'}, {name:'SITE_CODE', type:'VARCHAR'}, {name:'SITE_NAME', type:'VARCHAR'},
        {name:'PH', type:'NUMERIC'}, {name:'BOD', type:'NUMERIC'}, {name:'COD', type:'NUMERIC'},
        {name:'SS', type:'NUMERIC'}, {name:'DO_VAL', type:'NUMERIC'}, {name:'TN', type:'NUMERIC'}, {name:'TP', type:'NUMERIC'},
        {name:'TEMP', type:'NUMERIC'}, {name:'TURBIDITY', type:'NUMERIC'}
      ],
      TB_WATER_LEVEL_HOURLY: [
        {name:'MEASURE_DT', type:'TIMESTAMP'}, {name:'STATION_ID', type:'VARCHAR'}, {name:'STATION_NAME', type:'VARCHAR'},
        {name:'WATER_LEVEL', type:'NUMERIC'}, {name:'FLOW_RATE', type:'NUMERIC'}, {name:'RAINFALL', type:'NUMERIC'}
      ],
      TB_WATER_FLOW_MONTHLY: [
        {name:'YEAR_MONTH', type:'VARCHAR'}, {name:'STATION_ID', type:'VARCHAR'}, {name:'AVG_FLOW', type:'NUMERIC'},
        {name:'MAX_FLOW', type:'NUMERIC'}, {name:'MIN_FLOW', type:'NUMERIC'}, {name:'TOTAL_VOLUME', type:'NUMERIC'}
      ],
      VW_WATER_QUALITY_STATS: [
        {name:'YEAR', type:'VARCHAR'}, {name:'REGION', type:'VARCHAR'}, {name:'AVG_PH', type:'NUMERIC'},
        {name:'AVG_BOD', type:'NUMERIC'}, {name:'AVG_COD', type:'NUMERIC'}, {name:'SAMPLE_COUNT', type:'INTEGER'}
      ]
    }
  },
  DW_DAM: {
    tables: ['TB_DAM_WATER_LEVEL', 'TB_DAM_DISCHARGE', 'VW_DAM_STORAGE_RATE'],
    cols: {
      TB_DAM_WATER_LEVEL: [
        {name:'MEASURE_DATE', type:'DATE'}, {name:'DAM_CODE', type:'VARCHAR'}, {name:'DAM_NAME', type:'VARCHAR'},
        {name:'WATER_LEVEL', type:'NUMERIC'}, {name:'STORAGE_VOLUME', type:'NUMERIC'}, {name:'STORAGE_RATE', type:'NUMERIC'},
        {name:'INFLOW', type:'NUMERIC'}, {name:'OUTFLOW', type:'NUMERIC'}
      ],
      TB_DAM_DISCHARGE: [
        {name:'DISCHARGE_DT', type:'TIMESTAMP'}, {name:'DAM_CODE', type:'VARCHAR'}, {name:'GATE_NO', type:'INTEGER'},
        {name:'DISCHARGE_RATE', type:'NUMERIC'}, {name:'DURATION_MIN', type:'INTEGER'}
      ],
      VW_DAM_STORAGE_RATE: [
        {name:'MEASURE_DATE', type:'DATE'}, {name:'DAM_NAME', type:'VARCHAR'}, {name:'STORAGE_RATE', type:'NUMERIC'},
        {name:'PREV_YEAR_RATE', type:'NUMERIC'}, {name:'AVG_RATE', type:'NUMERIC'}
      ]
    }
  },
  DW_SUPPLY: {
    tables: ['TB_SUPPLY_DAILY', 'TB_SUPPLY_PRESSURE', 'VW_SUPPLY_REGION_SUMMARY'],
    cols: {
      TB_SUPPLY_DAILY: [
        {name:'SUPPLY_DATE', type:'DATE'}, {name:'PLANT_CODE', type:'VARCHAR'}, {name:'PLANT_NAME', type:'VARCHAR'},
        {name:'SUPPLY_VOLUME', type:'NUMERIC'}, {name:'DEMAND_VOLUME', type:'NUMERIC'}, {name:'LOSS_RATE', type:'NUMERIC'}
      ],
      TB_SUPPLY_PRESSURE: [
        {name:'MEASURE_DT', type:'TIMESTAMP'}, {name:'POINT_ID', type:'VARCHAR'}, {name:'PRESSURE', type:'NUMERIC'},
        {name:'FLOW_RATE', type:'NUMERIC'}
      ],
      VW_SUPPLY_REGION_SUMMARY: [
        {name:'YEAR_MONTH', type:'VARCHAR'}, {name:'REGION', type:'VARCHAR'}, {name:'TOTAL_SUPPLY', type:'NUMERIC'},
        {name:'AVG_PRESSURE', type:'NUMERIC'}, {name:'LOSS_RATE', type:'NUMERIC'}
      ]
    }
  },
  DW_ENERGY: {
    tables: ['TB_POWER_GENERATION', 'TB_ENERGY_CONSUMPTION', 'VW_ENERGY_MONTHLY'],
    cols: {
      TB_POWER_GENERATION: [
        {name:'GEN_DATE', type:'DATE'}, {name:'PLANT_CODE', type:'VARCHAR'}, {name:'PLANT_NAME', type:'VARCHAR'},
        {name:'GENERATION_MWH', type:'NUMERIC'}, {name:'CAPACITY_MW', type:'NUMERIC'}, {name:'UTILIZATION_RATE', type:'NUMERIC'}
      ],
      TB_ENERGY_CONSUMPTION: [
        {name:'CONSUME_DATE', type:'DATE'}, {name:'FACILITY_CODE', type:'VARCHAR'}, {name:'ELECTRIC_KWH', type:'NUMERIC'},
        {name:'GAS_M3', type:'NUMERIC'}, {name:'COST_KRW', type:'INTEGER'}
      ],
      VW_ENERGY_MONTHLY: [
        {name:'YEAR_MONTH', type:'VARCHAR'}, {name:'PLANT_NAME', type:'VARCHAR'}, {name:'TOTAL_GEN', type:'NUMERIC'},
        {name:'AVG_UTIL', type:'NUMERIC'}, {name:'PEAK_MW', type:'NUMERIC'}
      ]
    }
  },
  DW_ENV: {
    tables: ['TB_WEATHER_DAILY', 'TB_AIR_QUALITY', 'VW_ENV_COMPOSITE'],
    cols: {
      TB_WEATHER_DAILY: [
        {name:'OBS_DATE', type:'DATE'}, {name:'STATION_ID', type:'VARCHAR'}, {name:'TEMP_AVG', type:'NUMERIC'},
        {name:'TEMP_MAX', type:'NUMERIC'}, {name:'TEMP_MIN', type:'NUMERIC'}, {name:'RAINFALL_MM', type:'NUMERIC'},
        {name:'HUMIDITY', type:'NUMERIC'}, {name:'WIND_SPEED', type:'NUMERIC'}
      ],
      TB_AIR_QUALITY: [
        {name:'MEASURE_DT', type:'TIMESTAMP'}, {name:'STATION_NAME', type:'VARCHAR'}, {name:'PM10', type:'NUMERIC'},
        {name:'PM25', type:'NUMERIC'}, {name:'O3', type:'NUMERIC'}, {name:'NO2', type:'NUMERIC'}
      ],
      VW_ENV_COMPOSITE: [
        {name:'OBS_DATE', type:'DATE'}, {name:'REGION', type:'VARCHAR'}, {name:'TEMP', type:'NUMERIC'},
        {name:'RAINFALL', type:'NUMERIC'}, {name:'WATER_LEVEL', type:'NUMERIC'}, {name:'CORRELATION', type:'NUMERIC'}
      ]
    }
  },
  DM_ANALYTICS: {
    tables: ['DM_FLOOD_RISK_INDEX', 'DM_DROUGHT_FORECAST', 'DM_WATER_DEMAND_PRED'],
    cols: {
      DM_FLOOD_RISK_INDEX: [
        {name:'CALC_DATE', type:'DATE'}, {name:'REGION', type:'VARCHAR'}, {name:'RISK_INDEX', type:'NUMERIC'},
        {name:'RAIN_PROB', type:'NUMERIC'}, {name:'DAM_STORAGE', type:'NUMERIC'}, {name:'ALERT_LEVEL', type:'VARCHAR'}
      ],
      DM_DROUGHT_FORECAST: [
        {name:'FORECAST_DATE', type:'DATE'}, {name:'REGION', type:'VARCHAR'}, {name:'SPI_INDEX', type:'NUMERIC'},
        {name:'DROUGHT_LEVEL', type:'VARCHAR'}, {name:'CONFIDENCE', type:'NUMERIC'}
      ],
      DM_WATER_DEMAND_PRED: [
        {name:'PRED_DATE', type:'DATE'}, {name:'PLANT_CODE', type:'VARCHAR'}, {name:'PRED_DEMAND', type:'NUMERIC'},
        {name:'ACTUAL_DEMAND', type:'NUMERIC'}, {name:'ERROR_RATE', type:'NUMERIC'}
      ]
    }
  }
};

/* ── (레거시 스텝 함수 – 단일 페이지에서는 미사용, 호환성 유지) ── */
function chartRegGoStep() { /* no-op in single-page layout */ }

/* ── Load tables for selected schema ── */
function chartRegLoadTables() {
  var schema = document.getElementById('chartSrcSchema').value;
  var tableSel = document.getElementById('chartSrcTable');
  tableSel.innerHTML = '<option value="">테이블/뷰 선택</option>';
  _chartRegState.schema = schema;
  _chartRegState.table = '';
  _chartRegState.allColumns = [];
  _chartRegState.columns = [];
  document.getElementById('chartSrcColumnArea').style.display = 'none';
  document.getElementById('chartSrcPreviewCard').style.display = 'none';

  if (!schema || !_chartDbMeta[schema]) return;
  _chartDbMeta[schema].tables.forEach(function(t) {
    var opt = document.createElement('option');
    opt.value = t; opt.textContent = t;
    tableSel.appendChild(opt);
  });
}

function chartRegFilterTables() {
  var keyword = (document.getElementById('chartSrcSearch').value || '').toUpperCase();
  var tableSel = document.getElementById('chartSrcTable');
  var schema = document.getElementById('chartSrcSchema').value;
  if (!schema || !_chartDbMeta[schema]) return;
  tableSel.innerHTML = '<option value="">테이블/뷰 선택</option>';
  _chartDbMeta[schema].tables.forEach(function(t) {
    if (!keyword || t.toUpperCase().indexOf(keyword) >= 0) {
      var opt = document.createElement('option');
      opt.value = t; opt.textContent = t;
      tableSel.appendChild(opt);
    }
  });
}

/* ── Load columns for selected table ── */
function chartRegLoadColumns() {
  var schema = document.getElementById('chartSrcSchema').value;
  var table = document.getElementById('chartSrcTable').value;
  _chartRegState.table = table;
  _chartRegState.columns = [];

  var colArea = document.getElementById('chartSrcColumnArea');
  var colContainer = document.getElementById('chartSrcColumns');
  var selContainer = document.getElementById('chartSelectedColumns');
  var orderSel = document.getElementById('chartSrcOrderBy');

  if (!table || !_chartDbMeta[schema] || !_chartDbMeta[schema].cols[table]) {
    colArea.style.display = 'none';
    return;
  }

  var cols = _chartDbMeta[schema].cols[table];
  _chartRegState.allColumns = cols;
  colArea.style.display = '';

  // Render available columns
  colContainer.innerHTML = '';
  cols.forEach(function(c) {
    var tag = document.createElement('span');
    tag.className = 'col-tag';
    tag.setAttribute('data-col', c.name);
    tag.innerHTML = c.name + ' <span class="col-type">' + c.type + '</span>';
    tag.onclick = function() { chartRegToggleColumn(c); };
    colContainer.appendChild(tag);
  });

  // Reset selected
  selContainer.innerHTML = '<div style="color:var(--text-secondary); font-size:12px; text-align:center; padding:16px 0;">왼쪽에서 컬럼을 클릭하여 추가하세요</div>';
  document.getElementById('chartSelColCount').textContent = '(0개)';

  // Populate order by
  orderSel.innerHTML = '<option value="">정렬 없음</option>';
  cols.forEach(function(c) {
    var opt = document.createElement('option');
    opt.value = c.name; opt.textContent = c.name;
    orderSel.appendChild(opt);
  });
}

function chartRegToggleColumn(col) {
  var idx = -1;
  _chartRegState.columns.forEach(function(c, i) {
    if (c.name === col.name) idx = i;
  });

  if (idx >= 0) {
    _chartRegState.columns.splice(idx, 1);
  } else {
    _chartRegState.columns.push(col);
  }
  chartRegRenderSelectedColumns();

  // Update tag highlight
  var tags = document.querySelectorAll('#chartSrcColumns .col-tag');
  tags.forEach(function(tag) {
    var colName = tag.getAttribute('data-col');
    var isSelected = _chartRegState.columns.some(function(c) { return c.name === colName; });
    tag.classList.toggle('selected', isSelected);
  });
}

function chartRegRenderSelectedColumns() {
  var container = document.getElementById('chartSelectedColumns');
  var countEl = document.getElementById('chartSelColCount');
  var cols = _chartRegState.columns;
  countEl.textContent = '(' + cols.length + '개)';

  if (cols.length === 0) {
    container.innerHTML = '<div style="color:var(--text-secondary); font-size:12px; text-align:center; padding:16px 0;">왼쪽에서 컬럼을 클릭하여 추가하세요</div>';
    return;
  }

  container.innerHTML = '';
  cols.forEach(function(c) {
    var tag = document.createElement('span');
    tag.className = 'col-tag selected';
    tag.innerHTML = c.name + ' <span class="col-type">' + c.type + '</span> <span class="col-remove" onclick="event.stopPropagation(); chartRegToggleColumn({name:\'' + c.name + '\', type:\'' + c.type + '\'})">×</span>';
    container.appendChild(tag);
  });
}

/* ── Execute Query (mock) ── */
function chartRegExecuteQuery() {
  var schema = _chartRegState.schema;
  var table = _chartRegState.table;
  if (!schema || !table) { alert('스키마와 테이블을 선택해주세요.'); return; }

  var selCols = _chartRegState.columns;
  if (selCols.length === 0) {
    // Auto-select all columns
    _chartRegState.columns = _chartRegState.allColumns.slice();
    selCols = _chartRegState.columns;
    chartRegRenderSelectedColumns();
    var tags = document.querySelectorAll('#chartSrcColumns .col-tag');
    tags.forEach(function(tag) { tag.classList.add('selected'); });
  }

  var limit = parseInt(document.getElementById('chartSrcLimit').value) || 1000;
  if (limit > 50000) limit = 50000;

  // Generate mock data
  var rows = [];
  var numRows = Math.min(limit, 50 + Math.floor(Math.random() * 100));
  for (var i = 0; i < numRows; i++) {
    var row = {};
    selCols.forEach(function(c) {
      if (c.type === 'DATE') {
        var d = new Date(2025, 0, 1 + i);
        row[c.name] = d.toISOString().slice(0, 10);
      } else if (c.type === 'TIMESTAMP') {
        var d2 = new Date(2025, 0, 1, i % 24, 0, 0);
        d2.setDate(d2.getDate() + Math.floor(i / 24));
        row[c.name] = d2.toISOString().slice(0, 19).replace('T', ' ');
      } else if (c.type === 'NUMERIC') {
        row[c.name] = parseFloat((Math.random() * 100 + 10).toFixed(2));
      } else if (c.type === 'INTEGER') {
        row[c.name] = Math.floor(Math.random() * 1000);
      } else {
        // VARCHAR – generate meaningful codes/names
        var prefixes = ['S', 'D', 'P', 'R', 'A'];
        row[c.name] = prefixes[i % prefixes.length] + String(100 + (i % 20));
      }
    });
    rows.push(row);
  }

  _chartRegState.queryData = rows;

  // Show in AG Grid
  var colDefs = selCols.map(function(c) {
    var def = { headerName: c.name, field: c.name };
    if (c.type === 'NUMERIC') def.valueFormatter = function(p) { return p.value != null ? p.value.toLocaleString() : ''; };
    return def;
  });

  document.getElementById('chartSrcPreviewCard').style.display = '';
  document.getElementById('chartSrcRowCount').textContent = rows.length.toLocaleString() + '건 조회됨 (' + schema + '.' + table + ')';

  initAGGrid('ag-grid-chart-src-preview', colDefs, rows, {
    paginationPageSize: 10,
    pagination: rows.length > 10
  });

  // Auto-populate axis dropdowns and render preview
  chartRegPopulateAxisSelects();
  chartRegUpdatePreview();
}

/* ── Populate axis selects from selected columns ── */
function chartRegPopulateAxisSelects() {
  var xSel = document.getElementById('chartRegXAxis');
  var ySel = document.getElementById('chartRegYAxis');
  var gSel = document.getElementById('chartRegGroupBy');
  var cols = _chartRegState.columns;

  xSel.innerHTML = '<option value="">컬럼 선택</option>';
  ySel.innerHTML = '';
  gSel.innerHTML = '<option value="">없음</option>';

  cols.forEach(function(c) {
    var ox = document.createElement('option');
    ox.value = c.name; ox.textContent = c.name + ' (' + c.type + ')';
    xSel.appendChild(ox);

    if (c.type === 'NUMERIC' || c.type === 'INTEGER') {
      var oy = document.createElement('option');
      oy.value = c.name; oy.textContent = c.name;
      ySel.appendChild(oy);
    }

    if (c.type === 'VARCHAR') {
      var og = document.createElement('option');
      og.value = c.name; og.textContent = c.name;
      gSel.appendChild(og);
    }
  });

  // Auto-select first date/time for X, first numeric for Y
  cols.forEach(function(c) {
    if ((c.type === 'DATE' || c.type === 'TIMESTAMP' || c.type === 'VARCHAR') && !xSel.value) {
      xSel.value = c.name;
    }
  });
  if (ySel.options.length > 0) ySel.options[0].selected = true;
}

/* ── Chart Type Picker ── */
function chartRegSelectType(btn) {
  document.querySelectorAll('.chart-type-btn').forEach(function(b) { b.classList.remove('active'); });
  btn.classList.add('active');
  _chartRegState.chartType = btn.getAttribute('data-type');
  chartRegUpdatePreview();
}

/* ── Resize Preview ── */
function chartRegResizePreview() {
  var h = parseInt(document.getElementById('chartPreviewSize').value) || 400;
  document.getElementById('chartRegPreview').style.height = h + 'px';
  chartRegUpdatePreview();
}

/* ── Update Chart Preview (Canvas-based) ── */
function chartRegUpdatePreview() {
  var container = document.getElementById('chartRegPreview');
  if (!container) return;

  var xField = document.getElementById('chartRegXAxis') ? document.getElementById('chartRegXAxis').value : '';
  var ySelect = document.getElementById('chartRegYAxis');
  var yFields = [];
  if (ySelect) {
    for (var i = 0; i < ySelect.selectedOptions.length; i++) {
      yFields.push(ySelect.selectedOptions[i].value);
    }
  }

  if (!xField || yFields.length === 0 || _chartRegState.queryData.length === 0) {
    container.innerHTML = '<div style="text-align:center; color:var(--text-secondary);"><div style="font-size:48px; margin-bottom:8px;">📊</div><div>X축, Y축 컬럼을 선택하면 미리보기가 표시됩니다</div></div>';
    return;
  }

  var data = _chartRegState.queryData;
  var chartType = _chartRegState.chartType;
  var showLegend = document.getElementById('chartRegShowLegend') ? document.getElementById('chartRegShowLegend').checked : true;
  var showGrid = document.getElementById('chartRegShowGrid') ? document.getElementById('chartRegShowGrid').checked : true;
  var showDataLabel = document.getElementById('chartRegShowDataLabel') ? document.getElementById('chartRegShowDataLabel').checked : false;
  var smooth = document.getElementById('chartRegSmooth') ? document.getElementById('chartRegSmooth').checked : false;
  var stacked = document.getElementById('chartRegStacked') ? document.getElementById('chartRegStacked').checked : false;
  var mainColor = document.getElementById('chartRegColor') ? document.getElementById('chartRegColor').value : '#1677ff';

  var palette = _chartGetPalette(mainColor);

  // Canvas drawing
  var w = container.clientWidth || 600;
  var h = parseInt(container.style.height) || 400;
  container.innerHTML = '<canvas id="chartRegCanvas" width="' + w + '" height="' + h + '"></canvas>';
  var canvas = document.getElementById('chartRegCanvas');
  var ctx = canvas.getContext('2d');

  // Chart area
  var pad = { top: 40, right: 20, bottom: 50, left: 60 };
  if (showLegend) pad.top = 60;
  var cw = w - pad.left - pad.right;
  var ch = h - pad.top - pad.bottom;

  // Determine if dark mode
  var isDark = document.documentElement.getAttribute('data-theme') === 'dark';
  var bgColor = isDark ? '#1f1f1f' : '#ffffff';
  var textColor = isDark ? 'rgba(255,255,255,0.7)' : '#666';
  var gridColor = isDark ? 'rgba(255,255,255,0.08)' : 'rgba(0,0,0,0.06)';
  var labelColor = isDark ? 'rgba(255,255,255,0.85)' : '#333';

  // Background
  ctx.fillStyle = bgColor;
  ctx.fillRect(0, 0, w, h);

  // Limit data points for rendering
  var maxPts = 40;
  var step = Math.max(1, Math.floor(data.length / maxPts));
  var sampled = [];
  for (var si = 0; si < data.length; si += step) { sampled.push(data[si]); }
  if (sampled.length > maxPts) sampled = sampled.slice(0, maxPts);

  var labels = sampled.map(function(r) {
    var v = r[xField];
    return v != null ? String(v).slice(0, 10) : '';
  });

  if (chartType === 'pie' || chartType === 'donut') {
    _chartDrawPie(ctx, w, h, sampled, xField, yFields[0], palette, chartType === 'donut', showLegend, showDataLabel, textColor, labelColor, isDark);
    return;
  }

  if (chartType === 'gauge') {
    var gaugeVal = 0;
    if (sampled.length > 0 && yFields[0]) gaugeVal = sampled[sampled.length - 1][yFields[0]] || 0;
    _chartDrawGauge(ctx, w, h, gaugeVal, yFields[0], mainColor, textColor, labelColor, isDark);
    return;
  }

  // Get Y range
  var yMin = Infinity, yMax = -Infinity;
  sampled.forEach(function(r) {
    yFields.forEach(function(yf) {
      var v = parseFloat(r[yf]);
      if (!isNaN(v)) {
        if (stacked) { /* simplified */ }
        if (v < yMin) yMin = v;
        if (v > yMax) yMax = v;
      }
    });
  });

  var userMin = document.getElementById('chartRegYMin') ? parseFloat(document.getElementById('chartRegYMin').value) : NaN;
  var userMax = document.getElementById('chartRegYMax') ? parseFloat(document.getElementById('chartRegYMax').value) : NaN;
  if (!isNaN(userMin)) yMin = userMin;
  if (!isNaN(userMax)) yMax = userMax;

  if (yMin === yMax) { yMin -= 1; yMax += 1; }
  var yRange = yMax - yMin;
  yMin -= yRange * 0.05;
  yMax += yRange * 0.05;
  yRange = yMax - yMin;

  // Draw grid
  if (showGrid) {
    ctx.strokeStyle = gridColor;
    ctx.lineWidth = 1;
    for (var gi = 0; gi <= 5; gi++) {
      var gy = pad.top + ch - (ch * gi / 5);
      ctx.beginPath(); ctx.moveTo(pad.left, gy); ctx.lineTo(pad.left + cw, gy); ctx.stroke();
    }
  }

  // Y axis labels
  ctx.fillStyle = textColor;
  ctx.font = '11px sans-serif';
  ctx.textAlign = 'right';
  for (var yi = 0; yi <= 5; yi++) {
    var yv = yMin + yRange * yi / 5;
    var yy = pad.top + ch - (ch * yi / 5);
    ctx.fillText(yv.toFixed(1), pad.left - 8, yy + 3);
  }

  // X axis labels
  ctx.textAlign = 'center';
  var xStep2 = Math.max(1, Math.floor(labels.length / 8));
  labels.forEach(function(lb, idx) {
    if (idx % xStep2 !== 0 && idx !== labels.length - 1) return;
    var xx = pad.left + (idx / (labels.length - 1 || 1)) * cw;
    ctx.save();
    ctx.translate(xx, pad.top + ch + 14);
    ctx.rotate(-0.4);
    ctx.fillText(lb, 0, 0);
    ctx.restore();
  });

  // Draw series
  yFields.forEach(function(yf, sIdx) {
    var color = palette[sIdx % palette.length];
    var pts = sampled.map(function(r, idx) {
      var v = parseFloat(r[yf]);
      if (isNaN(v)) v = 0;
      return {
        x: pad.left + (idx / (sampled.length - 1 || 1)) * cw,
        y: pad.top + ch - ((v - yMin) / yRange) * ch
      };
    });

    if (chartType === 'bar') {
      var barW = Math.max(2, (cw / sampled.length / yFields.length) - 2);
      ctx.fillStyle = color;
      pts.forEach(function(p, idx) {
        var bx = p.x - barW * yFields.length / 2 + sIdx * barW;
        var by = p.y;
        var bh = pad.top + ch - by;
        ctx.fillRect(bx, by, barW, bh);
        if (showDataLabel) {
          ctx.fillStyle = labelColor;
          ctx.font = '10px sans-serif';
          ctx.textAlign = 'center';
          ctx.fillText(sampled[idx][yf], bx + barW / 2, by - 4);
          ctx.fillStyle = color;
        }
      });
    } else if (chartType === 'area') {
      // Fill area
      ctx.beginPath();
      ctx.moveTo(pts[0].x, pad.top + ch);
      pts.forEach(function(p) {
        if (smooth && pts.length > 2) ctx.lineTo(p.x, p.y);
        else ctx.lineTo(p.x, p.y);
      });
      ctx.lineTo(pts[pts.length - 1].x, pad.top + ch);
      ctx.closePath();
      ctx.fillStyle = color + '33';
      ctx.fill();
      // Line
      ctx.beginPath();
      pts.forEach(function(p, i) { i === 0 ? ctx.moveTo(p.x, p.y) : ctx.lineTo(p.x, p.y); });
      ctx.strokeStyle = color;
      ctx.lineWidth = 2;
      ctx.stroke();
    } else if (chartType === 'scatter') {
      pts.forEach(function(p, idx) {
        ctx.beginPath();
        ctx.arc(p.x, p.y, 4, 0, Math.PI * 2);
        ctx.fillStyle = color;
        ctx.fill();
      });
    } else if (chartType === 'heatmap') {
      var cellW = cw / sampled.length;
      var cellH = ch / yFields.length;
      var maxVal = 0;
      sampled.forEach(function(r) { var v = parseFloat(r[yf]) || 0; if (v > maxVal) maxVal = v; });
      pts.forEach(function(p, idx) {
        var v = parseFloat(sampled[idx][yf]) || 0;
        var intensity = maxVal > 0 ? v / maxVal : 0;
        ctx.fillStyle = _heatColor(intensity, color);
        ctx.fillRect(pad.left + idx * cellW, pad.top + sIdx * cellH, cellW - 1, cellH - 1);
      });
    } else {
      // Line chart (default)
      ctx.beginPath();
      pts.forEach(function(p, i) { i === 0 ? ctx.moveTo(p.x, p.y) : ctx.lineTo(p.x, p.y); });
      ctx.strokeStyle = color;
      ctx.lineWidth = 2.5;
      ctx.stroke();
      // Dots
      pts.forEach(function(p, idx) {
        ctx.beginPath();
        ctx.arc(p.x, p.y, 3, 0, Math.PI * 2);
        ctx.fillStyle = color;
        ctx.fill();
        if (showDataLabel && idx % Math.max(1, Math.floor(pts.length / 8)) === 0) {
          ctx.fillStyle = labelColor;
          ctx.font = '10px sans-serif';
          ctx.textAlign = 'center';
          ctx.fillText(sampled[idx][yf], p.x, p.y - 8);
        }
      });
    }
  });

  // Legend
  if (showLegend && yFields.length > 0) {
    ctx.font = '12px sans-serif';
    var lx = pad.left;
    yFields.forEach(function(yf, i) {
      var color = palette[i % palette.length];
      ctx.fillStyle = color;
      ctx.fillRect(lx, 12, 14, 14);
      ctx.fillStyle = labelColor;
      ctx.fillText(yf, lx + 18, 23);
      lx += ctx.measureText(yf).width + 36;
    });
  }

  // Title
  var chartName = document.getElementById('chartRegName') ? document.getElementById('chartRegName').value : '';
  if (chartName) {
    ctx.fillStyle = labelColor;
    ctx.font = 'bold 14px sans-serif';
    ctx.textAlign = 'center';
    ctx.fillText(chartName, w / 2, showLegend ? 46 : 22);
  }
}

function _chartGetPalette(mainColor) {
  var paletteSel = document.getElementById('chartRegPalette');
  var paletteName = paletteSel ? paletteSel.value : 'default';
  var palettes = {
    'default': [mainColor, '#52c41a', '#faad14', '#722ed1', '#13c2c2', '#eb2f96'],
    'warm':    ['#f5222d', '#fa541c', '#fa8c16', '#faad14', '#fadb14', '#a0d911'],
    'cool':    ['#13c2c2', '#1890ff', '#2f54eb', '#722ed1', '#36cfc9', '#597ef7'],
    'earth':   ['#8b6914', '#52c41a', '#389e0d', '#a0d911', '#d4b106', '#7cb305'],
    'vivid':   ['#f5222d', '#fa8c16', '#fadb14', '#52c41a', '#1890ff', '#722ed1']
  };
  return palettes[paletteName] || palettes['default'];
}

function _heatColor(intensity, baseColor) {
  var r = parseInt(baseColor.slice(1, 3), 16);
  var g = parseInt(baseColor.slice(3, 5), 16);
  var b = parseInt(baseColor.slice(5, 7), 16);
  var a = 0.1 + intensity * 0.8;
  return 'rgba(' + r + ',' + g + ',' + b + ',' + a.toFixed(2) + ')';
}

function _chartDrawPie(ctx, w, h, data, xField, yField, palette, isDonut, showLegend, showLabel, textColor, labelColor, isDark) {
  var cx = w / 2;
  var cy = h / 2 + (showLegend ? 10 : 0);
  var radius = Math.min(w, h) / 2 - 60;

  var total = 0;
  var slices = [];
  var maxSlices = Math.min(data.length, 10);
  for (var i = 0; i < maxSlices; i++) {
    var v = parseFloat(data[i][yField]) || 0;
    total += v;
    slices.push({ label: String(data[i][xField] || '').slice(0, 12), value: v });
  }

  var startAngle = -Math.PI / 2;
  slices.forEach(function(s, idx) {
    var angle = total > 0 ? (s.value / total) * Math.PI * 2 : 0;
    ctx.beginPath();
    ctx.moveTo(cx, cy);
    ctx.arc(cx, cy, radius, startAngle, startAngle + angle);
    ctx.fillStyle = palette[idx % palette.length];
    ctx.fill();

    if (showLabel && angle > 0.15) {
      var mid = startAngle + angle / 2;
      var lx = cx + Math.cos(mid) * radius * 0.65;
      var ly = cy + Math.sin(mid) * radius * 0.65;
      ctx.fillStyle = '#fff';
      ctx.font = 'bold 11px sans-serif';
      ctx.textAlign = 'center';
      ctx.fillText((s.value / total * 100).toFixed(1) + '%', lx, ly + 4);
    }

    startAngle += angle;
  });

  if (isDonut) {
    ctx.beginPath();
    ctx.arc(cx, cy, radius * 0.55, 0, Math.PI * 2);
    ctx.fillStyle = isDark ? '#1f1f1f' : '#fff';
    ctx.fill();
  }

  // Legend
  if (showLegend) {
    var ly2 = 14;
    var lx2 = 12;
    ctx.font = '11px sans-serif';
    slices.forEach(function(s, idx) {
      ctx.fillStyle = palette[idx % palette.length];
      ctx.fillRect(lx2, ly2, 12, 12);
      ctx.fillStyle = labelColor;
      ctx.fillText(s.label + ' (' + s.value.toFixed(1) + ')', lx2 + 16, ly2 + 10);
      lx2 += ctx.measureText(s.label + ' (' + s.value.toFixed(1) + ')').width + 32;
      if (lx2 > w - 80) { lx2 = 12; ly2 += 18; }
    });
  }
}

function _chartDrawGauge(ctx, w, h, value, label, color, textColor, labelColor, isDark) {
  var cx = w / 2;
  var cy = h / 2 + 30;
  var radius = Math.min(w, h) / 2 - 50;

  // Background arc
  ctx.beginPath();
  ctx.arc(cx, cy, radius, Math.PI, 0);
  ctx.lineWidth = 24;
  ctx.strokeStyle = isDark ? '#333' : '#eee';
  ctx.stroke();

  // Value arc
  var pct = Math.min(1, Math.max(0, value / 100));
  ctx.beginPath();
  ctx.arc(cx, cy, radius, Math.PI, Math.PI + Math.PI * pct);
  ctx.lineWidth = 24;
  ctx.strokeStyle = color;
  ctx.lineCap = 'round';
  ctx.stroke();

  // Value text
  ctx.fillStyle = labelColor;
  ctx.font = 'bold 32px sans-serif';
  ctx.textAlign = 'center';
  ctx.fillText(value.toFixed(1), cx, cy - 10);

  ctx.font = '14px sans-serif';
  ctx.fillStyle = textColor;
  ctx.fillText(label || 'Value', cx, cy + 16);
}

/* ── Summary Update ── */
function chartRegUpdateSummary() {
  var setTxt = function(id, val) { var el = document.getElementById(id); if (el) el.textContent = val || '-'; };
  setTxt('sumSource', _chartRegState.schema + '.' + _chartRegState.table);
  setTxt('sumName', document.getElementById('chartRegName') ? document.getElementById('chartRegName').value : '-');

  var activeType = document.querySelector('.chart-type-btn.active');
  setTxt('sumType', activeType ? activeType.textContent.trim() : '-');

  setTxt('sumXAxis', document.getElementById('chartRegXAxis') ? document.getElementById('chartRegXAxis').value : '-');

  var ySel = document.getElementById('chartRegYAxis');
  var yNames = [];
  if (ySel) { for (var i = 0; i < ySel.selectedOptions.length; i++) yNames.push(ySel.selectedOptions[i].value); }
  setTxt('sumYAxis', yNames.join(', ') || '-');

  var domSel = document.getElementById('chartRegDomain');
  setTxt('sumDomain', domSel && domSel.selectedOptions[0] ? domSel.selectedOptions[0].textContent : '-');

  var gradeSel = document.getElementById('chartRegGrade');
  setTxt('sumGrade', gradeSel && gradeSel.selectedOptions[0] ? gradeSel.selectedOptions[0].textContent : '-');

  setTxt('sumRowCount', _chartRegState.queryData.length.toLocaleString() + '건');
}

/* ── Submit ── */
function chartRegSubmit() {
  // Validate required fields
  if (_chartRegState.queryData.length === 0) { alert('데이터를 먼저 조회해주세요.'); return; }
  var name = document.getElementById('chartRegName');
  if (!name || !name.value.trim()) { alert('차트명을 입력해주세요.'); return; }
  var xSel = document.getElementById('chartRegXAxis');
  if (!xSel || !xSel.value) { alert('X축 컬럼을 선택해주세요.'); return; }
  var ySel = document.getElementById('chartRegYAxis');
  if (!ySel || ySel.selectedOptions.length === 0) { alert('Y축 컬럼을 선택해주세요.'); return; }
  alert('차트가 등록되었습니다.');
  navigate('dist-chart-content');
}

// ===== 외부 사용자 사용신청 폼 (로그인 화면) =====
function showExtRegisterForm() {
  document.querySelector('#loginOverlay > .card').style.display = 'none';
  document.getElementById('extRegisterForm').style.display = '';
}

function hideExtRegisterForm() {
  document.getElementById('extRegisterForm').style.display = 'none';
  document.querySelector('#loginOverlay > .card').style.display = '';
}

function submitExtRegister() {
  var name = document.getElementById('ext-name').value.trim();
  var org = document.getElementById('ext-org').value.trim();
  var dept = document.getElementById('ext-dept').value.trim();
  var email = document.getElementById('ext-email').value.trim();
  var phone = document.getElementById('ext-phone').value.trim();
  var purpose = document.getElementById('ext-purpose').value;
  var purposeDetail = document.getElementById('ext-purpose-detail').value.trim();
  var agreePrivacy = document.getElementById('ext-agree-privacy').checked;
  var agreeTerms = document.getElementById('ext-agree-terms').checked;

  if (!name || !org || !dept || !email || !phone) {
    showToast('필수 항목을 모두 입력해주세요.', 'error');
    return;
  }
  if (!purpose) { showToast('사용목적을 선택해주세요.', 'error'); return; }
  if (!purposeDetail) { showToast('상세 사용목적을 입력해주세요.', 'error'); return; }
  if (!agreePrivacy || !agreeTerms) {
    showToast('필수 약관에 동의해주세요.', 'error');
    return;
  }

  var receiptNo = 'EXT-' + new Date().getFullYear() + '-' + String(Math.floor(Math.random() * 9000) + 1000);
  showToast('신청이 접수되었습니다. 접수번호: ' + receiptNo, 'success');
  hideExtRegisterForm();
}

// ===== 신청현황 조회 (로그인 화면) =====
function showExtStatusCheck() {
  document.querySelector('#loginOverlay > .card').style.display = 'none';
  document.getElementById('extRegisterForm').style.display = 'none';
  document.getElementById('extStatusCheckForm').style.display = '';
  // 초기화
  document.getElementById('ext-check-name').value = '';
  document.getElementById('ext-check-id').value = '';
  document.getElementById('ext-check-phone').value = '';
  document.getElementById('ext-check-result').style.display = 'none';
}

function hideExtStatusCheck() {
  document.getElementById('extStatusCheckForm').style.display = 'none';
  document.querySelector('#loginOverlay > .card').style.display = '';
}

function checkExtRegisterStatus() {
  var name = document.getElementById('ext-check-name').value.trim();
  var idOrEmail = document.getElementById('ext-check-id').value.trim();
  var phone = document.getElementById('ext-check-phone').value.trim();

  if (!name || !idOrEmail) {
    showToast('성명과 접수번호(또는 이메일)를 모두 입력해주세요.', 'error');
    return;
  }

  // extRegisterData에서 검색
  var found = null;
  for (var i = 0; i < extRegisterData.length; i++) {
    var d = extRegisterData[i];
    if (d.name === name && (d.id === idOrEmail || d.email === idOrEmail)) {
      if (!phone || d.phone === phone) {
        found = d;
        break;
      }
    }
  }

  var resultDiv = document.getElementById('ext-check-result');
  if (!found) {
    resultDiv.style.display = '';
    resultDiv.innerHTML =
      '<div style="background:#fff2f0; border:1px solid #ffccc7; border-radius:8px; padding:16px; text-align:center;">' +
      '<div style="font-size:20px; margin-bottom:4px;">🔍</div>' +
      '<div style="font-size:13px; color:#cf1322; font-weight:600;">일치하는 신청 정보가 없습니다</div>' +
      '<div style="font-size:11px; color:var(--text-secondary); margin-top:4px;">성명과 접수번호(또는 이메일)를 다시 확인해주세요.</div>' +
      '</div>';
    return;
  }

  // 상태별 스타일
  var statusStyles = {
    '승인대기': { bg: '#fff8e1', c: '#d48806', dot: '#faad14', icon: '⏳', msg: '현재 심사가 진행 중입니다. 처리 완료 시 등록하신 이메일로 안내드립니다.' },
    '승인완료': { bg: '#e8f5e9', c: '#2e7d32', dot: '#52c41a', icon: '✅', msg: '승인이 완료되었습니다. 발급된 계정 정보는 등록하신 이메일로 발송되었습니다.' },
    '반려':     { bg: '#ffebee', c: '#c62828', dot: '#ff4d4f', icon: '❌', msg: '신청이 반려되었습니다. 반려 사유를 확인 후 재신청해주세요.' }
  };
  var st = statusStyles[found.status] || statusStyles['승인대기'];

  var html = '<div style="border:1px solid var(--border-color); border-radius:8px; overflow:hidden;">';
  // 상태 헤더
  html += '<div style="background:' + st.bg + '; padding:14px 16px; text-align:center;">';
  html += '<div style="font-size:24px; margin-bottom:4px;">' + st.icon + '</div>';
  html += '<div style="font-size:14px; font-weight:700; color:' + st.c + ';">' + found.status + '</div>';
  html += '<div style="font-size:11px; color:var(--text-secondary); margin-top:4px;">' + st.msg + '</div>';
  html += '</div>';
  // 상세 정보
  html += '<div style="padding:14px 16px; background:var(--card-bg);">';
  html += '<div style="display:grid; grid-template-columns:1fr 1fr; gap:8px; font-size:12px;">';
  html += '<div><span style="color:var(--text-secondary);">접수번호</span><br><strong>' + found.id + '</strong></div>';
  html += '<div><span style="color:var(--text-secondary);">신청일</span><br><strong>' + found.date + '</strong></div>';
  html += '<div><span style="color:var(--text-secondary);">소속기관</span><br>' + found.org + '</div>';
  html += '<div><span style="color:var(--text-secondary);">처리일</span><br>' + (found.processDate || '-') + '</div>';
  html += '</div>';

  // 반려 사유 표시
  if (found.status === '반려' && found.rejectReason) {
    html += '<div style="margin-top:10px; background:#fff2f0; border:1px solid #ffccc7; border-radius:6px; padding:10px;">';
    html += '<div style="font-size:11px; font-weight:600; color:#cf1322; margin-bottom:2px;">반려 사유</div>';
    html += '<div style="font-size:12px; color:#333;">' + found.rejectReason + '</div>';
    html += '</div>';
  }

  // 처리 단계 타임라인
  html += '<div style="margin-top:12px; padding-top:10px; border-top:1px solid var(--border-color);">';
  html += '<div style="font-size:11px; font-weight:600; color:var(--text-secondary); margin-bottom:8px;">처리 단계</div>';
  html += '<div style="display:flex; align-items:center; gap:0;">';
  // 1단계: 신청접수 (항상 완료)
  html += '<div style="text-align:center; flex:1;">';
  html += '<div style="width:28px; height:28px; border-radius:50%; background:#1677ff; color:#fff; display:inline-flex; align-items:center; justify-content:center; font-size:12px; font-weight:700;">1</div>';
  html += '<div style="font-size:10px; margin-top:2px; color:#1677ff; font-weight:600;">신청접수</div>';
  html += '</div>';
  // 연결선
  html += '<div style="flex:0 0 30px; height:2px; background:' + (found.status !== '승인대기' ? '#1677ff' : '#e0e0e0') + ';"></div>';
  // 2단계: 심사중
  var step2Active = true;
  var step2Color = found.status === '승인대기' ? '#faad14' : '#1677ff';
  html += '<div style="text-align:center; flex:1;">';
  html += '<div style="width:28px; height:28px; border-radius:50%; background:' + step2Color + '; color:#fff; display:inline-flex; align-items:center; justify-content:center; font-size:12px; font-weight:700;">2</div>';
  html += '<div style="font-size:10px; margin-top:2px; color:' + step2Color + '; font-weight:600;">심사중</div>';
  html += '</div>';
  // 연결선
  html += '<div style="flex:0 0 30px; height:2px; background:' + (found.status !== '승인대기' ? (found.status === '승인완료' ? '#52c41a' : '#f5222d') : '#e0e0e0') + ';"></div>';
  // 3단계: 처리완료
  var step3Color = found.status === '승인대기' ? '#e0e0e0' : (found.status === '승인완료' ? '#52c41a' : '#f5222d');
  var step3Text = found.status === '승인대기' ? '#999' : (found.status === '승인완료' ? '#52c41a' : '#f5222d');
  html += '<div style="text-align:center; flex:1;">';
  html += '<div style="width:28px; height:28px; border-radius:50%; background:' + step3Color + '; color:#fff; display:inline-flex; align-items:center; justify-content:center; font-size:12px; font-weight:700;">3</div>';
  html += '<div style="font-size:10px; margin-top:2px; color:' + step3Text + '; font-weight:600;">' + (found.status === '승인대기' ? '처리완료' : found.status) + '</div>';
  html += '</div>';
  html += '</div>'; // flex
  html += '</div>'; // 처리 단계

  html += '</div>'; // 상세 정보
  html += '</div>'; // 전체 카드

  resultDiv.style.display = '';
  resultDiv.innerHTML = html;
}

// ===== 비밀번호 찾기/초기화 (외부사용자) =====
function showPwResetForm() {
  document.querySelector('#loginOverlay > .card').style.display = 'none';
  document.getElementById('extRegisterForm').style.display = 'none';
  document.getElementById('extStatusCheckForm').style.display = 'none';
  document.getElementById('pwResetForm').style.display = '';
  // 초기화
  document.getElementById('pw-reset-name').value = '';
  document.getElementById('pw-reset-id').value = '';
  document.getElementById('pw-reset-phone').value = '';
  document.getElementById('pw-reset-result').style.display = 'none';
  document.getElementById('pw-reset-step1').style.display = '';
}

function hidePwResetForm() {
  document.getElementById('pwResetForm').style.display = 'none';
  document.querySelector('#loginOverlay > .card').style.display = '';
}

function generateTempPassword() {
  var chars = 'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghjkmnpqrstuvwxyz23456789';
  var pwd = 'Kw@';
  for (var i = 0; i < 8; i++) {
    pwd += chars.charAt(Math.floor(Math.random() * chars.length));
  }
  return pwd;
}

function verifyPwResetIdentity() {
  var name = document.getElementById('pw-reset-name').value.trim();
  var idOrEmail = document.getElementById('pw-reset-id').value.trim();
  var phone = document.getElementById('pw-reset-phone').value.trim();

  if (!name || !idOrEmail) {
    showToast('성명과 아이디(또는 이메일)를 모두 입력해주세요.', 'error');
    return;
  }

  // extRegisterData에서 검색
  var found = null;
  for (var i = 0; i < extRegisterData.length; i++) {
    var d = extRegisterData[i];
    if (d.name === name && (d.id === idOrEmail || d.email === idOrEmail)) {
      if (!phone || d.phone === phone) {
        found = d;
        break;
      }
    }
  }

  var resultDiv = document.getElementById('pw-reset-result');

  if (!found) {
    resultDiv.style.display = '';
    resultDiv.innerHTML =
      '<div style="background:#fff2f0; border:1px solid #ffccc7; border-radius:8px; padding:16px; text-align:center;">' +
      '<div style="font-size:20px; margin-bottom:4px;">🔍</div>' +
      '<div style="font-size:13px; color:#cf1322; font-weight:600;">일치하는 계정 정보가 없습니다</div>' +
      '<div style="font-size:11px; color:var(--text-secondary); margin-top:4px;">성명과 아이디(또는 이메일)를 다시 확인해주세요.</div>' +
      '</div>';
    return;
  }

  // 승인완료 상태가 아닌 경우
  if (found.status !== '승인완료') {
    resultDiv.style.display = '';
    resultDiv.innerHTML =
      '<div style="background:#fff8e1; border:1px solid #ffe58f; border-radius:8px; padding:16px; text-align:center;">' +
      '<div style="font-size:20px; margin-bottom:4px;">⚠️</div>' +
      '<div style="font-size:13px; color:#d48806; font-weight:600;">비밀번호 초기화를 할 수 없습니다</div>' +
      '<div style="font-size:11px; color:var(--text-secondary); margin-top:4px;">승인 완료된 계정만 비밀번호 초기화가 가능합니다.<br>현재 상태: <strong>' + found.status + '</strong></div>' +
      '</div>';
    return;
  }

  // 임시 비밀번호 발급
  var tempPwd = generateTempPassword();
  var maskedEmail = found.email.replace(/(.{2})(.*)(@.*)/, function(m, a, b, c) { return a + b.replace(/./g, '*') + c; });
  var now = new Date();
  var expireTime = new Date(now.getTime() + 24 * 60 * 60 * 1000);
  var expireStr = expireTime.toISOString().substring(0, 16).replace('T', ' ');

  document.getElementById('pw-reset-step1').style.display = 'none';

  var html = '<div style="border:1px solid var(--border-color); border-radius:8px; overflow:hidden;">';
  // 성공 헤더
  html += '<div style="background:#e8f5e9; padding:16px; text-align:center;">';
  html += '<div style="font-size:28px; margin-bottom:4px;">✅</div>';
  html += '<div style="font-size:15px; font-weight:700; color:#2e7d32;">임시 비밀번호가 발급되었습니다</div>';
  html += '<div style="font-size:11px; color:var(--text-secondary); margin-top:4px;">' + maskedEmail + ' 으로 발송되었습니다</div>';
  html += '</div>';
  // 임시 비밀번호 표시
  html += '<div style="padding:16px; background:var(--card-bg); text-align:center;">';
  html += '<div style="font-size:11px; color:var(--text-secondary); margin-bottom:6px;">임시 비밀번호 (프로토타입 화면 표시)</div>';
  html += '<div style="background:#f6f8fa; border:2px dashed var(--border-color); border-radius:8px; padding:14px; margin-bottom:12px;">';
  html += '<code style="font-size:18px; font-weight:700; letter-spacing:2px; color:#1677ff;">' + tempPwd + '</code>';
  html += '</div>';
  // 안내 사항
  html += '<div style="text-align:left; background:#fff8e1; border:1px solid #ffe58f; border-radius:6px; padding:10px; font-size:11px;">';
  html += '<div style="font-weight:600; color:#d48806; margin-bottom:4px;">⚠️ 안내 사항</div>';
  html += '<ul style="margin:0; padding-left:16px; color:#666; line-height:1.7;">';
  html += '<li>임시 비밀번호로 로그인 후 <strong>반드시 비밀번호를 변경</strong>해주세요.</li>';
  html += '<li>유효기간: <strong>' + expireStr + '</strong> 까지 (24시간)</li>';
  html += '<li>영문 대/소문자 + 숫자 + 특수문자 조합, 8자 이상으로 설정하세요.</li>';
  html += '</ul>';
  html += '</div>';
  html += '</div>';
  html += '</div>';

  resultDiv.style.display = '';
  resultDiv.innerHTML = html;
}

// ===== 외부사용자 관리 (관리자) =====
var extRegisterData = [
  { id: 'EXT-2026-0047', date: '2026-03-06', name: '박연구', org: '국립환경과학원', dept: '수질연구팀', position: '연구원', email: 'park@nier.go.kr', phone: '010-9876-5432', purpose: '공동 연구', purposeDetail: '한강 수계 수질 빅데이터 공동 분석 연구', dataAccess: '수질, 수문', period: '2026-04 ~ 2026-12', attachment: '재직증명서.pdf', status: '승인대기', processDate: '-' },
  { id: 'EXT-2026-0046', date: '2026-03-06', name: '이분석', org: '서울대학교', dept: '환경공학부', position: '교수', email: 'lee@snu.ac.kr', phone: '010-5555-1234', purpose: '데이터 조회', purposeDetail: '댐 수위 및 유량 데이터 분석을 통한 기후변화 영향 연구', dataAccess: '댐, 수문, 기상', period: '2026-03 ~ 2027-02', attachment: '연구계획서.pdf', status: '승인대기', processDate: '-' },
  { id: 'EXT-2026-0045', date: '2026-03-05', name: '김개발', org: '(주)워터테크', dept: '개발팀', position: '과장', email: 'kim@watertech.co.kr', phone: '010-1111-2222', purpose: 'API 연동', purposeDetail: '스마트 수도계량기 연동을 위한 실시간 데이터 API 활용', dataAccess: '수도', period: '2026-04 ~ 2026-09', attachment: '사업자등록증.pdf', status: '승인대기', processDate: '-' },
  { id: 'EXT-2026-0044', date: '2026-03-04', name: '정수질', org: '환경부', dept: '수질정책과', position: '사무관', email: 'jung@me.go.kr', phone: '010-3333-4444', purpose: '데이터 조회', purposeDetail: '전국 수질 모니터링 현황 파악 및 정책 수립 자료', dataAccess: '수질, 수문', period: '2026-03 ~ 2026-12', attachment: '재직증명서.pdf', status: '승인대기', processDate: '-' },
  { id: 'EXT-2026-0043', date: '2026-03-03', name: '최에너지', org: '한국에너지공단', dept: '신재생에너지팀', position: '대리', email: 'choi@energy.or.kr', phone: '010-7777-8888', purpose: '공동 연구', purposeDetail: '소수력 발전 효율 분석을 위한 수력 데이터 활용', dataAccess: '에너지, 댐', period: '2026-04 ~ 2026-10', attachment: '재직증명서.pdf', status: '승인대기', processDate: '-' },
  { id: 'EXT-2026-0040', date: '2026-02-28', name: '한수자원', org: '(주)그린워터', dept: 'R&D센터', position: '팀장', email: 'han@greenwater.kr', phone: '010-2222-3333', purpose: 'API 연동', purposeDetail: '정수장 운영 최적화 AI 모델 개발을 위한 수질/수량 데이터', dataAccess: '수질, 수도', period: '2026-03 ~ 2026-08', attachment: '사업자등록증.pdf', status: '승인완료', processDate: '2026-03-01' },
  { id: 'EXT-2026-0038', date: '2026-02-25', name: '오기상', org: '기상청', dept: '기후변화감시과', position: '연구관', email: 'oh@kma.go.kr', phone: '010-4444-5555', purpose: '데이터 조회', purposeDetail: '기후변화 영향 분석을 위한 수문·기상 데이터 교차 검증', dataAccess: '기상, 수문', period: '2026-03 ~ 2027-02', attachment: '재직증명서.pdf', status: '승인완료', processDate: '2026-02-27' },
  { id: 'EXT-2026-0035', date: '2026-02-20', name: '강환경', org: '환경정책평가연구원', dept: '물환경연구실', position: '부연구위원', email: 'kang@kei.re.kr', phone: '010-6666-7777', purpose: '공동 연구', purposeDetail: '하천 생태 건강성 평가를 위한 수질·수문 통합 분석', dataAccess: '수질, 수문, 댐', period: '2026-03 ~ 2026-11', attachment: '연구계획서.pdf', status: '승인완료', processDate: '2026-02-22' },
  { id: 'EXT-2026-0030', date: '2026-02-15', name: '임데이터', org: '(주)데이터솔루션', dept: '분석팀', position: '사원', email: 'lim@datasol.com', phone: '010-8888-9999', purpose: '기타', purposeDetail: '서류 미비 - 사업자등록증 미제출', dataAccess: '수문', period: '2026-03 ~ 2026-06', attachment: '-', status: '반려', processDate: '2026-02-17', rejectReason: '필수 첨부서류(사업자등록증) 미제출' },
  { id: 'EXT-2026-0028', date: '2026-02-10', name: '서외부', org: 'OO대학교', dept: '토목공학과', position: '대학원생', email: 'seo@univ.ac.kr', phone: '010-1234-0000', purpose: '데이터 조회', purposeDetail: '졸업논문용 수문 데이터 분석 (개인 연구 목적 불명확)', dataAccess: '수문', period: '2026-03 ~ 2026-08', attachment: '학생증사본.pdf', status: '반려', processDate: '2026-02-12', rejectReason: '사용목적 불명확 - 지도교수 확인서 필요' }
];

function initExtRegisterGrid() {
  initAGGrid('ag-grid-ext-register', [
    { field: 'id', headerName: '접수번호', width: 130, cellRenderer: function(p) { return '<span style="font-family:monospace; font-weight:600; color:var(--primary-color);">' + p.value + '</span>'; } },
    { field: 'date', headerName: '신청일', width: 100 },
    { field: 'name', headerName: '성명', width: 80, cellRenderer: function(p) { return '<strong>' + p.value + '</strong>'; } },
    { field: 'org', headerName: '소속기관', flex: 1 },
    { field: 'purpose', headerName: '사용목적', width: 100, cellRenderer: function(p) {
      var m = { '데이터 조회': { bg:'#e6f7ff', c:'#1677ff' }, 'API 연동': { bg:'#f9f0ff', c:'#722ed1' }, '공동 연구': { bg:'#f6ffed', c:'#52c41a' }, '기타': { bg:'#f5f5f5', c:'#666' } };
      var s = m[p.value] || { bg:'#f5f5f5', c:'#666' };
      return '<span style="background:'+s.bg+';color:'+s.c+';padding:2px 8px;border-radius:4px;font-size:11px;">'+p.value+'</span>';
    }},
    { field: 'status', headerName: '상태', width: 95, cellRenderer: function(p) {
      var m = { '승인대기': { bg:'#fff8e1', c:'#d48806', dot:'#faad14' }, '승인완료': { bg:'#e8f5e9', c:'#2e7d32', dot:'#52c41a' }, '반려': { bg:'#ffebee', c:'#c62828', dot:'#ff4d4f' } };
      var s = m[p.value] || { bg:'#f5f5f5', c:'#666', dot:'#999' };
      return '<span style="display:inline-flex;align-items:center;gap:4px;background:'+s.bg+';color:'+s.c+';padding:2px 8px;border-radius:4px;font-size:11px;"><span style="width:6px;height:6px;border-radius:50%;background:'+s.dot+';"></span>'+p.value+'</span>';
    }},
    { field: 'processDate', headerName: '처리일', width: 100 },
    { field: 'action', headerName: '관리', width: 180, sortable: false, filter: false, cellRenderer: function(p) {
      var html = '';
      if (p.data.status === '승인대기') {
        html += '<button class="btn btn-primary" style="padding:1px 6px;font-size:11px;margin-right:3px;background:#52c41a;border-color:#52c41a;" data-action="approve">승인</button>';
        html += '<button class="btn btn-outline" style="padding:1px 6px;font-size:11px;margin-right:3px;color:#f5222d;border-color:#f5222d;" data-action="reject">반려</button>';
      }
      html += '<button class="btn btn-outline" style="padding:1px 6px;font-size:11px;" data-action="detail">상세</button>';
      return html;
    }}
  ], extRegisterData, {
    domLayout: 'autoHeight',
    getRowStyle: function(params) {
      if (params.data.status === '승인대기') return { background: '#fffbe6' };
      return null;
    },
    onCellClicked: function(e) {
      if (e.colDef.field === 'action') {
        var action = e.event.target.getAttribute('data-action');
        if (action === 'approve') {
          if (confirm(e.data.name + '님(' + e.data.org + ')의 신청을 승인하시겠습니까?')) {
            approveExtRegisterDirect(e.data);
          }
        } else if (action === 'reject') {
          openExtRejectModal(e.data);
        } else if (action === 'detail') {
          openExtRegisterDetail(e.data);
        }
      }
    }
  });
}

function openExtRegisterDetail(data) {
  // 신청자 정보 채우기
  document.getElementById('ext-detail-id').textContent = data.id;
  document.getElementById('ext-detail-date').textContent = data.date;
  document.getElementById('ext-detail-name').textContent = data.name;
  document.getElementById('ext-detail-org').textContent = data.org;
  document.getElementById('ext-detail-dept').textContent = data.dept;
  document.getElementById('ext-detail-position').textContent = data.position || '-';
  document.getElementById('ext-detail-email').textContent = data.email;
  document.getElementById('ext-detail-phone').textContent = data.phone;
  document.getElementById('ext-detail-purpose').textContent = data.purpose;
  document.getElementById('ext-detail-period').textContent = data.period;
  document.getElementById('ext-detail-purpose-detail').textContent = data.purposeDetail;
  document.getElementById('ext-detail-data').textContent = data.dataAccess;
  document.getElementById('ext-detail-attachment').textContent = data.attachment || '-';

  // 상태 배지
  var statusMap = { '승인대기': { bg:'#fff8e1', c:'#d48806' }, '승인완료': { bg:'#e8f5e9', c:'#2e7d32' }, '반려': { bg:'#ffebee', c:'#c62828' } };
  var st = statusMap[data.status] || { bg:'#f5f5f5', c:'#666' };
  document.getElementById('ext-detail-status').innerHTML = '<span style="background:'+st.bg+';color:'+st.c+';padding:2px 10px;border-radius:4px;font-size:12px;font-weight:600;">'+data.status+'</span>';

  // 타임라인
  var timeline = document.getElementById('ext-detail-timeline');
  var html = '<div style="border-left:2px solid var(--border-color); padding-left:16px; margin-left:8px;">';
  html += '<div style="position:relative; margin-bottom:16px;">';
  html += '<div style="position:absolute; left:-22px; top:2px; width:12px; height:12px; border-radius:50%; background:#1677ff; border:2px solid #fff;"></div>';
  html += '<div style="font-size:12px; font-weight:600;">신청서 접수</div>';
  html += '<div style="font-size:11px; color:var(--text-secondary);">' + data.date + ' · ' + data.name + ' (' + data.org + ')</div>';
  html += '</div>';

  if (data.status === '승인완료') {
    html += '<div style="position:relative; margin-bottom:16px;">';
    html += '<div style="position:absolute; left:-22px; top:2px; width:12px; height:12px; border-radius:50%; background:#52c41a; border:2px solid #fff;"></div>';
    html += '<div style="font-size:12px; font-weight:600; color:#52c41a;">승인 완료</div>';
    html += '<div style="font-size:11px; color:var(--text-secondary);">' + data.processDate + ' · 관리자 승인 처리</div>';
    html += '</div>';
  } else if (data.status === '반려') {
    html += '<div style="position:relative; margin-bottom:16px;">';
    html += '<div style="position:absolute; left:-22px; top:2px; width:12px; height:12px; border-radius:50%; background:#f5222d; border:2px solid #fff;"></div>';
    html += '<div style="font-size:12px; font-weight:600; color:#f5222d;">반려</div>';
    html += '<div style="font-size:11px; color:var(--text-secondary);">' + data.processDate + ' · 사유: ' + (data.rejectReason || '-') + '</div>';
    html += '</div>';
  }
  html += '</div>';
  timeline.innerHTML = html;

  // 액션 카드 표시/숨김
  var actionCard = document.getElementById('ext-detail-action-card');
  var resultCard = document.getElementById('ext-detail-result-card');
  if (data.status === '승인대기') {
    actionCard.style.display = '';
    resultCard.style.display = 'none';
  } else if (data.status === '승인완료') {
    actionCard.style.display = 'none';
    resultCard.style.display = '';
    var genId = 'EXT_' + data.name.substring(0,1) + String(Math.floor(Math.random() * 9000) + 1000);
    document.getElementById('ext-detail-result').innerHTML =
      '<div style="display:grid; grid-template-columns:1fr 1fr; gap:8px;">' +
      '<div style="font-size:12px;"><span style="color:var(--text-secondary); min-width:80px; display:inline-block;">생성 계정</span> <strong>' + genId + '</strong></div>' +
      '<div style="font-size:12px;"><span style="color:var(--text-secondary); min-width:80px; display:inline-block;">임시 비밀번호</span> <code style="background:#f5f5f5; padding:2px 6px; border-radius:4px; font-size:11px;">Kw@' + Math.random().toString(36).substring(2, 8) + '</code></div>' +
      '<div style="font-size:12px;"><span style="color:var(--text-secondary); min-width:80px; display:inline-block;">계정 유효기간</span> ' + data.period + '</div>' +
      '<div style="font-size:12px;"><span style="color:var(--text-secondary); min-width:80px; display:inline-block;">접근 권한</span> 데이터 조회 (3등급)</div>' +
      '</div>';
  } else {
    actionCard.style.display = 'none';
    resultCard.style.display = 'none';
  }

  // 현재 상세 데이터 저장
  window._extDetailData = data;
  navigate('sys-ext-register-detail');
}

// --- 승인 처리 (직접) ---
function approveExtRegisterDirect(data) {
  data.status = '승인완료';
  data.processDate = new Date().toISOString().substring(0, 10);
  showToast(data.name + '님의 신청이 승인되었습니다. 계정이 생성되었습니다.', 'success');
  initExtRegisterGrid();
}

// 상세 화면에서 승인
function approveExtRegister() {
  if (!window._extDetailData) return;
  approveExtRegisterDirect(window._extDetailData);
  openExtRegisterDetail(window._extDetailData);
}

// --- 반려 모달 ---
function openExtRejectModal(data) {
  if (!data) return;
  window._extRejectTarget = data;
  document.getElementById('ext-reject-modal-id').textContent = data.id;
  document.getElementById('ext-reject-modal-date').textContent = data.date;
  document.getElementById('ext-reject-modal-name').textContent = data.name;
  document.getElementById('ext-reject-modal-org').textContent = data.org;
  document.getElementById('ext-reject-modal-reason').value = '';
  document.getElementById('ext-reject-modal').style.display = 'flex';
}

function closeExtRejectModal() {
  var modal = document.getElementById('ext-reject-modal');
  modal.style.display = 'none';
  var card = modal.querySelector('.modal-card');
  if (card) { card.style.transform = ''; card.style.left = ''; card.style.top = ''; card.style.position = ''; card.style.margin = ''; }
  window._extRejectTarget = null;
}

function confirmExtReject() {
  var reason = document.getElementById('ext-reject-modal-reason').value.trim();
  if (!reason) {
    showToast('반려 사유를 입력해주세요.', 'error');
    return;
  }
  var data = window._extRejectTarget;
  if (!data) return;
  data.status = '반려';
  data.processDate = new Date().toISOString().substring(0, 10);
  data.rejectReason = reason;
  showToast(data.name + '님의 신청이 반려되었습니다.', 'error');
  initExtRegisterGrid();
  closeExtRejectModal();
  // 상세 화면이 열려 있으면 갱신
  if (window._extDetailData && window._extDetailData.id === data.id) {
    openExtRegisterDetail(data);
  }
}

/* ========== 감사로그 필터/검색 ========== */
function filterAuditLog() {
  var grid = agGridInstances['ag-grid-sys-audit'];
  if (!grid) return;
  var typeVal = document.getElementById('audit-filter-type') ? document.getElementById('audit-filter-type').value : '';
  var riskVal = document.getElementById('audit-filter-risk') ? document.getElementById('audit-filter-risk').value : '';
  var searchVal = document.getElementById('audit-filter-search') ? document.getElementById('audit-filter-search').value.trim() : '';

  // 외부 필터 사용
  grid.setGridOption('isExternalFilterPresent', function() {
    return typeVal !== '' || riskVal !== '' || searchVal !== '';
  });
  grid.setGridOption('doesExternalFilterPass', function(node) {
    var d = node.data;
    if (typeVal && d.type !== typeVal) return false;
    if (riskVal && d.risk !== riskVal) return false;
    if (searchVal) {
      var s = searchVal.toLowerCase();
      var match = (d.user && d.user.toLowerCase().indexOf(s) >= 0) ||
                  (d.activity && d.activity.toLowerCase().indexOf(s) >= 0) ||
                  (d.entity && d.entity.toLowerCase().indexOf(s) >= 0) ||
                  (d.dept && d.dept.toLowerCase().indexOf(s) >= 0);
      if (!match) return false;
    }
    return true;
  });
  grid.onFilterChanged();
}

/* ========== 감사로그 상세보기 모달 ========== */
function openAuditDetail(data) {
  var modal = document.getElementById('audit-detail-modal');
  if (!modal) return;
  // 데이터 바인딩
  var el = function(id) { return document.getElementById(id); };
  el('adm-time').textContent = data.time || '-';
  el('adm-user').textContent = data.user || '-';
  el('adm-dept').textContent = data.dept || '-';
  el('adm-ip').textContent = data.ip || '-';
  el('adm-entity').textContent = data.entity || '-';
  el('adm-activity').textContent = data.activity || '-';

  // 유형 배지
  var typeColors = { '데이터':{bg:'#e8f0fe',c:'#1967d2'}, '수집':{bg:'#e8f5e9',c:'#2e7d32'}, '유통':{bg:'#fff3e0',c:'#ef6c00'}, '접속':{bg:'#f3e5f5',c:'#7b1fa2'}, '시스템':{bg:'#e0f7fa',c:'#00838f'}, '권한':{bg:'#fce4ec',c:'#c62828'}, '배치':{bg:'#f1f8e9',c:'#558b2f'}, 'API':{bg:'#e8eaf6',c:'#3949ab'} };
  var tc = typeColors[data.type] || {bg:'#f5f5f5',c:'#666'};
  el('adm-type').innerHTML = '<span style="background:'+tc.bg+';color:'+tc.c+';padding:2px 10px;border-radius:4px;font-size:12px;font-weight:600;">'+data.type+'</span>';

  // 결과 배지
  var resultMap = { '성공': {icon:'✅', c:'#4caf50'}, '차단': {icon:'🚫', c:'#f44336'}, '경고': {icon:'⚠️', c:'#ff9800'} };
  var rc = resultMap[data.result] || {icon:'', c:'#666'};
  el('adm-result').innerHTML = '<span style="color:'+rc.c+';font-weight:700;">'+rc.icon+' '+data.result+'</span>';

  // 위험도 배지
  var riskMap = { '높음':{bg:'#fff1f0',c:'#cf1322'}, '보통':{bg:'#fff7e6',c:'#d48806'}, '낮음':{bg:'#f6ffed',c:'#389e0d'} };
  var rk = riskMap[data.risk] || {bg:'#f5f5f5',c:'#666'};
  el('adm-risk').innerHTML = '<span style="background:'+rk.bg+';color:'+rk.c+';padding:2px 10px;border-radius:4px;font-size:12px;font-weight:600;">'+data.risk+'</span>';

  // 동일 사용자 최근 활동 (AG Grid 데이터에서 추출)
  var grid = agGridInstances['ag-grid-sys-audit'];
  var relatedHtml = '';
  if (grid) {
    var rows = [];
    grid.forEachNode(function(node) {
      if (node.data.user === data.user && node.data.time !== data.time) rows.push(node.data);
    });
    rows = rows.slice(0, 5);
    if (rows.length > 0) {
      rows.forEach(function(r) {
        var rrc = resultMap[r.result] || {icon:'', c:'#666'};
        relatedHtml += '<tr><td style="font-family:monospace;font-size:11px;color:#888;">'+r.time+'</td><td style="font-size:11px;">'+r.activity+'</td><td><span style="color:'+rrc.c+';font-size:11px;">'+rrc.icon+' '+r.result+'</span></td></tr>';
      });
    } else {
      relatedHtml = '<tr><td colspan="3" style="text-align:center;color:#999;font-size:11px;">관련 활동 없음</td></tr>';
    }
  }
  el('adm-related-tbody').innerHTML = relatedHtml;

  modal.style.display = 'flex';
}

function closeAuditDetailModal() {
  var modal = document.getElementById('audit-detail-modal');
  if (!modal) return;
  modal.style.display = 'none';
  var card = modal.querySelector('.modal-card');
  if (card) { card.style.transform = ''; card.style.left = ''; card.style.top = ''; card.style.position = ''; card.style.margin = ''; }
}

/* ========== 감사로그 CSV 내보내기 ========== */
function exportAuditCSV() {
  var grid = agGridInstances['ag-grid-sys-audit'];
  if (!grid) { showToast('그리드 데이터를 찾을 수 없습니다.', 'error'); return; }
  var rows = [];
  grid.forEachNodeAfterFilterAndSort(function(node) { rows.push(node.data); });
  if (rows.length === 0) { showToast('내보낼 데이터가 없습니다.', 'error'); return; }

  var headers = ['시간', '사용자', '부서', '유형', '활동 내용', '대상 엔티티', 'IP', '결과', '위험도'];
  var fields = ['time', 'user', 'dept', 'type', 'activity', 'entity', 'ip', 'result', 'risk'];
  var csvContent = '\uFEFF'; // BOM (한글 깨짐 방지)
  csvContent += headers.join(',') + '\n';
  rows.forEach(function(r) {
    var line = fields.map(function(f) {
      var val = (r[f] || '').toString().replace(/"/g, '""');
      return '"' + val + '"';
    }).join(',');
    csvContent += line + '\n';
  });

  var blob = new Blob([csvContent], { type: 'text/csv;charset=utf-8;' });
  var url = URL.createObjectURL(blob);
  var a = document.createElement('a');
  a.href = url;
  a.download = '감사로그_' + new Date().toISOString().substring(0, 10) + '.csv';
  document.body.appendChild(a);
  a.click();
  document.body.removeChild(a);
  URL.revokeObjectURL(url);
  showToast('감사로그 CSV 파일이 다운로드되었습니다.', 'success');
}

/* ========== 사용자 역할 추가/해제 ========== */
function openAddRoleModal() {
  var modal = document.getElementById('user-role-add-modal');
  if (!modal) return;
  var data = window._currentUserDetail;
  var userInfo = data ? data.name + ' (' + data.empNo + ' · ' + data.dept + ')' : '-';
  document.getElementById('arm-user-info').textContent = userInfo;
  document.getElementById('arm-role-select').value = '';
  document.getElementById('arm-reason').value = '';
  modal.style.display = 'flex';
}

function closeAddRoleModal() {
  var modal = document.getElementById('user-role-add-modal');
  if (!modal) return;
  modal.style.display = 'none';
  var card = modal.querySelector('.modal-card');
  if (card) { card.style.transform = ''; card.style.left = ''; card.style.top = ''; card.style.position = ''; card.style.margin = ''; }
}

function addUserRole() {
  var roleName = document.getElementById('arm-role-select').value;
  if (!roleName) { showToast('추가할 역할을 선택하세요.', 'error'); return; }
  var data = window._currentUserDetail;
  if (!data) return;

  var roleColors = {
    '시스템관리자': { bg:'#e8f0fe', c:'#1967d2', lv:'5' },
    '데이터관리자': { bg:'#e0f7fa', c:'#00838f', lv:'4' },
    '데이터엔지니어': { bg:'#fff3e0', c:'#ef6c00', lv:'3' },
    '일반사용자': { bg:'#f3e5f5', c:'#7b1fa2', lv:'2' },
    '외부사용자': { bg:'#fce4ec', c:'#c62828', lv:'1' }
  };
  var rc = roleColors[roleName] || { bg:'#f5f5f5', c:'#666', lv:'1' };
  var today = new Date().toISOString().substring(0, 10);

  // 중복 체크
  var tbody = document.getElementById('ud-roles');
  if (tbody && tbody.innerHTML.indexOf(roleName) >= 0) {
    showToast('이미 할당된 역할입니다.', 'error');
    return;
  }

  // 테이블 맨 앞에 행 추가
  var newRow = '<tr><td><span style="background:' + rc.bg + ';color:' + rc.c + ';padding:2px 8px;border-radius:4px;font-size:11px;font-weight:600;">' + roleName + '</span></td>' +
    '<td>Level ' + rc.lv + '</td><td>' + today + '</td><td>' + (window.currentRoleKey || 'admin') + '</td>' +
    '<td><button class="btn btn-outline btn-sm" style="font-size:10px;padding:1px 6px;color:#ef4444;border-color:#ef4444;" data-perm="admin" onclick="removeUserRole(this,\'' + roleName + '\')">해제</button></td></tr>';
  if (tbody) tbody.insertAdjacentHTML('afterbegin', newRow);

  // 이력 기록
  addPermHistory(roleName, 'user-role', '-', roleName);
  showToast(data.name + '님에게 ' + roleName + ' 역할이 추가되었습니다.', 'success');
  closeAddRoleModal();
}

function removeUserRole(btn, roleName) {
  if (!confirm(roleName + ' 역할을 해제하시겠습니까?')) return;
  var row = btn.closest('tr');
  if (row) row.remove();
  var data = window._currentUserDetail;
  var userName = data ? data.name : '-';
  addPermHistory(roleName, 'user-role', roleName, '해제');
  showToast(userName + '님의 ' + roleName + ' 역할이 해제되었습니다.', 'success');
}

/* ========== 사용자 승인 처리 ========== */
var _approveTarget = null;

function openApproveModal(data) {
  _approveTarget = data;
  var modal = document.getElementById('user-approve-modal');
  if (!modal) return;
  document.getElementById('apm-name').textContent = data.name || '-';
  document.getElementById('apm-empNo').textContent = data.empNo || '-';
  document.getElementById('apm-dept').textContent = data.dept || '-';
  document.getElementById('apm-role').textContent = data.role || '-';
  document.getElementById('apm-comment').value = '';
  modal.style.display = 'flex';
}

function closeApproveModal() {
  var modal = document.getElementById('user-approve-modal');
  if (!modal) return;
  modal.style.display = 'none';
  var card = modal.querySelector('.modal-card');
  if (card) { card.style.transform = ''; card.style.left = ''; card.style.top = ''; card.style.position = ''; card.style.margin = ''; }
  _approveTarget = null;
}

function approveUser() {
  if (!_approveTarget) return;
  var data = _approveTarget;
  var today = new Date().toISOString().substring(0, 10);

  // AG Grid 데이터 갱신
  data.status = '활성';
  data.joinDate = today;
  data.access = data.role === '시스템관리자' ? '전체' : data.role === '데이터관리자' ? '전체' : data.role === '데이터엔지니어' ? '할당됨' : data.role === '외부사용자' ? '3등급만' : '등급별';

  var grid = agGridInstances['ag-grid-sys-user'];
  if (grid) {
    grid.applyTransaction({ update: [data] });
    grid.refreshCells({ force: true });
  }

  addPermHistory(data.name, 'user-approve', '승인대기', '활성(승인)');
  showToast(data.name + '님의 가입이 승인되었습니다.', 'success');
  closeApproveModal();
}

function rejectUser() {
  if (!_approveTarget) return;
  var comment = document.getElementById('apm-comment').value.trim();
  if (!comment) { showToast('반려 의견을 입력하세요.', 'error'); return; }
  var data = _approveTarget;

  // AG Grid에서 행 제거
  var grid = agGridInstances['ag-grid-sys-user'];
  if (grid) {
    grid.applyTransaction({ remove: [data] });
  }

  addPermHistory(data.name, 'user-approve', '승인대기', '반려');
  showToast(data.name + '님의 가입이 반려되었습니다.', 'error');
  closeApproveModal();
}

/* ========== 사용자 목록 필터 ========== */
function filterUserGrid() {
  var grid = agGridInstances['ag-grid-sys-user'];
  if (!grid) return;
  var statusVal = document.getElementById('user-filter-status') ? document.getElementById('user-filter-status').value : '';
  var deptVal = document.getElementById('user-filter-dept') ? document.getElementById('user-filter-dept').value : '';
  var roleVal = document.getElementById('user-filter-role') ? document.getElementById('user-filter-role').value : '';
  var searchVal = document.getElementById('user-filter-search') ? document.getElementById('user-filter-search').value.trim() : '';

  grid.setGridOption('isExternalFilterPresent', function() {
    return statusVal !== '' || deptVal !== '' || roleVal !== '' || searchVal !== '';
  });
  grid.setGridOption('doesExternalFilterPass', function(node) {
    var d = node.data;
    if (statusVal && d.status !== statusVal) return false;
    if (deptVal && d.dept !== deptVal) return false;
    if (roleVal && d.role !== roleVal) return false;
    if (searchVal) {
      var s = searchVal.toLowerCase();
      var match = (d.name && d.name.toLowerCase().indexOf(s) >= 0) ||
                  (d.empNo && d.empNo.toLowerCase().indexOf(s) >= 0) ||
                  (d.dept && d.dept.toLowerCase().indexOf(s) >= 0);
      if (!match) return false;
    }
    return true;
  });
  grid.onFilterChanged();
}

/* ========== 사용자 목록 CSV 내보내기 ========== */
function exportUserCSV() {
  var grid = agGridInstances['ag-grid-sys-user'];
  if (!grid) { showToast('그리드 데이터를 찾을 수 없습니다.', 'error'); return; }
  var rows = [];
  grid.forEachNodeAfterFilterAndSort(function(node) { rows.push(node.data); });
  if (rows.length === 0) { showToast('내보낼 데이터가 없습니다.', 'error'); return; }

  var headers = ['이름', '사번', '부서', '직급', '역할', '접근등급', '상태', 'SSO', '최종로그인', '가입일'];
  var fields = ['name', 'empNo', 'dept', 'grade', 'role', 'access', 'status', 'sso', 'lastLogin', 'joinDate'];
  var csvContent = '\uFEFF';
  csvContent += headers.join(',') + '\n';
  rows.forEach(function(r) {
    var line = fields.map(function(f) {
      var val = (r[f] || '').toString().replace(/"/g, '""');
      return '"' + val + '"';
    }).join(',');
    csvContent += line + '\n';
  });

  var blob = new Blob([csvContent], { type: 'text/csv;charset=utf-8;' });
  var url = URL.createObjectURL(blob);
  var a = document.createElement('a');
  a.href = url;
  a.download = '사용자목록_' + new Date().toISOString().substring(0, 10) + '.csv';
  document.body.appendChild(a);
  a.click();
  document.body.removeChild(a);
  URL.revokeObjectURL(url);
  showToast('사용자 목록 CSV 파일이 다운로드되었습니다.', 'success');
}

/* ========== 권한 변경 승인 프로세스 ========== */
function closePermApproveModal() {
  var modal = document.getElementById('perm-approve-modal');
  if (!modal) return;
  modal.style.display = 'none';
  var card = modal.querySelector('.modal-card');
  if (card) { card.style.transform = ''; card.style.left = ''; card.style.top = ''; card.style.position = ''; card.style.margin = ''; }
}

function submitPermApproval() {
  var reason = document.getElementById('pam-reason').value.trim();
  if (!reason) { showToast('요청 사유를 입력하세요.', 'error'); return; }

  var roleKey = document.getElementById('perm-role-select').value;

  // 승인 요청 이력 저장
  var approvalRequests = JSON.parse(localStorage.getItem('PERM_APPROVAL_REQUESTS') || '[]');
  var custom = getCustomScreenPerms();
  var rolePerms = custom[roleKey] || {};

  approvalRequests.unshift({
    id: 'PAR-' + Date.now(),
    date: new Date().toISOString().substring(0, 19).replace('T', ' '),
    role: roleKey,
    changes: rolePerms,
    changeCount: Object.keys(rolePerms).length,
    reason: reason,
    requester: window.currentRoleKey || 'admin',
    status: '대기중'
  });

  // 최대 50건 보관
  if (approvalRequests.length > 50) approvalRequests = approvalRequests.slice(0, 50);
  localStorage.setItem('PERM_APPROVAL_REQUESTS', JSON.stringify(approvalRequests));

  // 변경 이력에도 기록
  addPermHistory(roleKey, '(승인요청)', '변경 ' + Object.keys(rolePerms).length + '건', '승인대기');

  showToast(roleKey + ' 역할의 권한 변경 승인이 요청되었습니다.', 'success');
  closePermApproveModal();

  // 변경 이력 UI 갱신
  if (typeof updatePermHistory === 'function') updatePermHistory();
}

// ===== 복구 로그 조회 (sys-recovery-log) =====

var recoveryLogData = [
  { date: '2026-03-19', time: '11:42:30', recoveryId: 'REC-2026-0147', db: 'DataHub-Prod', type: 'Full', status: '성공', duration: '2분 34초', records: '15,420', sizeMb: '1,240', verify: '검증완료', user: 'admin',
    bkupSrc: 'S3-Backup', bkupDt: '2026-03-19 10:00', vrfyBy: 'admin', vrfyAt: '11:50:00', vrfyRslt: '무결성 검사 통과 (100%), 체크섬 일치',
    tables: [
      { name: 'TB_WATER_LEVEL', total: 15420, recovered: 15420, errors: 0, stat: '성공', dur: '1분 20초' },
      { name: 'TB_WATER_LEVEL_HIST', total: 8230, recovered: 8230, errors: 0, stat: '성공', dur: '1분 14초' }
    ]},
  { date: '2026-03-19', time: '11:15:00', recoveryId: 'REC-2026-0146', db: 'Analytics-DB', type: 'Incremental', status: '성공', duration: '1분 48초', records: '8,320', sizeMb: '520', verify: '검증완료', user: '김데이터',
    bkupSrc: 'NFS-Mount', bkupDt: '2026-03-19 09:00', vrfyBy: '김데이터', vrfyAt: '11:25:00', vrfyRslt: '증분 데이터 정합성 확인 완료',
    tables: [
      { name: 'TB_ANALYSIS_RESULT', total: 5100, recovered: 5100, errors: 0, stat: '성공', dur: '52초' },
      { name: 'TB_PREDICT_MODEL', total: 3220, recovered: 3220, errors: 0, stat: '성공', dur: '56초' }
    ]},
  { date: '2026-03-19', time: '10:30:15', recoveryId: 'REC-2026-0145', db: 'DataHub-DR', type: 'Full', status: '성공', duration: '4분 12초', records: '42,100', sizeMb: '3,200', verify: '검증완료', user: 'admin',
    bkupSrc: 'S3-Backup', bkupDt: '2026-03-19 06:00', vrfyBy: 'admin', vrfyAt: '10:45:00', vrfyRslt: 'DR 동기화 검증 통과, RPO 4시간 충족',
    tables: [
      { name: 'TB_WATER_QUALITY', total: 22100, recovered: 22100, errors: 0, stat: '성공', dur: '2분 05초' },
      { name: 'TB_SENSOR_DATA', total: 15000, recovered: 15000, errors: 0, stat: '성공', dur: '1분 30초' },
      { name: 'TB_ALERT_HIST', total: 5000, recovered: 5000, errors: 0, stat: '성공', dur: '37초' }
    ]},
  { date: '2026-03-19', time: '09:00:00', recoveryId: 'REC-2026-0144', db: 'DataHub-Prod', type: 'Point-in-time', status: '실패', duration: '6분 30초', records: '0', sizeMb: '0', verify: '검증실패', user: 'admin',
    bkupSrc: 'S3-Backup', bkupDt: '2026-03-18 23:00', vrfyBy: '-', vrfyAt: '-', vrfyRslt: '-', errMsg: 'WAL 로그 손상으로 Point-in-time 복구 실패 (target: 2026-03-18 23:30:00)',
    tables: [
      { name: 'TB_BILLING_DATA', total: 31200, recovered: 0, errors: 31200, stat: '실패', dur: '-' }
    ]},
  { date: '2026-03-18', time: '22:15:00', recoveryId: 'REC-2026-0143', db: 'SAP-HANA', type: 'Full', status: '성공', duration: '8분 15초', records: '125,000', sizeMb: '8,500', verify: '검증완료', user: '박DBA',
    bkupSrc: 'Local-Disk', bkupDt: '2026-03-18 18:00', vrfyBy: '박DBA', vrfyAt: '22:30:00', vrfyRslt: 'SAP HANA 시스템 무결성 확인 완료',
    tables: [
      { name: 'TB_SAP_FI_DOC', total: 48000, recovered: 48000, errors: 0, stat: '성공', dur: '3분 10초' },
      { name: 'TB_SAP_MM_PO', total: 35000, recovered: 35000, errors: 0, stat: '성공', dur: '2분 45초' },
      { name: 'TB_SAP_HR_EMP', total: 42000, recovered: 42000, errors: 0, stat: '성공', dur: '2분 20초' }
    ]},
  { date: '2026-03-18', time: '18:30:00', recoveryId: 'REC-2026-0142', db: 'Archive-DB', type: 'Differential', status: '성공', duration: '3분 55초', records: '28,400', sizeMb: '2,100', verify: '미검증', user: '김데이터',
    bkupSrc: 'NFS-Mount', bkupDt: '2026-03-18 12:00', vrfyBy: '-', vrfyAt: '-', vrfyRslt: '-',
    tables: [
      { name: 'TB_LOG_ARCHIVE', total: 18400, recovered: 18400, errors: 0, stat: '성공', dur: '2분 20초' },
      { name: 'TB_AUDIT_ARCHIVE', total: 10000, recovered: 10000, errors: 0, stat: '성공', dur: '1분 35초' }
    ]},
  { date: '2026-03-18', time: '15:00:00', recoveryId: 'REC-2026-0141', db: 'DataHub-Prod', type: 'Incremental', status: '성공', duration: '1분 22초', records: '5,680', sizeMb: '380', verify: '검증완료', user: 'admin',
    bkupSrc: 'S3-Backup', bkupDt: '2026-03-18 14:00', vrfyBy: 'admin', vrfyAt: '15:10:00', vrfyRslt: '증분 복구 정합성 검증 완료',
    tables: [
      { name: 'TB_METER_READ', total: 5680, recovered: 5680, errors: 0, stat: '성공', dur: '1분 22초' }
    ]},
  { date: '2026-03-18', time: '12:00:00', recoveryId: 'REC-2026-0140', db: 'Analytics-DB', type: 'Point-in-time', status: '성공', duration: '5분 10초', records: '18,900', sizeMb: '1,580', verify: '검증완료', user: '이분석',
    bkupSrc: 'S3-Backup', bkupDt: '2026-03-18 08:00', vrfyBy: '이분석', vrfyAt: '12:20:00', vrfyRslt: 'Point-in-time 복구 성공, 타임스탬프 정합성 확인',
    tables: [
      { name: 'TB_PREDICTION', total: 10200, recovered: 10200, errors: 0, stat: '성공', dur: '3분 05초' },
      { name: 'TB_ML_FEATURE', total: 8700, recovered: 8700, errors: 0, stat: '성공', dur: '2분 05초' }
    ]},
  { date: '2026-03-18', time: '08:30:00', recoveryId: 'REC-2026-0139', db: 'DataHub-DR', type: 'Full', status: '진행중', duration: '-', records: '-', sizeMb: '-', verify: '미검증', user: 'system',
    bkupSrc: 'S3-Backup', bkupDt: '2026-03-18 06:00', vrfyBy: '-', vrfyAt: '-', vrfyRslt: '-',
    tables: [
      { name: 'TB_REALTIME_FLOW', total: 55000, recovered: 32000, errors: 0, stat: '진행중', dur: '-' }
    ]},
  { date: '2026-03-17', time: '23:45:00', recoveryId: 'REC-2026-0138', db: 'DataHub-Prod', type: 'Full', status: '성공', duration: '3분 50초', records: '22,800', sizeMb: '1,850', verify: '검증완료', user: 'admin',
    bkupSrc: 'S3-Backup', bkupDt: '2026-03-17 22:00', vrfyBy: 'admin', vrfyAt: '00:05:00', vrfyRslt: '야간 정기 복구 검증 통과',
    tables: [
      { name: 'TB_WATER_LEVEL', total: 12800, recovered: 12800, errors: 0, stat: '성공', dur: '2분 10초' },
      { name: 'TB_RAINFALL', total: 10000, recovered: 10000, errors: 0, stat: '성공', dur: '1분 40초' }
    ]},
  { date: '2026-03-17', time: '20:00:00', recoveryId: 'REC-2026-0137', db: 'SAP-HANA', type: 'Incremental', status: '실패', duration: '2분 10초', records: '0', sizeMb: '0', verify: '검증실패', user: '박DBA',
    bkupSrc: 'Local-Disk', bkupDt: '2026-03-17 18:00', vrfyBy: '-', vrfyAt: '-', vrfyRslt: '-', errMsg: 'SAP HANA 증분 백업 체크포인트 불일치 (delta merge 진행 중 충돌)',
    tables: [
      { name: 'TB_SAP_CO_DOC', total: 15600, recovered: 0, errors: 15600, stat: '실패', dur: '-' }
    ]},
  { date: '2026-03-17', time: '14:20:00', recoveryId: 'REC-2026-0136', db: 'Archive-DB', type: 'Full', status: '성공', duration: '7분 42초', records: '85,200', sizeMb: '6,400', verify: '미검증', user: '김데이터',
    bkupSrc: 'NFS-Mount', bkupDt: '2026-03-17 06:00', vrfyBy: '-', vrfyAt: '-', vrfyRslt: '-',
    tables: [
      { name: 'TB_LOG_ARCHIVE', total: 45200, recovered: 45200, errors: 0, stat: '성공', dur: '4분 10초' },
      { name: 'TB_DATA_ARCHIVE', total: 40000, recovered: 40000, errors: 0, stat: '성공', dur: '3분 32초' }
    ]}
];

function initRecoveryLogScreen() {
  if (agGridInstances['ag-grid-sys-recovery-log']) { return; }

  var cols = [
    { field: 'date', headerName: '날짜', width: 100, cellStyle: { fontSize: '12px', color: '#888' } },
    { field: 'time', headerName: '시간', width: 80, cellStyle: { fontSize: '12px', color: '#888', fontFamily: 'monospace' } },
    { field: 'recoveryId', headerName: '복구ID', width: 130, cellRenderer: function(p) { return '<code style="background:#f5f5f5;padding:1px 6px;border-radius:3px;font-size:11px;">' + p.value + '</code>'; } },
    { field: 'db', headerName: '대상 DB', width: 120, cellRenderer: function(p) { return '<strong>' + p.value + '</strong>'; } },
    { field: 'type', headerName: '복구유형', width: 110, cellRenderer: function(p) {
      var m = { 'Full': { bg: '#e8f0fe', c: '#1967d2' }, 'Incremental': { bg: '#e8f5e9', c: '#2e7d32' }, 'Point-in-time': { bg: '#fff3e0', c: '#ef6c00' }, 'Differential': { bg: '#f3e5f5', c: '#7b1fa2' } };
      var s = m[p.value] || { bg: '#f5f5f5', c: '#666' };
      return '<span style="background:' + s.bg + ';color:' + s.c + ';padding:2px 8px;border-radius:4px;font-size:11px;font-weight:600;">' + p.value + '</span>';
    }},
    { field: 'status', headerName: '상태', width: 80, cellRenderer: function(p) {
      var m = { '성공': { icon: '✅', c: '#52c41a' }, '실패': { icon: '❌', c: '#f5222d' }, '진행중': { icon: '🔄', c: '#fa8c16' }, '취소': { icon: '⛔', c: '#888' } };
      var s = m[p.value] || { icon: '', c: '#666' };
      return '<span style="color:' + s.c + ';font-weight:600;font-size:11px;">' + s.icon + ' ' + p.value + '</span>';
    }},
    { field: 'duration', headerName: '소요시간', width: 90, cellStyle: { fontSize: '12px' } },
    { field: 'records', headerName: '레코드', width: 85, cellStyle: { fontSize: '12px', textAlign: 'right' } },
    { field: 'sizeMb', headerName: '용량(MB)', width: 85, cellStyle: { fontSize: '12px', textAlign: 'right' } },
    { field: 'verify', headerName: '검증', width: 85, cellRenderer: function(p) {
      var m = { '검증완료': { bg: '#e8f5e9', c: '#2e7d32' }, '미검증': { bg: '#fff7e6', c: '#d48806' }, '검증실패': { bg: '#fff1f0', c: '#cf1322' } };
      var s = m[p.value] || { bg: '#f5f5f5', c: '#666' };
      return '<span style="background:' + s.bg + ';color:' + s.c + ';padding:2px 8px;border-radius:4px;font-size:10px;font-weight:600;">' + p.value + '</span>';
    }},
    { field: 'user', headerName: '실행자', width: 80, cellStyle: { fontSize: '12px' } },
    { field: 'detail', headerName: '상세', width: 60, sortable: false, filter: false, cellRenderer: function() { return '<button class="btn btn-outline" style="padding:1px 5px;font-size:10px;">보기</button>'; } }
  ];

  initAGGrid('ag-grid-sys-recovery-log', cols, recoveryLogData, {
    domLayout: 'autoHeight',
    getRowStyle: function(p) {
      if (p.data.status === '실패') { return { background: '#fff5f5' }; }
      if (p.data.status === '진행중') { return { background: '#fffbe6' }; }
    },
    onCellClicked: function(e) {
      if (e.colDef.field === 'detail') { openRecoveryDetail(e.data); }
    }
  });
}

function filterRecoveryLog() {
  var grid = agGridInstances['ag-grid-sys-recovery-log'];
  if (!grid) { return; }

  var dateFrom = document.getElementById('rcvry-date-from').value;
  var dateTo = document.getElementById('rcvry-date-to').value;
  var dbVal = document.getElementById('rcvry-filter-db').value;
  var typeVal = document.getElementById('rcvry-filter-type').value;
  var statusVal = document.getElementById('rcvry-filter-status').value;
  var vrfyVal = document.getElementById('rcvry-filter-vrfy').value;
  var searchVal = document.getElementById('rcvry-filter-search').value.trim().toLowerCase();

  grid.setGridOption('isExternalFilterPresent', function() {
    return dateFrom !== '' || dateTo !== '' || dbVal !== '' || typeVal !== '' || statusVal !== '' || vrfyVal !== '' || searchVal !== '';
  });

  grid.setGridOption('doesExternalFilterPass', function(node) {
    var d = node.data;
    if (dateFrom && d.date < dateFrom) { return false; }
    if (dateTo && d.date > dateTo) { return false; }
    if (dbVal && d.db !== dbVal) { return false; }
    if (typeVal && d.type !== typeVal) { return false; }
    if (statusVal && d.status !== statusVal) { return false; }
    if (vrfyVal && d.verify !== vrfyVal) { return false; }
    if (searchVal) {
      var match = (d.recoveryId && d.recoveryId.toLowerCase().indexOf(searchVal) >= 0) ||
                  (d.db && d.db.toLowerCase().indexOf(searchVal) >= 0);
      if (!match && d.tables) {
        for (var i = 0; i < d.tables.length; i++) {
          if (d.tables[i].name.toLowerCase().indexOf(searchVal) >= 0) { match = true; break; }
        }
      }
      if (!match) { return false; }
    }
    return true;
  });

  grid.onFilterChanged();
}

function resetRecoveryFilter() {
  document.getElementById('rcvry-date-from').value = '';
  document.getElementById('rcvry-date-to').value = '';
  document.getElementById('rcvry-filter-db').value = '';
  document.getElementById('rcvry-filter-type').value = '';
  document.getElementById('rcvry-filter-status').value = '';
  document.getElementById('rcvry-filter-vrfy').value = '';
  document.getElementById('rcvry-filter-search').value = '';
  filterRecoveryLog();
}

function exportRecoveryLog() {
  showToast('복구 로그 데이터를 CSV로 내보냅니다.', 'success');
}

function openRecoveryDetail(data) {
  var modal = document.getElementById('recovery-detail-modal');
  if (!modal) { return; }

  var el = function(id) { return document.getElementById(id); };
  el('rcvry-dtl-id').textContent = data.recoveryId || '-';
  el('rcvry-dtl-db').textContent = data.db || '-';
  el('rcvry-dtl-type').textContent = data.type || '-';
  el('rcvry-dtl-user').textContent = data.user || '-';

  // 상태 배지
  var statMap = { '성공': { icon: '✅', c: '#52c41a' }, '실패': { icon: '❌', c: '#f5222d' }, '진행중': { icon: '🔄', c: '#fa8c16' } };
  var st = statMap[data.status] || { icon: '', c: '#666' };
  el('rcvry-dtl-status').innerHTML = '<span style="color:' + st.c + ';font-weight:600;">' + st.icon + ' ' + (data.status || '-') + '</span>';

  el('rcvry-dtl-start').textContent = (data.date || '') + ' ' + (data.time || '');
  el('rcvry-dtl-end').textContent = data.fnshedAt || (data.status === '성공' ? data.date + ' (완료)' : '-');
  el('rcvry-dtl-duration').textContent = data.duration || '-';
  el('rcvry-dtl-bkup-src').textContent = data.bkupSrc || '-';
  el('rcvry-dtl-bkup-dt').textContent = data.bkupDt || '-';
  el('rcvry-dtl-total-rcrds').textContent = data.records || '-';
  el('rcvry-dtl-data-sz').textContent = (data.sizeMb || '-') + ' MB';

  // 검증 정보
  var vrfyMap = { '검증완료': { c: '#52c41a', icon: '✅' }, '미검증': { c: '#d48806', icon: '⏳' }, '검증실패': { c: '#cf1322', icon: '❌' } };
  var vs = vrfyMap[data.verify] || { c: '#666', icon: '' };
  el('rcvry-dtl-vrfy-stat').innerHTML = '<span style="color:' + vs.c + ';font-weight:600;">' + vs.icon + ' ' + (data.verify || '-') + '</span>';
  el('rcvry-dtl-vrfy-by').textContent = data.vrfyBy || '-';
  el('rcvry-dtl-vrfy-at').textContent = data.vrfyAt || '-';
  el('rcvry-dtl-vrfy-rslt').textContent = data.vrfyRslt || '-';

  // 테이블별 복구 내역
  var tbody = el('rcvry-dtl-table-tbody');
  if (data.tables && data.tables.length > 0) {
    var html = '';
    data.tables.forEach(function(t) {
      var statStyle = t.stat === '성공' ? 'color:#52c41a;' : (t.stat === '실패' ? 'color:#f5222d;' : 'color:#fa8c16;');
      html += '<tr>';
      html += '<td><code style="font-size:11px;">' + t.name + '</code></td>';
      html += '<td style="text-align:right;">' + (t.total || 0).toLocaleString() + '</td>';
      html += '<td style="text-align:right;">' + (t.recovered || 0).toLocaleString() + '</td>';
      html += '<td style="text-align:right;' + (t.errors > 0 ? 'color:#f5222d;font-weight:600;' : '') + '">' + (t.errors || 0).toLocaleString() + '</td>';
      html += '<td><span style="' + statStyle + 'font-weight:600;font-size:11px;">' + t.stat + '</span></td>';
      html += '<td>' + (t.dur || '-') + '</td>';
      html += '</tr>';
    });
    tbody.innerHTML = html;
  } else {
    tbody.innerHTML = '<tr><td colspan="6" style="text-align:center;color:#999;font-size:11px;">데이터 없음</td></tr>';
  }

  // 오류 메시지 표시/숨김
  var errBox = el('rcvry-dtl-error-box');
  if (data.errMsg) {
    errBox.style.display = 'block';
    el('rcvry-dtl-err-msg').textContent = data.errMsg;
  } else {
    errBox.style.display = 'none';
  }

  // 검증 실행 버튼 (미검증일 때만 표시)
  var vrfyBtn = el('rcvry-dtl-vrfy-btn');
  if (vrfyBtn) {
    vrfyBtn.style.display = (data.verify === '미검증') ? 'inline-flex' : 'none';
    vrfyBtn._rcvryData = data;
  }

  modal.style.display = 'flex';
}

function closeRecoveryDetailModal() {
  var modal = document.getElementById('recovery-detail-modal');
  if (!modal) { return; }
  modal.style.display = 'none';
  var card = modal.querySelector('.modal-card');
  if (card) { card.style.transform = ''; card.style.left = ''; card.style.top = ''; card.style.position = ''; card.style.margin = ''; }
}

function verifyRecoveryLog() {
  var btn = document.getElementById('rcvry-dtl-vrfy-btn');
  if (!btn || !btn._rcvryData) { return; }
  var data = btn._rcvryData;

  // 시뮬레이션: 검증 완료 처리
  data.verify = '검증완료';
  data.vrfyBy = window.currentRoleKey ? window.currentRoleKey.split('|')[1] || 'admin' : 'admin';
  data.vrfyAt = new Date().toLocaleTimeString('ko-KR', { hour: '2-digit', minute: '2-digit', second: '2-digit' });
  data.vrfyRslt = '무결성 검사 통과, 체크섬 일치 확인 완료';

  showToast(data.recoveryId + ' 복구 검증이 완료되었습니다.', 'success');

  // AG Grid 갱신
  var grid = agGridInstances['ag-grid-sys-recovery-log'];
  if (grid) { grid.refreshCells({ force: true }); }

  // 모달 갱신
  openRecoveryDetail(data);
}
