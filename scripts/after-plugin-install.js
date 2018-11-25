module.exports = function (ctx) {
  if (ctx.cmdLine.indexOf('USE_CLINICAL_RECORDS') < 0) {
    console.log('USE_CLINICAL_RECORDS was not provided');
    return;
  }

  var fs = ctx.requireCordovaModule('fs'),
    path = ctx.requireCordovaModule('path'),
    deferral = ctx.requireCordovaModule('q').defer(),
    configXMLPath = path.join(ctx.opts.projectRoot, 'config.xml'),
    et = ctx.requireCordovaModule('elementtree'),
    xcode = require('xcode');

  var configData = fs.readFileSync(configXMLPath).toString();
  var etree = et.parse(configData);
  var appName = etree.findtext('./name');
  var srcPath = path.join(ctx.opts.projectRoot, 'plugins/com.telerik.plugins.healthkit/src/ios');
  var projPath = path.join(ctx.opts.projectRoot, 'platforms/ios', appName + '.xcodeproj/project.pbxproj');
  var xcodeProj = xcode.project(projPath);

  xcodeProj.parse(function(err) {
    if (err) {
      console.log('xcode proj parse error, err: ', err);
      return deferral.reject(err);
    }

    xcodeProj.addHeaderFile(path.join(srcPath, 'HealthKitClinicalRecords.h'));
    xcodeProj.addSourceFile(path.join(srcPath, 'HealthKitClinicalRecords.m'));

    fs.writeFileSync(projPath, xcodeProj.writeSync());

    return deferral.resolve();
  });

  return deferral.promise;
};