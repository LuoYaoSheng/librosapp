//
//  ReaderPageView.m
//  Libros
//
//  Created by Sean Hess on 1/24/13.
//  Copyright (c) 2013 Sean Hess. All rights reserved.
//

#import "ReaderPageView.h"
#import <CoreText/CoreText.h>

@interface ReaderPageView ()
@property (nonatomic) NSInteger position;
@property (nonatomic, strong) id ctFrame;
@end



@implementation ReaderPageView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        self.chapter = -1;
        self.page = -1;
    }
    return self;
}

-(void)setFrameFromCache:(ReaderFrameCache*)cache chapter:(NSInteger)chapter page:(NSInteger)page {
    if (self.chapter == chapter && self.page == page)
        return;
    
    self.chapter = chapter;
    self.page = page;
    self.ctFrame = [cache frameForChapter:chapter page:page];
    self.hidden = NO;
    [self setNeedsDisplay];
}

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    // Flip the coordinate system
    CGContextSetTextMatrix(context, CGAffineTransformIdentity);
    CGContextTranslateCTM(context, 0, self.bounds.size.height);
    CGContextScaleCTM(context, 1.0, -1.0);
    
    CTFrameDraw((__bridge CTFrameRef)self.ctFrame, context);
}
@end
