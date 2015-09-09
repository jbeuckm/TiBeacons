### Usage ###

See this example app for usage: [TiBeacons Example App](https://github.com/jbeuckm/TiBeacons-Example-App)

Become an iBeacon:

```javascript
var TiBeacons = require('org.beuckman.tibeacons');

TiBeacons.addEventListener("advertisingStatus", function(event) {
    Ti.API.info(event.status);
});

TiBeacons.startAdvertisingBeacon({
   uuid : "00000000-0000-0000-0000-000000000000",
   identifier : "TiBeacon Test",
   major: 1,
   minor: 2
});
```

Start monitoring for iBeacons in one or more regions. This will continue in the background if the proper UIBackgroundModes are listed in tiapp.xml. Once the app has run once, iOS will start your app and run the event handler if it finds one of the monitored regions. The app does not have to be running.

```javascript

TiBeacons.startMonitoringForRegion({
    uuid : "00000000-0000-0000-0000-000000000000",
    identifier : "Test Region 1",
});

TiBeacons.startMonitoringForRegion({
    uuid : "00000000-0000-0000-0000-000000000001",
    identifier : "Test Region 2 (group-specific)",
    major: 1
});

TiBeacons.startMonitoringForRegion({
    uuid : "00000000-0000-0000-0000-000000000002",
    identifier : "Test Region 3 (device-specific)",
    major: 1,
    minor: 2
});
```

Listen for region events:

```javascript
TiBeacons.addEventListener("enteredRegion", alert);
TiBeacons.addEventListener("exitedRegion", alert);
TiBeacons.addEventListener("determinedRegionState", alert);
```

Start ranging beacons in a region. This takes takes more energy and will report the approximate distance of the device to the beacon.

```javascript
TiBeacons.startRangingForBeacons({
    uuid : "00000000-0000-0000-0000-000000000002",
    identifier : "Test Region",
    major: 1, //optional
    minor: 2 //optional
});
```

Listen for the range events:

```javascript
TiBeacons.addEventListener("beaconRanges", function(event) {
   alert(event.beacons);
});
```

Or just listen for beacon proximity changes:

```javascript
TiBeacons.addEventListener("beaconProximity", function(e){
   alert("beacon "+e.major+"/"+e.minor+" is now "+e.proximity);
});
```

## Permission and Hardware Status ##

Get notified when the user allows or disallows location services for your app:

```javascript
TiBeacons.addEventListener("changeAuthorizationStatus", function(e){
   if (e.status != "authorized") {
      Ti.API.error("not authorized");
   }
});
```

Find out if bluetooth is on or off (or unauthorized or unsupported or resetting):

```javascript
TiBeacons.addEventListener("bluetoothStatus", function(e){
   if (e.status != "on") {
      Ti.API.error("bluetooth is not on");
   }
});

TiBeacons.requestBluetoothStatus();

```



