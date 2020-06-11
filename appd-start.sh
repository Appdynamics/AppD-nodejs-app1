#!/bin/sh
#
# Install AppDynamics, Start teh Agent and the original Application
# Add additional container startup scripting here as necessary
#
npm install appdynamics@next &&
node appd-start.js
