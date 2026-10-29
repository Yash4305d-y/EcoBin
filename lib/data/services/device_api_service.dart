import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../core/constants/app_constants.dart';
import '../../core/errors/device_exceptions.dart';
import '../../core/utils/dustbin_fill_calculator.dart';
import '../models/device_status.dart';
import 'settings_service.dart';

/// Low-level HTTP communication client targeting the ESP32 microcontroller endpoints.
class DeviceApiService {
  DeviceApiService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Uri _buildUri(String ipAddress, String path) {
    final cleanIp = ipAddress.trim();
    if (!SettingsService.isValidIpv4(cleanIp)) {
      throw DeviceConnectionException(
        'Invalid IPv4 address format: "$ipAddress". Expected format: 192.168.4.1',
      );
    }
    return Uri.parse('http://$cleanIp$path');
  }

  Future<http.Response> _sendRequest(
    Future<http.Response> Function() requestFn, {
    required String endpoint,
  }) async {
    try {
      return await requestFn().timeout(AppConstants.httpTimeout);
    } on TimeoutException catch (e) {
      throw DeviceConnectionException(
        'Request to $endpoint timed out after ${AppConstants.httpTimeout.inSeconds}s',
        isTimeout: true,
        originalError: e,
      );
    } on SocketException catch (e) {
      throw DeviceConnectionException(
        'Failed to connect to ESP32 at $endpoint: ${e.message}',
        originalError: e,
      );
    } on http.ClientException catch (e) {
      throw DeviceConnectionException(
        'HTTP client transport failure on $endpoint: ${e.message}',
        originalError: e,
      );
    } catch (e) {
      throw DeviceConnectionException(
        'Unexpected communication error on $endpoint: $e',
        originalError: e,
      );
    }
  }

  Map<String, dynamic> _decodeJson(String body, String endpoint) {
    try {
      final dynamic decoded = jsonDecode(body);
      if (decoded is! Map<String, dynamic>) {
        throw DeviceDataException(
          'Unexpected JSON root structure on $endpoint (expected Map, got ${decoded.runtimeType})',
        );
      }
      return decoded;
    } on FormatException catch (e) {
      throw DeviceDataException(
        'Malformed JSON received from $endpoint: ${e.message}',
        originalError: e,
      );
    }
  }

  /// Sends `GET /api/health` to confirm device availability.
  Future<Map<String, dynamic>> checkHealth(String ipAddress) async {
    final uri = _buildUri(ipAddress, '/api/health');
    final response = await _sendRequest(
      () => _client.get(uri),
      endpoint: '/api/health',
    );

    if (response.statusCode != 200) {
      throw DeviceApiException(
        'Health check failed with HTTP ${response.statusCode}',
        statusCode: response.statusCode,
        endpoint: '/api/health',
        responseBody: response.body,
      );
    }

    return _decodeJson(response.body, '/api/health');
  }

  /// Sends `GET /api/status` and parses telemetry into [DeviceStatus].
  Future<DeviceStatus> getStatus(
    String ipAddress, {
    RollingMedianFillFilter? fillFilter,
  }) async {
    final uri = _buildUri(ipAddress, '/api/status');
    final response = await _sendRequest(
      () => _client.get(uri),
      endpoint: '/api/status',
    );

    if (response.statusCode != 200) {
      throw DeviceApiException(
        'Telemetry poll failed with HTTP ${response.statusCode}',
        statusCode: response.statusCode,
        endpoint: '/api/status',
        responseBody: response.body,
      );
    }

    final json = _decodeJson(response.body, '/api/status');
    try {
      return DeviceStatus.fromJson(
        json,
        deviceIp: ipAddress,
        communicationTime: DateTime.now(),
        fillFilter: fillFilter,
      );
    } catch (e) {
      throw DeviceDataException(
        'Failed to parse device status fields: $e',
        originalError: e,
      );
    }
  }

  /// Sends `POST /api/lid/open`.
  Future<Map<String, dynamic>> openLid(String ipAddress) async {
    final uri = _buildUri(ipAddress, '/api/lid/open');
    final response = await _sendRequest(
      () => _client.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(<String, dynamic>{}),
      ),
      endpoint: '/api/lid/open',
    );

    if (response.statusCode != 200 && response.statusCode != 202) {
      throw DeviceApiException(
        'Open lid rejected with HTTP ${response.statusCode}',
        statusCode: response.statusCode,
        endpoint: '/api/lid/open',
        responseBody: response.body,
      );
    }

    return _decodeJson(response.body, '/api/lid/open');
  }

  /// Sends `POST /api/lid/close`.
  Future<Map<String, dynamic>> closeLid(String ipAddress) async {
    final uri = _buildUri(ipAddress, '/api/lid/close');
    final response = await _sendRequest(
      () => _client.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(<String, dynamic>{}),
      ),
      endpoint: '/api/lid/close',
    );

    if (response.statusCode != 200 && response.statusCode != 202) {
      throw DeviceApiException(
        'Close lid rejected with HTTP ${response.statusCode}',
        statusCode: response.statusCode,
        endpoint: '/api/lid/close',
        responseBody: response.body,
      );
    }

    return _decodeJson(response.body, '/api/lid/close');
  }

  /// Sends `POST /api/mode`.
  Future<Map<String, dynamic>> setMode(
    String ipAddress,
    OperatingMode mode,
  ) async {
    final uri = _buildUri(ipAddress, '/api/mode');
    final response = await _sendRequest(
      () => _client.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'mode': mode.name}),
      ),
      endpoint: '/api/mode',
    );

    if (response.statusCode != 200) {
      throw DeviceApiException(
        'Mode update rejected with HTTP ${response.statusCode}',
        statusCode: response.statusCode,
        endpoint: '/api/mode',
        responseBody: response.body,
      );
    }

    return _decodeJson(response.body, '/api/mode');
  }

  /// Sends `POST /api/maintenance`.
  Future<Map<String, dynamic>> setMaintenance(
    String ipAddress,
    bool enabled,
  ) async {
    final uri = _buildUri(ipAddress, '/api/maintenance');
    final response = await _sendRequest(
      () => _client.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'enabled': enabled}),
      ),
      endpoint: '/api/maintenance',
    );

    if (response.statusCode != 200) {
      throw DeviceApiException(
        'Maintenance command rejected with HTTP ${response.statusCode}',
        statusCode: response.statusCode,
        endpoint: '/api/maintenance',
        responseBody: response.body,
      );
    }

    return _decodeJson(response.body, '/api/maintenance');
  }

  void dispose() {
    _client.close();
  }
}
