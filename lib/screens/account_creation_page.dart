import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../aws/amplify_service.dart';

class AccountCreationPage extends StatefulWidget {
  const AccountCreationPage({super.key});

  @override
  State<AccountCreationPage> createState() => _AccountCreationPageState();
}

class _AccountCreationPageState extends State<AccountCreationPage> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _companyController = TextEditingController();
  final TextEditingController _deviceCountController = TextEditingController();
  final TextEditingController _vendorIdController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _dateController = TextEditingController(
    text: DateFormat('yyyy-MM-dd').format(DateTime.now()),
  );

  @override
  void dispose() {
    // ... all disposals stay the same
    super.dispose();
  }

  InputDecoration _glassInput(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.indigo, fontSize: 14),
      prefixIcon: Icon(icon, color: Colors.indigoAccent, size: 20),
      filled: true,
      fillColor: Colors.indigo.withOpacity(0.05),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.indigo.withOpacity(0.1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.indigoAccent, width: 2),
      ),
    );
  }

  // --- UI Helpers for Layout ---

  /// Helper to create a Row on Desktop and a Column on Mobile
  Widget _responsiveFieldGroup(bool isMobile, List<Widget> children) {
    if (isMobile) {
      return Column(
        children: children.map((w) => Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: w
        )).toList(),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        children: children.map((w) => Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: children.last == w ? 0 : 20),
            child: w,
          ),
        )).toList(),
      ),
    );
  }

  // Logic methods (_showReviewDialog, _finalizeAccount, etc.) stay exactly the same...
  void _showReviewDialog() {
    if (_formKey.currentState!.validate()) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          // Responsive width for dialog
          double screenWidth = MediaQuery.of(context).size.width;
          return AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Icon(Icons.fact_check, color: Colors.indigo),
                SizedBox(width: 10),
                Text("Review", style: TextStyle(fontSize: 18)),
              ],
            ),
            content: SizedBox(
              width: screenWidth > 600 ? 400 : screenWidth * 0.8,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _reviewItem("Client", "${_firstNameController.text} ${_lastNameController.text}"),
                  _reviewItem("Vendor ID", _vendorIdController.text, isBold: true),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text("EDIT")),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
                onPressed: () {
                  Navigator.pop(context);
                  _finalizeAccount();
                },
                child: const Text("CONFIRM"),
              ),
            ],
          );
        },
      );
    }
  }

  Widget _reviewItem(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.black54, fontSize: 13)),
          Flexible(child: Text(value, textAlign: TextAlign.right, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal, fontSize: 13))),
        ],
      ),
    );
  }

  void _finalizeAccount() async { /* ... same as your code ... */ }
  void _showSuccessUI() { /* ... same as your code ... */ }
  void _showErrorUI(String message) { /* ... same as your code ... */ }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        bool isMobile = constraints.maxWidth < 700;

        return Scaffold(
          backgroundColor: Colors.grey[50],
          body: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(isMobile ? 16.0 : 32.0),
              child: Container(
                // Max width 700 on desktop, full width on mobile
                constraints: const BoxConstraints(maxWidth: 700),
                padding: EdgeInsets.all(isMobile ? 24 : 40),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 20,
                        offset: const Offset(0, 10)
                    )
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          "Register New Client",
                          style: TextStyle(
                              fontSize: isMobile ? 24 : 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.indigo
                          )
                      ),
                      const Text("Provision new IoT deployment accounts", style: TextStyle(color: Colors.grey)),
                      const SizedBox(height: 32),

                      _responsiveFieldGroup(isMobile, [
                        TextFormField(controller: _firstNameController, decoration: _glassInput("First Name", Icons.person)),
                        TextFormField(controller: _lastNameController, decoration: _glassInput("Last Name", Icons.person_outline)),
                      ]),

                      TextFormField(
                        controller: _emailController,
                        decoration: _glassInput("Email Address", Icons.email),
                        validator: (v) => (v == null || !v.contains('@')) ? 'Invalid email' : null,
                      ),
                      const SizedBox(height: 20),

                      _responsiveFieldGroup(isMobile, [
                        TextFormField(
                          controller: _passwordController,
                          obscureText: !_isPasswordVisible,
                          decoration: _glassInput("Password", Icons.lock).copyWith(
                            suffixIcon: _passwordSuffix(_isPasswordVisible, () => setState(() => _isPasswordVisible = !_isPasswordVisible)),
                          ),
                        ),
                        TextFormField(
                          controller: _confirmPasswordController,
                          obscureText: !_isConfirmPasswordVisible,
                          decoration: _glassInput("Confirm Password", Icons.lock_clock).copyWith(
                            suffixIcon: _passwordSuffix(_isConfirmPasswordVisible, () => setState(() => _isConfirmPasswordVisible = !_isConfirmPasswordVisible)),
                          ),
                          validator: (v) => v != _passwordController.text ? "Passwords don't match" : null,
                        ),
                      ]),

                      _responsiveFieldGroup(isMobile, [
                        TextFormField(controller: _locationController, decoration: _glassInput("Location", Icons.location_on)),
                        TextFormField(controller: _companyController, decoration: _glassInput("Company Name", Icons.business)),
                      ]),

                      _responsiveFieldGroup(isMobile, [
                        TextFormField(controller: _deviceCountController, decoration: _glassInput("Devices", Icons.developer_board), keyboardType: TextInputType.number),
                        TextFormField(controller: _vendorIdController, decoration: _glassInput("Vendor ID", Icons.verified_user)),
                      ]),

                      const SizedBox(height: 20),
                      InkWell(
                        onTap: _showReviewDialog,
                        child: Container(
                          height: 60,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            gradient: const LinearGradient(colors: [Colors.indigo, Colors.blueAccent]),
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text("INITIALIZE ACCOUNT", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _passwordSuffix(bool isVisible, VoidCallback onToggle) {
    return IconButton(
      icon: Icon(isVisible ? Icons.visibility : Icons.visibility_off, color: Colors.indigoAccent, size: 20),
      onPressed: onToggle,
    );
  }
}