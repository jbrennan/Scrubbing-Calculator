//
//  JBScrubbingTextViewWindowController.m
//  Scrub
//
//  Created by Jason Brennan on 12-08-26.
//  Copyright (c) 2012 Jason Brennan. All rights reserved.
//

#import "JBScrubbingTextViewWindowController.h"

@interface JBScrubbingTextViewWindowController () <NSTextViewDelegate>

@end

@implementation JBScrubbingTextViewWindowController


+ (id)new {
	return [[[self class] alloc] initWithWindowNibName:@"JBScrubbingTextViewWindowController"];
}


- (void)windowDidLoad {
    [super windowDidLoad];
    
    [self.textView setDelegate:self];
	[self.textView setFont:[NSFont fontWithName:@"Menlo" size:21.0f]];
}

@end
