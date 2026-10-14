# Fronting a Website/API with Zuplo (Free Plan Guide)

A generic, step-by-step guide for putting a Zuplo API gateway in front of an existing backend. Replace placeholders like `<BACKEND_URL>` with your own values.

---

## 0. Key concepts (read this first)

- **Zuplo is a gateway, not a web server.** It only forwards requests to your backend. It has no login page or content of its own.
- **Route = Path + Handler.**
  - **Path** is what clients call on the gateway (for example `/api/login`). Never put the backend URL here.
  - **Forward to** (inside the URL Forward handler) is where the request goes after policies run. This is where the backend URL belongs.
- **One route per endpoint** is normal. Each route can carry its own policies (rate limits, auth, and so on).
- **Environments:** each Zuplo environment has its own gateway URL.
  - Development (the editor working copy) uses a `*.zuplo.dev` URL.
  - Production uses a `*.zuplo.app` URL, created the first time you deploy.
- **Free plan limits:** custom domains need the Builder plan or above, and are never allowed on `*.zuplo.dev` development environments. On free, use the Zuplo-provided URLs.

---

## 1. Create the project and import your API

1. Create a project in the Zuplo portal.
2. Import your OpenAPI/Swagger file. Zuplo creates one route per endpoint, shown in the route list on the left of the **Code** tab.
3. Delete any placeholder routes (for example "New REST Operation" with a path like `/path-1`).

> If your API spec is incomplete (some apps leave endpoints out on purpose), anything not in the import will return a Zuplo 404 until you add routes for it. See section 5.

---

## 2. Set the backend URL as an environment variable

1. Go to **Settings -> Environment Variables** (left sidebar, under Configuration).
2. Add a variable:
   - Name: `BACKEND_URL`
   - Value: `https://your-backend.example.com` (no trailing slash)
   - Plain variable, not a secret
3. Make sure it applies to **every environment** you use (Development and Production). If you can set values per environment, give each environment its own backend URL.

Using one variable means you change the backend in a single place later.

---

## 3. Point each route at the backend

For each route (or just one to start):

1. Open the route in the **Code** tab.
2. Leave **Path** alone. It should show the real endpoint path, for example `/api/v1/login`.
3. Under **Request Handler**, set **Handler** to `URL Forward`.
4. In **Forward to**, enter:

   ```
   ${env.BACKEND_URL}
   ```

   Type it into the **Forward to** field. Do not put it in the Path field.
5. Click **Save**.

URL Forward appends the incoming path to the base URL, so `/api/v1/login` on the gateway becomes `<BACKEND_URL>/api/v1/login` on the backend.

**Bulk edit:** open **Files -> `config/routes.oas.json`** and use find and replace to change every `http://localhost:...` forward URL to `${env.BACKEND_URL}`.

---

## 4. Test a route correctly

Use the **Test Route** button in the route editor, Postman, or curl. **A browser address bar only sends GET**, so it is not a valid test for POST routes.

Example (login-style POST):

```bash
curl -X POST https://<your-gateway-url>/api/v1/login \
  -H "Content-Type: application/json" \
  -d '{"email":"you@example.com","password":"YourPassword123!"}'
```

In the Test Route panel:
- Open the **Body** tab.
- Change the body type dropdown (bottom left) from **None** to **JSON**.
- Paste your JSON and click **Send**.

**Authenticated endpoints:** log in first, copy the token from the response, then add a header `Authorization: Bearer <token>` on later requests (Headers tab). Zuplo passes headers through to the backend by default.

### Test URL gotcha
Do not paste a route pattern such as `/(.*)` into the test URL. That sends the literal text `/(.*)` as the path. Use a real path like `/` or `/api/v1/login`.

---

## 5. Cover endpoints your spec doesn't list

If your backend serves more than the imported routes (a web frontend, static assets, hidden or undocumented endpoints), add catch-all routes. Each uses **Handler: URL Forward** and **Forward to: `${env.BACKEND_URL}`**.

| Method | Path |
|---|---|
| GET | `/(.*)` |
| POST | `/(.*)` |
| PUT | `/(.*)` |
| DELETE | `/(.*)` |
| PATCH | `/(.*)` |

Notes:
- Type the path exactly, with no trailing characters (a stray `.` breaks it).
- **Order matters.** Zuplo uses the first matching route, so keep the specific imported routes above the catch-alls.
- If `/(.*)` doesn't match nested paths (for example `/static/js/app.js`), add explicit routes, all GET with URL Forward to `${env.BACKEND_URL}`:
  - `/static/(.*)`
  - `/manifest.json`
  - `/favicon.ico`
  - or try the pattern `/:path*` instead of `/(.*)`

---

## 6. Deploy to production

1. Make sure everything is saved. The **Save** button should be greyed out.
2. Click **Deploy to Production** (top right). If it asks for source control, go to **Settings -> Source Control**, connect a GitHub repo, and Zuplo will deploy from it.
3. Wait for the "Builds in progress" indicator to clear.
4. Open the **Deployment URLs** dropdown (top right) to find the production URL.
5. Re-run your curl test against the production URL.
6. Confirm `BACKEND_URL` is set for the Production environment. A missing value there is the most common reason production fails when dev works.

---

## 7. Dev vs. prod

| Zuplo environment | Gateway URL | `BACKEND_URL` |
|---|---|---|
| Development | `https://<project>-<id>.d2.zuplo.dev` | dev backend (or the same as prod if you only have one) |
| Production | `https://<project>-<id>.zuplo.app` | production backend |

The routes and policies are identical. Only the environment variable differs.

---

## 8. Custom domains (paid Builder plan or above)

Not available on the free plan or on any `*.zuplo.dev` environment.

1. Go to **Account Settings -> Custom Domains -> Add New Custom Domain**.
2. Type: **API Gateway**. Pick the environment (a production or preview environment, not development). Enter a hostname such as `api.example.com`.
3. Create the DNS record Zuplo shows you:

   ```
   CNAME   api   cname.zuplo.app
   ```

4. If your DNS is on **Cloudflare**, turn the **proxy (orange cloud) ON** for that record. Zuplo requires it.
5. If you have **CAA records**, authorize a certificate authority: `0 issue "pki.goog"`.
6. Wait a few minutes. If you made a typo and have to fix it, re-verification can take up to 4 hours.
7. Redeploy, then test on the new hostname.

**Putting the gateway on the same hostname as your existing site:** the backend must move to a different hostname first (for example `origin.example.com`), then the original hostname points at Zuplo's CNAME and `BACKEND_URL` points at the new origin hostname.

---

## 9. Recommended policies

On the **Request** side of routes (**Add Policy**):

- **Rate limiting** on everything (for example 60 requests/minute per IP).
- **Tighter rate limits** on login, signup, password reset and OTP routes (for example 5 to 10 per minute).
- **IP allowlist** if the site is private or a lab.
- **CORS:** defaults to "Deny All Origins". Allow your frontend's origin only if a browser app on another domain will call the gateway.
- **Auth:** if your backend issues its own tokens, you can leave auth to the backend at first and add a Zuplo JWT or API key policy later.

**Lock the backend to the gateway:** otherwise anyone can bypass Zuplo by hitting the backend hostname directly. Have Zuplo add a secret header (Set Request Headers policy) and have the backend, reverse proxy or firewall reject requests without it.

---

## 10. Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| 404 with JSON body (`httpproblems.com/http-status/404`, a `rayId`) | **Zuplo** found no matching route | Add a route or catch-all for that path and method |
| 404 with plain HTML (for example `openresty` or `nginx`) | Request reached your **backend**, which has no such path | Test the same path directly on the backend; check the path and Host header |
| 415 Unsupported Media Type | Test sent no body, so the content type defaulted to `text/plain` | Set the body type to JSON in Test Route |
| 403 `error code: 1003` | Cloudflare rejected the request (wrong host or direct IP) | Check Forward to points at a hostname, and review Cloudflare rules/Host header |
| Test Route works, browser shows a **white page** | Page HTML loaded but its assets or API calls failed | Open DevTools -> Console and Network, find the red requests, add routes for those paths |
| CORS errors in the Console | The site's frontend calls the backend hostname directly from the gateway origin | Serve the frontend from the same origin, or allow the origin in CORS, or have the app use relative URLs |
| Works in dev, fails in prod | `BACKEND_URL` missing in Production, or prod build not finished | Set the variable for Production and redeploy |
| Backend URL appears in the Path field | `{ }` variable button was used on the wrong field | Reset Path to the real endpoint path; set Forward to under Request Handler |
| Changes not showing | Build still running or unsaved | Click Save, wait for "Builds in progress" to clear, hard refresh (Cmd/Ctrl+Shift+R) |

**Tip for telling who answered:** a JSON error with `traceId`/`rayId` in Zuplo's format means the gateway answered. Your backend's own error page means the request got through.

---

## 11. Behind a tunnel or reverse proxy (Cloudflare Tunnel, Kong, nginx, etc.)

The tunnel and proxy sit behind Zuplo, so they don't affect Zuplo's own 404s. They matter once requests reach them:

- **Host header routing:** if the proxy routes by hostname and requests land on the wrong service, add a **Set Request Headers** policy that sets `Host` to the backend's hostname.
- **Cloudflare security rules** (Bot Fight Mode, WAF, Access) can block requests from Zuplo's servers. Watch for 403s with Cloudflare-style bodies.
- **Absolute URLs and redirects:** if the backend builds links or redirects using its own hostname, the browser can jump out of the gateway or hit CORS errors.

---

## Quick checklist

- [ ] Project created, OpenAPI imported
- [ ] Placeholder routes deleted
- [ ] `BACKEND_URL` set for Development and Production
- [ ] Each route: Handler = URL Forward, Forward to = `${env.BACKEND_URL}`
- [ ] Catch-all routes added for any unlisted paths (specific routes above them)
- [ ] Tested with Test Route or curl using JSON bodies
- [ ] Rate limiting added to sensitive routes
- [ ] Deployed to Production, production URL tested
- [ ] (Optional, paid) Custom domain and DNS record added
- [ ] (Optional) Backend restricted so only the gateway can reach it
