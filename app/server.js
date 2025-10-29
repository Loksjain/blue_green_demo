const express = require("express");
const path = require("path");
const app = express();

app.use(express.static(path.join(__dirname, "public")));

// Dynamic UI via environment
const COLOR = process.env.COLOR || "gray";
const LABEL = process.env.LABEL || "UNKNOWN";
const VERSION = process.env.VERSION || "v0";
const PORT = process.env.PORT || 8080;

app.get("/", (_req, res) => {
  const html = `
  <!doctype html>
  <html>
  <head>
    <meta charset="utf-8" />
    <title>Blue-Green Demo</title>
    <meta name="viewport" content="width=device-width, initial-scale=1"/>
    <style>
      html, body { height: 100%; margin: 0; }
      body {
        display: grid; place-items: center;
        background: ${COLOR};
        color: #fff; font-family: system-ui, Arial, sans-serif;
      }
      .card {
        text-align: center; padding: 2rem 3rem;
        border-radius: 16px; background: rgba(0,0,0,0.2);
        backdrop-filter: blur(6px);
      }
      h1 { font-size: 3rem; margin: 0 0 .25rem; letter-spacing: 2px; }
      p { margin: .25rem 0; }
      .dot { width:12px;height:12px;border-radius:50%;display:inline-block;background:#fff;margin-right:.5rem }
    </style>
  </head>
  <body>
    <div class="card">
      <h1><span class="dot"></span>${LABEL} ENV</h1>
      <p>VERSION: ${VERSION}</p>
      <p>COLOR: ${COLOR}</p>
    </div>
  </body>
  </html>`;
  res.status(200).send(html);
});

app.get("/healthz", (_req, res) => res.status(200).send("ok"));

app.listen(PORT, () => {
  console.log(`Listening on ${PORT} (${LABEL} / ${COLOR} / ${VERSION})`);
});
