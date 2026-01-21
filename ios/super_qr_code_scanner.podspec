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
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '12.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'

  s.xcconfig = { 
    'CLANG_CXX_LANGUAGE_STANDARD' => 'c++20',
  }

  # including C++ library
  s.library = 'c++'

  # # Set as a static lib
  # s.static_framework = true

  # module_map is needed so this module can be used as a framework
  s.module_map = 'super_qr_code_scanner.modulemap'
end
