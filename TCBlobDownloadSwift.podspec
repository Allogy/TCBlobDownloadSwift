Pod::Spec.new do |s|
  s.name         = "TCBlobDownloadSwift"
  s.version      = "0.3.2"
  s.summary      = "Powerful file downloads manager in Swift"
  s.homepage     = "https://github.com/thibaultCha/TCBlobDownloadSwift"
  s.license      = { :type => "MIT", :file => "LICENSE" }
  s.author       = { "Thibault Charbonnier" => "thibaultcha@me.com" }

  s.ios.deployment_target = "9.0"
  s.osx.deployment_target = "10.10"

  s.source       = {
    :git => "https://github.com/bonebox/TCBlobDownloadSwift.git",
    :tag => s.version.to_s
  }

  s.source_files = "Source/*.{h,swift}"
  s.requires_arc = true
end
