//
//  AppDelegate.m
//  graphics_osx
//
//  Created by Nicolas Ojeda Bar on 27/12/15.
//
//

#import <Foundation/NSByteOrder.h>

#import "AppDelegate.h"

CGFloat ReadDouble(const char *buf)
{
    unsigned long long d = *(unsigned long long *)buf;
    d = NSSwapBigLongLongToHost(d);
    return *(double *)&d;
}

CGColorRef ReadColor(const char *buf)
{
   CGFloat r = ReadDouble(buf);
   CGFloat g = ReadDouble(buf + 8);
   CGFloat b = ReadDouble(buf + 16);
   CGFloat a = ReadDouble(buf + 24);
   return CGColorCreateGenericRGB(r, g, b, a);
}

CGPoint ReadPoint(const char *buf)
{
    CGFloat x = ReadDouble(buf);
    CGFloat y = ReadDouble(buf + 8);
    return CGPointMake(x, y);
}

CGRect ReadRect(const char *buf)
{
    CGFloat x = ReadDouble(buf);
    CGFloat y = ReadDouble(buf + 8);
    CGFloat w = ReadDouble(buf + 16);
    CGFloat h = ReadDouble(buf + 24);
    return CGRectMake(x, y, w, h);
}

int ReadInt(const char *buf)
{
    int n = *(int *)buf;
    return NSSwapBigIntToHost(n);
}

@implementation GraphicsView {
    CGContextRef theImage;
}

// - (void)awakeFromNib {
//     // NSLog (@"awakeFromNib\n");
//     color = [NSColor blackColor];
//     font = [NSFont userFontOfSize: 0.0];
//     NSSize size = NSMakeSize (2 * self.frame.size.width, 2 * self.frame.size.height);

//     [NSBezierPath setDefaultLineCapStyle:NSRoundLineCapStyle];

//     theImage = [[NSImage alloc] initWithSize: size];
//     [theImage lockFocus];
//     [[NSColor whiteColor] set];
//     [NSBezierPath fillRect:NSMakeRect(0.0, 0.0, theImage.size.width, theImage.size.height)];
//     [theImage unlockFocus];
// }

- (void)setImage:(CGContextRef)image
{
    theImage = image;
}

- (void)drawRect:(NSRect)rect
{
    CGContextRef c = [NSGraphicsContext currentContext].CGContext;
    CGImageRef img = CGBitmapContextCreateImage(theImage);
    CGContextDrawImage(c, NSMakeRect(0,0,CGImageGetWidth(img), CGImageGetHeight(img)), img);
//    [theImage drawAtPoint:NSZeroPoint fromRect:rect operation:NSCompositeSourceOver fraction:1.0];
    CGImageRelease(img);
}

@end

@interface AppDelegate ()

@property (weak) IBOutlet NSWindow *window;
@end

@implementation AppDelegate {
    NSFileHandle *standardInput;

    char *buf;
    unsigned long len;
    unsigned int max;

    CGContextRef bitmapContext;
}


- (void)setColor:(CGColorRef)c {
    CGContextSetStrokeColorWithColor(bitmapContext, c);
    CGContextSetFillColorWithColor(bitmapContext, c);
}

- (void)setFontName:(CFStringRef)fontName {
    CGFontRef font = CGFontCreateWithFontName(fontName);
    CGContextSetFont(bitmapContext, font);
    CGFontRelease(font);
}

- (void)setFontSize:(CGFloat)fontSize {
    CGContextSetFontSize(bitmapContext, fontSize);
}

- (void)setDefaultLineWidth:(CGFloat)lineWidth {
    CGContextSetLineWidth(bitmapContext, lineWidth);
}

- (void)strokeLineFromPoint:(CGPoint)from toPoint:(CGPoint)to {
    CGContextMoveToPoint(bitmapContext, from.x, from.y);
    CGContextAddLineToPoint(bitmapContext, to.x, to.y);
    CGContextStrokePath(bitmapContext);
}

- (void)strokeRect:(CGRect)rect {
    CGContextStrokeRect(bitmapContext, rect);
}

- (void)fillRect:(CGRect)rect {
    CGContextFillRect(bitmapContext, rect);
}

- (void)strokeOvalInRect:(CGRect)rect {
    CGContextAddEllipseInRect(bitmapContext, rect);
    CGContextStrokePath(bitmapContext);
}

- (void)fillOvalInRect:(CGRect)rect {
    CGContextAddEllipseInRect(bitmapContext, rect);
    CGContextFillPath(bitmapContext);
}

- (void)strokePoly:(CGPoint *)points count:(size_t)count {
    CGContextAddLines(bitmapContext, points, count);
    CGContextStrokePath(bitmapContext);
}

- (void)drawString:(CFStringRef)string atPoint:(CGPoint)p {
    CFAttributedStringRef attrStr = CFAttributedStringCreate(NULL, string, CFDictionaryCreate(NULL, NULL, NULL, 0, NULL, NULL));
    CTLineRef line = CTLineCreateWithAttributedString(attrStr);
    CGContextSetTextPosition(bitmapContext, p.x, p.y);
    CTLineDraw(line, bitmapContext);
    CFRelease(line);
}

- (void)strokeArcWithCenter:(CGPoint)c radius:(CGFloat)r startAngle:(CGFloat)a1 endAngle:(CGFloat)a2 {
    CGContextAddArc(bitmapContext, c.x, c.y, r, a1, a2, 1);
    CGContextStrokePath(bitmapContext);
}

- (void)processData {
    unsigned int off = 0;

    while (off + 4 <= max) {
        unsigned int n = ReadInt(buf + off);
        // NSLog(@"Kind: %d (off=%d, max=%d, len=%ld)\n", n, off, max, len);
        switch (n) {
        case 0: { /* set title */
            // NSLog(@"set title\n");
            if (off + 8 > max) break;
            unsigned int title_len = ReadInt(buf + off + 4);
            if (off + 8 + title_len > max) break;
            NSString *title =
                [[NSString alloc] initWithBytes:(buf + off + 8) length:title_len encoding:NSUTF8StringEncoding];
            off += 8 + title_len;
            self.window.title = title;
            break;
        }
        case 2: { /* set color */
            // NSLog(@"set color\n");
            if (off + 4 + 8*4 > max) break;
            CGColorRef c = ReadColor(buf + off + 4);
            off += 4 + 8*4;
            [self setColor:c];
            break;
        }
        case 4: { /* stroke line */
            // NSLog(@"stroke line\n");
            if (off + 36 > max) break;
            CGPoint p1 = ReadPoint(buf + off + 4);
            CGPoint p2 = ReadPoint(buf + off + 20);
            off += 36;
            [self strokeLineFromPoint:p1 toPoint:p2];
            break;
        }
        case 5: { /* stroke rect */
            // NSLog(@"stroke rect\n");
            if (off + 36 > max) break;
            CGRect r = ReadRect(buf + off + 4);
            off += 36;
            [self strokeRect:r];
            break;
        }
        case 8: { /* fill rect */
            // NSLog(@"fill rect\n");
            if (off + 36 > max) break;
            CGRect r = ReadRect(buf + off + 4);
            off += 36;
            [self fillRect:r];
            break;
        }
        case 6: { /* stroke oval */
            // NSLog(@"stroke oval\n");
            if (off + 36 > max) break;
            CGRect r = ReadRect(buf + off + 4);
            off += 36;
            [self strokeOvalInRect:r];
            break;
        }
        case 7: { /* fill oval */
            // NSLog(@"fill oval\n");
            if (off + 36 > max) break;
            CGRect r = ReadRect(buf + off + 4);
            off += 36;
            [self fillOvalInRect:r];
            break;
        }
        case 9: { /* stroke poly */
            // NSLog(@"stroke poly\n");
            if (off + 8 > max) break;
            unsigned int count = ReadInt(buf + off + 4);
            if (off + 8 + 16*count > max) break;
            CGPoint *a = calloc(count, sizeof(CGPoint));
            for (int i = 0; i < count; i ++) {
                a[i] = ReadPoint(buf + off + 8 + 16*i);
            }
            off += 8 + 16*count;
            [self strokePoly:a count:count];
            break;
        }
        case 10: { /* set font name */
            // NSLog(@"set font name\n");
            if (off + 8 > max) break;
            int n = ReadInt(buf + off + 4);
            if (off + 8 + n > max) break;
            CFStringRef fontName = CFStringCreateWithBytes(NULL, (const unsigned char *)(buf + off + 8), n, kCFStringEncodingUTF8, false);
            off += 8 + n;
            [self setFontName:fontName];
            CFRelease(fontName);
            break;
        }
        case 11: { /* set font size */
            // NSLog(@"set font size");
            if (off + 12 > max) break;
            CGFloat size = ReadDouble(buf + off + 4);
            off += 12;
            [self setFontSize:size];
            break;
        }
        case 12: { /* set line width */
            // NSLog(@"set line width");
            if (off + 12 > max) break;
            CGFloat size = ReadDouble(buf + off + 4);
            off += 12;
            [self setDefaultLineWidth:size];
            break;
        }
        case 13: { /* stroke arc */
            // NSLog(@"stroke arc");
            if (off + 4 + 8*5 > max) break;
            NSPoint c = ReadPoint(buf + 4);
            CGFloat r = ReadDouble(buf + 20);
            CGFloat a1 = ReadDouble(buf + 28);
            CGFloat a2 = ReadDouble(buf + 36);
            off += 4 + 8*5;
            [self strokeArcWithCenter:c radius:r startAngle:a1 endAngle:a2];
            break;
        }
        default:
            NSLog(@"Unrecognized kind: %d\n", n);
            break;
        }
    }

    if (off > 0) {
        self.window.contentView.needsDisplay = YES;

        if (off < max) {
            memmove(buf, buf + off, max - off);
            max -= off;
        } else {
            max = 0;
        }
    }
}

- (void)handleInput:(NSNotification *)input {
    NSData *new_data = [input.userInfo objectForKey:NSFileHandleNotificationDataItem];
    NSLog(@"read %ld bytes (max=%d, len=%ld)\n", [new_data length], max, len);

    if (max + [new_data length] > len) {
        buf = realloc(buf, max + [new_data length]);
        len = max + [new_data length];
    }

    memcpy(buf + max, [new_data bytes], [new_data length]);
    max += [new_data length];

    [self processData];
    [standardInput readInBackgroundAndNotify];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    CGColorSpaceRef colorSpace = CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB);
    bitmapContext =
        CGBitmapContextCreate(NULL, 2 * self.window.frame.size.width, 2 * self.window.frame.size.height, 8, 0, colorSpace, kCGImageAlphaPremultipliedLast);
    CGColorSpaceRelease(colorSpace);

    NSFont *font = [NSFont userFontOfSize:0.0];
    [self setFontName:(__bridge CFStringRef)font.fontName];
    [self setFontSize:font.pointSize];
    CGContextSetLineCap(bitmapContext, kCGLineCapRound);
    [self setColor:CGColorGetConstantColor(kCGColorWhite)];
    CGContextFillRect(bitmapContext, CGRectInfinite);
    [self setColor:CGColorGetConstantColor(kCGColorBlack)];

    [self.window.contentView setImage:bitmapContext];

    standardInput = [NSFileHandle fileHandleWithStandardInput];
    buf = malloc (1024 * 128);
    max = 0;
    len = 1024 * 128;
    [standardInput readInBackgroundAndNotify];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleInput:)
                                                 name:NSFileHandleReadCompletionNotification
                                               object:nil];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}

@end
