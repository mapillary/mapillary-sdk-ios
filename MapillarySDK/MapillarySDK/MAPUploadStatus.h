//
//  MAPUploadStatus.h
//  MapillarySDK
//
//  Created by Anders Mårtensson on 2017-08-24.
//  Copyright © 2017 Mapillary. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MAPUploadStatus : NSObject

@property BOOL uploading;
@property int nbrImagesToUpload;
@property int nbrImagesUploaded;


@end
