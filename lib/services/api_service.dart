import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'http://209.38.117.86/amafi';
  // static const String baseUrl = 'http://192.168.1.22:8000';

  // Default company ID - can be changed by user
  static int currentCompanyId = 3;

  // Company management
  static void setCompany(int companyId) {
    currentCompanyId = companyId;
  }

  static int getCurrentCompany() {
    return currentCompanyId;
  }

  // Health check endpoint (no company needed)
  static Future<Map<String, dynamic>> checkHealth() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/health'));
      return {
        'success': response.statusCode == 200,
        'data': json.decode(response.body),
      };
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // Upload document (company-aware)
  static Future<Map<String, dynamic>> uploadDocument(
      File file, String userId) async {
    try {
      var request = http.MultipartRequest(
          'POST',
          Uri.parse(
              '$baseUrl/api/v1/companies/$currentCompanyId/documents/upload'));
      request.files.add(await http.MultipartFile.fromPath('file', file.path));
      request.fields['user_id'] = userId;

      var response = await request.send();
      var responseBody = await response.stream.bytesToString();

      return {
        'success': response.statusCode == 200,
        'data': json.decode(responseBody),
      };
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // Enhanced search documents with correct API parameters
  static Future<Map<String, dynamic>> searchDocuments(
    String query, {
    int limit = 10,
    bool useHybrid = true,
    bool enableReranking = true,
    bool allowGlobal = false,
  }) async {
    try {
      // Prepare query parameters
      final queryParameters = <String, String>{
        'query': query,
        'limit': limit.toString(),
        'use_hybrid': useHybrid.toString(),
        'use_reranking': enableReranking.toString(),
      };

      // Add global search parameter
      if (allowGlobal) {
        queryParameters['allow_global'] = 'true';
      }

      // Build the URI
      Uri uri;
      if (allowGlobal) {
        // Use global search endpoint when allow_global is true
        uri = Uri.parse('$baseUrl/api/v1/search').replace(
          queryParameters: queryParameters,
        );
      } else {
        // Use company-aware search endpoint
        uri = Uri.parse(
                '$baseUrl/api/v1/companies/$currentCompanyId/documents/search')
            .replace(
          queryParameters: queryParameters,
        );
      }

      print('🌐 API CALL DETAILS:');
      print('   Final URI: $uri');
      print('   Method: POST');
      print('   Headers: ${_getHeaders()}');
      print('   Parameters breakdown:');
      queryParameters.forEach((key, value) {
        print('     $key: $value');
      });

      final response = await http.post(
        uri,
        headers: _getHeaders(),
      );

      print('📡 API RESPONSE DETAILS:');
      print('   Status Code: ${response.statusCode}');
      print('   Response Body: ${response.body}');
      print('   Response Length: ${response.body.length} chars');
      if (response.statusCode != 200) {
        print('   Error Response Body: ${response.body}');
      } else {
        try {
          final decoded = json.decode(response.body);
          if (decoded is Map && decoded.containsKey('results')) {
            print(
                '   Results Array Length: ${(decoded['results'] as List).length}');
          }
        } catch (e) {
          print('   Could not parse response for logging: $e');
        }
      }

      final decoded = json.decode(response.body);

      // ✅ Force sort by similarity_score descending
      if (decoded is Map && decoded.containsKey('results')) {
        List results = decoded['results'];

        results.sort((a, b) {
          final aScore = (a['similarity_score'] ?? 0) as num;
          final bScore = (b['similarity_score'] ?? 0) as num;
          return bScore.compareTo(aScore); // descending
        });

        decoded['results'] = results;
      }

      return {
        'success': response.statusCode == 200,
        'data': decoded,
      };
    } catch (e) {
      print('Search error: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  // Legacy search method for backward compatibility
  static Future<Map<String, dynamic>> searchDocumentsLegacy(String query,
      {int limit = 10}) async {
    return searchDocuments(query, limit: limit);
  }

  // Get all documents (company-aware)
  static Future<Map<String, dynamic>> getDocuments() async {
    try {
      // Use company-scoped endpoint
      final response = await http.get(
        Uri.parse('$baseUrl/api/v1/companies/$currentCompanyId/documents'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': json.decode(response.body),
        };
      } else {
        return {
          'success': false,
          'error': 'Failed to load documents',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // Get system statistics (company-aware)
  static Future<Map<String, dynamic>> getStats() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/api/v1/companies/$currentCompanyId/stats'));
      return {
        'success': response.statusCode == 200,
        'data': json.decode(response.body),
      };
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // Get document details (keeping original endpoint for now)
  static Future<Map<String, dynamic>> getDocumentById(int documentId) async {
    try {
      final response =
          await http.get(Uri.parse('$baseUrl/api/v1/documents/$documentId'));
      return {
        'success': response.statusCode == 200,
        'data': json.decode(response.body),
      };
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // Reprocess document (keeping original endpoint for now)
  static Future<Map<String, dynamic>> reprocessDocument(int documentId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/v1/documents/$documentId/reprocess'),
      );
      return {
        'success': response.statusCode == 200,
        'data': response.statusCode == 200 ? json.decode(response.body) : null,
      };
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // Delete document (keeping original endpoint for now)
  static Future<Map<String, dynamic>> deleteDocument(int documentId) async {
    try {
      // Use company-scoped endpoint
      final response = await http.delete(
        Uri.parse(
            '$baseUrl/api/v1/companies/$currentCompanyId/documents/$documentId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': json.decode(response.body),
        };
      } else {
        return {
          'success': false,
          'error': 'Server error: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // Get available companies (for dropdown)
  static Future<Map<String, dynamic>> getCompanies() async {
    try {
      return {
        'success': true,
        'data': [
          // {'id': 1, 'name': 'Test Company'},
          // {'id': 2, 'name': 'Second Company'},
          {'id': 3, 'name': 'Estia Health'}, // ← Changed from 'Demo Company'
        ],
      };
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  static Map<String, String> _getHeaders() {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      // Add any authentication headers you need
      // 'Authorization': 'Bearer $token',
    };
  }

  static Future<Map<String, dynamic>> getDocumentStatus(
      String documentId) async {
    try {
      final response = await http.get(
        Uri.parse(
            '$baseUrl/api/v1/companies/$currentCompanyId/documents/$documentId/status'), // ← FIXED!
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': json.decode(response.body),
        };
      } else {
        return {
          'success': false,
          'error': 'Status check failed: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Status check error: $e',
      };
    }
  }

  // New method to get search mode combinations information
  static Map<String, Map<String, dynamic>> getSearchModeCombinations() {
    return {
      'hybrid_reranked': {
        'name': 'Hybrid + Reranking',
        'description':
            'Vector + keyword search with reranking - best overall quality',
        'recommended_for': 'Most queries, balanced relevance',
        'use_hybrid': true,
        'use_reranking': true,
      },
      'vector_reranked': {
        'name': 'Vector + Reranking',
        'description': 'Pure semantic search with reranking',
        'recommended_for': 'Conceptual queries where exact words don\'t matter',
        'use_hybrid': false,
        'use_reranking': true,
      },
      'hybrid_only': {
        'name': 'Hybrid Only',
        'description': 'Vector + keyword search without reranking',
        'recommended_for': 'Fast results when reranking speed not needed',
        'use_hybrid': true,
        'use_reranking': false,
      },
      'vector_only': {
        'name': 'Vector Only',
        'description': 'Pure semantic search without reranking',
        'recommended_for': 'Fastest option, semantic similarity only',
        'use_hybrid': false,
        'use_reranking': false,
      },
    };
  }

  // Method to validate search parameters
  static bool isValidSearchConfiguration(bool useHybrid, bool useReranking) {
    // All combinations are valid
    return true;
  }

  static Future<Map<String, dynamic>> calculateValuation({
    required int companyId, // ADDED: Make companyId a parameter
    required List<double> comparableMultiples,
    required int fiscalYear,
    String model = 'mixtral-8x7b',
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/v1/valuations/calculate'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'company_id': companyId,
          'comparable_multiples': comparableMultiples,
          'fiscal_year': fiscalYear,
          'model': model,
          'include_narrative': true,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'data': data,
        };
      } else {
        return {
          'success': false,
          'message': 'Server error: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  // Optional: Add method to get available models from backend
  static Future<Map<String, dynamic>> getAvailableModels() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/v1/valuations/models'),
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': jsonDecode(response.body),
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to fetch models',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }
}
