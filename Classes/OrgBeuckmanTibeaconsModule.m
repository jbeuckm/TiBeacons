/**
 * Your Copyright Here
 *
 * Appcelerator Titanium is Copyright (c) 2009-2010 by Appcelerator, Inc.
 * and licensed under the Apache Public License (version 2)
 */
#import "OrgBeuckmanTibeaconsModule.h"
#import "TiBase.h"
#import "TiHost.h"
#import "TiUtils.h"


@interface OrgBeuckmanTibeaconsModule ()

//@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, strong) NSMutableDictionary *monitoringRegions;
@property (nonatomic, strong) NSMutableDictionary *rangingRegions;

@property (nonatomic, strong) CBPeripheralManager *peripheralManager;
@property (nonatomic, strong) CLBeaconRegion *beaconRegion;

@property (nonatomic, strong) NSMutableDictionary *beaconProximities;

@end

@implementation OrgBeuckmanTibeaconsModule

#pragma mark Internal

// this is generated for your module, please do not change it
-(id)moduleGUID
{
	return @"8d388e36-9093-4df8-a4d3-1db3621f04c0";
}

// this is generated for your module, please do not change it
-(NSString*)moduleId
{
	return @"org.beuckman.tibeacons";
}

#pragma mark Lifecycle

-(void)startup
{
	[super startup];
    
    self.monitoringRegions = [[NSMutableDictionary alloc] init];
    self.rangingRegions = [[NSMutableDictionary alloc] init];
    
    self.beaconProximities = [[NSMutableDictionary alloc] init];
    
    autoRange = YES;
	
	NSLog(@"[INFO] %@ loaded",self);
}

- (CLLocationManager *)locationManager {
    NSLog(@"MapViewController - locationManager");
    if (_locationManager) {
        return _locationManager;
    } else {
        _locationManager = [[CLLocationManager alloc] init];
        _locationManager.delegate = self;
        return _locationManager;
    }
}

-(void)shutdown:(id)sender
{
	// this method is called when the module is being unloaded
	// typically this is during shutdown. make sure you don't do too
	// much processing here or the app will be quit forceably
	
	// you *must* call the superclass
	[super shutdown:sender];
}

#pragma mark Cleanup 

-(void)dealloc
{
    [self.rangingRegions release];
    [self.monitoringRegions release];
    [self.beaconProximities release];
    
    if (_locationManager) {
        [_locationManager release];
    }
    if (self.peripheralManager) {
        [self.peripheralManager release];
    }
    
	// release any resources that have been retained by the module
	[super dealloc];
}

#pragma mark Internal Memory Management

-(void)didReceiveMemoryWarning:(NSNotification*)notification
{
	// optionally release any resources that can be dynamically
	// reloaded once memory is available - such as caches
	[super didReceiveMemoryWarning:notification];
}

#pragma mark Listener Notifications

-(void)_listenerAdded:(NSString *)type count:(int)count
{
	if (count == 1 && [type isEqualToString:@"my_event"])
	{
		// the first (of potentially many) listener is being added 
		// for event named 'my_event'
	}
}

-(void)_listenerRemoved:(NSString *)type count:(int)count
{
	if (count == 0 && [type isEqualToString:@"my_event"])
	{
		// the last listener called for event named 'my_event' has
		// been removed, we can optionally clean up any resources
		// since no body is listening at this point for that event
	}
}

#pragma Public APIs

-(id)autoRange:(id)args
{
    return autoRange;
}

-(void)setAutoRange:(BOOL)_autoRange
{
    autoRange = _autoRange;
}



#pragma mark - Beacon ranging


- (CLBeaconRegion *)createBeaconRegionWithUUID:(NSString *)uuid major:(NSInteger)major minor:(NSInteger)minor identifier:(NSString *)identifier
{
    
    NSUUID *proximityUUID = [[NSUUID alloc] initWithUUIDString:uuid];
    CLBeaconRegion *beaconRegion;
    
    if (major != -1 && minor != -1) {
        beaconRegion = [[CLBeaconRegion alloc] initWithProximityUUID:proximityUUID major:major minor:minor identifier:identifier];
    }
    else if (major != -1) {
        beaconRegion = [[CLBeaconRegion alloc] initWithProximityUUID:proximityUUID major:major identifier:identifier];
    }
    else {
        beaconRegion = [[CLBeaconRegion alloc] initWithProximityUUID:proximityUUID identifier:identifier];
    }
    
    [proximityUUID release];

    beaconRegion.notifyEntryStateOnDisplay = true;
    beaconRegion.notifyOnEntry = true;
    beaconRegion.notifyOnExit = true;
    
    return [beaconRegion autorelease];
}

- (void)turnOnRangingWithRegion:(CLBeaconRegion *)beaconRegion
{
    NSLog(@"[INFO] Turning on ranging...");
    
    if (![CLLocationManager isRangingAvailable]) {
        NSLog(@"[INFO] Couldn't turn on ranging: Ranging is not available.");
        return;
    }
    
    [self.rangingRegions setObject:beaconRegion forKey:beaconRegion.identifier];
    
    [self.locationManager startRangingBeaconsInRegion:beaconRegion];
    
    NSLog(@"[INFO] Ranging turned on for region: %@.", beaconRegion);
}


- (void)startRangingForBeacons:(id)args
{
    ENSURE_UI_THREAD_1_ARG(args);
    ENSURE_SINGLE_ARG(args, NSDictionary);
    
    NSString *uuid = [TiUtils stringValue:[args objectForKey:@"uuid"]];
    NSInteger major = (NSUInteger)[TiUtils intValue:[args objectForKey:@"major"] def:-1];
    NSInteger minor = (NSUInteger)[TiUtils intValue:[args objectForKey:@"minor"] def:-1];

    NSString *identifier = [TiUtils stringValue:[args objectForKey:@"identifier"]];
    
    CLBeaconRegion *region = [self createBeaconRegionWithUUID:uuid major:major minor:minor identifier:identifier];
    
    [self turnOnRangingWithRegion:region];
}

- (void)stopRangingForAllBeacons:(id)args
{
    if (self.locationManager.rangedRegions.count == 0) {
        NSLog(@"[INFO] Didn't turn off ranging: Ranging already off.");
        return;
    }
    
    NSEnumerator *enumerator = [self.rangingRegions keyEnumerator];
    id key;
    while ((key = [enumerator nextObject])) {
        CLBeaconRegion *region = [self.rangingRegions objectForKey:key];
        [self.locationManager stopRangingBeaconsInRegion:region];
        [self.rangingRegions removeObjectForKey:key];
    }
    
    NSLog(@"[INFO] Turned off ranging in ALL regions.");
}

- (void)stopRangingForRegion:(CLRegion *)region
{
    CLBeaconRegion *beaconRegion = [self.rangingRegions objectForKey:region.identifier];
    [self.locationManager stopRangingBeaconsInRegion:beaconRegion];
    [self.rangingRegions removeObjectForKey:region.identifier];
    
    NSLog(@"[INFO] Turned off ranging for %@.", beaconRegion.identifier);
}

//
// PUBLIC
// Method which allows the client to be notified when it has entered the region
//
- (void)startMonitoringForRegion:(id)args
{
    ENSURE_UI_THREAD_1_ARG(args);
    ENSURE_SINGLE_ARG(args, NSDictionary);
 
    NSLog(@"[INFO] Turning on region monitoring...");

    NSString *uuid = [TiUtils stringValue:[args objectForKey:@"uuid"]];
    NSInteger major = (NSUInteger)[TiUtils intValue:[args objectForKey:@"major"] def:-1];
    NSInteger minor = (NSUInteger)[TiUtils intValue:[args objectForKey:@"minor"] def:-1];
    
    NSString *identifier = [TiUtils stringValue:[args objectForKey:@"identifier"]];
    
    CLBeaconRegion *region = [self createBeaconRegionWithUUID:uuid major:major minor:minor identifier:identifier];

    [self.monitoringRegions setObject:region forKey:region.identifier];
    
    [self.locationManager startMonitoringForRegion:region];
}


// Callback from CLLocationManager
- (void) locationManager:(CLLocationManager *)manager didStartMonitoringForRegion:(CLRegion *)region
{
    NSLog(@"[INFO] Did start monitoring region: %@", region.identifier);
    [self.locationManager requestStateForRegion:region];
}

// Callback from CLLocationManager
-(void)locationManager:(CLLocationManager *)manager didDetermineState:(CLRegionState)state forRegion:(CLRegion *)region
{
    if (state == CLRegionStateUnknown) {
        NSLog(@"[INFO] Region state unknown: %@", region.identifier);
        return;
    }
    else if (state == CLRegionStateInside)
    {
        if (autoRange) {
            CLBeaconRegion *beaconRegion = [self.monitoringRegions objectForKey:region.identifier];
            [self turnOnRangingWithRegion:beaconRegion];
        }
        NSLog(@"[INFO] Determined that we are in the region - can now start ranging for %@", region.identifier);
    }
    else
    {
        if (autoRange) {
            CLBeaconRegion *beaconRegion = [self.monitoringRegions objectForKey:region.identifier];
            [self stopRangingForRegion:beaconRegion];
        }
        NSLog(@"[INFO] Determined that we are not in the region: %@", region.identifier);
    }
    
    NSDictionary *event = [[NSDictionary alloc] initWithObjectsAndKeys:
                           @(state), @"regionState",
                           region.identifier, @"identifier",
                           nil];
    
    [self fireEvent:@"determinedRegionState" withObject:event];

}

- (void)locationManager:(CLLocationManager *)manager didEnterRegion:(CLRegion *)region {
    
    NSLog(@"[INFO] Entered region %@", region.identifier);
    NSDictionary *event = [[NSDictionary alloc] initWithObjectsAndKeys:
                           region.identifier, @"identifier",
                           nil];
    
    if (autoRange) {
        [self turnOnRangingWithRegion:[self.monitoringRegions objectForKey:region.identifier]];
    }
    
    [self fireEvent:@"enteredRegion" withObject:event];
    
}

-(void)locationManager:(CLLocationManager *)manager didExitRegion:(CLRegion *)region {

    NSLog(@"[INFO] exited region %@", region.identifier);
    NSDictionary *event = [[NSDictionary alloc] initWithObjectsAndKeys:
                           region.identifier, @"identifier",
                           nil];
    
    if (autoRange) {
        [self stopRangingForRegion:[self.monitoringRegions objectForKey:region.identifier]];
    }
    
    [self fireEvent:@"exitedRegion" withObject:event];
}

-(void)stopMonitoringAllRegions:(id)args
{
    if (self.locationManager.monitoredRegions.count == 0) {
        NSLog(@"[INFO] Didn't turn off monitoring: Monitoring already off.");
        return;
    }
    
    NSEnumerator *enumerator = [self.monitoringRegions keyEnumerator];
    id key;
    while (key = [enumerator nextObject]) {
        CLBeaconRegion *region = [self.monitoringRegions objectForKey:key];
        [self.locationManager stopMonitoringForRegion:region];
        [self.monitoringRegions removeObjectForKey:key];
    }
    
    NSLog(@"[INFO] Turned off monitoring in ALL regions.");
}


#pragma mark - Beacon ranging delegate methods
- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    if (![CLLocationManager locationServicesEnabled]) {
        NSLog(@"[INFO] Couldn't turn on ranging: Location services are not enabled.");
        return;
    }
    
    if ([CLLocationManager authorizationStatus] != kCLAuthorizationStatusAuthorized) {
        NSLog(@"[INFO] Couldn't turn on ranging: Location services not authorised.");
        return;
    }
    
}

- (void)locationManager:(CLLocationManager *)manager
        didRangeBeacons:(NSArray *)beacons
               inRegion:(CLBeaconRegion *)region {
    
    NSArray *filteredBeacons = [self filteredBeacons:beacons];
    
    if (filteredBeacons.count == 0) {
        // do nothing - no beacons
    }
    else {

        NSString *count = [NSString stringWithFormat:@"%lu", (unsigned long)[filteredBeacons count]];

        NSMutableArray *eventBeacons = [[NSMutableArray alloc] init];
        for (id beacon in filteredBeacons) {
            // do something with object
            [eventBeacons addObject:[self detailsForBeacon:beacon]];
        }
        
        NSDictionary *event = [[NSDictionary alloc] initWithObjectsAndKeys:
                               region.identifier, @"identifier",
                               region.proximityUUID.UUIDString, @"uuid",
                               count, @"count",
                               eventBeacons, @"beacons",
                               nil];
        [eventBeacons release];
    
        [self fireEvent:@"beaconRanges" withObject:event];
        [event release];
        
        [self reportCrossings:filteredBeacons inRegion:region];
    }
}

- (void)reportCrossings:(NSArray *)beacons inRegion:(CLRegion *)region
{
    for (int index = 0; index < [beacons count]; index++) {
        CLBeacon *current = [beacons objectAtIndex:index];
        NSString *identifier = [NSString stringWithFormat:@"%@/%@/%@", current.proximityUUID.UUIDString, current.major, current.minor];
        
        CLBeacon *previous = [self.beaconProximities objectForKey:identifier];
        if (previous) {
            
            if (previous.proximity != current.proximity) {
                NSMutableDictionary *event = [NSMutableDictionary dictionaryWithDictionary:[self detailsForBeacon:current]];
                [event setObject:region.identifier forKey:@"identifier"];
                [event setObject:[self decodeProximity:previous.proximity] forKey:@"fromProximity"];
                
                [self fireEvent:@"beaconProximity" withObject:event];
            }
        }
        else {
            NSLog(@"[INFO] no previous beacon exists");

            NSMutableDictionary *event = [NSMutableDictionary dictionaryWithDictionary:[self detailsForBeacon:current]];
            [event setObject:region.identifier forKey:@"identifier"];
            [self fireEvent:@"beaconProximity" withObject:event];
        }

        [self.beaconProximities setObject:current forKey:identifier];
    }
}


- (NSArray *)filteredBeacons:(NSArray *)beacons
{
    // Filters duplicate beacons out; this may happen temporarily if the originating device changes its Bluetooth id
    NSMutableArray *mutableBeacons = [beacons mutableCopy];
    
    NSMutableSet *lookup = [[NSMutableSet alloc] init];
    for (int index = 0; index < [beacons count]; index++) {
        CLBeacon *curr = [beacons objectAtIndex:index];
        NSString *identifier = [NSString stringWithFormat:@"%@/%@", curr.major, curr.minor];
        
        // this is very fast constant time lookup in a hash table
        if ([lookup containsObject:identifier]) {
            [mutableBeacons removeObjectAtIndex:index];
        } else {
            [lookup addObject:identifier];
        }
    }
    
    return [mutableBeacons copy];
}


- (NSDictionary *)detailsForBeacon:(CLBeacon *)beacon
{
    
    NSString *proximity = [self decodeProximity:beacon.proximity];
    
    NSDictionary *details = [[NSDictionary alloc] initWithObjectsAndKeys:
                             beacon.proximityUUID.UUIDString, @"uuid",
                             [NSString stringWithFormat:@"%@", beacon.major], @"major",
                             [NSString stringWithFormat:@"%@", beacon.minor], @"minor",
                             proximity, @"proximity",
                             [NSString stringWithFormat:@"%f", beacon.accuracy], @"accuracy",
                             [NSString stringWithFormat:@"%d", beacon.rssi], @"rssi",
                             nil
                             ];
    
    return [details autorelease];
}


- (NSString *)decodeProximity:(int)proximity
{
    switch (proximity) {
        case CLProximityNear:
            return @"near";
            break;
        case CLProximityImmediate:
            return @"immediate";
            break;
        case CLProximityFar:
            return @"far";
            break;
        case CLProximityUnknown:
        default:
            return @"unknown";
            break;
    }
    
}


#pragma mark - Beacon advertising
- (void)turnOnAdvertising
{
    if (self.peripheralManager.state != CBPeripheralManagerStatePoweredOn) {
        NSLog(@"[INFO] Peripheral manager is off.");
        return;
    }

    NSDictionary *beaconPeripheralData = [self.beaconRegion peripheralDataWithMeasuredPower:nil];
    [self.peripheralManager startAdvertising:beaconPeripheralData];
    
    NSLog(@"[INFO] Turning on advertising for region: %@.", self.beaconRegion);
}


- (void)startAdvertisingBeacon:(id)args
{
    ENSURE_UI_THREAD_1_ARG(args);
    ENSURE_SINGLE_ARG(args, NSDictionary);
    
    NSString *uuid = [TiUtils stringValue:[args objectForKey:@"uuid"]];
    NSString *identifier = [TiUtils stringValue:[args objectForKey:@"identifier"]];
    
    NSUInteger major = (NSUInteger)[TiUtils intValue:[args objectForKey:@"major"] def:1];
    NSUInteger minor = (NSUInteger)[TiUtils intValue:[args objectForKey:@"minor"] def:1];

    NSLog(@"[INFO] Turning on advertising...");
    
    self.beaconRegion = [self createBeaconRegionWithUUID:uuid major:major minor:minor identifier:identifier];
    [self.beaconRegion retain];
    
    if (!self.peripheralManager) {
        self.peripheralManager = [[CBPeripheralManager alloc] initWithDelegate:self queue:nil options:nil];
    }
    
    [self turnOnAdvertising];
}

- (void)stopAdvertisingBeacon:(id)args
{
    
    if (self.peripheralManager) {
        
        if (self.peripheralManager.state == CBPeripheralManagerStatePoweredOn){
            
            [self.peripheralManager stopAdvertising];
            
            [self.beaconRegion release];
            
            NSLog(@"[INFO] Turned off advertising.");
        }else{
            NSLog(@"[INFO] peripheral manager state was off, no need to turn advertsing off");
        }
    }
}

#pragma mark - Beacon advertising delegate methods
- (void)peripheralManagerDidStartAdvertising:(CBPeripheralManager *)peripheralManager error:(NSError *)error
{
    if (error) {
        NSLog(@"[INFO] Couldn't turn on advertising: %@", error);

        return;
    }
    
    if (peripheralManager.isAdvertising) {
        NSLog(@"[INFO] Turned on advertising.");
        
        NSDictionary *status = [[NSDictionary alloc] initWithObjectsAndKeys: @"on", @"status", nil];

        [self fireEvent:@"advertisingStatus" withObject:status];
        [status autorelease];
    }
}

- (void)peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheralManager
{
    if (peripheralManager.state != CBPeripheralManagerStatePoweredOn) {
        NSLog(@"[INFO] Peripheral manager is off.");
        return;
    }
    
    NSLog(@"[INFO] Peripheral manager is on.");

    [self turnOnAdvertising];
}


@end
