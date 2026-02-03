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

  // Visibility toggles
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  // Controllers
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
    _firstNameController.dispose();
    _lastNameController.dispose();
    _locationController.dispose();
    _companyController.dispose();
    _deviceCountController.dispose();
    _vendorIdController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  // UI Helpers
  InputDecoration _glassInput(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.indigo),
      prefixIcon: Icon(icon, color: Colors.indigoAccent),
      filled: true,
      fillColor: Colors.indigo.withOpacity(0.05),
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

  Widget _passwordSuffix(bool isVisible, VoidCallback onToggle) {
    return IconButton(
      icon: Icon(isVisible ? Icons.visibility : Icons.visibility_off, color: Colors.indigoAccent),
      onPressed: onToggle,
    );
  }

  Widget _reviewItem(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.black54, fontSize: 14)),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: isBold ? Colors.indigo : Colors.black87,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  // Logic Methods
  void _showReviewDialog() {
    if (_formKey.currentState!.validate()) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Icon(Icons.fact_check, color: Colors.indigo),
                SizedBox(width: 10),
                Text("Review Deployment"),
              ],
            ),
            content: SizedBox(
              width: 400,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("Verify details before final initialization.",
                      style: TextStyle(color: Colors.grey, fontSize: 13)),
                  const Divider(height: 30),
                  _reviewItem("Client", "${_firstNameController.text} ${_lastNameController.text}"),
                  _reviewItem("Email", _emailController.text),
                  _reviewItem("Company", _companyController.text),
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
                child: const Text("CONFIRM & CREATE"),
              ),
            ],
          );
        },
      );
    }
  }

  void _finalizeAccount() async {
    setState(() => _isLoading = true);
    try {
      bool success = await AmplifyService.pushAccountToDynamo(
        vendorID: _vendorIdController.text,
        firstName: _firstNameController.text,
        lastName: _lastNameController.text,
        email: _emailController.text,
        password: _passwordController.text,
        location: _locationController.text,
        companyName: _companyController.text,
        deviceCount: int.tryParse(_deviceCountController.text) ?? 0,
        date: _dateController.text,
      );

      if (success) {
        _showSuccessUI();
        _formKey.currentState?.reset();
        _emailController.clear();
        _passwordController.clear();
        _confirmPasswordController.clear();
      } else {
        _showErrorUI("Database sync failed.");
      }
    } catch (e) {
      _showErrorUI("Error: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSuccessUI() {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("🚀 Account Provisioned!"), backgroundColor: Colors.green));
  }

  void _showErrorUI(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("❌ $message"), backgroundColor: Colors.redAccent));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[50],
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: Container(
            width: 700,
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10))],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Register New Client", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.indigo)),
                  const Text("Provision new IoT deployment accounts", style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 40),
                  Row(
                    children: [
                      Expanded(child: TextFormField(controller: _firstNameController, decoration: _glassInput("First Name", Icons.person))),
                      const SizedBox(width: 20),
                      Expanded(child: TextFormField(controller: _lastNameController, decoration: _glassInput("Last Name", Icons.person_outline))),
                    ],
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _emailController,
                    decoration: _glassInput("Email Address", Icons.email),
                    validator: (v) => (v == null || !v.contains('@')) ? 'Invalid email' : null,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _passwordController,
                          obscureText: !_isPasswordVisible,
                          decoration: _glassInput("Password", Icons.lock).copyWith(
                            suffixIcon: _passwordSuffix(_isPasswordVisible, () => setState(() => _isPasswordVisible = !_isPasswordVisible)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: TextFormField(
                          controller: _confirmPasswordController,
                          obscureText: !_isConfirmPasswordVisible,
                          decoration: _glassInput("Confirm Password", Icons.lock_clock).copyWith(
                            suffixIcon: _passwordSuffix(_isConfirmPasswordVisible, () => setState(() => _isConfirmPasswordVisible = !_isConfirmPasswordVisible)),
                          ),
                          validator: (v) => v != _passwordController.text ? "Passwords don't match" : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(child: TextFormField(controller: _locationController, decoration: _glassInput("Location", Icons.location_on))),
                      const SizedBox(width: 20),
                      Expanded(child: TextFormField(controller: _companyController, decoration: _glassInput("Company Name", Icons.business))),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(child: TextFormField(controller: _deviceCountController, decoration: _glassInput("Devices", Icons.developer_board), keyboardType: TextInputType.number)),
                      const SizedBox(width: 20),
                      Expanded(child: TextFormField(controller: _vendorIdController, decoration: _glassInput("Vendor ID", Icons.verified_user))),
                    ],
                  ),
                  const SizedBox(height: 40),
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
  }
}