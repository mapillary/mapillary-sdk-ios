//
//  MAPProcessedImage+CoreDataProperties.m
//  
//
//  Created by Anders Mårtensson on 2018-11-30.
//
//

#import "MAPProcessedImage+CoreDataProperties.h"

@implementation MAPProcessedImage (CoreDataProperties)

+ (NSFetchRequest<MAPProcessedImage *> *)fetchRequest {
	return [NSFetchRequest fetchRequestWithEntityName:@"MAPProcessedImage"];
}

@dynamic filename;
@dynamic date;

@end
