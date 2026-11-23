// Executed by osascript with the JavaScript language option. Emit one AppKit
// screen index and physical display ID per line for display_map.sh.

ObjC.import("AppKit");

var screens = $.NSScreen.screens;
var displayIds = [];
for (var index = 0; index < screens.count; index++) {
    var description = screens.objectAtIndex(index).deviceDescription;
    displayIds.push(
        (index + 1) + "|" + ObjC.unwrap(description.objectForKey("NSScreenNumber"))
    );
}
displayIds.join("\n");
