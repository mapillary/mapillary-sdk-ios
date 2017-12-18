Pod::Spec.new do |s|

  s.name         = "MapillarySDK"
  s.version      = "0.111111"
  s.summary      = "A short description of MapillarySDK."  
  s.description  = "TODO description"
  s.homepage     = "https://www.mapillary.com"
  s.license      = "MIT"
  s.author       = { "Anders Mårtensson" => "anders@mapillary.com" }
  s.platform     = :ios, "8.0"
  s.requires_arc = true
  s.source       = { :path => '.' }
  s.source_files = "MapillarySDK", "MapillarySDK/MapillarySDK/**/*.{h,m}", "MapillarySDK/internal"
  s.dependency   'BOSImageResizeOperation', '~> 0.1'
  
end
