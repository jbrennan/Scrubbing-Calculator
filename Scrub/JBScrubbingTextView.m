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
@property (nonatomic, strong) NSMutableDictionary *numberRanges;
@property (assign) NSRange currentlyHighlightedRange;
@property (assign) CGPoint initialDragPoint;
@property (nonatomic, strong) NSString *initialDragLine;
@property (copy) NSString *initialString;
@property (strong) NSNumber *initialNumber;
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
	self.numberRanges = [@{} mutableCopy];
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
	self.numberRanges = [NSMutableDictionary new];
	
	NSString *string = [[self textStorage] string];
	PKTokenizer *tokenizer = [PKTokenizer tokenizerWithString:string];
	
	tokenizer.commentState.reportsCommentTokens = NO;
	tokenizer.whitespaceState.reportsWhitespaceTokens = YES;
	
	// Recognize 'x' as a symbol for multiplication
	[tokenizer setTokenizerState:tokenizer.symbolState from:'x' to:'x'];
	[tokenizer setTokenizerState:tokenizer.symbolState from:'X' to:'X'];
	
	PKToken *eof = [PKToken EOFToken];
	PKToken *token = nil;
	
	
	NSUInteger currentLocation = 0;
	
	while ((token = [tokenizer nextToken]) != eof) {
		NSRange numberRange = NSMakeRange(currentLocation, [[token stringValue] length]);
		
		if ([token isNumber]) {
			[expressionTokens addObject:[token stringValue]];
			
			[self setNumberString:[token stringValue] forRange:numberRange];
			
		} else if ([token isSymbol] && [_symbols containsObject:[token stringValue]]) {
			
			if ([[token stringValue] isEqualToString:@"="]) break;
			
			[expressionTokens addObject:[token stringValue]];
		} else if ([token isSymbol] && [[token stringValue] isEqualToString:@"="]) {
			break;
		}
		
		currentLocation += [[token stringValue] length];
	
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


- (BOOL)shouldChangeTextInRange:(NSRange)affectedCharRange replacementString:(NSString *)replacementString {
	
	// This happens when only the text attributes are changing.
	if (nil == replacementString) return YES;
	
	NSRange lineRange = [[self string] lineRangeForRange:affectedCharRange];
	NSString *currentLine = [self currentLineForRange:affectedCharRange];
	NSRange equalRange = [currentLine rangeOfString:@"=" options:kNilOptions range:lineRange];
	if (NSNotFound == equalRange.location) return YES; // no equal sign in this line so we don't care
	
	return (NSMaxRange(affectedCharRange) <= equalRange.location + lineRange.location);
}


- (NSString *)currentLineForRange:(NSRange)range {
	NSRange lineRange = [[self string] lineRangeForRange:range];
	return [[self string] substringWithRange:lineRange];
}


#pragma mark - Found number ranges
- (void)setNumberString:(NSString *)string forRange:(NSRange)numberRange {
	// Just store the start location of the number, because the length might change (if, say, number goes from 100 -> 99)
	self.numberRanges[NSStringFromRange(numberRange)] = string;
}


- (NSRange)numberStringRangeForCharacterIndex:(NSUInteger)character {
	for (NSString *rangeString in self.numberRanges) {
		NSRange range = NSRangeFromString(rangeString);
		if (NSLocationInRange(character, range)) {
			return range;
		}
		
	}
	return NSMakeRange(NSNotFound, 0);
}


- (NSNumber *)numberFromString:(NSString *)string {
	static NSNumberFormatter *formatter = nil;
	if (nil == formatter) {
		formatter = [[NSNumberFormatter alloc] init];
		[formatter setAllowsFloats:YES];
	}
	return [formatter numberFromString:string];
}


#pragma mark - Mousing

- (void)mouseMoved:(NSEvent *)theEvent {

	NSUInteger character = [self characterIndexForPoint:[NSEvent mouseLocation]];
	
	NSRange range = [self numberStringRangeForCharacterIndex:character];
	if (range.location == NSNotFound) {
		if (_currentlyHighlightedRange.location != NSNotFound) {
			// Only change this when it's not already set... skip some work, I suppose.
			self.currentlyHighlightedRange = range;
		}
		return;
	}
	
	
	self.currentlyHighlightedRange = range;
}


- (NSString *)lineForCurrentlyHighlightedRange {
	return [self currentLineForRange:self.currentlyHighlightedRange];
}


- (void)mouseDown:(NSEvent *)theEvent {
	if (self.currentlyHighlightedRange.location == NSNotFound) {
		[super mouseDown:theEvent];
		return;
	}
	
	self.initialDragPoint = [NSEvent mouseLocation];
	self.initialString = [[self string] substringWithRange:self.currentlyHighlightedRange];
	self.initialNumber = [self numberFromString:self.initialString];
	
	NSString *wholeText = [self string];
	
	
	NSString *originalLine = [self lineForCurrentlyHighlightedRange];
	NSRange originalLineRange = [wholeText rangeOfString:originalLine];
	
	self.initialDragLine = originalLine;

}


- (void)mouseDragged:(NSEvent *)theEvent {
	
	// Skip it if we're not currently dragging a word
	if (self.currentlyHighlightedRange.location == NSNotFound) {
		[super mouseDragged:theEvent];
		return;
	}
	
	NSLog(@"mouse dragged, current range is: %@", NSStringFromRange(self.currentlyHighlightedRange));
	
	//NSRange numberRange = [self numberStringRangeForCharacterIndex:self.currentlyHighlightedRange.location];
	NSRange numberRange = [self rangeForNumberNearestToIndex:self.currentlyHighlightedRange.location];
	NSString *numberString = [[self string] substringWithRange:numberRange];
	
	NSLog(@"Dragging...current number is: %@", numberString);
	NSNumber *number = [self numberFromString:numberString];
	
	if (nil == number) {
		NSLog(@"Couldn't parse a number out of :%@", numberString);
		return;
	}
	
	CGPoint screenPoint = [NSEvent mouseLocation];
	CGFloat x = screenPoint.x - self.initialDragPoint.x;
	CGFloat y = screenPoint.y - self.initialDragPoint.y;
	CGSize offset = CGSizeMake(x, y);
	
	
	NSInteger offsetValue = [self.initialNumber integerValue] + (NSInteger)offset.width;
	NSNumber *updatedNumber = @(offsetValue);
	NSString *updatedNumberString = [updatedNumber stringValue];
	
	
	// Now do the replacement in the existing text
	NSString *replacedCommand = [self.initialDragCommandString stringByReplacingCharactersInRange:self.initialDragRangeInOriginalCommand withString:updatedNumberString];
	
	[super insertText:updatedNumberString replacementRange:self.currentlyHighlightedRange];
	self.currentlyHighlightedRange = NSMakeRange(self.currentlyHighlightedRange.location, [updatedNumberString length]);
	
	
	// Update the position of commandStart depending on how our (whole) string has changed.
	NSUInteger lengthDifference = [self.initialDragCommandString length] - [replacedCommand length];
	self.commandStart = self.initialDragCommandStart - lengthDifference;
	
	if (self.numberDragHandler) {
		self.numberDragHandler(replacedCommand);
	}
}


- (void)mouseUp:(NSEvent *)theEvent {
	// Skip it if we're not currently dragging a word
	if (self.currentlyHighlightedRange.location == NSNotFound) {
		[super mouseUp:theEvent];
		return;
	}
	
	// Triggers clearing out our number-dragging state.
	[self highlightText];
	[self mouseMoved:theEvent];
	
	self.initialDragCommandString = nil;
	self.initialDragCommandRange = NSMakeRange(NSNotFound, NSNotFound);
	self.initialNumber = nil;
}


- (NSRange)rangeForNumberNearestToIndex:(NSUInteger)index {
	// parse this out right now...
	NSRange originalRange = self.initialDragCommandRange;
	
	// The problem is the command doesn't get updated in our history, so it breaks after the first use!!
	NSString *currentCommand = [self currentLineForRange:originalRange];
	
	PKTokenizer *tokenizer = [PKTokenizer tokenizerWithString:currentCommand];
	
	tokenizer.commentState.reportsCommentTokens = NO;
	tokenizer.whitespaceState.reportsWhitespaceTokens = YES;
	
	
	PKToken *eof = [PKToken EOFToken];
	PKToken *token = nil;
	
	
	NSUInteger currentLocation = 0; // in the command!
	
	while ((token = [tokenizer nextToken]) != eof) {
		
		NSRange numberRange = NSMakeRange(currentLocation + originalRange.location, [[token stringValue] length]);
		
		if ([token isNumber]) {
			if (NSLocationInRange(index, numberRange)) {
				return numberRange;
			}
		}
		
		
		currentLocation += [[token stringValue] length];
		
	}
	return NSMakeRange(NSNotFound, NSNotFound);
}

@end
