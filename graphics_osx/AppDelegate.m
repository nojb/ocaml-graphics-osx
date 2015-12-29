//
//  AppDelegate.m
//  graphics_osx
//
//  Created by Nicolas Ojeda Bar on 27/12/15.
//
//

#import <Foundation/NSByteOrder.h>

#import "AppDelegate.h"

@interface AppDelegate ()

@property (weak) IBOutlet NSWindow *window;
@end

@implementation AppDelegate {
    NSFileHandle *_stdin;
    NSMutableData *_data;

    char *buf;
    unsigned long len;
    unsigned int max;
}

- (void)processData {
    unsigned int off = 0;
    
    while (off + 4 <= max) {
        unsigned int n = NSSwapBigIntToHost(*(unsigned int *)(buf + off));
        NSLog(@"Kind: %d\n", n);
        
        switch (n) {
        case 0: { /* set title */
            if (off + 8 > max) break;
            unsigned int title_len = NSSwapBigIntToHost(*(unsigned int *)(buf + off + 4));
            if (off + 8 + title_len > max) break;
            NSString *title =
                [[NSString alloc] initWithBytes:(buf + off + 8) length:title_len encoding:NSUTF8StringEncoding];
            off += 8 + title_len;
            [self.window setTitle:title];
            break;
        }
        default:
            NSLog(@"Unrecognized kind: %d\n", n);
            break;
        }
    }
    
    if (off > 0) {
        memmove(buf, buf + off, max - off);
        max -= off;
    }
}

- (void)handleInput:(NSNotification *)input {
    NSData *new_data = [input.userInfo objectForKey:NSFileHandleNotificationDataItem];
    NSLog(@"read %ld bytes\n", [new_data length]);

    if (max + [new_data length] > len) {
        buf = realloc(buf, max + [new_data length]);
        len = max + [new_data length];
    }

    memcpy(buf + max, [new_data bytes], [new_data length]);
    max += [new_data length];

    [self processData];
    [_stdin readInBackgroundAndNotify];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    _data = [NSMutableData data];
    _stdin = [NSFileHandle fileHandleWithStandardInput];
    buf = malloc (4096);
    max = 0;
    len = 4096;
    [_stdin readInBackgroundAndNotify];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleInput:)
                                                 name:NSFileHandleReadCompletionNotification
                                               object:nil];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}

@end
