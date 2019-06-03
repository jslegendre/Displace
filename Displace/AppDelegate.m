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
#import <ServiceManagement/SMLoginItem.h>

@interface AppDelegate ()
@property (strong, nonatomic) NSUserDefaults *defaults;
@end

@implementation AppDelegate
-(void)quitLoginItem {
  AppleEvent event = {typeNull, nil};
  const char *bundleIDString = "com.github.jslegendre.DisplaceMenu";

  OSStatus result = AEBuildAppleEvent(kCoreEventClass, kAEQuitApplication, typeApplicationBundleID, bundleIDString, strlen(bundleIDString), kAutoGenerateReturnID, kAnyTransactionID, &event, NULL, "");

  if (result == noErr) {
    result = AESendMessage(&event, NULL, kAEAlwaysInteract|kAENoReply, kAEDefaultTimeout);
    AEDisposeDesc(&event);
  }
}

-(void)startAtLogin {
  if(!SMLoginItemSetEnabled(CFSTR("com.github.jslegendre.DisplaceMenu"), true)) {
    NSAlert *alert = [NSAlert new];
    alert.messageText = @"Could not Enable Start at Login";
    [NSApp activateIgnoringOtherApps:YES];
    [_defaults setBool:NO forKey:@"startAtLogin"];
    [_defaults synchronize];
    [alert runModal];
    return;
  }
  [_defaults setBool:YES forKey:@"startAtLogin"];
  [_defaults synchronize];
}

-(void)stopStartAtLogin {
  if(!SMLoginItemSetEnabled(CFSTR("com.github.jslegendre.DisplaceMenu"), false)) {
    NSAlert *alert = [NSAlert new];
    alert.messageText = @"Could not Enable Start at Login";
    [NSApp activateIgnoringOtherApps:YES];
    [_defaults setBool:NO forKey:@"startAtLogin"];
    [_defaults synchronize];
    [alert runModal];
    return;
  }
  [_defaults setBool:NO forKey:@"startAtLogin"];
  [_defaults synchronize];
}

-(void)uninstallDisplaceMenu {
  if([_defaults boolForKey:@"startAtLogin"]) {
    [self stopStartAtLogin];
  } else {
    [self quitLoginItem];
  }
  
  NSDictionary * dict = [_defaults dictionaryRepresentation];
  for (id key in dict) {
    [_defaults removeObjectForKey:key];
  }
  [_defaults synchronize];
}

-(void)uninstall {
  NSAlert *alert = [NSAlert new];
  alert.messageText = @"Uninstall Displace?";
  alert.informativeText = @"Are you sure you want to uninstall Displace?";
  [alert addButtonWithTitle:@"Cancel"];
  [alert addButtonWithTitle:@"Yes"];
  
  [NSApp activateIgnoringOtherApps:YES];
  NSModalResponse responseTag = [alert runModal];
  if (responseTag == NSAlertSecondButtonReturn) {
    [self uninstallDisplaceMenu];
  }
  
  //[NSApp terminate:nil];
}

-(void)launchLoginItem {
  NSString *bundlePath = [[NSBundle mainBundle] bundlePath];
  NSString *statusItemPath = [bundlePath stringByAppendingString:@"/Contents/Library/LoginItems/DisplaceMenu.app"];
  [[NSWorkspace new] launchApplication:statusItemPath];
}

-(void)askLoginPermission {
  NSAlert *alert = [NSAlert new];
  alert.messageText = @"Would you like Displace to start at login?";
  [alert addButtonWithTitle:@"Yes"];
  [alert addButtonWithTitle:@"No"];
  
  [NSApp activateIgnoringOtherApps:YES];
  NSModalResponse responseTag = [alert runModal];
  if (responseTag == NSAlertFirstButtonReturn) {
    [self startAtLogin];
    return;
  }
  
  [self launchLoginItem];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
  _defaults = [NSUserDefaults standardUserDefaults];
  if([[[NSProcessInfo processInfo] arguments] containsObject:@"uninstall"]) {
    [self uninstall]; //Does not return
    [NSApp terminate:nil];
  }
  
  if([[[NSProcessInfo processInfo] arguments] containsObject:@"stopStartAtLogin"]) {
    [self stopStartAtLogin];
    [self launchLoginItem];
    [NSApp terminate:nil];
  }
  
  if([[[NSProcessInfo processInfo] arguments] containsObject:@"startAtLogin"]) {
    [self quitLoginItem];
    [self startAtLogin];
    [NSApp terminate:nil];
  }
  
  if(![_defaults boolForKey:@"hasRun"]) {
    [_defaults setBool:YES forKey:@"hasRun"];
    [_defaults synchronize];
    [self askLoginPermission];
  } else {
    [self launchLoginItem];
  }
  
  [NSApp terminate:nil];
}

@end
