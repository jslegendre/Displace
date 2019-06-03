//
//  NSViewController+PrefsPopoverViewController.m
//  DisplaceMenu
//
//  Created by j on 5/30/19.
//  Copyright © 2019 j. All rights reserved.
//

#import "PrefsPopoverViewController.h"
#import "AppDelegate.h"

@interface PrefsPopoverViewController ()
@property (strong, nonatomic) NSUserDefaults *defaults;
@property (strong, nonatomic) AppDelegate *appDelegate;
@property (strong, nonatomic) NSView *mainView;
@property (weak) IBOutlet NSSlider *xThresholdSlider;
@property (weak) IBOutlet NSSlider *yThresholdSlider;
@property (weak) IBOutlet NSButton *xInvertedCheckbox;
@property (weak) IBOutlet NSButton *yInvertedCheckbox;
@property (weak) IBOutlet NSButton *startAtLoginCheckbox;
@property (weak) IBOutlet NSTextField *xThresholdValueLabel;
@property (weak) IBOutlet NSTextField *yThresholdValueLabel;
@property (weak) IBOutlet NSView *settingsView;
@end

@implementation PrefsPopoverViewController

-(void)viewDidLoad {
  _appDelegate = (AppDelegate*)[NSApp delegate];
  _defaults = [[NSUserDefaults alloc] initWithSuiteName:
               [NSString stringWithUTF8String:"com.github.jslegendre.Displace"]];
  
  [self updateUI];

  [_xThresholdSlider setTarget:self];
  [_yThresholdSlider setTarget:self];
  [_xInvertedCheckbox setTarget:self];
  [_yInvertedCheckbox setTarget:self];
  [_startAtLoginCheckbox setTarget:self];

  [_xThresholdSlider setContinuous:YES];
  [_yThresholdSlider setContinuous:YES];

  [_xThresholdSlider setAction:@selector(uiElementChanged)];
  [_yThresholdSlider setAction:@selector(uiElementChanged)];
  [_xInvertedCheckbox setAction:@selector(uiElementChanged)];
  [_yInvertedCheckbox setAction:@selector(uiElementChanged)];
  [_startAtLoginCheckbox setAction:@selector(uiElementChanged)];
  
  _mainView = [self view];
}

-(void)viewWillDisappear {
  if([self view] == _settingsView) {
    [self setView:_mainView];
  }
}

-(IBAction)quit:(id)sender {
  [NSApp terminate:nil];
}

-(IBAction)uninstall:(id)sender {
  [_appDelegate uninstall];
}

-(IBAction)toggleSettingsView:(id)sender {
  if([self view] == _settingsView) {
    [self setView:_mainView];
    return;
  }
  [self setView:_settingsView];
}

-(void)updateUI {
  NSInteger xThreshold = [_defaults integerForKey:@"axisXThreshold"];
  [_xThresholdValueLabel setStringValue:[@(xThreshold) stringValue]];
  [_xThresholdSlider setIntegerValue:xThreshold];
  
  BOOL xInverted = [_defaults boolForKey:@"axisXInverted"];
  [_xInvertedCheckbox setState:(xInverted ? NSControlStateValueOn : NSControlStateValueOff)];
  
  NSInteger yThreshold = [_defaults integerForKey:@"axisYThreshold"];
  [_yThresholdValueLabel setStringValue:[@(yThreshold) stringValue]];
  [_yThresholdSlider setIntegerValue:yThreshold];
  
  BOOL yInverted = [_defaults boolForKey:@"axisYInverted"];
  [_yInvertedCheckbox setState:(yInverted ? NSControlStateValueOn : NSControlStateValueOff)];
  
  BOOL startAtLogin = [_defaults boolForKey:@"startAtLogin"];
  [_startAtLoginCheckbox setState:(startAtLogin ? NSControlStateValueOn : NSControlStateValueOff)];
}

-(void)updateDefaults {
  [_defaults setInteger:[_xThresholdSlider integerValue] forKey:@"axisXThreshold"];
  [_defaults setInteger:[_yThresholdSlider integerValue] forKey:@"axisYThreshold"];
  [_defaults setBool:[_xInvertedCheckbox state] forKey:@"axisXInverted"];
  [_defaults setBool:[_yInvertedCheckbox state] forKey:@"axisYInverted"];
  [_defaults setBool:[_startAtLoginCheckbox state] forKey:@"startAtLogin"];
  [_defaults synchronize];
}

-(void)uiElementChanged {
  [self updateDefaults];
  [_appDelegate updateSharedVCValues];
  [self updateUI];
}

@end
