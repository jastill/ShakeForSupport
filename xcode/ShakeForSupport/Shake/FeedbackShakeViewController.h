//
//  Provided as an example only
//
//  Created by Astill, John on 3/17/13.
//
//

#import <UIKit/UIKit.h>
#import <MessageUI/MessageUI.h>

@interface FeedbackShakeViewController : UIViewController <MFMailComposeViewControllerDelegate>

@property (nonatomic, retain) UIImage *screenCapture;
@property (nonatomic, retain) IBOutlet UIButton *submitButton;
@property (nonatomic, retain) IBOutlet UIButton *dismissButton;
@property (nonatomic, retain) IBOutlet UIButton *shareButton;
@property (nonatomic, retain) IBOutlet UIImageView *shakeImage;

@property double startRadians;

-(IBAction)sendFeedback:(id)sender;
-(IBAction)shareWithFriends:(id)sender;

-(void)shake:(id)sender;
-(void)dismiss:(id)sender;

+ (NSString *)currentWifiSSID;


@end
