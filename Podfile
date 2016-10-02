# Uncomment this line to define a global platform for your project
# platform :ios, '8.0'
# Uncomment this line if you're using Swift
use_frameworks!

target 'Lucid Weather Clock' do

pod 'ForecastIO', :git => 'https://github.com/sxg/ForecastIO.git', :branch => 'swift3'
pod 'BEMAnalogClock', :git => 'https://wrutkowski@github.com/wrutkowski/BEMAnalogClock.git'
pod 'Charts', :git => 'https://github.com/danielgindi/Charts.git', :branch => 'Chart2.2.5-Swift3.0'
pod 'INTULocationManager'

end

post_install do |installer|
    installer.pods_project.targets.each do |target|
        target.build_configurations.each do |config|
            config.build_settings['SWIFT_VERSION'] = '3.0'
        end
    end
end
