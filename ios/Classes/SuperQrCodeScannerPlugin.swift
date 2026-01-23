import Flutter
import UIKit

// Dummy references to prevent linker from stripping the C functions
@_silgen_name("qr_scan_image")
func qr_scan_image_dummy() -> UnsafeMutableRawPointer?

@_silgen_name("qr_scan_bytes") 
func qr_scan_bytes_dummy() -> UnsafeMutableRawPointer?

@_silgen_name("qr_free_result")
func qr_free_result_dummy()

public class SuperQrCodeScannerPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    // FFI plugin, no method channel needed
    // Dummy calls to prevent optimization
    _ = qr_scan_image_dummy()
    _ = qr_scan_bytes_dummy()
    qr_free_result_dummy()
  }
}