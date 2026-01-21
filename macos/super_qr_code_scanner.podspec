#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint super_qr_code_scanner.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'super_qr_code_scanner'
  s.version          = '1.0.0'
  s.summary          = 'High-performance QR code scanner using ZXing-C++ and OpenCV'
  s.description      = <<-DESC
A Flutter plugin for scanning QR codes from images using native ZXing-C++ and OpenCV libraries.
                       DESC
  s.homepage         = 'http://example.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'email@example.com' }

  # This will ensure the source files in Classes/ are included in the native
  # builds of apps using this FFI plugin. Podspec does not support relative
  # paths, so Classes contains a forwarder C file that relatively imports
  # `../src/*` so that the C sources can be shared among all target platforms.
  s.source           = { :path => '.' }
  # s.source           = { :git => 'https://git.code.sf.net/p/libzueci/code', :branch => 'master' }
  s.source_files     = 'Classes/**/*'
  s.dependency 'FlutterMacOS'

  s.platform = :osx, '10.15'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
  s.swift_version = '5.0'

  s.xcconfig = {
    'CLANG_CXX_LANGUAGE_STANDARD' => 'c++20',
  }

  s.library = 'c++'

end
