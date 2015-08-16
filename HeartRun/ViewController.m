//
//  ViewController.m
//  HeartRun
//
//  Created by 鲁辰 on 7/30/15.
//  Copyright (c) 2015 ChenLu. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _stage = 2;// 2 - slow, 1 - warmup, 0 - heat
    
    //Tempo Init
    self.motionManager = [[CMMotionManager alloc] init];
    self.motionManager.accelerometerUpdateInterval = 1.0 / kUpdateFrequency;
    
    [self.motionManager startAccelerometerUpdatesToQueue:[NSOperationQueue currentQueue]
                                             withHandler:^(CMAccelerometerData  *accelerometerData, NSError *error) {
                                                 [self outputAccelerationData:accelerometerData.acceleration];
                                                 if(error){
                                                     NSLog(@"%@", error);
                                                 }
                                             }];
    
    NSThread* myThread = [[NSThread alloc] initWithTarget:self
                                                 selector:@selector(run)
                                                   object:nil];
    [myThread start];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


///////////////////////////////// User Interface /////////////////////////////////
- (IBAction)startLargeBtnPressed:(id)sender {
    _pauseBtn.hidden = NO;
    _startLargeBtn.hidden = YES;
    [self playUsingSession:_session];
    
    //Location Init
    [self startLocationUpdates];
    //[self.locationManager stopUpdatingLocation];
}

- (IBAction)isMusicBtnPressed:(id)sender {
    if (self.player.isPlaying) {
        UIImage *btnImage = [UIImage imageNamed:@"nomusic.png"];
        [_isMusicBtn setImage:btnImage forState:UIControlStateNormal];
    } else {
        UIImage *btnImage = [UIImage imageNamed:@"music.png"];
        [_isMusicBtn setImage:btnImage forState:UIControlStateNormal];
    }

    [self.player setIsPlaying:!self.player.isPlaying callback:nil];
}

- (IBAction)nextSongBtnPressed:(id)sender {
    [self.player skipNext:nil];
}

- (IBAction)pauseBtnPressed:(id)sender {
    _stopBtn.hidden = NO;
    _startSmallBtn.hidden = NO;
    _pauseBtn.hidden = YES;
    [self.player setIsPlaying:NO callback:nil];
    [self.locationManager stopUpdatingLocation];
}

- (IBAction)stopBtnPressed:(id)sender {
    _shareBtn.hidden = NO;
    _takePhotoBtn.hidden = NO;
    _stopBtn.hidden = YES;
    _startSmallBtn.hidden = YES;
    [self.player setIsPlaying:NO callback:nil];
    
    self.lastLocation = nil;
    self.lastDate = nil;
    self.date_array = nil;
}

- (IBAction)startSmallBtnPressed:(id)sender {
    _pauseBtn.hidden = NO;
    _stopBtn.hidden = YES;
    _startSmallBtn.hidden = YES;
    [self.player setIsPlaying:YES callback:nil];
    [self.locationManager startUpdatingLocation];
}

- (IBAction)shareBtnPressed:(id)sender {
    _startLargeBtn.hidden = NO;
    _shareBtn.hidden = YES;
    _takePhotoBtn.hidden = YES;
    [self tweetMedia];
}

- (IBAction)takePhoto:(id)sender {
    // Camera
    if (![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error"
                                                            message:@"Device has no camera"
                                                           delegate:nil
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles: nil];
        [alertView show];
        return;
    }
    
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        UIImagePickerController *picker = [[UIImagePickerController alloc] init];
        picker.delegate = self;
        picker.sourceType = UIImagePickerControllerSourceTypeCamera;
        picker.allowsEditing = NO;
        
        [self presentViewController:picker animated:YES completion:nil];
    }
}


///////////////////////////////// Play Music /////////////////////////////////
-(void)handleNewSession:(SPTSession *)session {
    self.session = session;
    
    if (self.player == nil) {
        self.player = [[SPTAudioStreamingController alloc] initWithClientId:@kClientId];
        self.player.playbackDelegate = self;
    }
    
    [self.player loginWithSession:session callback:^(NSError *error) {
        if (error != nil) {
            NSLog(@"*** Enabling playback got error: %@", error);
            return;
        }
        //[self playUsingSession:session];
    }];
}

-(void)playUsingSession:(SPTSession *)session {
    
    // Create a new player if needed
    if (self.player == nil) {
        self.player = [[SPTAudioStreamingController alloc] initWithClientId:@kClientId];
    }
    
    [self.player loginWithSession:session callback:^(NSError *error) {
        if (error != nil) {
            NSLog(@"*** Logging in got error: %@", error);
            return;
        }
        
        NSURL *trackURI = [NSURL URLWithString:@"spotify:user:blindchaser:playlist:5VNYun6eCtG6DVQAyZmC6W"];
        [self.player playURIs:@[ trackURI ] fromIndex:0 callback:^(NSError *error) {
            if (error != nil) {
                NSLog(@"*** Starting playback got error: %@", error);
                return;
            }
        }];
    }];
}

-(void)switchTrack {
    
    NSLog(@"Switch Track, %d", _stage);
    
    NSURL *trackURI;
    if (_stage == 0) {// Heat List
        trackURI = [NSURL URLWithString:@"spotify:user:playalistic-sweden:playlist:3bqLq0LzRzvQ0dIkRlYtKS"];
    } else if (_stage == 1) { // Warm-up List
        trackURI = [NSURL URLWithString:@"spotify:user:spotify:playlist:16BpjqQV1Ey0HeDueNDSYz"];
    } else { // Cool List
        trackURI = [NSURL URLWithString:@"spotify:user:charlotepirkis4:playlist:5rqxR5EqAMxAjADUURi9rc"];
    }
    
    [self.player playURIs:@[ trackURI ] fromIndex:0 callback:^(NSError *error) {
        if (error != nil) {
            NSLog(@"*** Starting playback got error: %@", error);
            return;
        }
    }];
}


///////////////////////////////// Tempo /////////////////////////////////
- (void) outputAccelerationData:(CMAcceleration)acceleration
{
    //init lastDate
    if (self.lastDate == nil) {
        self.lastDate = [NSDate date];
        _date_array = [[NSMutableArray alloc] init];
        [_date_array addObject:self.lastDate];
        return;
    }
    
    NSDate *current = [NSDate date];
    NSTimeInterval secs = [_lastDate timeIntervalSinceDate:current];
    
    if (acceleration.y < -0.8 && fabs(secs) > 0.5) {
        [_date_array addObject:current];
        if ([_date_array count] > 20)
            [_date_array removeObjectAtIndex:0];
        
        _lastDate = current;
        
        //NSLog(@"%f", secs);
        //NSLog(@"%f", fabs(acceleration.y));
    }
}

-(double) getTempo{
    if (_date_array == nil) {
        return 5.0;
    }
    NSDate *start = [_date_array objectAtIndex:0];
    NSInteger endCount = [_date_array count];
    NSDate *end = [_date_array objectAtIndex:(endCount - 1)];
    NSTimeInterval secs = [start timeIntervalSinceDate:end];
    
    NSDate *now = [NSDate date];
    NSTimeInterval interval = [now timeIntervalSinceDate:end];
    
    return interval > 3 ? (interval * fabs(secs) / endCount) : (fabs(secs) / endCount);
}

- (void)run {
    while (YES) {
        double tempo = 0.0;
        @synchronized(self) {
            tempo = [self getTempo];
        }
        NSLog(@"Tempo: %f", tempo);
        if (self.player.isPlaying) {
            if ([_date_array count] < 15) {
                continue;
            }
            if (tempo > 4 && _stage < 2) {
                //slow
                _stage = 2;
                [self switchTrack];
            } else if ((tempo <= 4 && tempo > 0.7) && _stage != 1) {
                //medium
                _stage = 1;
                [self switchTrack];
            } else if (tempo <= 0.7 && _stage != 0) {
                //fast
                _stage = 0;
                [self switchTrack];
            }
        }
        sleep(1);// Change to 3 to get a smooth switch
    }
}


///////////////////////////////// Camera /////////////////////////////////
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {

    UIImage *chosenImage = info[UIImagePickerControllerOriginalImage];
    _image = chosenImage;
        
    UIImageWriteToSavedPhotosAlbum(_image, nil, nil, nil);
    [picker dismissViewControllerAnimated:YES completion:NULL];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:NULL];
}

- (void)tweetMedia {
    NSLog(@"Tweet!");
    if ([SLComposeViewController isAvailableForServiceType:SLServiceTypeTwitter])
    {
            
        SLComposeViewController *tweetSheet = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeTwitter];
        NSString *ss = [[NSString alloc] initWithFormat:@"I ran %@ miles using HeartRun today!", _miles.text];
        [tweetSheet setInitialText:ss];
            
        //Add image
        if (_image != nil) {
            [tweetSheet addImage:_image];
        }
            
        [self presentViewController:tweetSheet animated:YES completion:^{
            NSLog(@"Photo uploaded.");
        }];
    }
    else
    {
        UIAlertView *alertView = [[UIAlertView alloc]
                                      initWithTitle:@"Sorry"
                                      message:@"You can't send a tweet right now, make sure your device has an internet connection and you have at least one Twitter account setup"
                                      delegate:self
                                      cancelButtonTitle:@"OK"
                                      otherButtonTitles:nil];
        [alertView show];
    }
}


///////////////////////////////// Location /////////////////////////////////
- (void)startLocationUpdates
{
    // Create the location manager if this object does not
    // already have one.
    if (self.locationManager == nil) {
        self.locationManager = [[CLLocationManager alloc] init];
    }
    
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0)
        [_locationManager requestAlwaysAuthorization];
    
    self.locationManager.delegate = self;
    self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    self.locationManager.activityType = CLActivityTypeFitness;
    
    // Movement threshold for new events.
    self.locationManager.distanceFilter = 0.05; // meters
    
    [self.locationManager startUpdatingLocation];
}

-(void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    CLLocation *curLocation = self.locationManager.location;
    
    if (_lastLocation == nil) {
        _lastLocation = curLocation;
        return;
    }
    
    _distance += [curLocation distanceFromLocation:_lastLocation];
    _lastLocation = curLocation;
    
    //NSLog(@"%f", _distance);
    //NSLog(@"%@", [NSString stringWithFormat:@"%.3fmi",(_distance/1609.344)]);
    
    self.miles.text = [NSString stringWithFormat:@"%.3f",(_distance/1609.344)];
}


@end
