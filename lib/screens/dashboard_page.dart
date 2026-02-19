import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:universal_html/html.dart' as html;

import '../aws/amplify_service.dart';
import 'dashboard_widget.dart'; // Import the new file

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  bool _isLoading = true;
  List<dynamic> _allClients = [];
  List<dynamic> _filteredClients = [];
  String? _error;

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    html.window.onContextMenu.listen((event) => event.preventDefault());
    super.initState();
    _loadClients();
  }

  List<dynamic> get _chronologicalHistory {
    List<dynamic> history = List.from(_allClients);
    history.sort((a, b) {
      DateTime dateA = DateTime.tryParse(a['deploymentDate'] ?? '') ?? DateTime(2000);
      DateTime dateB = DateTime.tryParse(b['deploymentDate'] ?? '') ?? DateTime(2000);
      return dateB.compareTo(dateA);
    });
    return history;
  }

  Future<void> _loadClients() async {
    setState(() => _isLoading = true);
    try {
      final data = await AmplifyService.fetchAllClients();
      setState(() {
        _allClients = data;
        _filteredClients = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteClient(String vendorID, String companyName) async {
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirm Delete"),
        content: Text("Are you sure you want to delete $companyName?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    ) ?? false;

    if (confirm) {
      setState(() => _isLoading = true);
      final success = await AmplifyService.deleteClient(vendorID);
      if (success) {
        _showSnackBar("Client deleted successfully", Colors.green);
        _loadClients();
      } else {
        setState(() => _isLoading = false);
        _showSnackBar("Failed to delete client", Colors.red);
      }
    }
  }

  // --- Logic Getters ---
  int get _totalDevices => _allClients.fold(0, (sum, item) => sum + (int.tryParse(item['deviceCount'].toString()) ?? 0));

  String get _topRegion {
    if (_allClients.isEmpty) return "N/A";
    var regions = _allClients.map((c) => c['location'].toString().toLowerCase()).toList();
    var freq = <dynamic, int>{};
    for (var r in regions) { freq[r] = (freq[r] ?? 0) + 1; }
    return freq.entries.reduce((a, b) => a.value > b.value ? a : b).key.toString();
  }

  String get _maxDeviceCity {
    if (_allClients.isEmpty) return "N/A";
    var cityDeviceMap = <String, int>{};
    for (var client in _allClients) {
      String city = client['location'] ?? 'Unknown';
      int devices = int.tryParse(client['deviceCount'].toString()) ?? 0;
      cityDeviceMap[city] = (cityDeviceMap[city] ?? 0) + devices;
    }
    var topEntry = cityDeviceMap.entries.reduce((a, b) => a.value > b.value ? a : b);
    return "${topEntry.key} (${topEntry.value})";
  }

  void _filterSearch(String query) {
    setState(() {
      _filteredClients = _allClients.where((client) {
        final company = client['companyName']?.toLowerCase() ?? '';
        final vendor = client['vendorID']?.toLowerCase() ?? '';
        return company.contains(query.toLowerCase()) || vendor.contains(query.toLowerCase());
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    bool isMobile = MediaQuery.of(context).size.width < 900;

    if (_isLoading && _allClients.isEmpty) return const Center(child: CircularProgressIndicator());
    if (_error != null) return Center(child: Text("❌ $_error"));

    return Scaffold(
      backgroundColor: isMobile ? Colors.grey[100] : Colors.white,
      appBar: isMobile
          ? AppBar(
        title: const Text("Client Deployments", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Colors.indigo),
        actions: [IconButton(icon: const Icon(Icons.download), onPressed: _downloadCSV)],
      )
          : null,
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: EdgeInsets.all(isMobile ? 12 : 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!isMobile) _buildDesktopHeader(),
                const SizedBox(height: 15),
                _buildHistoryLog(),
                const SizedBox(height: 15),
                _buildMetricCards(isMobile),
                const SizedBox(height: 15),
                _buildSearchBar(),
                const SizedBox(height: 20),
                _filteredClients.isEmpty
                    ? const Center(child: Padding(padding: EdgeInsets.all(40.0), child: Text("No clients match your search")))
                    : isMobile ? _buildMobileList() : _buildDesktopTable(),
                const SizedBox(height: 50),
              ],
            ),
          ),
          if (_isLoading) Container(color: Colors.black12, child: const Center(child: CircularProgressIndicator())),
        ],
      ),
    );
  }

  // --- Sub-Widgets (Still here because they rely on State/Logic) ---

  Widget _buildHistoryLog() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(children: [Icon(Icons.history, color: Colors.indigo), SizedBox(width: 8), Text("Deployment History Log", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))]),
        const SizedBox(height: 15),
        Container(
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.withOpacity(0.2))),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _chronologicalHistory.length > 5 ? 5 : _chronologicalHistory.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final log = _chronologicalHistory[index];
              return ListTile(
                leading: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text(log['deploymentDate']?.split('-').last ?? '--', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)),
                  Text(log['deploymentDate']?.split('-')[1] ?? '--', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                ]),
                title: Text("New Deployment: ${log['companyName']}"),
                subtitle: Text("Location: ${log['location']} • ${log['deviceCount']} devices"),
                trailing: const Icon(Icons.check_circle, color: Colors.green, size: 16),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCards(bool isMobile) {
    final metrics = [
      MetricItem("Total Clients", _allClients.length.toString(), Icons.people, Colors.indigo),
      MetricItem("Managed Devices", _totalDevices.toString(), Icons.developer_board, Colors.orange),
      MetricItem("Top Region", _topRegion, Icons.map, Colors.green),
      MetricItem("Max City Load", _maxDeviceCity, Icons.location_city, Colors.purple),
    ];

    if (isMobile) {
      return Column(children: metrics.map((m) => Padding(padding: const EdgeInsets.only(bottom: 12), child: DashboardWidgets.buildMetricCard(title: m.title, value: m.value, icon: m.icon, color: m.color, isMobile: isMobile))).toList());
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, crossAxisSpacing: 20, mainAxisExtent: 100),
      itemCount: metrics.length,
      itemBuilder: (context, index) {
        final m = metrics[index];
        return DashboardWidgets.buildMetricCard(title: m.title, value: m.value, icon: m.icon, color: m.color, isMobile: isMobile);
      },
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
      child: TextField(
        controller: _searchController,
        onChanged: _filterSearch,
        decoration: InputDecoration(
          hintText: "Search by Company or Vendor ID...",
          prefixIcon: const Icon(Icons.search, color: Colors.indigo),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(vertical: 15),
        ),
      ),
    );
  }

  Widget _buildDesktopHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text("Client Deployments", style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
        ElevatedButton.icon(
          onPressed: _filteredClients.isEmpty ? null : _downloadCSV,
          icon: const Icon(Icons.download),
          label: const Text("Export Search Results"),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12)),
        ),
      ],
    );
  }

  Widget _buildMobileList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _filteredClients.length,
      itemBuilder: (context, index) {
        final client = _filteredClients[index];
        return Card(
          elevation: 2,
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ExpansionTile(
            leading: const CircleAvatar(backgroundColor: Colors.indigo, child: Icon(Icons.business, color: Colors.white, size: 20)),
            title: Text(client['companyName'] ?? 'Unknown Co', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), overflow: TextOverflow.ellipsis),
            subtitle: Text("ID: ${client['vendorID']}", style: const TextStyle(fontSize: 13)),
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(color: Colors.indigo.withOpacity(0.02), borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(12), bottomRight: Radius.circular(12))),
                child: Column(children: [
                  DashboardWidgets.infoRow(Icons.person, "Owner", "${client['firstName']} ${client['lastName']}"),
                  DashboardWidgets.infoRow(Icons.email, "Email", client['email']),
                  DashboardWidgets.infoRow(Icons.location_on, "Location", client['location']),
                  DashboardWidgets.infoRow(Icons.devices, "Device Count", client['deviceCount'].toString()),
                  DashboardWidgets.infoRow(Icons.calendar_today, "Deployed", client['deploymentDate']),
                  const Divider(height: 24),
                  Align(alignment: Alignment.centerRight, child: TextButton.icon(onPressed: () => _deleteClient(client['vendorID'], client['companyName']), icon: const Icon(Icons.delete_outline, color: Colors.red), label: const Text("Delete Client", style: TextStyle(color: Colors.red))))
                ]),
              )
            ],
          ),
        );
      },
    );
  }

  Widget _buildDesktopTable() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.grey.withOpacity(0.2)), borderRadius: BorderRadius.circular(12)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width - 48),
            child: DataTable(
              headingRowColor: MaterialStateProperty.all(Colors.indigo.withOpacity(0.05)),
              columns: const [
                DataColumn(label: Text('Vendor ID', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Client Name', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Company', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Devices', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Location', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Deployment Date', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
              ],
              rows: _filteredClients.map((client) {
                return DataRow(cells: [
                  DataCell(Text(client['vendorID'] ?? '', style: const TextStyle(color: Colors.indigo, fontWeight: FontWeight.w600))),
                  DataCell(Text("${client['firstName']} ${client['lastName']}")),
                  DataCell(Text(client['companyName'] ?? '')),
                  DataCell(Text(client['deviceCount'].toString())),
                  DataCell(Text(client['location'] ?? '')),
                  DataCell(Text(client['deploymentDate'] ?? '')),
                  DataCell(IconButton(icon: const Icon(Icons.delete_outline, color: Colors.redAccent), onPressed: () => _deleteClient(client['vendorID'], client['companyName']))),
                ]);
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _downloadCSV() async {
    if (_filteredClients.isEmpty) return;
    List<List<dynamic>> rows = [["Vendor ID", "First Name", "Last Name", "Email", "Company", "Devices", "Location", "Date"]];
    for (var c in _filteredClients) {
      rows.add([c['vendorID'], c['firstName'], c['lastName'], c['email'], c['companyName'], c['deviceCount'], c['location'], c['deploymentDate']]);
    }
    String csvData = const ListToCsvConverter().convert(rows);
    try {
      if (kIsWeb) {
        final bytes = utf8.encode(csvData);
        final blob = html.Blob([bytes], 'text/csv');
        final url = html.Url.createObjectUrlFromBlob(blob);
        html.AnchorElement(href: url)..setAttribute("download", "clients_export_${DateTime.now().millisecondsSinceEpoch}.csv")..click();
        html.Url.revokeObjectUrl(url);
      } else if (Platform.isWindows) {
        String? path = await FilePicker.platform.saveFile(fileName: 'clients_export.csv', type: FileType.custom, allowedExtensions: ['csv']);
        if (path != null) await File(path).writeAsString(csvData);
      } else {
        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/clients_export.csv');
        await file.writeAsString(csvData);
        await Share.shareXFiles([XFile(file.path)]);
      }
      _showSnackBar("Export successful", Colors.green);
    } catch (e) {
      _showSnackBar("Error: $e", Colors.redAccent);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
  }
}