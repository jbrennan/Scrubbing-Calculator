//
//  JBScrubbingTextView.m
//  Scrub
//
//  Created by Jason Brennan on 12-08-26.
//  Copyright (c) 2012 Jason Brennan. All rights reserved.
//

#import "JBScrubbingTextView.h"
#import "JBExpressionEvaluator.h"
#import <ParseKit/ParseKit.h>

@interface JBScrubbingTextView () <NSTextStorageDelegate>
@end


@implementation JBScrubbingTextView {
	NSArray *_symbols;
}

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
	[self setTextContainerInset:CGSizeMake(10, 10)];
	_symbols = @[@"+", @"-", @"/", @"*", @"x", @"X", @"=", @"(", @")"];
}


- (void)textStorageDidProcessEditing:(NSNotification *)notification {
	[self parseText];
}


- (void)parseText {
	[self parseMath];
	[self highlightText];
}


- (void)parseMath {
	// Tokenize the string and ignore all words
	NSMutableArray *expressionTokens = [@[] mutableCopy];
	
	NSString *string = [[self textStorage] string];
	PKTokenizer *tokenizer = [PKTokenizer tokenizerWithString:string];
	
	tokenizer.commentState.reportsCommentTokens = NO;
	tokenizer.whitespaceState.reportsWhitespaceTokens = YES;
	
	// Recognize 'x' as a symbol for multiplication
	[tokenizer setTokenizerState:tokenizer.symbolState from:'x' to:'x'];
	[tokenizer setTokenizerState:tokenizer.symbolState from:'X' to:'X'];
	
	PKToken *eof = [PKToken EOFToken];
	PKToken *token = nil;
	
	[[self textStorage] beginEditing];
	
	
	while ((token = [tokenizer nextToken]) != eof) {
		
		if ([token isNumber]) {
			[expressionTokens addObject:[token stringValue]];
		} else if ([token isSymbol] && [_symbols containsObject:[token stringValue]]) {
			[expressionTokens addObject:[token stringValue]];
		}
		
	
	}
	NSLog(@"Expression tokens: %@", expressionTokens);
	[JBExpressionEvaluator evaluateExpression:expressionTokens];
	[[self textStorage] endEditing];
}



- (void)highlightText {
	NSString *string = [[self textStorage] string];
	PKTokenizer *tokenizer = [PKTokenizer tokenizerWithString:string];
	
	tokenizer.commentState.reportsCommentTokens = NO;
	tokenizer.whitespaceState.reportsWhitespaceTokens = YES;
	
	// Recognize 'x' as a symbol for multiplication
	[tokenizer setTokenizerState:tokenizer.symbolState from:'x' to:'x'];
	[tokenizer setTokenizerState:tokenizer.symbolState from:'X' to:'X'];
	
	PKToken *eof = [PKToken EOFToken];
	PKToken *token = nil;
	
	[[self textStorage] beginEditing];
	
	NSUInteger currentLocation = 0;
	
	while ((token = [tokenizer nextToken]) != eof) {
		NSColor *fontColor = [NSColor grayColor];
		
		if ([token isNumber]) {
			fontColor = [NSColor textColor];
		} else if ([token isSymbol]) {
			// which symbol?
			if ([_symbols containsObject:[token stringValue]]) {
				fontColor = [NSColor purpleColor];
			}
		}
		
		[[self textStorage] addAttribute:NSForegroundColorAttributeName value:fontColor range:NSMakeRange(currentLocation, [[token stringValue] length])];
		currentLocation += [[token stringValue] length];
	}
	
	
	[[self textStorage] endEditing];
}














@end
