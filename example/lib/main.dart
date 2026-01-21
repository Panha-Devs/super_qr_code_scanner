import 'package:flutter/material.dart';
import 'package:super_qr_code_scanner/super_qr_code_scanner.dart';
import 'package:image_picker/image_picker.dart';

void main() {
  // Enable logging for debugging
  QRScannerLogger.setEnabled(true);
  QRScannerLogger.setLevel(LogLevel.info);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Super QR Code Scanner Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const QRScannerDemo(),
    );
  }
}

class QRScannerDemo extends StatefulWidget {
  const QRScannerDemo({super.key});

  @override
  State<QRScannerDemo> createState() => _QRScannerDemoState();
}

class _QRScannerDemoState extends State<QRScannerDemo> {
  final scanner = SuperQRCodeScanner();
  final imagePicker = ImagePicker();
  List<QRCode> results = [];
  bool isScanning = false;
  String? errorMessage;
  String selectedConfig = 'Default';

  @override
  void initState() {
    super.initState();
    // Initialize with default config
    scanner.updateConfig(QRScannerConfig.defaultConfig);
  }

  void _updateConfig(String config) {
    setState(() {
      selectedConfig = config;
    });

    switch (config) {
      case 'Fast':
        scanner.updateConfig(QRScannerConfig.fastConfig);
        break;
      case 'Accurate':
        scanner.updateConfig(QRScannerConfig.accurateConfig);
        break;
      default:
        scanner.updateConfig(QRScannerConfig.defaultConfig);
    }

    _showSnackBar('Configuration changed to $config');
  }

  Future<void> _scanFromGallery() async {
    await _scanImage(ImageSource.gallery);
  }

  Future<void> _scanFromCamera() async {
    await _scanImage(ImageSource.camera);
  }

  Future<void> _scanImage(ImageSource source) async {
    setState(() {
      isScanning = true;
      errorMessage = null;
      results = [];
    });

    try {
      // Pick image from gallery or camera
      final XFile? pickedFile = await imagePicker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
      );

      if (pickedFile == null) {
        setState(() {
          isScanning = false;
        });
        _showSnackBar('No image selected');
        return;
      }

      // Run scan in background to avoid blocking UI
      final qrCodes = await scanner.scanImageFile(pickedFile.path);

      setState(() {
        results = qrCodes;
        isScanning = false;
      });

      if (qrCodes.isEmpty) {
        _showSnackBar('No QR codes found in image');
      } else {
        _showSnackBar('Found ${qrCodes.length} QR code(s)');
      }
    } on InvalidParameterException catch (e) {
      setState(() {
        isScanning = false;
        errorMessage = 'Invalid input: ${e.message}';
      });
      _showSnackBar(errorMessage!);
    } on ImageProcessingException catch (e) {
      setState(() {
        isScanning = false;
        errorMessage = 'Processing failed: ${e.message}';
      });
      _showSnackBar(errorMessage!);
    } catch (e) {
      setState(() {
        isScanning = false;
        errorMessage = 'Error: $e';
      });
      _showSnackBar(errorMessage!);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Super QR Code Scanner'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Configuration selector
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Configuration',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(
                            value: 'Fast',
                            label: Text('Fast'),
                            icon: Icon(Icons.speed),
                          ),
                          ButtonSegment(
                            value: 'Default',
                            label: Text('Default'),
                            icon: Icon(Icons.balance),
                          ),
                          ButtonSegment(
                            value: 'Accurate',
                            label: Text('Accurate'),
                            icon: Icon(Icons.high_quality),
                          ),
                        ],
                        selected: {selectedConfig},
                        onSelectionChanged: (Set<String> selection) {
                          _updateConfig(selection.first);
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Scan buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: isScanning ? null : _scanFromGallery,
                      icon: isScanning
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.photo_library),
                      label: const Text('Gallery'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: isScanning ? null : _scanFromCamera,
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Camera'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Results section
              if (results.isNotEmpty) ...[
                const Text(
                  'Results:',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 300,
                  child: ListView.builder(
                    itemCount: results.length,
                    itemBuilder: (context, index) {
                      final qr = results[index];
                      return Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            child: Text('${index + 1}'),
                          ),
                          title: Text(
                            qr.content,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text('Format: ${qr.format}'),
                          trailing: IconButton(
                            icon: const Icon(Icons.copy),
                            onPressed: () {
                              // In a real app, copy to clipboard
                              _showSnackBar('Copied: ${qr.content}');
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ] else if (errorMessage != null)
                Card(
                  color: Colors.red.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            errorMessage!,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                const SizedBox(
                  height: 200,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.qr_code_2,
                          size: 64,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No results yet',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Scan an image to see QR codes',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 24),
              // Usage information
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue),
                          SizedBox(width: 8),
                          Text(
                            'How to use',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                      Text(
                        '1. Tap "Gallery" to select an image\n'
                        '   or "Camera" to take a photo\n\n'
                        '2. The app will scan for QR codes\n\n'
                        '3. Results will appear below\n\n'
                        'Tip: Try different configurations\n'
                        'for varying quality images',
                        style: TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
