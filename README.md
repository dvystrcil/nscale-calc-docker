# nscale-calc-docker — build

Image for **nscale-calc**, a static scale-conversion calculator used when
drawing N-scale models in CAD. Enter a prototype dimension in feet and
inches, get millimetres to draw.

| | |
|---|---|
| Deploy repo | [dvystrcil/nscale-calc](https://github.com/dvystrcil/nscale-calc) |
| Image | `harbor.sirddail.net/ai/nscale-calc` |
| Live at | `https://nscale-calc.sirddail.net` (internal only) |

## What's in the image

Stock `nginxinc/nginx-unprivileged` plus one file. The page is entirely
self-contained — CSS and JS are inline, and it loads nothing at runtime —
so there is no build step, no bundler, and no multi-stage Dockerfile.

```
site/index.html      the calculator
nginx/default.conf   server block, plus /healthz served from memory
```

`nginx-unprivileged` rather than `nginx:alpine`: it listens on 8080 as a
non-root user and writes its pid and client temp files into `/tmp`, which
is what lets it run under the Deployment's `readOnlyRootFilesystem: true`
with a single `/tmp` emptyDir.

## Scale ratios

Defaults to **NMRA 1:160**. Also offers the exact 9 mm : 1435 mm gauge
ratio (1:159.44), 1:159, British 1:148, Japanese 1:150, and a custom
divisor.

Worth knowing: at 1:160, real standard gauge (4 ft 8½ in) reduces to
**8.969 mm**, not 9.000 — N track is fractionally wide for its own scale.
That is the standard's long-standing compromise, not an error in the
calculator, and the page shows it rather than hiding it.

## Pipeline

```
push to main
  └─ smoke: build image, serve it under the pod's security constraints,
     assert /, /healthz, and that the page is really the calculator
  └─ build: push :dev + :sha-… to Harbor, cut a patch GitHub release
       └─ docker-release: retag :dev as :X.Y.Z, :X.Y, :latest
            └─ argocd-image-updater writes the tag into the deploy repo
                 └─ ArgoCD syncs
```

Image tags carry no `v` prefix; git tags do.

## Editing the page

Edit `site/index.html` and merge to `main` — the pipeline handles the rest.
Nothing in the deploy repo needs touching.

Local check before pushing:

```bash
docker build -t nscale-calc:dev .
docker run --rm -d --name ns --read-only --tmpfs /tmp \
  --user 1000:1000 --cap-drop ALL -p 8080:8080 nscale-calc:dev
curl -s localhost:8080/healthz && open http://localhost:8080
docker rm -f ns
```
