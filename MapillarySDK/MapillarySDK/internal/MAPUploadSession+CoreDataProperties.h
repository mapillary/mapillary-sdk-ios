//
//  MAPUploadSession+CoreDataProperties.h
//  
//
//  Created by Anders Mårtensson on 2020-06-04.
//
//

#import "MAPUploadSession+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface MAPUploadSession (CoreDataProperties)

+ (NSFetchRequest<MAPUploadSession *> *)fetchRequest;

@property (nullable, nonatomic, copy) NSDate *date;
@property (nullable, nonatomic, copy) NSString *sequenceKey;
@property (nullable, nonatomic, copy) NSData *uploadFields;
@property (nullable, nonatomic, copy) NSString *uploadKeyPrefix;
@property (nullable, nonatomic, copy) NSString *uploadSessionKey;
@property (nullable, nonatomic, copy) NSString *uploadUrl;


@end

NS_ASSUME_NONNULL_END
