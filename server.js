const http = require('http');

const PORT = 8000;

const server = http.createServer((req, res) => {
  console.log(req.url, req.headers['user-agent']);
  if (req.url === '/') {
    res.setHeader('Content-Type', 'text/html');
    res.end(`<script>console.log(navigator.userAgent)</script>`);
  } else if (req.url === '/fetch') {
    res.setHeader('Content-Type', 'text/html');
    res.end(`<script>fetch('/agent').then(r => r.text()).then(t => { console.log(t); document.body.innerText = 'fetched' })</script>`);
  } else if (req.url === '/agent') {
    res.end(req.headers['user-agent']);
  } else {
    res.writeHead(404);
    res.end();
  }
});

server.listen(PORT, () => {
  console.log(`Listening on port ${PORT}`);
});
