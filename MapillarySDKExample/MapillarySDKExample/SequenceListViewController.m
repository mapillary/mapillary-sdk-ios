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
    
    [MAPFileManager getSequencesAsync:^(NSArray *sequences) {
        
        for (MAPSequence* s in sequences)
        {
            NSArray* images = [s getImages];
            
            if (images.count == 0)
            {
                [MAPFileManager deleteSequence:s];
            }
            else
            {
                NSDictionary* dict = @{@"sequence": s, @"count": [NSNumber numberWithUnsignedInteger:images.count]};
                [self.sequences addObject:dict];
            }
        }
        
        [self.tableView reloadData];
        
    }];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self.navigationController setNavigationBarHidden:NO];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
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
