# Cordova HealthKit Plugin
by [Eddy Verbruggen](https://twitter.com/eddyverbruggen)

<img src="img/healthkit-hero_2x.png" width="128px" height="128px"/>


## Work in progress
Things may break if you use this now.

### Supported functions:
* available: check if HealthKit is supported (iOS8+, not on iPad)
* readDateOfBirth: formatted as yyyy-MM-dd
* readGender: output = male|female|unknown
* readWeight: pass in unit
* saveWeight: pass in unit (g=grams, kg=kilograms, oz=ounces, lb=pounds, st=stones) and amount

### Currently in progress:
* saveWorkout

### Planned functions:
* readHeight
* saveHeight
* requestPermission(s)
* .. wishes? plz create an issue with your feature request

## Tips
* Make sure your app id has the 'HealthKit' entitlement when this plugin is installed.
* Also, make sure your app and AppStore description complies with these Apple review guidelines: https://developer.apple.com/app-store/review/guidelines/#healthkit
