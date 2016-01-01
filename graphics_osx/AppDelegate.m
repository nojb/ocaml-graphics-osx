//
//  AppDelegate.m
//  graphics_osx
//
//  Created by Nicolas Ojeda Bar on 27/12/15.
//
//

#import <Foundation/NSByteOrder.h>

#import "AppDelegate.h"

double ReadDouble(const char *buf)
{
    unsigned long long d = *(unsigned long long *)buf;
    d = NSSwapBigLongLongToHost(d);
    return *(double *)&d;
}

NSColor *ReadColor(const char *buf)
{
   double r = ReadDouble(buf);
   double g = ReadDouble(buf + 8);
   double b = ReadDouble(buf + 16);
   double a = ReadDouble(buf + 24);
   return [NSColor colorWithCalibratedRed:r green:g blue:b alpha:a];
}

NSPoint ReadPoint(const char *buf)
{
    double x = ReadDouble(buf);
    double y = ReadDouble(buf + 8);
    return NSMakePoint(x, y);
}

NSRect ReadRect(const char *buf)
{
    double x = ReadDouble(buf);
    double y = ReadDouble(buf + 8);
    double w = ReadDouble(buf + 16);
    double h = ReadDouble(buf + 24);
    return NSMakeRect(x, y, w, h);
}

int ReadInt(const char *buf)
{
    int n = *(int *)buf;
    return NSSwapBigIntToHost(n);
}

@implementation GraphicsView {
    NSColor *color;
    NSFont *font;
    NSImage *theImage;
}

- (void)awakeFromNib {
    // NSLog (@"awakeFromNib\n");
    color = [NSColor blackColor];
    font = [NSFont userFontOfSize: 0.0];
    NSSize size = NSMakeSize (2 * self.frame.size.width, 2 * self.frame.size.height);

    [NSBezierPath setDefaultLineCapStyle:NSRoundLineCapStyle];

    theImage = [[NSImage alloc] initWithSize: size];
    [theImage lockFocus];
    [[NSColor whiteColor] set];
    [NSBezierPath fillRect:NSMakeRect(0.0, 0.0, theImage.size.width, theImage.size.height)];
    [theImage unlockFocus];
}

- (void)setColor:(NSColor *)c {
    color = c;
}

- (void)setFontName:(NSString *)fontName {
    font = [NSFont fontWithName:fontName size:font.pointSize];
}

- (void)setFontSize:(float)fontSize {
    font = [NSFont fontWithName:font.fontName size:fontSize];
}

- (void)setDefaultLineWidth:(float)lineWidth {
    [NSBezierPath setDefaultLineWidth:lineWidth];
}

- (void)lockFocusInImage {
    [theImage lockFocus];
}

- (void)unlockFocusFromImage {
    [theImage unlockFocus];
}

- (void)strokeLineFromPoint:(NSPoint)from toPoint:(NSPoint)to {
    [color set];
    [NSBezierPath strokeLineFromPoint:from toPoint:to];
}

- (void)strokeRect:(NSRect)rect {
    [color set];
    [NSBezierPath strokeRect:rect];
}

- (void)fillRect:(NSRect)rect {
    [color set];
    [NSBezierPath fillRect:rect];
}

- (void)strokeOvalInRect:(NSRect)rect {
    [color set];
    [[NSBezierPath bezierPathWithOvalInRect:rect] stroke];
}

- (void)fillOvalInRect:(NSRect)rect {
    [color set];
    [[NSBezierPath bezierPathWithOvalInRect:rect] fill];
}

- (void)strokePoly:(NSPointArray)points count:(unsigned int)count {
    [color set];
    NSBezierPath *path = [NSBezierPath bezierPath];
    [path appendBezierPathWithPoints:points count:count];
    [path stroke];
}

- (void)drawString:(NSString *)string atPoint:(NSPoint)point {
    [font set];
    [color set];
    [string drawAtPoint:point withAttributes:[NSDictionary dictionary]];
}

- (void)strokeArcWithCenter:(NSPoint)c radius:(float)r startAngle:(float)a1 endAngle:(float)a2 {
    [color set];
    NSBezierPath *path = [NSBezierPath bezierPath];
    [path appendBezierPathWithArcWithCenter:c radius:r startAngle:a1 endAngle:a2];
    [path stroke];
}

- (void)drawRect:(NSRect)rect
{
    [theImage drawAtPoint:NSZeroPoint fromRect:rect operation:NSCompositeSourceOver fraction:1.0];
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
}

- (void)processData {
    unsigned int off = 0;

    [self.window.contentView lockFocusInImage];

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
            NSColor *c = ReadColor(buf + off + 4);
            off += 4 + 8*4;
            [self.window.contentView setColor:c];
            break;
        }
        case 4: { /* stroke line */
            // NSLog(@"stroke line\n");
            if (off + 36 > max) break;
            NSPoint p1 = ReadPoint(buf + off + 4);
            NSPoint p2 = ReadPoint(buf + off + 20);
            off += 36;
            [self.window.contentView strokeLineFromPoint:p1 toPoint:p2];
            break;
        }
        case 5: { /* stroke rect */
            // NSLog(@"stroke rect\n");
            if (off + 36 > max) break;
            NSRect r = ReadRect(buf + off + 4);
            off += 36;
            [self.window.contentView strokeRect:r];
            break;
        }
        case 8: { /* fill rect */
            // NSLog(@"fill rect\n");
            if (off + 36 > max) break;
            NSRect r = ReadRect(buf + off + 4);
            off += 36;
            [self.window.contentView fillRect:r];
            break;
        }
        case 6: { /* stroke oval */
            // NSLog(@"stroke oval\n");
            if (off + 36 > max) break;
            NSRect r = ReadRect(buf + off + 4);
            off += 36;
            [self.window.contentView strokeOvalInRect:r];
            break;
        }
        case 7: { /* fill oval */
            // NSLog(@"fill oval\n");
            if (off + 36 > max) break;
            NSRect r = ReadRect(buf + off + 4);
            off += 36;
            [self.window.contentView fillOvalInRect:r];
            break;
        }
        case 9: { /* stroke poly */
            // NSLog(@"stroke poly\n");
            if (off + 8 > max) break;
            unsigned int count = ReadInt(buf + off + 4);
            if (off + 8 + 16*count > max) break;
            NSPointArray a = calloc(count, sizeof(NSPoint));
            for (int i = 0; i < count; i ++) {
                a[i] = ReadPoint(buf + off + 8 + 16*i);
            }
            off += 8 + 16*count;
            [self.window.contentView strokePoly:a count:count];
            break;
        }
        case 10: { /* set font name */
            // NSLog(@"set font name\n");
            if (off + 8 > max) break;
            int n = ReadInt(buf + off + 4);
            if (off + 8 + n > max) break;
            NSString *fontName =
                [[NSString alloc] initWithBytes:(buf + off + 8) length:n encoding:NSUTF8StringEncoding];
            off += 8 + n;
            [self.window.contentView setFontName:fontName];
            break;
        }
        case 11: { /* set font size */
            // NSLog(@"set font size");
            if (off + 12 > max) break;
            double size = ReadDouble(buf + off + 4);
            off += 12;
            [self.window.contentView setFontSize:size];
            break;
        }
        case 12: { /* set line width */
            // NSLog(@"set line width");
            if (off + 12 > max) break;
            double size = ReadDouble(buf + off + 4);
            off += 12;
            [self.window.contentView setDefaultLineWidth:size];
            break;
        }
        case 13: { /* stroke arc */
            // NSLog(@"stroke arc");
            if (off + 4 + 8*5 > max) break;
            NSPoint c = ReadPoint(buf + 4);
            double r = ReadDouble(buf + 20);
            double a1 = ReadDouble(buf + 28);
            double a2 = ReadDouble(buf + 36);
            off += 4 + 8*5;
            [self.window.contentView strokeArcWithCenter:c radius:r startAngle:a1 endAngle:a2];
            break;
        }
        default:
            NSLog(@"Unrecognized kind: %d\n", n);
            break;
        }
    }

    [self.window.contentView unlockFocusFromImage];

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
    // NSLog(@"read %ld bytes (max=%d, len=%ld)\n", [new_data length], max, len);

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
