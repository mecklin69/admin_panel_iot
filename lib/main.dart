// import 'package:amplify_api/amplify_api.dart';
// import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
// import 'package:amplify_flutter/amplify_flutter.dart';
// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
//
// import 'aws/amplify_service.dart';
// import 'amplifyconfiguration.dart';
// Future<void> main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//
//   try {
//     await Amplify.addPlugins([
//       AmplifyAPI(),
//       // AmplifyAuthCognito(), // optional but fine
//     ]);
//
//     await Amplify.configure(amplifyconfig);
//     safePrint('Amplify configured');
//   } catch (e) {
//     safePrint('Amplify error: $e');
//   }
//
//   runApp(const AdminPanelApp());
// }
//
//
// class AdminPanelApp extends StatelessWidget {
//   const AdminPanelApp({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       debugShowCheckedModeBanner: false,
//       theme: ThemeData(
//         primarySwatch: Colors.indigo,
//         useMaterial3: true,
//         colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
//       ),
//       home: const AdminDashboard(),
//     );
//   }
// }
//
// class AdminDashboard extends StatefulWidget {
//   const AdminDashboard({super.key});
//
//   @override
//   State<AdminDashboard> createState() => _AdminDashboardState();
// }
// class DashboardPage extends StatefulWidget {
//   const DashboardPage({super.key});
//
//   @override
//   State<DashboardPage> createState() => _DashboardPageState();
// }
//
// class _DashboardPageState extends State<DashboardPage> {
//   bool _isLoading = true;
//   List<dynamic> _clients = [];
//   String? _error;
//
//   @override
//   void initState() {
//     super.initState();
//     _loadClients();
//   }
//
//   Future<void> _loadClients() async {
//     try {
//       final data = await AmplifyService.fetchAllClients();
//       setState(() {
//         _clients = data;
//         _isLoading = false;
//       });
//     } catch (e) {
//       setState(() {
//         _error = e.toString();
//         _isLoading = false;
//       });
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     if (_isLoading) {
//       return const Center(child: CircularProgressIndicator());
//     }
//
//     if (_error != null) {
//       return Center(child: Text("❌ $_error"));
//     }
//
//     if (_clients.isEmpty) {
//       return const Center(child: Text("No clients found"));
//     }
//
//     return Padding(
//       padding: const EdgeInsets.all(24),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           const Text(
//             "Client Deployments",
//             style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
//           ),
//           const SizedBox(height: 20),
//           Expanded(child: _buildTable()),
//         ],
//       ),
//     );
//   }
//   Widget _buildTable() {
//     return SingleChildScrollView(
//       scrollDirection: Axis.horizontal,
//       child: DataTable(
//         headingRowColor:
//         MaterialStateProperty.all(Colors.indigo.withOpacity(0.1)),
//         columns: const [
//           DataColumn(label: Text('Vendor ID')),
//           DataColumn(label: Text('Client')),
//           DataColumn(label: Text('Email')),
//           DataColumn(label: Text('Company')),
//           DataColumn(label: Text('Devices')),
//           DataColumn(label: Text('Location')),
//           DataColumn(label: Text('Date')),
//         ],
//         rows: _clients.map((client) {
//           return DataRow(cells: [
//             DataCell(Text(client['vendorID'] ?? '')),
//             DataCell(Text(
//                 "${client['firstName']} ${client['lastName']}")),
//             DataCell(Text(client['email'] ?? '')),
//             DataCell(Text(client['companyName'] ?? '')),
//             DataCell(Text(client['deviceCount'].toString())),
//             DataCell(Text(client['location'] ?? '')),
//             DataCell(Text(client['deploymentDate'] ?? '')),
//           ]);
//         }).toList(),
//       ),
//     );
//   }
// }
//
//
// class _AdminDashboardState extends State<AdminDashboard> {
//   int _selectedIndex = 0;
//
//   final List<Widget> _pages = [
//     const DashboardPage(),
//     const AccountCreationPage(),
//     const Center(child: Text('System Settings', style: TextStyle(fontSize: 24))),
//   ];
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Row(
//         children: [
//           NavigationRail(
//             extended: true,
//             selectedIndex: _selectedIndex,
//             onDestinationSelected: (int index) => setState(() => _selectedIndex = index),
//             leading: const Padding(
//               padding: EdgeInsets.symmetric(vertical: 20),
//               child: Icon(Icons.admin_panel_settings, size: 40, color: Colors.indigo),
//             ),
//             destinations: const [
//               NavigationRailDestination(icon: Icon(Icons.dashboard), label: Text('Dashboard')),
//               NavigationRailDestination(icon: Icon(Icons.person_add), label: Text('Create Account')),
//               NavigationRailDestination(icon: Icon(Icons.settings), label: Text('Settings')),
//             ],
//           ),
//           const VerticalDivider(thickness: 1, width: 1),
//           Expanded(child: _pages[_selectedIndex]),
//         ],
//       ),
//     );
//   }
// }
//
// class AccountCreationPage extends StatefulWidget {
//   const AccountCreationPage({super.key});
//
//   @override
//   State<AccountCreationPage> createState() => _AccountCreationPageState();
// }
//
// class _AccountCreationPageState extends State<AccountCreationPage> {
//   final _formKey = GlobalKey<FormState>();
//   bool _isLoading = false;
//
//   // Visibility toggles for passwords
//   bool _isPasswordVisible = false;
//   bool _isConfirmPasswordVisible = false;
//
//   // Existing Controllers
//   final TextEditingController _firstNameController = TextEditingController();
//   final TextEditingController _lastNameController = TextEditingController();
//   final TextEditingController _locationController = TextEditingController();
//   final TextEditingController _companyController = TextEditingController();
//   final TextEditingController _deviceCountController = TextEditingController();
//   final TextEditingController _vendorIdController = TextEditingController();
//   final TextEditingController _dateController = TextEditingController(
//     text: DateFormat('yyyy-MM-dd').format(DateTime.now()),
//   );
//
//   // NEW: Auth Controllers
//   final TextEditingController _emailController = TextEditingController();
//   final TextEditingController _passwordController = TextEditingController();
//   final TextEditingController _confirmPasswordController = TextEditingController();
//
//   @override
//   void dispose() {
//     _firstNameController.dispose();
//     _lastNameController.dispose();
//     _locationController.dispose();
//     _companyController.dispose();
//     _deviceCountController.dispose();
//     _vendorIdController.dispose();
//     _dateController.dispose();
//     // NEW: Dispose Auth Controllers
//     _emailController.dispose();
//     _passwordController.dispose();
//     _confirmPasswordController.dispose();
//     super.dispose();
//   }
//
//   // Helper for password visibility toggle
//   Widget _passwordSuffix(bool isVisible, VoidCallback onToggle) {
//     return IconButton(
//       icon: Icon(isVisible ? Icons.visibility : Icons.visibility_off, color: Colors.indigoAccent),
//       onPressed: onToggle,
//     );
//   }
//
//   // --- UI Section ---
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       color: Colors.grey[50],
//       child: Center(
//         child: SingleChildScrollView(
//           padding: const EdgeInsets.all(32.0),
//           child: Container(
//             width: 700,
//             padding: const EdgeInsets.all(40),
//             decoration: BoxDecoration(
//               color: Colors.white,
//               borderRadius: BorderRadius.circular(24),
//               boxShadow: [
//                 BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10)),
//               ],
//             ),
//             child: Form(
//               key: _formKey,
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   const Text("Register New Client",
//                       style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.indigo)),
//                   const Text("Provision new IoT deployment accounts", style: TextStyle(color: Colors.grey)),
//                   const SizedBox(height: 40),
//
//                   // Name Fields
//                   Row(
//                     children: [
//                       Expanded(child: TextFormField(controller: _firstNameController, decoration: _glassInput("First Name", Icons.person))),
//                       const SizedBox(width: 20),
//                       Expanded(child: TextFormField(controller: _lastNameController, decoration: _glassInput("Last Name", Icons.person_outline))),
//                     ],
//                   ),
//                   const SizedBox(height: 20),
//
//                   // NEW: Email Field
//                   TextFormField(
//                     controller: _emailController,
//                     keyboardType: TextInputType.emailAddress,
//                     decoration: _glassInput("Email Address", Icons.email),
//                     validator: (value) {
//                       if (value == null || !value.contains('@')) return 'Enter a valid email';
//                       return null;
//                     },
//                   ),
//                   const SizedBox(height: 20),
//
//                   // NEW: Password Fields
//                   Row(
//                     children: [
//                       Expanded(
//                         child: TextFormField(
//                           controller: _passwordController,
//                           obscureText: !_isPasswordVisible,
//                           decoration: _glassInput("Password", Icons.lock).copyWith(
//                             suffixIcon: _passwordSuffix(_isPasswordVisible, () => setState(() => _isPasswordVisible = !_isPasswordVisible)),
//                           ),
//                           validator: (value) => (value != null && value.length < 6) ? "Min 6 characters" : null,
//                         ),
//                       ),
//                       const SizedBox(width: 20),
//                       Expanded(
//                         child: TextFormField(
//                           controller: _confirmPasswordController,
//                           obscureText: !_isConfirmPasswordVisible,
//                           decoration: _glassInput("Confirm Password", Icons.lock_clock).copyWith(
//                             suffixIcon: _passwordSuffix(_isConfirmPasswordVisible, () => setState(() => _isConfirmPasswordVisible = !_isConfirmPasswordVisible)),
//                           ),
//                           validator: (value) {
//                             if (value != _passwordController.text) return "Passwords do not match";
//                             return null;
//                           },
//                         ),
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 20),
//
//                   // Existing Fields (Location, Company, etc.)
//                   Row(
//                     children: [
//                       Expanded(child: TextFormField(controller: _locationController, decoration: _glassInput("Location", Icons.location_on))),
//                       const SizedBox(width: 20),
//                       Expanded(child: TextFormField(controller: _companyController, decoration: _glassInput("Company Name", Icons.business))),
//                     ],
//                   ),
//                   const SizedBox(height: 20),
//                   Row(
//                     children: [
//                       Expanded(child: TextFormField(
//                         controller: _deviceCountController,
//                         keyboardType: TextInputType.number,
//                         decoration: _glassInput("Devices to Deploy", Icons.developer_board),
//                       )),
//                       const SizedBox(width: 20),
//                       Expanded(child: TextFormField(controller: _vendorIdController, decoration: _glassInput("Vendor ID", Icons.verified_user))),
//                     ],
//                   ),
//                   const SizedBox(height: 40),
//
//                   // Submit Button
//                   InkWell(
//                     onTap: _showReviewDialog,
//                     child: Container(
//                       height: 60,
//                       alignment: Alignment.center,
//                       decoration: BoxDecoration(
//                         borderRadius: BorderRadius.circular(12),
//                         gradient: const LinearGradient(colors: [Colors.indigo, Colors.blueAccent]),
//                       ),
//                       child: _isLoading
//                           ? const CircularProgressIndicator(color: Colors.white)
//                           : const Text("INITIALIZE ACCOUNT", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
//   void _showReviewDialog() {
//     // 1. Trigger the Form validation (Email, Password match, etc.)
//     if (_formKey.currentState!.validate()) {
//       showDialog(
//         context: context,
//         barrierDismissible: false,
//         builder: (BuildContext context) {
//           return AlertDialog(
//             backgroundColor: Colors.white,
//             surfaceTintColor: Colors.white,
//             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
//             title: const Row(
//               children: [
//                 Icon(Icons.fact_check, color: Colors.indigo),
//                 SizedBox(width: 10),
//                 Text("Review Deployment"),
//               ],
//             ),
//             content: SizedBox(
//               width: 400,
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   const Text("Verify the account details before final initialization.",
//                       style: TextStyle(color: Colors.grey, fontSize: 13)),
//                   const Divider(height: 30),
//                   _reviewItem("Client", "${_firstNameController.text} ${_lastNameController.text}"),
//                   _reviewItem("Email", _emailController.text),
//                   _reviewItem("Company", _companyController.text),
//                   _reviewItem("Vendor ID", _vendorIdController.text, isBold: true),
//                 ],
//               ),
//             ),
//             actions: [
//               TextButton(
//                 onPressed: () => Navigator.pop(context),
//                 child: const Text("EDIT", style: TextStyle(color: Colors.grey)),
//               ),
//               ElevatedButton(
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: Colors.indigo,
//                   foregroundColor: Colors.white,
//                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
//                 ),
//                 onPressed: () {
//                   Navigator.pop(context); // Close dialog
//                   _finalizeAccount();     // Start AWS Push
//                 },
//                 child: const Text("CONFIRM & CREATE"),
//               ),
//             ],
//           );
//         },
//       );
//     }
//   }
//   Widget _reviewItem(String label, String value, {bool isBold = false}) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 6.0),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           // The Label (e.g., "Vendor ID")
//           Text(
//               label,
//               style: const TextStyle(color: Colors.black54, fontSize: 14)
//           ),
//           // The Value (e.g., "VND-102")
//           Text(
//             value,
//             style: TextStyle(
//               fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
//               color: isBold ? Colors.indigo : Colors.black87,
//               fontSize: 14,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//   void _finalizeAccount() async {
//     // 1. Show the loading spinner on the button
//     setState(() => _isLoading = true);
//
//     try {
//       // 2. Call your Amplify service with all the data from the controllers
//       bool success = await AmplifyService.pushAccountToDynamo(
//         vendorID: _vendorIdController.text,
//         firstName: _firstNameController.text,
//         lastName: _lastNameController.text,
//         email: _emailController.text,
//         password: _passwordController.text,// NEW
//         location: _locationController.text,
//         companyName: _companyController.text,
//         deviceCount: int.tryParse(_deviceCountController.text) ?? 0,
//         date: _dateController.text,
//       );
//
//       if (success) {
//         _showSuccessUI();
//         _formKey.currentState?.reset(); // Clear the form on success
//
//         // Clear auth-specific controllers manually
//         _emailController.clear();
//         _passwordController.clear();
//         _confirmPasswordController.clear();
//       } else {
//         _showErrorUI("Database sync failed. Check AWS connection.");
//       }
//     } catch (e) {
//       _showErrorUI("An unexpected error occurred: $e");
//     } finally {
//       // 3. Always stop the loading spinner, even if it fails
//       setState(() => _isLoading = false);
//     }
//   }
//
//   void _showSuccessUI() {
//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(
//         content: Text("🚀 Account successfully provisioned in DynamoDB!"),
//         backgroundColor: Colors.green,
//         behavior: SnackBarBehavior.floating,
//       ),
//     );
//   }
//
//   void _showErrorUI(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text("❌ $message"),
//         backgroundColor: Colors.redAccent,
//         behavior: SnackBarBehavior.floating,
//       ),
//     );
//   }
//   InputDecoration _glassInput(String label, IconData icon) {
//     return InputDecoration(
//       labelText: label,
//       labelStyle: const TextStyle(color: Colors.indigo),
//       prefixIcon: Icon(icon, color: Colors.indigoAccent),
//       filled: true,
//       fillColor: Colors.indigo.withOpacity(0.05),
//       enabledBorder: OutlineInputBorder(
//         borderRadius: BorderRadius.circular(12),
//         borderSide: BorderSide(color: Colors.indigo.withOpacity(0.1)),
//       ),
//       focusedBorder: OutlineInputBorder(
//         borderRadius: BorderRadius.circular(12),
//         borderSide: const BorderSide(color: Colors.indigoAccent, width: 2),
//       ),
//       errorBorder: OutlineInputBorder(
//         borderRadius: BorderRadius.circular(12),
//         borderSide: const BorderSide(color: Colors.redAccent, width: 1),
//       ),
//       focusedErrorBorder: OutlineInputBorder(
//         borderRadius: BorderRadius.circular(12),
//         borderSide: const BorderSide(color: Colors.red, width: 2),
//       ),
//     );
//   }
// }



import 'package:amplify_api/amplify_api.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:flutter/material.dart';
import 'amplifyconfiguration.dart';
import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Amplify.addPlugins([AmplifyAPI()]);
    await Amplify.configure(amplifyconfig);
    safePrint('Amplify configured');
  } catch (e) {
    safePrint('Amplify error: $e');
  }

  runApp(const AdminPanelApp());
}