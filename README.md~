### Usage ###

Become an iBeacon:

```javascript
var TiBeacons = require('org.beuckman.tibeacons');

TiBeacons.addEventListener("advertisingStatus", function(event) {
    Ti.API.info(event.status);
});

TiBeacons.startAdvertisingBeacon({
   uuid : "00000000-0000-0000-0000-000000000000",
   identifier : "TiBeacon Test"
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
    identifier : "TiBeacon Test"
});
```

