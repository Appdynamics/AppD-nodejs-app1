from node:10

# Configure the main Application
#COPY capp1.js ./
#COPY package*.json ./
#RUN npm install

RUN npm install . --prefix test-app1/


# Configure AppDynamics
RUN npm install appdynamics@next
RUN npm install . --prefix appd-start/



EXPOSE 8081
CMD [ "node", "capp1.js" ]
