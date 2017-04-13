#
# Be sure to run `pod lib lint PhotoCaptionInputView.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'PhotoCaptionInputView'
  s.version          = '0.1.0'
  s.summary          = 'A short description of PhotoCaptionInputView.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
TODO: Add long description of the pod here.
                       DESC

  s.homepage         = 'https://github.com/nixplay/PhotoCaptionInputView'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'James Kong' => 'james.kong@nixplay.com' }
  s.source           = { :git => 'https://github.com/James Kong/PhotoCaptionInputView.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '9.0'

  s.source_files = 'PhotoCaptionInputView/Classes/**/*'
  s.resource_bundles = {
    'PhotoCaptionInputView' => ['Pod/Assets/*.png']
  }
  s.requires_arc = true
  s.frameworks = 'ImageIO', 'QuartzCore', 'AssetsLibrary', 'MediaPlayer'
  s.weak_frameworks = 'Photos'

  # s.resource_bundles = {
  #   'PhotoCaptionInputView' => ['PhotoCaptionInputView/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  # s.dependency 'AFNetworking', '~> 2.3'
  s.dependency 'MWPhotoBrowser'
end
