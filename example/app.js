
// open a single window
var win = Ti.UI.createWindow({
	backgroundColor:'white'
});
var label = Ti.UI.createLabel();
win.add(label);
win.open();


var TiBeacons = require('org.beuckman.tibeacons');
Ti.API.info("module is => " + TiBeacons);


// handle the results from ranging (below)
TiBeacons.addEventListener("didRangeBeacons", function(obj){
    Ti.API.info(obj);
});


// look for iBeacons
TiBeacons.startRangingForBeacons({
    uuid: "00000000-0000-0000-0000-000000000000",
    identifier: "TiBeacon Test"
});


// or if you want to be an iBeacon
TiBeacons.startAdvertisingBeacon({
    uuid: "00000000-0000-0000-0000-000000000000",
    identifier: "TiBeacon Test",
    major: 123,
    minor: 456
});

