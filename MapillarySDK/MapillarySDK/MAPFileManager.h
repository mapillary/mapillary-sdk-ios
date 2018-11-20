//
//  MAPFileManager.h
//  MapillarySDK
//
//  Created by Anders Mårtensson on 2017-08-24.
//  Copyright © 2017 Mapillary. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MAPSequence.h"
#import "MAPImage.h"

/**
 The `MAPFileManager` class contains methods for getting and deleting sequences.
 
 @see `MAPSequence`
 */
@interface MAPFileManager : NSObject

///-----------------------------------------------------------------------------
/// @name Sequences
///-----------------------------------------------------------------------------

/**
 Get's all the sequences synchronously.
 
 @param parseGpx If YES, the full GPX file is parsed. If NO, some properties of
 of the MAPSequence object will be nil.
 @return A list of sequences.
 */
+ (NSArray*)getSequences:(BOOL)parseGpx;

/**
 Get's all the sequences asynchronously.
 
 @param parseGpx If YES, the full GPX file is parsed. If NO, some properties of
 of the MAPSequence object will be nil.
 @param done A block object that contains the sequences on disk.
 */
+ (void)getSequencesAsync:(BOOL)parseGpx done:(void(^)(NSArray* sequences))done;

/**
 Deletes a sequence from disk. This deletes everything including images and the
 GPX file.
 
 @param sequence The sequence to delete.
 */
+ (void)deleteSequence:(MAPSequence*)sequence;


@end
