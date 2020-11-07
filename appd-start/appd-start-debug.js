console.log("AppDynamics Controller Host: ", process.env.APPDYNAMICS_CONTROLLER_HOST_NAME)
console.log("AppDynamics Main Application:", process.argv[2])
require("appdynamics").profile({
  reuseNode: 'true',
  debug: 'true'
});
// Expect ARGV[2] to be name of the main application
require(process.argv[2])
