// Tour_show_fragmented — deliberately trigger a native validation error.
//
// fragmented.png contains 700 separated alpha islands. A clickable overlay
// rejects more than 512 coverage rectangles, so the completion callback
// carries an `image_complexity` diagnostic. This is the error-path exhibit.

var $poi : Object
$poi:=Tour_selected_poi
Tour_display(File("/RESOURCES/Overlay/fragmented.png"); "clickable"; False; False)
