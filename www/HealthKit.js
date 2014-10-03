function HealthKit() {
}

HealthKit.prototype.available = function (successCallback, errorCallback) {
  cordova.exec(successCallback, errorCallback, "HealthKit", "available", []);
};

HealthKit.prototype.readDateOfBirth = function (successCallback, errorCallback) {
  cordova.exec(successCallback, errorCallback, "HealthKit", "readDateOfBirth", []);
};

HealthKit.prototype.readGender = function (successCallback, errorCallback) {
  cordova.exec(successCallback, errorCallback, "HealthKit", "readGender", []);
};

HealthKit.prototype.saveWeight = function (options, successCallback, errorCallback) {
  cordova.exec(successCallback, errorCallback, "HealthKit", "saveWeight", [options]);
};

HealthKit.prototype.readWeight = function (options, successCallback, errorCallback) {
  cordova.exec(successCallback, errorCallback, "HealthKit", "readWeight", [options]);
};

HealthKit.prototype.findWorkouts = function (options, successCallback, errorCallback) {
  cordova.exec(successCallback, errorCallback, "HealthKit", "findWorkouts", [options]);
};

HealthKit.prototype.saveWorkout = function (options, successCallback, errorCallback) {
  if (!options.startDate instanceof Date) {
    errorCallback("startDate must be a JavaScript Date Object");
    return;
  }
  if (!(options.endDate instanceof Date || options.duration > 0)) {
    errorCallback("endDate must be JavaScript Date Object, or the duration must be set");
    return;
  }
  var opts = options || {};
  opts.startTime = options.startDate.getTime();
  opts.endTime = options.endDate == null ? null : options.endDate.getTime();
  cordova.exec(successCallback, errorCallback, "HealthKit", "saveWorkout", [opts]);
};

HealthKit.install = function () {
  if (!window.plugins) {
    window.plugins = {};
  }

  window.plugins.healthkit = new HealthKit();
  return window.plugins.healthkit;
};

cordova.addConstructor(HealthKit.install);