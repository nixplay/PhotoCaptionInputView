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
#define LIGHT_BLUE_COLOR [UIColor colorWithRed:(96.0f/255.0f)  green:(178.0f/255.0f)  blue:(232.0f/255.0f) alpha:1.0]
#define DEFAULT_VIDEO_LENGTH 15
@interface MWZoomingScrollViewExt ()<ICGVideoTrimmerDelegate>{
    
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
    }
    return self;
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
}


-(void) didMoveToWindow {
    [super didMoveToWindow]; // (does nothing by default)
    if (self.window == nil) {
        // YOUR CODE FOR WHEN UIVIEW IS REMOVED
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
- (void)onDeviceOrientationChange {
    
    [self restoreRangeAndOffset];
}

-(void) restoreRangeAndOffset{
    if(((int)[[UIDevice currentDevice] orientation]) == ((int)[[UIApplication sharedApplication] statusBarOrientation])){
        MWPhotoExt *photoExt = self.photo;
        if(photoExt.startEndTime != nil){
            
            CGFloat restoredStartTime = [[photoExt.startEndTime valueForKey:@"startTime"] floatValue];
            CGFloat restoredEndTime = [[photoExt.startEndTime valueForKey:@"endTime"] floatValue];
            CGPoint restoredTrimmerTimeOffset = CGPointMake([[photoExt.startEndTime valueForKey:@"contentOffsetX"] floatValue], [[photoExt.startEndTime valueForKey:@"contentOffsetY"] floatValue]);
            [self.trimmerView resetSubviews];
            [self.trimmerView setVideoBoundsToStartTime: restoredStartTime endTime:floor(restoredEndTime) contentOffset:restoredTrimmerTimeOffset];
            [self.timeRangeLabel setText:[NSString stringWithFormat:@"%@ - %@", [self timeFormatted:self.startTime] , [self timeFormatted:self.endTime]]];
        }
    }
}

- (void)resetTrimmerSubview{
    
    typeof(self) __weak weakSelf = self;
    [self.photo getVideoURL:^(NSURL *url, AVURLAsset *avAsset) {
        if(url == nil){
            return;
        }
        //advoid put too much proceee to main queue
        dispatch_async(dispatch_get_main_queue(), ^{
            
            typeof(self) strongSelf = weakSelf;
            
            if (!strongSelf) return;
            if(!strongSelf.needInitTrimmer){
                strongSelf.needInitTrimmer = YES;
                if(url == nil){
                    return;
                }
                ((MWPhoto*)strongSelf.photo).videoURL = url;
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
                    CGRect frame = CGRectMake(5, [UIApplication sharedApplication].statusBarFrame.size.height+44, CGRectGetWidth(strongSelf.frame)-10, 50);
                    if(avAsset != nil){
                        strongSelf.asset = avAsset;
                    }else{
                        strongSelf.asset = [AVURLAsset assetWithURL:url];
                    }
                    Float64 assetDuration = CMTimeGetSeconds( strongSelf.asset.duration );
                    if( assetDuration == 0 ){
                        NSLog(@"WARNING: Could not load av asset");
                        return;
                    }
                    strongSelf.trimmerView = [[ICGVideoTrimmerView alloc] initWithFrame:CGRectMake(0,0,CGRectGetWidth(strongSelf.frame)-10, 50) asset:strongSelf.asset delegate:strongSelf];
                    if(@available(iOS 11, *)){
                    }else{
                        [strongSelf.trimmerView setFrame:frame];
                    }
                    [[strongSelf.trimmerView layer] setCornerRadius:5];
                    
                    CGRect frame2 = CGRectMake(frame.origin.x, frame.origin.y + frame.size.height , frame.size.width, 20);
                    UIView *timecodeView = [[UIView alloc] initWithFrame:CGRectZero];
                    
                    [timecodeView setBackgroundColor:[UIColor colorWithWhite:0 alpha:0.5]];
                    [timecodeView.layer setCornerRadius:10];
                    strongSelf.timecodeView = timecodeView;
                    if(@available(iOS 11, *)){
                    }else{
                        [strongSelf.timecodeView setFrame:frame2];
                        strongSelf.timecodeView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin |
                        UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleRightMargin;
                    }
                    //                    UILabel * timeRangeLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 0, frame2.size.width*0.7-20, frame2.size.height)];
                    UILabel * timeRangeLabel = [[UILabel alloc] initWithFrame:CGRectZero];
                    if(@available(iOS 11, *)){
                    }else{
                        [timeRangeLabel setFrame:CGRectMake(10, 0, frame2.size.width*0.7-20, frame2.size.height)];
                    }
                    timeRangeLabel.textAlignment = NSTextAlignmentLeft;
                    [timeRangeLabel setText:NSLocalizedString(@"MOVE_POINTERS_TO_TRIM_THE_VIDEO", nil)];
                    [timeRangeLabel setFont:[UIFont systemFontOfSize:11]];
                    [timeRangeLabel adjustsFontSizeToFitWidth];
                    [timeRangeLabel setTextColor:[UIColor whiteColor]];
                    
                    strongSelf.timeRangeLabel = timeRangeLabel;
                    
                    
                    //                    UILabel * timeLengthLabel = [[UILabel alloc] initWithFrame:CGRectMake(frame2.size.width*0.7+10, 0, frame2.size.width*0.3-20, frame2.size.height)];
                    UILabel * timeLengthLabel = [[UILabel alloc] initWithFrame:CGRectZero];
                    if(@available(iOS 11, *)){
                    }else{
                        [timeLengthLabel setFrame:CGRectMake(frame2.size.width*0.7+10, 0, frame2.size.width*0.3-20, frame2.size.height)];
                    }
                    timeLengthLabel.textAlignment = NSTextAlignmentRight;
                    [timeLengthLabel setText:@"00:00:00"];
                    [timeLengthLabel setTextColor:[UIColor whiteColor]];
                    [timeLengthLabel setFont:[UIFont systemFontOfSize:12]];
                    
                    [timecodeView addSubview:timeLengthLabel];
                    [timecodeView addSubview:timeRangeLabel];
                    
                    UIEdgeInsets padding = UIEdgeInsetsMake(5, 5, 5, -5);
                    
                    
                    
                    
                    strongSelf.timeLengthLabel = timeLengthLabel;
                    
                    [strongSelf.trimmerView setDelegate:strongSelf];
                    // set properties for trimmer view
                    [strongSelf.trimmerView setThumbWidth:20];
                    [strongSelf.trimmerView setThemeColor:LIGHT_BLUE_COLOR];
                    [strongSelf.trimmerView setShowsRulerView:NO];
                    [strongSelf.trimmerView setMaxLength:assetDuration < DEFAULT_VIDEO_LENGTH ? assetDuration : DEFAULT_VIDEO_LENGTH];
                    
                    [strongSelf.trimmerView setRulerLabelInterval:10];
                    
                    [strongSelf.trimmerView setTrackerColor:LIGHT_BLUE_COLOR];
                    
                    
                    // important: reset subviews
                    [strongSelf addSubview: strongSelf.trimmerView];
                    [strongSelf addSubview: timecodeView];
                    if(@available(iOS 11, *)){
                        [strongSelf.trimmerView mas_makeConstraints:^(MASConstraintMaker *make) {
                            //                        make.centerX.equalTo(strongSelf.trimmerView.superview.mas_centerX);
                            if(@available(iOS 11, *)){
                                make.top.equalTo( strongSelf.trimmerView.superview.mas_safeAreaLayoutGuideTop).with.offset(padding.top);
                                make.right.equalTo( strongSelf.trimmerView.superview.mas_safeAreaLayoutGuideRight).with.offset(padding.right);
                                make.left.equalTo( strongSelf.trimmerView.superview.mas_safeAreaLayoutGuideLeft).with.offset(padding.left);
                            }else{
                                make.top.equalTo( strongSelf.trimmerView.superview.mas_top).with.offset(padding.top);
                                make.right.equalTo( strongSelf.trimmerView.superview.mas_right).with.offset(padding.right);
                                make.left.equalTo( strongSelf.trimmerView.superview.mas_left).with.offset(padding.left);
                            }
                            make.height.mas_equalTo(frame.size.height);
                            
                        }];
                        [timecodeView mas_makeConstraints:^(MASConstraintMaker *make) {
                            if(@available(iOS 11, *)){
                                make.top.equalTo( strongSelf.trimmerView.mas_bottom ).with.offset(padding.top);
                                make.right.equalTo( timecodeView.superview.mas_safeAreaLayoutGuideRight).with.offset(padding.right);
                                make.left.equalTo( timecodeView.superview.mas_safeAreaLayoutGuideLeft).with.offset(padding.left);
                            }else{
                                make.top.equalTo( strongSelf.trimmerView.mas_bottom).with.offset(padding.top);
                                make.right.equalTo( timecodeView.superview.mas_right).with.offset(padding.right);
                                make.left.equalTo( timecodeView.superview.mas_left).with.offset(padding.left);
                            }
                            make.height.mas_equalTo(frame2.size.height);
                        }];
                        
                        [timeRangeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
                            make.top.equalTo(timeRangeLabel.superview.mas_top);
                            make.left.equalTo(timeRangeLabel.superview.mas_left).with.offset(padding.left);
                            make.bottom.equalTo(timeRangeLabel.superview.mas_bottom);
                            make.width.mas_equalTo(frame2.size.width*0.7);
                        }];
                        [timeLengthLabel mas_makeConstraints:^(MASConstraintMaker *make) {
                            make.top.equalTo(timeRangeLabel.superview.mas_top);
                            make.right.equalTo(timeRangeLabel.superview.mas_right).with.offset(padding.right);
                            make.bottom.equalTo(timeRangeLabel.superview.mas_bottom);
                            make.width.mas_equalTo(frame2.size.width*0.3);
                        }];
                    }
                    //                    strongSelf.trimmerView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin |
                    //                    UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleRightMargin;
                    //                    NSLog(@"[strongSelf.trimmerView resetSubviews]");
                    [strongSelf.trimmerView resetSubviews];
                    if(restoredStartTime != -1 && restoredEndTime != -1){
                        strongSelf.startTime = restoredStartTime;
                        strongSelf.endTime = restoredEndTime;
                        strongSelf.trimmerTimeOffset = restoredTrimmerTimeOffset;
                        [strongSelf.trimmerView setVideoBoundsToStartTime: restoredStartTime endTime:floor(restoredEndTime) contentOffset:restoredTrimmerTimeOffset];
                        [strongSelf.timeRangeLabel setText:[NSString stringWithFormat:@"%@ - %@", [strongSelf timeFormatted:strongSelf.startTime] , [strongSelf timeFormatted:strongSelf.endTime]]];
                    }else{
                        [strongSelf.trimmerView setVideoBoundsToStartTime:0 endTime: (floor(assetDuration) >= DEFAULT_VIDEO_LENGTH ? DEFAULT_VIDEO_LENGTH :  assetDuration) contentOffset:CGPointMake(0, 0)];
                    }
                    
                }
            }
        });
    }];
    
    
}

- (void) onVideoTapped{
    [self.trimmerView hideTracker:self.isPlaying];
    [super onVideoTapped];
    
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
        [self seekVideoToPos: _startTime < 0 ? 0 : _startTime ];
        [self.trimmerView seekToTime:_startTime];
        if(!_isLoop){
            [self.playButton setHidden:NO];
            [self.player pause];
        }
    }
}
#pragma mark - ICGVideoTrimmerDelegate

- (void)trimmerView:(ICGVideoTrimmerView *)trimmerView didChangeLeftPosition:(CGFloat)startTime rightPosition:(CGFloat)endTime trimmerViewContentOffset:(CGPoint)trimmerViewContentOffset
{
    _restartOnPlay = YES;
    [self.playButton setHidden:NO];
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
    _startTime = startTime > 0 ? startTime : 0;
    _endTime = endTime;
    _trimmerTimeOffset = CGPointMake(trimmerViewContentOffset.x, trimmerViewContentOffset.y);
    MWPhotoExt *photoExt = self.photo;
    
    if(photoExt.startEndTime == nil){
        photoExt.startEndTime = [NSMutableDictionary new];
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.timeLengthLabel setText:[self timeFormatted:endTime-startTime]];
        [self.timeRangeLabel setText:[NSString stringWithFormat:@"%@ - %@", [self timeFormatted:self.startTime] , [self timeFormatted:self.endTime]]];
    });
    [photoExt.startEndTime setValue:@(startTime) forKey:@"startTime"];
    [photoExt.startEndTime setValue:@(endTime) forKey:@"endTime"];
    [photoExt.startEndTime setValue:@(trimmerViewContentOffset.x) forKey:@"contentOffsetX"];
    [photoExt.startEndTime setValue:@(trimmerViewContentOffset.y) forKey:@"contentOffsetY"];
    
}

-(void)trimmerViewDidEndEditing:(nonnull ICGVideoTrimmerView *)trimmerView{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.timeRangeLabel setText:[NSString stringWithFormat:@"%@ - %@", [self timeFormatted:self.startTime] , [self timeFormatted:self.endTime]]];
    });
}

-(NSString*) timeFormatted:(CGFloat) sec{
    
    int totalSeconds = floorf(sec);
    int seconds = totalSeconds % 60;
    int minutes = (totalSeconds / 60) % 60;
    int hours = totalSeconds / 3600;
    
    return [NSString stringWithFormat:@"%02d:%02d:%02d",hours, minutes, seconds];
}
@end

