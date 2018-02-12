//
//  MAPGpxParser.h
//  MapillarySDK
//
//  Created by Anders Mårtensson on 2017-09-07.
//  Copyright © 2017 Mapillary. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "MAPSequence.h"

@interface MAPGpxParser : NSObject <NSXMLParserDelegate>

- (id)initWithPath:(NSString*)path;
- (void)parse:(void(^)(NSDictionary* dict))done;
- (void)quickParse:(void(^)(NSDictionary* dict))done;

@end
