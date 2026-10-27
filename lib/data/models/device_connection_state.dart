/// Represents the connection status of the EcoBin device.
enum DeviceConnectionStatus {
  disconnected('Disconnected'),
  connecting('Connecting...'),
  connected('Connected'),
  demoMode('Demo Mode (Simulated)'),
  error('Connection Error');

  const DeviceConnectionStatus(this.displayName);
  final String displayName;
}
