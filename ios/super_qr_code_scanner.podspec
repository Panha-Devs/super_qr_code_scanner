Pod::Spec.new do |s|
  s.name             = 'super_qr_code_scanner'
  s.version          = '1.0.0'
  s.summary          = 'High-performance QR code scanner'
  s.description      = 'QR code scanner using ZXing C++ and OpenCV'
  s.homepage         = 'https://github.com/yourusername/super_qr_code_scanner'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Name' => 'your.email@example.com' }
  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*', '../src/super_qr_code_scanner_api.{h,cpp}', '../src/zxing-cpp-core/src/**/*.{h,cpp,c}'
  s.public_header_files = 'Classes/**/*.h', '../src/super_qr_code_scanner_api.h'
  s.dependency 'Flutter'
  s.platform = :ios, '12.0'
  s.swift_version = '5.0'
  
  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386',
    'HEADER_SEARCH_PATHS' => '"${PODS_TARGET_SRCROOT}/../src/zxing-cpp-core/src" "$(inherited)"',
    'OTHER_CPLUSPLUSFLAGS' => '-std=c++17'
  }
  
  s.frameworks = 'AVFoundation', 'CoreMedia', 'CoreVideo', 'CoreImage'
  
  # OpenCV dependency
  s.dependency 'OpenCV', '~> 4.5'
end
