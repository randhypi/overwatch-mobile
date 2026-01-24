# System Architecture & API Resolution

## Goal Description
Documenting the finalized API Endpoints and Clean Architecture Data Flow for **Overwatch Mobile**.
This document serves as the Source of Truth for all network interactions and internal state management.

## User Review Required
> [!NOTE]
> These endpoints are implemented in `TraceRemoteDataSource` and are critical for the "Realtime Monitoring" feature.

## Resolved Structure

### [API Layer]
The "Three Musketeers" of data ingestion.

#### [POST] `/api/sdk/trace/list`
Fetch list of available log files.
- **Payload**: `{ "appName": "API EDC Nobu", "nodeName": "EDC Nobu" }`
- **Response**: List of filenames.

#### [POST] `/api/sdk/trace/view`
Fetch historical log content.
- **Payload**: `{ "appName": "API Nobu", "fileName": "trace_20230101.log", "lastPosition": 0 }`
- **Response**: GZIP Base64 `logCompressed`, new `lastPosition`.

#### [POST] `/api/sdk/trace/current`
Stream realtime log updates.
- **Payload**: `{ "appName": "API EDC Nobu", "nodeName": "EDC Nobu", "lastPosition": 1024 }`
- **Response**: GZIP Base64 `logCompressed` (delta only).

### [Architecture Layer]
Data flow from Server to UI, ensuring 60fps performance.

```mermaid
graph TD
    %% Styling
    classDef api fill:#e06c75,color:#fff,stroke:#333;
    classDef data fill:#d19a66,color:#000,stroke:#333;
    classDef domain fill:#98c379,color:#000,stroke:#333;
    classDef present fill:#61afef,color:#fff,stroke:#333;
    classDef ui fill:#c678dd,color:#fff,stroke:#333;

    subgraph "External World"
        Server[API Server 103.245.xxx]:::api
    end

    subgraph "Data Layer"
        RemoteDS[TraceRemoteDataSource]:::data
        ApiClient[Dio Client GZIP + SSL]:::data
        RepoImpl[TraceRepositoryImpl]:::data
    end

    subgraph "Domain Layer"
        Repo[TraceRepository Interface]:::domain
        Entity[TraceLog Entity]:::domain
        UsePair[PairingUseCase]:::domain
        UseEnrich[TransactionEnricher]:::domain
    end

    subgraph "Presentation Layer"
        Provider[DashboardController Riverpod]:::present
        State[List TransactionGroup]:::present
    end

    subgraph "UI Layer"
        Screen[DashboardScreen]:::ui
        List[ListView.builder]:::ui
        Card[TransactionGroupCard]:::ui
    end

    %% Flow Connections
    Server <-->|JSON + GZIP| ApiClient
    ApiClient --> RemoteDS
    RemoteDS -->|"Parse Regex"| RepoImpl
    RepoImpl -->|"Return List TraceLog"| UsePair
    
    UsePair -->|"1. Pair Req+Res"| UseEnrich
    UseEnrich -->|"2. Enrich Bank Name, Type"| Provider
    
    Provider -->|"Update State Riverpod"| State
    State -->|"Watch Rebuild"| Screen
    Screen -->|"Render Efficiently"| List
    List --> Card
```

## Verification Plan
### Automated Tests
- `TraceRemoteDataSourceTest`: Verifies that API calls return correct Tuple structures.
- `IsoParserTest`: Validates Regex parsing for ISO 8583.

### Manual Verification
- **Realtime Monitor**: Open Dashboard -> Check if logs appear in real-time.
- **History View**: Click "History" -> Select Date -> Verify older logs load.
