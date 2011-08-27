// Copyright 2006-2011 Aoren LLC. All rights reserved.

#import "JustNumFormatter.h"

@implementation JustNumFormatter

- (NSString*) stringForObjectValue:(id)obj
{
	unsigned int  Number = 0;
  
	if( [obj isKindOfClass:[NSNumber class]] ){	Number = [obj unsignedIntValue]; }
	else{ Number = [obj intValue]; }
  
	//NSLog(@"Number: %d %x %@\n", Number, obj, NSStringFromClass([obj class]));
	return [NSString stringWithFormat: @"%d", Number];
}

- (BOOL) getObjectValue:(id*)obj forString:(NSString*)string errorDescription:(NSString**)error
{
	//Remove any characters that are not in [0-9]
	NSMutableString*	tempString			  = [NSMutableString stringWithString:string];
	NSCharacterSet*		illegalCharacters     = [[NSCharacterSet characterSetWithCharactersInString:@"0123456789"] invertedSet];
	NSRange				illegalCharacterRange = [tempString rangeOfCharacterFromSet:illegalCharacters];

	error = 0L;

	while( illegalCharacterRange.location != NSNotFound )
	{
		[tempString deleteCharactersInRange:illegalCharacterRange];
		illegalCharacterRange = [tempString rangeOfCharacterFromSet:illegalCharacters];
	}

	*obj = tempString;

	//NSLog(@"string: %@\n", string);
	return YES;
}

- (BOOL) isPartialStringValid:(NSString*)partialString newEditingString:(NSString**)newString errorDescription:(NSString**)error;
{
	NSMutableString*	tempString			  = [NSMutableString stringWithString:partialString];
	NSCharacterSet*		illegalCharacters     = [[NSCharacterSet characterSetWithCharactersInString:@"0123456789"] invertedSet];
	
	newString = 0L;
	error = 0L;
	
	unichar a;
	int length = [tempString length];
	
	for( int i = 0; i < length; i++ )
	{
		a = [tempString characterAtIndex:i];
		
		if( [illegalCharacters characterIsMember:a] ){ return false; }
	}
	
	return true;
}

@end