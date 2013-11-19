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

Find and range iBeacons:

```javascript

var TiBeacons = require('org.beuckman.tibeacons');

TiBeacons.addEventListener("beaconRanges", function(event) {
   alert(event.beacons);
});

TiBeacons.startRangingForBeacons({
    uuid : "00000000-0000-0000-0000-000000000000",
    identifier : "TiBeacon Test",
    major: 1, // optional
    minor: 2  // optional
});
```

Listen for beacon proximity changes:

```javascript
TiBeacons.addEventListener("beaconProximity", function(e){
   alert("beacon "+e.major+"/"+e.minor+" is now "+e.proximity);
});
```