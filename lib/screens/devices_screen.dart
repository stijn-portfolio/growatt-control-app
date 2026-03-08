import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/config_provider.dart';
import '../providers/devices_provider.dart';
import '../widgets/device_card.dart';
import 'settings_screen.dart';

class DevicesScreen extends StatefulWidget {
  const DevicesScreen({super.key});

  @override
  State<DevicesScreen> createState() => _DevicesScreenState();
}

class _DevicesScreenState extends State<DevicesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDevices();
    });
  }

  Future<void> _loadDevices() async {
    final config = context.read<ConfigProvider>();
    final devices = context.read<DevicesProvider>();

    if (!config.isConfigured) {
      return;
    }

    // Check if this refresh will get fresh data
    final willFetchFresh = devices.willFetchFreshData;
    final nextFreshIn = devices.nextFreshDataIn;

    final apiService = config.getApiService();
    if (apiService != null) {
      await devices.loadDevices(apiService);

      // Show feedback if data was cached
      if (mounted && !willFetchFresh && nextFreshIn > 0) {
        final minutes = (nextFreshIn / 60).ceil();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Showing cached data (refreshes every 5 min, ${minutes}m remaining)',
            ),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _navigateToSettings() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SettingsScreen()),
    );
    // Reload devices after returning from settings
    if (mounted) {
      _loadDevices();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Growatt Devices'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _navigateToSettings,
            tooltip: 'Settings',
          ),
        ],
      ),
      body: Consumer2<ConfigProvider, DevicesProvider>(
        builder: (context, config, devices, child) {
          if (config.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (!config.isConfigured) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.settings,
                      size: 64,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No Configuration Found',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Please configure your API token and region to get started.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _navigateToSettings,
                      icon: const Icon(Icons.settings),
                      label: const Text('Open Settings'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          if (devices.isLoading) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading devices...'),
                ],
              ),
            );
          }

          if (devices.errorMessage != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Error',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      devices.errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _loadDevices,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          if (devices.devices.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.devices_other,
                      size: 64,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No Devices Found',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'No devices are associated with this API token.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _loadDevices,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Refresh'),
                    ),
                  ],
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _loadDevices,
            child: Column(
              children: [
                if (devices.lastRefresh != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    color: Colors.grey.shade100,
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Last updated: ${_formatTime(devices.lastRefresh!)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            Text(
                              '${devices.devices.length} device(s)',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.bolt,
                                  size: 14,
                                  color: devices.totalCurrentPower > 0
                                      ? Colors.green.shade700
                                      : Colors.grey.shade600,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${devices.totalCurrentPower.toStringAsFixed(0)} W',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: devices.totalCurrentPower > 0
                                        ? Colors.green.shade700
                                        : Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                Icon(
                                  Icons.wb_sunny,
                                  size: 14,
                                  color: Colors.orange.shade600,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${devices.totalPowerToday.toStringAsFixed(1)} kWh today',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                Expanded(
                  child: ListView.builder(
                    itemCount: devices.devices.length,
                    itemBuilder: (context, index) {
                      return DeviceCard(device: devices.devices[index]);
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: Consumer<DevicesProvider>(
        builder: (context, devices, child) {
          final cooldown = devices.refreshCooldownSeconds;
          final canRefresh = devices.canRefresh;
          final willFetchFresh = devices.willFetchFreshData;
          final nextFreshIn = devices.nextFreshDataIn;

          // Determine button state
          final bool enabled = canRefresh && (willFetchFresh || devices.devices.isEmpty);
          final String label;
          final String tooltip;

          if (!canRefresh) {
            // 5-second cooldown active
            label = '${cooldown}s';
            tooltip = 'Wait ${cooldown}s between refreshes';
          } else if (!willFetchFresh && nextFreshIn > 0) {
            // All devices have fresh data (< 5 min old) - show countdown
            if (nextFreshIn >= 60) {
              final minutes = nextFreshIn ~/ 60;
              final seconds = nextFreshIn % 60;
              label = '${minutes}m ${seconds}s';
              tooltip = 'Fresh data available in ${minutes}m ${seconds}s';
            } else {
              label = '${nextFreshIn}s';
              tooltip = 'Fresh data available in ${nextFreshIn}s';
            }
          } else {
            label = 'Refresh';
            tooltip = 'Refresh device data';
          }

          return FloatingActionButton.extended(
            onPressed: enabled ? _loadDevices : null,
            tooltip: tooltip,
            backgroundColor: enabled ? null : Colors.grey.shade400,
            icon: const Icon(Icons.refresh),
            label: Text(label),
          );
        },
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inSeconds < 60) {
      return '${diff.inSeconds}s ago';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else {
      return '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
    }
  }
}
