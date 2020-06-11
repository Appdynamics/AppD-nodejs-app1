console.log("Controller:", process.env.APPDYNAMICS_CONTROLLER_HOST_NAME)
require("appdynamics").profile({
  controllerHostName: process.env.APPDYNAMICS_CONTROLLER_HOST_NAME,
  controllerPort: process.env.APPDYNAMICS_CONTROLLER_PORT,
  controllerSslEnabled: process.env.APPDYNAMICS_CONTROLLER_SSL_ENABLED,  // Set to true if controllerPort is SSL
  accountName: process.env.APPDYNAMICS_AGENT_ACCOUNT_NAME,
  accountAccessKey: process.env.APPDYNAMICS_AGENT_ACCOUNT_ACCESS_KEY, //required
  applicationName: process.env.APPDYNAMICS_AGENT_APPLICATION_NAME,
  tierName: process.env.APPDYNAMICS_AGENT_TIER_NAME,
  nodeName: process.env.APPDYNAMICS_AGENT_NODE_NAME, 
  reuseNode: 'true',
  reuseNodePrefix: process.env.APPDYNAMICS_AGENT_NODE_NAME
 });
require(process.env.APP_ENTRY_POINT)
