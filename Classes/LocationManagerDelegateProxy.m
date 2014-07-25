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


-(void)proxyAppDelegateLocationManagerMethodsTo:(id)delegate forManager:(CLLocationManager *)locationManager
{
    TiApp *appInstance = (TiApp*)[[UIApplication sharedApplication] delegate];
    
    [self addTargetDelegateProperty:delegate toAppDelegateClass:[appInstance class]];

    [self addProtocolToAppDelegate:[appInstance class]];
/*
    [self addMethodsToAppDelegate:[appInstance class]];
 
    // This is what enables iOS to invoke the non-running app on region status events
    // see: http://stackoverflow.com/questions/19127282/ibeacon-notification-when-the-app-is-not-running/22515773#22515773
    locationManager.delegate = appInstance;
*/
}

/**
 * Add a property to the AppDelegate to reference the target delegate
 */
-(void)addTargetDelegateProperty:(id)targetDelegate toAppDelegateClass:(Class)appDelegateClass {
    
    objc_property_attribute_t type = { "T", "@\"OrgBeuckmanTibeaconsModule\"" };
    objc_property_attribute_t ownership = { "C", "" }; // C = copy
    objc_property_attribute_t backingivar  = { "V", "_locationManagerDelegateProxyTarget" };
    objc_property_attribute_t attrs[] = { type, ownership, backingivar };
    class_addProperty(appDelegateClass, "locationManagerDelegateProxyTarget", attrs, 3);

}


-(void)addMethodsToAppDelegate:(Class)appDelegateClass {
    
    class_addMethod(appDelegateClass, @selector(locationManager:didEnterRegion:), (IMP)didEnterRegion, "v@:##");
}

/**
 * Tell iOS that our app conforms to CLLocationManagerDelegate
 */
-(void)addProtocolToAppDelegate:(Class)appDelegateClass {
    
    Protocol *locationManagerProtocol = objc_getProtocol("CLLocationManagerDelegate");
    
    class_addProtocol(appDelegateClass, locationManagerProtocol);
}



void didEnterRegion(id self, SEL _cmd, CLLocationManager *manager, CLRegion *region)
{
    NSLog(@"[INFO] didEnterRegion from proxy");
    
    Ivar ivar = class_getInstanceVariable([self class], "_locationManagerDelegateProxyTarget");
    id<CLLocationManagerDelegate> targetDelegate = object_getIvar(self, ivar);
    
    [targetDelegate locationManager:manager didEnterRegion:region];
}




@end
