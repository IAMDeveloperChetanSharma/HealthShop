const {
  withEntitlementsPlist,
  withInfoPlist,
  withAndroidManifest,
} = require('@expo/config-plugins');

function withHealthKit(config) {
  config = withEntitlementsPlist(config, (config) => {
    config.modResults['com.apple.developer.healthkit'] = true;
    config.modResults['com.apple.developer.healthkit.access'] = [];
    return config;
  });
  config = withInfoPlist(config, (config) => {
    config.modResults.NSHealthShareUsageDescription =
      'HealthShop reads heart rate, oxygen saturation, and step count to show your health dashboard and history.';
    config.modResults.NSHealthUpdateUsageDescription =
      'HealthShop may write health readings only when you explicitly choose to import or sync them.';
    return config;
  });
  config = withAndroidManifest(config, (config) => {
    const manifest = config.modResults.manifest;
    manifest.queries = manifest.queries || [];
    const packageQuery = {
      package: [{ $: { 'android:name': 'com.google.android.apps.healthdata' } }],
    };
    const exists = manifest.queries.some((q) =>
      q.package?.some((p) => p.$?.['android:name'] === 'com.google.android.apps.healthdata'),
    );
    if (!exists) manifest.queries.push(packageQuery);
    return config;
  });
  return config;
}
module.exports = withHealthKit;
