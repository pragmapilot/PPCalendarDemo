//
//  PPViewController.m
//  PPCalendarDemo
//
//  Created by #pragaPilot on 29/05/14.
//  Copyright (c) 2014 PragmaPilot. All rights reserved.
//

#import "PPViewController.h"
#import <EventKit/EventKit.h>

@interface PPViewController ()

@property (weak, nonatomic) IBOutlet UIButton *addEventButton;
@property (weak, nonatomic) IBOutlet UIButton *removeEventButton;

// Event related stuff
@property (strong, nonatomic) NSDate *eventStartDate;
@property (strong, nonatomic, readonly) NSDate *eventEndDate;
@property (copy, nonatomic) NSString *eventTitle;

// UI stuff
@property (strong, nonatomic) UIAlertView *alertView;

@end

@implementation PPViewController

#pragma mark - View Controller lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    self.addEventButton.enabled = YES;
    self.removeEventButton.enabled = NO;
    
    self.eventTitle = @"#pragmaPilot's outstanding event!";
    
    self.alertView = [[UIAlertView alloc] initWithTitle:nil message:nil delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
}

#pragma mark - Properties

- (NSDate*)eventEndDate
{
    return [NSDate dateWithTimeInterval:60*60 sinceDate:self.eventStartDate]; // ends in one hour
}

#pragma mark - Handlers

- (IBAction)addEventButtonTapped:(id)sender
{
    EKEventStore *eventStore = [[EKEventStore alloc] init];
    
    if ([eventStore respondsToSelector:@selector(requestAccessToEntityType:completion:)])
    {
        [eventStore requestAccessToEntityType:EKEntityTypeEvent completion:^(BOOL granted, NSError *error) {
            // We need to run the main thread to issue alerts
            dispatch_async(dispatch_get_main_queue(), ^{
                if (error)
                {
                    self.alertView.message = @"Could not access the calendar because an error ocurred.";
                    [self.alertView show];
                }
                else if (!granted)
                {
                    self.alertView.message = @"Could not access the calendar because permission was not granted.";
                    [self.alertView show];
                }
                else
                {
                    self.eventStartDate = [NSDate date];
                    
                    EKEvent *event = [EKEvent eventWithEventStore:eventStore];
                    event.title = self.eventTitle;
                    event.startDate = self.eventStartDate;
                    event.endDate = self.eventEndDate;
                    
                    NSPredicate *predicate = [eventStore predicateForEventsWithStartDate:event.startDate endDate:event.endDate calendars:nil];
                    NSArray *eventsOnDate = [eventStore eventsMatchingPredicate:predicate];
                    
                    NSUInteger eventIndex = [eventsOnDate indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
                        EKEvent *eventToCheck = (EKEvent*)obj;
                        return [self.eventTitle isEqualToString:eventToCheck.title];
                    }];
                    
                    if(eventIndex != NSNotFound)
                    {
                        [event setCalendar:[eventStore defaultCalendarForNewEvents]];
                        
                        NSError *saveEventError;
                        [eventStore saveEvent:event span:EKSpanThisEvent error: &saveEventError];
                        
                        if(saveEventError)
                        {
                            self.alertView.message = @"Could not add event to the calendar because an error ocurred.";
                            [self.alertView show];
                        }
                        else
                        {
                            self.addEventButton.enabled = NO;
                            self.removeEventButton.enabled = YES;
                            
                            self.alertView.message = @"The event was added to the calendar.";
                            [self.alertView show];
                        }
                    }
                    else
                    {
                        self.addEventButton.enabled = NO;
                        self.removeEventButton.enabled = YES;
                        
                        self.alertView.message = @"Could not add event to the calendar because it already existed.";
                        [self.alertView show];
                    }
                }
            });
        }];
    }
    else
    {
        self.alertView.message = @"Could not add event to the calendar because the feature is not supported.";
        [self.alertView show];
    }
}

- (IBAction)removeEventButtonTapped:(id)sender
{
    EKEventStore *eventStore = [[EKEventStore alloc] init];
    if ([eventStore respondsToSelector:@selector(requestAccessToEntityType:completion:)])
    {
        [eventStore requestAccessToEntityType:EKEntityTypeEvent completion:^(BOOL granted, NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (error)
                {
                    self.alertView.message = @"Could not access the calendar because an error ocurred.";
                    [self.alertView show];
                }
                else if (!granted)
                {
                    self.alertView.message = @"Could not access the calendar because permission was not granted.";
                    [self.alertView show];
                }
                else
                {
                    NSPredicate *predicate = [eventStore predicateForEventsWithStartDate:self.eventStartDate endDate:self.eventEndDate calendars:nil];
                    NSArray *eventsOnDate = [eventStore eventsMatchingPredicate:predicate];
                    
                    NSUInteger eventIndex = [eventsOnDate indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
                        EKEvent *eventToCheck = (EKEvent*)obj;
                        return [self.eventTitle isEqualToString:eventToCheck.title];
                    }];
                    
                    if(eventIndex != NSNotFound)
                    {
                        NSError *removeEventError;
                        EKEvent *eventToRemove = eventsOnDate[eventIndex];
                        [eventStore removeEvent:eventToRemove span:EKSpanFutureEvents error:&removeEventError];
                        
                        if(removeEventError)
                        {
                            self.alertView.message = @"Could not remove event from the calendar because an error ocurred.";
                            [self.alertView show];
                        }
                        else
                        {
                            self.removeEventButton.enabled = NO;
                            self.addEventButton.enabled = YES;
                            
                            self.alertView.message = @"The event was removed from the calendar";
                            [self.alertView show];
                        }
                    }
                    else
                    {
                        self.addEventButton.enabled = NO;
                        self.removeEventButton.enabled = YES;
                        
                        self.alertView.message = @"Could not remove event from the calendar because it was not found.";
                        [self.alertView show];
                    }
                }
            });
        }];
    }
    else
    {
        self.alertView.message = @"Could not remove event from the calendar because the feature is not supported.";
        [self.alertView show];
    }
}

- (IBAction)openCalendarButtonTapped:(id)sender
{
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"calshow://"]];
}

@end
