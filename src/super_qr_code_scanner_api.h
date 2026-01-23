#ifndef SUPER_QR_CODE_SCANNER_API_H
#define SUPER_QR_CODE_SCANNER_API_H

#ifdef __cplusplus
extern "C" {
#endif

#if defined(_WIN32)
#define SUPER_QR_SCANNER_EXPORT __declspec(dllexport)
#else
#define SUPER_QR_SCANNER_EXPORT __attribute__((visibility("default")))
#endif

// Result structure for QR codes
typedef struct {
    char* content;
    char* format;
} QRCodeResult;

// Scan result containing multiple QR codes
typedef struct {
    QRCodeResult* results;
    int count;
} QRScanResult;

// Configuration for QR scanner
typedef struct {
    int max_symbols;
    int timeout_ms;
    int try_harder; // 1 = true, 0 = false
} QRScannerConfig;

// Scan QR codes from image file path
SUPER_QR_SCANNER_EXPORT QRScanResult* qr_scan_image(const char* image_path, QRScannerConfig* config);

// Scan QR codes from image bytes
SUPER_QR_SCANNER_EXPORT QRScanResult* qr_scan_bytes(const unsigned char* image_data, int width, int height, int channels, QRScannerConfig* config);

// Free scan result memory
SUPER_QR_SCANNER_EXPORT void qr_free_result(QRScanResult* result);

#ifdef __cplusplus
}
#endif

#endif // SUPER_QR_CODE_SCANNER_API_H
