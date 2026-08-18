const { withAppBuildGradle } = require('@expo/config-plugins');
module.exports = function withHealthConnect(config) {
  return withAppBuildGradle(config, (config) => {
    if (config.modResults.language === 'groovy') {
      const marker = "implementation 'androidx.health.connect:connect-client:1.1.0-alpha12'";
      if (!config.modResults.contents.includes(marker)) {
        config.modResults.contents = config.modResults.contents.replace(
          /dependencies \{/,
          `dependencies {\n  ${marker}`,
        );
      }
    }
    return config;
  });
};
