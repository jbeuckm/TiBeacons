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

@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, strong) CLBeaconRegion *beaconRegion;
@property (nonatomic, strong) CBPeripheralManager *peripheralManager;
@property (nonatomic, strong) NSArray *detectedBeacons;

@property NSUInteger major;
@property NSUInteger minor;

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
	// this method is called when the module is first loaded
	// you *must* call the superclass
	[super startup];
	
	NSLog(@"[INFO] %@ loaded",self);
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

-(id)example:(id)args
{
	// example method
	return @"hello world";
}

-(id)detectedBeacons
{
	// example property getter
	return self.detectedBeacons;
}

-(void)setExampleProp:(id)value
{
	// example property setter
}



#pragma mark - Beacon ranging
- (void)createBeaconRegionWithUUID:(NSString *)uuid andIdentifier:(NSString *)identifier
{
    if (self.beaconRegion)
        return;
    
    NSUUID *proximityUUID = [[NSUUID alloc] initWithUUIDString:uuid];
    self.beaconRegion = [[CLBeaconRegion alloc] initWithProximityUUID:proximityUUID identifier:identifier];
    
    self.beaconRegion.notifyEntryStateOnDisplay = true;
}

- (void)turnOnRangingWithUUID:(NSString *)uuid andIdentifier:(NSString *)identifier
{
    NSLog(@"[INFO] Turning on ranging...");
    
    if (![CLLocationManager isRangingAvailable]) {
        NSLog(@"[INFO] Couldn't turn on ranging: Ranging is not available.");
        return;
    }
    
    if (self.locationManager.rangedRegions.count > 0) {
        NSLog(@"[INFO] Didn't turn on ranging: Ranging already on.");
        return;
    }
    
    [self createBeaconRegionWithUUID:uuid andIdentifier:identifier];
    [self.locationManager startRangingBeaconsInRegion:self.beaconRegion];
    
    NSLog(@"[INFO] Ranging turned on for region: %@.", self.beaconRegion);
}


- (void)startRangingForBeacons:(id)args
{
    ENSURE_UI_THREAD_1_ARG(args);
    ENSURE_SINGLE_ARG(args, NSDictionary);
    
    NSString *uuid = [TiUtils stringValue:[args objectForKey:@"uuid"]];
    NSString *identifier = [TiUtils stringValue:[args objectForKey:@"identifier"]];
    
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.delegate = self;
    
    self.detectedBeacons = [NSArray array];
    
    [self turnOnRangingWithUUID:uuid andIdentifier:identifier];
}

- (void)stopRangingForBeacons:(id)args
{
    if (self.locationManager.rangedRegions.count == 0) {
        NSLog(@"[INFO] Didn't turn off ranging: Ranging already off.");
        return;
    }
    
    [self.locationManager stopRangingBeaconsInRegion:self.beaconRegion];
    
    self.detectedBeacons = [NSArray array];
    
    NSLog(@"[INFO] Turned off ranging.");
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
    } else {
        NSLog(@"[INFO] Found %lu %@.", (unsigned long)[filteredBeacons count],
              [filteredBeacons count] > 1 ? @"beacons" : @"beacon");

        NSString *count = [NSString stringWithFormat:@"%lu", (unsigned long)[filteredBeacons count]];

        NSMutableArray *eventBeacons = [[NSMutableArray alloc] init];
        for (id beacon in filteredBeacons) {
            // do something with object
            [eventBeacons addObject:[self detailsForBeacon:beacon]];
        }
        
        NSDictionary *event = [[NSDictionary alloc] initWithObjectsAndKeys:
                               count, @"count",
                               eventBeacons, @"beacons",
                               nil];
    
        [self fireEvent:@"beaconRanges" withObject:event];
        
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



#pragma mark - Beacon advertising
- (void)turnOnAdvertising
{
    if (self.peripheralManager.state != CBPeripheralManagerStatePoweredOn) {
        NSLog(@"[INFO] Peripheral manager is off.");
        return;
    }
    
    CLBeaconRegion *region = [[CLBeaconRegion alloc] initWithProximityUUID:self.beaconRegion.proximityUUID
                                                                     major:self.major
                                                                     minor:self.minor
                                                                identifier:self.beaconRegion.identifier];

    NSDictionary *beaconPeripheralData = [region peripheralDataWithMeasuredPower:nil];
    [self.peripheralManager startAdvertising:beaconPeripheralData];
    
    NSLog(@"[INFO] Turning on advertising for region: %@.", region);
}


- (void)startAdvertisingBeacon:(id)args
{
    ENSURE_UI_THREAD_1_ARG(args);
    ENSURE_SINGLE_ARG(args, NSDictionary);
    
    NSString *uuid = [TiUtils stringValue:[args objectForKey:@"uuid"]];
    NSString *identifier = [TiUtils stringValue:[args objectForKey:@"identifier"]];
    
    self.major = (NSUInteger)[TiUtils intValue:[args objectForKey:@"major"] def:1];
    self.minor = (NSUInteger)[TiUtils intValue:[args objectForKey:@"minor"] def:1];

    NSLog(@"[INFO] Turning on advertising...");
    
    [self createBeaconRegionWithUUID:uuid andIdentifier:identifier];
    
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

        [self fireEvent:@"advertisingStatus" withObject:[[NSDictionary alloc] initWithObjectsAndKeys: @"on", @"status", nil]];
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




- (NSDictionary *)detailsForBeacon:(CLBeacon *)beacon
{
    
    NSString *proximity;
    switch (beacon.proximity) {
        case CLProximityNear:
            proximity = @"near";
            break;
        case CLProximityImmediate:
            proximity = @"immediate";
            break;
        case CLProximityFar:
            proximity = @"far";
            break;
        case CLProximityUnknown:
        default:
            proximity = @"unknown";
            break;
    }
    
    return [[NSDictionary alloc] initWithObjectsAndKeys:
            [NSString stringWithFormat:@"%@", beacon.major], @"major",
            [NSString stringWithFormat:@"%@", beacon.minor], @"minor",
            proximity, @"proximity",
            [NSString stringWithFormat:@"%f", beacon.accuracy], @"accuracy",
            [NSString stringWithFormat:@"%d", beacon.rssi], @"rssi",
        nil
    ];
}


@end
