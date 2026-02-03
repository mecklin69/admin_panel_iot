import 'package:flutter/material.dart';
import '../aws/amplify_service.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  bool _isLoading = true;
  List<dynamic> _clients = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadClients();
  }

  Future<void> _loadClients() async {
    try {
      final data = await AmplifyService.fetchAllClients();
      setState(() {
        _clients = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return Center(child: Text("❌ $_error"));
    if (_clients.isEmpty) return const Center(child: Text("No clients found"));

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Client Deployments", style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          Expanded(child: _buildTable()),
        ],
      ),
    );
  }

  Widget _buildTable() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: MaterialStateProperty.all(Colors.indigo.withOpacity(0.1)),
        columns: const [
          DataColumn(label: Text('Vendor ID')),
          DataColumn(label: Text('Client')),
          DataColumn(label: Text('Email')),
          DataColumn(label: Text('Company')),
          DataColumn(label: Text('Devices')),
          DataColumn(label: Text('Location')),
          DataColumn(label: Text('Date')),
        ],
        rows: _clients.map((client) {
          return DataRow(cells: [
            DataCell(Text(client['vendorID'] ?? '')),
            DataCell(Text("${client['firstName']} ${client['lastName']}")),
            DataCell(Text(client['email'] ?? '')),
            DataCell(Text(client['companyName'] ?? '')),
            DataCell(Text(client['deviceCount'].toString())),
            DataCell(Text(client['location'] ?? '')),
            DataCell(Text(client['deploymentDate'] ?? '')),
          ]);
        }).toList(),
      ),
    );
  }
}