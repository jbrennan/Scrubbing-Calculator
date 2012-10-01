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


- (void)insertText:(id)insertString {
	[super insertText:insertString];
	NSRange selectedRange = [self selectedRange];
	[self parseMath];
	
	[self resetSelectionRange:selectedRange];
}


- (void)deleteBackward:(id)sender {
	[super deleteBackward:sender];
	NSRange selectedRange = [self selectedRange];
	[self parseMath];
	
	[self resetSelectionRange:selectedRange];
}


- (void)resetSelectionRange:(NSRange)oldSelectionRange {
	if (NSMaxRange(oldSelectionRange) <= [[self string] length]) {
		[self setSelectedRange:oldSelectionRange];
	} else {
		// This might happen when the inserted character is actually removed by the math parsing.
		// i.e., inserted something after the = sign and it was replaced.
		[self setSelectedRange:NSMakeRange([[self string] length], 0)];
	}
}

- (void)textStorageDidProcessEditing:(NSNotification *)notification {
	[self highlightText];
}


- (void)parseMath {
	
	/*
	 *
	 *
	 * BUUUUUUUUG: Currently only supports the first line. Ideally, I should be enumerating ALL THE LINES!
	 *
	 *
	 *
	 */
	
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
	
	
	
	
	while ((token = [tokenizer nextToken]) != eof) {
		
		if ([token isNumber]) {
			[expressionTokens addObject:[token stringValue]];
		} else if ([token isSymbol] && [_symbols containsObject:[token stringValue]]) {
			
			if ([[token stringValue] isEqualToString:@"="]) break;
			
			[expressionTokens addObject:[token stringValue]];
		} else if ([token isSymbol] && [[token stringValue] isEqualToString:@"="]) {
			break;
		}
		
	
	}

	
	
	
	if ([JBExpressionEvaluator expressionCanEvaluate:expressionTokens]) {
		NSString *result = [JBExpressionEvaluator evaluateExpression:expressionTokens];
		NSString *prettierResult = [NSString stringWithFormat:@"%g", [result doubleValue]];
		
		// append the answer with an = if the line doesn't already have one.
		NSRange lineRange = [string lineRangeForRange:[self selectedRange]];
		NSString *line = [string substringWithRange:lineRange];
		
		NSLog(@"line: %@", line);
		NSRange eqRange = [line rangeOfString:@"="];
		
		if (NSNotFound == eqRange.location) {
			line = [line stringByAppendingFormat:@" = %@", prettierResult];
		} else {
			// replace everything after the equal sign
			NSString *before = [line substringToIndex:NSMaxRange(eqRange)];
			NSLog(@"before: %@", before);
			line = [before stringByAppendingFormat:@" %@", prettierResult];
		}
		
		[[[self textStorage] mutableString] replaceCharactersInRange:lineRange withString:line];
		
	} else {
		
		NSRange lineRange = [string lineRangeForRange:[self selectedRange]];
		NSString *line = [string substringWithRange:lineRange];
		
		NSRange eqRange = [line rangeOfString:@" ="];
		if (NSNotFound != eqRange.location) {
			line = [line substringToIndex:eqRange.location];
		}
		[[self textStorage] replaceCharactersInRange:lineRange withString:line];
	}
	
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
