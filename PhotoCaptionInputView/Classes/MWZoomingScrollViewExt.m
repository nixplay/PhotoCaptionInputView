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
#import <PryntTrimmerView/PryntTrimmerView-Swift.h>
#import "MWPhotoExt.h"
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

@property (assign, nonatomic) BOOL isPlaying;
@property (assign, nonatomic) BOOL restartOnPlay;
@property (assign, nonatomic) BOOL initTrimmer;
@end
@implementation MWZoomingScrollViewExt
@synthesize playButton = _playButton;
@synthesize startTime = _startTime;
@synthesize stopTime = _endTime;
@synthesize initTrimmer = _initTrimmer;
@synthesize mDelegate = _mDelegate;

- (id)initWithPhotoBrowser:(MWPhotoBrowser *)browser {
    if ((self = [super initWithPhotoBrowser:browser])) {
        _startTime = -1;
        _endTime = -1;
        _isLoop = YES;
        _initTrimmer = NO;
    }
    return self;
}

- (void)prepareForReuse {
    [super prepareForReuse];
    self.isPlaying = NO;
    [self.player pause];
    _startTime = -1;
    _endTime = -1;
    _initTrimmer = NO;
    _url = nil;
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
        _endTime = -1;
        _initTrimmer = NO;
        _url = nil;
        self.asset = nil;
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
        if(photo.isVideo){
            
            typeof(self) __weak weakSelf = self;
            [self.photo getVideoURL:^(NSURL *url) {
                NSLog(@"url %@",url);
                dispatch_async(dispatch_get_main_queue(), ^{
                    // If the video is not playing anymore then bail
                    typeof(self) strongSelf = weakSelf;
                    if (!strongSelf) return;
                    
                    if (url) {
                        _url = url;
                        [strongSelf setupVideoPreviewUrl:url photoImageViewFrame:CGRectZero];
                        
                    } else {
                        
                    }
                });
            }];
        }
    }
}

-(void) setupVideoPreviewUrl:(NSURL*)url photoImageViewFrame:(CGRect)photoImageViewFrame{
    if((self.trimmerView == nil || self.trimmerView.superview != nil) && self.photo.isVideo){
        self.asset = [AVAsset assetWithURL:url];
        
        AVPlayerItem *item = [AVPlayerItem playerItemWithAsset:self.asset];
        
        self.player = [AVPlayer playerWithPlayerItem:item];
        self.playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.player];
        self.playerLayer.contentsGravity = AVLayerVideoGravityResizeAspect;
        self.player.actionAtItemEnd = AVPlayerActionAtItemEndNone;
        
        self.videoLayer = [[UIView alloc] initWithFrame:CGRectZero];
        self.videoPlayer = [[UIView alloc] initWithFrame:CGRectZero];
        [self.playerLayer setFrame:CGRectZero];
        [self.videoPlayer addSubview:self.videoLayer];
        [self addSubview:self.videoPlayer];
        self.videoLayer.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleRightMargin;
        
        self.videoPlayer.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleRightMargin;
        [self.videoLayer.layer addSublayer:self.playerLayer];
        
        self.videoLayer.tag = 1;
        
        self.videoPlaybackPosition = 0;
        
        //        if(!_initTrimmer){
        //            if(_trimmerView == nil){
        //                [self resetTrimmerSubview];
        //            }
        //            if(_trimmerView != nil){
        //
        //                [_trimmerView resetSubviews];
        //
        //
        //            }
        //            _initTrimmer = YES;
        //        }
    }
    
}

- (void)layoutSubviews {
    [super layoutSubviews];
    if(self.photo.isVideo){
        if(!_initTrimmer){
            //            if(_trimmerView == nil){
            //                [self resetTrimmerSubview];
            //            }
            if(_trimmerView != nil){
                
                [_trimmerView resetSubviews];
                
                
            }
            _initTrimmer = YES;
        }
    }
}

-(void) setFrameToCenter:(CGRect)frameToCenter{
    if(self.photo.isVideo){
        if(self.videoPlayer != nil && self.videoLayer != nil && self.playerLayer != nil){
            _photoImageViewFrame = frameToCenter;
            self.videoPlayer.frame = _photoImageViewFrame;
            self.videoLayer.frame = CGRectMake(0, 0, CGRectGetWidth(_photoImageViewFrame), CGRectGetHeight(_photoImageViewFrame));
            [self.playerLayer removeFromSuperlayer];
            self.playerLayer.frame = CGRectMake(0, 0, CGRectGetWidth(_photoImageViewFrame), CGRectGetHeight(_photoImageViewFrame));
            [self.videoLayer.layer addSublayer:self.playerLayer];
        }
    }
    
}

- (void)resetTrimmerSubview{
    
    typeof(self) __weak weakSelf = self;
    [self.photo getVideoURL:^(NSURL *url) {
        NSLog(@"url %@",url);
        dispatch_async(dispatch_get_main_queue(), ^{
            // If the video is not playing anymore then bail
            typeof(self) strongSelf = weakSelf;
            if (!strongSelf) return;
            
            if (url) {
                _url = url;
                
                if(_startTime == -1 && _endTime == -1){
                    if(_url != nil && _trimmerView == nil){
                        if(self.trimmerView == nil ){
                            if(self.asset == nil){
                                self.asset = [AVAsset assetWithURL:_url];
                            }
                            self.trimmerView = [[ICGVideoTrimmerView alloc] initWithFrame:CGRectMake(10, 100, CGRectGetWidth(self.frame)-20, 50) asset:self.asset delegate:self];
                            [self.trimmerView setDelegate:self];
                            // set properties for trimmer view
                            [self.trimmerView setThumbWidth:20];
                            [self.trimmerView setThemeColor:[UIColor lightGrayColor]];
                            [self.trimmerView setShowsRulerView:NO];
                            [self.trimmerView setMaxLength:10];
                            
                            [self.trimmerView setRulerLabelInterval:10];
                            
                            [self.trimmerView setTrackerColor:[UIColor cyanColor]];
                            
                            
                            // important: reset subviews
                            [self addSubview: _trimmerView];
                            self.trimmerView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin |
                            UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleRightMargin;
                            [self.trimmerView resetSubviews];
                            
                        }
                        
                    }
                    
                }
                
            } else {
                
            }
        });
    }];
    
    
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
    
    
    if(self.photo.isVideo){
        if (self.isPlaying) {
            if(_tap != nil){
                [self removeGestureRecognizer:_tap];
            }
            
            [self.player pause];
            [self stopPlaybackTimeChecker];
            [self playButton].hidden = NO;
        }else {
            //            [self resetTrimmerSubview];
            
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
    
    if (self.videoPlaybackPosition >= _endTime) {
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
    _endTime = endTime;
    if([_mDelegate respondsToSelector:@selector(zoomingScrollView:photo:startTime:endTime:)])
    {
        [_mDelegate zoomingScrollView:self photo:self.photo  startTime:_startTime endTime:_endTime];
    }
    
}

- (void)trimmerViewDidEndEditing:(nonnull ICGVideoTrimmerView *)trimmerView{
    
}
- (void) setStartTime:(CGFloat)startTime endTime:(CGFloat)endTime{
    if(_startTime != startTime && _endTime != endTime){
        [_trimmerView setVideoBoundsToStartTime:startTime endTime:endTime];
    }
}
@end
