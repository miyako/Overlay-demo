# Overlay-demo

A small **4D desktop project** that uses [miyako/Overlay](https://github.com/miyako/Overlay)
as a component dependency. Overlay puts a borderless native window on the desktop,
on top of everything else, and remembers where the user clicked.

The demo turns that into an **interactive walking tour**: a map with seven points of
interest, a list, and a floating card that appears next to the marker you click —
*near the marker on your actual screen*, not inside the 4D window. It is the shortest
honest way to show why a desktop window is a different primitive from a form.

| | |
| --- | --- |
| Component | [`miyako/Overlay`](https://github.com/miyako/Overlay) `0.1.1` |
| Host project | `Project/OverlayDemo.4DProject` (base name `OverlayDemo`) |
| 4D build used | 4D 21 R5, build `100176`, `Application version` = `2150` |
| Platform exercised | macOS 27.2.1, Apple Silicon (`arm64`) |
| Headless tool | `tool4d` from the same 4D 21 R5 installation |

![The Tour form at design time](<docs/form-preview.png>)

The preview is rendered from `Project/Sources/Forms/Tour/form.4DForm` by
`tools/4dform/fourdform`. The map area is blank there because the picture is bound
to `Form.mapPicture` at runtime; in 4D it shows the generated SVG island map.

## What the demo does

1. **Pick a point of interest** in the list, or click a marker on the map.
2. The map highlights the marker; the blurb panel shows the story.
3. **Show card** draws `Resources/Overlay/card_XX_*.png` as an Overlay window
   positioned over that marker's screen coordinates.
4. **Center** re-reads the window rectangle and snaps the card to the middle of the
   screen the window is on.
5. **Cancel** cancels a live overlay (it is an async SystemWorker process).
6. **Copy result** puts the last completion envelope on the clipboard as JSON.
7. **Fragmented sample** deliberately triggers a native validation error — see
   [FINDINGS.md](FINDINGS.md#1-the-512-rectangle-image-complexity-limit).
8. **Reset** clears selection, visit marks and the status panel.

Everything the component returns lands in the status panel as raw
`ok / stdout / stderr / exitCode / value` JSON so the protocol stays visible.

## Install Overlay

`Project/Sources/dependencies.json` declares the dependency:

```json
{
	"version": 2100,
	"dependencies": {
		"Overlay": {
			"github": "miyako/Overlay",
			"version": "0.1.1"
		}
	}
}
```

On first open, 4D's Dependency manager resolves that into `Components/Overlay.4dbase`.
`Components/` is git-ignored. If you need to work offline, download the `0.1.1`
release ZIP from the Overlay repository and unpack it there by hand — a local
`Components/` copy has the highest load priority, above the dependency declaration.

## Run it

Open `Project/OverlayDemo.4DProject` in 4D 21 R5 or later and run the `Tour` form
(`onStartup` opens it). The form is `1020 x 730`; the "Show card" window is a real
desktop window and is not clipped by the 4D window.

Headless checks (no GUI interaction, no accessibility permissions):

```sh
TOOL4D="/Applications/4D 21 R5 (100176)/tool4d.app/Contents/MacOS/tool4d"

# Data model, geometry, SVG document, form JSON, bundled assets.
"$TOOL4D" --dataless --skip-onstartup --startup-method=Smoke \
  --project=Project/OverlayDemo.4DProject

# Component metadata plus one real passive overlay shown for 400 ms.
"$TOOL4D" --dataless --skip-onstartup --startup-method=SmokeComponent \
  --project=Project/OverlayDemo.4DProject
```

Reports are written to `build/smoke.json` and `build/smoke-component.json`.
`SmokeComponent` also writes `build/smoke-component-step.txt` before each step so a
silent abort shows which call was reached.

### Evidence (this checkout, run 2026-11-25)

| Check | Status | Evidence |
| --- | --- | --- |
| `registry.count` | passed | 7 POIs |
| `registry.find.hit` / `.miss` | passed | `find("tidepools")`, `find("nowhere")` → Null |
| `registry.nearest.hit` / `.miss` | passed | `(0.22, 0.62)` → `tidepools`; `(0.99, 0.01)` → Null |
| `svg.render` / `svg.markers` | passed | 4154-char SVG, first/middle/last marker ids present |
| `svg.to.picture` | not_run | `Picture size = 0` — tool4d has no SVG rasterizer |
| `geometry.desktopPoint` / `.cardTopLeft` / `.clamp` | passed | `360, 270`; `210, 94`; `8, 819` |
| `form.json` | passed | 2 pages, `method.4dm` |
| `assets` | passed | 7 card PNGs + fragmented sample present and non-trivial |
| `component.version` | passed | helper `0.1.1` |
| `component.screens` | passed | 1 screen |
| `component.capabilities` | passed | 2 modes, PNG |
| `component.show` | passed | passive card, `outcome: dismissed`, `reason: timeout` |

Totals: `build/smoke.json` 12 passed / 0 failed / 3 not_run, `finished: true`;
`build/smoke-component.json` 4 passed / 0 failed, `finished: true`.
Static validation: `tools/4dlsp/tool4d-lsp-stdio check-syntax --workspace Project/`
reports nothing except the diagnostics the LSP cannot avoid for an unresolvable
component — `The class cs.Overlay.* is unknown` plus follow-on
"does not exist on type / undeclared property" warnings on the same lines.
`tools/4dform/boon` validates the form against the 4D form schema.

The tools in `tools/` are provisioned, not vendored: the skills' `4dtools` skill
installs the pinned `boon`, `fourdform`, `tool4d-lsp-stdio` and language bundles,
and `.gitignore` keeps those binaries out of the repository. Run `4dtools` first
if a command below reports a missing executable.

### Not verified here

* Windows (x64 or ARM64), Intel macOS, 4D Server or merged applications.
* Dependency-manager download from GitHub — the local run used `Components/Overlay.4dbase`.
* Signed/notarized artifacts — the bundled helper is unsigned.
* Pixel-exact placement or hit-testing against the OS display (no GUI automation
  in this session); desktop coordinates rest on `GET WINDOW RECT`, which is the
  content-area origin and is not DPI-attested. See [FINDINGS.md](FINDINGS.md).

## Layout

```
Project/                 the 4D project (Project/Sources/...)
  Sources/Classes/POIRegistry.4dm      7 POIs, nearest(), SVG map + card files
  Sources/Classes/TourGeometry.4dm     screen-coordinate math and clamping
  Sources/Forms/Tour/                  the desktop form
  Sources/Methods/Tour_*.4dm           form logic, overlay calls, error capture
  Sources/Methods/Smoke*.4dm           headless acceptance + status/error helpers
Resources/Overlay/       generated card PNGs and the fragmented sample
tools/assets/make_assets.py          regenerates the PNGs with Pillow
tools/<name>/            4D skills tools, provisioned by the 4dtools skill
                         (git-ignored: boon, fourdform, tool4d-lsp-stdio,
                         4d-language-classic/oop)
docs/                    design-time form preview
.agents/                 miyako/skills submodule (development guidance)
```

`tools/assets/make_assets.py` uses Pillow and the bundled Python of the DSH
runtime in this session; any Python 3 with Pillow 10+ works:

```sh
python3 tools/assets/make_assets.py
```

## Related

* [Overlay](https://github.com/miyako/Overlay) — the component, its API and host tests.
* [miyako/skills](https://github.com/miyako/skills) — the 4D agent skills followed here;
  proposed edits from this build are described in [FINDINGS.md](FINDINGS.md#6-proposed-skills-edits).
* [FINDINGS.md](FINDINGS.md) — chokepoints, failures and findings from building this.

MIT licensed; see [LICENSE](LICENSE).
