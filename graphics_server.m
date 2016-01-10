@import Cocoa;
@import CoreGraphics;

@interface MyClipView : NSClipView

@end

@implementation MyClipView

- (NSRect)constrainBoundsRect:(NSRect)proposedRect
{
    NSRect docRect = [self.documentView frame];
    NSRect rect = [super constrainBoundsRect:proposedRect];

    if (proposedRect.size.width >= docRect.size.width)
        rect.origin.x = floor(proposedRect.size.width - docRect.size.width) * -0.5f;

    if (proposedRect.size.height >= docRect.size.height)
        rect.origin.y = floor(proposedRect.size.height - docRect.size.height) * -0.5f;

    return rect;
}

@end

@interface GraphicsView : NSView

@end

@implementation GraphicsView
{
    CGContextRef bitmapContext;
}

- (instancetype)initWithBitmapContext:(CGContextRef)c {
    bitmapContext = c;
    size_t w = CGBitmapContextGetWidth(c);
    size_t h = CGBitmapContextGetHeight(c);
    NSRect frame = [[NSScreen mainScreen] convertRectFromBacking:NSMakeRect(0, 0, w, h)];
    return [super initWithFrame:frame];
}

- (void)drawRect:(NSRect)rect
{
    NSFrameRect(self.frame);
    CGContextRef c = [NSGraphicsContext currentContext].CGContext;
    CGImageRef img = CGBitmapContextCreateImage(bitmapContext);
    CGContextDrawImage(c, [self convertRectFromBacking:CGRectMake(0, 0, CGImageGetWidth(img), CGImageGetHeight(img))], img);
    CGImageRelease(img);
}

@end

@protocol GraphicsServerProtocol

- (void)setTitle:(NSString *)title;
- (void)setColor:(CGColorRef)c;
- (void)setFontName:(CFStringRef)fontName;
- (void)setFontSize:(CGFloat)fontSize;
- (void)setLineWidth:(CGFloat)lineWidth;
- (void)strokeLineFromPoint:(NSPoint)point1 toPoint:(NSPoint)point2;
- (void)strokeRect:(NSRect)rect;
- (void)fillRect:(NSRect)rect;
- (void)strokeOvalInRect:(NSRect)rect;
- (void)fillOvalInRect:(NSRect)rect;
- (void)strokePoly:(NSArray *)points;
- (void)drawString:(NSString *)string atPoint:(NSPoint)p;
- (void)strokeArcWithCenter:(NSPoint)c radius:(CGFloat)r startAngle:(CGFloat)a1 endAngle:(CGFloat)a2;
- (void)setNeedsDisplay:(BOOL)needsDisplay;

@end

@interface GraphicsServer : NSObject <GraphicsServerProtocol>

@property NSWindow *window;

@end

@implementation GraphicsServer
{
    CGContextRef bitmapContext;
}

- (instancetype)initWithSize:(NSSize)size
{
    self.window =
        [[NSWindow alloc] initWithContentRect:NSMakeRect(0, 0, size.width, size.height)
                                    styleMask:(NSTitledWindowMask | NSResizableWindowMask)
                                      backing:NSBackingStoreBuffered
                                        defer:NO];

    CGColorSpaceRef colorSpace = CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB);
    CGFloat scale = [[NSScreen mainScreen] backingScaleFactor];
    bitmapContext = CGBitmapContextCreate(NULL, scale * size.width, scale * size.height, 8, 0, colorSpace, kCGImageAlphaPremultipliedLast);
    CGContextScaleCTM(bitmapContext, scale, scale);
    CGColorSpaceRelease(colorSpace);

    NSFont *font = [NSFont userFontOfSize:0.0];
    [self setFontName:(__bridge CFStringRef)font.fontName];
    [self setFontSize:font.pointSize];
    CGContextSetLineCap(bitmapContext, kCGLineCapRound);
    // [self setColor:CGColorGetConstantColor(kCGColorWhite)];
    // CGContextFillRect(bitmapContext, CGRectInfinite);
    [self setColor:CGColorGetConstantColor(kCGColorBlack)];
    [self drawString:@"Hello, World" atPoint:CGPointMake(10,10)];

    NSScrollView *scrollView = [[NSScrollView alloc] initWithFrame:self.window.contentView.frame];
    [scrollView setContentView:[[MyClipView alloc] init]];
    scrollView.hasVerticalScroller = YES;
    scrollView.hasHorizontalScroller = YES;
    scrollView.borderType = NSNoBorder;
    scrollView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    scrollView.horizontalScrollElasticity = NSScrollElasticityAllowed;
    // scrollView.drawsBackground = NO;

    [scrollView setDocumentView: [[GraphicsView alloc] initWithBitmapContext:bitmapContext]];
    [self.window setContentView:scrollView];

    return self;
}

- (void)setTitle:(NSString *)title
{
    self.window.title = title;
}

- (void)setColor:(CGColorRef)c
{
    CGContextSetStrokeColorWithColor(bitmapContext, c);
    CGContextSetFillColorWithColor(bitmapContext, c);
}

- (void)setFontName:(CFStringRef)fontName
{
    CGFontRef font = CGFontCreateWithFontName(fontName);
    CGContextSetFont(bitmapContext, font);
    CGFontRelease(font);
}

- (void)setFontSize:(CGFloat)fontSize
{
    CGContextSetFontSize(bitmapContext, fontSize);
}

- (void)setLineWidth:(CGFloat)lineWidth
{
    CGContextSetLineWidth(bitmapContext, lineWidth);
}

- (void)strokeLineFromPoint:(CGPoint)from toPoint:(CGPoint)to
{
    CGContextMoveToPoint(bitmapContext, from.x, from.y);
    CGContextAddLineToPoint(bitmapContext, to.x, to.y);
    CGContextStrokePath(bitmapContext);
}

- (void)strokeRect:(CGRect)rect
{
    CGContextStrokeRect(bitmapContext, rect);
}

- (void)fillRect:(CGRect)rect
{
    CGContextFillRect(bitmapContext, rect);
}

- (void)strokeOvalInRect:(CGRect)rect
{
    CGContextAddEllipseInRect(bitmapContext, rect);
    CGContextStrokePath(bitmapContext);
}

- (void)fillOvalInRect:(CGRect)rect
{
    CGContextAddEllipseInRect(bitmapContext, rect);
    CGContextFillPath(bitmapContext);
}

- (void)strokePoly:(NSArray *)points
{
    CGPoint *arr = calloc(points.count, sizeof(CGPoint));
    for (int i = 0; i < points.count; i ++) {
        NSValue *v = [points objectAtIndex:i];
        arr[i] = v.pointValue;
    }
    CGContextAddLines(bitmapContext, arr, points.count);
    free(arr);
    CGContextStrokePath(bitmapContext);
}

- (void)drawString:(NSString *)str atPoint:(CGPoint)p
{
    CFStringRef string = (__bridge CFStringRef)str;
    CFAttributedStringRef attrStr = CFAttributedStringCreate(NULL, string, CFDictionaryCreate(NULL, NULL, NULL, 0, NULL, NULL));
    CTLineRef line = CTLineCreateWithAttributedString(attrStr);
    CGContextSetTextPosition(bitmapContext, p.x, p.y);
    CTLineDraw(line, bitmapContext);
    CFRelease(line);
}

- (void)strokeArcWithCenter:(CGPoint)c
                     radius:(CGFloat)r
                 startAngle:(CGFloat)a1
                   endAngle:(CGFloat)a2
{
    CGContextAddArc(bitmapContext, c.x, c.y, r, a1, a2, 1);
    CGContextStrokePath(bitmapContext);
}

- (void)setNeedsDisplay:(BOOL)needsDisplay
{
    [[self.window.contentView documentView] setNeedsDisplay:needsDisplay];
}

@end

int main ()
{
    @autoreleasepool {
        [NSApplication sharedApplication];
        [NSApp setActivationPolicy:NSApplicationActivationPolicyAccessory];

        // NSUserDefaults *standardDefaults = [NSUserDefaults standardUserDefaults];

        // NSInteger bitmapWidth = [standardDefaults integerForKey:@"width"];
        // NSInteger bitmapHeight = [standardDefaults integerForKey:@"height"];

        // if (!bitmapWidth) bitmapWidth = 600;
        // if (!bitmapHeight) bitmapHeight = 600;

        GraphicsServer *server = [[GraphicsServer alloc] initWithSize:NSMakeSize(600, 600)];

        NSConnection *conn = [NSConnection new];
        [conn setRootObject:server];

        if ([conn registerName:@"graphics_server"] == NO) {
            NSLog(@"Impossible to vend server");
        } else {
            NSLog(@"Server vended.");
        }

        [server.window cascadeTopLeftFromPoint:NSMakePoint(20,20)];
        [server.window makeKeyAndOrderFront:nil];

        [NSApp activateIgnoringOtherApps:YES];
        [NSApp run];
    }
    return EXIT_SUCCESS;
}
