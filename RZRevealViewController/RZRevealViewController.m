//
//  RZRevealViewController.m
//  Raizlabs
//
//  Created by Joe Goullaud on 2/17/12.
//  Copyright (c) 2012 Raizlabs. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "RZRevealViewController.h"

// Private pan gesture subclass to prevent overriding delegate externally

@interface RZRevealPanGestureRecognizer : UIPanGestureRecognizer

- (id)initWithTarget:(id)target action:(SEL)action delegate:(id<UIGestureRecognizerDelegate>)delegate;

@end

@implementation RZRevealPanGestureRecognizer

- (id)initWithTarget:(id)target action:(SEL)action delegate:(id<UIGestureRecognizerDelegate>)delegate
{
    self = [super initWithTarget:target action:action];
    if (self)
    {
        [super setDelegate:delegate];
    }
    return self;
}

- (void)setDelegate:(id<UIGestureRecognizerDelegate>)delegate
{
    @throw [NSException exceptionWithName:@"RZRevealViewControllerException" reason:@"The delegate of RZRevealViewController's pan gesture recognizer may not be changed" userInfo:nil];
}

@end

@interface RZRevealScreenEdgePanGestureRecognizer : UIScreenEdgePanGestureRecognizer

- (id)initWithTarget:(id)target action:(SEL)action delegate:(id<UIGestureRecognizerDelegate>)delegate;

@end

@implementation RZRevealScreenEdgePanGestureRecognizer

- (id)initWithTarget:(id)target action:(SEL)action delegate:(id<UIGestureRecognizerDelegate>)delegate
{
    self = [super initWithTarget:target action:action];
    if (self)
    {
        [super setDelegate:delegate];
    }
    return self;
}

- (void)setDelegate:(id<UIGestureRecognizerDelegate>)delegate
{
    @throw [NSException exceptionWithName:@"RZRevealViewControllerException" reason:@"The delegate of RZRevealViewController's pan gesture recognizer may not be changed" userInfo:nil];
}

@end

// -----------

@interface RZRevealViewController ()

@property (assign, nonatomic, readwrite, getter = isLeftHiddenViewControllerRevealed) BOOL leftHiddenViewControllerRevealed;
@property (assign, nonatomic, readwrite, getter = isRightHiddenViewControllerRevealed) BOOL rightHiddenViewControllerRevealed;
@property (strong, readwrite, nonatomic) UIPanGestureRecognizer *revealPanGestureRecognizer;
@property (strong, nonatomic) UITapGestureRecognizer *hideTapGestureRecognizer;

@property (nonatomic, strong) UIScreenEdgePanGestureRecognizer *revealEdgePanRecognizer;
@property (nonatomic, assign) BOOL usesEdgeGestureRecognizer;
@property (nonatomic, assign) UIRectEdge dragEdges;

- (void)setupRevealViewController;
- (void)initializeGestureRecognizers;

- (void)showHiddenViewController:(RZRevealViewControllerPosition)position offset:(CGFloat)offset duration:(CGFloat)duration animated:(BOOL)animated;
- (void)peekHiddenViewController:(RZRevealViewControllerPosition)position offset:(CGFloat)offset duration:(CGFloat)duration animated:(BOOL)animated;
- (void)hideHiddenViewController:(RZRevealViewControllerPosition)position duration:(CGFloat)duration animated:(BOOL)animated;

- (void)revealPanTriggered:(UIPanGestureRecognizer*)panGR;
- (void)hideTapTriggered:(UITapGestureRecognizer*)tapGR;

@end

@implementation RZRevealViewController

- (id)initWithMainViewController:(UIViewController*)mainVC
        leftHiddenViewController:(UIViewController*)leftVC
       rightHiddenViewController:(UIViewController*)rightVC
{
    return [self initWithMainViewController:mainVC
                   leftHiddenViewController:leftVC
                  rightHiddenViewController:rightVC
                            usesEdgeGesture:NO];
}

- (id)initWithMainViewController:(UIViewController*)mainVC
        leftHiddenViewController:(UIViewController*)leftVC
       rightHiddenViewController:(UIViewController*)rightVC
                 usesEdgeGesture:(BOOL)usesEdgeGesture
{
    self = [super init];
    if (self) {
        
        self.usesEdgeGestureRecognizer = usesEdgeGesture;
        self.dragEdges = ((leftVC != nil) ? UIRectEdgeLeft : 0) | ((rightVC != nil) ? UIRectEdgeRight : 0);
        
        [self setupRevealViewController];
        
        self.mainViewController = mainVC;
        self.leftHiddenViewController = leftVC;
        self.rightHiddenViewController = rightVC;
    }
    return self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        [self setupRevealViewController];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self setupRevealViewController];
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

- (void)setupRevealViewController
{
    self.revealEnabled = YES;
    self.peekEnabled = NO;

    [self initializeGestureRecognizers];

    self.revealOffset = 0;
    self.quickPeekHiddenOffset = self.view.bounds.size.width * 0.25;
    self.peekHiddenOffset = self.view.bounds.size.width * 0.5;
    self.showHiddenOffset = self.view.bounds.size.width  * 0.85;
    self.maxDragDistance = self.view.bounds.size.width;
}

- (void)initializeGestureRecognizers
{
    if(self.usesEdgeGestureRecognizer && self.revealEdgePanRecognizer == nil)
    {
        self.revealEdgePanRecognizer = [[RZRevealScreenEdgePanGestureRecognizer alloc] initWithTarget:self action:@selector(revealPanTriggered:) delegate:self];
        self.revealEdgePanRecognizer.edges = self.dragEdges;
        [self.view addGestureRecognizer:self.revealEdgePanRecognizer];
    }

    if (nil == self.revealPanGestureRecognizer)
    {
        self.revealPanGestureRecognizer = [[RZRevealPanGestureRecognizer alloc] initWithTarget:self action:@selector(revealPanTriggered:) delegate:self];
        [self.view addGestureRecognizer:self.revealPanGestureRecognizer];
    }

    if(self.usesEdgeGestureRecognizer)
    {
        self.revealPanGestureRecognizer.enabled = NO;
    }
}

#pragma mark - View lifecycle
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self initializeGestureRecognizers];
    
    if (self.mainViewController)
    {
        self.mainViewController.view.frame = self.view.bounds;
        self.mainViewController.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        
    }
    
    if(self.mainVCWrapperView == nil){
        self.mainVCWrapperView = [[UIView alloc] initWithFrame:self.view.bounds];
    }
    self.mainVCWrapperView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.mainVCWrapperView setClipsToBounds:NO];
    
    self.hideTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideTapTriggered:)];
    self.hideTapGestureRecognizer.enabled = NO;
    [self.mainVCWrapperView addGestureRecognizer:self.hideTapGestureRecognizer];
    
    [self addShadow];
}


- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    if (nil == self.mainViewController)
    {
        return UIInterfaceOrientationPortrait == interfaceOrientation;
    }
    
    // Return YES for supported orientations
    return [self.mainViewController shouldAutorotateToInterfaceOrientation:interfaceOrientation];
}

- (void) addShadow
{
    CALayer* wrapperLayer = self.mainVCWrapperView.layer;
    wrapperLayer.shadowPath = [[UIBezierPath bezierPathWithRect:wrapperLayer.bounds] CGPath];
    wrapperLayer.shadowRadius = 8.0f;
    wrapperLayer.shadowOpacity = 0.75f;
    wrapperLayer.shadowColor = [[UIColor blackColor] CGColor];
}

#pragma mark - Property Accessors

- (void)setMainViewController:(UIViewController *)mainViewController
{
    if (mainViewController == _mainViewController)
    {
        return;
    }
    
    CGRect frame = self.view.bounds;
    CGAffineTransform transform = CGAffineTransformIdentity;
    
    if (_mainViewController)
    {
        frame = _mainViewController.view.frame;
        transform = _mainViewController.view.transform;
    }
    
    [_mainViewController.view removeFromSuperview];
    [_mainViewController willMoveToParentViewController:nil];
    [_mainViewController removeFromParentViewController];
    _mainViewController = mainViewController;
    
    if (mainViewController)
    {
        [self addChildViewController:mainViewController];
        mainViewController.view.frame = frame;
        mainViewController.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        mainViewController.view.transform = transform;
    }
    
    if(self.mainVCWrapperView == nil)
    {
        self.mainVCWrapperView = [[UIView alloc] initWithFrame:frame];
    }
    
    if([self.mainVCWrapperView superview] != nil)
    {
        [self.mainVCWrapperView removeFromSuperview];
    }
    
    [self.mainVCWrapperView addSubview:self.mainViewController.view];
    [self.view addSubview:self.mainVCWrapperView];
}

- (void)setLeftHiddenViewController:(UIViewController *)hiddenViewController
{
    if (hiddenViewController == _leftHiddenViewController)
    {
        return;
    }
    
    CGRect frame = _leftHiddenViewController.view.frame;
    [_leftHiddenViewController.view removeFromSuperview];
    [_leftHiddenViewController willMoveToParentViewController:nil];
    [_leftHiddenViewController removeFromParentViewController];
    _leftHiddenViewController = hiddenViewController;
    
    if (hiddenViewController)
    {
        
        if (self.leftHiddenViewControllerRevealed)
        {
            [self addChildViewController:hiddenViewController];
            hiddenViewController.view.frame = frame;
            hiddenViewController.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
            [self.view insertSubview:hiddenViewController.view belowSubview:self.mainVCWrapperView];
            [hiddenViewController didMoveToParentViewController:self];
        }
    }
}

- (void)setRightHiddenViewController:(UIViewController *)hiddenViewController
{
    if (hiddenViewController == _rightHiddenViewController)
    {
        return;
    }
    
    CGRect frame = _rightHiddenViewController.view.frame;
    [_rightHiddenViewController.view removeFromSuperview];
    [_rightHiddenViewController willMoveToParentViewController:nil];
    [_rightHiddenViewController removeFromParentViewController];
    _rightHiddenViewController = hiddenViewController;
    
    if (hiddenViewController)
    {        
        if (self.rightHiddenViewControllerRevealed)
        {
            [self addChildViewController:hiddenViewController];
            hiddenViewController.view.frame = frame;
            hiddenViewController.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
            [self.view insertSubview:hiddenViewController.view belowSubview:self.mainVCWrapperView];
            [hiddenViewController didMoveToParentViewController:self];
        }
    }
}

- (void)setAllowMainVCInteractionWhileRevealed:(BOOL)allowMainVCInteractionWhileRevealed
{
    _allowMainVCInteractionWhileRevealed = allowMainVCInteractionWhileRevealed;
    if (self.leftHiddenViewControllerRevealed || self.rightHiddenViewControllerRevealed)
    {
        self.mainViewController.view.userInteractionEnabled = allowMainVCInteractionWhileRevealed;
        self.hideTapGestureRecognizer.enabled = !allowMainVCInteractionWhileRevealed;
        self.revealPanGestureRecognizer.enabled = YES;
    }
    
}

#pragma mark - Show/Peek/Hide Hidden VC methods

- (void)showLeftHiddenViewControllerAnimated:(BOOL)animated
{
    [self showLeftHiddenViewControllerWithOffset:self.showHiddenOffset animated:YES];
}

- (void)showRightHiddenViewControllerAnimated:(BOOL)animated
{
    [self showRightHiddenViewControllerWithOffset:self.showHiddenOffset animated:YES];
}

- (void)showLeftHiddenViewControllerWithOffset:(CGFloat)offset animated:(BOOL)animated;
{
    [self showHiddenViewController:RZRevealViewControllerPositionLeft offset:offset duration:0.25 animated:animated];
}

- (void)showRightHiddenViewControllerWithOffset:(CGFloat)offset animated:(BOOL)animated;
{
    [self showHiddenViewController:RZRevealViewControllerPositionRight offset:offset duration:0.25 animated:animated];
}

- (void)showHiddenViewController:(RZRevealViewControllerPosition)position offset:(CGFloat)offset duration:(CGFloat)duration animated:(BOOL)animated
{
    UIViewController* hiddenVC = nil;
    if (position == RZRevealViewControllerPositionLeft)
    {
        hiddenVC = self.leftHiddenViewController;
    }
    else
    {
        offset = -offset;
        hiddenVC = self.rightHiddenViewController;
    }
    
    if (hiddenVC)
    {
        if (hiddenVC.parentViewController == nil)
        {
            [self addChildViewController:hiddenVC];
            hiddenVC.view.frame = self.view.bounds;
            hiddenVC.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
            [self.view insertSubview:hiddenVC.view belowSubview:self.mainVCWrapperView];
            [hiddenVC didMoveToParentViewController:self];
        }
        
        if (animated)
        {
            [UIView animateWithDuration:0.25
                                  delay:0
                                options:UIViewAnimationOptionCurveEaseOut
                             animations:^{
                                 [self.mainViewController revealController:self willShowHiddenController:self.leftHiddenViewController position:position];
                                 [hiddenVC revealController:self willShowHiddenController:self.leftHiddenViewController position:position];
                                 
                                 if (self.delegate && [self.delegate respondsToSelector:@selector(revealController:willShowHiddenController:position:)])
                                 {
                                     [self.delegate revealController:self willShowHiddenController:hiddenVC position:position];
                                 }
                                 
                                 self.mainVCWrapperView.transform = CGAffineTransformMakeTranslation(offset, 0);
                             }
                             completion:^(BOOL finished) {
                                 [self setViewControllerRevealed:YES forPosition:position];
                                 
                                 [self.mainViewController revealController:self didShowHiddenController:hiddenVC position:position];
                                 [self.leftHiddenViewController revealController:self didShowHiddenController:hiddenVC position:position];
                                 
                                 if (self.delegate && [self.delegate respondsToSelector:@selector(revealController:didShowHiddenController:position:)])
                                 {
                                     [self.delegate revealController:self didShowHiddenController:hiddenVC position:position];
                                 }
                             }];
        }
        else
        {
            [self.mainViewController revealController:self willShowHiddenController:hiddenVC position:position];
            [self.leftHiddenViewController revealController:self willShowHiddenController:hiddenVC position:position];
            
            if (self.delegate && [self.delegate respondsToSelector:@selector(revealController:willShowHiddenController:position:)])
            {
                [self.delegate revealController:self willShowHiddenController:hiddenVC position:position];
            }
            
            self.mainVCWrapperView.transform = CGAffineTransformMakeTranslation(offset, 0);
            [self setViewControllerRevealed:YES forPosition:position];
            
            [self.mainViewController revealController:self didShowHiddenController:hiddenVC position:position];
            [self.leftHiddenViewController revealController:self didShowHiddenController:hiddenVC position:position];
            
            if (self.delegate && [self.delegate respondsToSelector:@selector(revealController:didShowHiddenController:position:)])
            {
                [self.delegate revealController:self didShowHiddenController:hiddenVC position:position];
            }
        }
    }
}

- (void)peekLeftHiddenViewControllerAnimated:(BOOL)animated
{
    [self peekLeftHiddenViewControllerWithOffset:self.peekHiddenOffset animated:animated];
}

- (void)peekRightHiddenViewControllerAnimated:(BOOL)animated
{
    [self peekRightHiddenViewControllerWithOffset:self.peekHiddenOffset animated:animated];
}

- (void)peekLeftHiddenViewControllerWithOffset:(CGFloat)offset animated:(BOOL)animated
{
    [self peekHiddenViewController:RZRevealViewControllerPositionLeft offset:offset duration:0.25 animated:animated];
}

- (void)peekRightHiddenViewControllerWithOffset:(CGFloat)offset animated:(BOOL)animated
{
    [self peekHiddenViewController:RZRevealViewControllerPositionRight offset:offset duration:0.25 animated:animated];
}

- (void)peekHiddenViewController:(RZRevealViewControllerPosition)position offset:(CGFloat)offset duration:(CGFloat)duration animated:(BOOL)animated
{
    UIViewController* hiddenVC = nil;
    if (position == RZRevealViewControllerPositionLeft)
    {
        hiddenVC = self.leftHiddenViewController;
    }
    else
    {
        offset = -offset;
        hiddenVC = self.rightHiddenViewController;
    }

    if (hiddenVC)
    {
        if (hiddenVC.parentViewController == nil)
        {
            [self addChildViewController:hiddenVC];
            hiddenVC.view.frame = self.view.bounds;
            hiddenVC.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
            [self.view insertSubview:hiddenVC.view belowSubview:self.mainVCWrapperView];
            [hiddenVC didMoveToParentViewController:self];
        }
        
        if (animated)
        {
            [UIView animateWithDuration:0.25
                                  delay:0
                                options:UIViewAnimationOptionCurveEaseOut
                             animations:^{
                                 [self.mainViewController revealController:self willPeekHiddenController:hiddenVC position:position];
                                 [self.leftHiddenViewController revealController:self willPeekHiddenController:hiddenVC position:position];
                                 
                                 if (self.delegate && [self.delegate respondsToSelector:@selector(revealController:willPeekHiddenController:position:)])
                                 {
                                     [self.delegate revealController:self willPeekHiddenController:hiddenVC position:position];
                                 }
                                 
                                 self.mainVCWrapperView.transform = CGAffineTransformMakeTranslation(offset, 0);
                             }
                             completion:^(BOOL finished) {
                                 [self setViewControllerRevealed:YES forPosition:position];
                                 
                                 [self.mainViewController revealController:self didPeekHiddenController:hiddenVC position:position];
                                 [self.leftHiddenViewController revealController:self didPeekHiddenController:hiddenVC position:position];
                                 
                                 if (self.delegate && [self.delegate respondsToSelector:@selector(revealController:didPeekHiddenController:position:)])
                                 {
                                     [self.delegate revealController:self didPeekHiddenController:hiddenVC position:position];
                                 }
                             }];
        }
        else
        {
            [self.mainViewController revealController:self willPeekHiddenController:hiddenVC position:position];
            [self.leftHiddenViewController revealController:self willPeekHiddenController:hiddenVC position:position];
            
            if (self.delegate && [self.delegate respondsToSelector:@selector(revealController:willPeekHiddenController:position:)])
            {
                [self.delegate revealController:self willPeekHiddenController:hiddenVC position:position];
            }
            
            self.mainVCWrapperView.transform = CGAffineTransformMakeTranslation(offset, 0);
            [self setViewControllerRevealed:YES forPosition:position];
            
            [self.mainViewController revealController:self didPeekHiddenController:hiddenVC position:position];
            [self.leftHiddenViewController revealController:self didPeekHiddenController:hiddenVC position:position];
            
            if (self.delegate && [self.delegate respondsToSelector:@selector(revealController:didPeekHiddenController:position:)])
            {
                [self.delegate revealController:self didPeekHiddenController:hiddenVC position:position];
            }
        }
    }
}

- (void)hideLeftHiddenViewControllerAnimated:(BOOL)animated
{
    [self hideHiddenViewController:RZRevealViewControllerPositionLeft duration:0.25 animated:animated];
}

- (void)hideRightHiddenViewControllerAnimated:(BOOL)animated
{
    [self hideHiddenViewController:RZRevealViewControllerPositionRight duration:0.25 animated:animated];
}

- (void)hideHiddenViewController:(RZRevealViewControllerPosition)position duration:(CGFloat)duration animated:(BOOL)animated
{
    UIViewController* vcToHide = (position == RZRevealViewControllerPositionLeft) ? self.leftHiddenViewController: self.rightHiddenViewController;

    if (animated)
    {
        [UIView animateWithDuration:duration
                              delay:0
                            options:UIViewAnimationOptionCurveEaseOut
                         animations:^{
                             [self.mainViewController revealController:self willHideHiddenController:vcToHide position:position];
                             [vcToHide revealController:self willHideHiddenController:vcToHide position:position];
                             
                             if (self.delegate && [self.delegate respondsToSelector:@selector(revealController:willHideHiddenController:position:)])
                             {
                                 [self.delegate revealController:self willHideHiddenController:vcToHide position:position];
                             }
                             
                             self.mainVCWrapperView.transform = CGAffineTransformIdentity;
                         }
                         completion:^(BOOL finished) {
                             
                             [vcToHide willMoveToParentViewController:nil];
                             [vcToHide removeFromParentViewController];
                             [vcToHide.view removeFromSuperview];
                             
                             [self setViewControllerRevealed:NO forPosition:position];
                             
                             [self.mainViewController revealController:self didHideHiddenController:vcToHide position:position];
                             [self.leftHiddenViewController revealController:self didHideHiddenController:vcToHide position:position];
                             
                             if (self.delegate && [self.delegate respondsToSelector:@selector(revealController:didHideHiddenController:position:)])
                             {
                                 [self.delegate revealController:self didHideHiddenController:vcToHide position:position];
                             }
                         }];
    }
    else
    {
        [self.mainViewController revealController:self willHideHiddenController:vcToHide position:position];
        [self.leftHiddenViewController revealController:self willHideHiddenController:vcToHide position:position];
        
        if (self.delegate && [self.delegate respondsToSelector:@selector(revealController:willHideHiddenController:position:)])
        {
            [self.delegate revealController:self willHideHiddenController:vcToHide position:position];
        }
        
        self.mainVCWrapperView.transform = CGAffineTransformIdentity;
        [vcToHide.view removeFromSuperview];
        [self setViewControllerRevealed:NO forPosition:position];
        
        [self.mainViewController revealController:self didHideHiddenController:vcToHide position:position];
        [self.leftHiddenViewController revealController:self didHideHiddenController:vcToHide position:position];
        
        if (self.delegate && [self.delegate respondsToSelector:@selector(revealController:didHideHiddenController:position:)])
        {
            [self.delegate revealController:self didHideHiddenController:vcToHide position:position];
        }
    }
}

- (void) setViewControllerRevealed:(BOOL)revealed forPosition:(RZRevealViewControllerPosition)position {
    
    if (position == RZRevealViewControllerPositionLeft)
    {
        self.leftHiddenViewControllerRevealed = revealed;
    }
    else
    {
        self.rightHiddenViewControllerRevealed = revealed;
    }
    
    if (revealed)
    {
        // Must disable interaction on VC itself, NOT wrapper
        // Disabling on wrapper allows "touch through" to hidden VC
        self.mainViewController.view.userInteractionEnabled = self.allowMainVCInteractionWhileRevealed;
        self.hideTapGestureRecognizer.enabled = !self.allowMainVCInteractionWhileRevealed;
        self.revealPanGestureRecognizer.enabled = YES;
    }
    else
    {
        self.mainViewController.view.userInteractionEnabled = YES;
        self.hideTapGestureRecognizer.enabled = NO;
        if(self.usesEdgeGestureRecognizer)
        {
            self.revealPanGestureRecognizer.enabled = NO;
        }
    }
}

#pragma mark - UIGestureRecognizer Callbacks

- (void)revealPanTriggered:(UIPanGestureRecognizer *)panGR
{
    static CGPoint initialTouchPoint;
    static CGPoint lastTouchPoint;
    static CGPoint currentLocation;
    static CGFloat initialOffset;
    
    static CGFloat currentPeekHiddenOffset;
    static CGFloat currentQuickPeekHiddenOffset;
    static CGFloat currentShowHiddenOffset;
    
    static NSTimeInterval lastTime;
    static NSTimeInterval currentTime;
        
    CGFloat locationOffset;
    
    switch (panGR.state) {
        case UIGestureRecognizerStateBegan:
            initialTouchPoint = [panGR locationInView:self.view];
            currentLocation = initialTouchPoint;
            lastTouchPoint = initialTouchPoint;
            lastTime = [NSDate timeIntervalSinceReferenceDate];
            currentTime = lastTime;
            initialOffset = self.mainVCWrapperView.transform.tx;
            
            currentQuickPeekHiddenOffset = self.quickPeekHiddenOffset;
            currentPeekHiddenOffset = self.peekHiddenOffset;
            currentShowHiddenOffset = self.showHiddenOffset;
            
            break;
        case UIGestureRecognizerStateChanged:
            lastTouchPoint = currentLocation;
            lastTime = currentTime;
            currentLocation = [panGR locationInView:self.view];
            currentTime = [NSDate timeIntervalSinceReferenceDate];
            locationOffset = round(currentLocation.x - initialTouchPoint.x + initialOffset);
            
            // This looks more complex than it needs to be but it's because we can pan to either side,
            // so we need to know which way the user intends to move before we start moving.
            if (locationOffset < 0.0)
            {
                if (!self.rightHiddenViewController)
                {
                    locationOffset = 0.0;
                }
                else if (!self.rightHiddenViewControllerRevealed)
                {
                    [self peekRightHiddenViewControllerWithOffset:0.0 animated:NO];
                }
            }
            else if (locationOffset > 0.0)
            {
                if (!self.leftHiddenViewController)
                {
                    locationOffset = 0.0;
                }
                else if (!self.leftHiddenViewControllerRevealed)
                {
                    [self peekLeftHiddenViewControllerWithOffset:0.0 animated:NO];
                }
            }
            
            
            if (self.isPeekEnabled && locationOffset > currentPeekHiddenOffset)
            {
                if (initialOffset > currentPeekHiddenOffset)
                {
                    if (locationOffset > initialOffset)
                    {
                        locationOffset = initialOffset + ((locationOffset - initialOffset) / 2.0);
                    }
                }
                else
                {
                    locationOffset = currentPeekHiddenOffset + ((locationOffset - currentPeekHiddenOffset) / 2.0);
                }
            }

            if(fabs(locationOffset) > self.maxDragDistance)
            {
                locationOffset = (locationOffset < 0.0f) ? ((-1) * self.maxDragDistance) : self.maxDragDistance;
            }

            self.mainVCWrapperView.transform = CGAffineTransformMakeTranslation(locationOffset, 0);
            
            break;
            
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateCancelled:
            currentLocation = [panGR locationInView:self.view];
            locationOffset = currentLocation.x - initialTouchPoint.x + initialOffset;
            
            double velocity = (currentLocation.x - lastTouchPoint.x) / (currentTime - lastTime);
            double speed = fabs(velocity);
            RZRevealViewControllerPosition position = locationOffset > 0 ? RZRevealViewControllerPositionLeft : RZRevealViewControllerPositionRight;
            CGFloat absLocOffset = fabs(locationOffset);
            
            // Make sure we have a valid offset for which view controllers are present
            BOOL validOffset = (locationOffset > 0 && self.leftHiddenViewController != nil) || (locationOffset < 0 && self.rightHiddenViewController != nil);
            
            if (validOffset && absLocOffset > fabs(initialOffset))
            {
                if (absLocOffset > (self.peekEnabled ? currentShowHiddenOffset : self.revealOffset))
                {
                    CGFloat newDistance = fabs(currentPeekHiddenOffset - absLocOffset);
                    
                    double duration = newDistance / speed;
                    
                    if (duration < 0.1)
                    {
                        duration = 0.1;
                    }
                    else if (duration > 0.25)
                    {
                        duration = 0.25;
                    }
                    
                    [self showHiddenViewController:position offset:currentShowHiddenOffset duration:duration animated:YES];
                }
                else if (self.isPeekEnabled && absLocOffset > (currentQuickPeekHiddenOffset + ((currentPeekHiddenOffset - currentQuickPeekHiddenOffset) / 3.0)))
                {
                    CGFloat newDistance = fabs(currentPeekHiddenOffset - absLocOffset);
                    
                    double duration = newDistance / speed;
                    
                    if (duration < 0.1)
                    {
                        duration = 0.1;
                    }
                    else if (duration > 0.25)
                    {
                        duration = 0.25;
                    }
                    
                    [self peekHiddenViewController:position offset:currentPeekHiddenOffset duration:duration animated:YES];
                }
                else if (self.isPeekEnabled && (absLocOffset > (currentQuickPeekHiddenOffset / 3.0) || velocity > 1000.0))
                {
                    CGFloat newDistance = fabs(currentQuickPeekHiddenOffset - absLocOffset);
                    
                    double duration = newDistance / speed;
                    
                    if (duration < 0.1)
                    {
                        duration = 0.1;
                    }
                    else if (duration > 0.25)
                    {
                        duration = 0.25;
                    }
                    
                    [self peekHiddenViewController:position offset:currentQuickPeekHiddenOffset duration:duration animated:YES];
                }
                else
                {
                    CGFloat newDistance = absLocOffset;
                    
                    double duration = newDistance / speed;
                    
                    if (duration < 0.1)
                    {
                        duration = 0.1;
                    }
                    else if (duration > 0.25)
                    {
                        duration = 0.25;
                    }
                    
                    [self hideHiddenViewController:position duration:duration animated:YES];
                }
            }
            else
            {
                CGFloat newDistance = absLocOffset;
                
                double duration = newDistance / speed;
                
                if (duration < 0.1)
                {
                    duration = 0.1;
                }
                else if (duration > 0.25)
                {
                    duration = 0.25;
                }
                
                [self hideHiddenViewController:position duration:duration animated:YES];
            }
            
            break;
        default:
            break;
    }
}

- (void)hideTapTriggered:(UITapGestureRecognizer *)tapGR
{
    if (self.leftHiddenViewControllerRevealed)
    {
        [self hideLeftHiddenViewControllerAnimated:YES];
    }
    else if (self.rightHiddenViewControllerRevealed)
    {
        [self hideRightHiddenViewControllerAnimated:YES];
    }
}

#pragma mark - UIGestureRecgonzierDelegate

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    if (gestureRecognizer == self.revealPanGestureRecognizer || gestureRecognizer == self.revealEdgePanRecognizer)
    {
        
        BOOL delegateAllowsReveal = YES;
        if ([self.delegate respondsToSelector:@selector(revealControllerShouldBeginReveal:)])
        {
            delegateAllowsReveal = [self.delegate revealControllerShouldBeginReveal:self];
        }
        
        if (!delegateAllowsReveal || !self.revealEnabled)
        {
            return NO;
        }
    }
    
    return YES;
}

@end


@implementation UIViewController (RZRevealViewController)

- (RZRevealViewController*)revealViewController
{
    if (self.parentViewController)
    {
        if ([self.parentViewController isKindOfClass:[RZRevealViewController class]])
        {
            return (RZRevealViewController*)self.parentViewController;
        }
        else
        {
            return [self.parentViewController revealViewController];
        }
    }
    
    return nil;
}

#pragma mark - RZRevealViewControllerDelegate Empty Implementations

- (void)revealController:(RZRevealViewController*)revealController willShowHiddenController:(UIViewController*)hiddenController position:(RZRevealViewControllerPosition)position {}
- (void)revealController:(RZRevealViewController*)revealController didShowHiddenController:(UIViewController*)hiddenController position:(RZRevealViewControllerPosition)position {}
- (void)revealController:(RZRevealViewController*)revealController willHideHiddenController:(UIViewController*)hiddenController position:(RZRevealViewControllerPosition)position {}
- (void)revealController:(RZRevealViewController*)revealController didHideHiddenController:(UIViewController*)hiddenController position:(RZRevealViewControllerPosition)position {}
- (void)revealController:(RZRevealViewController*)revealController willPeekHiddenController:(UIViewController*)hiddenController position:(RZRevealViewControllerPosition)position {}
- (void)revealController:(RZRevealViewController*)revealController didPeekHiddenController:(UIViewController*)hiddenController position:(RZRevealViewControllerPosition)position {}

@end
