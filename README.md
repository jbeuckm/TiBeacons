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

Start monitoring for iBeacons in one or more regions:

```javascript

TiBeacons.startMonitoringForRegion({
    uuid : "00000000-0000-0000-0000-000000000000",
    identifier : "Test Region 1",
});

TiBeacons.startRangingForBeacons({
    uuid : "00000000-0000-0000-0000-000000000001",
    identifier : "Test Region 2 (group-specific)",
    major: 1
});

TiBeacons.startRangingForBeacons({
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

If auto-ranging is enabled, the module will automatically start ranging when a region is entered.

```javascript
TiBeacons.enableAutoRanging();
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

