Pod::Spec.new do |s|
  s.name             = 'PushApp-IOS'
  s.version          = '0.1.3'
  s.summary          = 'Push and in-app notification SDK for iOS apps.'
  s.description      = 'Provides Firebase/APNs token registration, in-app rule engine handling, and custom in-app rendering using SwiftUI/WebKit.'
  s.homepage         = 'https://github.com/mehery-soccom/PushApp-IOS.git'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'meherysoccom' => 'ninja.kawasaki@gmail.com' }
  s.source           = { :git => 'https://github.com/mehery-soccom/PushApp-IOS.git', :tag => s.version.to_s }

  s.ios.deployment_target = '13.0'
  s.swift_version = '5.0'
  s.source_files = 'Classes/**/*.swift'

  s.frameworks = ['UIKit', 'Foundation', 'WebKit', 'UserNotifications', 'SwiftUI']
end
