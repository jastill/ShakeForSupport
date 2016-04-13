//
//  Provided as an example only
//
//  ViewController.m
//  ShakeForSupport
//
//  Created by Astill, John on 4/11/16.
//

#import "ViewController.h"

#import "FeedbackShakeViewController.h"

@interface ViewController ()

@end

@implementation ViewController


-(void)viewDidAppear:(BOOL)animated {
    
    [super viewDidAppear:animated];
    
    // Allow to be the first responder for receiving the shake gesture event
    [self becomeFirstResponder];
    
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/**
 * Capture the screenshot of this view to add to the email
 */
-(UIImage *) grabTheView:(UIView *) view {
    
    UIGraphicsBeginImageContextWithOptions(view.bounds.size, view.opaque, [[UIScreen mainScreen] scale]);
    [view.layer renderInContext:UIGraphicsGetCurrentContext()];
    
    UIImage *screenCapture = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return screenCapture;
}

- (void)motionEnded:(UIEventSubtype)motion withEvent:(UIEvent *)event {
    
    UIImage *screencap = [self grabTheView:self.view];
    
    if (motion == UIEventSubtypeMotionShake) {
        
        // This view controller shows the Feedback shake options, email, push to ticketing system etc
        FeedbackShakeViewController *fvc = [[FeedbackShakeViewController alloc] init];
        fvc.screenCapture = screencap;
        [self.navigationController pushViewController:fvc animated:YES];
    }
}

@end
