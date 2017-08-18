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
@end
@implementation MWZoomingScrollViewExt


- (void)setPhoto:(id<MWPhoto>)photo {
    [super setPhoto:photo];
    if(self.photo == nil){
        self.asset = nil;
        self.player = nil;
        [self.videoPlayer removeFromSuperview];
        [self.videoLayer removeFromSuperview];
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
                        [strongSelf setupVideoPreview:strongSelf url:url];
                        
                    } else {
                        
                    }
                });
            }];
        }
    }
}

-(void) setupVideoPreview:(MWZoomingScrollViewExt *) scrollView url:(NSURL*)url{
    if(scrollView.trimmerView == nil || scrollView.trimmerView.superview != nil){
        scrollView.asset = [AVAsset assetWithURL:url];
        
        AVPlayerItem *item = [AVPlayerItem playerItemWithAsset:scrollView.asset];
        
        scrollView.player = [AVPlayer playerWithPlayerItem:item];
        scrollView.playerLayer = [AVPlayerLayer playerLayerWithPlayer:scrollView.player];
        scrollView.playerLayer.contentsGravity = AVLayerVideoGravityResizeAspect;
        scrollView.player.actionAtItemEnd = AVPlayerActionAtItemEndNone;
        
        scrollView.videoLayer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, scrollView.frame.size.width, scrollView.frame.size.height)];
        scrollView.videoPlayer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, scrollView.frame.size.width, scrollView.frame.size.height)];
        
        [scrollView.videoPlayer addSubview:scrollView.videoLayer];
        [scrollView addSubview:scrollView.videoPlayer];
        scrollView.videoLayer.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin |
        UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleRightMargin;
        [scrollView.videoLayer.layer addSublayer:scrollView.playerLayer];
        
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:scrollView action:@selector(tapOnVideoLayer:)];
        scrollView.videoLayer.tag = 1;
        scrollView.playerLayer.frame = CGRectMake(0, 0, scrollView.videoLayer.frame.size.width, scrollView.videoLayer.frame.size.height);
        [scrollView.videoLayer addGestureRecognizer:tap];
        
        scrollView.videoPlaybackPosition = 0;
        
        //                            [scrollView tapOnVideoLayer:tap];
        scrollView.trimmerView = [[ICGVideoTrimmerView alloc] initWithFrame:CGRectMake(0, 50, CGRectGetWidth(scrollView.frame), 50)];
        // set properties for trimmer view
        [scrollView.trimmerView setThemeColor:[UIColor lightGrayColor]];
        [scrollView.trimmerView setAsset:scrollView.asset];
        [scrollView.trimmerView setShowsRulerView:YES];
        [scrollView.trimmerView setRulerLabelInterval:10];
        
        [scrollView.trimmerView setTrackerColor:[UIColor cyanColor]];
        [scrollView.trimmerView setDelegate:scrollView];
        
        // important: reset subviews
        [scrollView addSubview: _trimmerView];
        scrollView.trimmerView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin |
        UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleRightMargin;
        [scrollView.trimmerView resetSubviews];
    }

}

- (void)tapOnVideoLayer:(UITapGestureRecognizer *)tap
{
    if (self.isPlaying) {
        [self.player pause];
        [self stopPlaybackTimeChecker];
    }else {
        if (_restartOnPlay){
            [self seekVideoToPos: self.startTime];
            [self.trimmerView seekToTime:self.startTime];
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
    
    if (self.videoPlaybackPosition >= self.stopTime) {
        self.videoPlaybackPosition = self.startTime;
        [self seekVideoToPos: self.startTime];
        [self.trimmerView seekToTime:self.startTime];
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

- (void)trimmerView:(ICGVideoTrimmerView *)trimmerView didChangeLeftPosition:(CGFloat)startTime rightPosition:(CGFloat)endTime{
    
}
@end
