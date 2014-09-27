function HealthKit() {
}

HealthKit.prototype.available = function (successCallback, errorCallback) {
  cordova.exec(successCallback, errorCallback, "HealthKit", "available", []);
};

HealthKit.prototype.saveWeight = function (successCallback, errorCallback) {
  cordova.exec(successCallback, errorCallback, "HealthKit", "saveWeight", []);
};

HealthKit.prototype.readWeight = function (successCallback, errorCallback) {
  cordova.exec(successCallback, errorCallback, "HealthKit", "readWeight", []);
};

HealthKit.install = function () {
  if (!window.plugins) {
    window.plugins = {};
  }

  window.plugins.healthkit = new HealthKit();
  return window.plugins.healthkit;
};

cordova.addConstructor(HealthKit.install);