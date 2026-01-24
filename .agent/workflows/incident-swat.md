# 🚨 Incident SWAT Protocol (The Firefighter)

## Objective
Rapid response protocol to diagnose and fix production issues "in the wild".

## Diagnosis Flow

1.  **Isolation (Who is the culprit?)**
    -   **Network**: Is the device connected? Is the IP `103.245.xxx` reachable? (Use Ping Tool).
    -   **Server**: Is the API returning 500? (Check Dashboard "System" Status).
    -   **App**: Is the Parser failing? (Check "Orphan" logs count).

2.  **Log Dumping Procedure**
    -   Since we cannot debug user device directly:
    -   Ask User to go to: **Settings -> Export Logs**.
    -   Logs should be dumped to `/Documents/OverwatchLogs/dump_{date}.txt`.
    -   Analyze `dump_{date}.txt` for exceptions (grep "Exception").

3.  **Key Patterns to Watch**
    -   `HandshakeException`: SSL Pinning Mismatch (Server cert changed).
    -   `FormatException`: JSON structure changed (Backend API breaking change).
    -   `SocketException`: Firewalls/VPN issues on User network.

4.  **Action Plan**
    -   **Level 1**: Clear Cache / Restart App.
    -   **Level 2**: Reinstall APK.
    -   **Level 3 (DevOps)**: Hotfix release required. Follow `@release-guard`.
