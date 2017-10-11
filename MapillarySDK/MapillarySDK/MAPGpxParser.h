//
//  MAPGpxParser.h
//  MapillarySDK
//
//  Created by Anders Mårtensson on 2017-09-07.
//  Copyright © 2017 Mapillary. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MAPSequence.h"

@interface MAPGpxParser : NSObject <NSXMLParserDelegate>

- (instancetype)initWithPath:(NSString*)path;
- (void)parse:(void(^)(NSDictionary* dict))done;

@end
