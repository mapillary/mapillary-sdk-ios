//
//  MAPGpxParser.m
//  MapillarySDK
//
//  Created by Anders Mårtensson on 2017-09-07.
//  Copyright © 2017 Mapillary. All rights reserved.
//

#import "MAPGpxParser.h"
#import "MAPLocation.h"
#import "MAPInternalUtils.h"
#import "MAPDefines.h"

@interface MAPGpxParser()

@property NSXMLParser* xmlParser;
@property NSMutableArray* locations;
@property NSMutableDictionary* currentTrackPoint;
@property NSMutableString* currentElementValue;
@property NSDateFormatter* dateFormatter;
@property BOOL parsingMeta;
@property BOOL quickParse;

@property NSString* deviceMake;
@property NSString* deviceModel;
@property NSString* deviceUUID;
@property NSNumber* directionOffset;
@property NSString* localTimeZone;
@property NSString* organizationKey;
@property NSNumber* private;
@property NSString* rigSequenceUUID;
@property NSString* rigUUID;
@property NSString* sequenceUUID;
@property NSNumber* timeOffset;
@property NSDate* sequenceDate;
@property NSMutableDictionary* accelerometerVector;
@property NSMutableDictionary* deviceAngle;
@property NSMutableDictionary* compassHeading;

@property (nonatomic, copy) void (^doneCallback)(NSDictionary* dict);

@end

@implementation MAPGpxParser


- (id)initWithPath:(NSString*)path
{
    self = [super init];
    if (self)
    {
        self.dateFormatter = [MAPInternalUtils defaultDateFormatter];
        self.dateFormatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ss.SSS'Z'";
        
        NSData* data = [NSData dataWithContentsOfFile:path];
        self.xmlParser = [[NSXMLParser alloc] initWithData:data];
        self.xmlParser.delegate = self;
        
        self.locations = [NSMutableArray array];
        self.parsingMeta = NO;
        self.quickParse = NO;
        
        // Default values
        if ([[NSFileManager defaultManager] fileExistsAtPath:path])
        {
            self.localTimeZone = nil;
            self.organizationKey = nil;
            self.private = @NO;
            self.sequenceUUID = nil;
            self.timeOffset = nil;
            self.directionOffset = nil;
            self.sequenceDate = nil;
            self.rigUUID = nil;
            self.rigSequenceUUID = nil;
        }
        else
        {
            self.localTimeZone = [[NSTimeZone localTimeZone] description];
            self.organizationKey = nil;
            self.private = @NO;
            self.sequenceUUID = [[NSUUID UUID] UUIDString];
            self.timeOffset = nil;
            self.directionOffset = nil;
            self.sequenceDate = [NSDate date];
            self.rigUUID = [[NSUUID UUID] UUIDString];
            self.rigSequenceUUID = [[NSUUID UUID] UUIDString];
        }
        
        MAPDevice* defaultDevice = [MAPDevice thisDevice];
        self.deviceMake = defaultDevice.make;
        self.deviceModel = defaultDevice.model;
        self.deviceUUID = defaultDevice.UUID;
    }
    return self;
}

- (void)dealloc
{
    self.dateFormatter = nil;
}

- (void)parse:(void(^)(NSDictionary* dict))done
{
    self.doneCallback = done;
    [self.xmlParser parse];
}

- (void)quickParse:(void(^)(NSDictionary* dict))done
{
    self.quickParse = YES;
    self.doneCallback = done;
    [self.xmlParser parse];
}

- (NSString*)stringForKey:(NSString*)key
{
    return [NSString stringWithFormat:@"mapillary:%@", key];
}

#pragma mark - NSXMLParserDelegate

- (void)parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)parseError
{
    [self parserDidEndDocument:parser];
}

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict
{
    self.currentElementValue = [[NSMutableString alloc] init];
    
    if ([elementName isEqualToString:@"metadata"])
    {
        self.parsingMeta = YES;
    }
    
    // Skip GPS track if we are doing a quick parse
    if (!self.quickParse)
    {
        if ([elementName isEqualToString:@"trkpt"])
        {
            self.currentTrackPoint = [NSMutableDictionary dictionaryWithDictionary:attributeDict];
        }
        else if ([elementName isEqualToString:[self stringForKey:kMAPAccelerometerVector]])
        {
            self.accelerometerVector = [NSMutableDictionary dictionary];
        }
        else if ([elementName isEqualToString:[self stringForKey:kMAPDeviceAngle]])
        {
            self.deviceAngle = [NSMutableDictionary dictionary];
        }
        else if ([elementName isEqualToString:[self stringForKey:kMAPCompassHeading]])
        {
            self.compassHeading = [NSMutableDictionary dictionary];
        }
    }
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string
{
    [self.currentElementValue appendString:string];
    //NSLog(@"%@", string);
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName
{
    NSString* strippedValue = [self.currentElementValue stringByTrimmingCharactersInSet:[NSCharacterSet controlCharacterSet]];
    
    // Meta
    
    if (self.parsingMeta && [elementName isEqualToString:@"time"])
    {
        self.parsingMeta = NO;
        self.sequenceDate = [self.dateFormatter dateFromString:strippedValue];
    }
    
    else if ([elementName isEqualToString:[self stringForKey:kMAPLocalTimeZone]])
    {
        self.localTimeZone = strippedValue;
    }
    
    else if ([elementName isEqualToString:[self stringForKey:kMAPOrganizationKey]])
    {
        self.organizationKey = strippedValue;
    }
              
    else if ([elementName isEqualToString:[self stringForKey:kMAPPrivate]])
    {
        self.private = [NSNumber numberWithBool:strippedValue.boolValue];
    }
    
    else if ([elementName isEqualToString:[self stringForKey:kMAPSequenceUUID]])
    {
        self.sequenceUUID = strippedValue;
    }
    
    else if ([elementName isEqualToString:[self stringForKey:kMAPRigSequenceUUID]])
    {
        self.rigSequenceUUID = strippedValue;
    }
    
    else if ([elementName isEqualToString:[self stringForKey:kMAPRigUUID]])
    {
        self.rigUUID = strippedValue;
    }
    
    else if ([elementName isEqualToString:[self stringForKey:kMAPTimeOffset]])
    {
        NSNumberFormatter* f = [[NSNumberFormatter alloc] init];
        f.numberStyle = NSNumberFormatterDecimalStyle;
        f.locale = [NSLocale systemLocale];
        self.timeOffset = [f numberFromString:strippedValue];
    }
    
    else if ([elementName isEqualToString:[self stringForKey:kMAPDirectionOffset]])
    {
        NSNumberFormatter* f = [[NSNumberFormatter alloc] init];
        f.numberStyle = NSNumberFormatterDecimalStyle;
        f.locale = [NSLocale systemLocale];
        self.directionOffset = [f numberFromString:strippedValue];
    }
    
    else if ([elementName isEqualToString:[self stringForKey:kMAPDeviceUUID]])
    {
        self.deviceUUID = strippedValue;
    }
    
    else if ([elementName isEqualToString:[self stringForKey:kMAPDeviceMake]])
    {
        self.deviceMake = strippedValue;
    }
    
    else if ([elementName isEqualToString:[self stringForKey:kMAPDeviceModel]])
    {
        self.deviceModel = strippedValue;
    }
    
    // GPS track points
    else if (self.currentTrackPoint)
    {
        if ([elementName isEqualToString:@"trkpt"])
        {
            CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake([self.currentTrackPoint[@"lat"] doubleValue], [self.currentTrackPoint[@"lon"] doubleValue]);
            CLLocationDistance altitude = [self.currentTrackPoint[@"ele"] doubleValue];
            
            
            CLLocationAccuracy horizontalAccuracy = [self.currentTrackPoint[kMAPGPSAccuracyMeters] doubleValue];
            CLLocationAccuracy verticalAccuracy = 0;
            CLLocationDirection course = [self.currentTrackPoint[kMAPCompassHeading][kMAPTrueHeading] doubleValue];
            CLLocationSpeed speed = [self.currentTrackPoint[kMAPGPSSpeed] doubleValue];
            NSDate* timestamp = [self.dateFormatter dateFromString:self.currentTrackPoint[@"time"]];
            
            MAPLocation* location = [[MAPLocation alloc] init];
            location.location = [[CLLocation alloc] initWithCoordinate:coordinate
                                                              altitude:altitude
                                                    horizontalAccuracy:horizontalAccuracy
                                                      verticalAccuracy:verticalAccuracy
                                                                course:course
                                                                 speed:speed
                                                             timestamp:timestamp];
            
            location.timestamp = timestamp;
            
            if (self.currentTrackPoint[kMAPAccelerometerVector] != nil)
            {
                location.deviceMotionX = self.currentTrackPoint[kMAPAccelerometerVector][@"x"];
                location.deviceMotionY = self.currentTrackPoint[kMAPAccelerometerVector][@"y"];
                location.deviceMotionZ = self.currentTrackPoint[kMAPAccelerometerVector][@"z"];
            }
            
            if (self.currentTrackPoint[kMAPDeviceAngle] != nil)
            {
                location.devicePitch = self.currentTrackPoint[kMAPDeviceAngle][@"pitch"];
                location.deviceRoll = self.currentTrackPoint[kMAPDeviceAngle][@"roll"];
                location.deviceYaw = self.currentTrackPoint[kMAPDeviceAngle][@"yaw"];
            }
            
            if (self.currentTrackPoint[kMAPCompassHeading] != nil)
            {
                location.headingAccuracy = self.currentTrackPoint[kMAPCompassHeading][kMAPAccuracyDegrees];
                location.magneticHeading = self.currentTrackPoint[kMAPCompassHeading][kMAPMagneticHeading];
                location.trueHeading = self.currentTrackPoint[kMAPCompassHeading][kMAPTrueHeading];
            }
            
            [self.locations addObject:location];
        }
        else if (![elementName isEqualToString:@"extensions"])
        {
            if ([elementName containsString:@"mapillary:"])
            {
                elementName = [elementName stringByReplacingOccurrencesOfString:@"mapillary:" withString:@""];
            }
            
            NSString* trimmedValue = [self.currentElementValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            
            // Finished parsing kMAPAccelerometerVector
            if ([elementName isEqualToString:kMAPAccelerometerVector])
            {
                [self.currentTrackPoint setObject:self.accelerometerVector forKey:elementName];
                self.accelerometerVector = nil;
            }
            
            // Finished parsing kMAPDeviceAngle
            else if ([elementName isEqualToString:kMAPDeviceAngle])
            {
                [self.currentTrackPoint setObject:self.deviceAngle forKey:elementName];
                self.deviceAngle = nil;
            }
            
            // Finished parsing kMAPCompassHeading
            else if ([elementName isEqualToString:kMAPCompassHeading])
            {
                [self.currentTrackPoint setObject:self.compassHeading forKey:elementName];
                self.compassHeading = nil;
            }
            
            // Other
            else
            {
                // Currently parsing kMAPAccelerometerVector
                if (self.accelerometerVector)
                {
                    [self.accelerometerVector setObject:trimmedValue forKey:elementName];
                }
                
                // Currently parsing kMAPDeviceAngle
                else if (self.deviceAngle)
                {
                    [self.deviceAngle setObject:trimmedValue forKey:elementName];
                }
                
                // Currently parsing kMAPCompassHeading
                else if (self.compassHeading)
                {
                    [self.compassHeading setObject:trimmedValue forKey:elementName];
                }
                
                else
                {
                    [self.currentTrackPoint setObject:trimmedValue forKey:elementName];
                }
            }
        }
    }
    
    // Check if quick parse is done
    if (self.quickParse && self.localTimeZone && self.sequenceUUID && self.timeOffset && self.directionOffset && self.deviceMake && self.deviceModel && self.deviceUUID && self.sequenceDate)
    {
        [self.xmlParser abortParsing];
    }
}

- (void)parserDidEndDocument:(NSXMLParser*)parser
{
    if (self.doneCallback)
    {
        NSMutableDictionary* dict = dict = [NSMutableDictionary dictionary];
        
        if (self.localTimeZone != nil)     [dict setObject:self.localTimeZone forKey:kMAPLocalTimeZone];
        if (self.organizationKey != nil)   [dict setObject:self.organizationKey forKey:kMAPOrganizationKey];
        if (self.private != nil)           [dict setObject:self.private forKey:kMAPPrivate];
        if (self.sequenceUUID != nil)      [dict setObject:self.sequenceUUID forKey:kMAPSequenceUUID];
        if (self.timeOffset != nil)        [dict setObject:self.timeOffset forKey:kMAPTimeOffset];
        if (self.directionOffset!= nil)    [dict setObject:self.directionOffset forKey:kMAPDirectionOffset];
        if (self.deviceMake != nil)        [dict setObject:self.deviceMake forKey:kMAPDeviceMake];
        if (self.deviceModel != nil)       [dict setObject:self.deviceModel forKey:kMAPDeviceModel];
        if (self.deviceUUID != nil)        [dict setObject:self.deviceUUID forKey:kMAPDeviceUUID];
        if (self.sequenceDate != nil)      [dict setObject:self.sequenceDate forKey:kMAPCaptureTime];
        if (self.rigSequenceUUID != nil)   [dict setObject:self.rigSequenceUUID forKey:kMAPRigSequenceUUID];
        if (self.rigUUID != nil)           [dict setObject:self.rigUUID forKey:kMAPRigUUID];
        
        if (!self.quickParse)
        {
            if (self.locations)            [dict setObject:self.locations forKey:@"locations"];
        }
        
        self.doneCallback(dict);
        
        self.doneCallback = nil;
    }
}

@end
