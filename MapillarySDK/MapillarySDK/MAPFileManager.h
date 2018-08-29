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
 A fast but incomplete method for listing sequences. It does not parse the GPX file so some
 meta data will not be initialised.
 
 @return A list of sequences.
 */
+ (NSArray*)listSequences;

/**
 A slow but complete method for listing sequences. It parses the GPX file and
 initialises all meta data.
 
 @param done A block object that contains the sequences on disk.
 */
+ (void)getSequencesAsync:(void(^)(NSArray* sequences))done;

/**
 Deletes a sequence from disk. This deletes everything including images and the
 GPX file.
 
 @param sequence The sequence to delete.
 */
+ (void)deleteSequence:(MAPSequence*)sequence;


@end
