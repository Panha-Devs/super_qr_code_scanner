import 'package:super_qr_code_scanner/src/models.dart';

extension QrCodeModelExtension on QRCode {
  bool get isQrCode {
    return format == 'QRCode';
  }
}

extension QrCodeListExtension on List<QRCode> {
  List<QRCode> get qrCodes {
    return where((qrCode) => qrCode.isQrCode).toList();
  }
}
