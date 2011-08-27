// Copyright 2006-2011 Aoren LLC. All rights reserved.

#import "HighlightView.h"

static void myCalculateShadingValues( void *info, const float *in, float *out )
{
	HGradient* gr = (HGradient*)info;
	
    /*float v;
    size_t k, components;
    static const float c[] = {0, 0, 0, 1 };
 
    components = (size_t)info;
 
    v = *in;
	
    for( k = 0; k < components -1; k++ )
	{
		*out++ = c[k] * v;
	}
	
	*out++ = 1;*/
	int		i;
	float   x = in[0];

	for( i = 0; i < 4; i++ )
	{
		out[i] = gr->c1[i] + x * ( gr->c2[i] - gr->c1[i] );
	}
}

#pragma mark

@implementation HGradient

- (id) initWithR:(float)r G:(float)g B:(float)b A:(float)a R:(float)r2 G:(float)g2 B:(float)b2 A:(float)a2
{
	if( self = [super init] )
	{
		c1[0] =  r; c1[1] =  g; c1[2] =  b; c1[3] =  a;
		c2[0] = r2; c2[1] = g2; c2[2] = b2; c2[3] = a2;
	}
	
	return self;
}

@end


@implementation HighlightView

- (void) roundRectPath:(CGContextRef)con rect:(CGRect)aRect
{
	CGContextBeginPath(con);
		CGContextMoveToPoint(con, aRect.size.width - HALFLW, aRect.size.height/2);
		CGContextAddArcToPoint(con, aRect.size.width - HALFLW, aRect.size.height - HALFLW, aRect.size.width/2, aRect.size.height - HALFLW, CORNER);
		CGContextAddArcToPoint(con, HALFLW, aRect.size.height - HALFLW, HALFLW, aRect.size.height/2, CORNER);
		CGContextAddArcToPoint(con, HALFLW, HALFLW, aRect.size.width/2, HALFLW, CORNER);
		CGContextAddArcToPoint(con, aRect.size.width - HALFLW, HALFLW, aRect.size.width - HALFLW, aRect.size.height/2, CORNER);
	CGContextClosePath(con);
}

/*
CGGradientRef myGradient;
	CGColorSpaceRef myColorspace;
	size_t num_locations = 2;
	CGFloat locations[2] = { 0.0, 0.5 };
	CGFloat components[8] = { 1.0, 1.0, 1.0, 1.0,  // Start color
							  0.0, 0.5, 1.0, 1.0 }; // End color
	 
	myColorspace = CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB);
	myGradient = CGGradientCreateWithColorComponents (myColorspace, components,locations, num_locations);
	
					
	CGGradientRef myGradient2;
	CGColorSpaceRef myColorspace2;
	size_t num_locations2 = 2;
	CGFloat locations2[2] = { 0.0, 1.0 };
	CGFloat components2[8] = { 1.0, 1.0, 1.0, 0.1,  // Start color
							  1.0, 1.0, 1.0, 0.5 }; // End color
	 
	myColorspace2 = CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB);
	myGradient2 = CGGradientCreateWithColorComponents (myColorspace2, components2,locations2, num_locations2);
	
	
	
			

	 
		
		
		[self roundRectPath:con rect:aRect];

		CGContextSaveGState(con);
			CGContextClip(con);
			CGPoint myStartPoint, myEndPoint;
			myStartPoint.x = 0.0;
			myStartPoint.y = 0.0;
			myEndPoint.x = 0.0;
			myEndPoint.y = aRect.size.height;
			CGContextDrawLinearGradient(con, myGradient, myStartPoint, myEndPoint, kCGGradientDrawsAfterEndLocation);

			CGContextMoveToPoint(con, -aRect.size.width/2, aRect.size.height);
			CGContextAddCurveToPoint(con, -aRect.size.width/2, 0.0, aRect.size.width + aRect.size.width/2, 0.0, aRect.size.width + aRect.size.width/2, aRect.size.height);
			CGContextClip(con);
			CGPoint myStartPoint2, myEndPoint2;
			myStartPoint2.x = 0.0;
			//myStartPoint2.y = aRect.size.height/2;
			myStartPoint2.y = 0.0;
			myEndPoint2.x = 0.0;
			myEndPoint2.y = aRect.size.height;
			//CGContextSetBlendMode(con, kCGBlendModeColor);
			CGContextDrawLinearGradient(con, myGradient2, myStartPoint2, myEndPoint2, 0);
		CGContextRestoreGState(con);
		
		
		[self roundRectPath:con rect:aRect];
			
		CGContextSetRGBFillColor( con, 0, 0, 1, 0.5 );
		CGContextSetRGBStrokeColor( con, 0, 0, 0, 1.0 );
		CGContextSetLineWidth(con, LINEWIDTH);
		//CGContextSetShouldAntialias(con, false);
		//CGContextFillPath(con);	
		CGContextStrokePath(con);
		//CGContextDrawPath(con, kCGPathFillStroke);

*/

- (void) drawRect:(CGRect)aRect
{
	if( aRect.size.height != 1.0 )
	{
		/*CGContextRef myContext = (CGContext*)[[NSGraphicsContext currentContext] graphicsPort];

		CGContextClearRect( myContext, aRect );
		CGContextSetRGBFillColor( myContext, 1, 0, 0, 0.25 );

		if( 1 )
		{
			CGContextFillRect( myContext, CGRectMake( aRect.origin.x, aRect.origin.y, aRect.size.width - extraSpace, fontHeight ) );
			CGContextFillRect( myContext, CGRectMake( aRect.origin.x, aRect.origin.y + fontHeight, aRect.size.width, aRect.size.height - (fontHeight * 2) ) );
			CGContextFillRect( myContext, CGRectMake( aRect.origin.x + initialOffset, aRect.origin.y + (aRect.size.height - fontHeight), aRect.size.width - initialOffset, aRect.size.height ) );
		}
		else
		{
			CGContextFillRect( myContext, aRect );
			//CGContextSetRGBFillColor( myContext, 0, 0, 1, .5 );
			//CGContextFillRect( myContext, CGRectMake(0, 0, 100, 200) );
		}*/
		
		if( LI )
		{
			CGContextRef con = (CGContext*)[[NSGraphicsContext currentContext] graphicsPort];

			CGContextClearRect( con, aRect );
		
			HGradient* gr1 = [[HGradient alloc] initWithR:1.0 G:1.0 B:1.0 A:0.9 R:0.0 G:0.5 B:1.0 A:0.9];
			HGradient* gr2 = [[HGradient alloc] initWithR:1.0 G:1.0 B:1.0 A:0.1 R:1.0 G:1.0 B:1.0 A:0.5];
		
			CGPoint myStartPoint, myEndPoint;
			myStartPoint.x = 0.0;
			myStartPoint.y = 0.0;
			myEndPoint.x = 0.0;
			myEndPoint.y = aRect.size.height;
			CGPoint myStartPoint2, myEndPoint2;
			myStartPoint2.x = 0.0;
			myStartPoint2.y = 0.0;
			myEndPoint2.x = 0.0;
			myEndPoint2.y = aRect.size.height/2;
			static CGFunctionCallbacks callbacks = {0, &myCalculateShadingValues, NULL};
			float components[8] = { 0.0, 1.0, 0.0, 1.0,  0.0, 1.0, 0.0, 1.0 };
			
			CGShadingRef myGradient;
			//float locations[2] = { 0.0, 0.5 };
			float locations[2] = { 0.0, 1.0 };
			myGradient = CGShadingCreateAxial( CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB), myStartPoint2, myEndPoint2, CGFunctionCreate( gr1, 1, locations, 4, components, &callbacks ), YES, YES );
			
							
			CGShadingRef myGradient2;
			float locations2[2] = { 0.0, 1.0 };
			myGradient2 = CGShadingCreateAxial (CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB), myStartPoint, myEndPoint, CGFunctionCreate( gr2, 1, locations2, 4, components, &callbacks ), YES, YES );

		
		
		[self roundRectPath:con rect:aRect];

		CGContextSaveGState(con);
			CGContextClip(con);
			CGContextDrawShading( con, myGradient );

			CGContextMoveToPoint(con, -aRect.size.width/2, aRect.size.height);
			CGContextAddCurveToPoint(con, -aRect.size.width/2, 0.0, aRect.size.width + aRect.size.width/2, 0.0, aRect.size.width + aRect.size.width/2, aRect.size.height);
			CGContextClip(con);
						//CGContextSetBlendMode(con, kCGBlendModeColor);
			CGContextDrawShading( con, myGradient2 );
		CGContextRestoreGState(con);
		
		
		[self roundRectPath:con rect:aRect];
			
		//CGContextSetRGBFillColor( con, 0, 0, 1, 0.5 );
		CGContextSetRGBStrokeColor( con, 0, 0, 0, 1.0 );
		CGContextSetLineWidth(con, LINEWIDTH);
		//CGContextSetShouldAntialias(con, false);
		//CGContextFillPath(con);	
		CGContextStrokePath(con);
		//CGContextDrawPath(con, kCGPathFillStroke);
		
		
			
	

	//NSLog(@"%f %f\n", aRect.size.width, aRect.size.height);
			/*float w, h;
			w = aRect.size.width;
			h = aRect.size.height;
		 
			CGContextSelectFont( con, "Monaco", h/10, kCGEncodingFontSpecific );
			CGContextSetCharacterSpacing( con, 10 );
			CGContextSetTextDrawingMode( con, kCGTextFillStroke );
		 
			CGContextSetRGBFillColor( con, 0, 1, 0, .5 );
			CGContextSetRGBStrokeColor( con, 0, 0, 1, 1 );
			
			NSString* s = (NSString*)[LI getPriorityValue];
			
			CGContextShowTextAtPoint( con, 40, 0, [s UTF8String], [s length] ); 	*/
		}
	}
}

@end
