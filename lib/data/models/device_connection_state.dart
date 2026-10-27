/// Represents the connection status of the EcoBin hardware or simulated device.
enum DeviceConnectionStatus {
  connecting('Connecting...'),
  online('Online'),
  offline('Offline'),
  error('Connection Error'),
  demoMode('Demo Mode (Simulated)');

  const DeviceConnectionStatus(this.displayName);
  final String displayName;

  bool get isOnline => this == online;
  bool get isDemo => this == demoMode;
}
