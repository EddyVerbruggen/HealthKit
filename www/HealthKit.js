function HealthKit() {
}

HealthKit.prototype.available = function (successCallback, errorCallback) {
  cordova.exec(successCallback, errorCallback, "HealthKit", "available", []);
};


HealthKit.prototype.checkAuthStatus = function (options, successCallback, errorCallback) {
  cordova.exec(successCallback, errorCallback, "HealthKit", "checkAuthStatus", [options]);
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
        errorCallback("Missing required parameter sampleType");
    }
    
    var opts = options || {};
    
    
    cordova.exec(successCallback, errorCallback, "HealthKit", "monitorSampleType", [opts]);
};

           
HealthKit.prototype.querySampleType = function (options, successCallback, errorCallback) {

    if (!(options.sampleType)) {
        errorCallback("Missing required parameter sampleType");
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

HealthKit.prototype.queryCorrelationType = function (options, successCallback, errorCallback) {

    if (!(options.correlationType)) {
        errorCallback("Missing required parameter correlationType");
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
                   
                   
    cordova.exec(successCallback, errorCallback, "HealthKit", "queryCorrelationType", [opts]);
};

HealthKit.prototype.saveQuantitySample = function (options, successCallback, errorCallback) {

    if (!(options.sampleType)) {
        errorCallback("Missing required parameter sampleType");
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
                   
    cordova.exec(successCallback, errorCallback, "HealthKit", "saveQuantitySample", [opts]);
};

HealthKit.prototype.saveCorrelation = function (options, successCallback, errorCallback) {

    if (!(options.correlationType)) {
        errorCallback("Missing required parameter correlationType");
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

	if (!options.samples instanceof Array) {
		errorCallback("samples must be a JavaScript Array Object");
      	return;
    }
    /*console.log('before samples loop');
    console.log(options.samples);
    var finalSamples = [];
    var sample;
    for ( sample in options.samples ) {
    	var tempSample = sample;
    	console.log('checking tempSample ');
    	console.log(tempSample);
    	if (!tempSample.startDate instanceof Date) {
		  errorCallback("sample.startDate must be a JavaScript Date Object");
		  return;
		}
		console.log('checking sample ');
    	tempSample.startDate = Math.round(tempSample.startDate.getTime()/1000);
	
		console.log('checking sample ');
    	if (!tempSample.endDate instanceof Date) {
		  errorCallback("sample.endDate must be a JavaScript Date Object");
		  return;
		}
					   
		console.log('checking sample ');
    	if (tempSample.endDate instanceof Date) {
		  tempSample.endDate = Math.round(tempSample.endDate.getTime()/1000);
		}
		console.log('moving onto next sample');
		finalSamples.push(tempSample);
    }
    options.objects = finalSamples;
    console.log('after objects loop');*/
    var opts = options || {};
                   
    cordova.exec(successCallback, errorCallback, "HealthKit", "saveCorrelation", [opts]);
};


HealthKit.prototype.sumQuantityType = function (options, successCallback, errorCallback) {
    
    if (!(options.sampleType)) {
        errorCallback("Missing required parameter sampleType");
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