//
//  JBAppDelegate.m
//  Scrub
//
//  Created by Jason Brennan on 12-08-26.
//  Copyright (c) 2012 Jason Brennan. All rights reserved.
//

#import "JBAppDelegate.h"
#import "JBScrubbingTextViewWindowController.h"

@implementation JBAppDelegate {
	JBScrubbingTextViewWindowController *_windowController;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	_windowController = [JBScrubbingTextViewWindowController new];
	[[_windowController window] makeKeyAndOrderFront:self];
}

@end
