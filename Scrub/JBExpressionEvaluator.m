//
//  JBExpressionEvaluator.m
//  Scrub
//
//  Created by Jason Brennan on 12-08-26.
//  Copyright (c) 2012 Jason Brennan. All rights reserved.
//

#import "JBExpressionEvaluator.h"


@implementation JBExpressionEvaluator {
	NSArray *_operators;
}

+ (instancetype)evaluator {
	
	static JBExpressionEvaluator *evaluator = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		evaluator = [JBExpressionEvaluator new];
	});
	
	return evaluator;
}



- (id)init {
	if ((self = [super init])) {
		_operators = @[@"+", @"-", @"*", @"x", @"/"];
	}
	
	return self;
}

+ (NSString *)evaluateExpression:(NSArray *)expression {
	JBExpressionEvaluator *evaluator = [self evaluator];
	NSArray *postfix = [evaluator postfixExpressionFromInfixExpression:expression];
	
	NSLog(@"%@", postfix);
	
	return @"";
}


- (NSArray *)postfixExpressionFromInfixExpression:(NSArray *)expression {
	
	NSMutableArray *post = [@[] mutableCopy];
	NSMutableArray *stack = [@[] mutableCopy];
	
	
	NSInteger tokenIndex = 0;
	for (NSString *token in expression) {
		
		if ([self isOperand:token]) {
			[post addObject:token];
			continue;
		}
		
		
		if ([token isEqualToString:@"("]) {
			[stack addObject:token];
			continue;
		}
		
		
		if ([token isEqualToString:@")"]) {
			// Pop the stack until we find the opening ( and add popped values to `post`
			while ([stack count] > 0 && ![[stack lastObject] isEqualToString:@"("]) {
				[post addObject:[stack lastObject]];
				[stack removeLastObject];
			}
			if ([[stack lastObject] isEqualToString:@"("]) {
				[stack removeLastObject];
			} else {
				NSLog(@"ERROR! There was an extra ) in the expression at token index: %ld", tokenIndex);
			}
			continue;
		}
		
		
		if ([self isOperator:token]) {
			if ([stack count] < 1 || [[stack lastObject] isEqualToString:@"("]) {
				[stack addObject:token];
			} else {
				while ([stack count] > 0 && ![[stack lastObject] isEqualToString:@"("] && [self operator:token hasLowerOrEqualPrecendence:[stack lastObject]]) {
					[post addObject:[stack lastObject]];
					[stack removeLastObject];
				}
				[stack addObject:token];
			}
		}
		
		tokenIndex++;
	}
	
	if ([stack count]) {
		for (NSString *token in [stack reverseObjectEnumerator]) {
			[post addObject:token];
		}
	}

	
	return [NSArray arrayWithArray:post];
}


- (NSNumber *)numberFromString:(NSString *)string {
	static NSNumberFormatter *formatter = nil;
	if (nil == formatter) {
		formatter = [[NSNumberFormatter alloc] init];
		[formatter setAllowsFloats:YES];
	}
	return [formatter numberFromString:string];
}


- (BOOL)isOperand:(NSString *)op {
	return [self numberFromString:op] != nil;
}


- (BOOL)isOperator:(NSString *)op {
	return [_operators containsObject:op];
}


- (BOOL)operator:(NSString *)op hasLowerOrEqualPrecendence:(NSString *)otherOp {
	NSInteger opIndex = [_operators indexOfObject:op];
	NSInteger otherOpIndex = [_operators indexOfObject:otherOp];
	NSInteger mulIndex = [_operators indexOfObject:@"*"];
	
	if (opIndex < mulIndex && otherOpIndex < mulIndex) return YES; // same precedence
	if (opIndex >= mulIndex && otherOpIndex >= mulIndex) return YES; // same precedence
	return (opIndex <= otherOpIndex); // different precedence, return if op has less or same prec as otherOp
}

@end