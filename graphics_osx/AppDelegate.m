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
}

- (void)processData {
    int off = 0;
    unsigned long len = [_data length];
    char *bytes = (char *)[_data bytes];
    
    while (off + 4 <= len) {
        unsigned int n = *(unsigned int *)(bytes + off);
        n = NSSwapBigIntToHost(n);
        NSLog(@"Length: %d\n", n);
        
        if (off + 4 + n > len) break;
        
        NSData *json_data = [NSData dataWithBytes:(bytes + off + 4) length:n];
        
        off += 4 + n;
        
        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:json_data options:0 error:nil];
        NSString *kind = [json objectForKey:@"kind"];
        if ([kind isEqualToString:@"setTitle"]) {
            [self.window setTitle:[json objectForKey:@"title"]];
        }
    }
    
    if (off > 0) {
        memmove(bytes, bytes + off, len - off);
        [_data setLength:(len - off)];
    }
}

- (void)handleInput:(NSNotification *)input {
    NSData *new_data = [input.userInfo objectForKey:NSFileHandleNotificationDataItem];
    NSLog(@"read %ld bytes: %@\n", (unsigned long)[new_data length], new_data);
    [_data appendData:new_data];
    [self processData];
    [_stdin readInBackgroundAndNotify];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    _data = [NSMutableData data];
    _stdin = [NSFileHandle fileHandleWithStandardInput];
    [_stdin readInBackgroundAndNotify];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleInput:) name:NSFileHandleReadCompletionNotification object:nil];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}

@end
