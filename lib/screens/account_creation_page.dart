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

  // --- Logic Methods ---

  void _finalizeAccount() async {
    setState(() => _isLoading = true);
    try {
      final success = await AmplifyService.pushAccountToDynamo(
        vendorID: _vendorIdController.text.trim(),
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        location: _locationController.text.trim(),
        companyName: _companyController.text.trim(),
        deviceCount: int.tryParse(_deviceCountController.text) ?? 0,
        date: _dateController.text,
      );

      if (success) {
        _showSuccessUI();
      } else {
        _showErrorUI("Registration failed. Vendor ID may already exist.");
      }
    } catch (e) {
      _showErrorUI("Network error: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSuccessUI() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Icon(Icons.check_circle, color: Colors.green, size: 60),
        content: const Text("Account initialized successfully on AWS.", textAlign: TextAlign.center),
        actions: [
          Center(
            child: TextButton(
              onPressed: () {
                Navigator.pop(context);
                _formKey.currentState?.reset();
              },
              child: const Text("CONTINUE", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
    );
  }

  void _showErrorUI(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating, // Better for Android modern UI
        margin: const EdgeInsets.all(10),
      ),
    );
  }

  void _showReviewDialog() {
    if (_formKey.currentState!.validate()) {
      // Unfocus keyboard before showing dialog
      FocusScope.of(context).unfocus();

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text("Review Entry", style: TextStyle(color: Colors.indigo)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _reviewItem("Owner", "${_firstNameController.text} ${_lastNameController.text}"),
                  _reviewItem("Company", _companyController.text),
                  _reviewItem("Vendor ID", _vendorIdController.text, isBold: true),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text("EDIT")),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
                onPressed: () { Navigator.pop(context); _finalizeAccount(); },
                child: const Text("CONFIRM", style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      );
    }
  }

  // --- UI Components ---

  InputDecoration _glassInput(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.indigo, fontSize: 14),
      prefixIcon: Icon(icon, color: Colors.indigoAccent, size: 20),
      filled: true,
      fillColor: Colors.indigo.withOpacity(0.05),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.indigo.withOpacity(0.1))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.indigoAccent, width: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      // SafeArea is critical for Android/iOS to avoid status bars and notches
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            bool isMobile = constraints.maxWidth < 700;

            return Center(
              child: SingleChildScrollView(
                // Use BouncingScrollPhysics for a more premium mobile feel
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 16.0 : 32.0,
                    vertical: 24.0
                ),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 700),
                  padding: EdgeInsets.all(isMobile ? 20 : 40),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20)],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Register Client", style: TextStyle(fontSize: isMobile ? 26 : 32, fontWeight: FontWeight.bold, color: Colors.indigo)),
                        const Text("AWS IoT Deployment Provisioning", style: TextStyle(color: Colors.grey)),
                        const SizedBox(height: 30),

                        _buildResponsivePair(isMobile, [
                          _buildField(_firstNameController, "First Name", Icons.person),
                          _buildField(_lastNameController, "Last Name", Icons.person_outline),
                        ]),

                        _buildField(_emailController, "Email", Icons.email, isEmail: true),
                        const SizedBox(height: 20),

                        _buildResponsivePair(isMobile, [
                          _buildPasswordField(_passwordController, "Password", _isPasswordVisible, () => setState(() => _isPasswordVisible = !_isPasswordVisible)),
                          _buildPasswordField(_confirmPasswordController, "Confirm", _isConfirmPasswordVisible, () => setState(() => _isConfirmPasswordVisible = !_isConfirmPasswordVisible), isConfirm: true),
                        ]),

                        _buildResponsivePair(isMobile, [
                          _buildField(_locationController, "Location", Icons.location_on),
                          _buildField(_companyController, "Company", Icons.business),
                        ]),

                        _buildResponsivePair(isMobile, [
                          _buildField(_deviceCountController, "Devices", Icons.developer_board, isNumber: true),
                          _buildField(_vendorIdController, "Vendor ID", Icons.verified_user),
                        ]),

                        const SizedBox(height: 30),

                        // Main Action Button
                        SizedBox(
                          width: double.infinity,
                          height: 55,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _showReviewDialog,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.indigo,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 2,
                            ),
                            child: _isLoading
                                ? const CircularProgressIndicator(color: Colors.white)
                                : const Text("INITIALIZE DEPLOYMENT", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // --- DRY Helpers for Cleaner UI ---

  Widget _buildField(TextEditingController controller, String label, IconData icon, {bool isEmail = false, bool isNumber = false}) {
    return TextFormField(
      controller: controller,
      keyboardType: isEmail ? TextInputType.emailAddress : (isNumber ? TextInputType.number : TextInputType.text),
      decoration: _glassInput(label, icon),
      validator: (v) {
        if (v == null || v.isEmpty) return 'Required';
        if (isEmail && !v.contains('@')) return 'Invalid Email';
        return null;
      },
    );
  }

  Widget _buildPasswordField(TextEditingController controller, String label, bool visible, VoidCallback toggle, {bool isConfirm = false}) {
    return TextFormField(
      controller: controller,
      obscureText: !visible,
      decoration: _glassInput(label, Icons.lock).copyWith(
        suffixIcon: IconButton(icon: Icon(visible ? Icons.visibility : Icons.visibility_off), onPressed: toggle),
      ),
      validator: (v) {
        if (v == null || v.isEmpty) return 'Required';
        if (!isConfirm && v.length < 6) return 'Min 6 chars';
        if (isConfirm && v != _passwordController.text) return 'Mismatch';
        return null;
      },
    );
  }

  Widget _buildResponsivePair(bool isMobile, List<Widget> children) {
    if (isMobile) return Column(children: children.map((c) => Padding(padding: const EdgeInsets.only(bottom: 20), child: c)).toList());
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(children: children.map((c) => Expanded(child: Padding(padding: EdgeInsets.only(right: c == children.last ? 0 : 20), child: c))).toList()),
    );
  }

  Widget _reviewItem(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal, color: Colors.indigo)),
        ],
      ),
    );
  }
}