import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../aws/amplify_service.dart';
import 'dart:convert';
import 'dart:io' show File, Platform; // Use 'show' to be explicit
import 'package:flutter/foundation.dart' show kIsWeb;

// This is the trick for Web
import 'package:universal_html/html.dart' as html;
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
    super.initState();
    _loadClients();
  }

  Future<void> _loadClients() async {
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

  void _filterSearch(String query) {
    setState(() {
      _filteredClients = _allClients.where((client) {
        final company = client['companyName']?.toLowerCase() ?? '';
        final vendor = client['vendorID']?.toLowerCase() ?? '';
        final searchLower = query.toLowerCase();
        return company.contains(searchLower) || vendor.contains(searchLower);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    bool isMobile = MediaQuery.of(context).size.width < 800;

    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return Center(child: Text("❌ $_error"));

    return Scaffold(
      backgroundColor: isMobile ? Colors.grey[100] : Colors.white,
      appBar: isMobile ? AppBar(
        title: const Text("Deployments"),
        actions: [IconButton(icon: const Icon(Icons.download), onPressed: _downloadCSV)],
      ) : null,
      body: Padding(
        padding: EdgeInsets.all(isMobile ? 12 : 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isMobile) _buildDesktopHeader(),
            const SizedBox(height: 15),
            _buildSearchBar(),
            const SizedBox(height: 20),
            Expanded(
              child: _filteredClients.isEmpty
                  ? const Center(child: Text("No clients match your search"))
                  : isMobile ? _buildMobileList() : _buildDesktopTable(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
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
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.indigo,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileList() {
    return ListView.builder(
      itemCount: _filteredClients.length,
      padding: const EdgeInsets.only(bottom: 100), // Space for FAB if any
      itemBuilder: (context, index) {
        final client = _filteredClients[index];
        return Card(
          elevation: 2,
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Theme(
            // This removes the unwanted borders that ExpansionTile sometimes adds
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              // Key Fix: Wrap leading/title in a way that handles constraints
              leading: const CircleAvatar(
                backgroundColor: Colors.indigo,
                child: Icon(Icons.business, color: Colors.white, size: 20),
              ),
              title: Text(
                client['companyName'] ?? 'Unknown Co',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                overflow: TextOverflow.ellipsis, // Prevents text from pushing width
              ),
              subtitle: Text(
                "ID: ${client['vendorID']}",
                style: const TextStyle(fontSize: 13),
              ),
              children: [
                Container(
                  width: double.infinity, // Ensures internal content uses full width
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Colors.indigo.withOpacity(0.02),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(12),
                      bottomRight: Radius.circular(12),
                    ),
                  ),
                  child: Column(
                    children: [
                      _infoRow(Icons.person, "Owner", "${client['firstName']} ${client['lastName']}"),
                      _infoRow(Icons.email, "Email", client['email']),
                      _infoRow(Icons.location_on, "Location", client['location']),
                      _infoRow(Icons.devices, "Device Count", client['deviceCount'].toString()),
                      _infoRow(Icons.calendar_today, "Deployed", client['deploymentDate']),
                    ],
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _infoRow(IconData icon, String label, String? val) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        Icon(icon, size: 16, color: Colors.indigo),
        const SizedBox(width: 8),
        Text("$label: ", style: const TextStyle(fontWeight: FontWeight.bold)),
        Text(val ?? '--')
      ]),
    );
  }

  // --- DESKTOP VIEW ---
  Widget _buildDesktopTable() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal, // Key for horizontal overflow
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical, // Key for vertical overflow
            child: ConstrainedBox(
              constraints: BoxConstraints(
                // Ensures the table is at least as wide as the container
                minWidth: MediaQuery.of(context).size.width - 48,
              ),
              child: DataTable(
                headingRowColor: MaterialStateProperty.all(Colors.indigo.withOpacity(0.05)),
                dataRowMaxHeight: 60,
                headingRowHeight: 55,
                horizontalMargin: 20,
                columnSpacing: 40, // Adjust this to space out columns better
                columns: const [
                  DataColumn(label: Text('Vendor ID', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Client Name', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Company', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Devices', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Location', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Deployment Date', style: TextStyle(fontWeight: FontWeight.bold))),
                ],
                rows: _filteredClients.map((client) {
                  return DataRow(cells: [
                    DataCell(Text(client['vendorID'] ?? '', style: const TextStyle(color: Colors.indigo, fontWeight: FontWeight.w600))),
                    DataCell(Text("${client['firstName']} ${client['lastName']}")),
                    DataCell(Text(client['companyName'] ?? '')),
                    DataCell(Text(client['deviceCount'].toString())),
                    DataCell(Text(client['location'] ?? '')),
                    DataCell(Text(client['deploymentDate'] ?? '')),
                  ]);
                }).toList(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- DOWNLOAD LOGIC ---
  // --- DOWNLOAD LOGIC ---
  Future<void> _downloadCSV() async {
    if (_filteredClients.isEmpty) return;

    // 1. Prepare data rows
    List<List<dynamic>> rows = [
      ["Vendor ID", "First Name", "Last Name", "Email", "Company", "Devices", "Location", "Date"]
    ];

    for (var c in _filteredClients) {
      rows.add([
        c['vendorID'],
        c['firstName'],
        c['lastName'],
        c['email'],
        c['companyName'],
        c['deviceCount'],
        c['location'],
        c['deploymentDate']
      ]);
    }

    // 2. Convert to CSV String
    String csvData = const ListToCsvConverter().convert(rows);

    try {
      if (kIsWeb) {
        // --- WEB LOGIC ---
        final bytes = utf8.encode(csvData);
        final blob = html.Blob([bytes], 'text/csv');
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.AnchorElement(href: url)
          ..setAttribute("download", "clients_export_${DateTime.now().millisecondsSinceEpoch}.csv")
          ..click();
        html.Url.revokeObjectUrl(url);

        _showSnackBar("Download started", Colors.green);
      }
      else if (Platform.isWindows) {
        // --- WINDOWS LOGIC ---
        String? path = await FilePicker.platform.saveFile(
          dialogTitle: 'Save Client Export',
          fileName: 'clients_export.csv',
          type: FileType.custom,
          allowedExtensions: ['csv'],
        );

        if (path != null) {
          final file = File(path);
          await file.writeAsString(csvData);
          _showSnackBar("File saved to $path", Colors.green);
        }
      }
      else {
        // --- MOBILE LOGIC (Android/iOS) ---
        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/clients_export.csv');
        await file.writeAsString(csvData);
        await Share.shareXFiles([XFile(file.path)], text: 'Client Export');
      }
    } catch (e) {
      debugPrint("Download error: $e");
      _showSnackBar("Error saving file: $e", Colors.redAccent);
    }
  }

  // Small helper for cleaner code
  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }
}