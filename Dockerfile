from node:10

COPY app1.js ./
COPY node_modules ./node_modules
COPY package*.json ./
RUN npm install

EXPOSE 8081

CMD [ "node", "app1.js" ]
