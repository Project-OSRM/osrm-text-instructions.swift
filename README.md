# OSRM Text Instructions for Swift

[![Build Status](https://travis-ci.org/Project-OSRM/osrm-text-instructions.swift.svg?branch=master)](https://travis-ci.org/Project-OSRM/osrm-text-instructions.swift)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![CocoaPods](https://img.shields.io/cocoapods/v/OSRMTextInstructions.svg)](http://cocoadocs.org/docsets/OSRMTextInstructions/)

OSRM Text Instructions is a library for iOS, macOS, tvOS, and watchOS applications written in Swift 4 or Objective-C that transforms [OSRM](http://www.project-osrm.org/) route responses into localized text instructions. The last tagged version for Swift 3.2 is `v0.5.0` and the code is also available on the branch [`swift3.2`](https://github.com/Project-OSRM/osrm-text-instructions.swift/tree/swift3.2).

You can use OSRM Text Instructions in conjunction with [MapboxDirections.swift](https://github.com/mapbox/MapboxDirections.swift/) and [MapboxNavigation.swift](https://github.com/mapbox/MapboxNavigation.swift/) to generate visual and voice guidance in a turn-by-turn navigation application.

OSRM Text Instructions for Swift is based on the canonical [osrm-text-instructions](https://github.com/Project-OSRM/osrm-text-instructions/) library written in JavaScript. Both versions are [translated at Transifex](https://www.transifex.com/project-osrm/osrm-text-instructions/) – please help us add support for the languages you speak.

## Getting started

Specify the following dependency in your [Carthage](https://github.com/Carthage/Carthage/) Cartfile:

```cartfile
github "Project-OSRM/osrm-text-instructions.swift" ~> 0.5.0
```

Or in your [CocoaPods](http://cocoapods.org/) Podfile:

```podspec
pod 'OSRMTextInstructions', '~> 0.5.0'
```

Then `import OSRMTextInstructions` or `@import OSRMTextInstructions;`.
