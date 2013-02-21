//
//  RZRevealViewController.m
//  Raizlabs
//
//  Created by Joe Goullaud on 2/17/12.
//  Copyright (c) 2012 Raizlabs. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "RZRevealViewController.h"

@interface RZRevealViewController ()

@property (assign, nonatomic, readwrite, getter = isHiddenViewControllerRevealed) BOOL hiddenViewControllerRevealed;
@property (strong, nonatomic, readwrite) UIPanGestureRecognizer *revealPanGestureRecognizer;

- (void)setupRevealViewController;

- (void)showHiddenViewControllerWithOffset:(CGFloat)offset duration:(CGFloat)duration animated:(BOOL)animated;
- (void)peekHiddenViewControllerWithOffset:(CGFloat)offset duration:(CGFloat)duration animated:(BOOL)animated;
- (void)hideHiddenViewControllerWithDuration:(CGFloat)duration animated:(BOOL)animated;

- (void)revealPanTriggered:(UIPanGestureRecognizer*)panGR;
@end

@implementation RZRevealViewController
@synthesize mainViewController = _mainViewController;
@synthesize hiddenViewController = _hiddenViewController;

@synthesize mainVCWrapperView = _mainVCWrapperView;
@synthesize shadowView = _shadowView;

@synthesize hiddenViewControllerRevealed = _hiddenViewControllerRevealed;
@synthesize revealEnabled = _revealEnabled;

@synthesize revealPanGestureRecognizer = _revealPanGestureRecognizer;

@synthesize quickPeekHiddenOffset = _quickPeekHiddenOffset;
@synthesize peekHiddenOffset = _peekHiddenOffset;
@synthesize showHiddenOffset = _showHiddenOffset;
@synthesize revealGestureThreshold = _revealGestureThreshold;

@synthesize delegate = _delegate;

- (id)initWithMainViewController:(UIViewController*)mainVC andHiddenViewController:(UIViewController*)hiddenVC
{
    self = [self initWithNibName:nil bundle:nil];
    if (self) {
        
        self.mainViewController = mainVC;
        self.hiddenViewController = hiddenVC;
        [self setupRevealViewController];

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
    
    self.revealPanGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(revealPanTriggered:)];
    self.revealPanGestureRecognizer.delegate = self;
    
    self.quickPeekHiddenOffset = self.view.bounds.size.width * 0.85;
    self.peekHiddenOffset = self.view.bounds.size.width * 0.85;
    self.showHiddenOffset = self.view.bounds.size.width  * 0.85;
    self.revealGestureThreshold = CGFLOAT_MAX;
    
    [self.view addGestureRecognizer:self.revealPanGestureRecognizer];
}

#pragma mark - View lifecycle
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.view addGestureRecognizer:self.revealPanGestureRecognizer];
    
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
    UIImage *shadowImage = [UIImage imageNamed:@"shadow-left-edge.png"];
    CGRect shadowFrame = CGRectMake(-shadowImage.size.width, 0, shadowImage.size.width, self.view.bounds.size.height);
    self.shadowView = [[UIImageView alloc] initWithFrame:shadowFrame];
    [self.shadowView setImage:shadowImage];
    [self.mainVCWrapperView addSubview:self.shadowView];
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

- (void)setHiddenViewController:(UIViewController *)hiddenViewController
{
    if (hiddenViewController == _hiddenViewController)
    {
        return;
    }
    
    CGRect frame = _hiddenViewController.view.frame;
    [_hiddenViewController.view removeFromSuperview];
    [_hiddenViewController removeFromParentViewController];
    _hiddenViewController = hiddenViewController;
    
    if (hiddenViewController)
    {
        [self addChildViewController:hiddenViewController];
        
        if (self.hiddenViewControllerRevealed)
        {
            hiddenViewController.view.frame = frame;
            hiddenViewController.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
            [self.view insertSubview:hiddenViewController.view belowSubview:self.mainVCWrapperView];
        }
    }
}

#pragma mark - Show/Peek/Hide Hidden VC methods

- (void)showHiddenViewControllerAnimated:(BOOL)animated
{
    [self showHiddenViewControllerWithOffset:self.showHiddenOffset animated:YES];
}

- (void)showHiddenViewControllerWithOffset:(CGFloat)offset animated:(BOOL)animated;
{
    [self showHiddenViewControllerWithOffset:offset duration:0.25 animated:animated];
}

- (void)showHiddenViewControllerWithOffset:(CGFloat)offset duration:(CGFloat)duration animated:(BOOL)animated
{
    if (self.hiddenViewController)
    {
        self.hiddenViewController.view.frame = self.view.bounds;
        self.hiddenViewController.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [self.view insertSubview:self.hiddenViewController.view belowSubview:self.mainVCWrapperView];
        
        if (animated)
        {
            [UIView animateWithDuration:0.25
                                  delay:0
                                options:UIViewAnimationOptionCurveEaseOut
                             animations:^{
                                 [self.mainViewController revealController:self willShowHiddenController:self.hiddenViewController];
                                 [self.hiddenViewController revealController:self willShowHiddenController:self.hiddenViewController];
                                 
                                 if (self.delegate && [self.delegate respondsToSelector:@selector(revealController:willShowHiddenController:)])
                                 {
                                     [self.delegate revealController:self willShowHiddenController:self.hiddenViewController];
                                 }
                                 
                                 self.mainVCWrapperView.transform = CGAffineTransformMakeTranslation(offset, 0);
                             }
                             completion:^(BOOL finished) {
                                 self.hiddenViewControllerRevealed = YES;
                                 
                                 [self.mainViewController revealController:self didShowHiddenController:self.hiddenViewController];
                                 [self.hiddenViewController revealController:self didShowHiddenController:self.hiddenViewController];
                                 
                                 if (self.delegate && [self.delegate respondsToSelector:@selector(revealController:didShowHiddenController:)])
                                 {
                                     [self.delegate revealController:self didShowHiddenController:self.hiddenViewController];
                                 }
                             }];
        }
        else
        {
            [self.mainViewController revealController:self willShowHiddenController:self.hiddenViewController];
            [self.hiddenViewController revealController:self willShowHiddenController:self.hiddenViewController];
            
            if (self.delegate && [self.delegate respondsToSelector:@selector(revealController:willShowHiddenController:)])
            {
                [self.delegate revealController:self willShowHiddenController:self.hiddenViewController];
            }
            
            self.mainVCWrapperView.transform = CGAffineTransformMakeTranslation(offset, 0);
            self.hiddenViewControllerRevealed = YES;
            
            [self.mainViewController revealController:self didShowHiddenController:self.hiddenViewController];
            [self.hiddenViewController revealController:self didShowHiddenController:self.hiddenViewController];
            
            if (self.delegate && [self.delegate respondsToSelector:@selector(revealController:didShowHiddenController:)])
            {
                [self.delegate revealController:self didShowHiddenController:self.hiddenViewController];
            }
        }
    }
}

- (void)peekHiddenViewControllerAnimated:(BOOL)animated
{
    [self peekHiddenViewControllerWithOffset:self.peekHiddenOffset animated:animated];
}

- (void)peekHiddenViewControllerWithOffset:(CGFloat)offset animated:(BOOL)animated
{
    [self peekHiddenViewControllerWithOffset:offset duration:0.25 animated:animated];
}

- (void)peekHiddenViewControllerWithOffset:(CGFloat)offset duration:(CGFloat)duration animated:(BOOL)animated
{
    if (self.hiddenViewController)
    {
        self.hiddenViewController.view.frame = self.view.bounds;
        self.hiddenViewController.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [self.view insertSubview:self.hiddenViewController.view belowSubview:self.mainVCWrapperView];
        
        if (animated)
        {
            [UIView animateWithDuration:0.25
                                  delay:0
                                options:UIViewAnimationOptionCurveEaseOut
                             animations:^{
                                 [self.mainViewController revealController:self willPeekHiddenController:self.hiddenViewController];
                                 [self.hiddenViewController revealController:self willPeekHiddenController:self.hiddenViewController];
                                 
                                 if (self.delegate && [self.delegate respondsToSelector:@selector(revealController:willPeekHiddenController:)])
                                 {
                                     [self.delegate revealController:self willPeekHiddenController:self.hiddenViewController];
                                 }
                                 
                                 self.mainVCWrapperView.transform = CGAffineTransformMakeTranslation(offset, 0);
                             }
                             completion:^(BOOL finished) {
                                 self.hiddenViewControllerRevealed = YES;
                                 
                                 [self.mainViewController revealController:self didPeekHiddenController:self.hiddenViewController];
                                 [self.hiddenViewController revealController:self didPeekHiddenController:self.hiddenViewController];
                                 
                                 if (self.delegate && [self.delegate respondsToSelector:@selector(revealController:didPeekHiddenController:)])
                                 {
                                     [self.delegate revealController:self didPeekHiddenController:self.hiddenViewController];
                                 }
                             }];
        }
        else
        {
            [self.mainViewController revealController:self willPeekHiddenController:self.hiddenViewController];
            [self.hiddenViewController revealController:self willPeekHiddenController:self.hiddenViewController];
            
            if (self.delegate && [self.delegate respondsToSelector:@selector(revealController:willPeekHiddenController:)])
            {
                [self.delegate revealController:self willPeekHiddenController:self.hiddenViewController];
            }
            
            self.mainVCWrapperView.transform = CGAffineTransformMakeTranslation(offset, 0);
            self.hiddenViewControllerRevealed = YES;
            
            [self.mainViewController revealController:self didPeekHiddenController:self.hiddenViewController];
            [self.hiddenViewController revealController:self didPeekHiddenController:self.hiddenViewController];
            
            if (self.delegate && [self.delegate respondsToSelector:@selector(revealController:didPeekHiddenController:)])
            {
                [self.delegate revealController:self didPeekHiddenController:self.hiddenViewController];
            }
        }
    }
}

- (void)hideHiddenViewControllerAnimated:(BOOL)animated
{
    [self hideHiddenViewControllerWithDuration:0.25 animated:animated];
}

- (void)hideHiddenViewControllerWithDuration:(CGFloat)duration animated:(BOOL)animated
{
    if (animated)
    {
        [UIView animateWithDuration:duration
                              delay:0
                            options:UIViewAnimationOptionCurveEaseOut
                         animations:^{
                             [self.mainViewController revealController:self willHideHiddenController:self.hiddenViewController];
                             [self.hiddenViewController revealController:self willHideHiddenController:self.hiddenViewController];
                             
                             if (self.delegate && [self.delegate respondsToSelector:@selector(revealController:willHideHiddenController:)])
                             {
                                 [self.delegate revealController:self willHideHiddenController:self.hiddenViewController];
                             }
                             
                             self.mainVCWrapperView.transform = CGAffineTransformIdentity;
                         }
                         completion:^(BOOL finished) {
                             [self.hiddenViewController.view removeFromSuperview];
                             self.hiddenViewControllerRevealed = NO;
                             
                             [self.mainViewController revealController:self didHideHiddenController:self.hiddenViewController];
                             [self.hiddenViewController revealController:self didHideHiddenController:self.hiddenViewController];
                             
                             if (self.delegate && [self.delegate respondsToSelector:@selector(revealController:didHideHiddenController:)])
                             {
                                 [self.delegate revealController:self didHideHiddenController:self.hiddenViewController];
                             }
                         }];
    }
    else
    {
        [self.mainViewController revealController:self willHideHiddenController:self.hiddenViewController];
        [self.hiddenViewController revealController:self willHideHiddenController:self.hiddenViewController];
        
        if (self.delegate && [self.delegate respondsToSelector:@selector(revealController:willHideHiddenController:)])
        {
            [self.delegate revealController:self willHideHiddenController:self.hiddenViewController];
        }
        
        self.mainVCWrapperView.transform = CGAffineTransformIdentity;
        [self.hiddenViewController.view removeFromSuperview];
        self.hiddenViewControllerRevealed = NO;
        
        [self.mainViewController revealController:self didHideHiddenController:self.hiddenViewController];
        [self.hiddenViewController revealController:self didHideHiddenController:self.hiddenViewController];
        
        if (self.delegate && [self.delegate respondsToSelector:@selector(revealController:didHideHiddenController:)])
        {
            [self.delegate revealController:self didHideHiddenController:self.hiddenViewController];
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
            
            if (!self.hiddenViewControllerRevealed)
            {
                [self peekHiddenViewControllerWithOffset:0.0 animated:NO];
            }
            
            break;
        case UIGestureRecognizerStateChanged:
            lastTouchPoint = currentLocation;
            lastTime = currentTime;
            currentLocation = [panGR locationInView:self.view];
            currentTime = [NSDate timeIntervalSinceReferenceDate];
            locationOffset = round(currentLocation.x - initialTouchPoint.x + initialOffset);
            
            if (locationOffset < 0.0)
            {
                locationOffset = 0.0;
            }
            else if (locationOffset > currentPeekHiddenOffset)
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
            
            self.mainVCWrapperView.transform = CGAffineTransformMakeTranslation(locationOffset, 0);
            
            break;
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateCancelled:
            currentLocation = [panGR locationInView:self.view];
            locationOffset = currentLocation.x - initialTouchPoint.x + initialOffset;
            
            CGFloat lastOffset = currentLocation.x - lastTouchPoint.x;
            double velocity = (currentLocation.x - lastTouchPoint.x) / (currentTime - lastTime);
            double speed = fabs(velocity);
            
            //            NSLog(@"Last Offset: %f Velocity: %f", lastOffset, velocity);
            
            if (lastOffset > 0.0 || (locationOffset > initialOffset && lastOffset > -10.0))
            {
                if (initialOffset >= currentShowHiddenOffset && locationOffset > currentShowHiddenOffset)
                {
                    CGFloat newDistance = fabs(currentPeekHiddenOffset - locationOffset);
                    
                    double duration = newDistance / speed;
                    
                    if (duration < 0.1)
                    {
                        duration = 0.1;
                    }
                    else if (duration > 0.25)
                    {
                        duration = 0.25;
                    }
                    
                    [self showHiddenViewControllerWithOffset:currentShowHiddenOffset duration:duration animated:YES];
                }
                else if (locationOffset > (currentQuickPeekHiddenOffset + ((currentPeekHiddenOffset - currentQuickPeekHiddenOffset) / 3.0)))
                {
                    CGFloat newDistance = fabs(currentPeekHiddenOffset - locationOffset);
                    
                    double duration = newDistance / speed;
                    
                    if (duration < 0.1)
                    {
                        duration = 0.1;
                    }
                    else if (duration > 0.25)
                    {
                        duration = 0.25;
                    }
                    
                    [self peekHiddenViewControllerWithOffset:currentPeekHiddenOffset duration:duration animated:YES];
                }
                else if (locationOffset > (currentQuickPeekHiddenOffset / 3.0) || velocity > 1000.0)
                {
                    CGFloat newDistance = fabs(currentQuickPeekHiddenOffset - locationOffset);
                    
                    double duration = newDistance / speed;
                    
                    if (duration < 0.1)
                    {
                        duration = 0.1;
                    }
                    else if (duration > 0.25)
                    {
                        duration = 0.25;
                    }
                    
                    [self peekHiddenViewControllerWithOffset:currentQuickPeekHiddenOffset duration:duration animated:YES];
                }
                else
                {
                    CGFloat newDistance = fabs(locationOffset);
                    
                    double duration = newDistance / speed;
                    
                    if (duration < 0.1)
                    {
                        duration = 0.1;
                    }
                    else if (duration > 0.25)
                    {
                        duration = 0.25;
                    }
                    
                    [self hideHiddenViewControllerWithDuration:duration animated:YES];
                }
            }
            else
            {
                CGFloat newDistance = fabs(locationOffset);
                
                double duration = newDistance / speed;
                
                if (duration < 0.1)
                {
                    duration = 0.1;
                }
                else if (duration > 0.25)
                {
                    duration = 0.25;
                }
                
                [self hideHiddenViewControllerWithDuration:duration animated:YES];
            }
            
            break;
        default:
            break;
    }
}

#pragma mark - UIGestureRecgonzierDelegate

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    if (gestureRecognizer == self.revealPanGestureRecognizer)
    {
        CGPoint location = [gestureRecognizer locationInView:self.view];
        
        if (!self.revealEnabled || (!self.hiddenViewControllerRevealed && location.x > self.revealGestureThreshold))
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

- (void)revealController:(RZRevealViewController*)revealController willShowHiddenController:(UIViewController*)hiddenController
{
}

- (void)revealController:(RZRevealViewController*)revealController didShowHiddenController:(UIViewController*)hiddenController
{
}

- (void)revealController:(RZRevealViewController*)revealController willHideHiddenController:(UIViewController*)hiddenController
{
}

- (void)revealController:(RZRevealViewController*)revealController didHideHiddenController:(UIViewController*)hiddenController
{
}

- (void)revealController:(RZRevealViewController*)revealController willPeekHiddenController:(UIViewController*)hiddenController
{
}

- (void)revealController:(RZRevealViewController*)revealController didPeekHiddenController:(UIViewController*)hiddenController
{
}

@end
