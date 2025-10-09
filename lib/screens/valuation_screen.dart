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
  String selectedModel = 'mixtral-8x7b';
  String companyName = 'Loading...';

  // Document selection
  int? selectedDocumentId;
  String? selectedDocumentName;
  List<dynamic> availableDocuments = [];
  bool isLoadingDocuments = true;

  // Fiscal year auto-detection
  int? selectedFiscalYear;
  bool isLoadingFiscalYear = false;

  final List<double> comparableMultiples = [7.5, 8.2, 7.0, 8.8, 7.8];

  @override
  void initState() {
    super.initState();
    _loadCompanyName();
    _loadDocuments();
  }

  Future<void> _loadCompanyName() async {
    try {
      final companyNames = {
        1: 'Test Company',
        2: 'Second Company',
        3: 'M&A Advisory Partners',
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

  Future<void> _loadDocuments() async {
    try {
      final result = await ApiService.getDocuments(limit: 50);
      if (result['success']) {
        final docs = result['data']['documents'] ?? [];
        setState(() {
          availableDocuments = docs;
          isLoadingDocuments = false;
          // Auto-select first document if available
          if (docs.isNotEmpty) {
            selectedDocumentId = docs[0]['id'];
            selectedDocumentName = docs[0]['original_filename'];
            // Load fiscal year for first document
            _loadFiscalYearForDocument(docs[0]['id']);
          }
        });
      }
    } catch (e) {
      print('Error loading documents: $e');
      setState(() {
        isLoadingDocuments = false;
      });
    }
  }

  Future<void> _loadFiscalYearForDocument(int documentId) async {
    setState(() {
      isLoadingFiscalYear = true;
    });

    try {
      final result = await ApiService.getDocumentFiscalYear(documentId);

      if (result['success'] && mounted) {
        final defaultYear = result['data']['default_year'];
        setState(() {
          selectedFiscalYear = defaultYear ?? 2024; // Fallback to 2024
          isLoadingFiscalYear = false;
        });
      }
    } catch (e) {
      print('Error loading fiscal year: $e');
      setState(() {
        selectedFiscalYear = 2024; // Fallback
        isLoadingFiscalYear = false;
      });
    }
  }

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
    if (selectedDocumentId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select a target company document first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (selectedFiscalYear == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Fiscal year not detected. Please try again.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
      valuationResult = null;
    });

    try {
      // Extract target name from filename
      String targetName = (selectedDocumentName ?? '')
          .replaceAll(' valuation.pdf', '')
          .replaceAll(' Valuation IER.pdf', '')
          .replaceAll('.pdf', '');

      final result = await ApiService.calculateValuation(
        companyId: ApiService.getCurrentCompany(),
        documentId: selectedDocumentId!,
        targetName: targetName,
        comparableMultiples: comparableMultiples,
        fiscalYear: selectedFiscalYear!,
        model: selectedModel,
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

            // Target Company Selector
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.business, color: Color(0xFF1E3A8A)),
                        SizedBox(width: 8),
                        Text(
                          'Select Target Company',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    if (isLoadingDocuments)
                      Center(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    else if (availableDocuments.isEmpty)
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.warning, color: Colors.orange),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'No documents available. Upload a valuation document first.',
                                style: TextStyle(color: Colors.orange[900]),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Container(
                        width: double.infinity,
                        child: DropdownButtonFormField<int>(
                          value: selectedDocumentId,
                          isExpanded: true,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                          ),
                          hint: Text('Choose a company to value'),
                          items: availableDocuments
                              .map<DropdownMenuItem<int>>((doc) {
                            String filename =
                                doc['original_filename'] ?? 'Unknown';
                            String displayName = filename
                                .replaceAll(' valuation.pdf', '')
                                .replaceAll(' Valuation IER.pdf', '')
                                .replaceAll('.pdf', '');

                            return DropdownMenuItem<int>(
                              value: doc['id'],
                              child: Row(
                                children: [
                                  Icon(Icons.description,
                                      size: 16, color: Colors.grey[600]),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      displayName,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                        fontSize: 14,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (value) async {
                            setState(() {
                              selectedDocumentId = value;
                              final doc = availableDocuments.firstWhere(
                                (d) => d['id'] == value,
                                orElse: () => null,
                              );
                              selectedDocumentName = doc?['original_filename'];
                            });

                            // Auto-detect fiscal year for selected document
                            if (value != null) {
                              await _loadFiscalYearForDocument(value);
                            }
                          },
                        ),
                      ),

                    // Show fiscal year info below dropdown
                    if (selectedDocumentId != null &&
                        !isLoadingFiscalYear &&
                        selectedFiscalYear != null) ...[
                      SizedBox(height: 12),
                      Container(
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.green[200]!),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.calendar_today,
                                size: 16, color: Colors.green[700]),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Using FY $selectedFiscalYear data • ${availableDocuments.firstWhere((d) => d['id'] == selectedDocumentId)['chunk_count']} records',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.green[900],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (isLoadingFiscalYear) ...[
                      SizedBox(height: 12),
                      Row(
                        children: [
                          SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Detecting fiscal year...',
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),

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
            }),

            SizedBox(height: 20),

            // Calculate Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: (isLoading ||
                        selectedDocumentId == null ||
                        selectedFiscalYear == null)
                    ? null
                    : _calculateValuation,
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
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Column(
              children: [
                FittedBox(
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
