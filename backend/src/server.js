import express from "express";
import cors from "cors";
import jwt from "jsonwebtoken";
import { readFile } from "node:fs/promises";
import { fileURLToPath } from "node:url";
import { dirname, join } from "node:path";
import crypto from "node:crypto";

const __dirname = dirname(fileURLToPath(import.meta.url));
const PORT = process.env.PORT || 8787;
const JWT_SECRET = process.env.JWT_SECRET || "dev-only-secret-change-me";

const app = express();
app.use(cors());
app.use(express.json());

async function loadServers() {
  const raw = await readFile(join(__dirname, "..", "data", "servers.json"), "utf8");
  return JSON.parse(raw);
}

function auth(req, res, next) {
  const header = req.headers.authorization || "";
  const token = header.startsWith("Bearer ") ? header.slice(7) : null;
  if (!token) return res.status(401).json({ error: "missing_token" });
  try {
    req.user = jwt.verify(token, JWT_SECRET);
    next();
  } catch {
    res.status(401).json({ error: "invalid_token" });
  }
}

// Health
app.get("/api/health", (_req, res) => res.json({ ok: true, ts: Date.now() }));

// Auth (mock): any email/password works, returns a JWT.
app.post("/api/auth/login", (req, res) => {
  const { email } = req.body ?? {};
  if (!email) return res.status(400).json({ error: "email_required" });
  const token = jwt.sign({ sub: email, plan: "premium" }, JWT_SECRET, {
    expiresIn: "30d",
  });
  res.json({ token, user: { email, plan: "premium" } });
});

// Server list
app.get("/api/servers", auth, async (_req, res) => {
  const servers = await loadServers();
  res.json({ servers });
});

// Targets the client pings locally to rank servers by latency.
app.get("/api/ping-targets", auth, async (_req, res) => {
  const servers = await loadServers();
  res.json({
    targets: servers.map((s) => ({ id: s.id, host: s.host, port: s.port })),
  });
});

// Provision a WireGuard session. In production this would register the
// client's public key with the node and return ephemeral peer config.
app.post("/api/session", auth, async (req, res) => {
  const { serverId, exitServerId, publicKey } = req.body ?? {};
  if (!serverId || !publicKey) {
    return res.status(400).json({ error: "serverId_and_publicKey_required" });
  }
  const servers = await loadServers();
  const entry = servers.find((s) => s.id === serverId);
  if (!entry) return res.status(404).json({ error: "server_not_found" });
  const exit = exitServerId ? servers.find((s) => s.id === exitServerId) : null;

  // Mock peer keys (NEVER do this in production — keys come from real nodes).
  const peerPublicKey = crypto.randomBytes(32).toString("base64");

  const peers = [
    {
      publicKey: peerPublicKey,
      endpoint: `${entry.host}:${entry.port}`,
      allowedIPs: exit ? [`${exit.host}/32`] : ["0.0.0.0/0", "::/0"],
      persistentKeepalive: 25,
    },
  ];

  if (exit) {
    peers.push({
      publicKey: crypto.randomBytes(32).toString("base64"),
      endpoint: `${exit.host}:${exit.port}`,
      allowedIPs: ["0.0.0.0/0", "::/0"],
      persistentKeepalive: 25,
    });
  }

  res.json({
    sessionId: crypto.randomUUID(),
    multihop: Boolean(exit),
    interface: {
      address: ["10.66.66.2/32", "fd66::2/128"],
      dns: ["10.66.66.1", "1.1.1.1"],
      mtu: 1420,
    },
    peers,
    expiresAt: Date.now() + 1000 * 60 * 60 * 24,
  });
});

app.listen(PORT, () => {
  console.log(`IllUsion VPN backend listening on http://localhost:${PORT}`);
});
