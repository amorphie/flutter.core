#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint enverify.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'enverify'
  s.version          = '0.0.1'
  s.summary          = 'A new Flutter plugin project.'
  s.description      = <<-DESC
A new Flutter plugin project.
                       DESC
  s.homepage         = 'http://example.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'email@example.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '11.0'
  s.ios.deployment_target = '11.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'

  s.dependency 'EnVerify', '1.3.14.2'
  s.dependency 'Starscream', '3.0.6'
  s.dependency 'GoogleWebRTC'
  s.dependency 'GoogleMLKit/FaceDetection'
  s.dependency 'GoogleMLKit/BarcodeScanning'
  s.dependency 'TensorFlowLiteSwift'
  s.dependency 'Socket.IO-Client-Swift', '14.0.0'
  s.dependency 'Alamofire', '5.6.2'
  s.dependency 'GoogleMLKit/TextRecognition', '2.2.0'
  s.dependency 'OpenSSL-Universal', '1.1.1900'
  s.dependency 'SwiftyJSON', '5.0'
end
