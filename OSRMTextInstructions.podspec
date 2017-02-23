Pod::Spec.new do |s|

  # ―――  Spec Metadata  ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #

  s.name = "OSRMTextInstructions.swift"
  s.version = "0.0.1"
  s.summary = "Project OSRM text instructions"

  s.description  = <<-DESC
  OSRM Text Instructions is a library for iOS, macOS, tvOS, and watchOS applications written in Swift or Objective-C that transforms OSRM route responses into localized text instructions.
                DESC

  s.homepage = "http://project-osrm.org/"

  # ―――  Spec License  ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #

  s.license = { :type => "ISC", :file => "LICENSE.md" }

  # ――― Author Metadata  ――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #

  s.author = { "Mapbox" => "mobile@mapbox.com" }

  # ――― Platform Specifics ――――――――――――――――――――――――――――――――――――――――――――――――――――――― #

  s.ios.deployment_target = "9.0"

  # ――― Source Location ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #

  s.source = { :git => "https://github.com/Project-OSRM/osrm-text-instructions.swift.git", :tag => "v#{s.version.to_s}" }

  # ――― Source Code ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #

  s.source_files = "OSRMTextInstructions"

  # ――― Project Settings ――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #

  s.requires_arc = true
  s.module_name = "OSRMTextInstructions"

  s.dependency "MapboxDirections.swift"

  s.xcconfig = {
    "SWIFT_VERSION" => "3.0"
  }

end

