//
//  MAPProcessedImage+CoreDataProperties.h
//  
//
//  Created by Anders Mårtensson on 2018-11-30.
//
//

#import "MAPProcessedImage+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface MAPProcessedImage (CoreDataProperties)

+ (NSFetchRequest<MAPProcessedImage *> *)fetchRequest;

@property (nullable, nonatomic, copy) NSString *filename;
@property (nullable, nonatomic, copy) NSDate *date;

@end

NS_ASSUME_NONNULL_END
