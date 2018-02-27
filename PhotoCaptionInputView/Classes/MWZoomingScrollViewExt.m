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
#import "MWPhotoExt.h"
#import <Masonry/Masonry.h>
@class MWPhotoBrowser;
#define LIGHT_BLUE_COLOR [UIColor colorWithRed:(96.0f/255.0f)  green:(178.0f/255.0f)  blue:(232.0f/255.0f) alpha:1.0]
#define DEFAULT_VIDEO_LENGTH 15
#define LOADING_DID_END_NOTIFICATION @"LOADING_DID_END_NOTIFICATION"
#define BUNDLE [self getBundle]
#define HINTS_MESSAGE NSLocalizedStringFromTableInBundle(@"Limited to %@ seconds. Drag the blue bars to trim the video",  @"PhotoCaptionInputView", BUNDLE, @"Limited to %@ seconds. Drag the blue bars to trim the video")
#define SELECTION NSLocalizedStringFromTableInBundle(@"Selection",  @"PhotoCaptionInputView", BUNDLE, @"Selection")
#define TO NSLocalizedStringFromTableInBundle(@"to",  @"PhotoCaptionInputView", BUNDLE, @"to")

@interface MWZoomingScrollViewExt ()<ICGVideoTrimmerDelegate>{
    NSTimer * _hintsVisibilityTimer;
    CGRect _photoImageViewFrame;
    
    BOOL _isLoop;
    
}
@property (strong, nonatomic) ICGVideoTrimmerView *trimmerView;
@property (strong, nonatomic) UILabel *timeLengthLabel;
@property (strong, nonatomic) UILabel *timeRangeLabel;
@property (strong, nonatomic) UIView *timecodeView;
@property (assign, nonatomic) BOOL restartOnPlay;
@property (assign, nonatomic) BOOL needInitTrimmer;
@property (assign, nonatomic) CGFloat startTime;
@property (assign, nonatomic) CGFloat endTime;
//dotn use contentOffeset it will mess up UIScrollView of UIScrollView
@property (assign, nonatomic) CGPoint trimmerTimeOffset;
@property (assign, nonatomic) NSURL *url;
@property (assign, nonatomic) MWPhotoBrowser* photobrowser;
    
@end
@implementation MWZoomingScrollViewExt
@synthesize startTime = _startTime;
@synthesize endTime = _endTime;
@synthesize trimmerTimeOffset = _trimmerTimeOffset;
@synthesize needInitTrimmer = _needInitTrimmer;

    
- (id)initWithPhotoBrowser:(MWPhotoBrowser *)browser {
    if ((self = [super initWithPhotoBrowser:browser])) {
        _startTime = -1;
        _endTime = -1;
        _isLoop = YES;
        self.needInitTrimmer = NO;
        [self listeningRotating];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handleLoadingDidEndNotification:)
                                                     name:LOADING_DID_END_NOTIFICATION
                                                   object:nil];
        self.photobrowser = browser;
    }
    return self;
}

-(NSBundle*) getBundle{
    NSBundle * bundle = [NSBundle bundleWithURL:[[NSBundle bundleForClass:[self class]] URLForResource:@"PhotoCaptionInputView" withExtension:@"bundle"]];
    NSLog(@" %@",[bundle localizations]);
    return bundle;
}

- (void)listeningRotating {
    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onDeviceOrientationChange)
                                                 name:UIDeviceOrientationDidChangeNotification
                                               object:nil];
}
    
- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[UIDevice currentDevice] endGeneratingDeviceOrientationNotifications];
//    [[NSNotificationCenter defaultCenter] removeObserver:self name:LOADING_DID_END_NOTIFICATION object:nil];
}

-(void) hideHints{
    if (_hintsVisibilityTimer) {
        [_hintsVisibilityTimer invalidate];
        _hintsVisibilityTimer = nil;
    }
}
#pragma mark - MWPhoto Loading Notification
    
- (void)handleLoadingDidEndNotification:(NSNotification *)notification {
    MWZoomingScrollViewExt *strongSelf = notification.object;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self hideHints];
       _hintsVisibilityTimer = [NSTimer scheduledTimerWithTimeInterval:2 target:self selector:@selector(hideHints) userInfo:nil repeats:NO];
        //        typeof(self) strongSelf = self;
        
        if (!strongSelf) return;
        if(!strongSelf.needInitTrimmer){
            strongSelf.needInitTrimmer = YES;
            if(strongSelf.asset == nil){
                return;
            }
            ((MWPhoto*)strongSelf.photo).videoURL = strongSelf.url;
            [strongSelf setupVideoPreviewAsset:strongSelf.asset photoImageViewFrame:strongSelf.frame];
            //            NSLog(@"description %@",strongSelf.description);
            if(strongSelf.startTime == -1 && strongSelf.endTime == -1 && strongSelf.trimmerView == nil && strongSelf.trimmerView == nil ){
                
                //restore time range before init
                MWPhotoExt *photoExt = strongSelf.photo;
                CGFloat restoredStartTime = strongSelf.startTime;
                CGFloat restoredEndTime = strongSelf.endTime;
                CGPoint restoredTrimmerTimeOffset = strongSelf.trimmerTimeOffset;
                if(photoExt.startEndTime != nil){
                    restoredStartTime = [[photoExt.startEndTime valueForKey:@"startTime"] floatValue];
                    restoredEndTime = [[photoExt.startEndTime valueForKey:@"endTime"] floatValue];
                    restoredTrimmerTimeOffset = CGPointMake([[photoExt.startEndTime valueForKey:@"contentOffsetX"] floatValue], [[photoExt.startEndTime valueForKey:@"contentOffsetY"] floatValue]);
                }
                
                ;
                CGRect frame = CGRectMake(5, [UIApplication sharedApplication].statusBarFrame.size.height+44, CGRectGetWidth(strongSelf.frame)-20, 50);
                
                Float64 assetDuration = CMTimeGetSeconds( strongSelf.asset.duration );
                if( assetDuration == 0 ){
                    NSLog(@"WARNING: Could not load av asset");
                    return;
                }
                strongSelf.trimmerView = [[ICGVideoTrimmerView alloc] initWithFrame:frame asset:strongSelf.asset delegate:strongSelf];
                strongSelf.trimmerView.minLength = (assetDuration < 3 ) ? 0 : 3;
                [strongSelf.trimmerView setDelegate:strongSelf];
                // set properties for trimmer view
                [strongSelf.trimmerView setThumbWidth:20];
                [strongSelf.trimmerView setThemeColor:LIGHT_BLUE_COLOR];
                [strongSelf.trimmerView setShowsRulerView:NO];
                [strongSelf.trimmerView setMaxLength:assetDuration < DEFAULT_VIDEO_LENGTH ? assetDuration : DEFAULT_VIDEO_LENGTH];
                
                [strongSelf.trimmerView setRulerLabelInterval:10];
                
                [strongSelf.trimmerView setTrackerColor:LIGHT_BLUE_COLOR];
                if(@available(iOS 11, *)){
                }else{
                    [strongSelf.trimmerView setFrame:frame];
                    strongSelf.trimmerView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin  | UIViewAutoresizingFlexibleWidth |
                    UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleRightMargin;
                }
                [[strongSelf.trimmerView layer] setCornerRadius:5];
                
                CGRect frame2 = CGRectMake(frame.origin.x, frame.origin.y + frame.size.height+5 , frame.size.width, 20);
                UIView *timecodeView = [[UIView alloc] initWithFrame:CGRectZero];
                
                [timecodeView setBackgroundColor:[UIColor colorWithWhite:0 alpha:0.5]];
                [timecodeView.layer setCornerRadius:10];
                strongSelf.timecodeView = timecodeView;
                if(@available(iOS 11, *)){
                }else{
                    [strongSelf.timecodeView setFrame:frame2];
                    strongSelf.timecodeView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin  | UIViewAutoresizingFlexibleWidth |
                    UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleRightMargin;
                }
                
                UILabel * timeRangeLabel = [[UILabel alloc] initWithFrame:CGRectZero];
                if(@available(iOS 11, *)){
                }else{
                    [timeRangeLabel setFrame:CGRectMake(0, 0, frame2.size.width, frame2.size.height)];
                    
                }
                timeRangeLabel.textAlignment = NSTextAlignmentCenter;
                
                [timeRangeLabel setFont:[UIFont systemFontOfSize:11]];
                [timeRangeLabel adjustsFontSizeToFitWidth];
                [timeRangeLabel setTextColor:[UIColor whiteColor]];
                
                strongSelf.timeRangeLabel = timeRangeLabel;
                [timecodeView addSubview:strongSelf.timeRangeLabel];
                
                UILabel * timeLengthLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, frame2.size.width*0.3-20, frame2.size.height)];

                
                timeLengthLabel.textAlignment = NSTextAlignmentCenter;
                [timeLengthLabel setText:@"00:00:00"];
                [timeLengthLabel setTextColor:[UIColor whiteColor]];
                [timeLengthLabel.layer setBackgroundColor:[[UIColor colorWithWhite:0 alpha:0.3] CGColor]];
                
                [timeLengthLabel setFont:[UIFont systemFontOfSize:12]];
                [timeLengthLabel.layer setMasksToBounds:YES];
                timeLengthLabel.layer.cornerRadius = 8;
                timeLengthLabel.clipsToBounds = YES;
                [strongSelf addSubview:timeLengthLabel];
                if(@available(iOS 11, *)){
                }else{
                    [timeLengthLabel setNeedsLayout];
                    
                    
                    CGRect frame = timeLengthLabel.frame;
                    frame.origin.y = self.frame.origin.y+25;
                    frame.origin.x = self.frame.size.width*0.5f - frame.size.width*0.5f;
                    timeLengthLabel.frame = frame;
                    timeLengthLabel.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin  | UIViewAutoresizingFlexibleWidth |
                    UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleRightMargin;
                }
                
                strongSelf.timeLengthLabel = timeLengthLabel;
                
                
                
                
                // important: reset subviews
                [strongSelf addSubview: strongSelf.trimmerView];
                [strongSelf addSubview: strongSelf.timecodeView];
                if(@available(iOS 11, *)){
                    
                    //ref : https://stackoverflow.com/questions/33141343/autolayout-invalid-related-to-hidden-navigationbar-in-xib 
                    float labelTopPadding = (strongSelf.photobrowser.navigationController.navigationBar.alpha==1) ? -25 : 10 ;
                    float topPadding = (strongSelf.photobrowser.navigationController.navigationBar.alpha==1) ? 0 : 50 ;
                    UIEdgeInsets padding = UIEdgeInsetsMake(topPadding, 10, 0, -10);
                    
                    [strongSelf.timeLengthLabel mas_makeConstraints:^(MASConstraintMaker *make) {
                        make.centerX.equalTo(strongSelf.timecodeView.mas_centerX);
                        if(@available(iOS 11, *)){
                            make.top.equalTo(strongSelf.mas_safeAreaLayoutGuideTop).with.offset(labelTopPadding);
                        }else{
                            make.top.equalTo(strongSelf.mas_top).with.offset(labelTopPadding);
                        }
                        make.width.mas_equalTo(frame2.size.width*0.3);
                        make.height.mas_equalTo(frame2.size.height);
                    }];
                    
                    [strongSelf.trimmerView mas_makeConstraints:^(MASConstraintMaker *make) {
                        
                        if(@available(iOS 11, *)){
                            make.top.equalTo( strongSelf.timeLengthLabel.mas_safeAreaLayoutGuideTop).with.offset(padding.top);
                            make.right.equalTo( strongSelf.trimmerView.superview.mas_safeAreaLayoutGuideRight).with.offset(padding.right);
                            make.left.equalTo( strongSelf.trimmerView.superview.mas_safeAreaLayoutGuideLeft).with.offset(padding.left);
                        }else{
                            make.top.equalTo( strongSelf.timeLengthLabel.mas_top).with.offset(padding.top);
                            make.right.equalTo( strongSelf.trimmerView.superview.mas_right).with.offset(padding.right);
                            make.left.equalTo( strongSelf.trimmerView.superview.mas_left).with.offset(padding.left);
                        }
                        make.height.mas_equalTo(frame.size.height);
                        make.width.mas_equalTo(frame.size.width);
                        
                    }];
                    [timecodeView mas_makeConstraints:^(MASConstraintMaker *make) {
                        if(@available(iOS 11, *)){
                            make.top.equalTo( strongSelf.trimmerView.mas_bottom ).with.offset(10);
                            make.right.equalTo( timecodeView.superview.mas_safeAreaLayoutGuideRight).with.offset(padding.right);
                            make.left.equalTo( timecodeView.superview.mas_safeAreaLayoutGuideLeft).with.offset(padding.left);
                        }else{
                            make.top.equalTo( strongSelf.trimmerView.mas_bottom).with.offset(padding.top);
                            make.right.equalTo( timecodeView.superview.mas_right).with.offset(padding.right);
                            make.left.equalTo( timecodeView.superview.mas_left).with.offset(padding.left);
                        }
                        make.height.mas_equalTo(frame2.size.height);
                    }];
                    
                    [strongSelf.timeRangeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
                        make.centerX.equalTo(strongSelf.timecodeView.mas_centerX);
                        make.centerY.equalTo(strongSelf.timecodeView.mas_centerY);
                    }];
                    
                }
                //                    strongSelf.trimmerView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin |
                //                    UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleRightMargin;
                //                    NSLog(@"[strongSelf.trimmerView resetSubviews]");
//                [strongSelf.trimmerView resetSubviews];
                if(restoredStartTime != -1 && restoredEndTime != -1){
                    strongSelf.startTime = restoredStartTime;
                    strongSelf.endTime = restoredEndTime;
                    strongSelf.trimmerTimeOffset = restoredTrimmerTimeOffset;
                    [strongSelf.trimmerView setVideoBoundsToStartTime: restoredStartTime endTime:(restoredEndTime > DEFAULT_VIDEO_LENGTH ) ? floor(restoredEndTime) : restoredEndTime contentOffset:restoredTrimmerTimeOffset];
                    [strongSelf setVideoRangeLabelWithSring:[NSString stringWithFormat:@"%@: %@ %@ %@", SELECTION, [strongSelf timeFormatted:strongSelf.startTime] , TO, [strongSelf timeFormatted:strongSelf.endTime]]];
                }else{
                    [strongSelf.trimmerView setVideoBoundsToStartTime:0 endTime: (floor(assetDuration) >= DEFAULT_VIDEO_LENGTH ? DEFAULT_VIDEO_LENGTH :  assetDuration) contentOffset:CGPointMake(0, 0)];
                }
                
                
            }
        }
    });
}
    
-(void) didMoveToWindow {
    [super didMoveToWindow]; // (does nothing by default)
    if (self.window == nil) {
        // YOUR CODE FOR WHEN UIVIEW IS REMOVED
        [self stopPlaybackTimeChecker];
        self.isPlaying = NO;
        [self.player seekToTime:CMTimeMake(0, 1)];
        [self.player pause];
        [self.player replaceCurrentItemWithPlayerItem:nil];
        _startTime = -1;
        _endTime = -1;
        self.needInitTrimmer = NO;
        
        self.asset = nil;
        self.player = nil;
        self.playerLayer = nil;
        self.videoLayer = nil;
        self.videoPlayer = nil;
        [self.trimmerView removeFromSuperview];
        self.trimmerView = nil;
        
        [self.timeLengthLabel removeFromSuperview];
        [self.timeRangeLabel removeFromSuperview];
        self.timeLengthLabel = nil;
        self.timeRangeLabel = nil;
        [self.timecodeView removeFromSuperview];
        self.timecodeView = nil;
    }
}
- (void)prepareForReuse {
    [super prepareForReuse];
    [self stopPlaybackTimeChecker];
    self.isPlaying = NO;
    
    [self.player seekToTime:CMTimeMake(0, 1)];
    [self.player pause];
    [self.player replaceCurrentItemWithPlayerItem:nil];
    _startTime = -1;
    _endTime = -1;
    self.needInitTrimmer = NO;
    
    self.asset = nil;
    self.player = nil;
    self.playerLayer = nil;
    self.videoLayer = nil;
    self.videoPlayer = nil;
    [self.trimmerView removeFromSuperview];
    self.trimmerView = nil;
    [self.timeLengthLabel removeFromSuperview];
    [self.timeRangeLabel removeFromSuperview];
    self.timeLengthLabel = nil;
    self.timeRangeLabel = nil;
    [self.timecodeView removeFromSuperview];
    self.timecodeView = nil;
    [self playButton].hidden = NO;
}
    
- (void)setPhoto:(id<MWPhoto>)photo {
    [super setPhoto:photo];
    if(self.photo == nil){
        _startTime = -1;
        _endTime = -1;
        self.needInitTrimmer = NO;
        
        self.asset = nil;
        
        [self.player seekToTime:CMTimeMake(0, 1)];
        [self.player pause];
        [self.player replaceCurrentItemWithPlayerItem:nil];
        
        [self.videoPlayer removeFromSuperview];
        [self.videoLayer removeFromSuperview];
        [self.playerLayer removeFromSuperlayer];
        [self.trimmerView removeFromSuperview];
        self.player = nil;
        self.playerLayer = nil;
        self.videoLayer = nil;
        self.videoPlayer = nil;
        self.trimmerView = nil;
        
        [self.timeLengthLabel removeFromSuperview];
        [self.timeRangeLabel removeFromSuperview];
        self.timeLengthLabel = nil;
        self.timeRangeLabel = nil;
        [self.timecodeView removeFromSuperview];
        self.timecodeView = nil;
        
    }
}
    
- (void)layoutSubviews {
    [super layoutSubviews];
    [self restoreRangeAndOffset];
}
-(void) setPlayButton:(UIButton*)button{
    [super setPlayButton:button];
    self.playButton.hidden = YES;
}
- (void)onDeviceOrientationChange {
    
    //    [self restoreRangeAndOffset];
}
    
-(void) restoreRangeAndOffset{
    if(((int)[[UIDevice currentDevice] orientation]) == ((int)[[UIApplication sharedApplication] statusBarOrientation])){
        MWPhotoExt *photoExt = self.photo;
        if(photoExt.startEndTime != nil){
            
            CGFloat restoredStartTime = [[photoExt.startEndTime valueForKey:@"startTime"] floatValue];
            CGFloat restoredEndTime = [[photoExt.startEndTime valueForKey:@"endTime"] floatValue];
            CGPoint restoredTrimmerTimeOffset = CGPointMake([[photoExt.startEndTime valueForKey:@"contentOffsetX"] floatValue], [[photoExt.startEndTime valueForKey:@"contentOffsetY"] floatValue]);
            [self.trimmerView resetSubviews];
            [self.trimmerView setVideoBoundsToStartTime: restoredStartTime endTime:(restoredEndTime > DEFAULT_VIDEO_LENGTH) ? floor(restoredEndTime) : restoredEndTime  contentOffset:restoredTrimmerTimeOffset];
            //            [self.timeRangeLabel setText:[NSString stringWithFormat:@"%@ - %@", [self timeFormatted:self.startTime] , [self timeFormatted:self.endTime]]];
            [self setVideoRangeLabelWithSring:[NSString stringWithFormat:@"%@: %@ %@ %@", SELECTION, [self timeFormatted:self.startTime] , TO, [self timeFormatted:self.endTime]]];

        }
    }
}
    
- (void)resetTrimmerSubview{
    
    typeof(self) __weak weakSelf = self;

    [self.photo getVideoURL:^(NSURL *url, AVAsset *avAsset) {
        if(url == nil && avAsset == nil){
            return;
        }
        weakSelf.asset = avAsset;
        weakSelf.url = url;
        if(!weakSelf.trimmerView){
//        if(CMTimeGetSeconds(weakSelf.asset.duration ) > 3){
            [[NSNotificationCenter defaultCenter] postNotificationName:LOADING_DID_END_NOTIFICATION object:weakSelf];
//        }else{
//            typeof(self) __strong strongSelf = weakSelf;
//            dispatch_async(dispatch_get_main_queue(), ^{
//                [strongSelf setupVideoPreviewUrl:strongSelf.url avurlAsset:((AVURLAsset*)strongSelf.asset) photoImageViewFrame:strongSelf.frame];
//            });
//        }
        }
        //advoid put too much proceee to main queue
        
    }];
    
    
}
    
- (void) onVideoTapped{
    [self.trimmerView hideTracker:self.isPlaying];
    [super onVideoTapped];
    
}
    
    
#pragma mark - PlaybackTimeCheckerTimer
-(void) playerItemDidReachEnd:(NSNotification *)notification{
    
    [super playerItemDidReachEnd:notification];
    self.isPlaying = NO;

}
- (void)onPlaybackTimeCheckerTimer
{
    CMTime curTime = [self.player currentTime];
    Float64 seconds = CMTimeGetSeconds(curTime);
    if (seconds < 0){
        seconds = 0; // this happens! dont know why.
    }
    self.videoPlaybackPosition = seconds;
    if(self.trimmerView){
        [self.trimmerView seekToTime:seconds];
        
        if (self.videoPlaybackPosition >= _endTime) {
            self.videoPlaybackPosition = _startTime;
            [self seekVideoToPos: _startTime < 0 ? 0 : _startTime ];
            [self.trimmerView seekToTime:_startTime];
            if(!_isLoop){
                self.playButton.hidden = NO;
                [self.player pause];
            }
        }
    }
}

#pragma mark - ICGVideoTrimmerDelegate
    
- (void)trimmerView:(ICGVideoTrimmerView *)trimmerView didChangeLeftPosition:(CGFloat)startTime rightPosition:(CGFloat)endTime trimmerViewContentOffset:(CGPoint)trimmerViewContentOffset
    {
        _restartOnPlay = YES;
        if(self.isPlaying){
            self.playButton.hidden = NO;
        }
        [self.player pause];
        self.isPlaying = NO;
        [self stopPlaybackTimeChecker];
        
        [self.trimmerView hideTracker:true];
        
        if (startTime > 0 || trimmerViewContentOffset.x > 0) {
            //then it moved the left position, we should rearrange the bar
            [self seekVideoToPos:startTime];
        }
        else{ // right has changed
//            [self seekVideoToPos:endTime];
        }
        _startTime = startTime > 0 ? startTime : 0;
        _endTime = endTime;
        _trimmerTimeOffset = CGPointMake(trimmerViewContentOffset.x, trimmerViewContentOffset.y);
        MWPhotoExt *photoExt = self.photo;
        
        if(photoExt.startEndTime == nil){
            photoExt.startEndTime = [NSMutableDictionary new];
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.timeLengthLabel setText:[self timeFormatted:endTime-startTime]];
            //        [self.timeRangeLabel setText:[NSString stringWithFormat:@"%@ - %@", [self timeFormatted:self.startTime] , [self timeFormatted:self.endTime]]];
            if(_trimmerTimeOffset.x == 0 || _endTime == 0 || _startTime == CMTimeGetSeconds( self.asset.duration )){
                [self.timeRangeLabel setText:[NSString stringWithFormat:HINTS_MESSAGE,@(DEFAULT_VIDEO_LENGTH)]];
            }
            [self setVideoRangeLabelWithSring:[NSString stringWithFormat:@"%@: %@ %@ %@", SELECTION, [self timeFormatted:self.startTime] , TO, [self timeFormatted:self.endTime]]];
        });
        [photoExt.startEndTime setValue:@(startTime) forKey:@"startTime"];
        [photoExt.startEndTime setValue:@(endTime) forKey:@"endTime"];
        [photoExt.startEndTime setValue:@(trimmerViewContentOffset.x) forKey:@"contentOffsetX"];
        [photoExt.startEndTime setValue:@(trimmerViewContentOffset.y) forKey:@"contentOffsetY"];
        
    }
    
-(void)trimmerViewDidEndEditing:(nonnull ICGVideoTrimmerView *)trimmerView{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self setVideoRangeLabelWithSring:[NSString stringWithFormat:@"%@: %@ %@ %@", SELECTION, [self timeFormatted:self.startTime] , TO, [self timeFormatted:self.endTime]]];
        //        [self.timeRangeLabel setText:[NSString stringWithFormat:@"%@ - %@", [self timeFormatted:self.startTime] , [self timeFormatted:self.endTime]]];
    });
}
    
-(NSString*) timeFormatted:(CGFloat) sec{

    int totalSeconds = floorf(sec);
    int seconds = totalSeconds % 60;
    int minutes = (totalSeconds / 60) % 60;
    int hours = totalSeconds / 3600;

    return [NSString stringWithFormat:@"%02d:%02d:%02d",hours, minutes, seconds];
}

-(void) setVideoRangeLabelWithSring:(NSString*) msg{
    
    if(_hintsVisibilityTimer){
        [self.timeRangeLabel setText:[NSString stringWithFormat:HINTS_MESSAGE,@(DEFAULT_VIDEO_LENGTH)]];
    }else{
        NSLog(@"setVideoRangeLabelWithSring %@",msg);
        [self.timeRangeLabel setText:msg];
    }
}

- (NSString*) labelText{
    NSBundle* bundle = [NSBundle bundleWithURL:[[NSBundle bundleForClass:[MWZoomingScrollViewExt class]] URLForResource:@"PhotoCaptionInputView" withExtension:@"bundle"]];
    
    return NSLocalizedStringFromTableInBundle(@"Syncing", @"PhotoCaptionInputView", bundle, @"Downloading from iCloud");
}
@end

