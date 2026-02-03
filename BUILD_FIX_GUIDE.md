# Fixing iOS Deployment target issues
# This happens when some pods have an older deployment target than what Xcode supports.

In your `ios/Podfile`, update the `post_install` block as follows:

```ruby
post_install do |installer|
  installer.pods_project.targets.each do |target|
    flutter_additional_ios_build_settings(target)
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '13.0'
    end
  end
end
```

Then run:
1. `cd ios`
2. `rm -rf Pods Podfile.lock`
3. `pod install`
4. `cd ..`
5. `flutter run`
