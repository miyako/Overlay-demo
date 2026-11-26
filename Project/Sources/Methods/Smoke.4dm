// Smoke — headless acceptance for the parts of the demo that do not need a GUI.
//
//   tool4d --project=Project/OverlayDemo.4DProject --skip-onstartup \
//          --startup-method=Smoke
//
// Writes build/smoke.json. The Overlay component calls live in SmokeComponent
// (a separate startup method) because calling compiled component classes from
// this tool4d build is not reliable: see FINDINGS.md. This method therefore
// reports component checks as not_run and still finishes, so the deterministic
// checks below always produce evidence.

ON ERR CALL("Smoke_error"; ek local)

var $report; $check; $poi; $form; $position; $marker : Object
var $pois : Collection
var $reg : Object
var $checks : Collection
var $database; $build : 4D.Folder
var $file; $formFile : 4D.File
var $svg : Text
var $picture : Picture

$database:=Folder(fk database folder)
$build:=$database.folder("build")
If (Not($build.exists))
	$build.create()
End if
$checks:=New collection

// POIRegistry: the data model is a plain class with no UI dependency.
$reg:=cs.POIRegistry.new()
$pois:=$reg.all()
$checks.push(New object("name"; "registry.count"; "status"; Smoke_status($pois.length=7); "detail"; String($pois.length)+" POIs"))
$check:=$reg.find("tidepools")
$checks.push(New object("name"; "registry.find.hit"; "status"; Smoke_status(($check#Null) & ($check.id="tidepools")); "detail"; "find(\"tidepools\")"))
$check:=$reg.find("nowhere")
$checks.push(New object("name"; "registry.find.miss"; "status"; Smoke_status($check=Null); "detail"; "find(\"nowhere\")"))

$poi:=$reg.nearest(0.22; 0.62)
$checks.push(New object("name"; "registry.nearest.hit"; "status"; Smoke_status(($poi#Null) & ($poi.id="tidepools")); "detail"; "nearest(0.22, 0.62)"))
$poi:=$reg.nearest(0.99; 0.01)
$checks.push(New object("name"; "registry.nearest.miss"; "status"; Smoke_status($poi=Null); "detail"; "no marker near (0.99, 0.01)"))

// Map picture: the SVG document is generated as text; rasterisation is a GUI
// concern (tool4d has no SVG renderer, see FINDINGS.md).
$svg:=$reg.svg("tidepools"; New object())
$checks.push(New object("name"; "svg.render"; "status"; Smoke_status((Position("<svg"; $svg)=1) & (Position("poi_tidepools"; $svg)>0) & (Length($svg)>3000)); "detail"; String(Length($svg))+" chars"))
$checks.push(New object("name"; "svg.markers"; "status"; Smoke_status((Position("poi_tidepools"; $svg)>0) & (Position("poi_night_market"; $svg)>0) & (Position("poi_copper_mine"; $svg)>0)); "detail"; "marker ids for first, middle and last POI"))
$picture:=$reg.picture("tidepools"; New object())
$checks.push(New object("name"; "svg.to.picture"; "status"; Smoke_status(Picture size($picture)>0); "detail"; "Picture size="+String(Picture size($picture))+" bytes"))
$check:=New object("tidepools"; True; "lighthouse"; True; "whale_pier"; False)
$checks.push(New object("name"; "registry.visitedCount"; "status"; Smoke_status(($reg.visitedCount($check)=2) & ($reg.visitedCount(Null)=0)); "detail"; "2 visited of 3 keys"))
$svg:=$reg.svg("night_market"; New object())
$checks.push(New object("name"; "svg.label.clamp"; "status"; Smoke_status(Length($svg)>3000); "detail"; "label near the right edge renders"))

// TourGeometry: pure Integer arithmetic in screen coordinates.
$position:=cs.TourGeometry.new().desktopPoint(100; 50; 10; 20; 500; 400; 0.5; 0.5)
$checks.push(New object("name"; "geometry.desktopPoint"; "status"; Smoke_status(($position.x=360) & ($position.y=270)); "detail"; String($position.x)+", "+String($position.y)))
$marker:=cs.TourGeometry.new().cardTopLeft(360; 270; 300; 166; 10)
$checks.push(New object("name"; "geometry.cardTopLeft"; "status"; Smoke_status(($marker.x=210) & ($marker.y=94)); "detail"; String($marker.x)+", "+String($marker.y)))
$position:=cs.TourGeometry.new().clampToScreen(-50; 1000; 300; 166; 1512; 993; 8)
$checks.push(New object("name"; "geometry.clamp"; "status"; Smoke_status(($position.x=8) & ($position.y=819) & ($position.clamped=True)); "detail"; String($position.x)+", "+String($position.y)))

// Form JSON: the desktop form must be present and complete enough to open.
$formFile:=$database.file("Project/Sources/Forms/Tour/form.4DForm")
If ($formFile.exists)
	$form:=JSON Parse($formFile.getText())
	$checks.push(New object("name"; "form.json"; "status"; Smoke_status(($form.pages.length=2) & (Value type($form.pages[0].objects.map)=Is object) & (Value type($form.pages[0].objects.poiList)=Is object) & ($form.method="method.4dm")); "detail"; String($form.pages.length)+" pages, method "+String($form.method)))
Else
	$checks.push(New object("name"; "form.json"; "status"; "failed"; "detail"; "form file missing"))
End if

// Bundled card images referenced by the registry.
$checks.push(New object("name"; "assets"; "status"; "passed"; "detail"; "7 card images + fragmented sample"))
For each ($poi; $pois)
	$file:=$database.file("Resources/"+$poi.card)
	If ((Not($file.exists)) | ($file.size<1000))
		$checks.pop()
		$checks.push(New object("name"; "assets"; "status"; "failed"; "detail"; "missing or tiny: "+$poi.card))
	End if
End for each
$file:=$database.file("Resources/Overlay/fragmented.png")
If (Not($file.exists))
	$checks.pop()
	$checks.push(New object("name"; "assets"; "status"; "failed"; "detail"; "missing Resources/Overlay/fragmented.png"))
End if

// Component metadata is attempted separately.
$checks.push(New object("name"; "component.version"; "status"; "not_run"; "detail"; "see SmokeComponent / FINDINGS.md"))
$checks.push(New object("name"; "component.screens"; "status"; "not_run"; "detail"; "see SmokeComponent / FINDINGS.md"))

$report:=New object
$report.protocol:=1
$report.finished:=True
$report.phase:="done"
$report.checks:=$checks
$report.passed:=0
$report.failed:=0
$report.not_run:=0
For each ($check; $checks)
	Case of
		: ($check.status="passed")
			$report.passed:=$report.passed+1
		: ($check.status="failed")
			$report.failed:=$report.failed+1
		Else
			$report.not_run:=$report.not_run+1
	End case
End for each
$report.isCompiled:=Is compiled mode
$report.applicationVersion:=Application version

$file:=$build.file("smoke.json")
$file.setText(JSON Stringify($report; *))
QUIT 4D(0)
