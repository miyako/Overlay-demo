// Smoke_error — dump the runtime failure that aborted Smoke, then leave quietly.
var $report : Object
var $build : 4D.Folder
var $file : 4D.File
$build:=Folder(fk database folder).folder("build")
If (Not($build.exists))
	$build.create()
End if
$file:=$build.file("smoke-error.json")
$report:=New object("protocol"; 1; "finished"; True; "phase"; "error"; "errors"; Last errors; "method"; "Smoke"; "step"; Storage.probeStep)
$file.setText(JSON Stringify($report; *))
QUIT 4D(0)
