import 'dart:async';

import 'package:flutter/material.dart';
import 'dashboard_page.dart';
import 'account_creation_page.dart';
import 'firmwareFlashPage.dart';
class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const DashboardPage(),
    const AccountCreationPage(),
    const FirmwareFlashPage(),
    const SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    bool isMobile = MediaQuery.of(context).size.width < 800;

    return Scaffold(
      // Mobile Top Bar
      appBar: isMobile ? AppBar(
        title: const Text("IoT Admin"),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const Icon(Icons.bolt, color: Colors.indigo),
      ) : null,

      // Bottom Nav for Mobile
      bottomNavigationBar: isMobile ? BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.indigo,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.person_add), label: 'Account'),
          BottomNavigationBarItem(icon: Icon(Icons.system_update_alt), label: 'Flash'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ) : null,

      body: Row(
        children: [
          // Navigation Rail for Desktop Only
          if (!isMobile) ...[
            NavigationRail(
              extended: MediaQuery.of(context).size.width > 1200,
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
          ],
          Expanded(child: _pages[_selectedIndex]),
        ],
      ),
    );
  }
}
// --------------------------------------------------------------------------
// NEW: FIRMWARE FLASH PAGE
// --------------------------------------------------------------------------

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