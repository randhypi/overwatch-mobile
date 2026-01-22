document.addEventListener('DOMContentLoaded', () => {
  // --- Global State ---
  let allIsoTransactions = [];
  let allJsonTransactions = [];
  let filteredIso = [];
  let filteredJson = [];
  let sortOrder = 'desc'; // 'desc' for newest first, 'asc' for oldest first

  // --- Virtual Scroller State ---
  const ITEM_HEIGHT = 150; // Estimated height of a transaction card
  const BUFFER_SIZE = 10; // Number of items to render outside viewport

  // --- Element References ---
  const filterInputs = document.querySelectorAll('.filter-input');
  const logicToggle = document.getElementById('logic-toggle');
  const sortButton = document.getElementById('sort-toggle-btn');
  const isoResultsContainer = document.getElementById('iso-results');
  const jsonResultsContainer = document.getElementById('json-results');
  const bankDatalist = document.getElementById('bank-list');

  // --- Data Population ---
  function populateBankDatalist() {
    if (!window.BIN_DATA || Object.keys(window.BIN_DATA).length === 0) {
      console.warn('BIN_DATA is not available to populate bank list.');
      return;
    }

    const uniqueBanks = new Map();
    for (const bin in window.BIN_DATA) {
      const bank = window.BIN_DATA[bin];
      if (bank && bank.name && !uniqueBanks.has(bank.name)) {
        uniqueBanks.set(bank.name, bank);
      }
    }

    const fragment = document.createDocumentFragment();
    uniqueBanks.forEach(bank => {
      const option = document.createElement('option');
      option.value = bank.name;
      fragment.appendChild(option);
    });

    bankDatalist.appendChild(fragment);
    
    // Trigger re-render now that BIN data is available
    console.log('[Dashboard] BIN Data loaded. Refreshing cards with Bank Names...');
    applyFiltersAndRender();
  }

  function whenBinDataReady(callback) {
    if (window.BIN_DATA && Object.keys(window.BIN_DATA).length > 0) {
      callback();
    } else {
      setTimeout(() => whenBinDataReady(callback), 150);
    }
  }

  // --- Data Fetching ---
  async function initializeDashboard() {
    const loadingOverlay = document.getElementById('loadingOverlay');
    if (loadingOverlay) loadingOverlay.style.display = 'flex';

    whenBinDataReady(populateBankDatalist);

    const maxRetries = 20;
    let attempt = 0;

    while (attempt < maxRetries) {
      try {
        console.log(`[Dashboard] Fetching data from SERVER (Attempt ${attempt + 1}/${maxRetries})...`);

        // SERVER ARCHITECTURE: Request data from Node.js Server
        const response = await fetch('/api/transactions');
        if (!response.ok) {
           throw new Error(`Server error: ${response.status} ${response.statusText}`);
        }
        
        const jsonResponse = await response.json();
        
        if (!jsonResponse.success) {
          throw new Error(jsonResponse.error || 'Failed to fetch data from server');
        }

        const { iso, json } = jsonResponse.data;
        allIsoTransactions = iso || [];
        allJsonTransactions = json || [];

        console.log(`Loaded ${allIsoTransactions.length} ISO and ${allJsonTransactions.length} JSON transactions.`);
        
        // --- DEBUG STATS DISPLAY ---
        const debugStats = document.getElementById('debug-stats-bar') || document.createElement('div');
        debugStats.id = 'debug-stats-bar';
        debugStats.style.cssText = 'background: #111; padding: 10px; margin-bottom: 20px; border-left: 4px solid #4ade80; color: #fff; font-family: monospace; font-size: 14px;';
        debugStats.innerHTML = `
           <strong>SYSTEM HEALTH CHECK:</strong> &nbsp;
           <span style="color:${allIsoTransactions.length > 0 ? '#4ade80' : '#f87171'}">ISO Logs: ${allIsoTransactions.length}</span> &nbsp;|&nbsp;
           <span style="color:${allJsonTransactions.length > 0 ? '#4ade80' : '#f87171'}">JSON Logs: ${allJsonTransactions.length}</span> &nbsp;|&nbsp;
           <span>Total: ${allIsoTransactions.length + allJsonTransactions.length}</span>
        `;
        // Insert before filters if possible, or prepended to main container
        const mainContainer = document.querySelector('.container') || document.body;
        if (!document.getElementById('debug-stats-bar')) mainContainer.prepend(debugStats);
        // ---------------------------

        // --- DEBUG: LOG RAW DATA ---
        console.group("🔍 DATA DEBUG INSPECTION");
        if (allIsoTransactions.length > 0) {
            console.log("ISO Item [0]:", allIsoTransactions[0]);
            console.log("ISO Item [0] MTI Check:", allIsoTransactions[0].mti, "Req MTI:", allIsoTransactions[0].request?.mti);
        } else {
            console.warn("ISO Data is EMPTY");
        }

        if (allJsonTransactions.length > 0) {
           console.log("JSON Item [0]:", allJsonTransactions[0]);
           console.log("JSON Item [0] Trace Check:", allJsonTransactions[0].traceNumber, "Ref:", allJsonTransactions[0].refnum);
        }
        console.groupEnd();
        // ---------------------------

        applyFiltersAndRender();
        
        if (loadingOverlay) loadingOverlay.style.display = 'none';
        return; // Success!

      } catch (error) {
        attempt++;
        console.warn(`[Dashboard] Failed to load data (Attempt ${attempt}):`, error);

        if (attempt >= maxRetries) {
          if (loadingOverlay) loadingOverlay.style.display = 'none';
          isoResultsContainer.innerHTML = `<p class="status-message error">Gagal memuat database dari Server.<br>Error: ${error.message}<br>Pastikan Server Node.js berjalan (port 3000).</p>`;
        } else {
          if (attempt > 3) {
            isoResultsContainer.innerHTML = `<p class="status-message warning">Menunggu koneksi Server... (Percobaan ${attempt}/${maxRetries})<br>Mohon pastikan server dinyalakan...</p>`;
          }
          await new Promise(r => setTimeout(r, 1500));
        }
      }
    }
  }

  // --- Rendering Logic (Standard List, No Virtual Scroll) ---
  function renderList(container, items, renderItemFn) {
    container.innerHTML = '';
    const fragment = document.createDocumentFragment();

    // Render all items (consider pagination if > 500 items in future)
    items.forEach(item => {
      const element = renderItemFn(item);
      fragment.appendChild(element);
    });

    container.appendChild(fragment);
  }

  // --- Lazy Rendering State ---
  let alignedCache = [];
  let renderOffset = 0;
  const BATCH_SIZE = 50;
  let observer = null;

  function setupInfiniteScroll() {
    if (observer) observer.disconnect();
    
    observer = new IntersectionObserver((entries) => {
      // If sentinel is visible, load more
      if (entries[0].isIntersecting) {
        renderNextBatch();
      }
    }, { rootMargin: '400px' }); // Preload 400px before reaching bottom
  }

  function renderNextBatch() {
    const batch = alignedCache.slice(renderOffset, renderOffset + BATCH_SIZE);
    
    // Safety check
    if (batch.length === 0 && renderOffset === 0) {
       isoResultsContainer.innerHTML = '<p class="status-message">No matching transactions.</p>';
       jsonResultsContainer.innerHTML = '<p class="status-message">No matching transactions.</p>';
       return;
    }
    if (batch.length === 0) return; // No more data to append

    // Remove existing Sentinel (if any)
    const oldSentinels = document.querySelectorAll('.scroll-sentinel');
    oldSentinels.forEach(el => el.remove());

    const isoFragment = document.createDocumentFragment();
    const jsonFragment = document.createDocumentFragment();

    batch.forEach(row => {
      // Render ALL ISOs for this RefNum group
      row.isos?.forEach(iso => {
        isoFragment.appendChild(createIsoCard(iso));
      });
      
      // Render ALL JSONs for this RefNum group
      row.jsons?.forEach(json => {
        jsonFragment.appendChild(createJsonCard(json));
      });
    });

    isoResultsContainer.appendChild(isoFragment);
    jsonResultsContainer.appendChild(jsonFragment);

    renderOffset += BATCH_SIZE;

    // Append New Sentinel if there is more data
    if (renderOffset < alignedCache.length) {
      const sentinel = document.createElement('div');
      sentinel.className = 'scroll-sentinel';
      sentinel.style.height = '20px'; // minimal height
      sentinel.style.width = '100%';
      // Append only to one container to trigger observer (ISO container is fine)
      isoResultsContainer.appendChild(sentinel);
      if (observer) observer.observe(sentinel);
    }
  }

  function applyFiltersAndRender() {
    const filters = Array.from(filterInputs).reduce((acc, input) => {
      acc[input.dataset.filter] = input.value.trim();
      return acc;
    }, {});
    const isAndLogic = logicToggle.checked;

    // 1. Join EVERYTHING first to get pairs
    const allJoined = joinTransactions(allIsoTransactions, allJsonTransactions, sortOrder);

    // 2. Filter the pairs (Pair-Aware)
    alignedCache = allJoined.filter(entry => shouldShowEntry(entry, filters, isAndLogic));
    
    // 3. REPOPULATE Global Arrays for Copy/Export Handlers
    filteredIso = alignedCache.flatMap(entry => entry.isos || []);
    filteredJson = alignedCache.flatMap(entry => entry.jsons || []);

    // 4. Reset Rendering State
    renderOffset = 0;
    isoResultsContainer.innerHTML = '';
    jsonResultsContainer.innerHTML = '';

    // 4. Init Scroll Observer
    setupInfiniteScroll();

    // 5. Render First Batch
    renderNextBatch();
  }

  function joinTransactions(isoList, jsonList, sortOrder) {
    // Group by RefNum (fallback to other unique keys if RefNum is N/A, but RefNum is safest for pairing)
    const map = new Map();
    const allItems = [];

    // 1. Map ISOs (Support multiple legs per RefNum)
    isoList.forEach(item => {
      // Key: RefNum alone behaves best for financial matching
      // If RefNum is N/A/empty, use a unique timestamp-random key effectively disabling matching
      const key = (item.refNum && item.refNum !== 'N/A') ? item.refNum : `ISO_UNMATCHED_${Math.random()}`;
      
      if (!map.has(key)) map.set(key, { isos: [], jsons: [], sortTime: null });
      const entry = map.get(key);
      entry.isos.push(item); // ✅ PUSH instead of overwrite
      
      const itemTime = item.request?.timestamp || item.response?.timestamp || item.timestamp;
      if (!entry.sortTime || itemTime > entry.sortTime) {
        entry.sortTime = itemTime;
      }
    });

    // 2. Map JSONs (Support multiple legs per RefNum)
    jsonList.forEach(item => {
      // Use hoisted refnum for reliability
      const refKey = item.refnum || item.request?.data?.referenceNumber;
      // Normalization: Remove whitespace/unknown chars if any
      const key = (refKey && String(refKey).trim() !== '') ? String(refKey).trim() : `JSON_UNMATCHED_${Math.random()}`;

      if (!map.has(key)) map.set(key, { isos: [], jsons: [], sortTime: null });
      const entry = map.get(key);
      entry.jsons.push(item); // ✅ PUSH instead of overwrite
      
      // Update sortTime if ISO didn't set it
      const jsonTime = item.timestamp;
      if (!entry.sortTime || (sortOrder === 'desc' ? jsonTime > entry.sortTime : jsonTime < entry.sortTime)) {
         entry.sortTime = jsonTime;
      }
    });
    
    // DEBUG: Check Alignment Stats
    let matchCount = 0;
    let isoOnly = 0;
    let jsonOnly = 0;
    map.forEach(val => {
        if (val.isos.length > 0 && val.jsons.length > 0) matchCount++;
        else if (val.isos.length > 0) isoOnly++;
        else if (val.jsons.length > 0) jsonOnly++;
    });
    // console.log(`[Join Stats] Checked ${isoList.length} ISO, ${jsonList.length} JSON.`);
    // console.log(`[Join Stats] Matched: ${matchCount} | ISO Only: ${isoOnly} | JSON Only: ${jsonOnly}`);

    // 3. Convert to Array
    const joinedList = Array.from(map.values());

    // 4. Sort
    joinedList.sort((a, b) => {
      const timeA = a.sortTime || '';
      const timeB = b.sortTime || '';
      if (!timeA || !timeB) return 0;
      
      // FIX: Use Date directly (ISO strings are safe)
      // If server returns ISO (e.g., 2026-01-03T...), new Date() parses it correctly.
      let dateA = new Date(timeA);
      let dateB = new Date(timeB);

      // Fallback: If invalid date (NaN), treat as Oldest (Epoch 0)
      if (isNaN(dateA.getTime())) dateA = new Date(0);
      if (isNaN(dateB.getTime())) dateB = new Date(0);

      return sortOrder === 'desc' ? dateB - dateA : dateA - dateB;
    });

    return joinedList;
  }

  function createPlaceholderCard() {
    const card = document.createElement('div');
    card.className = 'transaction-card placeholder';
    // Match the standard card inner structure height roughly, or use visibility:hidden clone
    // For simplicity, we just set a min-height or put text
    card.innerHTML = `<div style="padding: 20px; text-align:center;">- No Data -</div>`;
    // We set style to visible so spacing exists, but content is just a dash
    card.style.visibility = 'visible'; 
    return card;
  }

  function handleSortToggle() {
    sortOrder = sortOrder === 'desc' ? 'asc' : 'desc';
    sortButton.innerHTML = `Sort: ${sortOrder === 'desc' ? 'Newest' : 'Oldest'} <span id="sort-icon">${sortOrder === 'desc' ? '↓' : '↑'}</span>`;
    applyFiltersAndRender();
  }

  // --- Filtering Logics ---
  // --- Pair-Aware Filtering Logic ---
  function shouldShowEntry(entry, filters, isAndLogic) {
    const activeFilterKeys = Object.keys(filters).filter(k => filters[k]);
    if (activeFilterKeys.length === 0) return true;

    // A pair matches if ANY leg (ISO or JSON) satisfies the filter logic
    
    // Check ISO legs
    const isoResults = (entry.isos || []).map(iso => {
       const mapped = mapIsoForFilter(iso, isAndLogic);
       return getFilterMatches(mapped, filters, activeFilterKeys);
    });

    // Check JSON legs
    const jsonResults = (entry.jsons || []).map(json => {
       const mapped = mapJsonForFilter(json);
       return getFilterMatches(mapped, filters, activeFilterKeys);
    });

    if (isAndLogic) {
        // AND mode: The pair as a whole must satisfy ALL active filter keys.
        // We consider a key satisfied if it matches in ANY ISO or ANY JSON of this pair.
        return activeFilterKeys.every(key => {
            const matchInIso = isoResults.some(res => res[key]);
            const matchInJson = jsonResults.some(res => res[key]);
            return matchInIso || matchInJson;
        });
    } else {
        // OR mode: The pair matches if ANY leg matches ANY filter
        const anyIsoMatch = isoResults.some(res => activeFilterKeys.some(key => res[key]));
        const anyJsonMatch = jsonResults.some(res => activeFilterKeys.some(key => res[key]));
        return anyIsoMatch || anyJsonMatch;
    }
  }

  function getFilterMatches(dataObject, filters, activeKeys) {
    const matches = {};
    activeKeys.forEach(key => {
        if (dataObject[key] === undefined) {
            matches[key] = false;
        } else {
            const filterValue = filters[key];
            const strValue = String(dataObject[key]);
            
            // Special Logic for Status
            if (key === 'status' && filterValue.startsWith('!')) {
                const excluded = filterValue.substring(1);
                matches[key] = excluded ? !strValue.toLowerCase().includes(excluded.toLowerCase()) : true;
            } else if (key === 'status' && filterValue.includes(',')) {
                const multi = filterValue.split(',').map(v => v.trim().toLowerCase()).filter(v => v);
                matches[key] = multi.length > 0 ? multi.includes(strValue.toLowerCase()) : true;
            } else {
                // Standard Contains
                matches[key] = strValue.toLowerCase().includes(filterValue.toLowerCase());
            }
        }
    });
    return matches;
  }

  function mapIsoForFilter(t, isAndLogic) {
    const cardNum = t.request?.dataElements?.['002'] || '';
    const bankInfo = cardNum ? window.getBankInfoByBin(cardNum) : null;
    return {
      trace: t.traceNumber || '',
      pan: cardNum,
      serial: isAndLogic ? '' : undefined, // Ignore SN in OR mode for ISO
      status: t.responseCode || (t.response ? '' : 'N/A'),
      pcode: t.pcode || '',
      refnum: t.refNum || '',
      terminalId: t.request?.dataElements?.['041'] || '',
      bankName: bankInfo?.name || ''
    };
  }

  function mapJsonForFilter(t) {
    let cardNum = t.request?.data?.cardNumber || '';
    // Fallback: extract from track2Data if cardNumber is empty
    if (!cardNum && t.request?.data?.track2Data) {
      const parts = t.request.data.track2Data.split(/[=D]/);
      if (parts.length > 0) cardNum = parts[0].trim();
    }
    const bankInfo = cardNum ? window.getBankInfoByBin(cardNum) : null;
    return {
      trace: t.traceNumber || '',
      pan: cardNum,
      serial: t.serialNumber || '',
      status: t.responseStatus || (t.response ? '' : 'N/A'),
      pcode: t.pcode || '',
      refnum: t.refnum || t.request?.data?.referenceNumber || '',
      terminalId: t.terminalId || t.request?.data?.terminalId || '',
      bankName: bankInfo?.name || ''
    };
  }

  // --- Modal Logic ---
  let modalOverlay, modalTitle, modalBody, modalCloseBtn;

  function initializeModal() {
    const modalHtml = `
      <div class="modal-overlay" id="raw-data-modal">
        <div class="modal-content">
          <div class="modal-header">
            <h2 id="modal-title">Raw Data</h2>
            <button class="modal-close-btn" id="modal-close">&times;</button>
          </div>
          <div class="modal-body" id="modal-body">
            <!-- Content goes here -->
          </div>
        </div>
      </div>
    `;
    document.body.insertAdjacentHTML('beforeend', modalHtml);

    modalOverlay = document.getElementById('raw-data-modal');
    modalTitle = document.getElementById('modal-title');
    modalBody = document.getElementById('modal-body');
    modalCloseBtn = document.getElementById('modal-close');

    modalCloseBtn.addEventListener('click', closeModal);
    modalOverlay.addEventListener('click', (e) => {
      if (e.target === modalOverlay) closeModal();
    });

    // Close on Escape key
    document.addEventListener('keydown', (e) => {
      if (e.key === 'Escape' && modalOverlay.classList.contains('active')) {
        closeModal();
      }
    });
  }

  function openModal(title, content) {
    if (!modalOverlay) initializeModal();
    modalTitle.textContent = title;
    modalBody.innerHTML = content;
    modalOverlay.classList.add('active');
  }

  function closeModal() {
    if (modalOverlay) {
      modalOverlay.classList.remove('active');
      modalBody.innerHTML = ''; // Clear content
    }
  }

  function formatRupiah(amount) {
    if (!amount || amount === 'N/A') return 'Rp 0';
    const num = parseFloat(String(amount).replace(/[^0-9.-]+/g,""));
    return new Intl.NumberFormat('id-ID', { style: 'currency', currency: 'IDR', minimumFractionDigits: 0 }).format(num);
  }

  // Helper: Mask PAN for display (show first 6 + last 4)
  function maskPan(pan) {
    if (!pan || pan === 'N/A' || pan.length < 10) return pan || 'N/A';
    const first6 = pan.slice(0, 6);
    const last4 = pan.slice(-4);
    return `${first6}****${last4}`;
  }

  // Helper: Format Date for Display (DD MMM YYYY HH:mm:ss.SSS)
  function formatDisplayDate(isoString) {
      if (!isoString || isoString === 'N/A') return 'N/A';
      try {
          const d = new Date(isoString);
          if (isNaN(d.getTime())) return isoString; // Fallback if not valid date

          const day = String(d.getDate()).padStart(2, '0');
          const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
          const month = months[d.getMonth()];
          const year = d.getFullYear();
          const h = String(d.getHours()).padStart(2, '0');
          const m = String(d.getMinutes()).padStart(2, '0');
          const s = String(d.getSeconds()).padStart(2, '0');
          const ms = String(d.getMilliseconds()).padStart(3, '0');

          return `${day} ${month} ${year} ${h}:${m}:${s}.${ms}`;
      } catch (e) {
          return isoString;
      }
  }

  // --- Card Creation Functions ---
  function createIsoCard(t) {
    const card = document.createElement('div');
    card.className = 'transaction-card';
    if (t.responseCode === '00') card.classList.add('status-ok');
    else if (t.response) card.classList.add('status-fail');
    else card.classList.add('status-no-response');

    const time = t.request?.timestamp || t.response?.timestamp || 'N/A';
    const displayTime = formatDisplayDate(time);

    card.innerHTML = `
      <div class="card-header">
        <strong>Refnum: ${t.refNum || 'N/A'}</strong>
        <span class="pan-display">🪪 ${maskPan(t.request?.dataElements?.['002'])}</span>
        <span class="timestamp">${displayTime}</span>
      </div>
      <div class="card-body-structured">
        ${createKvPair('Status:', t.responseCode || (t.response ? '-' : 'No Response'), true)}
        ${createKvPair('Amount:', formatRupiah(t.amount))}
        ${createKvPair('PCode:', t.pcode || 'N/A')}
      </div>
      <details class="raw-data-collapsible">
        <summary>Show Raw Data</summary>
        <div class="raw-data-content">
          <h4>ISO Request</h4>
          <pre>${formatRawData(t.request, 'ISO8583')}</pre>
          <h4>ISO Response</h4>
          <pre>${formatRawData(t.response, 'ISO8583')}</pre>
        </div>
      </details>
    `;

    return card;
  }

  function createJsonCard(t) {
    const card = document.createElement('div');
    card.className = 'transaction-card';
    const isSuccess = t.responseStatus === '00';

    if (isSuccess) card.classList.add('status-ok');
    else if (t.response) card.classList.add('status-fail');
    else card.classList.add('status-no-response');

    const time = t.timestamp || 'N/A';

    const detailedType = window.getDetailedTransactionType(t.pcode, t.request?.data?.privateData);
    const mgmtType = window.getNetworkMgmtType(t.request?.data?.mti, t.request?.data?.networkMgmtCode);
    
    // Bank Name Logic
    let bankDisplay = '';
    const pcode = t.pcode || '';
    
    // Logic: 
    // 1. Cek Saldo (301000) -> Use BIN (Card Number)
    // 2. Tarik Tunai (011000) / Transfer (401000) -> Use Dest/Issuer Bank Code
    
    if (pcode.startsWith('301')) { 
        // Inquiry / Cek Saldo -> Use BIN
        let cardNum = t.request?.data?.cardNumber;
        if (!cardNum && t.request?.data?.track2Data) {
            const parts = t.request?.data?.track2Data?.split(/[=D]/) || [];
            if (parts.length > 0) cardNum = parts[0].trim();
        }
        const bankInfo = window.getBankInfoByBin(cardNum);
        if (bankInfo) bankDisplay = `(${bankInfo.name})`;

    } else if (pcode.startsWith('011') || pcode.startsWith('401')) {
        // Withdrawal or Transfer -> Show Sender (Issuer) & Receiver (Dest)
        const destCode = t.request?.data?.destBankCode;
        const issuerCode = t.request?.data?.issuerBankCode;
        
        let senderBank = 'Unknown';
        let receiverBank = 'Unknown';

        // 1. Determine Sender (Issuer)
        if (issuerCode) {
            senderBank = window.getBankNameByCode(issuerCode);
        } else {
             // Fallback to BIN
             let cardNum = t.request?.data?.cardNumber;
             if (!cardNum && t.request?.data?.track2Data) {
                const parts = t.request?.data?.track2Data?.split(/[=D]/) || [];
                if (parts.length > 0) cardNum = parts[0].trim();
             }
             const bankInfo = window.getBankInfoByBin(cardNum);
             if (bankInfo) senderBank = bankInfo.name;
        }

        // 2. Determine Receiver (Dest)
        if (destCode) {
            receiverBank = window.getBankNameByCode(destCode);
        }

        // Format: (Sender -> Receiver)
        // If typically same (On Us), might look like (BRI -> BRI) dealing with user request literally
        bankDisplay = `(${senderBank} <span style="color:#fbbf24; font-weight:bold;">&rarr;</span> ${receiverBank})`;

    } else {
         // Default Fallback to BIN
         let cardNum = t.request?.data?.cardNumber;
         if (!cardNum && t.request?.data?.track2Data) {
            const parts = t.request?.data?.track2Data?.split(/[=D]/) || [];
            if (parts.length > 0) cardNum = parts[0].trim();
         }
         const bankInfo = window.getBankInfoByBin(cardNum);
         if (bankInfo) bankDisplay = `(${bankInfo.name})`;
    }

    const displayType = mgmtType || detailedType;
    const finalDisplayType = displayType ? `${displayType} <span style="font-weight:normal; color:#cbd5e1; font-size:0.9em;">${bankDisplay}</span>` : '';
    
    // Add Terminal ID
    const terminalId = t.request?.data?.terminalId || 'N/A';

    const bodyHtml = detailedType ? `
      <div class="card-body-structured">
        ${createKvPair('Status:', t.responseStatus || (t.response ? '-' : 'N/A'), true)}
        <div class="kv-pair"><span style="font-weight:bold; color:#fff;">${finalDisplayType}</span></div>
      </div>
      <div class="card-body-structured">
         ${createKvPair('Amount:', formatRupiah(t.amount || t.request?.data?.amount))}
         ${createKvPair('Trace:', t.traceNumber || 'N/A')}
         ${createKvPair('TID:', terminalId)}
      </div>
    ` : `
      <div class="card-body-structured">
        ${createKvPair('Status:', t.responseStatus || (t.response ? '-' : 'N/A'), true)}
        ${createKvPair('Amount:', formatRupiah(t.amount || t.request?.data?.amount))}
        ${createKvPair('Trace:', t.traceNumber || 'N/A')}
        ${createKvPair('TID:', terminalId)}
      </div>
    `;

    // Extract PAN for display
    let displayPan = t.request?.data?.cardNumber || '';
    if (!displayPan && t.request?.data?.track2Data) {
      const parts = t.request.data.track2Data.split(/[=D]/);
      if (parts.length > 0) displayPan = parts[0].trim();
    }

    card.innerHTML = `
      <div class="card-header">
        <strong>Refnum: ${t.refnum || t.request?.data?.referenceNumber || 'N/A'}</strong>
        <strong>SN: ${t.serialNumber || t.request?.data?.serialNumber || 'N/A'}</strong>
        <span class="pan-display">🪪 ${maskPan(displayPan)}</span>
        <span class="timestamp">${time}</span>
      </div>
      ${bodyHtml}
      <details class="raw-data-collapsible">
        <summary>Show Raw Data</summary>
        <div class="raw-data-content">
          <h4>JSON Request</h4>
          <pre>${formatRawData(t.request, 'JSON')}</pre>
          <h4>JSON Response</h4>
          <pre>${formatRawData(t.response, 'JSON')}</pre>
        </div>
      </details>
    `;

    return card;
  }

  // --- Helper Functions ---
  function createKvPair(label, value, isValueStrong = false) {
    const valueEl = isValueStrong ? `<strong class="status-text">${value}</strong>` : `<span>${value}</span>`;
    return `<div class="kv-pair"><span>${label}</span>${valueEl}</div>`;
  }

  function formatRawData(entry, source) {
    if (!entry) return 'N/A';
    try {
      if (source === 'JSON') {
        const dataToFormat = entry.data || entry;
        return JSON.stringify(dataToFormat, null, 2).replace(/</g, '&lt;').replace(/>/g, '&gt;');
      } else if (source === 'ISO8583') {
        const rawMti = entry.mti;
        const mtiDisplay = (rawMti && rawMti !== '0NaN') ? rawMti : 'N/A';
        let output = `MTI: ${mtiDisplay}
`;
        if (entry.dataElements && typeof entry.dataElements === 'object') {
          for (const [key, value] of Object.entries(entry.dataElements)) {
            output += `${key.padEnd(3)}  [${value}]
`;
          }
        }
        return output.replace(/</g, '&lt;').replace(/>/g, '&gt;');
      }
    } catch (e) {
      console.error('[formatRawData] Error:', e);
      return "Error formatting data.";
    }
    return 'Unknown format';
  }

  function debounce(func, delay) {
    let timeout;
    return function (...args) {
      clearTimeout(timeout);
      timeout = setTimeout(() => func.apply(this, args), delay);
    };
  }

  function handleExport() {
    if (filteredIso.length === 0) {
      alert('No ISO transactions are currently displayed to copy.');
      return;
    }

    let fullExportContent = '';
    let exportedCount = 0;
    const wantedKeys = ['002', '003', '004', '011', '012', '022', '037', '039'];

    filteredIso.forEach(t => {
      if (!t.response || !t.response.dataElements) {
        return;
      }

      const timestamp = t.response.timestamp || 'N/A';
      const responseDataElements = t.response.dataElements;
      let transactionString = `Tgl & Jam : ${timestamp}\n`;
      let hasContent = false;

      wantedKeys.forEach(key => {
        if (responseDataElements.hasOwnProperty(key)) {
          transactionString += `DE<${key}> : ${responseDataElements[key]}\n`;
          hasContent = true;
        }
      });

      if (hasContent) {
        fullExportContent += transactionString + '\n';
        exportedCount++;
      }
    });

    if (exportedCount === 0) {
      alert('None of the displayed transactions have the required response data to copy.');
      return;
    }

    navigator.clipboard.writeText(fullExportContent).then(() => {
      const originalText = exportButton.textContent;
      const originalColor = exportButton.style.backgroundColor;
      exportButton.textContent = 'Copied!';
      exportButton.style.backgroundColor = 'var(--status-ok)';

      setTimeout(() => {
        exportButton.textContent = originalText;
        exportButton.style.backgroundColor = originalColor;
      }, 2000);
    }).catch(err => {
      console.error('Failed to copy to clipboard:', err);
      alert('Failed to copy data. Please check console for errors.');
    });
  }

  // --- Copy Handlers ---

  function copyToClipboard(text, btnId) {
    navigator.clipboard.writeText(text).then(() => {
      const btn = document.getElementById(btnId);
      const originalText = btn.innerHTML;
      btn.textContent = 'Copied!';
      
      // Update style momentarily
      if (btnId === 'copy-simple-btn') {
          btn.style.background = 'linear-gradient(135deg, #059669 0%, #047857 100%)';
      } else {
          btn.style.background = 'linear-gradient(135deg, #2563eb 0%, #1d4ed8 100%)';
      }
      
      setTimeout(() => {
        btn.innerHTML = originalText;
        btn.style.background = '';
      }, 2000);
    }).catch(err => {
      console.error('Failed to copy to clipboard:', err);
      alert('Failed to copy data. Please check console for errors.');
    });
  }

  // 1. Copy Detail (Keep existing logic - Segmented Summary + All Details)
  function handleCopyDetail() {
    if (filteredIso.length === 0) {
      alert('No ISO transactions are currently displayed to copy.');
      return;
    }

    // RC Code Mapping
    const RC_MAP = {
      '00': 'Berhasil',
      '51': 'Saldo Tidak Cukup',
      '55': 'PIN Salah',
      '61': 'Limit Terlampaui',
      '68': 'Response Timeout',
      '91': 'Issuer Timeout',
      '96': 'System Error'
    };

    // Grouping Logc (Keep Existing)
    const rcGroups = {};
    filteredIso.forEach(t => {
      const rc = t.responseCode || (t.response?.dataElements?.['039']) || 'N/A';
      if (!rcGroups[rc]) {
        rcGroups[rc] = { count: 0, inquiries: new Set(), withdrawals: new Set(), transfers: new Set(), terminals: new Set() };
      }
      const group = rcGroups[rc];
      group.count++;
      
      const terminalId = t.request?.dataElements?.['041'];
      if (terminalId) group.terminals.add(terminalId);

      const pcode = t.pcode || t.request?.dataElements?.['003'];
      const cardNum = t.request?.dataElements?.['002'];
      let bankName = 'Unknown Bank';
      if (cardNum) {
        const bankInfo = window.getBankInfoByBin(cardNum);
        if (bankInfo?.name) bankName = bankInfo.name;
      }

      if (pcode) {
        if (pcode.startsWith('40')) {
          let destCode = t.bank_penerima || t.request?.dataElements?.['127'];
          let destDisplay = 'Unknown';
          if (destCode) {
             const dbName = window.getBankNameByCode(destCode);
             destDisplay = dbName ? dbName : `(${destCode})`;
          }
          group.transfers.add(`${bankName} -> ${destDisplay}`);
        } else if (pcode.startsWith('01')) {
          group.withdrawals.add(bankName);
        } else {
          group.inquiries.add(bankName);
        }
      } else {
        group.inquiries.add(bankName);
      }
    });

    const timestamps = filteredIso.map(t => t.request?.timestamp || t.response?.timestamp).filter(ts => ts && ts !== 'N/A');
    const minTime = timestamps.length > 0 ? new Date(Math.min(...timestamps.map(ts => new Date(ts)))) : null;
    const maxTime = timestamps.length > 0 ? new Date(Math.max(...timestamps.map(ts => new Date(ts)))) : null;
    
    // Time Format Helper
    const formatTime = (date) => {
      if (!date) return 'N/A';
      const d = String(date.getDate()).padStart(2, '0');
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      const m = months[date.getMonth()];
      const y = date.getFullYear();
      const h = String(date.getHours()).padStart(2, '0');
      const min = String(date.getMinutes()).padStart(2, '0');
      return `${d} ${m} ${y}, ${h}:${min}`;
    };

    let report = 'Laporan Transaksi ISO\n';
    report += `Periode: ${formatTime(minTime)} - ${formatTime(maxTime)}\n\n`;

    Object.keys(rcGroups).sort().forEach(rc => {
      const group = rcGroups[rc];
      const desc = RC_MAP[rc];
      const rcLabel = desc ? `RC ${rc} (${desc})` : `RC ${rc}`;
      report += `${rcLabel}\n`;
      
      if (group.inquiries.size > 0) {
        report += `- Cek saldo :\n`;
        Array.from(group.inquiries).forEach((bank, idx) => report += `   ${idx + 1}. ${bank}\n`);
        report += `\n`;
      }
      if (group.withdrawals.size > 0) {
        report += `- Tarik Tunai :\n`;
        Array.from(group.withdrawals).forEach((bank, idx) => report += `   ${idx + 1}. ${bank}\n`);
        report += `\n`;
      }
      if (group.transfers.size > 0) {
        report += `- Transfer\n`;
         Array.from(group.transfers).forEach((flow, idx) => report += `   ${idx + 1}. ${flow}\n`);
        report += `\n`;
      }
      if (group.terminals.size > 0) {
        report += `Terminal: ${group.terminals.size}\n`;
      }
      report += '\n';
    });

    report += '----------------------------------------\n';
    report += 'DETAIL TRANSAKSI:\n\n';

    const wantedKeys = ['002', '003', '004', '011', '012', '022', '037', '039'];
    const shouldMask = document.getElementById('mask-pan-toggle')?.checked ?? true;
    
    filteredIso.forEach((t) => {
      const rawTimestamp = t.request?.timestamp || t.response?.timestamp;
      const formattedTimestamp = rawTimestamp ? formatTime(new Date(rawTimestamp)) : 'N/A';
      report += `Tgl & Jam : ${formattedTimestamp}\n`;
      const reqElements = t.request?.dataElements || {};
      const respElements = t.response?.dataElements || {};
      wantedKeys.forEach(key => {
        const value = reqElements[key] || respElements[key];
        if (value) {
          const displayValue = (key === '002' && shouldMask) ? maskPan(value) : value;
          report += `DE<${key}> : ${displayValue}\n`;
        }
      });
      report += '\n';
    });

    copyToClipboard(report, 'copy-detail-btn');
  }

  // 2. Copy Simple (Sampling Logic: 1 Sample per RC)
  function handleCopySimple() {
    if (filteredIso.length === 0) {
      alert('No ISO transactions are currently displayed to copy.');
      return;
    }

    // Time Format Helper (Duplicated for independence/clarity)
    const formatTime = (date) => {
      if (!date) return 'N/A';
      const d = String(date.getDate()).padStart(2, '0');
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      const m = months[date.getMonth()];
      const y = date.getFullYear();
      const h = String(date.getHours()).padStart(2, '0');
      const min = String(date.getMinutes()).padStart(2, '0');
      return `${d} ${m} ${y}, ${h}:${min}`;
    };

    const timestamps = filteredIso.map(t => t.request?.timestamp || t.response?.timestamp).filter(ts => ts && ts !== 'N/A');
    const minTime = timestamps.length > 0 ? new Date(Math.min(...timestamps.map(ts => new Date(ts)))) : null;
    const maxTime = timestamps.length > 0 ? new Date(Math.max(...timestamps.map(ts => new Date(ts)))) : null;

    // Identify Unique RCs
    const uniqueRCs = new Set();
    const samples = {}; // RC -> Transaction Object

    filteredIso.forEach(t => {
      const rc = t.responseCode || (t.response?.dataElements?.['039']) || 'N/A';
      if (!uniqueRCs.has(rc)) {
        uniqueRCs.add(rc);
        samples[rc] = t; // Store FIRST occurrence as sample
      }
    });

    const sortedRCs = Array.from(uniqueRCs).filter(rc => rc !== 'N/A').sort();
    
    // Generate Header
    let report = `Laporan Transaksi Kendala RC ${sortedRCs.join(',')}\n`;
    report += `Periode: ${formatTime(minTime)} - ${formatTime(maxTime)}\n\n`;
    report += `Berikut Data :\n\n`;

    // Generate Samples
    const wantedKeys = ['002', '003', '004', '011', '012', '022', '037', '039'];
    const shouldMask = document.getElementById('mask-pan-toggle')?.checked ?? true;
    
    sortedRCs.forEach(rc => {
        const t = samples[rc];
        const rawTimestamp = t.request?.timestamp || t.response?.timestamp;
        const formattedTimestamp = rawTimestamp ? formatTime(new Date(rawTimestamp)) : 'N/A';
        
        report += `Tgl & Jam : ${formattedTimestamp}\n`;
        
        const reqElements = t.request?.dataElements || {};
        const respElements = t.response?.dataElements || {};
        
        wantedKeys.forEach(key => {
            const value = reqElements[key] || respElements[key];
            if (value) {
              const displayValue = (key === '002' && shouldMask) ? maskPan(value) : value;
              report += `DE<${key}> : ${displayValue}\n`;
            }
        });
        
        report += '\n'; // Spacer between samples
    });

    copyToClipboard(report, 'copy-simple-btn');
  }

  // Copy ISO Handlers
  const copySimpleBtn = document.getElementById('copy-simple-btn');
  if (copySimpleBtn) {
    copySimpleBtn.addEventListener('click', handleCopySimple);
  }

  const copyDetailBtn = document.getElementById('copy-detail-btn');
  if (copyDetailBtn) {
    copyDetailBtn.addEventListener('click', handleCopyDetail);
  }

  // 3. Report Simple (JSON Source)
  function handleReportSimple() {
    const shouldMask = document.getElementById('mask-pan-toggle')?.checked ?? true;
    if (filteredJson.length === 0) {
      alert('No JSON transactions are currently displayed.');
      return;
    }

    // Format DateTime with day name (Kamis, 09 Jan 2026, 11:04:15)
    const formatDT = (ts) => {
      if (!ts) return 'N/A';
      const d = new Date(ts);
      if (isNaN(d.getTime())) return ts;
      const days = ['Minggu', 'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu'];
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      const day = days[d.getDay()];
      const dd = String(d.getDate()).padStart(2, '0');
      const mm = months[d.getMonth()];
      const yyyy = d.getFullYear();
      const hh = String(d.getHours()).padStart(2, '0');
      const min = String(d.getMinutes()).padStart(2, '0');
      const ss = String(d.getSeconds()).padStart(2, '0');
      return `${day}, ${dd} ${mm} ${yyyy}, ${hh}:${min}:${ss}`;
    };

    let report = '';
    filteredJson.forEach(t => {
      const sn = t.serialNumber || 'N/A';
      const tid = t.terminalId || t.request?.data?.terminalId || 'N/A';
      const pcode = t.pcode || '';
      const type = window.getDetailedTransactionType(pcode, t.request?.data?.privateData) || 'N/A';

      let pan = t.request?.data?.cardNumber || '';
      if (!pan && t.request?.data?.track2Data) {
        const parts = t.request.data.track2Data.split(/[=D]/);
        if (parts.length > 0) pan = parts[0].trim();
      }
      const displayPan = shouldMask ? maskPan(pan) : (pan || 'N/A');
      const dt = formatDT(t.timestamp);

      report += `SN: ${sn}\nTID: ${tid}\nType: ${type}\n`;

      // Amount only for non-balance inquiry (301xxx = Cek Saldo)
      if (!pcode.startsWith('301')) {
        const amount = formatRupiah(t.amount || t.request?.data?.amount);
        report += `Amount: ${amount}\n`;
      }

      report += `PAN: ${displayPan}\nDateTime: ${dt}\n\n`;
    });

    copyToClipboard(report, 'report-simple-btn');
  }

  const reportSimpleBtn = document.getElementById('report-simple-btn');
  if (reportSimpleBtn) {
    reportSimpleBtn.addEventListener('click', handleReportSimple);
  }
  
  const clearDbButton = document.getElementById('clear-db-button');
  if (clearDbButton) {
    clearDbButton.addEventListener('click', async () => {
      if (confirm('WARNING: Ini akan menghapus SEMUA data di Server database. Lanjutkan?')) {
        try {
          const res = await fetch('/api/reset', { method: 'POST' });
          const json = await res.json();
          if (json.success) {
            alert('Database berhasil dikosongkan.');
            window.location.reload();
          } else {
            alert('Gagal menghapus database: ' + json.error);
          }
        } catch (e) {
          alert('Error: ' + e.message);
        }
      }
    });
  }

  // --- Event Listeners ---
  const debouncedApplyFilters = debounce(applyFiltersAndRender, 300);
  filterInputs.forEach(input => input.addEventListener('input', debouncedApplyFilters));
  logicToggle.addEventListener('change', applyFiltersAndRender);
  sortButton.addEventListener('click', handleSortToggle);

  // Cleanup Duplicates Handler
  const cleanupButton = document.getElementById('cleanup-duplicates-btn');
  cleanupButton.addEventListener('click', async () => {
    if (!confirm('⚠️ This will delete all duplicate records (keeping oldest). Continue?')) {
      return;
    }
    
    cleanupButton.disabled = true;
    cleanupButton.textContent = '🔄 Cleaning...';
    
    try {
      const response = await fetch('/api/cleanup-duplicates', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' }
      });
      
      const result = await response.json();
      
      if (result.success) {
        alert(`✅ Cleanup Complete!\n\nISO: ${result.isoDeleted} duplicates deleted\nJSON: ${result.jsonDeleted} duplicates deleted\nTotal: ${result.isoDeleted + result.jsonDeleted} records removed`);
        
        // Reload data
        await loadInitialData();
      } else {
        alert(`❌ Cleanup failed: ${result.error}`);
      }
    } catch (error) {
      alert(`❌ Error: ${error.message}`);
    } finally {
      cleanupButton.disabled = false;
      cleanupButton.textContent = '🧹 Cleanup Duplicates';
    }
  });

  // --- Realtime Updates (SSE) ---
  function setupRealtimeUpdates() {
    console.log('[Dashboard] Connecting to Realtime Event Stream...');
    const evtSource = new EventSource('/api/events');

    evtSource.onmessage = (e) => {
        // Heartbeat or random message
        // console.log('[SSE] Msg:', e.data);
    };

    let renderTimeout = null;
    const throttleRender = () => {
        if (renderTimeout) return;
        renderTimeout = setTimeout(() => {
            applyFiltersAndRender();
            renderTimeout = null;
        }, 1000); // Max once per second
    };

    evtSource.addEventListener('new_transactions', (e) => {
        try {
            const batch = JSON.parse(e.data); // Array of { type: 'iso'|'json', data: tx, timestamp: ts }
            if (!Array.isArray(batch)) return;

            batch.forEach(payload => {
                if (payload.type === 'iso') {
                    allIsoTransactions.unshift(payload.data);
                } else if (payload.type === 'json') {
                    allJsonTransactions.unshift(payload.data);
                }
            });

            // 2. Show Toast Notification (Summary)
            showToast(`Received ${batch.length} new transactions!`);

            // 3. Update Debug Stats
            updateDebugStats();

            // 4. Trigger Re-Render (Throttled)
            throttleRender();

        } catch (err) {
            console.error('[Realtime] Error processing batch event:', err);
        }
    });

    // Keep legacy support for single events if any
    evtSource.addEventListener('new_transaction', (e) => {
        try {
            const payload = JSON.parse(e.data);
            if (payload.type === 'iso') {
                allIsoTransactions.unshift(payload.data);
            } else if (payload.type === 'json') {
                allJsonTransactions.unshift(payload.data);
            }
            showToast(`New ${payload.type.toUpperCase()} Received!`);
            updateDebugStats();
            throttleRender();
        } catch (err) {
            console.error('[Realtime] Error processing single event:', err);
        }
    });

    evtSource.onerror = (err) => {
        console.warn('[Realtime] Connection lost, retrying...', err);
        evtSource.close();
        // EventSource auto-retries, but we might want to wait a bit manually if it spams.
        // For now let standard browser retry mechanism work.
    };
  }

  function showToast(message) {
      const toast = document.createElement('div');
      toast.className = 'toast-notification';
      toast.style.cssText = `
          position: fixed; bottom: 20px; right: 20px;
          background: #4ade80; color: #000; padding: 12px 24px;
          border-radius: 8px; font-weight: bold; box-shadow: 0 4px 12px rgba(0,0,0,0.3);
          z-index: 9999; animation: slideIn 0.3s ease-out;
      `;
      toast.textContent = message;
      document.body.appendChild(toast);
      setTimeout(() => {
          toast.style.opacity = '0';
          setTimeout(() => toast.remove(), 300);
      }, 3000);
  }

  function updateDebugStats() {
       const bar = document.getElementById('debug-stats-bar');
       if(bar) {
           bar.innerHTML = `
           <strong>SYSTEM HEALTH CHECK:</strong> &nbsp;
           <span style="color:${allIsoTransactions.length > 0 ? '#4ade80' : '#f87171'}">ISO Logs: ${allIsoTransactions.length}</span> &nbsp;|&nbsp;
           <span style="color:${allJsonTransactions.length > 0 ? '#4ade80' : '#f87171'}">JSON Logs: ${allJsonTransactions.length}</span> &nbsp;|&nbsp;
           <span>Total: ${allIsoTransactions.length + allJsonTransactions.length}</span>
           `;
       }
  }

  // --- Initial Load ---
  initializeDashboard();
  setupRealtimeUpdates(); // Start Listening
});
