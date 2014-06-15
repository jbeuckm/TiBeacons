var TiBeacons = require('org.beuckman.tibeacons');
Ti.API.info("module is => " + TiBeacons);

TiBeacons.enableAutoRanging();

function enterRegion(e) {
	alert(e);
}
function exitRegion(e) {
	alert(e);
}
function updateRanges(e) {
	Ti.API.info(e);
}
function handleProximity(e) {
	Ti.API.info(e);
	
	console.log("proximity: " + e.proximity);
}

function addListeners() {

	TiBeacons.addEventListener("enteredRegion", enterRegion);
	TiBeacons.addEventListener("exitedRegion", exitRegion);

	TiBeacons.addEventListener("beaconRanges", updateRanges);
	TiBeacons.addEventListener("beaconProximity", handleProximity);
	
}
function removeListeners() {
	
	TiBeacons.removeEventListener("enteredRegion", enterRegion);
	TiBeacons.removeEventListener("exitedRegion", exitRegion);

	TiBeacons.removeEventListener("beaconRanges", updateRanges);
	TiBeacons.removeEventListener("beaconProximity", handleProximity);
}

function pauseApp() {
	TiBeacons.stopMonitoringAllRegions();
	TiBeacons.stopRangingForAllBeacons();

	removeListeners();
}
function appResumed(e) {
	addListeners();
}
Ti.App.addEventListener("pause", pauseApp);
Ti.App.addEventListener("resumed", appResumed);

addListeners();



function toggleMonitoring() {

    if ($.monitoringSwitch.value) {
        TiBeacons.startMonitoringForRegion({
            uuid : "00000000-0000-0000-0000-000000000000",
            identifier : "Test Region 1"
        });
        TiBeacons.startMonitoringForRegion({
            uuid : "00000000-0000-0000-0000-000000000001",
            major: 1,
            identifier : "Test Region 2"
        });
        TiBeacons.startMonitoringForRegion({
            uuid : "00000000-0000-0000-0000-000000000002",
            major: 1,
            minor: 2,
            identifier : "Test Region 3"
        });

        TiBeacons.startMonitoringForRegion({
            uuid : "B9407F30-F5F8-466E-AFF9-25556B57FE6D",
            identifier : "Estimote"
        });

    } else {
	TiBeacons.stopMonitoringAllRegions();
    }
}
