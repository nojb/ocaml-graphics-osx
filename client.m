#define CAML_NAME_SPACE

#include <caml/mlvalues.h>
#include <caml/memory.h>

@import Cocoa;
@import CoreGraphics;

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

id server = nil;

void caml_open_graph(value unit)
{
    NSConnection *theConnection = [NSConnection connectionWithRegisteredName:@"graphics_server"
                                                                        host:nil];
    server = [theConnection rootProxy];
    [server setProtocolForProxy:@protocol(GraphicsServerProtocol)];
    return;
}

void caml_set_title(value title)
{
    CAMLparam1(title);

    @autoreleasepool {
        NSString *string = [[NSString alloc] initWithBytes:String_val(title) length:caml_string_length(title) encoding:NSUTF8StringEncoding];
        [server setTitle:string];
    }

    CAMLreturn0;
}

extern void run_server(void*);
extern int caml_startup(const char **);

void* run_ocaml(void *argv)
{
    caml_startup(argv);
    return NULL;
}

#include <pthread.h>

int main(int argc, const char **argv)
{
    NSLog(@"Hello, World!");
    pthread_t t;
    assert (pthread_create(&t, NULL, run_ocaml, argv) == 0);
    run_server (NULL);
    return 0;
}

// int main (int argc, const char * argv[])
// {
//     @autoreleasepool {
//         NSConnection *theConnection =
//             [NSConnection connectionWithRegisteredName:@"graphics_server" host:nil];
//         id server = [theConnection rootProxy];
//         [server setProtocolForProxy:@protocol(GraphicsServerProtocol)];
//         [server drawString:@"Yeah" atPoint:NSMakePoint(40, 40)];
//         [server setNeedsDisplay:YES];

//         NSLog(@"Work finished.");
//     }

//     return EXIT_SUCCESS;
// }
