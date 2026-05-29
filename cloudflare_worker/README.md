# Cloudflare Worker — Claude API Proxy (CORS)

Flutter Web cannot call `https://api.anthropic.com` directly because of browser CORS. This Worker forwards requests server-side and adds `Access-Control-Allow-Origin: *`.

## Deploy

1. Go to [cloudflare.com](https://cloudflare.com) → **Workers & Pages** → **Create Worker**
2. Paste the contents of `worker.js`
3. **Settings** → **Variables** → **Add**:
   - Name: `CLAUDE_API_KEY`
   - Value: your Anthropic API key (`sk-ant-...`)
4. **Deploy** and copy the Worker URL (e.g. `https://netgulf-claude-proxy.your-subdomain.workers.dev`)

## Run NetGulf on Chrome

```bash
flutter run -d chrome --dart-define=ANTHROPIC_PROXY_URL=https://xxx.workers.dev
```

Do **not** pass `CLAUDE_API_KEY` to the Flutter app on Web — the key lives only in the Worker secret.

## Local test (optional)

```bash
npx wrangler dev
# or: npx wrangler deploy
```

Set `CLAUDE_API_KEY` in Wrangler secrets:

```bash
npx wrangler secret put CLAUDE_API_KEY
```
