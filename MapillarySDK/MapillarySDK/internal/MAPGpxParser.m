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

@interface MAPGpxParser()

@property NSXMLParser* xmlParser;
@property NSMutableArray* locations;
@property NSMutableDictionary* currentTrackPoint;
@property NSMutableString* currentElementValue;
@property NSDateFormatter* dateFormatter;
@property NSString* localTimeZone;
@property NSString* project;
@property NSString* sequenceKey;
@property NSNumber* timeOffset;
@property NSNumber* directionOffset;
@property NSString* deviceMake;
@property NSString* deviceModel;
@property NSString* deviceUUID;
@property NSDate* sequenceDate;
@property NSNumber* imageOrientation;
@property BOOL parsingMeta;
@property BOOL quickParse;

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
            self.project = nil;
            self.sequenceKey = nil;
            self.timeOffset = nil;
            self.directionOffset = nil;
            self.sequenceDate = nil;
            self.imageOrientation = nil;
        }
        else
        {
            self.localTimeZone = [[NSTimeZone localTimeZone] description];
            self.project = @"";
            self.sequenceKey = [[NSUUID UUID] UUIDString];
            self.timeOffset = @0;
            self.directionOffset = @-1;
            self.sequenceDate = [NSDate date];
            self.imageOrientation = @-1;
        }
        
        MAPDevice* defaultDevice = [MAPDevice thisDevice];
        self.deviceMake = defaultDevice.make;
        self.deviceModel = defaultDevice.model;
        self.deviceUUID = defaultDevice.UUID;
    }
    return self;
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
    if (!self.quickParse && [elementName isEqualToString:@"trkpt"])
    {
        self.currentTrackPoint = [NSMutableDictionary dictionaryWithDictionary:attributeDict];
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
    
    else if ([elementName isEqualToString:@"mapillary:localTimeZone"])
    {
        self.localTimeZone = strippedValue;
    }
    
    else if ([elementName isEqualToString:@"mapillary:project"])
    {
        self.project = strippedValue;
    }
    
    else if ([elementName isEqualToString:@"mapillary:sequenceKey"])
    {
        self.sequenceKey = strippedValue;
    }
    
    else if ([elementName isEqualToString:@"mapillary:timeOffset"])
    {
        NSNumberFormatter* f = [[NSNumberFormatter alloc] init];
        f.numberStyle = NSNumberFormatterDecimalStyle;
        f.locale = [NSLocale systemLocale];
        self.timeOffset = [f numberFromString:strippedValue];
    }
    
    else if ([elementName isEqualToString:@"mapillary:directionOffset"])
    {
        NSNumberFormatter* f = [[NSNumberFormatter alloc] init];
        f.numberStyle = NSNumberFormatterDecimalStyle;
        f.locale = [NSLocale systemLocale];
        self.directionOffset = [f numberFromString:strippedValue];
    }
    
    else if ([elementName isEqualToString:@"mapillary:deviceUUID"])
    {
        self.deviceUUID = strippedValue;
    }
    
    else if ([elementName isEqualToString:@"mapillary:deviceMake"])
    {
        self.deviceMake = strippedValue;
    }
    
    else if ([elementName isEqualToString:@"mapillary:deviceModel"])
    {
        self.deviceModel = strippedValue;
    }
    
    else if ([elementName isEqualToString:@"mapillary:imageOrientation"])
    {
        self.imageOrientation = [NSNumber numberWithInt:strippedValue.intValue];
    }
    
    // GPS track points
    else if (self.currentTrackPoint)
    {
        if ([elementName isEqualToString:@"trkpt"])
        {
            CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake([self.currentTrackPoint[@"lat"] doubleValue], [self.currentTrackPoint[@"lon"] doubleValue]);
            CLLocationDistance altitude = [self.currentTrackPoint[@"ele"] doubleValue];
            CLLocationAccuracy horizontalAccuracy = [self.currentTrackPoint[@"gpsAccuracyMeters"] doubleValue];
            CLLocationAccuracy verticalAccuracy = 0;
            CLLocationDirection course = [self.currentTrackPoint[@"compassTrueHeading"] doubleValue];
            CLLocationSpeed speed = 0;
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
            location.deviceMotionX = [self.currentTrackPoint[@"motionX"] doubleValue];
            location.deviceMotionY = [self.currentTrackPoint[@"motionY"] doubleValue];
            location.deviceMotionZ = [self.currentTrackPoint[@"motionZ"] doubleValue];
            location.headingAccuracy = [self.currentTrackPoint[@"compassAccuracyDegrees"] doubleValue];
            location.magneticHeading = [self.currentTrackPoint[@"compassMagneticHeading"] doubleValue];
            location.trueHeading = [self.currentTrackPoint[@"compassTrueHeading"] doubleValue];
            
            [self.locations addObject:location];
        }
        else if (![elementName isEqualToString:@"extensions"] && ![elementName isEqualToString:@"fix"])
        {
            if ([elementName containsString:@"mapillary:"])
            {
                elementName = [elementName stringByReplacingOccurrencesOfString:@"mapillary:" withString:@""];
            }
            
            NSString* trimmedValue = [self.currentElementValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            
            [self.currentTrackPoint setObject:trimmedValue forKey:elementName];
        }
    }
    
    // Check if quick parse is done
    if (self.quickParse && self.localTimeZone && self.project && self.sequenceKey && self.timeOffset && self.directionOffset && self.deviceMake && self.deviceModel && self.deviceUUID && self.sequenceDate && self.imageOrientation)
    {
        [self.xmlParser abortParsing];
    }
}

- (void)parserDidEndDocument:(NSXMLParser*)parser
{
    if (self.doneCallback)
    {
        NSMutableDictionary* dict = dict = [NSMutableDictionary dictionary];
        
        if (self.localTimeZone != nil)     [dict setObject:self.localTimeZone forKey:@"localTimeZone"];
        if (self.project != nil)           [dict setObject:self.project forKey:@"project"];
        if (self.sequenceKey != nil)       [dict setObject:self.sequenceKey forKey:@"sequenceKey"];
        if (self.timeOffset != nil)        [dict setObject:self.timeOffset forKey:@"timeOffset"];
        if (self.directionOffset!= nil)    [dict setObject:self.directionOffset forKey:@"directionOffset"];
        if (self.deviceMake != nil)        [dict setObject:self.deviceMake forKey:@"deviceMake"];
        if (self.deviceModel != nil)       [dict setObject:self.deviceModel forKey:@"deviceModel"];
        if (self.deviceUUID != nil)        [dict setObject:self.deviceUUID forKey:@"deviceUUID"];
        if (self.sequenceDate != nil)      [dict setObject:self.sequenceDate forKey:@"sequenceDate"];
        if (self.imageOrientation!= nil)   [dict setObject:self.imageOrientation forKey:@"imageOrientation"];
        
        if (!self.quickParse)
        {
            if (self.locations)     [dict setObject:self.locations forKey:@"locations"];
        }
        
        self.doneCallback(dict);
        
        self.doneCallback = nil;
    }
}

@end
