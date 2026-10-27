# EcoBin 🌱

**A Smart Dustbin Monitoring and Control System powered by Flutter, ESP32, and IoT.**

EcoBin is an Android application designed to monitor and control an ESP32-based smart dustbin over local Wi-Fi. It provides real-time device status, fill-level monitoring, lid controls, operating modes, activity tracking, and alerts through a clean Material 3 interface.

## 📥 Download EcoBin

**[⬇️ Download EcoBin for Android (APK)](https://github.com/Yash4305d-y/APP/releases/download/v1.0.0/app-arm64-v8a-release.apk)**

Download the APK and install it on a compatible Android phone. If Android blocks the installation, allow installation from that source in your device settings.

> **Note:** EcoBin is designed to communicate with an ESP32 on the local Wi-Fi network. Device-control and monitoring features require compatible ESP32 firmware and hardware.

## ✨ Features

- **Live Device Monitoring** — View dustbin status and available fill-level readings.
- **Smart Lid Control** — Send open and close commands to the ESP32.
- **Operating Modes** — Switch between Automatic, Manual, and Maintenance modes.
- **Sensor Status** — View available sensor-health information.
- **Activity Tracking** — Track events observed while the app is connected and running.
- **Alerts** — View device and connection-related alerts within the app.
- **Connection Management** — Monitor connection status and recover when the device becomes reachable again.
- **Debug Logs** — Inspect HTTP requests and responses for troubleshooting.
- **Modern Interface** — Dark navy surfaces, mint accents, and a Material 3 design.
- **Local Communication** — Communicates directly with the ESP32 over Wi-Fi without requiring a paid cloud service.

## 🛠️ Tech Stack

| Technology | Purpose |
|---|---|
| Flutter | Android application development |
| Dart | Application programming language |
| Riverpod | State management |
| HTTP | ESP32 API communication |
| SharedPreferences | Local settings storage |
| SQLite (`sqflite`) | Local database support |
| FL Chart | Charts and data visualization |
| ESP32 | IoT controller |
| Arduino | ESP32 firmware development |
| Git & GitHub | Version control and project hosting |

## 🏗️ Architecture

```text
Android App (Flutter)
        |
        | HTTP over local Wi-Fi
        v
ESP32 Web Server
        |
        +---- Ultrasonic Sensor (Hand Detection)
        |
        +---- Ultrasonic Sensor (Fill-Level Detection)
        |
        +---- Servo Motor (Lid Control)
```

The application uses a repository-based architecture to separate the UI from device communication.

```text
lib/
├── core/
│   └── theme/
├── data/
│   └── repositories/
├── models/
├── providers/
├── screens/
└── main.dart
```

*The directory structure above is a high-level overview; exact folder names may vary with the current implementation.*

## 🔌 Hardware Requirements

The following components are intended for the ESP32 smart-dustbin setup:

- ESP32 development board
- Two HC-SR04 ultrasonic sensors
- Servo motor suitable for the lid mechanism
- Dustbin and mechanical mounting hardware
- Appropriate power supply and jumper wires
- Voltage-divider components or a suitable level shifter for sensor Echo signals

### Example Pin Configuration

| Component | ESP32 GPIO |
|---|---:|
| Servo signal | GPIO 18 |
| Hand sensor Trig | GPIO 25 |
| Hand sensor Echo | GPIO 26 |
| Fill sensor Trig | GPIO 32 |
| Fill sensor Echo | GPIO 33 |

Verify the pin configuration against your actual firmware before wiring the components.

## 📡 ESP32 Communication

EcoBin communicates with the ESP32 through HTTP endpoints over the local network.

| Method | Endpoint | Purpose |
|---|---|---|
| `GET` | `/api/health` | Check device availability |
| `GET` | `/api/status` | Retrieve current device status |
| `POST` | `/api/lid/open` | Request lid opening |
| `POST` | `/api/lid/close` | Request lid closing |
| `POST` | `/api/mode` | Change operating mode |
| `POST` | `/api/maintenance` | Control maintenance state |
| `GET` | `/api/history` | Optional history endpoint, if implemented |

The Android app and ESP32 firmware must agree on endpoint paths, request payloads, response fields, and accepted mode values.

## 🚀 Run Locally

### Prerequisites

- Flutter SDK
- Dart SDK (included with Flutter)
- Android Studio and Android SDK
- A compatible Android device or emulator
- ESP32 hardware and compatible firmware for physical-device testing

### 1. Clone the repository

```bash
git clone https://github.com/Yash4305d-y/APP.git
cd APP
```

### 2. Install dependencies

```bash
flutter pub get
```

### 3. Check the development environment

```bash
flutter doctor
```

Resolve any issues relevant to Android development.

### 4. Run the application

```bash
flutter devices
flutter run
```

For physical ESP32 communication, configure the app with the correct ESP32 IP address and ensure the phone can reach it over Wi-Fi.

## 📦 Build the Android APK

To build a release APK for multiple Android CPU architectures:

```bash
flutter build apk --release --split-per-abi
```

Generated APKs are located in:

```text
build/app/outputs/flutter-apk/
```

For most modern Android phones using 64-bit ARM processors, use:

```text
app-arm64-v8a-release.apk
```

## 🔐 Safety and Reliability

- Use a suitable external power supply for the servo motor and connect grounds appropriately.
- **Do not connect HC-SR04 Echo pins directly to ESP32 GPIO pins without appropriate 3.3 V level protection.**
- Test the servo with its mechanical linkage disconnected before attaching it to the lid.
- Confirm the lid's movement and sensor readings before leaving the system unattended.
- Device readings and actions depend on compatible firmware and functioning hardware.
- Activity history reflects events observed by the app; it should not be treated as a complete record of events that occurred while the app was disconnected.

## ⚠️ Limitations

- Requires a reachable ESP32 and compatible API firmware for real-device features.
- Communication is intended for the local network; internet access alone does not guarantee device connectivity.
- Sensor readings depend on calibration, sensor placement, and environmental conditions.
- Background operation and push notifications are not guaranteed features of the current version.
- Hardware behavior must be validated on the physical setup.

## 🔮 Future Improvements

- Persistent event history and richer analytics
- Improved sensor calibration and diagnostics
- More detailed connection troubleshooting
- Optional export of activity data
- Additional device and hardware configurations

## 👨‍💻 Author

**Yash Kalyani**

- GitHub: [@Yash4305d-y](https://github.com/Yash4305d-y)
- Portfolio: [yashkalyani.vercel.app](https://yashkalyani.vercel.app)

---

⭐ If you find this project interesting, consider starring the repository!
