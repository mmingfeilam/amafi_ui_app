import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ValuationScreen extends StatefulWidget {
  @override
  _ValuationScreenState createState() => _ValuationScreenState();
}

class _ValuationScreenState extends State<ValuationScreen> {
  bool isLoading = false;
  Map<String, dynamic>? valuationResult;
  String? errorMessage;
  String selectedModel = 'mixtral-8x7b'; // Default to recommended model
  String companyName = 'Loading...'; // Will be fetched

  // Default comparable multiples for testing
  final List<double> comparableMultiples = [7.5, 8.2, 7.0, 8.8, 7.8];
  final int fiscalYear = 2023;

  @override
  void initState() {
    super.initState();
    _loadCompanyName();
  }

  Future<void> _loadCompanyName() async {
    try {
      // Get company name from your API or use the company dropdown selection
      // For now, using a hardcoded map - you can replace with actual API call
      final companyNames = {
        1: 'Test Company',
        2: 'Second Company',
        3: 'Estia Health',
      };

      setState(() {
        companyName =
            companyNames[ApiService.getCurrentCompany()] ?? 'Demo Company';
      });
    } catch (e) {
      setState(() {
        companyName = 'Company ${ApiService.getCurrentCompany()}';
      });
    }
  }

  // Model configurations matching your backend
  final Map<String, Map<String, dynamic>> models = {
    'mistral-7b': {
      'name': 'Quick',
      'description': 'Fast draft valuations',
      'speed': '2-5 sec',
      'icon': Icons.flash_on,
      'color': Color(0xFF4CAF50),
    },
    'mixtral-8x7b': {
      'name': 'Balanced',
      'description': 'Best for regular use',
      'speed': '5-10 sec',
      'icon': Icons.star,
      'color': Color(0xFF2196F3),
      'recommended': true,
    },
    'mixtral-8x22b': {
      'name': 'Premium',
      'description': 'Detailed analysis',
      'speed': '10-15 sec',
      'icon': Icons.workspace_premium,
      'color': Color(0xFF9C27B0),
    },
    'gpt-4o': {
      'name': 'Best',
      'description': 'Critical valuations',
      'speed': '5 sec',
      'icon': Icons.diamond,
      'color': Color(0xFFFF9800),
    },
  };

  Future<void> _calculateValuation() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
      valuationResult = null;
    });

    try {
      final result = await ApiService.calculateValuation(
        companyId: 3, // Replace with actual company ID if needed
        comparableMultiples: comparableMultiples,
        fiscalYear: fiscalYear,
        model: selectedModel, // Pass selected model
      );

      if (result['success']) {
        setState(() {
          valuationResult = result['data'];
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = result['message'] ?? 'Failed to calculate valuation';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error: ${e.toString()}';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              'Company Valuation',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E3A8A),
                  ),
            ),
            SizedBox(height: 8),
            Text(
              'AI-powered valuation analysis using trading comparables',
              style: TextStyle(color: Colors.grey[600]),
            ),
            SizedBox(height: 24),

            // Model Selection Section
            Text(
              'Analysis Quality',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E3A8A),
              ),
            ),
            SizedBox(height: 12),

            // Model Selection Cards
            ...models.entries.map((entry) {
              final modelKey = entry.key;
              final modelInfo = entry.value;
              final isSelected = selectedModel == modelKey;
              final isRecommended = modelInfo['recommended'] ?? false;

              return GestureDetector(
                onTap: isLoading
                    ? null
                    : () {
                        setState(() {
                          selectedModel = modelKey;
                        });
                      },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(
                      color:
                          isSelected ? modelInfo['color'] : Colors.grey[300]!,
                      width: isSelected ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: modelInfo['color'].withOpacity(0.2),
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ]
                        : [],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        // Icon
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: modelInfo['color'].withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            modelInfo['icon'],
                            color: modelInfo['color'],
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    modelInfo['name'],
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF1E3A8A),
                                    ),
                                  ),
                                  if (isRecommended)
                                    Container(
                                      margin: EdgeInsets.only(left: 6),
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Color(0xFF2196F3),
                                        borderRadius: BorderRadius.circular(3),
                                      ),
                                      child: Text(
                                        'RECOMMENDED',
                                        style: TextStyle(
                                          fontSize: 8,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                          letterSpacing: 0.3,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Text(
                                modelInfo['description'],
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 3),
                              Row(
                                children: [
                                  Icon(
                                    Icons.access_time,
                                    size: 12,
                                    color: Colors.grey[500],
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    modelInfo['speed'],
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // Selection indicator
                        Icon(
                          isSelected
                              ? Icons.check_circle
                              : Icons.circle_outlined,
                          color: isSelected
                              ? modelInfo['color']
                              : Colors.grey[300],
                          size: 24,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),

            SizedBox(height: 20),

            // Calculate Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: isLoading ? null : _calculateValuation,
                icon: isLoading
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Icon(Icons.calculate),
                label: Text(isLoading
                    ? 'Generating Analysis...'
                    : 'Calculate Valuation'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Color(0xFF1E3A8A),
                ),
              ),
            ),

            if (isLoading) ...[
              SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text(
                        'Analyzing financial data...',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Using ${models[selectedModel]?['name']} model • ${models[selectedModel]?['speed']}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            if (errorMessage != null) ...[
              SizedBox(height: 24),
              Card(
                color: Colors.red[50],
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.error, color: Colors.red),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          errorMessage!,
                          style: TextStyle(color: Colors.red[900]),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            if (valuationResult != null) ...[
              SizedBox(height: 24),
              _buildValuationResults(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildValuationResults() {
    final valRange = valuationResult!['valuation_range'];
    final compStats = valuationResult!['comparable_stats'];
    final narrative = valuationResult!['narrative'];
    final modelUsed = valuationResult!['model_used'];
    final processingTime = valuationResult!['processing_time_seconds'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Model Info Banner
        if (modelUsed != null)
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: models[modelUsed]?['color'].withOpacity(0.1) ??
                  Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: models[modelUsed]?['color'].withOpacity(0.3) ??
                    Colors.blue[200]!,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  models[modelUsed]?['icon'] ?? Icons.check_circle,
                  color: models[modelUsed]?['color'] ?? Colors.blue,
                  size: 20,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Generated with ${models[modelUsed]?['name'] ?? modelUsed} model in ${processingTime?.toStringAsFixed(1) ?? '?'}s',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[800],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        if (modelUsed != null) SizedBox(height: 16),

        // Valuation Range Card
        Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Valuation Range',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildValuePill(
                      'Low',
                      '\$${valRange['low']['value'].toStringAsFixed(1)}M',
                      '${valRange['low']['multiple'].toStringAsFixed(2)}x',
                      Colors.orange,
                    ),
                    _buildValuePill(
                      'Mid',
                      '\$${valRange['mid']['value'].toStringAsFixed(1)}M',
                      '${valRange['mid']['multiple'].toStringAsFixed(2)}x',
                      Colors.blue,
                    ),
                    _buildValuePill(
                      'High',
                      '\$${valRange['high']['value'].toStringAsFixed(1)}M',
                      '${valRange['high']['multiple'].toStringAsFixed(2)}x',
                      Colors.green,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        SizedBox(height: 16),

        // Comparable Stats Card
        Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Comparable Companies',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 12),
                _buildStatRow('Sample Size', '${compStats['count']} companies'),
                _buildStatRow('Mean Multiple',
                    '${compStats['mean'].toStringAsFixed(2)}x'),
                _buildStatRow('Median Multiple',
                    '${compStats['median'].toStringAsFixed(2)}x'),
                _buildStatRow('Range',
                    '${compStats['min'].toStringAsFixed(2)}x - ${compStats['max'].toStringAsFixed(2)}x'),
              ],
            ),
          ),
        ),

        SizedBox(height: 16),

        // AI Analysis Card
        Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.auto_awesome, color: Color(0xFF1E3A8A)),
                    SizedBox(width: 8),
                    Text(
                      'AI Analysis',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                Text(
                  narrative,
                  style: TextStyle(height: 1.5),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildValuePill(
      String label, String value, String multiple, Color color) {
    return Expanded(
      // Changed from Column to Expanded wrapper
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8),
          Container(
            padding: EdgeInsets.symmetric(
                horizontal: 12, vertical: 12), // Reduced horizontal padding
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Column(
              children: [
                FittedBox(
                  // Added FittedBox to scale text if needed
                  fit: BoxFit.scaleDown,
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
                Text(
                  multiple,
                  style: TextStyle(
                    fontSize: 12,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: FontWeight.w500)),
          Text(value, style: TextStyle(color: Colors.grey[700])),
        ],
      ),
    );
  }
}
