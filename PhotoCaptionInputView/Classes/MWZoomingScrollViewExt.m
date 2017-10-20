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
#define LIGHT_BLUE_COLOR [UIColor colorWithRed:(96.0f/255.0f)  green:(178.0f/255.0f)  blue:(232.0f/255.0f) alpha:1.0]
#define DEFUALT_VIDEO_LENGTH 15
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
@end
@implementation MWZoomingScrollViewExt
//@synthesize playButton = _playButton;
@synthesize startTime = _startTime;
@synthesize endTime = _endTime;
@synthesize contentOffset = _contentOffset;
@synthesize needInitTrimmer = _needInitTrimmer;
@synthesize mDelegate = _mDelegate;

- (id)initWithPhotoBrowser:(MWPhotoBrowser *)browser {
    if ((self = [super initWithPhotoBrowser:browser])) {
        _startTime = -1;
        _endTime = -1;
        _isLoop = YES;
        self.needInitTrimmer = NO;
    }
    return self;
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

//-(void) setPlayButton:(UIButton*)button{
//    playButton = button;
////    [_playButton addTarget:self action:@selector(onPlayButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
//}

-(void) setNeedInitTrimmer:(BOOL)needInitTrimmer{
    //    NSLog(@"initTrimmer %i set to initTrimmer  :%i", _needInitTrimmer, needInitTrimmer);
    _needInitTrimmer = needInitTrimmer;
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
    if(self.photo.isVideo){
        if(!self.needInitTrimmer && _trimmerView != nil){
            [_trimmerView resetSubviews];
            self.needInitTrimmer = YES;
        }
    }
}

- (void)resetTrimmerSubview{
    
    typeof(self) __weak weakSelf = self;
    [self.photo getVideoURL:^(NSURL *url) {
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
                    CGPoint restoredContentOffset = strongSelf.contentOffset;
                    if(photoExt.startEndTime != nil){
                        restoredStartTime = [[photoExt.startEndTime valueForKey:@"startTime"] floatValue];
                        restoredEndTime = [[photoExt.startEndTime valueForKey:@"endTime"] floatValue];
                        restoredContentOffset = CGPointMake([[photoExt.startEndTime valueForKey:@"contentOffsetX"] floatValue], [[photoExt.startEndTime valueForKey:@"contentOffsetY"] floatValue]);
                    }
                    
                    ;
                    CGRect frame = CGRectMake(5, [UIApplication sharedApplication].statusBarFrame.size.height+44, CGRectGetWidth(strongSelf.frame)-10, 50);
                    if(strongSelf.asset == nil){
                        strongSelf.asset = [AVAsset assetWithURL:url];
                    }
                    strongSelf.trimmerView = [[ICGVideoTrimmerView alloc] initWithFrame:frame asset:strongSelf.asset delegate:strongSelf];
                    [[strongSelf.trimmerView layer] setCornerRadius:5];
                    
                    CGRect frame2 = CGRectMake(frame.origin.x, frame.origin.y + frame.size.height , frame.size.width, 20);
                    UIView *timecodeView = [[UIView alloc] initWithFrame:frame2];
                    [timecodeView setBackgroundColor:[UIColor colorWithWhite:0 alpha:0.5]];
                    [timecodeView.layer setCornerRadius:10];
                    strongSelf.timecodeView = timecodeView;
                    strongSelf.timecodeView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin |
                    UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleRightMargin;
                    
                    UILabel * timeRangeLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 0, frame2.size.width*0.7-20, frame2.size.height)];
                    timeRangeLabel.textAlignment = NSTextAlignmentLeft;
                    [timeRangeLabel setText:NSLocalizedString(@"MOVE_POINTERS_TO_TRIM_THE_VIDEO", nil)];
                    [timeRangeLabel setFont:[UIFont systemFontOfSize:11]];
                    [timeRangeLabel adjustsFontSizeToFitWidth];
                    [timeRangeLabel setTextColor:[UIColor whiteColor]];
                    [timecodeView addSubview:timeRangeLabel];
                    strongSelf.timeRangeLabel = timeRangeLabel;
                    
                    
                    UILabel * timeLengthLabel = [[UILabel alloc] initWithFrame:CGRectMake(frame2.size.width*0.7+10, 0, frame2.size.width*0.3-20, frame2.size.height)];
                    timeLengthLabel.textAlignment = NSTextAlignmentRight;
                    [timeLengthLabel setText:@"00:00:00"];
                    [timeLengthLabel setTextColor:[UIColor whiteColor]];
                    [timeLengthLabel setFont:[UIFont systemFontOfSize:12]];
                    
                    [timecodeView addSubview:timeLengthLabel];
                    [strongSelf addSubview: timecodeView];
                    strongSelf.timeLengthLabel = timeLengthLabel;
                    
                    [strongSelf.trimmerView setDelegate:strongSelf];
                    // set properties for trimmer view
                    [strongSelf.trimmerView setThumbWidth:20];
                    [strongSelf.trimmerView setThemeColor:[UIColor lightGrayColor]];
                    [strongSelf.trimmerView setShowsRulerView:NO];
                    [strongSelf.trimmerView setMaxLength:CMTimeGetSeconds(asset.duration) < DEFUALT_VIDEO_LENGTH ? CMTimeGetSeconds(asset.duration) : DEFUALT_VIDEO_LENGTH];
                    
                    [strongSelf.trimmerView setRulerLabelInterval:10];
                    
                    [strongSelf.trimmerView setTrackerColor:LIGHT_BLUE_COLOR];
                    
                    
                    // important: reset subviews
                    [strongSelf addSubview: strongSelf.trimmerView];
                    strongSelf.trimmerView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin |
                    UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleRightMargin;
                    NSLog(@"[strongSelf.trimmerView resetSubviews]");
                    [strongSelf.trimmerView resetSubviews];
                    if(restoredStartTime != -1 && restoredEndTime != -1){
                        strongSelf.startTime = restoredStartTime;
                        strongSelf.endTime = restoredEndTime;
                        strongSelf.contentOffset = restoredContentOffset;
                        [strongSelf.trimmerView setVideoBoundsToStartTime:restoredStartTime endTime:restoredEndTime contentOffset:restoredContentOffset];
                        [strongSelf.timeRangeLabel setText:[NSString stringWithFormat:@"%@ - %@", [strongSelf timeFormatted:strongSelf.startTime] , [strongSelf timeFormatted:strongSelf.endTime]]];
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
        [self seekVideoToPos: _startTime];
        [self.trimmerView seekToTime:_startTime];
        if(!_isLoop){
            [self.playButton setHidden:NO];
            [self.player pause];
        }
    }
}

/*
 // Only override drawRect: if you perform custom drawing.
 // An empty implementation adversely affects performance during animation.
 - (void)drawRect:(CGRect)rect {
 // Drawing code
 }
 */
#pragma mark - ICGVideoTrimmerDelegate

- (void)trimmerView:(ICGVideoTrimmerView *)trimmerView didChangeLeftPosition:(CGFloat)startTime rightPosition:(CGFloat)endTime contentOffset:(CGPoint)contentOffset
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
    _contentOffset = CGPointMake(contentOffset.x, contentOffset.y);
    MWPhotoExt *photoExt = self.photo;
    
    if(photoExt.startEndTime == nil){
        photoExt.startEndTime = [NSMutableDictionary new];
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.timeLengthLabel setText:[self timeFormatted:endTime-startTime]];
        [self.timeRangeLabel setText:[NSString stringWithFormat:@"%@ - %@", [self timeFormatted:self.startTime] , [self timeFormatted:self.endTime]]];
    });
    //    NSLog(@"start time %f endTime %f",startTime, endTime);
    
    [photoExt.startEndTime setValue:@(startTime) forKey:@"startTime"];
    [photoExt.startEndTime setValue:@(endTime) forKey:@"endTime"];
    [photoExt.startEndTime setValue:@(contentOffset.x) forKey:@"contentOffsetX"];
    [photoExt.startEndTime setValue:@(contentOffset.y) forKey:@"contentOffsetY"];
    
    if([_mDelegate respondsToSelector:@selector(zoomingScrollView:photo:startTime:endTime:)])
    {
        [_mDelegate zoomingScrollView:self photo:self.photo  startTime:_startTime endTime:_endTime];
    }
    
}

-(NSString*) timeFormatted:(CGFloat) sec{
    
    int totalSeconds = floorf(sec);
    int seconds = totalSeconds % 60;
    int minutes = (totalSeconds / 60) % 60;
    int hours = totalSeconds / 3600;
    
    return [NSString stringWithFormat:@"%02d:%02d:%02d",hours, minutes, seconds];
}

- (void)trimmerViewDidEndEditing:(nonnull ICGVideoTrimmerView *)trimmerView{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.timeRangeLabel setText:[NSString stringWithFormat:@"%@ - %@", [self timeFormatted:self.startTime] , [self timeFormatted:self.endTime]]];
    });
}

- (NSString*)description {
    return [NSString stringWithFormat:@"<%@:%p %@>",
            NSStringFromClass([self class]),
            self,
            @{
              @"needInitTrimmer"            : @(self.needInitTrimmer),
              @"startTime": @(self.startTime),
              @"endTime": @(self.endTime),
              
              }];
}
@end

