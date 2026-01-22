# 🧠 Overwatch Core Logic: Pairing & Parsing Guide

This document explains the algorithms used to parse raw logs and pair them (Request + Response) into a single transaction object. Use this logic in the Flutter `Domain` layer.

## 1. ISO 8583 Logic (`Field 011` Pairing)

**Context Source**: `parser.js` (Lines 8-71)
**Goal**: Match an outgoing Request (MTI 0800/0200) with its corresponding Response (MTI 0810/0210).

### Algo Steps:
1.  **Parsing**:
    *   Extract timestamp and MTI from the header: `[Timestamp] <MTI>`
    *   Extract Data Elements using Regex: `Field 011: [Value]`
2.  **Conversion**: Convert raw map to a Dart Object (`IsoTrace`).
3.  **Pairing (The "Join")**:
    *   Store all `REQ` in a list.
    *   Store all `RSP` in a list.
    *   Iterate through `REQ`:
        *   Get `Trace Number` (Field 011).
        *   Find finding `RSP` that has the **same** `Trace Number`.
        *   **Match Found**: Merge into `LogPair(request: req, response: rsp)`.
        *   **No Match**: Create `LogPair(request: req, response: null)` (Orphan).

> **Fallback**: If Field 011 is missing (rare), use `RefNum` (Field 037) or simply display as unpaired.

## 2. JSON Logic (RefNum Pairing)

**Context Source**: `parser.js` (Lines 73-181)
**Context Source**: `dashboard.js` (Lines 271-287)

### Algo Steps:
1.  **Parsing**:
    *   Identify JSON blocks from logs.
    *   Extract `referenceNumber`, `traceNumber`, `pcode`.
2.  **Pairing**:
    *   **Primary Key**: `referenceNumber` (Most reliable).
    *   **Secondary Key**: `traceNumber` (If RefNum matches multiple or is missing).
    *   **Anonymous Responses**: Some error responses from the EDC API don't have RefNum. Match them **Greedily** to the nearest preceding unmatched Request (FIFO).

## 3. Dashboard Display Assembly ("The View Model")

**Context Source**: `dashboard.js` (Lines 250-320)

When pairing ISO and JSON streams together for the main list:
1.  **Group by RefNum**:
    *   Create a Map: `Map<String, List<Transaction>>`.
    *   Key = `RefNum` (e.g., `804520650073`).
    *   Value = List of all ISO legs + List of all JSON legs sharing that RefNum.
2.  **Sorting**:
    *   Sort the final list by `Timestamp` (Desc).
    *   If a group has multiple timestamps, use the **latest** one.

## 4. UI/Style Rules
*   **Status Color**:
    *   `responseCode == "00"` -> **Green** (`#98c379`)
    *   Else -> **Red** (`#e06c75`)
*   **Masking**:
    *   Always mask PAN (Card Number): Show first 6, mask middle, show last 4.
    *   Example: `606058******7354`.

---
*Refer to the attached `dashboard.js` and `parser.js` files for exact implementation details.*
