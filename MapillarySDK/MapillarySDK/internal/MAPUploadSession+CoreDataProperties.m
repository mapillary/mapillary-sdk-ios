//
//  MAPUploadSession+CoreDataProperties.m
//  
//
//  Created by Anders Mårtensson on 2020-06-04.
//
//

#import "MAPUploadSession+CoreDataProperties.h"

@implementation MAPUploadSession (CoreDataProperties)

+ (NSFetchRequest<MAPUploadSession *> *)fetchRequest {
	return [NSFetchRequest fetchRequestWithEntityName:@"MAPUploadSession"];
}

@dynamic date;
@dynamic sequenceKey;
@dynamic uploadFields;
@dynamic uploadKeyPrefix;
@dynamic uploadSessionKey;
@dynamic uploadUrl;

@end
