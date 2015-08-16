//
//  ViewController.h
//  HeartRun
//
//  Created by 鲁辰 on 7/30/15.
//  Copyright (c) 2015 ChenLu. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Spotify/Spotify.h>
#import <CoreMotion/CoreMotion.h>
#import <Accounts/Accounts.h>
#import <Social/Social.h>
#import <CoreLocation/CoreLocation.h>

#import "Config.h"

#define kUpdateFrequency	60.0

@interface ViewController : UIViewController<UIAccelerometerDelegate, SPTAudioStreamingDelegate, SPTAudioStreamingPlaybackDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, CLLocationManagerDelegate>

//UI
@property (weak, nonatomic) IBOutlet UILabel *miles;
@property (weak, nonatomic) IBOutlet UIButton *startLargeBtn;
@property (weak, nonatomic) IBOutlet UIButton *isMusicBtn;
@property (weak, nonatomic) IBOutlet UIButton *pauseBtn;
@property (weak, nonatomic) IBOutlet UIButton *stopBtn;
@property (weak, nonatomic) IBOutlet UIButton *startSmallBtn;
@property (weak, nonatomic) IBOutlet UIButton *shareBtn;
@property (weak, nonatomic) IBOutlet UIButton *takePhotoBtn;

- (IBAction)startLargeBtnPressed:(id)sender;
- (IBAction)isMusicBtnPressed:(id)sender;
- (IBAction)nextSongBtnPressed:(id)sender;
- (IBAction)pauseBtnPressed:(id)sender;
- (IBAction)stopBtnPressed:(id)sender;
- (IBAction)startSmallBtnPressed:(id)sender;
- (IBAction)shareBtnPressed:(id)sender;
- (IBAction)takePhoto:(id)sender;


//Play music
@property (nonatomic, strong) SPTSession *session;
@property (nonatomic, strong) SPTAudioStreamingController *player;
@property (nonatomic) NSInteger stage;

-(void)handleNewSession:(SPTSession *)session;


//Tempo
@property (strong, nonatomic) CMMotionManager *motionManager;

@property (nonatomic, strong) NSMutableArray *date_array;
@property (nonatomic, strong) NSDate *lastDate;


//Location
@property (strong, nonatomic) CLLocationManager *locationManager;
@property (strong, nonatomic) CLLocation *lastLocation;
@property (nonatomic) double distance;


//Share
@property (strong, nonatomic) UIImage *image;

@end

