function HealthKit() {
}

HealthKit.prototype.available = function (successCallback, errorCallback) {
  cordova.exec(successCallback, errorCallback, "HealthKit", "available", []);
};

HealthKit.prototype.readDateOfBirth = function (successCallback, errorCallback) {
  cordova.exec(successCallback, errorCallback, "HealthKit", "readDateOfBirth", []);
};

HealthKit.prototype.saveWeight = function (options, successCallback, errorCallback) {
  cordova.exec(successCallback, errorCallback, "HealthKit", "saveWeight", [options]);
};

HealthKit.prototype.readWeight = function (options, successCallback, errorCallback) {
  cordova.exec(successCallback, errorCallback, "HealthKit", "readWeight", [options]);
};

HealthKit.prototype.saveWorkout = function (options, successCallback, errorCallback) {
  cordova.exec(successCallback, errorCallback, "HealthKit", "saveWorkout", [options]);
};

HealthKit.install = function () {
  if (!window.plugins) {
    window.plugins = {};
  }

  window.plugins.healthkit = new HealthKit();
  return window.plugins.healthkit;
};

cordova.addConstructor(HealthKit.install);