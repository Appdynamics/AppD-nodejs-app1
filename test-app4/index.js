console.log("Starting");
var http = require("http");
var req = require('request')
var n = 1;
var startTimeSec = Math.round(Date.now() / 1000);
http.createServer(function (request, response) {
  const id = 12294;
  var t1 = Math.round(Date.now() / 1000) - startTimeSec;
  req.put('http://test-app-backend:5646/api/test', {json:{id: id}}, function(err, resp, body) {
    var t2 = Math.round(Date.now() / 1000) - startTimeSec;
    var d1 = t2 - t1;
    console.log(` PUT n: ${n} t1: ${t1} t2: ${t2} diff: ${d1}`)
    //response.write(n.toString());
    response.end(body);
    n++;
  });
  //function latency(N,r){ for(let i=2,c,x=r[1];i<N;i++,x=r[i-1]) { do { c = 0, x++; for(let k=0;k<i;k++) for(let n=0;n<k;n++) c=r[n]+r[k]==x?c+1:c } while(c!=1) r[i]=x; } return r[N-1] };
  //console.log( latency(1100,[1,2]) );
}).listen(process.env.APP_LISTEN_PORT);
console.log('test-app3 running at http://127.0.0.1:' + process.env.APP_LISTEN_PORT + '/');
