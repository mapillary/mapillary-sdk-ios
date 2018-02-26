//
//  SequenceListViewController.m
//  MapillarySDKExample
//
//  Created by Anders Mårtensson on 2017-12-19.
//  Copyright © 2017 com.mapillary.sdk.example. All rights reserved.
//

#import "SequenceListViewController.h"
#import <MapillarySDK/MapillarySDK.h>

@interface SequenceListViewController ()

@property NSMutableArray* sequences;
@property NSDateFormatter* dateFormatter;

@end

@implementation SequenceListViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.dateFormatter = [[NSDateFormatter alloc] init];
    self.dateFormatter.dateStyle = NSDateFormatterLongStyle;
    
    self.sequences = [[NSMutableArray alloc] init];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self.navigationController setNavigationBarHidden:NO];
    
    [MAPFileManager listSequences:^(NSArray *sequences) {
        
        for (MAPSequence* s in sequences)
        {
            NSArray* images = [s listImages];
            
            if (images.count == 0)
            {
                [MAPFileManager deleteSequence:s];
            }
            else
            {
                NSDictionary* dict = @{@"sequence": s, @"count": @0};
                [self.sequences addObject:dict];
            }
        }
        
        [self.tableView reloadData];
        
    }];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.sequences.count;
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary* dict = [self.sequences objectAtIndex:indexPath.row];
    MAPSequence* sequence = dict[@"sequence"];
    NSNumber* count = dict[@"count"];
    
    UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"cell"];
    }
    
    NSString* dateString = [self.dateFormatter stringFromDate:sequence.sequenceDate];
    cell.textLabel.text = [NSString stringWithFormat:@"%@, %d images", dateString, count.intValue];
    
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (editingStyle == UITableViewCellEditingStyleDelete)
    {
        [tableView beginUpdates];
        
        NSDictionary* dict = [self.sequences objectAtIndex:indexPath.row];
        MAPSequence* sequence = dict[@"sequence"];
        [MAPFileManager deleteSequence:sequence];
        
        [self.sequences removeObjectAtIndex:indexPath.row];
        [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        
        [tableView endUpdates];
    }
}

@end
