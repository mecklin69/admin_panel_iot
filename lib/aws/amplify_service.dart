import 'dart:convert'; // Required for jsonDecode
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_api/amplify_api.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
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

  // --- CREATE ---
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
      final String graphQLDocument = '''
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

  // --- READ (FETCH) ---
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
      final List users = data['listClients']['items'];

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

  // --- DELETE ---
  static Future<bool> deleteClient(String vendorID) async {
    try {
      // Note: Because vendorID is your @primaryKey, we pass that to the input
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

      if (response.errors.isNotEmpty) {
        safePrint('Delete Errors: ${response.errors}');
        return false;
      }
      return true;
    } catch (e) {
      safePrint('Delete failed: $e');
      return false;
    }
  }
}