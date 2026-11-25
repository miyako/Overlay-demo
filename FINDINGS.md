# Findings: building a 4D project on the Overlay component

Notes from building `miyako/Overlay-demo` with the 4D 21 R5 toolchain and the
[miyako/skills](https://github.com/miyako/skills) playbook. Each item is something
that cost time, produced a wrong assumption, or is worth knowing before the next
project. Status vocabulary matches the skills' evidence matrix: `passed`,
`failed`, `not_run` mean *executed and passed*, *executed and failed*, and
*no execution evidence* — `not_run` is never a pass.

Environment: macOS 27.2.1 arm64, 4D 21 R5 build `100176`, `Application version`
`2150`, Overlay `0.1.1`.

## 1. The 512-rectangle image-complexity limit

`overlay-cli` rejects a **clickable** PNG whose alpha coverage needs more than 512
rectangles. It is a real, protocol-level error, not a size or memory limit:

```console
$ overlay-cli show --image Resources/Overlay/fragmented.png \
    --mode clickable --timeout-ms 300 --x 40 --y 40
{"protocol":1,"error":{"code":"image_complexity",
 "message":"clickable PNG exceeds 512 alpha-coverage rectangles"}}
exit 2
```

The same image in `passive` mode is accepted, and a normal card in `clickable`
mode is accepted. So the limit is about *hit-testing region extraction*, which
only matters when the overlay must report which part was clicked. The demo makes
this an intentional exhibit: **Fragmented sample** sends 700 alpha islands to a
clickable overlay and surfaces the diagnostic in the status panel.

Takeaway: design clickable overlays as a handful of solid shapes. Detailed art
belongs in a passive overlay; put invisible clickable regions on top if needed.

## 2. tool4d has no SVG rasterizer, and it can disturb later native calls

`SVG EXPORT TO PICTURE` fails under `tool4d`:

```
tool4d.4DRT [-9926] The referenced element is invalid.
action_description: "The XML command cannot be executed"
Picture size(...) = 0
```

The same SVG is well-formed (`xmllint --noout` passes) and Quick Look renders it,
so this is a missing GUI/SVG renderer in the headless tool, not a malformed
document. In the GUI form the call works and the map appears.

Worse, the failure is not clean. Calls into the compiled Overlay component made
*after* an `SVG EXPORT TO PICTURE` in the same startup method sometimes aborted
the method with no catchable error (`ON ERR CALL` never fired, `QUIT 4D` never
ran, exit code 0). Isolating the component checks in `SmokeComponent`, with no
SVG export in the same process, succeeded 4/4 runs. Treat that as a strong
correlation, not a proven mechanism — but the practical rule is simple: **do not
mix a known-failing XML/SVG call and component `SystemWorker` calls in one
headless run.**

Related: the component itself spawns SystemWorkers, and `handle.result` returns
the whole completion envelope (`ok/stdout/stderr/exitCode/value`), *not* the
decoded `value`. Read `result.value.outcome`, not `result.outcome`.

## 3. "Dependency cannot be found" is noise when Components/ is populated

Declaring the dependency in `Project/Sources/dependencies.json` makes every
tool4d run print:

```
PackageManager No component to fetch dependencies
PackageManager Dependency 'Overlay' cannot be found
```

…while `cs.Overlay.Overlay`, `.version()`, `.screens()`, `.capabilities()` and
`.show()` all work. The reason is the documented priority order: a component
found in the project's `Components/` folder wins over the dependency declaration.
tool4d prints the package-manager warning regardless; it is not a load failure.

Consequence for CI: a `not_run` on component checks is justified when
`Components/` is empty and only the network fetch is missing — but keep the
distinction between "package manager could not fetch" and "component cannot be
loaded". Here the latter was `passed`.

## 4. The LSP cannot see components

`tools/4dlsp` on this project reports exactly the expected set:

```
Tour_metadata.4dm:6:6: error: The class cs.Overlay.Overlay is unknown.
Tour_display.4dm:10:6: error: The class cs.Overlay.OverlayHandle is unknown.
```

No other diagnostics remain. That is not a syntax failure to fix — the compiler
and runtime resolve the component; the language server does not analyse
`Components/`. Budget for these known errors when using `check-syntax` as a gate,
and never "fix" them with dummy classes in the project.

## 5. 4D language traps that cost real time

* **No static members.** `cs.POIRegistry.all()` is a syntax/runtime error; every
  class method is an instance method. Use `cs.POIRegistry.new().all()`, and make
  helper methods that call each other idiomatic instance calls (`This.find(...)`).
* **No `Class` keyword line** in a `.4dm` class file. The compiler rejects
  `Class code out of any function`.
* **`Round` needs an explicit places argument**: `Round(x; 0)`, or the LSP reports
  a prototype mismatch.
* **`Min` / `Max` are array-only.** Scalar clamping is `If ($v<$min) ... End if`.
* **Typed local variables reject compatible-looking values.** Assigning a
  Picture to a variable declared `Object` raises `[15] This operation is not
  compatible with the two arguments` and leaves the variable unassigned — the
  method may then continue with a Null where you expected data. Declare
  `$picture : Picture`.
* **A typed `Object` variable cannot hold a Collection.** `var $pois : Object` plus
  `$pois := $reg.all()` produced a report field that silently rendered as `" POIs"`.
  Declare `$pois : Collection`.
* **No ternary.** `If(cond; a; b)` is not a function. A tiny `Smoke_status`
  method that maps a Boolean to `"passed"/"failed"` is the least noisy fix.
* **`Position`'s 4th argument is a length, not an occurrence count.**
  `Position("poi_"; $svg; 1; 7)` does not count 7 markers; it searched 7
  characters. Count with repeated calls if needed.
* **`Picture size()` returns bytes only** in this compiler; there is no
  width/height overload.
* **`var $x : Text array` is invalid**; use `ARRAY TEXT($x; 0)`.
* **Booleans do not short-circuit for type-sensitive work.** `($v#Null) & $v.ok`
  is fine for Objects here, but guard `Value type` before comparing variants when
  a Null is possible.

## 6. Desktop coordinates: honest but unverified

Positioning uses `GET WINDOW RECT` for the form's window, adds the object origin
and the marker's normalised map fraction, then offsets the card by half its width
and its full height plus a 10 px gap, clamped to the screen with an 8 px margin.
`TourGeometry` is unit-tested headlessly (`geometry.*` above).

What that does **not** prove: that the OS reports the same coordinate space,
that Retina scaling is handled, or that the marker position matches a pixel in the
rendered map. Form coordinates are assumed to start at the content area, which is
true for a standard window with the object at the page origin — worth an explicit
GUI check in a future session. An accepted click is reported at the pointer
location, not at an element inside the image, so "which marker was clicked" is
resolved by the host, not the component.

## 7. Async overlays need a live worker

`show` returns a handle immediately; completion arrives in a worker process. Two
consequences:

* Cancel is real: `handle.cancel()` flips shared state and messages the worker.
* A headless test must poll `handle.done` and bound the wait. Polling at 100 ms
  with a 10 s cap is enough for a 400 ms timeout overlay; the poll observed
  `dismissed/timeout` in 100 ms.

Keep the handle's state in a preallocated shared object (the component already
does) and never invent a shared PID map.

## 8. Proposed skills edits

Offered as a PR to `miyako/skills`; each one is grounded in an observation above.

| Skill | Proposed addition |
| --- | --- |
| `4dproject` | A "consuming a GitHub component" section: exact `dependencies.json` descriptor (`dependencies.NAME.github` + `version` or `tag`), the documented priority order (`Components/` > `dependencies.json` > built-in), and that the file must exist before the first headless open. |
| `4dcli` | Note that `PackageManager ... Dependency 'X' cannot be found` can appear while `Components/X.4dbase` still loads and component classes work — do not classify that log line as a failure. |
| `4dcli` | Add the SVG rasterizer gap: `SVG EXPORT TO PICTURE` under tool4d fails with `-9926` / `The XML command cannot be executed` and yields a 0-byte picture; rasterisation checks belong to a GUI run (`not_run` headless). Add the observation that a failing XML/SVG command earlier in the same headless method can make later component/SystemWorker calls abort uncatchably. |
| `4dproject` | Note that `fourdform` previews show picture inputs blank when their `dataSource` is bound at runtime; that is expected and not a form defect. |
| `4dmethods` / `4dlang` | A short "4D is not JavaScript" list: no static members, no `Class` keyword line, `Round(expr; places)`, array-only `Min`/`Max`, no ternary, `Position`'s 4th argument is a length, typed variables reject mismatched types with `[15]` and continue with Null. |
| `4dlsp` | Confirm that component classes are unresolvable by design and list the resulting expected diagnostics, so `check-syntax` output can be triaged without chasing them. |

## 9. What the next session should attack

* GUI acceptance: an actual click on a marker, verify the card appears next to
  it and that clicks pass through the transparent hole in `clickable` mode.
* Windows: `Overlay.new("Windows-x64")` on ARM64 Windows is unsupported; x64 is
  reached through emulation. No Windows 4D evidence exists here.
* Dependency-manager installation from GitHub (fresh `Components/` removed) to
  validate the declared descriptor end to end.
* Signed helper distribution if the demo is ever handed to someone who will hit
  Gatekeeper quarantine.

## 10. Evidence files

| Path | Content |
| --- | --- |
| `build/smoke.json` | 12 passed / 0 failed / 3 not_run, `finished: true` |
| `build/smoke-component.json` | 4 passed / 0 failed, `finished: true` |
| `build/smoke-component-step.txt` | last component step reached (`done`) |
| `build/tour-preview.png` | design-time form render |
| `docs/form-preview.png` | committed copy of the preview |
| `Overlay.md` history | component API used: `new`, `version`, `screens`, `capabilities`, `show`, `showBlob`, handle `done`/`cancel`/`result` |
