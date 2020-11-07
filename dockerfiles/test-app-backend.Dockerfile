from node:12

# Install Main application
ENV APP_NAME="test-app4"
COPY backend.js /
COPY ${APP_NAME} ${APP_NAME}/
COPY downloads/nvm-v0-33-11-install.sh /
RUN npm install --prefix ${APP_NAME} && \
    npm install request \
    npm install ${APP_NAME} && \
    bash nvm-v0-33-11-install.sh


# wget -qO- https://raw.githubusercontent.com/creationix/nvm/v0.33.11/install.sh | bash

# Install AppDynamics Agent and the appd startup app
COPY appd-start appd-start/
RUN npm install appdynamics@next && \
    npm install --prefix appd-start

EXPOSE ${APP_LISTEN_PORT}

# Start AppDynamics and then the main application test-app1
ENTRYPOINT  node backend.js
#CMD [ "sleep", "3600" ]
