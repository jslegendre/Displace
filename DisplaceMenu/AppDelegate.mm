/*
 * Copyright (c) 2019 jslegendre / Xord. All rights reserved.
 *
 *  Released under "The GNU General Public License (GPL-2.0)"
 *
 *  This program is free software; you can redistribute it and/or modify it
 *  under the terms of the GNU General Public License as published by the
 *  Free Software Foundation; either version 2 of the License, or (at your
 *  option) any later version.
 *
 *  This program is distributed in the hope that it will be useful, but
 *  WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
 *  or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License
 *  for more details.
 *
 *  You should have received a copy of the GNU General Public License along
 *  with this program; if not, write to the Free Software Foundation, Inc.,
 *  59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
 *
 */
#import "AppDelegate.h"
#import "IOPoll.hpp"

@interface AppDelegate ()
@property (strong, nonatomic) NSStatusItem *statusItem;
@property (strong, nonatomic) NSUserDefaults *defaults;
@property (strong, nonatomic) NSImage *barIcon;
@property (strong, nonatomic) NSImage *barIconLocked;
@property (strong, nonatomic) NSPopover *prefsPopover;
@property (strong, nonatomic) NSString *mainBundlePath;
@end

@implementation AppDelegate
void *inStruct, *outStruct;
size_t smcIOArgSize;
IOPoll *ioPoll;
dispatch_queue_t gQueueDefault =
            dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
short axisXThreshold, axisYThreshold, axisZThreshold;
bool isXInverted, isYInverted, startAtLogin;
io_service_t serviceFramebuffer;

IOOptionBits rotate0 = (0x00000400 | (kIOScaleRotate0) << 16);
IOOptionBits rotate90 = (0x00000400 | (kIOScaleRotate90) << 16);
IOOptionBits rotate180 = (0x00000400 | (kIOScaleRotate180) << 16);
IOOptionBits rotate270 = (0x00000400 | (kIOScaleRotate270) << 16);

struct _axes {
  short x;
  short y;
  short z;
};

void rotate(IOOptionBits rotation) {
  kern_return_t ret = IOServiceRequestProbe(serviceFramebuffer, rotation);
  if(ret != kIOReturnSuccess) {
    NSLog(@"IOServiceRequestProbe for framebuffer returned %d", err_get_code(ret));
    throw std::invalid_argument("Could not rotate screen");
  }
}

/* TODO: Handle Z-Axis to block keyboard on
 2-in-1 devices when flipped */
void IOPollResultHandler() {
  struct _axes axes = { 0, 0, 0 };
  memcpy(&axes, outStruct, sizeof(struct _axes));
  if(abs(axes.y) > axisYThreshold || abs(axes.x) > axisXThreshold) {
    if(abs(axes.y) > abs(axes.x)) {
      if((isYInverted ? axes.y * -1 : axes.y) > 0) {
        rotate(rotate180);
      } else {
        rotate(rotate0);
      }
    } else if((isXInverted ? axes.x * -1 : axes.x) < 0) {
      rotate(rotate270);
    } else if((isXInverted ? axes.x * -1 : axes.x) > 0) {
      rotate(rotate90);
    }
  } else {
    rotate(rotate0);
  }
  
#ifdef DEBUG
  NSLog(@"Current axes: %d, %d, %d", axes.x, axes.y, axes.z);
#endif
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
  _prefsPopover = [NSPopover new];
  _prefsPopover.contentViewController = [[PrefsPopoverViewController alloc] initWithNibName:@"PrefsPopover" bundle:nil];
  
  _defaults = [[NSUserDefaults alloc] initWithSuiteName:
               [NSString stringWithUTF8String:"com.github.jslegendre.Displace"]];

  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(performTogglePopover)
                                               name:@"TogglePopover"
                                             object:nil];
  
  NSURL *launchURL =[[NSWorkspace sharedWorkspace] URLForApplicationWithBundleIdentifier:@"com.github.jslegendre.Displace"];
  _mainBundlePath = [[launchURL relativePath] stringByAppendingString:@"/Contents/MacOS/Displace"];
  
  serviceFramebuffer = IOServiceGetMatchingService(kIOMasterPortDefault, IOServiceMatching("IOFramebuffer"));
  if(!serviceFramebuffer) {
    [self runAlertForStdExceptionWithString:"Could not get IOFramebuffer IOService"];
  }
  _statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSSquareStatusItemLength];
  _statusItem.highlightMode = NO;
  
  _statusItem.button.target = self;
  _statusItem.button.action = @selector(toggleRotation:);

  /* NSStatusBarButton is a private subclass of NSButton used exclusively by NSStatusItem.
   * We can assume there will only be one instance of NSStatusItem (and therefor
   * NSStatusBarButton) so it is safe to swizzle this class as it will not affect other
   * NSButton instances. */
  method_exchangeImplementations(
                                 class_getInstanceMethod(objc_getClass("NSStatusBarButton"), @selector(rightMouseDown:)),
                                 class_getInstanceMethod(object_getClass(self), @selector(togglePopover:)));
  
  _barIcon = [NSImage imageNamed:@"bar-icon"];
  _barIconLocked = [NSImage imageNamed:@"bar-icon-locked"];
  [_barIcon setTemplate:YES];
  _statusItem.image = _barIcon;
  
  [self initDefaults];
  [self setupPoller];
  [self toggleRotation:nil];
}

- (void)performTogglePopover {
  if([_prefsPopover isShown]) {
    [_prefsPopover close];
    return;
  }
  
  [_prefsPopover showRelativeToRect:_statusItem.button.bounds
                             ofView:_statusItem.button
                      preferredEdge:NSMinYEdge];
}

- (void)togglePopover:(NSEvent *)ev {
  [[NSNotificationCenter defaultCenter]
   postNotificationName:@"TogglePopover"
   object:self];
}

-(void)runAlertForStdExceptionWithString:(const char*)what {
  NSAlert *alert = [NSAlert new];
  alert.messageText = @"Error!";
  alert.informativeText = [NSString stringWithUTF8String:what];
  [alert runModal];
  [NSApp terminate:nil];
}

-(void)setupPoller {
  smcIOArgSize = 40;
  inStruct = malloc(smcIOArgSize);
  memset(inStruct, 1, smcIOArgSize);
  outStruct = malloc(smcIOArgSize);
  memset(outStruct, 0, smcIOArgSize);
  try {
    ioPoll = new IOPoll("SMCMotionSensor", 5, inStruct, outStruct,
                        smcIOArgSize, smcIOArgSize, 1, &IOPollResultHandler);
  }
  catch (std::exception & e) {
    NSLog(@"[AppDelegate setupPoller] caught IOPoll::IOPoll");
    [self runAlertForStdExceptionWithString:e.what()];
    [NSApp terminate:nil];
  }
}

-(void)updateSharedVCValues {
  isXInverted = [_defaults boolForKey:@"axisXInverted"];
  isYInverted = [_defaults boolForKey:@"axisYInverted"];
  axisXThreshold = (short)[_defaults integerForKey:@"axisXThreshold"];
  axisYThreshold = (short)[_defaults integerForKey:@"axisYThreshold"];
  axisZThreshold = (short)[_defaults integerForKey:@"axisZThreshold"];
  if([_defaults boolForKey:@"startAtLogin"] != startAtLogin) {
    [self toggleStartAtLogin];
  }
}

-(void)initDefaults {
  if(![_defaults integerForKey:@"axisXThreshold"]) {
    [_defaults setInteger:50 forKey:@"axisXThreshold"];
    [_defaults setInteger:50 forKey:@"axisYThreshold"];
    [_defaults setInteger:150 forKey:@"axisZThreshold"];
    isXInverted = false;
    isYInverted = false;
  }
  startAtLogin = [_defaults boolForKey:@"startAtLogin"];
  [self updateSharedVCValues];
}

- (void)toggleRotation:(NSEvent *)ev {
  if([_prefsPopover isShown]) {
    [[NSNotificationCenter defaultCenter]
     postNotificationName:@"TogglePopover"
     object:self];
    return;
  }
  
  if(ioPoll->getPolling()) {
    ioPoll->stop();
    _statusItem.image = _barIconLocked;
    return;
  }
  
  _statusItem.image = _barIcon;
  dispatch_async(gQueueDefault, ^{
    try {
      ioPoll->start();
    } catch(std::exception & e) {
      NSLog(@"[AppDelegate toggleRotation:] caught IOPoll::start");
      dispatch_sync(dispatch_get_main_queue(), ^{
        [self runAlertForStdExceptionWithString:e.what()];
      });
    }
  });
}

-(void)uninstall {
  
  [NSTask launchedTaskWithLaunchPath:_mainBundlePath arguments:[NSArray arrayWithObject:@"uninstall"]];
}

-(void)toggleStartAtLogin {
  [NSTask launchedTaskWithLaunchPath:_mainBundlePath arguments:[NSArray arrayWithObject:
                                                                (startAtLogin ? @"stopStartAtLogin" : @"startAtLogin")]];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
  if(inStruct)
    free(inStruct);
  
  if(outStruct)
    free(outStruct);
  
  if(ioPoll)
    ioPoll->~IOPoll();
  
  if(serviceFramebuffer)
    IOServiceClose(serviceFramebuffer);
  
}

@end
