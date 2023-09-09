Pod::Spec.new do |s|

  # ―――  Spec Metadata  ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #

  s.name = "OSRMTextInstructions"
  s.version = "0.6.0"
  s.summary = "Transforms OSRM route reponses into human-readable instructions."

  s.description  = <<-DESC
  OSRMTextInstructions transforms OSRM route responses into localized, human-readable turn-by-turn instructions. Primarily intended for use with MapboxDirections.swift.
                DESC

  s.homepage = "http://project-osrm.org/"

  # ―――  Spec License  ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #

  s.license = { :type => "BSD", :file => "LICENSE.md" }

  # ――― Author Metadata  ――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #

  s.author = { "Mapbox" => "mobile@mapbox.com" }
  s.social_media_url   = "https://twitter.com/mapbox"

  # ――― Platform Specifics ――――――――――――――――――――――――――――――――――――――――――――――――――――――― #

  #  When using multiple platforms
  s.ios.deployment_target = "8.0"
  s.osx.deployment_target = "10.10"
  s.watchos.deployment_target = "2.0"
  s.tvos.deployment_target = "9.0"

  # ――― Source Location ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #

  s.source = { :git => "https://github.com/Project-OSRM/osrm-text-instructions.swift.git", :tag => "v#{s.version.to_s}" }

  # ――― Resources ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #

  s.resources = ['OSRMTextInstructions/*.lproj/*.plist']

  # ――― Source Code ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #

  s.source_files = "OSRMTextInstructions"

  # ――― Project Settings ――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #

  s.requires_arc = true
  s.module_name = "OSRMTextInstructions"

  s.dependency "MapboxDirections.swift", "~> 2.0"

end
