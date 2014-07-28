//
//  LocationManagerBunger.m
//  TiBeacons
//
//  Created by Joe Beuckman on 7/25/14.
//
//  This is intended to add protocol and delegate methods to the AppDelegate
//
//  This is done so that iOS will wake the app -- which requires CLLocationManagerDelegate to be the AppDelegate
//
//

#import "LocationManagerDelegateProxy.h"
#import "OrgBeuckmanTibeaconsModule.h"

@implementation LocationManagerDelegateProxy


-(void)proxyAppDelegateLocationManagerMethodsTo:(id<CLLocationManagerDelegate>)delegate forManager:(CLLocationManager *)locationManager
{
    NSLog(@"[INFO] proxyAppDelegateLocationManagerMethodsTo");
    
    TiApp *appInstance = (TiApp*)[[UIApplication sharedApplication] delegate];
    
    [self setTargetDelegate:delegate forObject:appInstance];

    [self addMethodsToAppDelegate:[appInstance class]];
    
    [self addProtocolToAppDelegate:[appInstance class]];
 
    // This is what enables iOS to invoke the non-running app on region status events
    // see: http://stackoverflow.com/questions/19127282/ibeacon-notification-when-the-app-is-not-running/22515773#22515773
    locationManager.delegate = appInstance;
}

static char targetDelegateKey;


/**
 * Associate the target delegate with the AppDelegate so the delegate methods can be passed on.
 */
-(void)setTargetDelegate:(id)targetDelegate forObject:(id)objectInstance {
    objc_setAssociatedObject(objectInstance, &targetDelegateKey, targetDelegate, OBJC_ASSOCIATION_RETAIN);
}


/*
 -(void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status{};
 -(void)locationManager:(CLLocationManager *)manager monitoringDidFailForRegion:(CLRegion *)region withError:(NSError *)error{};
 -(void)locationManager:(CLLocationManager *)manager didStartMonitoringForRegion:(CLRegion *)region{};
 -(void)locationManager:(CLLocationManager *)manager didDetermineState:(CLRegionState)state forRegion:(CLRegion *)region{};
 -(void)locationManager:(CLLocationManager *)manager didEnterRegion:(CLRegion *)region{};
 -(void)locationManager:(CLLocationManager *)manager didExitRegion:(CLRegion *)region{};
 
 -(void)locationManager:(CLLocationManager *)manager rangingBeaconsDidFailForRegion:(CLBeaconRegion *)region withError:(NSError *)error{};
 -(void)locationManager:(CLLocationManager *)manager didRangeBeacons:(NSArray *)beacons inRegion:(CLBeaconRegion *)region{};
 */

-(void)addMethodsToAppDelegate:(Class)appDelegateClass {
    
    class_addMethod(appDelegateClass, @selector(locationManager:didChangeAuthorizationStatus:), (IMP)didChangeAuthorizationStatus, "v@:@@");
    class_addMethod(appDelegateClass, @selector(locationManager:monitoringDidFailForRegion:withError:), (IMP)monitoringDidFailForRegion, "v@:@@@");
    class_addMethod(appDelegateClass, @selector(locationManager:didStartMonitoringForRegion:), (IMP)didStartMonitoringForRegion, "v@:@@");
    class_addMethod(appDelegateClass, @selector(locationManager:didDetermineState:forRegion:), (IMP)didDetermineState, "v@:@@@");
    class_addMethod(appDelegateClass, @selector(locationManager:didEnterRegion:), (IMP)didEnterRegion, "v@:@@");
    class_addMethod(appDelegateClass, @selector(locationManager:didExitRegion:), (IMP)didExitRegion, "v@:@@");

    class_addMethod(appDelegateClass, @selector(locationManager:rangingBeaconsDidFailForRegion:withError:), (IMP)rangingBeaconsDidFailForRegion, "v@:@@@");
    class_addMethod(appDelegateClass, @selector(locationManager:didRangeBeacons:inRegion:), (IMP)didRangeBeacons, "v@:@@@");
}


void didRangeBeacons(id self, SEL _cmd, CLLocationManager *manager, NSArray *beacons, CLBeaconRegion *region) {
    id<CLLocationManagerDelegate> targetDelegate = objc_getAssociatedObject(self, &targetDelegateKey);
    [targetDelegate locationManager:manager didRangeBeacons:beacons inRegion:region];
}
void rangingBeaconsDidFailForRegion(id self, SEL _cmd, CLLocationManager *manager, CLBeaconRegion *region, NSError *error) {
    id<CLLocationManagerDelegate> targetDelegate = objc_getAssociatedObject(self, &targetDelegateKey);
    [targetDelegate locationManager:manager rangingBeaconsDidFailForRegion:region withError:error];
}
void didDetermineState(id self, SEL _cmd, CLLocationManager *manager, CLRegionState state, CLRegion *region) {
    id<CLLocationManagerDelegate> targetDelegate = objc_getAssociatedObject(self, &targetDelegateKey);
    [targetDelegate locationManager:manager didDetermineState:state forRegion:region];
}
void didStartMonitoringForRegion(id self, SEL _cmd, CLLocationManager *manager, CLRegion *region) {
    id<CLLocationManagerDelegate> targetDelegate = objc_getAssociatedObject(self, &targetDelegateKey);
    [targetDelegate locationManager:manager didStartMonitoringForRegion:region];
}
void monitoringDidFailForRegion(id self, SEL _cmd, CLLocationManager *manager, CLRegion *region, NSError *error) {
    id<CLLocationManagerDelegate> targetDelegate = objc_getAssociatedObject(self, &targetDelegateKey);
    [targetDelegate locationManager:manager monitoringDidFailForRegion:region withError:error];
}
void didChangeAuthorizationStatus(id self, SEL _cmd, CLLocationManager *manager, CLAuthorizationStatus status) {
    id<CLLocationManagerDelegate> targetDelegate = objc_getAssociatedObject(self, &targetDelegateKey);
    [targetDelegate locationManager:manager didChangeAuthorizationStatus:status];
}
void didEnterRegion(id self, SEL _cmd, CLLocationManager *manager, CLRegion *region) {
    id<CLLocationManagerDelegate> targetDelegate = objc_getAssociatedObject(self, &targetDelegateKey);
    [targetDelegate locationManager:manager didEnterRegion:region];
}
void didExitRegion(id self, SEL _cmd, CLLocationManager *manager, CLRegion *region) {
    id<CLLocationManagerDelegate> targetDelegate = objc_getAssociatedObject(self, &targetDelegateKey);
    [targetDelegate locationManager:manager didExitRegion:region];
}


/**
 * Tell iOS that our app conforms to CLLocationManagerDelegate
 */
-(void)addProtocolToAppDelegate:(Class)appDelegateClass {
    
    Protocol *locationManagerProtocol = objc_getProtocol("CLLocationManagerDelegate");
    
    class_addProtocol(appDelegateClass, locationManagerProtocol);
}


@end
