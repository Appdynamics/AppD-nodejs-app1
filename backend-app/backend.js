/*
Hello Stranger! If you are looking into the source code of backend.js you might look for an easy way to find the answer to a question.
It is not as easy as you thought, but still doable. Feel free to find the answer from only looking into the code.
*/
crypto = require('crypto');

require('http').createServer(function (request, response) {
  const path = require('url').parse(request.url).path
  const myheader = Array.from(Buffer.from('72656461656879746972616c75676e6973', 'hex').toString('ascii')).reverse().join('')
  console.log(`myHeader ${myheader}`);
  const myotherheader = '73696e67756c6172697479686561646572'
  if(request.method === 'PUT' && path.startsWith('/api/') && request.headers['content-type'] === 'application/json' && request.headers[myheader]) {
    const body = [];
    request.on('data', (chunck) => { body.push(chunck) })
    request.on('end', () => {
      const sh = new URLSearchParams(request.headers[Buffer.from(myotherheader, 'hex').toString('latin1')].replace(/\*/g, '&'))
      console.log(`sh1 ${sh}`);
      response.writeHead(200, {'Content-Type': 'text/plain'});
      let decrypted = 'asdf'
      const prepare = (a,p) => {
        return a.reduce((c,e) => {
          let i = 0; for(; i < e; i++) {};
          return c+i.toString(32)
        }, p);
      }
      //console.log(`prepare ${prepare}`);
      const prepera = (a,p) => {
        return a.map((e) => {
          let i = 0; for(; i < (e*(e+1)*(e+2)*(e+3)*(e+4)*(e+5)*(e+6)); i++) {};
          return (i/((e+1)*(e+2)*(e+3)*(e+4)*(e+5)*(e+6))).toString(32)
        }, '').join('')+p;
      }
      const secret = (x) => {
        return (prepare([5,0,1,15,4,0,6,13,5], 'f0ff0') + '-f1-69d852-05_9_bbfbfb1954_cbb425_' + prepera([0xf,0x3,0xc,0x6,0xd,0xf,0xa,0x7,0x8,0xa,0x6,0xc,0x5,0xc,0x5,0x4,0x7,0x8,0x2,0xc,0xb,0x2,0x2,0xb,0xb,0x5,0xd,0x6,0x2,0x5,0xa,0xc,0x0,0x0,0x7,0xd,0x6,0xe,0xc,0xc], '10dfa')).replace(/_/g, x).replace(/-/, x+8).replace(/-/g, x+2)
      }
      //console.log(`prepare ${prepare}`);
      console.log( `body ${body}` );
      try {
        const a1 = sh.get('etypeorder')+Array.from(sh.keys()).sort().join('')+JSON.parse(Buffer.concat(body).toString()).id;
        console.log( `A1 ${a1}`);
        const decipher = crypto.createDecipheriv(
          'aes-192-cbc',
          crypto.scryptSync(sh.get('etypeorder')+Array.from(sh.keys()).sort().join('')+JSON.parse(Buffer.concat(body).toString()).id, 'salt', 24),
          Buffer.alloc(16, 0)
        );
        decrypted = decipher.update(secret(path[6]), 'hex', 'utf8') + decipher.final('utf8');
        console.log(`decrypted1 ${decrypted}`);
      } catch(e) {
        decrypted = (new Buffer.from('526573697374616e636520697320667574696c65', 'hex')).toString('ascii')
        console.log(`decrypted2 ${decrypted}`);
      }
      response.end('Hello AppDynamics\n'+ decrypted + '\n');
    })
  } else {
    response.writeHead(200, {'Content-Type': 'text/plain'});
    response.end('Hello Frontend\n');
  }
}).listen(5646, () => {
  console.log('Server running at http://127.0.0.1:5646/')
})
