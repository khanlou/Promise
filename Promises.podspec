Pod::Spec.new do |s|
  s.name             = "Promises"
  s.version          = "2.0.1"
  s.summary          = "A Promise library for Swift"
  s.description      = "A Promise library for Swift, based partially on Javascript's A+ spec"
  s.module_name      = "Promise"
  s.homepage         = "https://github.com/khanlou/Promise"
  s.license          = 'MIT'
  s.authors           = { "Soroush Khanlou" => "soroush@khanlou.com" }
  s.source           = { :git => 'https://github.com/khanlou/Promise.git', :tag => "#{s.version}" }
  s.social_media_url = 'https://twitter.com/khanlou'
  s.source_files = 'Promise/*.swift'
  s.cocoapods_version = '>= 1.0'
  s.ios.deployment_target = '9.0'
  s.osx.deployment_target = '10.11'
  s.tvos.deployment_target = "9.0"
  s.watchos.deployment_target = "2.0"
  s.frameworks = 'Foundation'
end
