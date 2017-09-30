Pod::Spec.new do |s|
  s.name             = "Promise"
  s.version          = "v2.0"
  s.summary          = "A Promise library for Swift"
  s.description      = "A Promise library for Swift, based partially on Javascript's A+ spec"
  s.module_name      = "Promise"
  s.homepage         = "https://github.com/khanlou/Promise"
  s.license          = 'MIT'
  s.author           = { "Soroush Khanlou" => "soroush@khanlou.com" }
  s.source           = { :git => "https://github.com/khanlou/Promise.git", :tag => "#{spec.version}" }
  s.social_media_url = 'https://twitter.com/khanlou'
  s.source_files = 'Sources/*.swift'
  s.cocoapods_version = '>= 1.0'
  s.ios.deployment_target = '9.0'
  s.osx.deployment_target = '10.11'
  s.frameworks = 'Foundation'
end