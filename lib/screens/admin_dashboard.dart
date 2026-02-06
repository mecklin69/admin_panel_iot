import 'dart:async';

import 'package:flutter/material.dart';
import 'dashboard_page.dart';
import 'account_creation_page.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedIndex = 0;

  // We add the FirmwareFlashPage here as the 3rd index
  final List<Widget> _pages = [
    const DashboardPage(),
    const AccountCreationPage(),
    const FirmwareFlashPage(), // NEW: Flash IoT Device Page
    const SettingsPage(),      // Settings is now 4th
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            extended: true,
            selectedIndex: _selectedIndex,
            onDestinationSelected: (int index) => setState(() => _selectedIndex = index),
            leading: const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Icon(Icons.bolt, size: 40, color: Colors.indigo),
            ),
            destinations: const [
              NavigationRailDestination(icon: Icon(Icons.dashboard), label: Text('Dashboard')),
              NavigationRailDestination(icon: Icon(Icons.person_add), label: Text('Create Account')),
              NavigationRailDestination(icon: Icon(Icons.system_update_alt), label: Text('Flash IoT')),
              NavigationRailDestination(icon: Icon(Icons.settings), label: Text('Settings')),
            ],
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(child: _pages[_selectedIndex]),
        ],
      ),
    );
  }
}

// --------------------------------------------------------------------------
// NEW: FIRMWARE FLASH PAGE
// --------------------------------------------------------------------------
class FirmwareFlashPage extends StatefulWidget {
  const FirmwareFlashPage({super.key});

  @override
  State<FirmwareFlashPage> createState() => _FirmwareFlashPageState();
}

class _FirmwareFlashPageState extends State<FirmwareFlashPage> {
  double _progress = 0;
  bool _isFlashing = false;
  String _statusMessage = "Device Ready for Update";
  String _currentVersion = "v1.2.0";
  String _latestVersion = "v1.5.8 (Available)";

  void _simulateFlash() {
    setState(() {
      _isFlashing = true;
      _progress = 0;
      _statusMessage = "Connecting to Update Server...";
    });

    // Simulate progress over time
    Timer.periodic(const Duration(milliseconds: 100), (timer) {
      setState(() {
        _progress += 0.02; // Increment by 2%

        if (_progress >= 0.2) _statusMessage = "Downloading Firmware Binary...";
        if (_progress >= 0.5) _statusMessage = "Verifying MD5 Checksum...";
        if (_progress >= 0.8) _statusMessage = "Writing to Flash Memory...";

        if (_progress >= 1.0) {
          _progress = 1.0;
          _isFlashing = false;
          _statusMessage = "Update Successful! Device Rebooting...";
          _currentVersion = "v1.5.8";
          timer.cancel();
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Firmware Flash Station", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
          const Text("Manage over-the-air (OTA) updates for your connected IoT hardware."),
          const SizedBox(height: 30),

          // Version Info Card
          Card(
            elevation: 0,
            color: Colors.indigo.withOpacity(0.05),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("HARDWARE: Industrial Sensor G2", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)),
                      const SizedBox(height: 4),
                      Text("Installed Version: $_currentVersion"),
                      Text("Latest Available: $_latestVersion"),
                    ],
                  ),
                  ElevatedButton.icon(
                    onPressed: _isFlashing ? null : () => setState(() => _latestVersion = "v1.5.8 (Check Complete)"),
                    icon: const Icon(Icons.sync),
                    label: const Text("CHECK FOR UPDATE"),
                  )
                ],
              ),
            ),
          ),

          const SizedBox(height: 50),

          // Progress & Controls
          Center(
            child: Column(
              children: [
                Text(_statusMessage, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
                const SizedBox(height: 20),

                // The Progress Bar
                Container(
                  width: 600,
                  height: 12,
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(10)),
                  child: LinearProgressIndicator(
                    value: _progress,
                    backgroundColor: Colors.grey[200],
                    color: Colors.green,
                    minHeight: 12,
                  ),
                ),
                const SizedBox(height: 10),
                Text("${(_progress * 100).toInt()}% Complete", style: const TextStyle(color: Colors.grey)),

                const SizedBox(height: 40),

                // Flash Action Button
                SizedBox(
                  width: 250,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _isFlashing ? null : _simulateFlash,
                    icon: const Icon(Icons.flash_on),
                    label: const Text("FLASH FIRMWARE"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange[800],
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey[300],
                    ),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}

// --------------------------------------------------------------------------
// UPDATED SETTINGS PAGE
// --------------------------------------------------------------------------
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("System Settings", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
          Divider(),
          ListTile(
            leading: Icon(Icons.cloud_done),
            title: Text("API Status"),
            subtitle: Text("AWS Amplify Connected (Region: us-east-1)"),
          ),
          ListTile(
            leading: Icon(Icons.security),
            title: Text("Environment Mode"),
            subtitle: Text("Production - Encryption Active"),
          ),
        ],
      ),
    );
  }
}