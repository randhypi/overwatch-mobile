# API LOGGING TRACE Specification

Source of Truth for Trace API Integration.

**Base URL**: `http://103.245.122.241:47023`

---

## 1. Trace List
**Path**: `/api/sdk/trace/list`
**Method**: `POST`

### Request
```json
{
	"appName": "API EDC Nobu",
	"nodeName": "EDC Nobu"
}
```

### Response
```json
{
	"responseCode": "00",
	"responseMessage": "Success",
	"data": {
		"listFiles": [
			"EDC Nobu_20251224_08.log",
			"EDC Nobu_20251121_08.log",
			"EDC Nobu_20241226_18.log",
			"EDC Nobu_20241226_15.log"
		]
	}
}
```

---

## 2. Trace View
**Path**: `/api/sdk/trace/view`
**Method**: `POST`

### Request
```json
{
	"appName": "API EDC Nobu",
	"fileName": "EDC Nobu_20251224_08.log",
	"lastPosition": 0
}
```

### Response
```json
{
	"responseCode": "00",
	"responseMessage": "Success",
	"data": {
		"logCompressed": "...",
		"lastPosition": 8429
	}
}
```

---

## 3. Trace Current
**Path**: `/api/sdk/trace/current`
**Method**: `POST`

### Request
```json
{
	"appName": "API EDC Nobu",
	"nodeName": "EDC Nobu",
	"lastPosition": 0
}
```

### Response
```json
{
	"responseCode": "00",
	"responseMessage": "Success",
	"data": {
		"logCompressed": "...",
		"lastPosition": 8429
	}
}
```

---

## Notes
- **Compression**: Field `logCompressed` is **Base64 encoded GZIP**.
- **Pagination**: Use `lastPosition` to fetch incremental updates and avoid redundant data transfer.
