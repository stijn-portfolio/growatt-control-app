import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/device.dart';
import '../providers/config_provider.dart';
import '../providers/devices_provider.dart';

class DeviceCard extends StatefulWidget {
  final Device device;

  const DeviceCard({
    super.key,
    required this.device,
  });

  @override
  State<DeviceCard> createState() => _DeviceCardState();
}

class _DeviceCardState extends State<DeviceCard> {
  bool _isToggling = false;

  Future<void> _handleToggle(bool value) async {
    setState(() {
      _isToggling = true;
    });

    final config = context.read<ConfigProvider>();
    final devices = context.read<DevicesProvider>();
    final apiService = config.getApiService();

    if (apiService == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('API service not configured'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        _isToggling = false;
      });
      return;
    }

    final success = await devices.toggleDevice(
      apiService,
      widget.device,
      value,
    );

    setState(() {
      _isToggling = false;
    });

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Device turned ${value ? 'on' : 'off'} successfully',
            ),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(devices.errorMessage ?? 'Failed to control device'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Color _getStatusColor() {
    final device = widget.device;
    if (device.hasFault) return Colors.red;
    if (device.isWaiting) return Colors.orange;
    if (device.isProducing) return Colors.green;
    return Colors.grey; // Unknown status
  }

  IconData _getDeviceIcon() {
    switch (widget.device.deviceType.toLowerCase()) {
      case 'inv':
        return Icons.bolt;
      case 'storage':
        return Icons.battery_charging_full;
      case 'sph':
      case 'spa':
        return Icons.solar_power;
      case 'noah':
        return Icons.power;
      default:
        return Icons.devices;
    }
  }

  @override
  Widget build(BuildContext context) {
    final device = widget.device;
    final canControl = !device.isNoahDevice;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getDeviceIcon(),
                  size: 32,
                  color: _getStatusColor(),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        device.displayName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Type: ${device.deviceType.toUpperCase()}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor().withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _getStatusColor()),
                      ),
                      child: Text(
                        device.statusText ?? 'Unknown',
                        style: TextStyle(
                          color: _getStatusColor(),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (device.lastUpdated != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        _formatLastUpdated(device.lastUpdated!),
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'SN: ${device.deviceSn}',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
                fontFamily: 'monospace',
              ),
            ),
            if (device.statusText != null) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  if (device.pac != null)
                    _buildInfoChip(
                      Icons.bolt,
                      '${device.pac!.toStringAsFixed(0)} W',
                      'Current Power',
                    ),
                  if (device.powerToday != null)
                    _buildInfoChip(
                      Icons.wb_sunny,
                      '${device.powerToday!.toStringAsFixed(1)} kWh',
                      'Today',
                    ),
                  if (device.temperature != null)
                    _buildInfoChip(
                      Icons.thermostat,
                      '${device.temperature!.toStringAsFixed(1)}°C',
                      'Temp',
                    ),
                ],
              ),
            ],
            if (canControl) ...[
              const Divider(height: 24),
              Consumer<DevicesProvider>(
                builder: (context, devicesProvider, child) {
                  final cooldown = devicesProvider.toggleCooldownSeconds;
                  final canToggleNow = devicesProvider.canToggle;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Power Control',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          _isToggling
                              ? const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : Switch(
                                  value: device.isProducing,
                                  onChanged: (canToggleNow && !device.hasFault)
                                      ? _handleToggle
                                      : null,
                                ),
                        ],
                      ),
                      if (!canToggleNow && cooldown > 0) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Wait ${cooldown}s before next toggle',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.orange.shade700,
                            fontStyle: FontStyle.italic,
                          ),
                          textAlign: TextAlign.end,
                        ),
                      ],
                    ],
                  );
                },
              ),
            ] else ...[
              const Divider(height: 24),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, size: 16, color: Colors.orange),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Noah devices do not support power control',
                        style: TextStyle(fontSize: 12, color: Colors.orange),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade700),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatLastUpdated(DateTime lastUpdated) {
    final now = DateTime.now();
    final diff = now.difference(lastUpdated);

    if (diff.inMinutes < 1) {
      return 'Just now';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else {
      return '${diff.inDays}d ago';
    }
  }
}
