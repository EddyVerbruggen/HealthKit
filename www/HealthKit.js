function HealthKit() {
}

HealthKit.prototype.available = function (successCallback, errorCallback) {
  cordova.exec(successCallback, errorCallback, "HealthKit", "available", []);
};

HealthKit.prototype.requestAuthorization = function (options, successCallback, errorCallback) {
  cordova.exec(successCallback, errorCallback, "HealthKit", "requestAuthorization", [options]);
};

HealthKit.prototype.readDateOfBirth = function (successCallback, errorCallback) {
  cordova.exec(successCallback, errorCallback, "HealthKit", "readDateOfBirth", []);
};

HealthKit.prototype.readGender = function (successCallback, errorCallback) {
  cordova.exec(successCallback, errorCallback, "HealthKit", "readGender", []);
};

HealthKit.prototype.saveWeight = function (options, successCallback, errorCallback) {
  if (options.date === undefined) {
    options.date = new Date();
  }
  if (typeof options.date == 'object') {
    options.date = Math.round(options.date.getTime()/1000);
  }
  cordova.exec(successCallback, errorCallback, "HealthKit", "saveWeight", [options]);
};

HealthKit.prototype.readWeight = function (options, successCallback, errorCallback) {
  cordova.exec(successCallback, errorCallback, "HealthKit", "readWeight", [options]);
};

HealthKit.prototype.saveHeight = function (options, successCallback, errorCallback) {
  if (options.date === undefined) {
    options.date = new Date();
  }
  if (typeof options.date == 'object') {
    options.date = Math.round(options.date.getTime()/1000);
  }
  cordova.exec(successCallback, errorCallback, "HealthKit", "saveHeight", [options]);
};

HealthKit.prototype.readHeight = function (options, successCallback, errorCallback) {
  cordova.exec(successCallback, errorCallback, "HealthKit", "readHeight", [options]);
};

HealthKit.prototype.findWorkouts = function (options, successCallback, errorCallback) {
  cordova.exec(successCallback, errorCallback, "HealthKit", "findWorkouts", [options]);
};

HealthKit.prototype.saveWorkout = function (options, successCallback, errorCallback) {
  if (!options.startDate instanceof Date) {
    errorCallback("startDate must be a JavaScript Date Object");
    return;
  }
  options.startDate = Math.round(options.startDate.getTime()/1000);

  if (!(options.endDate instanceof Date || options.duration > 0)) {
    errorCallback("endDate must be JavaScript Date Object, or the duration must be set");
    return;
  }
  if (options.endDate instanceof Date) {
    options.endDate = Math.round(options.endDate.getTime()/1000);
  }

  var opts = options || {};
  cordova.exec(successCallback, errorCallback, "HealthKit", "saveWorkout", [opts]);
};
               
HealthKit.prototype.monitorSampleType = function (options, successCallback, errorCallback) {
    
    
    if (!(options.sampleType)) {
        errorCallback("Missing required paramter sampleType");
    }
    
    var opts = options || {};
    
    
    cordova.exec(successCallback, errorCallback, "HealthKit", "monitorSampleType", [opts]);
};

           
HealthKit.prototype.querySampleType = function (options, successCallback, errorCallback) {

    if (!(options.sampleType)) {
        errorCallback("Missing required paramter sampleType");
    }

    if (!options.startDate instanceof Date) {
      errorCallback("startDate must be a JavaScript Date Object");
      return;
    }
    options.startDate = Math.round(options.startDate.getTime()/1000);

    if (!options.endDate instanceof Date) {
      errorCallback("endDate must be a JavaScript Date Object");
      return;
    }
                   
    if (options.endDate instanceof Date) {
      options.endDate = Math.round(options.endDate.getTime()/1000);
    }

    var opts = options || {};
                   
                   
    cordova.exec(successCallback, errorCallback, "HealthKit", "querySampleType", [opts]);
};


HealthKit.prototype.sumQuantityType = function (options, successCallback, errorCallback) {
    
    if (!(options.sampleType)) {
        errorCallback("Missing required paramter sampleType");
    }
    
    if (!options.startDate instanceof Date) {
        errorCallback("startDate must be a JavaScript Date Object");
        return;
    }
    options.startDate = Math.round(options.startDate.getTime()/1000);
    
    if (!options.endDate instanceof Date) {
        errorCallback("endDate must be a JavaScript Date Object");
        return;
    }
    
    if (options.endDate instanceof Date) {
        options.endDate = Math.round(options.endDate.getTime()/1000);
    }
    
    var opts = options || {};
    
    
    cordova.exec(successCallback, errorCallback, "HealthKit", "sumQuantityType", [opts]);
};


HealthKit.install = function () {
  if (!window.plugins) {
    window.plugins = {};
  }

  window.plugins.healthkit = new HealthKit();
  return window.plugins.healthkit;
};

cordova.addConstructor(HealthKit.install);
