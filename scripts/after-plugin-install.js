module.exports = function (ctx) {
  if (ctx.cmdLine.indexOf('CLINICAL_READ_PERMISSION') < 0) {
    console.log('CLINICAL_READ_PERMISSION was not provided');
    return;
  }

  try {
    var fs = ctx.requireCordovaModule('fs'),
      path = ctx.requireCordovaModule('path'),
      deferral = ctx.requireCordovaModule('q').defer(),
      configXMLPath = path.join(ctx.opts.projectRoot, 'config.xml'),
      et = ctx.requireCordovaModule('elementtree'),
      xcode = require('xcode');


    var usageDescription = ctx.cmdLine.split('CLINICAL_READ_PERMISSION=')[1].split('--')[0].trim();

    console.log('*** Installing HealthKitClinicalRecords ***');
    console.log('CLINICAL_READ_PERMISSION = ', usageDescription);

    var configData = fs.readFileSync(configXMLPath).toString();
    var etree = et.parse(configData);
    var appName = etree.findtext('./name');
    var srcPath = path.join(ctx.opts.projectRoot, 'plugins/com.telerik.plugins.healthkit/src/ios');
    var projPath = path.join(ctx.opts.projectRoot, 'platforms/ios', appName + '.xcodeproj/project.pbxproj');
    var xcodeProj = xcode.project(projPath);

    xcodeProj.parse(function (err) {
      if (err) {
        console.log('xcode proj parse error, err: ', err);
        return deferral.reject(err);
      }

      xcodeProj.addHeaderFile(path.join(srcPath, 'HealthKitClinicalRecords.h'));
      xcodeProj.addSourceFile(path.join(srcPath, 'HealthKitClinicalRecords.m'));

      fs.writeFileSync(projPath, xcodeProj.writeSync());

      // add CLINICAL_READ_PERMISSION text to config.xml
      var tagPlatform = etree.findall('./platform[@name="ios"]');
      if (tagPlatform.length > 0) {
        var tagEditConfig = et.Element('config-file', { target: '*-Info.plist', parent: 'NSHealthClinicalHealthRecordsShareUsageDescription' });
        var tagString = et.Element('string');
        tagString.text = usageDescription;
        tagEditConfig.append(tagString);
        tagPlatform[0].append(tagEditConfig);

        configData = etree.write({ 'indent': 4 });
        fs.writeFileSync(configXMLPath, configData);
      }

      console.log('*** DONE Installing HealthKitClinicalRecords ***');

      return deferral.resolve();
    });
  } catch(e) {
    console.log('after-plugin-install error, e: ', JSON.stringify(e, null, 2));
    deferral.reject(e);
  }

  return deferral.promise;
};