// shared/business_logic.js
// This file contains shared business logic and mappings for use across different pages.

// Make these available globally within the extension's scope
window.PCODE_MAP = {
    '301000': 'Inquiry Balance',
    '401000': 'Transfer',
    '011000': 'Tarik Tunai'
};

window.getNetworkType = function (privateData) {
    if (!privateData) return 'Unknown';
    if (privateData.startsWith('0210')) return 'WITHDRAWAL_OFF_US';
    if (privateData.startsWith('0110')) return 'WITHDRAWAL_ON_US';
    if (privateData.startsWith('02')) return 'OFF_US';
    if (privateData.startsWith('01')) return 'ON_US';
    return 'OFF_US'; // Default
}

window.getNetworkMgmtType = function (mti, networkMgmtCode) {
    if (mti === '0800') {
        if (networkMgmtCode === '301') {
            return 'Echo Test';
        }
        return 'Sign On';
    }
    return null;
}

window.getDetailedTransactionType = function (pcode, privateData) {
    // Priority check: Identify withdrawal by privateData first, as it can be definitive.
    if (privateData && (privateData.startsWith('0110') || privateData.startsWith('0210'))) {
        const networkType = window.getNetworkType(privateData);
        return networkType.includes('ON_US') ? 'Tarik Tunai Sesama' : 'Tarik Tunai Bank Lain';
    }

    // Fallback to PCode-based mapping for other transaction types.
    const transactionType = window.PCODE_MAP[pcode];
    if (!transactionType) return null; // Not a financial transaction we are tracking.

    const networkType = window.getNetworkType(privateData);

    switch (transactionType) {
        case 'Transfer':
            return networkType.includes('ON_US') ? 'Transfer Sesama' : 'Transfer Bank Lain';
        case 'Inquiry Balance':
            return networkType.includes('ON_US') ? 'Check Saldo Bank Nobu' : 'Check Saldo Bank Lain';
        case 'Tarik Tunai': // This remains as a fallback for PCode-based identification.
            return networkType.includes('ON_US') ? 'Tarik Tunai Sesama' : 'Tarik Tunai Bank Lain';
        default:
            return transactionType; // Fallback to the basic name
    }
}

// --- BIN Data Handling ---
window.BIN_DATA = {};

(async function loadBinData() {
    try {
        const response = await fetch('../data/bin_list.json');
        if (!response.ok) {
            console.error('Failed to load BIN data', response.statusText);
            return;
        }
        window.BIN_DATA = await response.json();
        console.log('BIN data loaded successfully.');
    } catch (e) {
        console.error('Error fetching or parsing BIN data:', e);
    }
})();

window.getBankInfoByBin = function (bin) {
    if (!bin || typeof bin !== 'string' || bin.length < 6) {
        return null;
    }
    const binPrefix = bin.substring(0, 6);
    return window.BIN_DATA[binPrefix] || null;
}

window.filterValidTransactions = function (transactions) {
    if (!transactions || !Array.isArray(transactions)) {
        return [];
    }
    return transactions.filter(t => {
        const pcode = t.pcode;
        const isTrackedPcode = window.PCODE_MAP.hasOwnProperty(pcode);

        const responseStatus = t.responseStatus;
        const isFailure = responseStatus && responseStatus !== '00';

        return pcode || isFailure;
    });
}

// --- Centralized Data Rules for ISO 8583 ---
window.TransactionRules = {
    // Helper to safely access ISO fields whether assuming Object or Map structure
    _get: function (obj, field) {
        if (!obj) return undefined;
        if (obj.dataElements) {
            // If it's a Map
            if (typeof obj.dataElements.get === 'function') {
                return obj.dataElements.get(field);
            }
            // If it's an Object
            return obj.dataElements[field];
        }
        return undefined;
    },

    getStatus: function (tx) {
        const resp = tx.response;
        if (!resp) return 'TIMEOUT'; // No response at all

        const rc = this._get(resp, '039');
        if (!rc) return 'EMPTY_RC'; // Response exists but no RC (rare)

        return rc === '00' ? 'SUCCESS' : 'FAILED';
    },

    getResponseCode: function (tx) {
        if (!tx.response) return 'TIMEOUT';
        const rc = this._get(tx.response, '039');
        return rc || 'EMPTY_RC';
    },

    getBank: function (tx) {
        const cardNum = this._get(tx.request, '002');
        if (!cardNum) return 'Unknown Bank';

        const bankInfo = window.getBankInfoByBin(cardNum);
        return bankInfo ? bankInfo.name : 'Unknown Bank';
    },

    getTerminalId: function (tx) {
        return this._get(tx.request, '041') || 'Unknown TID';
    },

    getType: function (tx) {
        const pcode = this._get(tx.request, '003');
        const privateData = this._get(tx.request, '048'); // 048 is commonly Private Data/Additional Data
        return window.getDetailedTransactionType(pcode, privateData) || (pcode ? `Code ${pcode}` : 'Unknown Type');
    },

    getAmount: function (tx) {
        const amtStr = this._get(tx.request, '004'); // e.g., "000000100000"
        if (!amtStr) return 0;
        return parseInt(amtStr, 10) || 0;
    },

    getRefNum: function (tx) {
        return this._get(tx.request, '037') || 'N/A';
    },

    getTimestamp: function (tx) {
        // Assuming timestamp is at the root of the transaction object or request
        return tx.request?.timestamp || null;
    }
};

// --- Bank Code Mapping ---
window.BANK_CODE_MAP = {
    '002': 'BRI',
    '008': 'MANDIRI',
    '009': 'BNI',
    '004': 'BTN', // Added common ones, can be expanded
    '014': 'BCA',
    '011': 'DANAMON',
    '013': 'PERMATA',
    '016': 'MAYBANK',
    '019': 'PANIN',
    '022': 'CIMB NIAGA',
    '050': 'STANDARD CHARTERED',
    '087': 'HSBC',
    '110': 'BJB',
    '111': 'DKI',
    '200': 'BTN',
};

// Populate the map further when BIN data is loaded
window.populateBankCodeMap = function(binData) {
    if (!binData) return;
    for (const bin in binData) {
        const entry = binData[bin];
        if (entry && entry.code && entry.name) {
             window.BANK_CODE_MAP[entry.code] = entry.name;
        }
    }
    console.log(`[BankCodeMap] Enriched with ${Object.keys(window.BANK_CODE_MAP).length} codes.`);
};

(async function loadBinData() {
    try {
        const response = await fetch('../data/bin_list.json');
        if (!response.ok) {
            console.error('Failed to load BIN data', response.statusText);
            return;
        }
        window.BIN_DATA = await response.json();
        // Trigger population of code map
        window.populateBankCodeMap(window.BIN_DATA);
        console.log('BIN data loaded successfully.');
    } catch (e) {
        console.error('Error fetching or parsing BIN data:', e);
    }
})();

window.getBankNameByCode = function(code) {
    if (!code) return null;
    return window.BANK_CODE_MAP[code] || `Bank ${code}`; // Fallback to "Bank CODE" if unknown
};
