module.exports = function (ctx) {
  var isMeteorProject = ctx.opts.projectRoot.indexOf('/.meteor/') > -1;

  if (ctx.cmdLine.indexOf('CLINICAL_READ_PERMISSION') < 0 && !isMeteorProject) {
    console.log('CLINICAL_READ_PERMISSION was not provided');
    return;
  }

  try {
    var fs = require('fs'),
      path = require('path'),
      configXMLPath = path.join(ctx.opts.projectRoot, 'config.xml'),
      et = require('elementtree'),
      xcode = require('xcode'),
      usageDescription;

    if (isMeteorProject) {
      var meteorProjectPath = ctx.opts.projectRoot.split('/.meteor/')[0];
      var mobileConfigPath = path.join(meteorProjectPath, 'mobile-config.js');
      var mobileConfigData = fs.readFileSync(mobileConfigPath, 'utf8');
      var re = /CLINICAL_READ_PERMISSION?:\s*["|'](.*)['|"]/g;
      var matches = re.exec(mobileConfigData);
      if (matches && matches.length > 1) {
        usageDescription = matches[1];
      } else {
        console.log('CLINICAL_READ_PERMISSION was not provided');
        return;
      }
    } else {
      usageDescription = ctx.cmdLine.split('CLINICAL_READ_PERMISSION=')[1].split('--')[0].trim();
    }

    console.log('*** Installing HealthKitClinicalRecords ***');
    console.log('CLINICAL_READ_PERMISSION = ', usageDescription);

    var configData = fs.readFileSync(configXMLPath).toString();
    var etree = et.parse(configData);
    var appName = etree.findtext('./name');
    var srcPath = path.join(ctx.opts.projectRoot, 'plugins/com.telerik.plugins.healthkit/src/ios');
    var projPath = path.join(ctx.opts.projectRoot, 'platforms/ios', appName + '.xcodeproj/project.pbxproj');
    var xcodeProj = xcode.project(projPath);
    xcodeProj.parseSync();

    xcodeProj.addHeaderFile(path.join(srcPath, 'HealthKitClinicalRecords.h'));
    xcodeProj.addSourceFile(path.join(srcPath, 'HealthKitClinicalRecords.m'));

    fs.writeFileSync(projPath, xcodeProj.writeSync());

    // enable health records
    var tagPlatform = etree.findall('./platform[@name="ios"]');
    if (tagPlatform.length > 0) {
      // add CLINICAL_READ_PERMISSION text to config.xml
      var tagEditConfig = et.Element('config-file', { target: '*-Info.plist', parent: 'NSHealthClinicalHealthRecordsShareUsageDescription' });
      var tagString = et.Element('string');
      tagString.text = usageDescription;
      tagEditConfig.append(tagString);
      tagPlatform[0].append(tagEditConfig);

      // add Health Records to entitlements
      ['*Entitlements-Debug.plist', '*Entitlements-Release.plist'].forEach(function(fileName){
        var healthRecordCapabilityConfig = et.Element('config-file', { target: fileName, parent: 'com.apple.developer.healthkit.access'});
        var healthRecordArray = et.Element('array');
        var healthRecordString = et.Element('string');
        healthRecordString.text = 'health-records';
        healthRecordArray.append(healthRecordString);
        healthRecordCapabilityConfig.append(healthRecordArray);
        tagPlatform[0].append(healthRecordCapabilityConfig);
      });

      configData = etree.write({ 'indent': 4 });
      fs.writeFileSync(configXMLPath, configData);
    }

    console.log('*** DONE Installing HealthKitClinicalRecords ***');
  } catch(e) {
    console.log('healthkit after-plugin-install error, e: ', JSON.stringify(e, null, 2));
  }
};
