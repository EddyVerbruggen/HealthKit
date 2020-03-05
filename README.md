# Cordova HealthKit Plugin

[![NPM version][npm-image]][npm-url]
[![Downloads][downloads-image]][npm-url]
[![Twitter Follow][twitter-image]][twitter-url]

[npm-image]:http://img.shields.io/npm/v/com.telerik.plugins.healthkit.svg
[npm-url]:https://npmjs.org/package/com.telerik.plugins.healthkit
[downloads-image]:http://img.shields.io/npm/dm/com.telerik.plugins.healthkit.svg
[twitter-image]:https://img.shields.io/twitter/follow/eddyverbruggen.svg?style=social&label=Follow%20me
[twitter-url]:https://twitter.com/eddyverbruggen

<img src="img/healthkit-hero_2x.png" width="128px" height="128px"/>

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

#### Using PhoneGap Build?

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
#### Using PhoneGap Build - cli-7 or superior?

PhoneGap Build has [recently migrated](https://blog.phonegap.com/phonegap-7-0-1-now-on-build-and-it-includes-some-important-changes-89087fe465f5) from the custom build process to the standard Cordova build process. If you are already running on the new builder, it is no longer necessary to add the variables differently, and the variables must be defined as in the Cordova case.

```xml
<platform name="ios">
    <plugin name="com.telerik.plugins.healthkit" spec="^0.5.5" >
        <variable name="HEALTH_READ_PERMISSION" value="App needs read access" />
        <variable name="HEALTH_WRITE_PERMISSION" value="App needs write access" />
    </plugin>        
</platform>
```

#### Need Clinical Records Functionality (FHIR)?

If you would like to read clinical record (FHIR) data from the HealthKit store you can use the [fork of this plugin here](https://github.com/rossmartin/HealthKit). Please see https://github.com/EddyVerbruggen/HealthKit/issues/113 for why this was functionality was removed from this plugin.
