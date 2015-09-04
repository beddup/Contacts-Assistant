/*
 * QRCodeReaderViewController
 *
 * Copyright 2014-present Yannick Loriot.
 * http://yannickloriot.com
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 *
 */

#import "QRCodeReaderView.h"

@interface QRCodeReaderView ()
@property (nonatomic, strong) CAShapeLayer *overlay;

@end

@implementation QRCodeReaderView

- (id)initWithFrame:(CGRect)frame
{
  if ((self = [super initWithFrame:frame])) {
    [self addOverlay];
  }

  return self;
}

- (void)drawRect:(CGRect)rect
{
  CGRect innerRect = CGRectInset(rect, 50, 50);

  CGFloat minSize = MIN(innerRect.size.width, innerRect.size.height);
  if (innerRect.size.width != minSize) {
    innerRect.origin.x   += (innerRect.size.width - minSize) / 2;
    innerRect.size.width = minSize;
  }
  else if (innerRect.size.height != minSize) {
    innerRect.origin.y    += (innerRect.size.height - minSize) / 2;
    innerRect.size.height = minSize;
  }

  CGRect offsetRect = CGRectOffset(innerRect, 0, 15);

    UIBezierPath *path=    [UIBezierPath bezierPath];
    //left up corner
    [path moveToPoint:CGPointMake(CGRectGetMinX(offsetRect), CGRectGetMinY(offsetRect))];
    [path addLineToPoint:CGPointMake(CGRectGetMinX(offsetRect)+CGRectGetWidth(offsetRect)/6, CGRectGetMinY(offsetRect))];
    [path moveToPoint:CGPointMake(CGRectGetMinX(offsetRect), CGRectGetMinY(offsetRect))];
    [path addLineToPoint:CGPointMake(CGRectGetMinX(offsetRect), CGRectGetMinY(offsetRect)+CGRectGetHeight(offsetRect)/6)];

    //right up corner
    [path moveToPoint:CGPointMake(CGRectGetMaxX(offsetRect), CGRectGetMinY(offsetRect))];
    [path addLineToPoint:CGPointMake(CGRectGetMaxX(offsetRect)-CGRectGetWidth(offsetRect)/6, CGRectGetMinY(offsetRect))];
    [path moveToPoint:CGPointMake(CGRectGetMaxX(offsetRect), CGRectGetMinY(offsetRect))];
    [path addLineToPoint:CGPointMake(CGRectGetMaxX(offsetRect), CGRectGetMinY(offsetRect)+CGRectGetHeight(offsetRect)/6)];

    //right down corner
    [path moveToPoint:CGPointMake(CGRectGetMaxX(offsetRect), CGRectGetMaxY(offsetRect))];
    [path addLineToPoint:CGPointMake(CGRectGetMaxX(offsetRect)-CGRectGetWidth(offsetRect)/6, CGRectGetMaxY(offsetRect))];
    [path moveToPoint:CGPointMake(CGRectGetMaxX(offsetRect), CGRectGetMaxY(offsetRect))];
    [path addLineToPoint:CGPointMake(CGRectGetMaxX(offsetRect), CGRectGetMaxY(offsetRect)-CGRectGetHeight(offsetRect)/6)];

    //down left
    [path moveToPoint:CGPointMake(CGRectGetMinX(offsetRect), CGRectGetMaxY(offsetRect))];
    [path addLineToPoint:CGPointMake(CGRectGetMinX(offsetRect)+CGRectGetWidth(offsetRect)/6, CGRectGetMaxY(offsetRect))];
    [path moveToPoint:CGPointMake(CGRectGetMinX(offsetRect), CGRectGetMaxY(offsetRect))];
    [path addLineToPoint:CGPointMake(CGRectGetMinX(offsetRect), CGRectGetMaxY(offsetRect)-CGRectGetHeight(offsetRect)/6)];
    [path closePath];
    _overlay.path=path.CGPath;



}

#pragma mark - Private Methods

- (void)addOverlay
{
  _overlay = [[CAShapeLayer alloc] init];
  _overlay.backgroundColor = [UIColor clearColor].CGColor;
  _overlay.fillColor       = [UIColor clearColor].CGColor;
  _overlay.strokeColor     = [UIColor colorWithRed:81.0/255 green:167.0/255 blue:249.0/255 alpha:1].CGColor;
  _overlay.lineWidth       = 2.5;
  [self.layer addSublayer:_overlay];
}

@end
