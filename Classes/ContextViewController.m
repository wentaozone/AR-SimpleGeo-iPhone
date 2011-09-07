//
//  ContextViewController.m
//  SimpleGeo
//
//  Copyright (c) 2010-2011, SimpleGeo Inc.
//  All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
//     * Redistributions of source code must retain the above copyright
//       notice, this list of conditions and the following disclaimer.
//     * Redistributions in binary form must reproduce the above copyright
//       notice, this list of conditions and the following disclaimer in the
//       documentation and/or other materials provided with the distribution.
//     * Neither the name of the <organization> nor the
//       names of its contributors may be used to endorse or promote products
//       derived from this software without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
// ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
// WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
// DISCLAIMED. IN NO EVENT SHALL <COPYRIGHT HOLDER> BE LIABLE FOR ANY
// DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
// (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
// LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
// ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
// SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//

#import "ContextViewController.h"
#import "SM3DAR.h"


@implementation ContextViewController

@synthesize locationController;
@synthesize simpleGeoController;
@synthesize tableView;
@synthesize tvCell;
@synthesize tvMapCell;
@synthesize contextData;

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    if (! contextData) {
        [self loadContextForCurrentLocation:self];
    }
}

- (void)dealloc
{
    [contextData release];
    [super dealloc];
}

- (IBAction)loadContextForCurrentLocation:(id)sender
{
    CLLocationCoordinate2D lastLocation = [[self.locationController lastLocation] coordinate];

    [self.simpleGeoController setDelegate:self];
    [self.simpleGeoController.client getContextForPoint:[SGPoint pointWithLatitude:lastLocation.latitude
                                                                         longitude:lastLocation.longitude]];
}

#pragma mark SimpleGeoDelegate methods

- (void)requestDidFail:(ASIHTTPRequest *)request
{
    NSLog(@"Request failed: %@: %i", [request responseStatusMessage], [request responseStatusCode]);
}

- (void)requestDidFinish:(ASIHTTPRequest *)request
{
    // NSLog(@"Request finished: %@", [request responseString]);
}

- (void)didLoadContext:(NSDictionary *)context
              forQuery:(NSDictionary *)query
{
    self.contextData = [context objectForKey:@"features"];

    [tableView reloadData];
}

#pragma mark UITableViewDataSource methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)aTableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)aTableView
 numberOfRowsInSection:(NSInteger)section
{
    if (contextData) {
        return [contextData count] + 1;
    }

    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)aTableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == 0) {
        static NSString *ContextMapIdentifier = @"ContextTableViewMapCell";
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:ContextMapIdentifier];
        if (cell == nil) {
            [[NSBundle mainBundle] loadNibNamed:@"ContextTVCells"
                                          owner:self
                                        options:nil];
            cell = tvMapCell;
            self.tvMapCell = nil;
        }

        CLLocationCoordinate2D lastLocation = [[self.locationController lastLocation] coordinate];


        MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(lastLocation, 1000.0, 1000.0);
        SM3DARMapView *mapView = (SM3DARMapView *)[cell viewWithTag:1];
        [mapView setRegion:region];

        return cell;
    } else {
        static NSString *ContextIdentifier = @"ContextTableViewCell";
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:ContextIdentifier];
        if (cell == nil) {
            [[NSBundle mainBundle] loadNibNamed:@"ContextTVCells"
                                          owner:self
                                        options:nil];
            cell = tvCell;
            self.tvCell = nil;
        }

        NSDictionary *row = [contextData objectAtIndex:indexPath.row - 1];
        NSString *name = [row objectForKey:@"name"];
        NSString *category = @"";

        if ([[row objectForKey:@"classifiers"] count] > 0) {
            NSDictionary *classifiers = [[row objectForKey:@"classifiers"] objectAtIndex:0];

            category = [classifiers objectForKey:@"category"];

            NSString *subcategory = (NSString *)[classifiers objectForKey:@"subcategory"];
            if (subcategory && ! ([subcategory isEqual:@""] ||
                                  [subcategory isEqual:[NSNull null]])) {
                category = [NSString stringWithFormat:@"%@ ➟ %@", category, subcategory];
            }
        }

        UILabel *label;
        label = (UILabel *)[cell viewWithTag:1];
        label.text = [category uppercaseString];

        label = (UILabel *)[cell viewWithTag:2];
        label.text = name;

        return cell;
    }
}

#pragma mark UITableViewDelegate methods

- (CGFloat)tableView:(UITableView *)aTableView
heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == 0) {
        return 141.0;
    } else if (indexPath.row == [contextData count]) {
        return 81.0;
    }

    return 80.0;
}

@end
