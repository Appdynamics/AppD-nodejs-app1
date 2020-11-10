console.log("Starting: test-app2");
const http = require("http");
const url = require('url');
//const sleep = require('sleep');

var n = 1;

function latency(N,r){ for(let i=2,c,x=r[1];i<N;i++,x=r[i-1]) { do { c = 0, x++; for(let k=0;k<i;k++) for(let n=0;n<k;n++) c=r[n]+r[k]==x?c+1:c } while(c!=1) r[i]=x; } return r[N-1] }

function msleep(n) {
  Atomics.wait(new Int32Array(new SharedArrayBuffer(4)), 0, 0, n);
}
function sleep(n) {
  msleep(n*1000);
}

function httpHandler( request, response) {
  const parsedUrl = url.parse(request.url, true);
  if ( parsedUrl.pathname === '/' ) {
       response.writeHead(200, {'Content-type':'text/plain'});

   } else if ( parsedUrl.pathname === '/date' ){
       response.writeHead(200, {'Content-type':'text/plain'});
       response.write(new Date().toString());

   } else if ( parsedUrl.pathname === '/slow' ){
       response.writeHead(200, {'Content-type':'text/plain'});
       console.log( latency(1000,[1,2]) );

  } else if ( parsedUrl.pathname === '/sleep' ){
      const delay = Number( parsedUrl.query.delay );
      console.log(delay);
      response.writeHead(200, {'Content-type':'text/plain'});
      msleep(delay);

   } else if ( parsedUrl.pathname === '/slow2' ){
      const p1 = Number( parsedUrl.query.p1 );
      const p2 = Number( parsedUrl.query.p2 );
      const p3 = Number( parsedUrl.query.p3 );
      console.log( `slow2 ${p1} ${p2} ${p3}` );
      response.writeHead(200, {'Content-type':'text/plain'});
      console.log( latency(p1,[p2,p3]) );

   } else if ( parsedUrl.pathname === '/echo' ){
       const name = parsedUrl.query.name;
       console.log(`echo ${name}`);
       if (name) {
         response.writeHead(200, {'Content-type':'text/plain'});
         response.write(`Echo: ${name}`);
       } else {
         response.writeHead(400, {'Content-type':'text/plain'});
       }
   } else {
       response.writeHead(404, {'Content-type':'text/plain'});
   };
  response.write(n.toString());
  response.end();
  n++;
}

http.createServer(httpHandler).listen(process.env.APP_LISTEN_PORT);

console.log('Server 2 running at http://127.0.0.1:' + process.env.APP_LISTEN_PORT + '/');
