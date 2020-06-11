var http = require("http");

var n = 1;
http.createServer(function (request, response) {
   response.writeHead(200, {'Content-Type': 'text/plain'});
   response.end(n.toString());
   n++;
}).listen(process.env.APP_LISTEN_PORT);
console.log('Server running at http://127.0.0.1:' + process.env.APP_LISTEN_PORT + '/');
