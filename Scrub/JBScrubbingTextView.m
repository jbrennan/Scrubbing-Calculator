//
//  JBScrubbingTextView.m
//  Scrub
//
//  Created by Jason Brennan on 12-08-26.
//  Copyright (c) 2012 Jason Brennan. All rights reserved.
//

#import "JBScrubbingTextView.h"
#import <ParseKit/ParseKit.h>

@interface JBScrubbingTextView () <NSTextStorageDelegate>
@end


@implementation JBScrubbingTextView

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
		[self commonInitWithFrame:frame];
    }
    
    return self;
}


- (id)initWithCoder:(NSCoder *)aDecoder {
	self = [super initWithCoder:aDecoder];
	if (self) {
		[self commonInitWithFrame:[self frame]];
	}
	return self;
}


- (void)commonInitWithFrame:(CGRect)frame {
	[[self textStorage] setDelegate:self];
}


- (void)textStorageDidProcessEditing:(NSNotification *)notification {
	[self parseText];
}


- (void)parseText {
	[self parseMath];
	[self highlightText];
}


- (void)parseMath {
	
}



- (void)highlightText {
	
}














@end
