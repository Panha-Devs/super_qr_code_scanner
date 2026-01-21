import 'package:flutter/material.dart';
import 'package:super_qr_code_scanner/super_qr_code_scanner.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

void main() {
  // Configure QR Scanner
  QRScannerLogger.setEnabled(true);
  QRScannerLogger.setLevel(LogLevel.info);
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'QR Scanner Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const QRScannerPage(),
    );
  }
}

class QRScannerPage extends StatefulWidget {
  const QRScannerPage({super.key});

  @override
  State<QRScannerPage> createState() => _QRScannerPageState();
}

class _QRScannerPageState extends State<QRScannerPage> {
  final _scanner = SuperQRCodeScanner();
  final _picker = ImagePicker();
  List<QRCode> _results = [];
  bool _isScanning = false;
  String? _imagePath;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Configure scanner for accuracy
    _scanner.updateConfig(QRScannerConfig.accurateConfig);
  }

  Future<void> _pickAndScanImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      
      if (image == null) return;

      setState(() {
        _isScanning = true;
        _imagePath = image.path;
        _results = [];
        _errorMessage = null;
      });

      // Scan QR codes
      final results = await Future.microtask(
        () => _scanner.scanImageFile(image.path),
      );

      setState(() {
        _results = results;
        _isScanning = false;
      });
    } on InvalidParameterException catch (e) {
      setState(() {
        _isScanning = false;
        _errorMessage = 'Invalid image: ${e.message}';
      });
    } on ImageProcessingException catch (e) {
      setState(() {
        _isScanning = false;
        _errorMessage = 'Processing failed: ${e.message}';
      });
    } catch (e) {
      setState(() {
        _isScanning = false;
        _errorMessage = 'Error: $e';
      });
    }
  }

  Future<void> _takePhotoAndScan() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.camera);
      
      if (image == null) return;

      setState(() {
        _isScanning = true;
        _imagePath = image.path;
        _results = [];
        _errorMessage = null;
      });

      final results = await Future.microtask(
        () => _scanner.scanImageFile(image.path),
      );

      setState(() {
        _results = results;
        _isScanning = false;
      });
    } on InvalidParameterException catch (e) {
      setState(() {
        _isScanning = false;
        _errorMessage = 'Invalid image: ${e.message}';
      });
    } on ImageProcessingException catch (e) {
      setState(() {
        _isScanning = false;
        _errorMessage = 'Processing failed: ${e.message}';
      });
    } catch (e) {
      setState(() {
        _isScanning = false;
        _errorMessage = 'Error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('QR Code Scanner'),
      ),
      body: Column(
        children: [
          if (_imagePath != null)
            Expanded(
              flex: 2,
              child: Image.file(
                File(_imagePath!),
                fit: BoxFit.contain,
              ),
            ),
          
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: _isScanning ? null : _pickAndScanImage,
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Pick Image'),
                ),
                ElevatedButton.icon(
                  onPressed: _isScanning ? null : _takePhotoAndScan,
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Take Photo'),
                ),
              ],
            ),
          ),

          if (_isScanning)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            ),

          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                color: Colors.red.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      Icon(Icons.error, color: Colors.red.shade700),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(color: Colors.red.shade700),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          Expanded(
            flex: 3,
            child: _buildResults(),
          ),
        ],
      ),
    );
  }

  Widget _buildResults() {
    if (_isScanning) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Scanning QR codes...'),
          ],
        ),
      );
    }

    if (_results.isEmpty && _imagePath != null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.qr_code_scanner, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No QR codes found',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    if (_results.isEmpty) {
      return const Center(
        child: Text(
          'Select an image to scan for QR codes',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _results.length,
      itemBuilder: (context, index) {
        final qr = _results[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              child: Text('${index + 1}'),
            ),
            title: Text(
              qr.format,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: SelectableText(
              qr.content,
              style: const TextStyle(fontSize: 14),
            ),
            isThreeLine: true,
          ),
        );
      },
    );
  }
}
