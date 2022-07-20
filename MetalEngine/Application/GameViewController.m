//
//  GameViewController.m
//  MetalEngine
//
//  Created by Lachlan Russell on 12/11/21.
//

#import "GameViewController.h"
#import "MetalEngine-Swift.h"
#import "Renderer.h"

@implementation GameViewController {
    MTKView *_view;
    Renderer *_renderer;
    NSMutableSet<NSNumber *> *_pressedKeys;
    NSWindowController *_prefsWindow;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    _prefsWindow = [PrefsWindowObjCBridge makePrefsWindow];
    [_prefsWindow showWindow:self];

    _view = (MTKView *)self.view;

    _view.device = MTLCreateSystemDefaultDevice();

    if (!_view.device) {
        NSLog(@"Metal is not supported on this device");
        self.view = [[NSView alloc] initWithFrame:self.view.frame];
        return;
    }

    _renderer = [[Renderer alloc] initWithMetalKitView:_view];

    [_renderer mtkView:_view drawableSizeWillChange:_view.bounds.size];

    _view.delegate = _renderer;
}

@end
