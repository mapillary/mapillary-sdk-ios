Pod::Spec.new do |s|

  s.name             = 'MapillarySDK'
  s.version          = '0.0.1'
  s.platform         = :ios, '8.0'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.summary          = 'Mapillary is a platform for creating street-level imagery and extract data using computer vision'
  s.homepage         = 'https://github.com/mapillary/mapillary-sdk-ios'
  s.social_media_url = 'https://twitter.com/mapillary'
  s.author           = { 'Anders Mårtensson' => 'anders@mapillary.com' }
  s.source           = { :git => 'https://github.com/mapillary/mapillary-sdk-ios.git', :tag => s.version.to_s }
  s.source_files     = 'MapillarySDK', 'MapillarySDK/MapillarySDK/**/*.{h,m}', 'MapillarySDK/internal'
  s.requires_arc     = true
  s.dependency 'AFNetworking', '~> 3.0'
  s.dependency 'BOSImageResizeOperation', '~> 0.1'
  s.dependency 'OCMockito', '~> 5.0'
  s.dependency 'SDVersion', '~> 4.0'
  s.dependency 'AWSCore', '~> 2.6'
  s.dependency 'AWSS3', '~> 2.6'

end
