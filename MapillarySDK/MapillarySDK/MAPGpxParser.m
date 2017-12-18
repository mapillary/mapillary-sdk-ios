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
    }
    return self;
}

- (void)parse:(void(^)(NSDictionary* dict))done
{
    self.doneCallback = done;
    [self.xmlParser parse];
}

- (void)parserDidStartDocument:(NSXMLParser *)parser
{
    
}

- (void)parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)parseError
{
    NSLog(@"Parser error: %@", parseError);
}

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict
{
    self.currentElementValue = [[NSMutableString alloc] init];
    
    if ([elementName isEqualToString:@"trkpt"])
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
    if (self.currentTrackPoint)
    {
        if ([elementName isEqualToString:@"trkpt"])
        {
            CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake([self.currentTrackPoint[@"lat"] doubleValue], [self.currentTrackPoint[@"lon"] doubleValue]);
            CLLocationDistance altitude = 0;
            CLLocationAccuracy horizontalAccuracy = [self.currentTrackPoint[@"gpsAccuracyMeters"] doubleValue];
            CLLocationAccuracy verticalAccuracy = 0;
            CLLocationDirection course = [self.currentTrackPoint[@"gpsAccuracyMeters"] doubleValue];
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
            //location.heading = [[CLHeading alloc] init];
            
            [self.locations addObject:location];
            
            //self.currentTrackPoint = nil;
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
}

- (void)parserDidEndDocument:(NSXMLParser*)parser
{
    if (self.doneCallback)
    {
        NSDictionary* dict = @{@"locations": self.locations};
        
        self.doneCallback(dict);
        self.doneCallback = nil;
    }
}

@end
