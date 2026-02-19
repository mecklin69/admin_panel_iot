import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../aws/amplify_service.dart';

class FirmwareFlashPage extends StatefulWidget {
  const FirmwareFlashPage({super.key});

  @override
  State<FirmwareFlashPage> createState() => _FirmwareFlashPageState();
}

class _FirmwareFlashPageState extends State<FirmwareFlashPage> {
  String? _selectedVendorID;
  PlatformFile? _selectedFile;
  List<String> _availableVendorIDs = [];
  List<dynamic> _persistentInventory = [];
  bool _isLoading = true;

  // Custom Colors (Colorful Palette)
  final Color primaryColor = const Color(0xFF006064); // Dark Teal
  final Color accentColor = const Color(0xFFFF6D00);  // Deep Orange
  final Color surfaceColor = const Color(0xFFF4F7F6);

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  // --- REFRESH DATA FROM AWS ---
  Future<void> _refreshData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        AmplifyService.fetchAllClients(),
        AmplifyService.fetchFirmwareMappings(),
      ]);

      setState(() {
        _availableVendorIDs = results[0]
            .map((c) => c['vendorID'].toString())
            .where((id) => id.isNotEmpty)
            .toList();
        _persistentInventory = results[1];
        _isLoading = false;
      });
    } catch (e) {
      _showSnackBar("Sync Error: $e", Colors.redAccent);
      setState(() => _isLoading = false);
    }
  }

  // --- SAVE TO AWS ---
  Future<void> _handleRegister() async {
    if (_selectedVendorID == null || _selectedFile == null) {
      _showSnackBar("Missing Vendor ID or Binary File", accentColor);
      return;
    }

    setState(() => _isLoading = true);

    final success = await AmplifyService.pushFirmwareMapping(
      vendorID: _selectedVendorID!,
      fileName: _selectedFile!.name,
      fileSize: "${(_selectedFile!.size / 1024).toStringAsFixed(2)} KB",
    );

    if (success) {
      _selectedFile = null;
      await _refreshData(); // Updates mapping history list
      _showSnackBar("Firmware successfully deployed to Cloud", Colors.teal);
    } else {
      setState(() => _isLoading = false);
      _showSnackBar("AWS Database Error", Colors.redAccent);
    }
  }

  Future<void> _pickFirmware() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['bin', 'hex', 'ota', 'zip'],
    );
    if (result != null) setState(() => _selectedFile = result.files.first);
  }

  void _showSnackBar(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg, style: const TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: color,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(15),
        )
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isMobile = MediaQuery.of(context).size.width < 700;

    return Scaffold(
      backgroundColor: surfaceColor,
      body: _isLoading && _persistentInventory.isEmpty
          ? Center(child: CircularProgressIndicator(color: primaryColor))
          : RefreshIndicator(
        color: accentColor,
        onRefresh: _refreshData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.all(isMobile ? 16 : 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 35),
              _buildUploadCard(isMobile),
              const SizedBox(height: 45),
              _buildHistorySection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("OTA Control Center",
            style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: primaryColor, letterSpacing: -0.5)),
        const SizedBox(height: 5),
        Container(width: 60, height: 4, decoration: BoxDecoration(color: accentColor, borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 10),
        const Text("Deploy and track firmware binaries across your global hardware fleet.",
            style: TextStyle(fontSize: 15, color: Colors.black54)),
      ],
    );
  }

  Widget _buildUploadCard(bool isMobile) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: primaryColor.withOpacity(0.08), blurRadius: 30, offset: const Offset(0, 10))],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Styled Dropdown
          DropdownButtonFormField<String>(
            value: _selectedVendorID,
            hint: const Text("Select Targeted Vendor"),
            decoration: _inputDecoration(Icons.router_rounded, "Hardware Target"),
            items: _availableVendorIDs.map((id) => DropdownMenuItem(value: id, child: Text(id))).toList(),
            onChanged: (val) => setState(() => _selectedVendorID = val),
          ),
          const SizedBox(height: 20),

          // Custom File Picker UI
          _filePickerUI(),
          const SizedBox(height: 30),

          // Gradient Button
          InkWell(
            onTap: _isLoading ? null : _handleRegister,
            child: Container(
              height: 60,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [primaryColor, primaryColor.withOpacity(0.8)]),
                borderRadius: BorderRadius.circular(15),
                boxShadow: [BoxShadow(color: primaryColor.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Center(
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.cloud_upload_rounded, color: Colors.white),
                    SizedBox(width: 10),
                    Text("REGISTER FIRMWARE", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _filePickerUI() {
    return GestureDetector(
      onTap: _pickFirmware,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: primaryColor.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: accentColor.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(Icons.file_copy_rounded, color: accentColor, size: 24),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _selectedFile == null ? "Binary Selection" : _selectedFile!.name,
                    style: TextStyle(fontWeight: FontWeight.bold, color: _selectedFile == null ? Colors.black45 : Colors.black87),
                  ),
                  Text(_selectedFile == null ? "Tap to browse local storage" : "${(_selectedFile!.size / 1024).toStringAsFixed(1)} KB",
                      style: const TextStyle(fontSize: 12, color: Colors.black38)),
                ],
              ),
            ),
            Icon(Icons.add_circle_outline_rounded, color: primaryColor),
          ],
        ),
      ),
    );
  }

  Widget _buildHistorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text("Live Deployment History", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87)),
            const Spacer(),
            IconButton(icon: Icon(Icons.refresh_rounded, color: primaryColor), onPressed: _refreshData),
          ],
        ),
        const SizedBox(height: 15),
        if (_persistentInventory.isEmpty)
          _emptyStateUI()
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _persistentInventory.length,
            itemBuilder: (context, index) {
              final item = _persistentInventory[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.black.withOpacity(0.05)),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  leading: CircleAvatar(
                    backgroundColor: surfaceColor,
                    child: Icon(Icons.developer_board_rounded, color: primaryColor, size: 20),
                  ),
                  title: Text("${item['vendorID']}", style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("${item['fileName']} • ${item['uploadDate']}"),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                    child: const Text("SYNCED", style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _emptyStateUI() {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 40),
          Icon(Icons.inventory_2_outlined, size: 60, color: Colors.black12),
          const SizedBox(height: 10),
          const Text("No firmware mappings in DynamoDB", style: TextStyle(color: Colors.black26)),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(IconData icon, String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: primaryColor.withOpacity(0.6)),
      prefixIcon: Icon(icon, color: primaryColor),
      filled: true,
      fillColor: surfaceColor,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: primaryColor, width: 2)),
    );
  }
}