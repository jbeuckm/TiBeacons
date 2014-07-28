//
//  LocationManagerBunger.h
//  TiBeacons
//
//  Created by Joe on 7/25/14.
//

#import <Foundation/Foundation.h>
#import "TiApp.h"

#include <objc/runtime.h>

@import CoreLocation;
@import CoreBluetooth;

@interface LocationManagerDelegateProxy : NSObject
{

}

-(void)proxyAppDelegateLocationManagerMethodsTo:(id)delegate forManager:(CLLocationManager *)locationManager;

@end
