# nscale-calc — static scale-conversion calculator for N scale CAD work.
#
# The whole application is one self-contained HTML file (no build step, no
# JS bundle, no external assets — the page inlines its own CSS and JS and
# loads nothing at runtime). So this image is stock nginx plus that file;
# there is deliberately no multi-stage build, unlike tor-dice-docker which
# has a Svelte bundle and a Go binary to produce.
#
# nginxinc/nginx-unprivileged (not nginx:alpine): it listens on 8080 as a
# non-root user and already writes its pid and client temp files into /tmp,
# which is what makes it work under the pod's readOnlyRootFilesystem: true
# with a single /tmp emptyDir. Verified live before the manifests were
# written, running the image with --read-only --tmpfs /tmp as uid 1000.
FROM nginxinc/nginx-unprivileged:1-alpine

# Serve the calculator at /. Our config replaces the stock default.conf,
# which carries commented-out PHP/FastCGI blocks we have no use for.
COPY --chown=101:0 --chmod=644 nginx/default.conf /etc/nginx/conf.d/default.conf
COPY --chown=101:0 --chmod=644 site/index.html /usr/share/nginx/html/index.html

# Group-readable (gid 0) rather than owned by a fixed uid: the Deployment
# runs as uid 1000, not the image's own 101, and only the root group is
# guaranteed common to both.
EXPOSE 8080
