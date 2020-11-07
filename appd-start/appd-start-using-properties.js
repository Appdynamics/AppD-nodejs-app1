console.log("AppDynamics Controller Host: ", process.env.APPDYNAMICS_CONTROLLER_HOST_NAME)
console.log("AppDynamics Main Application:", process.argv[2])
require("appdynamics").profile({
  controllerHostName: process.env.APPDYNAMICS_CONTROLLER_HOST_NAME,
  controllerPort: process.env.APPDYNAMICS_CONTROLLER_PORT,
  controllerSslEnabled: process.env.APPDYNAMICS_CONTROLLER_SSL_ENABLED,  // Set to true if controllerPort is SSL
  certificateFile: process.env.APPDYNAMICS_CONTROLLER_CERTIFICATE_FILE, // Controller PEM Certificate
  accountName: process.env.APPDYNAMICS_AGENT_ACCOUNT_NAME,
  accountAccessKey: process.env.APPDYNAMICS_AGENT_ACCOUNT_ACCESS_KEY, //required
  applicationName: process.env.APPDYNAMICS_AGENT_APPLICATION_NAME,
  tierName: process.env.APPDYNAMICS_AGENT_TIER_NAME,
  nodeName: process.env.APPDYNAMICS_AGENT_NODE_NAME,
  reuseNode: 'true',
  reuseNodePrefix: process.env.APPDYNAMICS_AGENT_NODE_NAME
});
// Expect ARGV[2] to be name of the main application
require(process.argv[2])
