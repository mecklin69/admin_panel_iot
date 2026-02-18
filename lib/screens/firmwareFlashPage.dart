import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../aws/amplify_service.dart';

class FirmwareFlashPage extends StatefulWidget {
  const FirmwareFlashPage({super.key});

  @override
  State<FirmwareFlashPage> createState() => _FirmwareFlashPageState();
}

class _FirmwareFlashPageState extends State<FirmwareFlashPage> {
  // State variables
  String? _selectedVendorID;
  PlatformFile? _selectedFile;
  List<String> _availableVendorIDs = [];
  List<dynamic> _persistentInventory = []; // Now stores data from DB
  bool _isLoadingVendors = true;

  // Tracking inventory locally
  final List<Map<String, String>> _firmwareInventory = [];

  @override
  void initState() {
    super.initState();
    _fetchExistingVendors();
  }

  // --- Logic: Fetch IDs from Amplify ---
  Future<void> _fetchExistingVendors() async {
    try {
      final clients = await AmplifyService.fetchAllClients();
      setState(() {
        // Extract only the vendorID strings and remove duplicates
        _availableVendorIDs = clients
            .map((c) => c['vendorID']?.toString() ?? '')
            .where((id) => id.isNotEmpty)
            .toList();
        _isLoadingVendors = false;
      });
    } catch (e) {
      debugPrint("Error fetching vendors: $e");
      setState(() => _isLoadingVendors = false);
    }
  }

  // --- Logic: Pick Firmware File ---
  Future<void> _pickFirmware() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['bin', 'hex', 'ota', 'zip'],
    );

    if (result != null) {
      setState(() => _selectedFile = result.files.first);
    }
  }

  // --- Logic: Register ---
  void _registerFirmware() {
    if (_selectedVendorID == null || _selectedFile == null) {
      _showSnackBar("Select a Vendor and a File first!", Colors.orange);
      return;
    }

    setState(() {
      _firmwareInventory.insert(0, {
        "vendorID": _selectedVendorID!,
        "fileName": _selectedFile!.name,
        "size": "${(_selectedFile!.size / 1024).toStringAsFixed(2)} KB",
        "date": DateTime.now().toString().split('.')[0],
      });
      _selectedFile = null; // Reset file but keep vendor for convenience
    });
    _showSnackBar("Firmware mapped to $_selectedVendorID", Colors.green);
  }

  void _showSnackBar(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  @override
  Widget build(BuildContext context) {
    bool isMobile = MediaQuery.of(context).size.width < 700;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isMobile ? 16 : 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Firmware Management",
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.indigo)),
            const Text("Select a provisioned Vendor ID to associate with custom firmware."),
            const SizedBox(height: 30),

            // --- SECTION 1: UPLOAD & ASSIGN ---
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.indigo.withOpacity(0.03),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.indigo.withOpacity(0.1)),
              ),
              child: Column(
                children: [
                  // --- VENDOR PICKER (DROPDOWN) ---
                  _isLoadingVendors
                      ? const LinearProgressIndicator()
                      : DropdownButtonFormField<String>(
                    value: _selectedVendorID,
                    hint: const Text("Select Available Vendor ID"),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      prefixIcon: const Icon(Icons.badge, color: Colors.indigo),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    items: _availableVendorIDs.map((id) {
                      return DropdownMenuItem(value: id, child: Text(id));
                    }).toList(),
                    onChanged: (val) => setState(() => _selectedVendorID = val),
                  ),

                  const SizedBox(height: 15),

                  // File Selection Area
                  _filePickerUI(),

                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton.icon(
                      onPressed: _registerFirmware,
                      icon: const Icon(Icons.link, color: Colors.white),
                      label: const Text("MAP FIRMWARE TO VENDOR", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // --- SECTION 2: TRACKING ---
            const Text("Firmware Mapping History", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            _buildInventoryList(),
          ],
        ),
      ),
    );
  }

  Widget _filePickerUI() {
    return InkWell(
      onTap: _pickFirmware,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Icon(Icons.file_present, color: _selectedFile == null ? Colors.grey : Colors.orange),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _selectedFile == null ? "Select Firmware Binary" : _selectedFile!.name,
                style: TextStyle(color: _selectedFile == null ? Colors.grey : Colors.black, fontWeight: FontWeight.w500),
              ),
            ),
            const Icon(Icons.search, color: Colors.indigo),
          ],
        ),
      ),
    );
  }

  Widget _buildInventoryList() {
    if (_firmwareInventory.isEmpty) {
      return const Center(child: Text("No firmware mappings recorded in this session."));
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _firmwareInventory.length,
      itemBuilder: (context, index) {
        final item = _firmwareInventory[index];
        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(side: BorderSide(color: Colors.grey.shade200), borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading: const Icon(Icons.app_settings_alt, color: Colors.orange),
            title: Text("Vendor: ${item['vendorID']}", style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text("${item['fileName']} • ${item['date']}"),
            trailing: IconButton(
              icon: const Icon(Icons.close, size: 20),
              onPressed: () => setState(() => _firmwareInventory.removeAt(index)),
            ),
          ),
        );
      },
    );
  }
}