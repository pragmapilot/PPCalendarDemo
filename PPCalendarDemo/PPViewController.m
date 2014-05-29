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

@property (strong, nonatomic) NSDate *eventStartDate;
@property (strong, nonatomic, readonly) NSDate *eventEndDate;
@property (copy, nonatomic) NSString *eventTitle;

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
                    // Do something with error
                }
                else if (!granted)
                {
                    // Notify user permission was not granted, perhaps?
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
                    
                    __block BOOL eventExists = NO;
                    
                    [eventsOnDate enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                        EKEvent *eventToCheck = (EKEvent*)obj;
                        
                        if([event.title isEqualToString:eventToCheck.title])
                        {
                            eventExists = YES;
                            *stop = YES;
                        }
                    }];
                    
                    if(! eventExists)
                    {
                        [event setCalendar:[eventStore defaultCalendarForNewEvents]];
                        
                        NSError *saveEventError;
                        [eventStore saveEvent:event span:EKSpanThisEvent error: &saveEventError];
                        
                        if(saveEventError)
                        {
                            // Do something with error
                        }
                        else
                        {
                            // Notify success
                            self.addEventButton.enabled = NO;
                            self.removeEventButton.enabled = YES;
                        }
                    }
                    else
                    {
                        // Warn of existing event
                        self.addEventButton.enabled = NO;
                        self.removeEventButton.enabled = YES;
                    }
                }
            });
        }];
    }
    else
    {
        // Notify operation not supported
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
                    // Do something with error
                }
                else if (!granted)
                {
                    // Notify user permission was not granted, perhaps?
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
                            // Do something with error
                        }
                        else
                        {
                            // Notify success
                            self.removeEventButton.enabled = NO;
                            self.addEventButton.enabled = YES;
                        }
                    }
                    else
                    {
                        // Warn of non-existing event
                        self.addEventButton.enabled = NO;
                        self.removeEventButton.enabled = YES;
                    }
                }
            });
        }];
    }
    else
    {
        // Notify operation not supported
    }
}

- (IBAction)openCalendarButtonTapped:(id)sender
{
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"calshow://"]];
}

@end
