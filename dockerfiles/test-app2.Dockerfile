from node:12

# Install Main application
ENV APP_NAME="test-app2"
COPY ${APP_NAME} ${APP_NAME}/
COPY downloads/nvm-v0-33-11-install.sh /
RUN npm install --prefix ${APP_NAME} && \
    npm install ${APP_NAME} && \
    bash nvm-v0-33-11-install.sh


# wget -qO- https://raw.githubusercontent.com/creationix/nvm/v0.33.11/install.sh | bash

# Install AppDynamics Agent and the appd startup app
COPY appd-start appd-start/
RUN npm install appdynamics@next && \
    npm install --prefix appd-start

EXPOSE ${APP_LISTEN_PORT}

# Start AppDynamics and then the main application test-app1
ENTRYPOINT  node appd-start ${APP_NAME}
#CMD [ "sleep", "3600" ]
