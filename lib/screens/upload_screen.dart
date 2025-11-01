import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:async';
import '../services/api_service.dart';
import '../services/file_picker_service.dart';

class UploadScreen extends StatefulWidget {
  @override
  _UploadScreenState createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  final _userIdController = TextEditingController(
    text: 'technician-${DateTime.now().millisecondsSinceEpoch}',
  );

  File? _selectedFile;
  FileInfo? _selectedFileInfo;
  bool _isUploading = false;
  bool _isProcessing = false;
  bool _hasProcessingDocuments = false; // NEW: Track if any doc is processing
  String? _uploadResult;
  double _uploadProgress = 0.0;

  // Status polling
  Timer? _statusTimer;
  Timer? _processingCheckTimer; // NEW: Timer for checking processing status
  String? _currentDocumentId;

  @override
  void initState() {
    super.initState();
    _checkForProcessingDocuments();
    // Poll every 3 seconds to check if other documents are processing
    _processingCheckTimer = Timer.periodic(Duration(seconds: 3), (_) {
      _checkForProcessingDocuments();
    });
  }

  @override
  void dispose() {
    _statusTimer?.cancel();
    _processingCheckTimer?.cancel(); // NEW: Cancel processing check timer
    _userIdController.dispose();
    super.dispose();
  }

  // NEW: Check if any documents are currently processing
  Future<void> _checkForProcessingDocuments() async {
    try {
      final response = await ApiService.getDocuments(limit: 10);
      if (response['success']) {
        final docs = response['data']['documents'] as List;
        final hasProcessing =
            docs.any((doc) => doc['processing_status'] == 'processing');

        if (mounted) {
          setState(() {
            _hasProcessingDocuments = hasProcessing;
          });

          // ← ADD THIS: Stop polling if no processing documents
          if (!hasProcessing && _processingCheckTimer != null) {
            _processingCheckTimer?.cancel();
            _processingCheckTimer = null;
          }
        }
      }
    } catch (e) {
      print('Error checking processing status: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // NEW: Button is disabled if uploading OR if another doc is processing
    final isButtonDisabled = _isUploading || _hasProcessingDocuments;

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Upload Manual',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E3A8A),
                ),
          ),
          SizedBox(height: 16),

          // Upload Form Card
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Technician ID Field
                  TextField(
                    controller: _userIdController,
                    decoration: InputDecoration(
                      labelText: 'Technician ID',
                      hintText: 'Enter your technician identifier',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                    ),
                  ),
                  SizedBox(height: 16),

                  // File Selection Area
                  Container(
                    width: double.infinity,
                    constraints: BoxConstraints(minHeight: 120),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: _selectedFile != null
                            ? Color(0xFF1E3A8A)
                            : Colors.grey[300]!,
                        width: _selectedFile != null ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(8),
                      color: _selectedFile != null
                          ? Color(0xFF1E3A8A).withOpacity(0.05)
                          : null,
                    ),
                    child: InkWell(
                      onTap: _isUploading ? null : _selectFile,
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _selectedFile != null
                                  ? Icons.description
                                  : Icons.cloud_upload,
                              size: 40,
                              color: _selectedFile != null
                                  ? Color(0xFF1E3A8A)
                                  : Colors.grey[600],
                            ),
                            SizedBox(height: 8),
                            Text(
                              _selectedFileInfo?.name ??
                                  'Tap to select PDF manual',
                              style: TextStyle(
                                color: _selectedFile != null
                                    ? Color(0xFF1E3A8A)
                                    : Colors.grey[600],
                                fontSize: 14,
                                fontWeight: _selectedFile != null
                                    ? FontWeight.w500
                                    : FontWeight.normal,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (_selectedFileInfo != null) ...[
                              SizedBox(height: 4),
                              Text(
                                _selectedFileInfo!.sizeFormatted,
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                              SizedBox(height: 6),
                              Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.green[100],
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  'Ready to upload',
                                  style: TextStyle(
                                    color: Colors.green[700],
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: 16),

                  // NEW: Warning box when another document is processing
                  if (_hasProcessingDocuments && !_isUploading) ...[
                    Container(
                      padding: EdgeInsets.all(12),
                      margin: EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange[200]!),
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.orange),
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Another document is being processed. Please wait before uploading.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.orange[900],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Upload Progress
                  if (_isUploading) ...[
                    LinearProgressIndicator(
                      value: _uploadProgress,
                      backgroundColor: Colors.grey[300],
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Color(0xFF1E3A8A)),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Uploading... ${(_uploadProgress * 100).toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    SizedBox(height: 16),
                  ],

                  // Processing Status
                  if (_isProcessing && !_isUploading) ...[
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue[200]!),
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  Color(0xFF1E3A8A)),
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Processing document...',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF1E3A8A),
                                  ),
                                ),
                                Text(
                                  'Advanced OCR extraction in progress (1-2 minutes)',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 16),
                  ],

                  // Upload Button - MODIFIED
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _selectedFile != null && !isButtonDisabled
                          ? _uploadFile
                          : null,
                      icon: _isUploading
                          ? SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Icon(Icons.upload),
                      label: Text(_isUploading
                          ? 'Uploading...'
                          : _hasProcessingDocuments
                              ? 'Processing...'
                              : 'Upload Manual'),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),

                  // Clear Selection Button
                  if (_selectedFile != null && !_isUploading) ...[
                    SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _clearSelection,
                        icon: Icon(Icons.clear),
                        label: Text('Clear Selection'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Upload Result
          if (_uploadResult != null) ...[
            SizedBox(height: 16),
            Card(
              color: _uploadResult!.toLowerCase().contains('error') ||
                      _uploadResult!.toLowerCase().contains('failed')
                  ? Colors.red[50]
                  : _uploadResult!.toLowerCase().contains('complete')
                      ? Colors.green[50]
                      : Colors.blue[50],
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      _uploadResult!.toLowerCase().contains('error') ||
                              _uploadResult!.toLowerCase().contains('failed')
                          ? Icons.error
                          : _uploadResult!.toLowerCase().contains('complete')
                              ? Icons.check_circle
                              : Icons.info,
                      color: _uploadResult!.toLowerCase().contains('error') ||
                              _uploadResult!.toLowerCase().contains('failed')
                          ? Colors.red
                          : _uploadResult!.toLowerCase().contains('complete')
                              ? Colors.green
                              : Colors.blue,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _uploadResult!,
                        style: TextStyle(
                          color:
                              _uploadResult!.toLowerCase().contains('error') ||
                                      _uploadResult!
                                          .toLowerCase()
                                          .contains('failed')
                                  ? Colors.red[700]
                                  : _uploadResult!
                                          .toLowerCase()
                                          .contains('complete')
                                      ? Colors.green[700]
                                      : Colors.blue[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          SizedBox(height: 24),

          // Information Section
          _buildInfoSection(),
        ],
      ),
    );
  }

  Widget _buildInfoSection() {
    final fileTypeInfo = FilePickerService.getSupportedFileTypes();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Supported Formats',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E3A8A),
            fontSize: 16,
          ),
        ),
        SizedBox(height: 8),
        _buildInfoItem(Icons.picture_as_pdf, 'PDF documents'),
        _buildInfoItem(Icons.scanner, 'Scanned PDFs (OCR supported)'),
        _buildInfoItem(Icons.file_upload,
            'Maximum file size: ${fileTypeInfo.maxSizeFormatted}'),
        SizedBox(height: 16),
        Text(
          'Processing Info',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E3A8A),
            fontSize: 16,
          ),
        ),
        SizedBox(height: 8),
        _buildInfoItem(Icons.auto_awesome, 'AI-powered text extraction'),
        _buildInfoItem(Icons.search, 'Automatic semantic indexing'),
        _buildInfoItem(
            Icons.hourglass_empty, 'Background processing (1-2 minutes)'),
        _buildInfoItem(Icons.notifications_active, 'Real-time status updates'),
      ],
    );
  }

  Widget _buildInfoItem(IconData icon, String text) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Future<void> _selectFile() async {
    try {
      final result = await FilePickerService.pickPdfFile();

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);

        // Validate the selected file
        final validation = await FilePickerService.validateFile(file);

        if (!validation.isValid) {
          setState(() {
            _uploadResult = 'Error: ${validation.error}';
          });
          return;
        }

        // Get file information
        final fileInfo = await FilePickerService.getFileInfo(file);

        setState(() {
          _selectedFile = file;
          _selectedFileInfo = fileInfo;
          _uploadResult = null;
          _uploadProgress = 0.0;
          _isProcessing = false;
        });
      }
    } catch (e) {
      setState(() {
        _uploadResult = 'Error selecting file: $e';
      });
    }
  }

  void _clearSelection() {
    _statusTimer?.cancel();
    setState(() {
      _selectedFile = null;
      _selectedFileInfo = null;
      _uploadResult = null;
      _uploadProgress = 0.0;
      _isProcessing = false;
      _currentDocumentId = null;
    });
  }

  void _startStatusPolling(String documentId) {
    _currentDocumentId = documentId;
    _statusTimer?.cancel();

    setState(() {
      _isProcessing = true;
    });

    // ← NEW: Restart the processing check timer
    _processingCheckTimer?.cancel();
    _processingCheckTimer = Timer.periodic(Duration(seconds: 3), (_) {
      _checkForProcessingDocuments();
    });

    _statusTimer = Timer.periodic(Duration(seconds: 5), (timer) async {
      try {
        final status = await ApiService.getDocumentStatus(documentId);

        if (status['success']) {
          final statusData = status['data'];

          if (statusData['processing_status'] == 'completed') {
            setState(() {
              _isProcessing = false;
              _uploadResult =
                  'Processing complete! Document is now searchable.\n'
                  'Chunks created: ${statusData['chunk_count']}\n'
                  'Quality score: ${(statusData['text_quality_score'] ?? 0.0).toStringAsFixed(2)}';
            });
            timer.cancel();

            // ← NEW: Also cancel the processing check timer
            _processingCheckTimer?.cancel();
            _processingCheckTimer = null;

            // Show completion notification
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content:
                    Text('Document processing completed! Ready for search.'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 4),
              ),
            );
          } else if (statusData['processing_status'] == 'failed') {
            setState(() {
              _isProcessing = false;
              _uploadResult = 'Processing failed. Please try uploading again.';
            });
            timer.cancel();

            // ← NEW: Also cancel the processing check timer
            _processingCheckTimer?.cancel();
            _processingCheckTimer = null;
          }
          // If still processing, keep polling
        }
      } catch (e) {
        // If error checking status, stop polling but don't show error
        // (processing might still be happening)
        timer.cancel();

        // ← NEW: Also cancel the processing check timer on error
        _processingCheckTimer?.cancel();
        _processingCheckTimer = null;

        setState(() {
          _isProcessing = false;
        });
      }
    });
  }

  Future<void> _uploadFile() async {
    if (_selectedFile == null || _userIdController.text.trim().isEmpty) {
      setState(() {
        _uploadResult = 'Error: Please select a file and enter technician ID';
      });
      return;
    }

    setState(() {
      _isUploading = true;
      _uploadResult = null;
      _uploadProgress = 0.0;
      _isProcessing = false;
    });

    try {
      // Simulate upload progress
      for (int i = 0; i <= 100; i += 10) {
        await Future.delayed(Duration(milliseconds: 100));
        if (mounted) {
          setState(() {
            _uploadProgress = i / 100;
          });
        }
      }

      final result = await ApiService.uploadDocument(
        _selectedFile!,
        _userIdController.text.trim(),
      );

      setState(() {
        _isUploading = false;
        _uploadProgress = 1.0;

        if (result['success']) {
          final docId = result['data']['document_id'].toString();
          final status = result['data']['status'] ?? 'processing';

          _uploadResult = 'Upload successful! Document ID: $docId\n'
              'Status: $status\n'
              'Your manual is being processed in the background and will be searchable when complete.';

          _selectedFile = null;
          _selectedFileInfo = null;
          _uploadProgress = 0.0;

          // Start status polling
          _startStatusPolling(docId);
        } else {
          _uploadResult =
              'Upload failed: ${result['error'] ?? 'Unknown error'}';
        }
      });

      // Show success snackbar
      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Document uploaded successfully! Processing in background...'),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: 'View Documents',
              textColor: Colors.white,
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Go to Documents tab to view uploaded files'),
                  ),
                );
              },
            ),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isUploading = false;
        _uploadProgress = 0.0;
        _uploadResult = 'Upload error: $e';
        _isProcessing = false;
      });
    }
  }
}
