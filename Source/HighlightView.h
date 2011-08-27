// Copyright 2006-2011 Aoren LLC. All rights reserved.

#import <Cocoa/Cocoa.h>

#import "LanguageInspector.h"

#define HIGHLIGHTTIME		0.25
#define PRESSHIGHLIGHTTIME	0.5
#define HIGHLIGHTFONT		@"Lucida Grande"
#define HIGHLIGHTSIZE		24.0
#define HIGHLIGHTEDGETHRESH	10.0
#define LINESPACING			-8.0
#define BASELINEOFFSET		-8.0

#define CORNER			10.0
#define LINEWIDTH		2.0
#define HALFLW			LINEWIDTH/2

@class LanguageInspector;

@interface HGradient : NSObject
{
	@public
	float	c1[4];
	float	c2[4];
}

- (id) initWithR:(float)r G:(float)g B:(float)b A:(float)a R:(float)r2 G:(float)g2 B:(float)b2 A:(float)a2;

@end


@interface HighlightView : NSView
{
	@public
	LanguageInspector*				LI;
	/*int								initialOffset;
	int								extraSpace;
	int								fontHeight;*/
	
	IBOutlet NSTextView*						textView;
	//NSTextField*						textView;
	//NSText*						textView;
}

@end