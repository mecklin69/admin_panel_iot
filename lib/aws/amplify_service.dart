import 'dart:convert';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_api/amplify_api.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart'; // Add to pubspec.yaml if missing
import '../amplifyconfiguration.dart';

class AmplifyService {
  static Future<void> configureAmplify() async {
    try {
      final api = AmplifyAPI();
      final auth = AmplifyAuthCognito();
      await Amplify.addPlugins([api, auth]);
      await Amplify.configure(amplifyconfig);
      safePrint('Amplify successfully configured');
    } catch (e) {
      safePrint('Error configuring Amplify: $e');
    }
  }

  // --- CLIENT: CREATE ---
  static Future<bool> pushAccountToDynamo({
    required String vendorID,
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required String location,
    required String companyName,
    required int deviceCount,
    required String date,
  }) async {
    try {
      const String graphQLDocument = '''
mutation CreateClient(\$vendorID: String!, \$firstName: String!, \$lastName: String!, \$email: String!, \$password: String!, \$location: String!, \$companyName: String!, \$deviceCount: Int!, \$date: String!) {
  createClient(input: {
    vendorID: \$vendorID,
    firstName: \$firstName,
    lastName: \$lastName,
    email: \$email,
    password: \$password,
    location: \$location,
    companyName: \$companyName,
    deviceCount: \$deviceCount,
    deploymentDate: \$date
  }) {
    vendorID
  }
}''';

      final request = GraphQLRequest<String>(
        document: graphQLDocument,
        variables: {
          'vendorID': vendorID,
          'firstName': firstName,
          'lastName': lastName,
          'email': email,
          'password': password,
          'location': location,
          'companyName': companyName,
          'deviceCount': deviceCount,
          'date': date,
        },
      );

      final response = await Amplify.API.mutate(request: request).response;
      return response.errors.isEmpty;
    } catch (e) {
      safePrint('Mutation failed: $e');
      return false;
    }
  }

  // --- CLIENT: READ ---
  static Future<List<dynamic>> fetchAllClients() async {
    try {
      const String graphQLDocument = '''
query ListClients {
  listClients {
    items {
      vendorID
      firstName
      lastName
      email
      password
      location
      companyName
      deviceCount
      deploymentDate
    }
  }
}''';

      final request = GraphQLRequest<String>(document: graphQLDocument);
      final response = await Amplify.API.query(request: request).response;

      if (response.data != null) {
        final Map<String, dynamic> data = jsonDecode(response.data!);
        return data['listClients']['items'] ?? [];
      }
      return [];
    } catch (e) {
      safePrint('Fetch failed: $e');
      return [];
    }
  }

  // --- FIRMWARE: CREATE (NOW PERSISTENT) ---
  static Future<bool> pushFirmwareMapping({
    required String vendorID,
    required String fileName,
    required String fileSize,
  }) async {
    try {
      const String graphQLDocument = '''
mutation CreateFirmwareMapping(\$vendorID: String!, \$fileName: String!, \$fileSize: String!, \$uploadDate: String!) {
  createFirmwareMapping(input: {
    vendorID: \$vendorID,
    fileName: \$fileName,
    fileSize: \$fileSize,
    uploadDate: \$uploadDate
  }) {
    id
    vendorID
  }
}''';

      final request = GraphQLRequest<String>(
        document: graphQLDocument,
        variables: {
          'vendorID': vendorID,
          'fileName': fileName,
          'fileSize': fileSize,
          'uploadDate': DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now()),
        },
      );

      final response = await Amplify.API.mutate(request: request).response;

      if (response.errors.isNotEmpty) {
        safePrint('GraphQL Errors: ${response.errors}');
        return false;
      }
      return true;
    } catch (e) {
      safePrint("AWS Push Error: $e");
      return false;
    }
  }

  // --- FIRMWARE: READ (NOW PERSISTENT) ---
  static Future<List<dynamic>> fetchFirmwareMappings() async {
    try {
      const String graphQLDocument = '''
query ListFirmwareMappings {
  listFirmwareMappings {
    items {
      id
      vendorID
      fileName
      fileSize
      uploadDate
    }
  }
}''';

      final request = GraphQLRequest<String>(document: graphQLDocument);
      final response = await Amplify.API.query(request: request).response;

      if (response.data != null) {
        final Map<String, dynamic> data = jsonDecode(response.data!);
        List items = data['listFirmwareMappings']['items'] ?? [];
        // Sort newest first
        items.sort((a, b) => (b['uploadDate'] ?? "").compareTo(a['uploadDate'] ?? ""));
        return items;
      }
      return [];
    } catch (e) {
      safePrint('Firmware Fetch failed: $e');
      return [];
    }
  }

  // --- AUTH: LOGIN ---
  static Future<bool> loginUser(String email, String password) async {
    try {
      const String graphQLDocument = '''
query ListClients {
  listClients {
    items {
      email
      password
    }
  }
}''';

      final request = GraphQLRequest<String>(document: graphQLDocument);
      final response = await Amplify.API.query(request: request).response;

      if (response.data == null) return false;

      final Map<String, dynamic> data = jsonDecode(response.data!);
      final List users = data['listClients']['items'] ?? [];

      for (final user in users) {
        if (user['email'] == email && user['password'] == password) {
          return true;
        }
      }
      return false;
    } catch (e) {
      safePrint("Login error: $e");
      return false;
    }
  }

  // --- CLIENT: DELETE ---
  static Future<bool> deleteClient(String vendorID) async {
    try {
      const String graphQLDocument = '''
mutation DeleteClient(\$vendorID: String!) {
  deleteClient(input: { vendorID: \$vendorID }) {
    vendorID
  }
}''';

      final request = GraphQLRequest<String>(
        document: graphQLDocument,
        variables: {'vendorID': vendorID},
      );

      final response = await Amplify.API.mutate(request: request).response;
      return response.errors.isEmpty;
    } catch (e) {
      safePrint('Delete failed: $e');
      return false;
    }
  }
}