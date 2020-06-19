from node:12

# Install Main application
COPY test-app1 test-app1/
RUN npm install --prefix test-app1 && \
    npm install test-app1

# Install AppDynamics Agent and the appd startup app
COPY appd-start appd-start/
RUN npm install appdynamics@next && \
    npm install --prefix appd-start

EXPOSE ${APP_LISTEN_PORT}

# Start AppDynamics and then the main application test-app1
CMD [ "node", "appd-start", "test-app1" ]
#CMD [ "sleep", "3600" ]
