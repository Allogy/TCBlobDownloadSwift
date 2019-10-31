Pod::Spec.new do |s|
  s.name         = "TCBlobDownloadSwift"
  s.version      = "0.7.0"
  s.summary      = "Powerful file downloads manager in Swift"
  s.homepage     = "https://github.com/thibaultCha/TCBlobDownloadSwift"
  s.license      = { :type => "MIT", :file => "LICENSE" }
  s.author       = { "Thibault Charbonnier" => "thibaultcha@me.com" }

  s.ios.deployment_target = "12.0"
  s.swift_version = '5.1'

  s.source       = {
    :git => "https://github.com/Allogy/TCBlobDownloadSwift.git",
    :tag => s.version.to_s
  }

  s.source_files = "Source/*.{h,swift}"
  s.requires_arc = true
end
