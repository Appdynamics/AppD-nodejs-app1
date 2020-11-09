console.log("Starting");
console.log("APP_LATENCY: ", process.env.APP_LATENCY);
var http = require("http");
var n = 1;
var appLatency = Number(process.env.APP_LATENCY);

function latency(N,r) {
  for (let i=2,c,x=r[1];i<N;i++,x=r[i-1]) {
    do {
        c = 0, x++;
        for(let k=0;k<i;k++)
          for(let n=0;n<k;n++)
            c=r[n]+r[k]==x?c+1:c
       } while(c!=1) r[i]=x; }
  return r[N-1]
};

http.createServer(function (request, response) {
  console.log( latency(appLatency,[1,2]) );
  response.writeHead(200, {'Content-Type': 'text/plain'});
  response.write(n.toString());
  response.end();
  n++;
}).listen(process.env.APP_LISTEN_PORT);
console.log('test-app3 running at http://127.0.0.1:' + process.env.APP_LISTEN_PORT + '/');
