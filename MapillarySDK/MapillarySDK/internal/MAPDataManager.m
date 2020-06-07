//
//  MAPDataManager.m
//  MapillarySDK
//
//  Created by Anders Mårtensson on 2018-07-03.
//  Copyright © 2018 Mapillary. All rights reserved.
//

#import "MAPDataManager.h"
#import "MAPLocation.h"
#import "MAPSequence.h"
#import <PodAsset/PodAsset.h>
#import "MAPProcessedImage+CoreDataClass.h"

@implementation MAPDataManager

+ (MAPDataManager*)sharedManager
{
    static id sharedMyManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedMyManager = [[self alloc] init];
    });
    return sharedMyManager;
}

- (void)saveChanges
{
    [self saveContext];
}

#pragma mark - Coordinates

- (void)addLocation:(MAPLocation*)location sequence:(MAPSequence*)sequence
{
    NSManagedObjectContext* context = [MAPDataManager sharedManager].persistentContainer.viewContext;
    
    MAPCoordinate* coordinate = (MAPCoordinate*)[NSEntityDescription insertNewObjectForEntityForName:@"MAPCoordinate" inManagedObjectContext:context];
    
    coordinate.latitude = location.location.coordinate.latitude;
    coordinate.longitude = location.location.coordinate.longitude;
    coordinate.altitude = location.location.altitude;
    
    coordinate.speed = location.location.speed;
    
    coordinate.deviceRoll = location.deviceRoll.doubleValue;
    coordinate.deviceYaw = location.deviceYaw.doubleValue;
    coordinate.devicePitch = location.devicePitch.doubleValue;
    
    coordinate.deviceMotionX = location.deviceMotionX.doubleValue;
    coordinate.deviceMotionY = location.deviceMotionY.doubleValue;
    coordinate.deviceMotionZ = location.deviceMotionZ.doubleValue;
    
    coordinate.headingAccuracy = location.headingAccuracy.doubleValue;
    coordinate.trueHeading = location.trueHeading.doubleValue;
    coordinate.magneticHeading = location.magneticHeading.doubleValue;
    
    coordinate.timestamp = location.timestamp;
    
    coordinate.deviceMake = sequence.device.make;
    coordinate.deviceModel = sequence.device.model;
    coordinate.deviceUUID = sequence.device.UUID;
    
    coordinate.organizationKey = sequence.organizationKey;
    coordinate.isPrivate = sequence.isPrivate;

    /*@property (nonatomic) double angle;
    */
    
    [[MAPDataManager sharedManager] saveChanges];
}

- (void)getAllLocationsLimitedToDevice:(MAPDevice*)inputDevice result:(void(^)(NSArray* locations, MAPDevice* device, NSString* organizationKey, bool isPrivate))result
{
    [self getLocationsFrom:nil to:nil limitedToDevice:inputDevice result:^(NSArray *locations, MAPDevice *device, NSString *organizationKey, bool isPrivate) {
        
        result(locations, device, organizationKey, isPrivate);
    }];
}

- (void)getLocationsFrom:(NSDate*)from to:(NSDate*)to limitedToDevice:(MAPDevice*)inputDevice result:(void(^)(NSArray* locations, MAPDevice* device, NSString* organizationKey, bool isPrivate))result
{
    NSMutableArray* locations = [NSMutableArray array];
    
    NSManagedObjectContext* context = [MAPDataManager sharedManager].persistentContainer.viewContext;
    
    NSFetchRequest* fetch = [[NSFetchRequest alloc] initWithEntityName:@"MAPCoordinate"];
    fetch.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:YES]];
    
    if (from && to)
    {
        fetch.predicate =  [NSPredicate predicateWithFormat:@"timestamp >= %@ AND timestamp <= %@", from, to];
    }
    
    else if (from)
    {
        fetch.predicate =  [NSPredicate predicateWithFormat:@"timestamp >= %@", from];
    }
    
    else if (to)
    {
        fetch.predicate =  [NSPredicate predicateWithFormat:@"timestamp <= %@", to];
    }
    
    if (inputDevice)
    {
        NSPredicate* devicePredicate = nil;
        
        if (inputDevice.UUID)
        {
            devicePredicate =  [NSPredicate predicateWithFormat:@"deviceUUID == %@", inputDevice.UUID];
        }
        else if (inputDevice.make && inputDevice.model)
        {
            devicePredicate =  [NSPredicate predicateWithFormat:@"deviceMake == %@ AND deviceModel == %@", inputDevice.make, inputDevice.model];
        }
        
        if (fetch.predicate && devicePredicate)
        {
            fetch.predicate = [[NSCompoundPredicate alloc] initWithType:NSAndPredicateType subpredicates:@[fetch.predicate, devicePredicate]];
        }
        else if (devicePredicate)
        {
            fetch.predicate = devicePredicate;
        }
    }
    
    NSError* error = nil;
    
    NSArray* fetchResult = [context executeFetchRequest:fetch error:&error];
    
    if (error)
    {
        NSLog(@"ERROR getting coordinates");
    }
    else
    {
        for (MAPCoordinate* c in fetchResult)
        {
            
            CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake(c.latitude, c.longitude);
            CLLocationDistance altitude = c.altitude;
            CLLocationAccuracy horizontalAccuracy = c.headingAccuracy;
            CLLocationAccuracy verticalAccuracy = 0;
            CLLocationDirection course = c.trueHeading;
            CLLocationSpeed speed = c.speed;
            NSDate* timestamp = c.timestamp;
            
            MAPLocation* location = [[MAPLocation alloc] init];
            location.location = [[CLLocation alloc] initWithCoordinate:coordinate
                                                              altitude:altitude
                                                    horizontalAccuracy:horizontalAccuracy
                                                      verticalAccuracy:verticalAccuracy
                                                                course:course
                                                                 speed:speed
                                                             timestamp:timestamp];
            
            location.timestamp = c.timestamp;
            
            location.deviceYaw = [NSNumber numberWithDouble:c.deviceYaw];
            location.deviceRoll = [NSNumber numberWithDouble:c.deviceRoll];
            location.devicePitch = [NSNumber numberWithDouble:c.devicePitch];
            
            location.deviceMotionX = [NSNumber numberWithDouble:c.deviceMotionX];
            location.deviceMotionY = [NSNumber numberWithDouble:c.deviceMotionY];
            location.deviceMotionZ = [NSNumber numberWithDouble:c.deviceMotionZ];
            
            [locations addObject:location];
        }
    }
    
    if (fetchResult.count > 0)
    {
        MAPCoordinate* middle = fetchResult[fetchResult.count/2];
        MAPDevice* device = [[MAPDevice alloc] initWithMake:middle.deviceMake andModel:middle.deviceModel andUUID:middle.deviceUUID isExternal:YES];
        
        result(locations, device, middle.organizationKey, middle.isPrivate);
    }
    else
    {
        result(locations, nil, nil, NO);
    }
}

- (void)deleteCoordinatesOlderThan:(NSDate*)date
{
    NSManagedObjectContext* context = [MAPDataManager sharedManager].persistentContainer.viewContext;
    
    NSFetchRequest* fetch = [[NSFetchRequest alloc] initWithEntityName:@"MAPCoordinate"];
    fetch.predicate =  [NSPredicate predicateWithFormat:@"timestamp <= %@", date];
    
    NSBatchDeleteRequest* delete = [[NSBatchDeleteRequest alloc] initWithFetchRequest:fetch];
    
    NSError* error = nil;
    
    [context executeRequest:delete error:&error];
    
    if (error)
    {
        NSLog(@"ERROR deleting coordinates");
    }
}

#pragma mark - Images

- (void)setImageAsProcessed:(MAPImage*)image
{
    NSManagedObjectContext* context = [MAPDataManager sharedManager].persistentContainer.viewContext;
    
    MAPProcessedImage* processed = (MAPProcessedImage*)[NSEntityDescription insertNewObjectForEntityForName:@"MAPProcessedImage" inManagedObjectContext:context];
    
    processed.date = [NSDate date];
    processed.filename = image.imagePath.lastPathComponent;
    
    [[MAPDataManager sharedManager] saveChanges];
}

- (void)removeImageInformation:(MAPImage*)image
{
    NSManagedObjectContext* context = [MAPDataManager sharedManager].persistentContainer.viewContext;
    
    NSFetchRequest* fetch = [[NSFetchRequest alloc] initWithEntityName:@"MAPProcessedImage"];
    fetch.predicate =  [NSPredicate predicateWithFormat:@"filename == %@", image.imagePath.lastPathComponent];
    
    NSBatchDeleteRequest* delete = [[NSBatchDeleteRequest alloc] initWithFetchRequest:fetch];
    
    NSError* error = nil;
    
    [context executeRequest:delete error:&error];
    
    if (error)
    {
        NSLog(@"ERROR deleting coordinates");
    }
}

- (BOOL)isImageProcessed:(MAPImage*)image
{
    NSManagedObjectContext* context = [MAPDataManager sharedManager].persistentContainer.viewContext;
    
    NSFetchRequest* fetch = [[NSFetchRequest alloc] initWithEntityName:@"MAPProcessedImage"];
    fetch.predicate =  [NSPredicate predicateWithFormat:@"filename == %@", image.imagePath.lastPathComponent];
    
    NSError* error = nil;
    
    NSUInteger count = [context countForFetchRequest:fetch error:&error];
    if (error)
    {
        NSLog(@"ERROR getting processed image");
    }
    else
    {
        return count > 0;
    }
    
    return NO;
}

- (NSDictionary*)getProcessedImages
{
    NSManagedObjectContext* context = [MAPDataManager sharedManager].persistentContainer.viewContext;
    
    NSFetchRequest* fetch = [[NSFetchRequest alloc] initWithEntityName:@"MAPProcessedImage"];
    
    NSError* error = nil;
    
    NSArray* fetchResult = [context executeFetchRequest:fetch error:&error];
    
    if (error)
    {
        NSLog(@"ERROR getting processed images");
    }
    else if (fetchResult.count > 0)
    {
        NSMutableArray* keys = [NSMutableArray array];
        
        for (MAPProcessedImage* p in fetchResult)
        {
            [keys addObject:p.filename];
        }
        
        return [NSDictionary dictionaryWithObjects:fetchResult forKeys:keys];
    }
    
    return [NSDictionary dictionary];
}

- (void)deleteImagesOlderThan:(NSDate*)date
{
    NSManagedObjectContext* context = [MAPDataManager sharedManager].persistentContainer.viewContext;
    
    NSFetchRequest* fetch = [[NSFetchRequest alloc] initWithEntityName:@"MAPProcessedImage"];
    fetch.predicate =  [NSPredicate predicateWithFormat:@"date <= %@", date];
    
    NSBatchDeleteRequest* delete = [[NSBatchDeleteRequest alloc] initWithFetchRequest:fetch];
    
    NSError* error = nil;
    
    [context executeRequest:delete error:&error];
    
    if (error)
    {
        NSLog(@"ERROR deleting coordinates");
    }
}

#pragma mark - Upload sessions

- (void)addUploadSessionKey:(NSString*)uploadSessionKey uploadFields:(NSDictionary*)uploadFields uploadKeyPrefix:(NSString*)uploadKeyPrefix uploadUrl:(NSURL*)uploadUrl forSequence:(NSString*)sequenceKey
{
    NSManagedObjectContext* context = [MAPDataManager sharedManager].persistentContainer.viewContext;
    
    MAPUploadSession* uploadSession = (MAPUploadSession*)[NSEntityDescription insertNewObjectForEntityForName:@"MAPUploadSession" inManagedObjectContext:context];
    
    uploadSession.date = [NSDate date];
    uploadSession.sequenceKey = sequenceKey;
    uploadSession.uploadFields = [NSJSONSerialization dataWithJSONObject:uploadFields options:0 error:nil];
    uploadSession.uploadKeyPrefix = uploadKeyPrefix;
    uploadSession.uploadSessionKey = uploadSessionKey;
    uploadSession.uploadUrl = uploadUrl.absoluteString;
    
    [[MAPDataManager sharedManager] saveChanges];
}

- (void)removeUploadSession:(NSString*)uploadSessionKey
{
    NSManagedObjectContext* context = [MAPDataManager sharedManager].persistentContainer.viewContext;
    
    NSFetchRequest* fetch = [[NSFetchRequest alloc] initWithEntityName:@"MAPUploadSession"];
    fetch.predicate =  [NSPredicate predicateWithFormat:@"uploadSessionKey == %@", uploadSessionKey];
    
    NSBatchDeleteRequest* delete = [[NSBatchDeleteRequest alloc] initWithFetchRequest:fetch];
    
    NSError* error = nil;
    
    [context executeRequest:delete error:&error];
    
    if (error)
    {
        NSLog(@"ERROR deleting upload session");
    }
}

- (void)removeUploadSessionForSequenceKey:(NSString*)sequenceKey
{
    NSManagedObjectContext* context = [MAPDataManager sharedManager].persistentContainer.viewContext;
    
    NSFetchRequest* fetch = [[NSFetchRequest alloc] initWithEntityName:@"MAPUploadSession"];
    fetch.predicate =  [NSPredicate predicateWithFormat:@"sequenceKey == %@", sequenceKey];
    
    NSBatchDeleteRequest* delete = [[NSBatchDeleteRequest alloc] initWithFetchRequest:fetch];
    
    NSError* error = nil;
    
    [context executeRequest:delete error:&error];
    
    if (error)
    {
        NSLog(@"ERROR deleting upload session");
    }
}

- (NSArray*)getUploadSessions
{
    NSManagedObjectContext* context = [MAPDataManager sharedManager].persistentContainer.viewContext;
    
    NSFetchRequest* fetch = [[NSFetchRequest alloc] initWithEntityName:@"MAPUploadSession"];
    
    NSError* error = nil;
    
    NSArray* fetchResult = [context executeFetchRequest:fetch error:&error];
    
    if (error)
    {
        NSLog(@"ERROR getting upload sessions");
    }
    else if (fetchResult.count > 0)
    {
        return fetchResult;
    }
    
    return [NSArray array];
}

- (MAPUploadSession*)getUploadSessionForSequenceKey:(NSString*)sequenceKey
{
    MAPUploadSession* uploadSession = nil;
    
    NSManagedObjectContext* context = [MAPDataManager sharedManager].persistentContainer.viewContext;
    NSFetchRequest* fetch = [[NSFetchRequest alloc] initWithEntityName:@"MAPUploadSession"];
    fetch.predicate =  [NSPredicate predicateWithFormat:@"sequenceKey == %@", sequenceKey];
    
    NSError* error = nil;
    
    NSArray* fetchResult = [context executeFetchRequest:fetch error:&error];
    
    if (error)
    {
        NSLog(@"ERROR getting upload session");
    }
    else if (fetchResult.count > 0)
    {
        uploadSession = fetchResult[0];
    }
    
    return uploadSession;
}

#pragma mark - Core Data stack

@synthesize persistentContainer = _persistentContainer;

- (NSPersistentContainer *)persistentContainer
{
    @synchronized (self)
    {
        if (_persistentContainer == nil)
        {
            NSBundle* podBundle = [PodAsset bundleForPod:@"MapillarySDK"];
            
            if (podBundle == nil)
            {
                podBundle = [NSBundle bundleForClass:[self class]];
            }
            
            NSURL* url = [podBundle URLForResource:@"MAPDataModel" withExtension:@"momd"];
            NSManagedObjectModel* managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:url];
            
            _persistentContainer = [[NSPersistentContainer alloc] initWithName:@"MAPDataModel" managedObjectModel:managedObjectModel];
                        
            [_persistentContainer loadPersistentStoresWithCompletionHandler:^(NSPersistentStoreDescription *storeDescription, NSError *error)
            {
                if (error != nil)
                {
                    /*
                     Typical reasons for an error here include:
                     * The parent directory does not exist, cannot be created, or disallows writing.
                     * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                     * The device is out of space.
                     * The store could not be migrated to the current model version.
                     Check the error message to determine what the actual problem was.
                     */
                    NSLog(@"Unresolved error %@, %@", error, error.userInfo);
                    
                    // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                    abort();
                }
            }];
        }
    }
    
    return _persistentContainer;
}

#pragma mark - Core Data Saving support

- (void)saveContext
{
    NSManagedObjectContext* context = [MAPDataManager sharedManager].persistentContainer.viewContext;
    
    [context performBlockAndWait:^{
        
        NSError *error = nil;
        
        if ([context hasChanges] && ![context save:&error])
        {
            NSLog(@"Unresolved error %@, %@", error, error.userInfo);
            
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            abort();
        }
        
    }];        
}


@end
