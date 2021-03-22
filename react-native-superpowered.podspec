require "json"

package = JSON.parse(File.read(File.join(__dir__, "package.json")))

Pod::Spec.new do |s|
  s.name         = "react-native-superpowered"
  s.version      = package["version"]
  s.summary      = package["description"]
  s.homepage     = package["homepage"]
  s.license      = package["license"]
  s.authors      = package["author"]

  s.platforms    = { :ios => "10.0" }
  s.source       = { :git => "https://github.com/craftmusic/SuperpoweredSDK.git", :tag => "#{s.version}" }

  
  s.source_files = "ios/**/*.{h,m,mm,hpp,swift}"
  # s.requires_arc = true
  # s.framework = "MediaPlayer"

  s.ios.source_files = "ios/**/*.{h,m,mm,hpp,swift", "Superpowered/OpenSource/SuperpoweredIOSAudioIO.h", "Superpowered/OpenSource/SuperpoweredIOSAudioIO.mm"
  s.ios.frameworks = "Foundation", "AVFoundation", "AudioToolbox", "CoreAudio", "CoreMedia", "UIKit", "MediaPlayer"
  s.ios.vendored_libraries = "Superpowered/libSuperpoweredAudioIOS.a"
 
  s.pod_target_xcconfig = { 'HEADER_SEARCH_PATHS' => '"${PODS_ROOT}/../../node_modules/react-native-superpowered/Superpowered"/**' }

  s.dependency "React"
end
