# Cordova HealthKit Plugin

<img src="img/healthkit-hero_2x.png" width="128px" height="128px"/>
<table width="100%">
  <tr>
    <td width="100"><a href="http://plugins.telerik.com/plugin/healthkit"><img src="http://www.x-services.nl/github-images/telerik-verified-plugins-marketplace.png" width="97px" height="71px" alt="Marketplace logo"/></a></td>
    <td>For a quick demo app and easy code samples, check out the plugin page at the Verified Plugins Marketplace: http://plugins.telerik.com/plugin/healthkit</td>
  </tr>
</table>

### Supported functions

[See the example](demo/index.html) for how to use these functions.

* `available`: check if HealthKit is supported (iOS8+, not on iPad)
* `checkAuthStatus`: pass in a type and get back on of undetermined | denied | authorized
* `requestAuthorization`: ask some or all permissions up front
* `readDateOfBirth`: formatted as yyyy-MM-dd
* `readGender`: output = male|female|other|unknown
* `readBloodType`: output = A+|A-|B+|B-|AB+|AB-|O+|O-|unknown
* `readFitzpatrickSkinType`: output = I|II|III|IV|V|VI|unknown
* `readWeight`: pass in unit (g=gram, kg=kilogram, oz=ounce, lb=pound, st=stone)
* `saveWeight`: pass in unit (g=gram, kg=kilogram, oz=ounce, lb=pound, st=stone) and amount
* `readHeight`: pass in unit (mm=millimeter, cm=centimeter, m=meter, in=inch, ft=foot)
* `saveHeight`: pass in unit (mm=millimeter, cm=centimeter, m=meter, in=inch, ft=foot) and amount
* `saveWorkout`
* `findWorkouts`: no params yet, so this will return all workouts ever of any type
* `querySampleType`
* `querySampleTypeAggregated`
* `sumQuantityType`
* `monitorSampleType`
* `saveQuantitySample`
* `saveCorrelation`
* `queryCorrelationType`
* `deleteSamples`

### Resources

* The official Apple documentation for [HealthKit can be found here](https://developer.apple.com/library/ios/documentation/HealthKit/Reference/HealthKit_Framework/index.html#//apple_ref/doc/uid/TP40014707).

* For functions that require the `unit` attribute, you can find the [comprehensive list of possible units from the Apple Developers documentation](https://developer.apple.com/library/ios/documentation/HealthKit/Reference/HKUnit_Class/index.html#//apple_ref/doc/uid/TP40014727-CH1-SW2).

### Tips
* Make sure your app id has the 'HealthKit' entitlement when this plugin is installed. This is added automatically to your app if you use cordova-ios 4.3.0 or higher.
* Also, make sure your app and AppStore description complies with these Apple review guidelines: https://developer.apple.com/app-store/review/guidelines/#healthkit

### Installation

Using the Cordova CLI?

```bash
cordova plugin add com.telerik.plugins.healthkit --variable HEALTH_READ_PERMISSION='App needs read access' --variable HEALTH_WRITE_PERMISSION='App needs write access'
```
`HEALTH_READ_PERMISSION` and `HEALTH_WRITE_PERMISSION` are shown when your app asks for access to data in HealthKit.

Using PhoneGap Build?

```xml
<plugin name="com.telerik.plugins.healthkit" source="npm" />

<!-- Read access -->
<config-file platform="ios" parent="NSHealthShareUsageDescription">
  <string>App needs read access</string>
</config-file>
<!-- Write access -->
<config-file platform="ios" parent="NSHealthUpdateUsageDescription">
  <string>App needs write access</string>
</config-file>
```
