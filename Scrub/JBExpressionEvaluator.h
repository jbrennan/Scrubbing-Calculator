//
//  JBExpressionEvaluator.h
//  Scrub
//
//  Created by Jason Brennan on 12-08-26.
//  Copyright (c) 2012 Jason Brennan. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface JBExpressionEvaluator : NSObject
+ (NSString *)evaluateExpression:(NSArray *)expression;
+ (BOOL)expressionCanEvaluate:(NSArray *)expression;
@end
