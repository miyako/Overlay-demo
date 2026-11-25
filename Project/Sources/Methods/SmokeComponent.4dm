// SmokeComponent — headless check of the Overlay component classes.
//
//   tool4d --project=Project/OverlayDemo.4DProject --skip-onstartup \
//          --startup-method=SmokeComponent
//
// Deliberately separate from Smoke: in the observed tool4d 21 R5 build the call
// into the compiled Overlay component sometimes aborts the startup method with
// no catchable error (see FINDINGS.md). Keeping it isolated means the main
// smoke report is never lost. Steps are written to build/smoke-component-step.txt
// so a silent abort shows exactly which call was reached.

ON ERR CALL("Smoke_error"; ek local)

var $build : 4D.Folder
var $target : Text
var $overlay; $version; $screens; $caps; $check : Object
var $checks : Collection
var $file : 4D.File

$build:=Folder(fk database folder).folder("build")
If (Not($build.exists))
	$build.create()
End if
$build.file("smoke-component-step.txt").setText("start")
$checks:=New collection

$target:=Tour_target
$build.file("smoke-component-step.txt").setText("target="+$target)

$overlay:=cs.Overlay.Overlay.new($target)
$build.file("smoke-component-step.txt").setText("constructed")

$version:=$overlay.version()
$build.file("smoke-component-step.txt").setText("version")
$checks.push(New object("name"; "component.version"; "status"; Smoke_status(($version#Null) & $version.ok & ($version.value.version#"") ); "detail"; "helper version "+String($version.value.version)))

$screens:=$overlay.screens()
$build.file("smoke-component-step.txt").setText("screens")
$checks.push(New object("name"; "component.screens"; "status"; Smoke_status(($screens#Null) & $screens.ok & ($screens.value.screens.length>0)); "detail"; String($screens.value.screens.length)+" screen(s)"))

$caps:=$overlay.capabilities()
$build.file("smoke-component-step.txt").setText("capabilities")
$checks.push(New object("name"; "component.capabilities"; "status"; Smoke_status(($caps#Null) & $caps.ok & ($caps.value.protocol=1)); "detail"; "modes "+String($caps.value.modes.length)+", format "+String($caps.value.format)))

// Real display: passive card with a short timeout, then poll the handle.
var $handle : cs.OverlayHandle
var $options; $outcome : Object
var $card : 4D.File
var $waited : Integer
$card:=Folder(fk database folder).file("Resources/Overlay/card_01_tidepools.png")
$options:=New object("image"; $card; "mode"; "passive"; "timeoutMs"; 400; "fadeInMs"; 0; "fadeOutMs"; 0; "opacity"; 0.9)
$build.file("smoke-component-step.txt").setText("show")
$handle:=$overlay.show($options; Null)
$waited:=0
While ((Not($handle.done)) & ($waited<100))
	DELAY PROCESS(Current process; 100)
	$waited:=$waited+1
End while
$build.file("smoke-component-step.txt").setText("shown")
If ($handle.done)
	$outcome:=$handle.result
	$build.file("smoke-component-show.json").setText(JSON Stringify($outcome; *))
	$checks.push(New object("name"; "component.show"; "status"; Smoke_status(($outcome#Null) & ($outcome.ok=True) & (String($outcome.value.outcome)="dismissed") & (String($outcome.value.reason)="timeout")); "detail"; "outcome "+String($outcome.value.outcome)+", reason "+String($outcome.value.reason)+", waited "+String($waited*100)+" ms"))
Else
	$checks.push(New object("name"; "component.show"; "status"; "failed"; "detail"; "handle not done after 10 s"))
End if

$check:=New object("protocol"; 1; "finished"; True; "phase"; "component"; "checks"; $checks; "passed"; 0; "failed"; 0; "not_run"; 0)
For each ($caps; $checks)
	Case of
		: ($caps.status="passed")
			$check.passed:=$check.passed+1
		: ($caps.status="failed")
			$check.failed:=$check.failed+1
		Else
			$check.not_run:=$check.not_run+1
	End case
End for each
$check.isCompiled:=Is compiled mode
$check.applicationVersion:=Application version
$file:=$build.file("smoke-component.json")
$file.setText(JSON Stringify($check; *))
$build.file("smoke-component-step.txt").setText("done")
QUIT 4D(0)
