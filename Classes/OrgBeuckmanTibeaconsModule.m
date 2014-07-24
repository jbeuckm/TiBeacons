#import "OrgBeuckmanTibeaconsModule.h"
#import "TiBase.h"
#import "TiHost.h"
#import "TiUtils.h"


@interface OrgBeuckmanTibeaconsModule ()


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
    
    beaconProximities = [[NSMutableDictionary alloc] init];
    
	NSLog(@"[INFO] %@ loaded",self);
}

- (CLLocationManager *)locationManager {
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
    [beaconProximities release];
    
    if (_locationManager) {
        [_locationManager release];
    }
    if (peripheralManager) {
        [peripheralManager release];
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

- (id)authorizationStatus
{
    return [self decodeAuthorizationStatus:[CLLocationManager authorizationStatus]];
}


#pragma mark - Beacon monitoring

- (void)startMonitoringForRegion:(id)args
{
    ENSURE_UI_THREAD_1_ARG(args);
    ENSURE_SINGLE_ARG(args, NSDictionary);

    CLBeaconRegion *region = [self regionForArgs:args];
    
    NSLog(@"[INFO] Turning on region monitoring in %@", region);

    [self.locationManager startMonitoringForRegion:region];
}

-(void)stopMonitoringAllRegions:(id)args
{
    NSArray *regions = [[self locationManager].monitoredRegions allObjects];
    
    for (CLBeaconRegion *region in regions) {
        [[self locationManager] stopMonitoringForRegion:region];
    }
    [regions release];
    
    NSLog(@"[INFO] Turned off monitoring in ALL regions.");
}



#pragma mark - Beacon monitoring delegate methods

- (void)locationManager:(CLLocationManager *)manager monitoringDidFailForRegion:(CLRegion *)region withError:(NSError *)error
{
    NSLog(@"[ERROR] monitoringDidFailForRegion");
}
- (void)locationManager:(CLLocationManager *)manager rangingBeaconsDidFailForRegion:(CLBeaconRegion *)region withError:(NSError *)error
{
    NSLog(@"[ERROR] rangingBeaconsDidFailForRegion");
}

- (void) locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
        if (![CLLocationManager locationServicesEnabled]) {
            NSLog(@"[ERROR] Location services are not enabled.");
        }
        
        if ([CLLocationManager authorizationStatus] != kCLAuthorizationStatusAuthorized) {
            NSLog(@"[ERROR] Location services not authorized.");
        }
    

    NSDictionary *event = [[NSDictionary alloc] initWithObjectsAndKeys:
                           [self decodeAuthorizationStatus:[CLLocationManager authorizationStatus]], @"status",
                           nil];
    
    [self fireEvent:@"changeAuthorizationStatus" withObject:event];
}


- (void) locationManager:(CLLocationManager *)manager didStartMonitoringForRegion:(CLRegion *)region
{
    NSLog(@"[INFO] Did start monitoring region: %@", region.identifier);
    [self.locationManager requestStateForRegion:region];
}


-(void)locationManager:(CLLocationManager *)manager didDetermineState:(CLRegionState)state forRegion:(CLRegion *)region
{
    if (state == CLRegionStateInside)
    {
        NSLog(@"[INFO] State INSIDE region %@", region.identifier);
    }
    else if (state == CLRegionStateOutside)
    {
        NSLog(@"[INFO] State OUTSIDE region: %@", region.identifier);
    }
    else {
        NSLog(@"[INFO] State UNKNOWN region: %@", region.identifier);
    }
    
    NSMutableDictionary *event = [NSMutableDictionary dictionaryWithDictionary:[self detailsForBeaconRegion:(CLBeaconRegion *)region]];
    [event setObject:[self decodeRegionState:state] forKey:@"regionState"];
    
    [self fireEvent:@"determinedRegionState" withObject:event];

}

- (void)locationManager:(CLLocationManager *)manager didEnterRegion:(CLRegion *)region {
    
    NSLog(@"[INFO] Entered region %@", region.identifier);

    [self fireEvent:@"enteredRegion" withObject:[self detailsForBeaconRegion:(CLBeaconRegion *)region]];
    
}

-(void)locationManager:(CLLocationManager *)manager didExitRegion:(CLRegion *)region {

    NSLog(@"[INFO] exited region %@", region.identifier);

    [self fireEvent:@"exitedRegion" withObject:[self detailsForBeaconRegion:(CLBeaconRegion *)region]];
}



#pragma mark - Beacon ranging

- (CLBeaconRegion *)createBeaconRegionWithUUID:(NSString *)uuid major:(NSInteger)major minor:(NSInteger)minor identifier:(NSString *)identifier
{
    
    NSUUID *proximityUUID = [[NSUUID alloc] initWithUUIDString:uuid];
    CLBeaconRegion *region;
    
    if (major != -1 && minor != -1) {
        region = [[CLBeaconRegion alloc] initWithProximityUUID:proximityUUID major:major minor:minor identifier:identifier];
    }
    else if (major != -1) {
        region = [[CLBeaconRegion alloc] initWithProximityUUID:proximityUUID major:major identifier:identifier];
    }
    else {
        region = [[CLBeaconRegion alloc] initWithProximityUUID:proximityUUID identifier:identifier];
    }
    
    [proximityUUID release];
    
    region.notifyEntryStateOnDisplay = true;
    region.notifyOnEntry = true;
    region.notifyOnExit = true;
    
    return [region autorelease];
}

- (void)turnOnRangingWithRegion:(CLBeaconRegion *)region
{
    NSLog(@"[INFO] Turning on ranging for %@", region);
    
    if (![CLLocationManager isRangingAvailable]) {
        NSLog(@"[INFO] Couldn't turn on ranging: Ranging is not available.");
        return;
    }
    
    [self.locationManager startRangingBeaconsInRegion:region];
    
    NSLog(@"[INFO] Ranging turned on for region: %@.", region);
}


- (void)startRangingForBeacons:(id)args
{
    ENSURE_UI_THREAD_1_ARG(args);
    ENSURE_SINGLE_ARG(args, NSDictionary);
    
    
    [self turnOnRangingWithRegion:[self regionForArgs:args]];
}

- (void)stopRangingForBeacons:(id)args
{
    ENSURE_UI_THREAD_1_ARG(args);
    ENSURE_SINGLE_ARG(args, NSDictionary);
    
    
    [self stopRangingForRegion:[self regionForArgs:args]];
}

- (CLBeaconRegion *)regionForArgs:(id)args
{
    NSString *uuid = [TiUtils stringValue:[args objectForKey:@"uuid"]];
    NSInteger major = (NSUInteger)[TiUtils intValue:[args objectForKey:@"major"] def:-1];
    NSInteger minor = (NSUInteger)[TiUtils intValue:[args objectForKey:@"minor"] def:-1];
    
    NSString *identifier = [TiUtils stringValue:[args objectForKey:@"identifier"]];
    
    CLBeaconRegion *region = [self createBeaconRegionWithUUID:uuid major:major minor:minor identifier:identifier];
    
    NSString *notify = [TiUtils stringValue:[args objectForKey:@"notifyEntryStateOnDisplay"]];
    if (notify && [notify isEqualToString:@"YES"]) {
        region.notifyEntryStateOnDisplay = YES;
        NSLog(@"[INFO] notifyEntryStateOnDisplay ON");
    }
    
    return region;
}

- (void)stopRangingForAllBeacons:(id)args
{
    if (self.locationManager.rangedRegions.count == 0) {
        NSLog(@"[INFO] Didn't turn off ranging: Ranging already off.");
        return;
    }
    
    NSArray *regions = [[self locationManager].rangedRegions allObjects];
    for (CLBeaconRegion *region in regions) {
        [self.locationManager stopRangingBeaconsInRegion:region];
    }
    [regions release];
    
    NSLog(@"[INFO] Turned off ranging in ALL regions.");
}


- (void)stopRangingForRegion:(CLRegion *)region
{
    NSLog(@"[INFO] stopRangingForRegion %@", region);

    [self.locationManager stopRangingBeaconsInRegion:(CLBeaconRegion *)region];
    
    NSLog(@"[INFO] Turned off ranging for %@.", region.identifier);
}



#pragma mark - Beacon ranging delegate methods

- (void)enableAutoRanging:(id)args
{
    NSLog(@"[ERROR] Auto-ranging is deprecated in version 0.8");
}
- (void)disableAutoRanging:(id)args
{
    NSLog(@"[ERROR] Auto-ranging is deprecated in version 0.8");
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
        
        CLBeacon *previous = [beaconProximities objectForKey:identifier];
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

        [beaconProximities setObject:current forKey:identifier];
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
                             [NSString stringWithFormat:@"%ld", (long)beacon.rssi], @"rssi",
                             nil
                             ];
    
    return [details autorelease];
}
- (NSDictionary *)detailsForBeaconRegion:(CLBeaconRegion *)region
{
    
    NSMutableDictionary *details = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
                             region.identifier, @"identifier",
                             region.proximityUUID.UUIDString, @"uuid",
                             nil
                             ];

    if (region.major) {
        [details setObject:[NSString stringWithFormat:@"%@", region.major] forKey:@"major"];
    }
    if (region.minor) {
        [details setObject:[NSString stringWithFormat:@"%@", region.minor] forKey:@"minor"];
    }
    
    return details;
}

- (NSString *)decodeAuthorizationStatus:(int)authStatus
{
    switch (authStatus) {
        case kCLAuthorizationStatusAuthorized:
            return @"authorized";
            break;
        default:
            return @"unauthorized";
            break;
    }
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
- (NSString *)decodeRegionState:(int)state
{
    switch (state) {
        case CLRegionStateInside:
            return @"inside";
            break;
        case CLRegionStateOutside:
            return @"outside";
            break;
        case CLRegionStateUnknown:
        default:
            return @"unknown";
            break;
    }
    
}


#pragma mark - Beacon advertising

- (void)turnOnAdvertising
{
    if (peripheralManager.state != CBPeripheralManagerStatePoweredOn) {
        NSLog(@"[INFO] Peripheral manager is off.");
        return;
    }

    NSDictionary *beaconPeripheralData = [beaconRegion peripheralDataWithMeasuredPower:nil];
    [peripheralManager startAdvertising:beaconPeripheralData];
    
    NSLog(@"[INFO] Turning on advertising for region: %@.", beaconRegion);
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
    
    beaconRegion = [self createBeaconRegionWithUUID:uuid major:major minor:minor identifier:identifier];
    [beaconRegion retain];
    
    if (!peripheralManager) {
        peripheralManager = [[CBPeripheralManager alloc] initWithDelegate:self queue:nil options:nil];
    }
    
    [self turnOnAdvertising];
}

- (void)stopAdvertisingBeacon:(id)args
{
    
    if (peripheralManager) {
        
        if (peripheralManager.state == CBPeripheralManagerStatePoweredOn){
            
            [peripheralManager stopAdvertising];
            
            [beaconRegion release];
            
            NSLog(@"[INFO] Turned off advertising.");
        }else{
            NSLog(@"[INFO] peripheral manager state was off, no need to turn advertsing off");
        }
    }
}

#pragma mark - Beacon advertising delegate methods

- (void)peripheralManagerDidStartAdvertising:(CBPeripheralManager *)pManager error:(NSError *)error
{
    if (error) {
        NSLog(@"[INFO] Couldn't turn on advertising: %@", error);

        return;
    }
    
    if (pManager.isAdvertising) {
        NSLog(@"[INFO] Turned on advertising.");
        
        NSDictionary *status = [[NSDictionary alloc] initWithObjectsAndKeys: @"on", @"status", nil];

        [self fireEvent:@"advertisingStatus" withObject:status];
        [status autorelease];
    }
}

- (void)peripheralManagerDidUpdateState:(CBPeripheralManager *)pManager
{
    if (pManager.state != CBPeripheralManagerStatePoweredOn) {
        NSLog(@"[INFO] Peripheral manager is off.");
        return;
    }
    
    NSLog(@"[INFO] Peripheral manager is on.");

    [self turnOnAdvertising];
}


@end
