
#import "TiModule.h"
#import "LocationManagerDelegateProxy.h"

@import CoreLocation;
@import CoreBluetooth;

@interface OrgBeuckmanTibeaconsModule : TiModule <CLLocationManagerDelegate, CBPeripheralManagerDelegate, CBCentralManagerDelegate>
{
    CBPeripheralManager *peripheralManager;
    CLBeaconRegion *beaconRegion;
    
    NSMutableDictionary *beaconProximities;
    CLLocationManager *_locationManager;
    CBCentralManager *bluetoothManager;
}

@end
