Pod::Spec.new do |s|
  s.name           = 'NativeHealth'
  s.version        = '1.0.0'
  s.summary        = 'Native HealthKit bridge for HealthShop'
  s.description    = 'Local Expo module bridging Apple HealthKit.'
  s.author         = 'HealthShop'
  s.homepage       = 'https://example.com'
  s.platforms      = { :ios => '16.4' }
  s.source         = { :path => '.' }
  s.source_files   = '**/*.{swift,h,m,mm}'
  s.dependency 'ExpoModulesCore'
  s.swift_version = '5.0'
end
