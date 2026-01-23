#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint super_qr_code_scanner.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'super_qr_code_scanner'
  s.version          = '1.0.6'
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
    'OTHER_LDFLAGS' => '-force_load ${PODS_ROOT}/../.symlinks/plugins/super_qr_code_scanner/ios/libs/libsuper_qr_code_scanner.a'
  }

  # including C++ library
  s.library = 'c++'
  s.library = 'z'

  # --------------------------
  # Prepare command: build native static lib
  # --------------------------
  s.prepare_command = <<-CMD
    cd ../src
    echo "Starting build super_qr_code_scanner static from scrip: ${PWD}"
    FORCE_FLAG=${FORCE_BUILD:-"force"}
    sh ../script/prepare-ios-lib.sh $FORCE_FLAG
  CMD

  # --------------------------
  # Vendored static library
  # --------------------------
  # This path is relative to the podspec (ios/)
  s.vendored_library = 'libs/libsuper_qr_code_scanner.a'

  # module_map is needed so this module can be used as a framework
  s.module_map = 'super_qr_code_scanner.modulemap'
end
