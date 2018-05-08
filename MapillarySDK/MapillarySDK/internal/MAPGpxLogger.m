//
//  MAPGpxLogger.m
//  MapillarySDK
//
//  Created by Anders Mårtensson on 2017-03-21.
//  Copyright © 2017 Mapillary. All rights reserved.
//

#import "MAPGpxLogger.h"
#import "MAPInternalUtils.h"
#import "MAPLoginManager.h"
#import "MAPDefines.h"

static NSString* kQueueOperationsChanged = @"kQueueOperationsChanged";

@interface MAPGpxOperation : NSOperation

@property (nonatomic) NSString* path;
@property (nonatomic) MAPLocation* location;
@property (nonatomic) NSString* time;
@property (nonatomic) int imageOrientation;

@end

NSString* footer;
unsigned long long footerLength;

@implementation MAPGpxOperation

- (void)main
{
    @autoreleasepool
    {
        NSFileHandle* file = [NSFileHandle fileHandleForWritingAtPath:self.path];
        NSMutableString* locationString = [[NSMutableString alloc] init];
        
        // Add location
        [locationString appendFormat:@"\t\t\t<trkpt lat=\"%f\" lon=\"%f\">\n", self.location.location.coordinate.latitude, self.location.location.coordinate.longitude];
        
        // Add eleveation
        [locationString appendFormat:@"\t\t\t\t<ele>%f</ele>\n", self.location.location.altitude];
        
        // Add time
        [locationString appendFormat:@"\t\t\t\t<time>%@</time>\n", self.time];
        
        // Add extensions
        NSMutableString* extensionsString = [[NSMutableString alloc] init];
        
        if (self.location.deviceMotionX != nil && self.location.deviceMotionY != nil && self.location.deviceMotionZ != nil)
        {
            [extensionsString appendFormat:@"\t\t\t\t\t<mapillary:%@>\n", kMAPAccelerometerVector];
            [extensionsString appendFormat:@"\t\t\t\t\t\t<x>%f</x>\n", -self.location.deviceMotionX.floatValue];
            [extensionsString appendFormat:@"\t\t\t\t\t\t<y>%f</y>\n", self.location.deviceMotionY.floatValue];
            [extensionsString appendFormat:@"\t\t\t\t\t\t<z>%f</z>\n", self.location.deviceMotionZ.floatValue];
            [extensionsString appendFormat:@"\t\t\t\t\t</mapillary:%@>\n", kMAPAccelerometerVector];
        }
        
        [extensionsString appendFormat:@"\t\t\t\t\t<mapillary:%@>%f</mapillary:%@>\n", kMAPGPSAccuracyMeters, self.location.location.horizontalAccuracy, kMAPGPSAccuracyMeters];
        
        float atanAngle = atan2(self.location.deviceMotionY.doubleValue, self.location.deviceMotionX.doubleValue);
        [extensionsString appendFormat:@"\t\t\t\t\t<mapillary:%@>%f</mapillary:%@>\n", kMAPAtanAngle, atanAngle, kMAPAtanAngle];
        
        if (self.location.trueHeading != nil)
        {
            [extensionsString appendFormat:@"\t\t\t\t\t<mapillary:%@>\n", kMAPCompassHeading];
            [extensionsString appendFormat:@"\t\t\t\t\t\t<mapillary:%@>%f</mapillary:%@>\n", kMAPTrueHeading, self.location.trueHeading.floatValue, kMAPTrueHeading];
            [extensionsString appendFormat:@"\t\t\t\t\t\t<mapillary:%@>%f</mapillary:%@>\n", kMAPMagneticHeading, self.location.magneticHeading.floatValue, kMAPMagneticHeading];
            [extensionsString appendFormat:@"\t\t\t\t\t\t<mapillary:%@>%f</mapillary:%@>\n", kMAPAccuracyDegrees, self.location.headingAccuracy.floatValue, kMAPAccuracyDegrees];
            [extensionsString appendFormat:@"\t\t\t\t\t</mapillary:%@>\n", kMAPCompassHeading];
        }
        
        if (self.location.devicePitch != nil && self.location.deviceRoll != nil && self.location.deviceYaw != nil)
        {
            [extensionsString appendFormat:@"\t\t\t\t\t<mapillary:%@>\n", kMAPDeviceAngle];
            [extensionsString appendFormat:@"\t\t\t\t\t\t<pitch>%f</pitch>\n", self.location.devicePitch.floatValue];
            [extensionsString appendFormat:@"\t\t\t\t\t\t<roll>%f</roll>\n", self.location.deviceRoll.floatValue];
            [extensionsString appendFormat:@"\t\t\t\t\t\t<yaw>%f</yaw>\n", self.location.deviceYaw.floatValue];
            [extensionsString appendFormat:@"\t\t\t\t\t</mapillary:%@>\n", kMAPDeviceAngle];
        }
        
        [extensionsString appendFormat:@"\t\t\t\t\t<mapillary:%@>%f</mapillary:%@>\n", kMAPGPSSpeed, self.location.location.speed, kMAPGPSSpeed];
        
        [extensionsString appendFormat:@"\t\t\t\t\t<mapillary:%@>%d</mapillary:%@>\n", kMAPOrientation, self.imageOrientation, kMAPOrientation];
        
        [locationString appendFormat:@"\t\t\t\t<extensions>\n%@\t\t\t\t</extensions>\n", extensionsString];
        
        // End track point
        [locationString appendString:@"\t\t\t</trkpt>\n"];
        
        // Append footer
        [locationString appendString:footer];
        
        // Append to end of file - footer length
        NSData* locationData = [locationString dataUsingEncoding:NSUTF8StringEncoding];
        
        
        NSDictionary* attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:self.path error:nil];
        
        unsigned long long fileLength = [attributes fileSize];
        
        [file seekToFileOffset:fileLength-footerLength];
        [file writeData:locationData];
        [file closeFile];
    }
}

@end

@interface MAPGpxLogger()

@property (nonatomic) NSOperationQueue* operationQueue;
@property (nonatomic) NSString* path;
@property (nonatomic) NSDateFormatter* dateFormatter;
@property (nonatomic) MAPSequence* sequence;

@end

@implementation MAPGpxLogger

- (id)initWithFile:(NSString*)path andSequence:(MAPSequence*)sequence
{
    self = [super init];
    
    if (self)
    {
        self.path = path;
        self.sequence = sequence;
        
        self.dateFormatter = [MAPInternalUtils defaultDateFormatter];
        self.dateFormatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ss.SSS'Z'";
        
        self.operationQueue = [[NSOperationQueue alloc] init];
        self.operationQueue.maxConcurrentOperationCount = 1;
        
        [self.operationQueue addObserver:self forKeyPath:@"operations" options:0 context:&kQueueOperationsChanged];
        
        if (![[NSFileManager defaultManager] fileExistsAtPath:path])
        {
            NSString* versionString = [MAPInternalUtils appVersion];
            NSString* dateString = [self.dateFormatter stringFromDate:sequence.sequenceDate];
            NSString* authorString = [[MAPLoginManager currentUser] userName];
            
            NSMutableString* extensionsString = [[NSMutableString alloc] init];
            
            [extensionsString appendFormat:@"\t\t<mapillary:%@>mapillary_ios</mapillary:%@>\n", kMAPAppNameString, kMAPAppNameString];
            [extensionsString appendFormat:@"\t\t<mapillary:%@>%@</mapillary:%@>\n", kMAPDeviceMake, sequence.device.make, kMAPDeviceMake];
            [extensionsString appendFormat:@"\t\t<mapillary:%@>%@</mapillary:%@>\n", kMAPDeviceModel, sequence.device.model, kMAPDeviceModel];
            [extensionsString appendFormat:@"\t\t<mapillary:%@>%@</mapillary:%@>\n", kMAPDeviceUUID, sequence.device.UUID, kMAPDeviceUUID];
            [extensionsString appendFormat:@"\t\t<mapillary:%@>%f</mapillary:%@>\n", kMAPDirectionOffset, sequence.directionOffset.floatValue, kMAPDirectionOffset];
            [extensionsString appendFormat:@"\t\t<mapillary:%@>%@</mapillary:%@>\n", kMAPLocalTimeZone, [[NSTimeZone systemTimeZone] description], kMAPLocalTimeZone];
            
            if (sequence.organizationKey)
            {
                [extensionsString appendFormat:@"\t\t<mapillary:%@>%@</mapillary:%@>\n", kMAPOrganizationKey, sequence.organizationKey, kMAPOrganizationKey];
                [extensionsString appendFormat:@"\t\t<mapillary:%@>%@</mapillary:%@>\n", kMAPPrivate, sequence.private ? @"true" : @"false", kMAPPrivate];
            }
            
            if (sequence.rigSequenceUUID && sequence.rigUUID)
            {
                [extensionsString appendFormat:@"\t\t<mapillary:%@>%@</mapillary:%@>\n", kMAPRigSequenceUUID, sequence.rigSequenceUUID, kMAPRigSequenceUUID];
                [extensionsString appendFormat:@"\t\t<mapillary:%@>%@</mapillary:%@>\n", kMAPRigUUID, sequence.rigUUID, kMAPRigUUID];
            }
            
            [extensionsString appendFormat:@"\t\t<mapillary:%@>%@</mapillary:%@>\n", kMAPSettingsUserKey, [[MAPLoginManager currentUser] userKey], kMAPSettingsUserKey];
            [extensionsString appendFormat:@"\t\t<mapillary:%@>%@</mapillary:%@>\n", kMAPSequenceUUID, sequence.sequenceKey, kMAPSequenceUUID];
            [extensionsString appendFormat:@"\t\t<mapillary:%@>%f</mapillary:%@>\n", kMAPTimeOffset, sequence.timeOffset.floatValue, kMAPTimeOffset];
            [extensionsString appendFormat:@"\t\t<mapillary:%@>%@</mapillary:%@>\n", kMAPVersionString, versionString, kMAPVersionString];
            
            
            NSMutableString* header = [[NSMutableString alloc] init];
            [header appendFormat:@"<?xml version=\"1.0\" encoding=\"UTF-8\" ?>\n"];
            [header appendFormat:@"<gpx version=\"1.1\" creator=\"Mapillary iOS %@\" xmlns:mapillary=\"http://www.mapillary.com\" xmlns=\"http://www.topografix.com/GPX/1/1\">\n", versionString];
            [header appendFormat:@"\t<metadata>\n"];
            [header appendFormat:@"\t\t<author>\n\t\t\t<name>%@</name>\n\t\t</author>\n", authorString];
            [header appendFormat:@"\t\t<link href=\"https://www.mapillary.com/app/user/%@\"/>\n", authorString];
            [header appendFormat:@"\t\t<time>%@</time>\n", dateString];
            [header appendFormat:@"\t</metadata>\n"];
            [header appendFormat:@"\t<extensions>\n%@\t</extensions>\n", extensionsString];
            [header appendFormat:@"\t<trk>\n"];
            [header appendFormat:@"\t\t<src>Logged by %@ using Mapillary</src>\n", authorString];
            [header appendFormat:@"\t\t<trkseg>\n"];
            footer = [NSString stringWithFormat:@"\t\t</trkseg>\n\t</trk>\n</gpx>"];
            
            [header appendString:footer];
            
            NSData* data = [header dataUsingEncoding:NSUTF8StringEncoding];
            [[NSFileManager defaultManager] createFileAtPath:path contents:data attributes:nil];
            
            NSData* footerData = [footer dataUsingEncoding:NSUTF8StringEncoding];
            footerLength = footerData.length;
        }
    }
    
    return self;
}

- (void)dealloc
{
    [self.operationQueue removeObserver:self forKeyPath:@"operations"];
}

- (void)addLocation:(MAPLocation*)location
{
    self.busy = YES;
    
    MAPGpxOperation* op = [[MAPGpxOperation alloc] init];
    op.path = self.path;
    op.location = location;
    op.imageOrientation = self.sequence.imageOrientation.intValue;
    
    if (location.timestamp)
    {
        op.time = [self.dateFormatter stringFromDate:location.timestamp];
    }
    else
    {
        op.time = [self.dateFormatter stringFromDate:[NSDate date]];
    }
    
    [self.operationQueue addOperation:op];
    
    //NSLog(@"%lu", (unsigned long)self.operationQueue.operationCount);
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (object == self.operationQueue && [keyPath isEqualToString:@"operations"] && context == &kQueueOperationsChanged)
    {
        //NSLog(@"%lu", (unsigned long)self.operationQueue.operationCount);
        if ([self.operationQueue.operations count] == 0)
        {
            self.busy = NO;
        }
    }
    else
    {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

@end

