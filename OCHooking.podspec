#
# Be sure to run `pod lib lint OCHooking.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'OCHooking'
  s.version          = '0.1.1'

  # basic 基础组件 
  # weakbusiness 弱业务组件
  # business 业务组件
  
  s.summary          = 'business A short description of OCHooking.'

  # This description is used to generate tags and improve search results.
  #   * Think: What does it do? Why did you write it? What is the focus?
  #   * Try to keep it short, snappy and to the point.
  #   * Write the description between the DESC delimiters below.
  #   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
TODO: Add long description of the pod here.
                       DESC

  s.homepage         = 'http://git.2dfire.net/ios/OCHooking'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'tripleCC' => 'triplec.linux@gmail.com' }
  s.source           = { :git => 'http://git.2dfire.net/ios/OCHooking.git', :tag => s.version.to_s }
  s.ios.deployment_target = '8.0'
  
  s.source_files = 'OCHooking/Classes/**/*'
  s.public_header_files = 'OCHooking/Classes/**/*.{h}'
  # s.private_header_files = 

  # 资源依赖必须使用 bundle
  # s.resource_bundles = {
  #     'OCHooking' => ['OCHooking/Assets/*']
  # }
  # ['OCHooking/Assets/*.{xcassets}']

  # s.dependency 'TDFModuleKit'
end
