from node:14

# Install Main application
ENV APP_NAME="test-app0"
COPY ${APP_NAME} ${APP_NAME}/
COPY downloads/nvm-v0-33-11-install.sh /

RUN bash nvm-v0-33-11-install.sh && \
    npm install --prefix ${APP_NAME} && \
    npm install ${APP_NAME}

#RUN nvm install v10.18.0 && \
#    nvm install v12.19.0



# wget -qO- https://raw.githubusercontent.com/creationix/nvm/v0.33.11/install.sh | bash

# Install AppDynamics Agent and the appd startup app
COPY appd-start appd-start/
RUN npm install appdynamics@next && \
    npm install --prefix appd-start

EXPOSE ${APP_LISTEN_PORT}

# Start AppDynamics and then the main application test-app1
ENTRYPOINT  node appd-start ${APP_NAME}
#CMD [ "sleep", "3600" ]
