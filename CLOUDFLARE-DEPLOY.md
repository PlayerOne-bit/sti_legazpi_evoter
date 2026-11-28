# Deploy the download page to Cloudflare

The Flutter app and API stay on their current hosts. This deploys only the static landing page in `download-site/` as a Cloudflare Worker with Static Assets.

## Cloudflare build settings

Connect the public `PlayerOne-bit/sti_legazpi_evoter` GitHub repository to the Worker named `sti-legazpi-evoter`, using the `master` branch. Configure:

| Setting | Value |
|---|---|
| Root directory | `/` |
| Build command | None / blank |
| Deploy command | `npx wrangler deploy` |

The root `wrangler.jsonc` tells Wrangler to publish `download-site/`. The `download-site/_headers` file applies the security headers and prevents `config.js` from being cached. Each push to `master` triggers a new production build.

If a build was already running before `wrangler.jsonc` reached GitHub, let it finish or fail. The new push should trigger another build using the configuration file.

## Finish the first deployment

1. Wait for the Cloudflare build to succeed. In **Workers & Pages → sti-legazpi-evoter → Settings → Domains & Routes**, copy the assigned `workers.dev` URL. It should look like `https://sti-legazpi-evoter.<account-subdomain>.workers.dev`.
2. Open Render → `sti-evoter-api` → **Environment**. Add that exact origin (scheme and host, no trailing slash) to `Cors__Origins`. Keep any other origins you still use, separated by commas.
3. Set `App__DownloadUrl` to the same Cloudflare URL with a trailing slash. This changes the download button included in student password emails.
4. Save the Render environment changes and wait for the API to restart.
5. Open the Cloudflare URL. Confirm the page loads and both platform buttons show the latest release. Check that the release history includes the version from `download-site/history.js`.
6. Test the page's API access by opening browser developer tools or checking that the version cards show a version and file size rather than an API error.

The page reads the API address from `download-site/config.js`; it is already set to `https://sti-evoter-api.onrender.com`. The download buttons fetch the latest manifest from the API, while the release history is deployed from this repository.

## Existing Netlify address

The old Netlify deployment can remain available as a fallback, but it will not receive these updates while production deploys are paused. Once Cloudflare is working, use its `workers.dev` URL in messages and admin instructions. You do not need a custom domain for this setup.
