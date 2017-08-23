Pod::Spec.new do |s|

  s.name         = "MapillarySDK"
  s.version      = "0.0.1"
  s.summary      = "A short description of MapillarySDK."  
  s.description  = "TODO description"
  s.homepage     = "https://www.mapillary.com"
  s.license      = "MIT"
  s.author       = { "Anders Mårtensson" => "anders@mapillary.com" }
  s.platform     = :ios, "8.0"
  s.source       = { :path => '.' }  
  s.source_files = "MapillarySDK", "MapillarySDK/MapillarySDK/**/*.{h,m}"
  
end
