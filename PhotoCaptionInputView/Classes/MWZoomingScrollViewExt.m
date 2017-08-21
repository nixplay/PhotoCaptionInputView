//
//  MWZoomingScrollViewExt.m
//  Pods
//
//  Created by James Kong on 18/8/2017.
//
//

#import "MWZoomingScrollViewExt.h"
#import "ICGVideoTrimmerView.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import <AVFoundation/AVFoundation.h>

@interface MWZoomingScrollViewExt ()<ICGVideoTrimmerDelegate>{
    NSURL* _url;
    CGRect _photoImageViewFrame;
    UITapGestureRecognizer * _tap;
    BOOL _isLoop;
}
@property (strong, nonatomic) AVPlayer *player;
@property (strong, nonatomic) AVPlayerItem *playerItem;
@property (strong, nonatomic) AVPlayerLayer *playerLayer;
@property (strong, nonatomic) NSTimer *playbackTimeCheckerTimer;
@property (assign, nonatomic) CGFloat videoPlaybackPosition;

@property (strong, nonatomic) ICGVideoTrimmerView *trimmerView;
@property (strong, nonatomic) UIView *videoPlayer;
@property (strong, nonatomic) UIView *videoLayer;

@property (strong, nonatomic) NSString *tempVideoPath;
@property (strong, nonatomic) AVAsset *asset;

@property (assign, nonatomic) CGFloat startTime;
@property (assign, nonatomic) CGFloat stopTime;
@property (assign, nonatomic) BOOL isPlaying;
@property (assign, nonatomic) BOOL restartOnPlay;
@property (assign, nonatomic) BOOL initTrimmer;
@end
@implementation MWZoomingScrollViewExt
@synthesize playButton = _playButton;
@synthesize startTime = _startTime;
@synthesize stopTime = _stopTime;
@synthesize initTrimmer = _initTrimmer;
- (id)initWithPhotoBrowser:(MWPhotoBrowser *)browser {
    if ((self = [super initWithPhotoBrowser:browser])) {
        _startTime = -1;
        _stopTime = -1;
        _isLoop = NO;
        _initTrimmer = NO;
    }
    return self;
}

- (void)prepareForReuse {
    [super prepareForReuse];
    self.isPlaying = NO;
    [self.player pause];
    _startTime = -1;
    _stopTime = -1;
    _initTrimmer = NO;
    self.asset = nil;
    self.player = nil;
    self.playerLayer = nil;
    self.videoLayer = nil;
    self.videoPlayer = nil;
    self.trimmerView = nil;
    [self playButton].hidden = NO;
}

-(void) setPlayButton:(UIButton*)button{
    _playButton = button;
    [_playButton addTarget:self action:@selector(onPlayButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
}
- (void)setPhoto:(id<MWPhoto>)photo {
    [super setPhoto:photo];
    if(self.photo == nil){
        _startTime = -1;
        _stopTime = -1;
        _initTrimmer = NO;
        self.asset = nil;
//        [self.avPlayerView removeFromSuperview];
//        self.avPlayerView = nil;
        self.player = nil;
        [self.videoPlayer removeFromSuperview];
        [self.videoLayer removeFromSuperview];
        [self.playerLayer removeFromSuperlayer];
        [self.trimmerView removeFromSuperview];
        self.playerLayer = nil;
        self.videoLayer = nil;
        self.videoPlayer = nil;
        self.trimmerView = nil;
    }else{
        //        if(photo.isVideo){
        //
        //            typeof(self) __weak weakSelf = self;
        //            [self.photo getVideoURL:^(NSURL *url) {
        //                NSLog(@"url %@",url);
        //                dispatch_async(dispatch_get_main_queue(), ^{
        //                    // If the video is not playing anymore then bail
        //                    typeof(self) strongSelf = weakSelf;
        //                    if (!strongSelf) return;
        //
        //                    if (url) {
        //                        [strongSelf setupVideoPreview:strongSelf url:url];
        //
        //                    } else {
        //
        //                    }
        //                });
        //            }];
        //        }
    }
}
-(void) displaySubView:(CGRect)photoImageViewFrame{
//    _photoImageViewFrame = photoImageViewFrame;
    if(self.photo.isVideo){
        
        typeof(self) __weak weakSelf = self;
        [self.photo getVideoURL:^(NSURL *url) {
            NSLog(@"url %@",url);
            dispatch_async(dispatch_get_main_queue(), ^{
                // If the video is not playing anymore then bail
                typeof(self) strongSelf = weakSelf;
                if (!strongSelf) return;
                
                if (url) {
                    _url = url;
                    
                    [self setupVideoPreviewUrl:_url photoImageViewFrame:_photoImageViewFrame];
                    
                    
                } else {
                    
                }
            });
        }];
    }
    
}
-(void) setupVideoPreviewUrl:(NSURL*)url photoImageViewFrame:(CGRect)photoImageViewFrame{
    if(self.trimmerView == nil || self.trimmerView.superview != nil){
        self.asset = [AVAsset assetWithURL:url];
        
        AVPlayerItem *item = [AVPlayerItem playerItemWithAsset:self.asset];
        
        self.player = [AVPlayer playerWithPlayerItem:item];
        self.playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.player];
        self.playerLayer.contentsGravity = AVLayerVideoGravityResizeAspect;
        self.player.actionAtItemEnd = AVPlayerActionAtItemEndNone;
        
        self.videoLayer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320,240)];
        self.videoPlayer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320,240)];
        [self.playerLayer setFrame:CGRectMake(0, 0, 320,240)];
        [self.videoPlayer addSubview:self.videoLayer];
        [self addSubview:self.videoPlayer];
        self.videoLayer.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleRightMargin;
  
        self.videoPlayer.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleRightMargin;
        [self.videoLayer.layer addSublayer:self.playerLayer];
        
//        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapOnVideoLayer:)];
        self.videoLayer.tag = 1;
        
//        [self addGestureRecognizer:tap];
        
        self.videoPlaybackPosition = 0;
//        [self resetTrimmerSubview];
        
    }
    
}

- (void)layoutSubviews {
    [super layoutSubviews];
    if(_trimmerView != nil){
        if(!_initTrimmer){
            [self.trimmerView resetSubviews];
            
            self.videoPlayer.frame = _photoImageViewFrame;
            self.videoLayer.frame = CGRectMake(0, 0, CGRectGetWidth(_photoImageViewFrame), CGRectGetHeight(_photoImageViewFrame));
            [self.playerLayer removeFromSuperlayer];
            self.playerLayer.frame = CGRectMake(0, 0, CGRectGetWidth(_photoImageViewFrame), CGRectGetHeight(_photoImageViewFrame));
            [self.videoLayer.layer addSublayer:self.playerLayer];
            
            _initTrimmer = YES;
        }
    }
}

-(void) setFrameToCenter:(CGRect)frameToCenter{
    _photoImageViewFrame = frameToCenter;
    
}

- (void)resetTrimmerSubview{
    if(_startTime == -1 && _stopTime == -1){
        if(_url != nil && _trimmerView == nil){
            if(self.trimmerView == nil){
                self.trimmerView = [[ICGVideoTrimmerView alloc] initWithFrame:CGRectMake(10, 100, CGRectGetWidth(self.frame)-20, 80) asset:self.asset];
                [self.trimmerView setDelegate:self];
                // set properties for trimmer view
                [self.trimmerView setThumbWidth:20];
                [self.trimmerView setThemeColor:[UIColor lightGrayColor]];
                [self.trimmerView setShowsRulerView:YES];
                [self.trimmerView setMaxLength:10];
                
                [self.trimmerView setRulerLabelInterval:10];
                
                [self.trimmerView setTrackerColor:[UIColor cyanColor]];
                
                
                // important: reset subviews
                [self addSubview: _trimmerView];
                self.trimmerView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin |
                UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleRightMargin;
//
            }
            //            [self setupVideoPreview:self url:_url photoImageViewFrame:_photoImageViewFrame];
        }
//        if(_trimmerView != nil){
//            [self.trimmerView resetSubviews];
//        }
    }
    
}

- (void) tapOnVideoLayer:(UITapGestureRecognizer *)tap
{
    [self onVideoTapped];
}

-(void) onPlayButtonPressed:(id) sender{
    
    [self onVideoTapped];
    
    _tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapOnVideoLayer:)];
    [self addGestureRecognizer:_tap];
    

}
- (void) onVideoTapped{
    
    
    
    if (self.isPlaying) {
        if(_tap != nil){
            [self removeGestureRecognizer:_tap];
        }

        [self.player pause];
        [self stopPlaybackTimeChecker];
        [self playButton].hidden = NO;
    }else {
        
        
        [self playButton].hidden = YES;
        if (_restartOnPlay){
            [self seekVideoToPos: _startTime];
            [self.trimmerView seekToTime:_startTime];
            _restartOnPlay = NO;
        }
        [self.player play];
        [self startPlaybackTimeChecker];
    }
    self.isPlaying = !self.isPlaying;
    [self.trimmerView hideTracker:!self.isPlaying];
    
}
- (void)startPlaybackTimeChecker
{
    [self stopPlaybackTimeChecker];
    
    self.playbackTimeCheckerTimer = [NSTimer scheduledTimerWithTimeInterval:0.1f target:self selector:@selector(onPlaybackTimeCheckerTimer) userInfo:nil repeats:YES];
}

- (void)stopPlaybackTimeChecker
{
    if (self.playbackTimeCheckerTimer) {
        [self.playbackTimeCheckerTimer invalidate];
        self.playbackTimeCheckerTimer = nil;
    }
}


#pragma mark - PlaybackTimeCheckerTimer

- (void)onPlaybackTimeCheckerTimer
{
    CMTime curTime = [self.player currentTime];
    Float64 seconds = CMTimeGetSeconds(curTime);
    if (seconds < 0){
        seconds = 0; // this happens! dont know why.
    }
    self.videoPlaybackPosition = seconds;
    
    [self.trimmerView seekToTime:seconds];
    
    if (self.videoPlaybackPosition >= _stopTime) {
        self.videoPlaybackPosition = _startTime;
        [self seekVideoToPos: _startTime];
        [self.trimmerView seekToTime:_startTime];
        if(!_isLoop){
            [self.playButton setHidden:NO];
            [self.player pause];
        }
    }
}

- (void)seekVideoToPos:(CGFloat)pos
{
    self.videoPlaybackPosition = pos;
    CMTime time = CMTimeMakeWithSeconds(self.videoPlaybackPosition, self.player.currentTime.timescale);
    //NSLog(@"seekVideoToPos time:%.2f", CMTimeGetSeconds(time));
    [self.player seekToTime:time toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
}

/*
 // Only override drawRect: if you perform custom drawing.
 // An empty implementation adversely affects performance during animation.
 - (void)drawRect:(CGRect)rect {
 // Drawing code
 }
 */
#pragma mark - ICGVideoTrimmerDelegate

- (void)trimmerView:(ICGVideoTrimmerView *)trimmerView didChangeLeftPosition:(CGFloat)startTime rightPosition:(CGFloat)endTime
{
    _restartOnPlay = YES;
    [self.player pause];
    self.isPlaying = NO;
    [self stopPlaybackTimeChecker];
    
    [self.trimmerView hideTracker:true];
    
    if (startTime != _startTime) {
        //then it moved the left position, we should rearrange the bar
        [self seekVideoToPos:startTime];
    }
    else{ // right has changed
        [self seekVideoToPos:endTime];
    }
    _startTime = startTime;
    _stopTime = endTime;
    
}

@end
