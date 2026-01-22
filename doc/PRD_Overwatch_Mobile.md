# Product Requirements Document (PRD) - Overwatch Mobile

## 1. Introduction
**Product Name**: Overwatch Mobile
**Version**: 1.0.0
**Purpose**: A high-fidelity mobile companion for the Overwatch Transaction Monitor system. It allows support teams to monitor, filter, and analyze ISO 8583 & JSON transaction logs in realtime from their mobile devices, ensuring critical issues (timeouts, error response codes) can be detected anywhere.

## 2. User Persona
*   **Target User**: DevOps Engineer / Technical Support (Level 2).
*   **Key Goals**:
    1.  Instant visibility of transaction streams.
    2.  Quick filtering (e.g., "Find all timeouts for Store A").
    3.  Copying detailed logs for debugging without opening a laptop.
*   **Pain Points**: Web Dashboard is not mobile-optimized; existing scraping requires keeping a desktop browser open.

## 3. Core Features

### 3.1. Realtime Dashboard (The "Matrix" View)
*   **Data Stream**: Two-column layout (or Tabbed View on small screens) for:
    *   **ISO Stream** (API Nobu / 00006021010)
    *   **JSON Stream** (API EDC Nobu)
*   **Visual Guard**:
    *   **Status OK**: Green Indicators (`#98c379`)
    *   **Status Fail**: Red Indicators (`#e06c75`)
    *   **No Response**: Dimmed/Opacity styling.
*   **Sorting**: Default to "Newest First" (Time Descending).

### 3.2. Advanced Filtering (Console-style)
*   User can input text to filter by:
    *   **Trace Number**
    *   **Reference Number**
    *   **Terminal ID**
    *   **Serial Number**
    *   **PAN (Card Number)** -> *Must be masked by default*
    *   **Response Status** (e.g., `!00` for errors)
    *   **PCode**
*   **Logic Toggle**: Switch between `AND` (Match All) and `OR` (Match Any) logic.

### 3.3. Key Actions
*   **Copy Simple**: Copies a summary (Time, Trace, Ref, Amount, Status) to clipboard.
*   **Copy Detail**: Copies the full raw JSON payload to clipboard.
*   **Masking Toggle**: Global toggle to mask sensitive card numbers (PAN) in the UI (`******1234`).
*   **Cleanup Duplicates**: Button to trigger server-side cleanup.

## 4. UI/UX Design Specifications
The app MUST replicate the existing "Hacker/Console" aesthetic of the Web Dashboard.

### 4.1. Color Palette (Strict Adherence)
| Element | Hex Code | Description |
| :--- | :--- | :--- |
| **Background** | `#282c34` | Main App Background |
| **Card Background** | `#323842` | Transaction Item Bg |
| **Header Background** | `#1e2127` | Top Bar & Filter Area |
| **Primary Text** | `#abb2bf` | Standard content text |
| **Secondary Text** | `#7f8899` | Labels, timestamp |
| **Input Background** | `#3a3f4b` | Filter textfields |
| **Button Primary** | `#61afef` | Standard actions (Blue) |
| **Status OK** | `#98c379` | Green (Success) |
| **Status Fail** | `#e06c75` | Red (Error) |
| **Slider/Toggle** | `#5c6370` | Toggle switches |

### 4.2. Typography
*   **Family**: `Roboto` or `Inter` (Google Fonts).
*   **Monospace**: Use `JetBrains Mono` or `Roboto Mono` for log content (Trace IDs, JSON payloads).

### 4.3. Layout Changes for Mobile
*   **Tabs**: Instead of side-by-side columns (which don't fit on phone), use a **TabController**:
    *   [Tab 1: ISO Logs]
    *   [Tab 2: JSON Logs]
*   **Filters**: Collapsible "Filter Drawer" or "Expandable Header" to save screen space.

## 5. Non-Functional Requirements
*   **Security (CRITICAL)**: `SecretKey` and `ClientID` MUST NOT be visible in the source code strings. Use Native C++ storage.
*   **Performance**: Must handle list rendering of 500+ items without lag (Use `ListView.builder`).
*   **Offline Handling**: Show "Network Error" toast if API unreachable.
