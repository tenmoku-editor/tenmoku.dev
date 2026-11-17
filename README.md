# tenmoku.dev

The landing page for [Tenmoku](https://github.com/tenmoku-editor/tenmoku), a
free, open-source native code editor. One static page: plain HTML and CSS, no
framework, no build step, no tracking. The only script is a small inline one
that points the download buttons at the latest release's files through the
GitHub API; without it they go to the Releases page.

## Layout

| Path | What it is |
| --- | --- |
| `index.html` | the page |
| `assets/style.css` | its styles, in the app's own Yohen (dark) and Hakuji (light) theme colours, following the system's light or dark setting |
| `assets/fonts/` | Instrument Sans, Instrument Serif and Spline Sans Mono, the fonts the app bundles (SIL OFL 1.1, licences beside them), subset to Latin as WOFF2 |
| `assets/hero.webp`, `hero@2x.webp`, `hero.png` | the screenshot of the app (WebP at 1x and 2x, PNG fallback) |
| `assets/og.png` | the 1200×630 social card, cropped from the screenshot |
| `assets/favicon.svg`, `apple-touch-icon.png`, `favicon.ico` | the app icon (`crates/fastedit/assets/icon/` in the app repo) |
| `CNAME` | `tenmoku.dev`, the custom domain |
| `scripts/check-site.sh` | the checks CI runs |
| `.github/workflows/pages.yml` | checks and deploys the site |

## Preview locally

Any static file server at the repo root works:

```sh
python3 -m http.server 8000    # then open http://localhost:8000
```

Opening `index.html` directly also works, except that some browsers block the
download buttons' API call from a `file://` page (they then link to the
Releases page, as intended).

## Check

```sh
scripts/check-site.sh
```

It needs `python3` and Node (for `npx`). It checks that the HTML validates
(html-validate, pinned in the script, with `.htmlvalidate.json`), that every
local link, image and font resolves and every `#anchor` exists, that
everything the page can load weighs under 1.5 MB (it counts both hero sizes
and the PNG, more than any browser fetches), and that `CNAME` is
`tenmoku.dev`. Lint the workflow with
[actionlint](https://github.com/rhysd/actionlint) when you change it.

## Deploy

Every push to `main` (and a manual run: Actions > Pages > Run workflow) runs
`.github/workflows/pages.yml`: it runs `scripts/check-site.sh`, copies
`index.html`, `favicon.ico`, `CNAME` and `assets/` into `_site/`, and
publishes that with GitHub's Pages actions (`configure-pages`,
`upload-pages-artifact`, `deploy-pages`). A failed check stops the deploy.

The repository's Pages source must be **GitHub Actions** (Settings > Pages),
with the custom domain `tenmoku.dev` and **Enforce HTTPS** on. DNS for
`tenmoku.dev` points at GitHub Pages: `A` records for the apex to
185.199.108.153, 185.199.109.153, 185.199.110.153 and 185.199.111.153 (and
`AAAA` to 2606:50c0:8000::153, 2606:50c0:8001::153, 2606:50c0:8002::153 and
2606:50c0:8003::153), and optionally `www` as a `CNAME` to
`tenmoku-editor.github.io`.

## Updating

- **Wording:** every claim on the page should be one the app repo backs: its
  README, `PERF.md`, `docs/release/platforms.md`, `docs/vim.md` and what has
  shipped on its `main`. Change the claim when they change.
- **Screenshot:** the current one was captured on Linux with the app repo's
  `run-fastedit-linux` skill (Xvfb with Mesa's software Vulkan, xdotool), at a
  1440×900 logical window and scale 2 (`GPUI_X11_SCALE_FACTOR=2`), in the
  default Yohen theme. Keep the same names and sizes (2880×1800 and
  1440×900), each file under 500 KB, and update the `alt` text in
  `index.html` to match what it shows. Recrop `og.png` to 1200×630.
- **Downloads:** nothing to do per release. The buttons match the latest
  release's file names (`Tenmoku-X.Y.Z-macos-arm64.zip`,
  `-windows-x64-Setup.exe`, `-windows-arm64-Setup.exe`,
  `-linux-x86_64.AppImage`, `-linux-x86_64.tar.gz`); if those names change,
  change the `data-asset` patterns in `index.html`.

## Licence

Apache-2.0, like Tenmoku: see [LICENSE](LICENSE). The fonts are under the
SIL Open Font License 1.1 (`assets/fonts/OFL-*.txt`).
