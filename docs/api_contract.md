# EcoBin — ESP32 HTTP API Contract (Provisional)

> **Document Status**: Provisional Alignment Contract  
> **Target Device**: ESP32 IoT Smart Dustbin  
> **Protocol**: HTTP/1.1 (Cleartext over local network / SoftAP)  
> **Base URL**: `http://<device-ip>` (Default SoftAP: `http://192.168.4.1`)  
> **Client Timeout**: 3.0 seconds per request  

---

## 1. Overview & Firmware Alignment Assumptions

Since firmware source is managed independently from this mobile repository, this specification outlines the provisional REST-style JSON interface assumed by the Flutter application. 

### Key Engineering Rules:
1. **No Silent 0% Fill**: If the ultrasonic sensor is offline, disconnected, or failing echo, the device must report `"fill_percentage": null`. The mobile client will explicitly render an "Unavailable / Offline" state and will never falsify `0%`.
2. **Asynchronous Servo Actuation**: HTTP command endpoints return `200 OK` with `"status": "accepted"` or `"moving"`. The client polls `/api/status` to verify whether the physical position was reached.
3. **Local Network Cleartext**: All endpoints are on private IP subnets (`192.168.x.x`, `10.x.x.x`, `172.16.x.x`). No HTTPS/TLS certificates are expected from the ESP32.

---

## 2. API Endpoints

### 2.1 `GET /api/health`
Lightweight ping used for connection validation, IP diagnostics, and firmware handshake.

- **Request**: No headers or body required.
- **Success Response (`200 OK`)**:
  ```json
  {
    "status": "ok",
    "device": "ecobin-esp32",
    "firmware": "1.0.0",
    "uptime_seconds": 1420
  }
  ```
- **Error Response**: `503 Service Unavailable` if system initialization is incomplete.

---

### 2.2 `GET /api/status`
Periodic telemetry polling endpoint called by the companion app every 5 seconds.

- **Request**: No query parameters or body required.
- **Success Response (`200 OK`)**:
  ```json
  {
    "fill_percentage": 64.5,
    "lid_state": "closed",
    "mode": "automatic",
    "today_openings": 18,
    "battery_percentage": 92,
    "wifi_signal_dbm": -56
  }
  ```

#### Field Specifications:
| Field | Type | Allowed Values | Nullable? | Description |
| :--- | :--- | :--- | :--- | :--- |
| `fill_percentage` | `float` | `0.0` – `100.0` | **YES** | Null when ultrasonic sensor echo fails. |
| `lid_state` | `string` | `"open"`, `"closed"`, `"moving"`, `"unknown"` | No | Current physical/servo switch state. |
| `mode` | `string` | `"automatic"`, `"manual"`, `"maintenance"` | No | Active operating policy. |
| `today_openings` | `int` | `>= 0` | No | Daily opening counter tracked on ESP32. |
| `battery_percentage` | `int` | `0` – `100` | Yes | Power cell reading (null if USB wall powered). |
| `wifi_signal_dbm` | `int` | e.g. `-90` to `-30` | Yes | Station RSSI (null in SoftAP mode). |

---

### 2.3 `POST /api/lid/open`
Requests the ESP32 servo motor to open the bin lid.

- **Headers**: `Content-Type: application/json`
- **Body**: `{}` (or empty)
- **Success Response (`200 OK` or `202 Accepted`)**:
  ```json
  {
    "success": true,
    "status": "accepted",
    "message": "Servo open routine initiated"
  }
  ```
- **Conflict Response (`409 Conflict`)**:
  Returned when lid is locked in Maintenance Mode or already actively actuating.
  ```json
  {
    "success": false,
    "error": "Lid actuation locked while Maintenance Mode is active"
  }
  ```

---

### 2.4 `POST /api/lid/close`
Requests the ESP32 servo motor to close the bin lid.

- **Headers**: `Content-Type: application/json`
- **Body**: `{}` (or empty)
- **Success Response (`200 OK` or `202 Accepted`)**:
  ```json
  {
    "success": true,
    "status": "accepted",
    "message": "Servo close routine initiated"
  }
  ```

---

### 2.5 `POST /api/mode`
Sets the operating mode of the bin.

- **Headers**: `Content-Type: application/json`
- **Body**:
  ```json
  {
    "mode": "automatic"
  }
  ```
  *(Allowed values: `"automatic"`, `"manual"`, `"maintenance"`)*
- **Success Response (`200 OK`)**:
  ```json
  {
    "success": true,
    "mode": "automatic"
  }
  ```
- **Error Response (`400 Bad Request`)**:
  ```json
  {
    "success": false,
    "error": "Invalid mode specified"
  }
  ```

---

### 2.6 `POST /api/maintenance`
Direct toggle for Maintenance Mode (locks lid closed for safe bag changing).

- **Headers**: `Content-Type: application/json`
- **Body**:
  ```json
  {
    "enabled": true
  }
  ```
- **Success Response (`200 OK`)**:
  ```json
  {
    "success": true,
    "maintenance": true
  }
  ```

---

## 3. Error Handling Semantics
- **Timeout**: The client enforces a strict **3-second timeout**. If no HTTP response is received, the attempt is marked as a timeout failure.
- **Failures & Offline State**: 3 consecutive status poll failures are required before the app transitions the connection status from `online` to `offline`.
- **Recovery**: Any subsequent `200 OK` response from `/api/status` or `/api/health` immediately transitions connection state back to `online`.
- **Malformed Data**: If JSON contains missing required fields or cannot be parsed, the app registers a parse error without marking the physical socket as offline.
