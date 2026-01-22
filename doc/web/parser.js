/**
 * parser.js - Server-Side Logic for Overwatch
 * 
 * Ported from extension/pairing_logic.js
 * Handles raw text chunk parsing and transaction pairing.
 */

const IsoHandler = {
  requests: [],
  responses: [],

  reset: function () {
    this.requests = [];
    this.responses = [];
  },

  processChunk: function (text) {
    const entries = parseIsoEntries(text);
    entries.forEach((entry) => {
      entry.type === "REQ" ? this.requests.push(entry) : this.responses.push(entry);
    });
    return { newEntryCount: entries.length };
  },

  flushPaired: function () {
    const transactions = [];
    const unmatchedRequests = [];

    for (const req of this.requests) {
      let matchIndex = -1;
      const reqTrace = req.dataElements.get("011");

      if (reqTrace) {
        matchIndex = this.responses.findIndex(
          (rsp) => rsp.dataElements.get("011") === reqTrace
        );
      }

      if (matchIndex > -1) {
        transactions.push({ request: req, response: this.responses[matchIndex] });
        this.responses.splice(matchIndex, 1);
      } else {
        unmatchedRequests.push(req);
      }
    }

    this.requests = unmatchedRequests;
    return transactions;
  },

  finalize: function () {
    const transactions = [];
    let unmatchedResponses = [...this.responses];
    for (const req of this.requests) {
      let match = null;
      const reqTrace = req.dataElements.get("011");
      if (reqTrace) {
        const matchIndex = unmatchedResponses.findIndex(
          (rsp) => rsp.dataElements.get("011") === reqTrace
        );
        if (matchIndex > -1) {
          match = unmatchedResponses[matchIndex];
          unmatchedResponses.splice(matchIndex, 1);
        }
      }
      transactions.push({ request: req, response: match });
    }
    unmatchedResponses.forEach((rsp) => transactions.push({ request: null, response: rsp }));
    return transactions;
  },
};

const JsonHandler = {
  entries: [],

  reset: function () {
    this.entries = [];
  },

  processChunk: function (text) {
    const parsedEntries = parseJsonEntries(text);
    this.entries.push(...parsedEntries);
    return { newEntryCount: parsedEntries.length };
  },

  flushPaired: function (isoTransactions) {
    const isoMap = new Map();
    for (const iso of isoTransactions) {
      if (iso.refNum && iso.pcode) {
        const key = `${iso.refNum}-${iso.pcode}`;
        isoMap.set(key, iso);
      }
    }

    const allRequests = this.entries.filter((e) => e.type === "REQ");
    let allResponses = this.entries.filter((e) => e.type === "RSP");
    const pairedTransactions = [];
    const unmatchedRequests = [];

    for (const req of allRequests) {
      let respMatchIndex = -1;
      const mti = req.data?.mti;

      if (mti === "0800") {
        const traceNum = req.data?.traceNumber;
        if (traceNum) {
          respMatchIndex = allResponses.findIndex(
            (rsp) => rsp.data?.data?.traceNumber === traceNum
          );
        }
      } else {
        const refNum = req.data?.referenceNumber;
        const pCode = req.data?.pcode;

        if (refNum && pCode) {
          // SIMPLE & ROBUST: Match by IDs regardless of Status
          respMatchIndex = allResponses.findIndex(
             (rsp) => {
                 const rspData = rsp.data?.data || rsp.data;
                 const rspRef = rspData?.transactionInfo?.referenceNumber || rspData?.referenceNumber;
                 return rspRef === refNum;
             }
          );
        }
      }

      if (respMatchIndex > -1) {
        pairedTransactions.push({
          request: req,
          response: allResponses[respMatchIndex],
        });
        allResponses.splice(respMatchIndex, 1);
      } else {
        unmatchedRequests.push(req);
      }
    }



    // --- PHASE 2: GREEDY FALLBACK (For Anonymous Error Responses) ---
    // If we still have unmatched requests and unmatched responses (with no ID),
    // pair them sequentially (FIFO).
    
    // We need to re-scan unmatchedRequests because strict ID matching might have skipped them.
    // The current 'unmatchedRequests' array is populated in the ELSE block above.
    
    // Actually, to do this correctly, we should separate the loop.
    // Strategy: 
    // 1. Filter out successful ID matches.
    // 2. Pair leftovers.
    
    // But to respect existing flow:
    // We can iterate unmatchedRequests AFTER the main loop.
    // But 'allResponses' has been spliced. So it contains only leftovers! Perfect.
    
    const trulyUnmatchedRequests = [];
    
    for (const req of unmatchedRequests) {
        let paired = false;
        // Look for FIRST Anonymous Response
        const anonIdx = allResponses.findIndex(rsp => {
             const d = rsp.data?.data || rsp.data;
             return (!d?.referenceNumber && !d?.traceNumber && !d?.transactionInfo?.referenceNumber);
        });
        
        if (anonIdx > -1) {
            // Pair Greedy!
            pairedTransactions.push({
                request: req,
                response: allResponses[anonIdx]
            });
            allResponses.splice(anonIdx, 1);
            paired = true;
        }
        
        if (!paired) trulyUnmatchedRequests.push(req);
    }

    this.entries = [...trulyUnmatchedRequests, ...allResponses];
    return pairedTransactions;
  },

  finalize: function (isoTransactions) {
    const isoMap = new Map();
    for (const iso of isoTransactions) {
      if (iso.refNum && iso.pcode) {
        const key = `${iso.refNum}-${iso.pcode}`;
        isoMap.set(key, iso);
      }
    }

    const allRequests = this.entries.filter((e) => e.type === "REQ");
    let allResponses = this.entries.filter((e) => e.type === "RSP");
    const pairedTransactions = [];
    const unmatchedRequests = []; // We need to track these for fallback

    // --- PHASE 1: ID MATCHING ---
    for (const req of allRequests) {
      let respMatchIndex = -1;
      const mti = req.data?.mti;

      if (mti === "0800") {
        const traceNum = req.data?.traceNumber;
        if (traceNum) {
          respMatchIndex = allResponses.findIndex(
            (rsp) => rsp.data?.data?.traceNumber === traceNum
          );
        }
      } else {
        const refNum = req.data?.referenceNumber;
        const pCode = req.data?.pcode;

        if (refNum && pCode) {
          // SIMPLE & ROBUST: Match by IDs regardless of Status
          respMatchIndex = allResponses.findIndex(
             (rsp) => {
                 const rspData = rsp.data?.data || rsp.data;
                 const rspRef = rspData?.transactionInfo?.referenceNumber || rspData?.referenceNumber;
                 return rspRef === refNum;
             }
          );
        }
      }

      if (respMatchIndex > -1) {
        pairedTransactions.push({
          request: req,
          response: allResponses[respMatchIndex],
        });
        allResponses.splice(respMatchIndex, 1);
      } else {
        unmatchedRequests.push(req);
      }
    }
    
    // --- PHASE 2: GREEDY FALLBACK (Finalize) ---
    for (const req of unmatchedRequests) {
        let paired = false;
        const anonIdx = allResponses.findIndex(rsp => {
             const d = rsp.data?.data || rsp.data;
             return (!d?.referenceNumber && !d?.traceNumber && !d?.transactionInfo?.referenceNumber);
        });
        
        if (anonIdx > -1) {
            pairedTransactions.push({
                request: req,
                response: allResponses[anonIdx]
            });
            allResponses.splice(anonIdx, 1);
            paired = true;
        } else {
            // Truly Orphan Request
            pairedTransactions.push({ request: req, response: null });
        }
    }
    
    // Handle leftover responses if any (optional, usually junk or orphan responses)
    // The previous finalize skipped them. We can skip or log.
    // Parser.js style: return transactions. 
    
    return pairedTransactions;
  },
};

// --- Parsers ---

function parseJsonEntries(rawText) {
  const lines = rawText.split("\n");
  const entries = [];
  let currentEntry = null;
  const headerRegex = /^\s*\[?([\d\w\s:.-]+)\]?\s+<?(REQ|RSP)>?/;
  
  for (const line of lines) {
    const headerMatch = line.match(headerRegex);
    if (headerMatch) {
      if (currentEntry) entries.push(currentEntry);
      currentEntry = {
        timestamp: headerMatch[1].trim(),
        type: headerMatch[2],
        source: "JSON",
        content: line + "\n",
      };
    } else if (currentEntry) {
      currentEntry.content += line + "\n";
    }
  }
  if (currentEntry) entries.push(currentEntry);

  return entries.map((entry) => {
    let data = {};
    const jsonStartIndex = entry.content.indexOf("{");
    const jsonEndIndex = entry.content.lastIndexOf("}");
    if (jsonStartIndex !== -1 && jsonEndIndex > jsonStartIndex) {
      const jsonString = entry.content.substring(jsonStartIndex, jsonEndIndex + 1);
      try {
        data = JSON.parse(jsonString);
      } catch (e) {
        data = { parseError: e.message };
      }
    }
    return { ...entry, data };
  });
}

function parseIsoEntries(rawText) {
  // Regex to find Entry Starts: [Timestamp] <MTI> OR just Timestamp <MTI>
  // Permit Missing MTI: (?:\[)?(Timestamp)(?:\])? (?:\s*<(\d{4})>)?
  // We refine timestamp to be more specific to avoid matching random numbers
  const headerRegex = /(?:\[)?(\d{1,2}\s+[A-Za-z]{3}\s+\d{4}\s+[\d:.]+|[\d-]{10}\s+[\d:.]{8,})(?:\])?(?:\s*<(\d{4})>)?/g;
  
  // Permissive DE Regex: Supports "Field 002: [Val]", "002 [Val]", "002 : Val"
  // Logic: Optional 'Field', 3 digits, separator, value
  const deRegex = /(?:Field\s+)?(\d{3})[:\s]+(?:\[)?([^\]\r\n]+)(?:\])?/g; 

  const entries = [];
  let match;
  let lastIndex = 0;

  // 1. Identify Blocks based on Headers
  while ((match = headerRegex.exec(rawText)) !== null) {
      if (lastIndex > 0) {
           const contentChunk = rawText.substring(lastIndex, match.index);
           if (entries.length > 0) entries[entries.length - 1].content = contentChunk;
      }
      
      const timestamp = match[1] ? match[1].trim() : "Unknown";
      const mti = match[2] || "0000"; // Default to 0000 if missing
      const mtiFunction = parseInt(mti[2] || '0');
      
      entries.push({
          timestamp: timestamp,
          mti: mti,
          type: (mtiFunction % 2 === 0) ? "REQ" : "RSP",
          source: "ISO8583",
          content: '', // Will be filled by next iteration or end of string
          dataElements: new Map(),
      });
      
      lastIndex = headerRegex.lastIndex;
  }
  
  // Capture last chunk
  if (lastIndex > 0 && lastIndex < rawText.length) {
       if (entries.length > 0) entries[entries.length - 1].content = rawText.substring(lastIndex);
  } else if (entries.length === 0 && rawText.trim().length > 0) {
      // Emergency Fallback: If text exists but NO Header matched, treat as Orphan Record
      entries.push({
          timestamp: new Date().toISOString(),
          mti: "0000",
          type: "REQ",
          source: "ISO8583",
          content: rawText,
          dataElements: new Map(),
      });
  }

  // 2. Parse Fields within Blocks
  entries.forEach(entry => {
      let deMatch;
      // Reset lastIndex for local loop (though .matchAll or new Regexp per loop typically safer, /g with exec works if loop finishes)
      // Safest to create new RegExp instance or reset lastIndex if reusing global? 
      // Actually, standard Exec loop on a new string (entry.content) works fine.
      
      const localDeRegex = new RegExp(deRegex); // Clone
      while ((deMatch = localDeRegex.exec(entry.content)) !== null) {
          if (deMatch[1] && deMatch[2]) {
              entry.dataElements.set(deMatch[1], deMatch[2].trim());
          }
      }
  });

  return entries;
}

// --- Mappers ---

function mapIsoTransactionsForDisplay(transactions) {
  return transactions.map((tx) => {
    const convertEntry = (entry) => {
      if (!entry) return null;
      const dataElementsObj = entry.dataElements instanceof Map
        ? Object.fromEntries(entry.dataElements)
        : entry.dataElements;

      return {
        timestamp: entry.timestamp,
        mti: entry.mti,
        dataElements: dataElementsObj,
        content: entry.content // <--- Pass raw content
      };
    };

    const convertedRequest = convertEntry(tx.request);
    const convertedResponse = convertEntry(tx.response);
    const rawAmount = convertedRequest?.dataElements?.["004"] || convertedResponse?.dataElements?.["004"];
    const finalAmount = rawAmount ? parseInt(rawAmount.slice(0, -2), 10) : undefined;

    return {
      request: convertedRequest,
      response: convertedResponse,
      refNum: convertedRequest?.dataElements?.["037"] || convertedResponse?.dataElements?.["037"] || 'N/A',
      responseCode: convertedResponse?.dataElements?.["039"],
      traceNumber: convertedRequest?.dataElements?.["011"] || convertedResponse?.dataElements?.["011"],
      pcode: convertedRequest?.dataElements?.["003"] || convertedResponse?.dataElements?.["003"],
      amount: finalAmount,
      source: "ISO8583",
      rawContent: convertedRequest?.content || convertedResponse?.content || "RAW_CONTENT_MISSING" // Debugging Aid
    };
  });
}

function mapPairedJsonForDisplay(pairedTransactions) {
  return pairedTransactions.map((tx) => {
    return {
      request: tx.request,
      response: tx.response,
      traceNumber: tx.request.data?.traceNumber,
      serialNumber: tx.request.data?.serialNumber,
      pcode: tx.request.data?.pcode,
      refnum: tx.request.data?.referenceNumber,
      responseStatus: tx.response?.data?.responseStatus,
      responseMessage: tx.response?.data?.responseMessage,
      timestamp: tx.request.timestamp,
      source: "JSON",
    };
  });
}

module.exports = {
  IsoHandler,
  JsonHandler,
  mapIsoTransactionsForDisplay,
  mapPairedJsonForDisplay
};
