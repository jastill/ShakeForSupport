//
//  Provided as an example only
//  FeedbackShakeViewController.m
//
//  Created by Astill, John on 3/17/13.
//
//

#import "FeedbackShakeViewController.h"
#include <QuartzCore/QuartzCore.h>

#import <SystemConfiguration/CaptiveNetwork.h>

#import <AudioToolbox/AudioToolbox.h>
#include <asl.h>

// Constants that can be replaced for your application
#define cAppName @"Shake Me App"

#define cDistributionList @"mydl@distributionlist.list"

// Image name for screencapture attachment to email
#define cImageFilename @"screencapture.png"

// Body of the email sent when sharing the application via email. Share meaning recommending it to someone else. This is in the file shareappemail.html
@interface FeedbackShakeViewController ()

@end

@implementation FeedbackShakeViewController

/**
 *
 */
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

/**
 *
 */
- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.navigationController setNavigationBarHidden:YES animated:NO];
    
    // Buzz the phone when the view opens
	AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/**
 * Read the log files from the device
 */
-(NSString*) getLogs {
    NSMutableString *logFile = [[NSMutableString alloc] initWithCapacity:9000];
    
    aslmsg q, m;
    q = asl_new(ASL_TYPE_QUERY);
    
    if (q == NULL   ) {
        [logFile appendString:@"Unable to read log files."];
        return logFile;
    }
    
    // Loop through the log entries.
    asl_object_t r = asl_search(NULL, q);
    while (NULL != (m = asl_next(r))) {
        const char* level = asl_get(m, ASL_KEY_LEVEL);
        const char* facility = asl_get(m, ASL_KEY_FACILITY);
        const char* message = asl_get(m, ASL_KEY_MSG);
        const char* time = asl_get(m, ASL_KEY_TIME);
        const char* nano = asl_get(m, ASL_KEY_TIME_NSEC);
        
        NSTimeInterval interval = [[NSString stringWithFormat:@"%s",time] doubleValue];
        NSDate *date = [NSDate dateWithTimeIntervalSince1970:interval];
        
        [logFile appendString:[NSString stringWithFormat:@"[%s] %@ %snS %s %s\n", level, date, nano, facility, message]];

    }
    asl_release(r);
    
    return logFile;
}

/**
 * Dismiss the feedback view
 */
-(IBAction)dismiss:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

/**
 * Show the share with friends email.
 */
-(IBAction)shareWithFriends:(id)sender {
    if ([MFMailComposeViewController canSendMail])
    {
        MFMailComposeViewController *mailer = [[MFMailComposeViewController alloc] init];
        mailer.mailComposeDelegate = self;
        
        [mailer setSubject:[NSString stringWithFormat:@" %@  app",cAppName]];
        NSString *filePath = [[NSBundle mainBundle] pathForResource:@"shareappemail" ofType:@"html"];
        NSError *error;
        NSString *shareEmail = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error: &error];
        [mailer setMessageBody:shareEmail  isHTML:YES];
        [self presentViewController:mailer animated:YES completion:nil];
    } else {
        [self unableToSendEmail];
    }
}

/**
 * Delegate method for sending mail. Generic error display if something did not work.
 */
- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error {
    switch (result)
    {
        case MFMailComposeResultCancelled:
            break;
        case MFMailComposeResultSaved:
            break;
        case MFMailComposeResultSent:
            break;
        case MFMailComposeResultFailed:
            NSLog(@"Mail failed: the email message was not saved or queued.");
            break;
        default:
            NSLog(@"Mail not sent.");
            break;
    }
    // Remove the mail view
    [self dismissViewControllerAnimated:YES completion:nil];
    [self dismiss:self];
}

#pragma mark - Help Methods

// Get the current SSID of the wifi if avilable.
+ (NSString *)currentWifiSSID {
    // Does not work on the simulator. This is old coding
    NSString *ssid = nil;
    NSArray *ifs = (id)CFBridgingRelease(CNCopySupportedInterfaces());
    for (NSString *ifnam in ifs) {
        NSDictionary *info = (id)CFBridgingRelease(CNCopyCurrentNetworkInfo((CFStringRef)ifnam));
        if (info[@"SSID"]) {
            ssid = info[@"SSID"];
        }
    }
    return ssid;
}

/**
 * This will cuase the support email to be composed. This currently includes data Specific to Travel Receipt Capture
 */
-(IBAction)sendFeedback:(id)sender {
    
    if ([MFMailComposeViewController canSendMail])
    {
        NSString *logs = [self getLogs];
        
        MFMailComposeViewController *mailer = [[MFMailComposeViewController alloc] init];
        mailer.mailComposeDelegate = self;
        [mailer setToRecipients:[NSArray arrayWithObjects:cDistributionList, nil]];
        [mailer setSubject:@"Shake app Feedback"];
        NSData *imageData = UIImagePNGRepresentation(self.screenCapture);
        [mailer addAttachmentData:imageData mimeType:@"image/png" fileName:@"screencapture.png"];
        [mailer addAttachmentData:[logs dataUsingEncoding:NSUTF8StringEncoding] mimeType:@"text/plain" fileName:@"logfile.txt"];

        // Other attachments can be added here
        NSString *appVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:(NSString*)kCFBundleVersionKey];
        NSString *systemVersion = [[UIDevice currentDevice] systemVersion];
        NSString *deviceType = [UIDevice currentDevice].model;
        NSString *ssid = [FeedbackShakeViewController currentWifiSSID];
        if (ssid == nil) {
            ssid = @"No Wifi SSID found";
        }
        
        NSString *emailBody = [NSString stringWithFormat:@"Please describe your feedback here, including steps on how to recreate any problems you may have:\r\n\r\n\r\nWireless SSID: %@\r\n%@ Version: %@\r\niOS Version: %@\r\nDevice type: %@\r\nLocale: %@\r\nLanguage: %@\r\n",ssid, @"ShakeMeApp", appVersion, systemVersion, deviceType,[[NSLocale currentLocale] localeIdentifier],[[[NSUserDefaults standardUserDefaults] objectForKey:@"AppleLanguages"] objectAtIndex:0]];

        [mailer setMessageBody:emailBody isHTML:NO];
        [self presentViewController:mailer animated:YES completion:nil];
    } else {
        [self unableToSendEmail];
    }
}

/**
 * This controller needs to be able to be first responder to respond to the shake
 */
-(BOOL) canBecomeFirstResponder {
    return YES;
}

/**
 * Make sure we are first responder so that we can capture the shake
 */
-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    // Allow to be the first responder for receiving the shake gesture event
    [self becomeFirstResponder];

    // Wobble the image when the view appears
    [self rotateTo:M_PI/8 from:0.0f];
}

/**
 *
 */
- (void)viewWillDisappear:(BOOL)animated {
    // No longer need to receive the shake gesture event since the view is gone
    [self resignFirstResponder];
    [super viewWillDisappear:animated];
}
#pragma mark - email support

/**
 * Alert for not being able to send email
 */
-(void) unableToSendEmail {
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Unable to submit email"
                                                                   message:@"It would appear that your device does not support sending email."
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction * action) {}];
    
    [alert addAction:defaultAction];
    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - Animation for icon in feedback screen
// This is only for animation effects

/**
 * Capture the twist event
 */
- (void)motionEnded:(UIEventSubtype)motion withEvent:(UIEvent *)event {
    [self rotateTo:self.startRadians - M_PI/8 from:self.startRadians ];
}

/**
 * Rotate the image from fromValue radians to toValue radians
 */
-(void)rotateTo:(double)toValue from:(double)fromValue {
    NSLog(@"fromValue: %f toValue: %f",fromValue, toValue);
    
    self.startRadians = fromValue;
    
    CABasicAnimation* anim = [CABasicAnimation animationWithKeyPath:@"transform.rotation"];
    [anim setFromValue:[NSNumber numberWithFloat:fromValue]];
    [anim setToValue:[NSNumber numberWithDouble:toValue]]; // rotation angle
    [anim setDuration:0.1];
    [anim setRepeatCount:6];
    [anim setAutoreverses:YES];
    [self.shakeImage.layer addAnimation:anim forKey:@"iconShake"];
}

/**
 * allow the icon to rotate
 */
-(void)shake:(UIRotationGestureRecognizer *)recognizer {
    // Determine the transform from the current position
    double startPosition = self.startRadians + [recognizer rotation];
    
    CGAffineTransform transform = CGAffineTransformMakeRotation(startPosition);
    self.shakeImage.transform = transform;
    
    // If the gesture has ended or is canceled, begin the animation
    // back to horizontal and fade out
    if (([recognizer state] == UIGestureRecognizerStateEnded) || ([recognizer state] == UIGestureRecognizerStateCancelled)) {
        // To value should be current rotation in radians
        CGFloat toValue = self.startRadians;
        [self rotateTo:toValue from:startPosition];
        
    }
}

@end
