function HealthKit() {
}

HealthKit.prototype.available = function (successCallback, errorCallback) {
  cordova.exec(successCallback, errorCallback, "HealthKit", "available", []);
};

HealthKit.prototype.saveWeight = function (options, successCallback, errorCallback) {
  cordova.exec(successCallback, errorCallback, "HealthKit", "saveWeight", [options]);
};

HealthKit.prototype.readWeight = function (options, successCallback, errorCallback) {
  cordova.exec(successCallback, errorCallback, "HealthKit", "readWeight", [options]);
};

HealthKit.install = function () {
  if (!window.plugins) {
    window.plugins = {};
  }

  window.plugins.healthkit = new HealthKit();
  return window.plugins.healthkit;
};

cordova.addConstructor(HealthKit.install);