//
//  RZRevealViewController.h
//  Raizlabs
//
//  Created by Joe Goullaud on 2/17/12.
//  Copyright (c) 2012 Raizlabs. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol RZRevealViewControllerDelegate;

@interface RZRevealViewController : UIViewController <UIGestureRecognizerDelegate>

@property (strong, nonatomic) IBOutlet UIViewController *mainViewController;
@property (strong, nonatomic) IBOutlet UIViewController *hiddenViewController;
@property (strong, nonatomic) UIView *mainVCWrapperView;
@property (strong, nonatomic) UIImageView *shadowView;

@property (assign, nonatomic, readonly, getter = isHiddenViewControllerRevealed) BOOL hiddenViewControllerRevealed;
@property (assign, nonatomic, getter = isRevealEnabled) BOOL revealEnabled;

@property (strong, nonatomic, readonly) UIPanGestureRecognizer *revealPanGestureRecognizer;

@property (assign, nonatomic) CGFloat quickPeekHiddenOffset;                    // Defaults to self.view.bounds.size.width / 4.0
@property (assign, nonatomic) CGFloat peekHiddenOffset;                         // Defaults to self.view.bounds.size.width / 2.0
@property (assign, nonatomic) CGFloat showHiddenOffset;                         // Defaults to self.view.bounds.size.width
@property (assign, nonatomic) CGFloat revealGestureThreshold;                   // Defaults to CGFLOAT_MAX

@property (weak, nonatomic) id<RZRevealViewControllerDelegate> delegate;

- (id)initWithMainViewController:(UIViewController*)mainVC andHiddenViewController:(UIViewController*)hiddenVC;

- (IBAction)showHiddenViewControllerAnimated:(BOOL)animated;
- (void)showHiddenViewControllerWithOffset:(CGFloat)offset animated:(BOOL)animated;
- (IBAction)peekHiddenViewControllerAnimated:(BOOL)animated;
- (void)peekHiddenViewControllerWithOffset:(CGFloat)offset animated:(BOOL)animated;
- (IBAction)hideHiddenViewControllerAnimated:(BOOL)animated;

@end

@protocol RZRevealViewControllerDelegate <NSObject>

@optional
- (void)revealController:(RZRevealViewController*)revealController willShowHiddenController:(UIViewController*)hiddenController;
- (void)revealController:(RZRevealViewController*)revealController didShowHiddenController:(UIViewController*)hiddenController;
- (void)revealController:(RZRevealViewController*)revealController willHideHiddenController:(UIViewController*)hiddenController;
- (void)revealController:(RZRevealViewController*)revealController didHideHiddenController:(UIViewController*)hiddenController;
- (void)revealController:(RZRevealViewController*)revealController willPeekHiddenController:(UIViewController*)hiddenController;
- (void)revealController:(RZRevealViewController*)revealController didPeekHiddenController:(UIViewController*)hiddenController;

@end


@interface UIViewController (RZRevealViewController) <RZRevealViewControllerDelegate>

@property (weak, nonatomic, readonly) RZRevealViewController *revealViewController;

@end
