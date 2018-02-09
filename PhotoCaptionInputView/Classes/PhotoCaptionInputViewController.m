//
//  PhotoCaptionInputViewController.m
//  Pods
//
//  Created by James Kong on 12/4/2017.
//
//

#import "PhotoCaptionInputViewController.h"
#import <MobileCoreServices/UTCoreTypes.h>
#import <MWPhotoBrowser/MWPhotoBrowser.h>
#import <MWPhotoBrowser/MWGridCell.h>
#import <MWPhotoBrowser/UIImage+MWPhotoBrowser.h>
#import <GMImagePicker/GMImagePickerController.h>
#import "MWPhotoExt.h"
#import "UITextView+Placeholder.h"
#import "IQKeyboardManager.h"
#import "IQUIView+IQKeyboardToolbar.h"
#import "IQTextView.h"
#import "MWZoomingScrollViewExt.h"
#import "Masonry.h"
#import "MBProgressHUD.h"
#define LIGHT_BLUE_COLOR [UIColor colorWithRed:(99/255.0f)  green:(176/255.0f)  blue:(228.0f/255.0f) alpha:1.0]
#define LIGHT_BLUE_CGCOLOR [LIGHT_BLUE_COLOR CGColor]
#define TEXTFIELD_BG_COLOR [UIColor whiteColor]
#define TEXTFIELD_TEXT_COLOR [UIColor blackColor]
#define MAX_CHARACTER 160
#define PLACEHOLDER_TEXT [NSString stringWithFormat:@"%@(0/%d)", NSLocalizedString(@"ADD_CAPTION" , nil ) , MAX_CHARACTER]
#define LAYOUT_START_Y 10.5f
#define BUNDLE_UIIMAGE(imageNames) [UIImage imageNamed:[NSString stringWithFormat:@"%@.bundle/%@", NSStringFromClass([self class]), imageNames]]
#define BIN_UIIMAGE BUNDLE_UIIMAGE(@"images/bin.png")
#define MAX_VIDEO_ALERT 10
#define DEFAULT_VIDEO_LENGTH 15
@interface PhotoCaptionInputViewController ()<GMImagePickerControllerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate>{
    //    NSMutableArray* preSelectedAssets;
    UIView* hightlightView;
    BOOL keyboardIsShown;
    float textViewOrigYRatio;
    BOOL needResetLayout;
    
}
    @property (nonatomic, weak) NSArray* preSelectedAssets;
    @end

@implementation PhotoCaptionInputViewController
    
    @synthesize collectionView = _collectionView;
    @synthesize addButton = _addButton;
    @synthesize textView = _textView;
    @synthesize selfDelegate = _selfDelegate;
    @synthesize backButton = _backButton;
    @synthesize trashButton = _trashButton;
#pragma mark - Init
    
-(id)initWithPhotos:(NSArray* _Nonnull)photos thumbnails:(NSArray* _Nonnull)thumbnails  preselectedAssets:(NSArray*  _Nullable) _preselectedAssets delegate:(id<PhotoCaptionInputViewDelegate>)delegate{
    if ((self = [super init])) {
        [self initialisation];
        self.selfPhotos = [NSMutableArray arrayWithArray:photos];
        self.selfThumbs = [NSMutableArray arrayWithArray:thumbnails];
        //        if(_preselectedAssets == nil){
        //            preSelectedAssets = [NSMutableArray array];
        //        }else{
        //            preSelectedAssets = [NSMutableArray arrayWithArray:_preselectedAssets];
        //        }
        
        if(_selfPhotos == nil){
            [NSException raise:@"PhotoCaptionInputViewController photos is nil" format:@"PhotoCaptionInputViewController photos can not be nil."];
        }
        if(_selfThumbs == nil){
            [NSException raise:@"PhotoCaptionInputViewController thumbnail is nil" format:@"PhotoCaptionInputViewController thumbnail can not be nil."];
        }
        _selfDelegate = delegate;
        self.delegate = self;
        needResetLayout = YES;
    }
    return self;
    
}
- (id)initWithCoder:(NSCoder *)decoder {
    if ((self = [super initWithCoder:decoder])) {
        [self initialisation];
    }
    return self;
}
- (void)viewDidLoad {
    [super viewDidLoad];
    
    float initY = self.navigationController.view.frame.size.height * (LAYOUT_START_Y/12.0)-20;
    __block float initHeight = ((self.navigationController.view.frame.size.height > self.navigationController.view.frame.size.width) ? self.navigationController.view.frame.size.height : self.navigationController.view.frame.size.width)* (1.0/12.0);
    textViewOrigYRatio = (initY-30) / self.navigationController.view.frame.size.height;
    UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
    [flowLayout setItemSize:CGSizeMake(initHeight, initHeight)];
    [flowLayout setScrollDirection:UICollectionViewScrollDirectionHorizontal];
    //    flowLayout.sectionInset = UIEdgeInsetsMake(5, 25, 5, 25);
    flowLayout.itemSize = CGSizeMake(initHeight, initHeight);
    flowLayout.minimumLineSpacing = 3;
    flowLayout.minimumInteritemSpacing = 3;
    flowLayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    
    CGRect rect = CGRectMake(0,
                             0,
                             self.navigationController.view.frame.size.width-initHeight-15,
                             initHeight);
    
    self.collectionView = [[UICollectionView alloc]initWithFrame:rect
                                            collectionViewLayout:flowLayout
                           ];
    self.collectionView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth;
    
    [self.collectionView registerClass:[MWGridCell class] forCellWithReuseIdentifier:@"GridCell"];
    self.collectionView.backgroundColor = [UIColor clearColor];
    
    [self.collectionView setCollectionViewLayout:flowLayout];
    [self.collectionView setShowsHorizontalScrollIndicator:NO];
    
    self.collectionView.delegate = self;
    self.collectionView.dataSource = self;
    
    self.addButton = [[UIButton alloc]initWithFrame:CGRectMake(0, 0, initHeight, initHeight)];
    
    NSString *format = @"PhotoCaptionInputView.bundle/%@";
    [self.addButton setImage:[UIImage imageForResourcePath:[NSString stringWithFormat:format, @"add_button"] ofType:@"png" inBundle:[NSBundle bundleForClass:[self class]]]  forState:UIControlStateNormal];
    self.addButton.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleLeftMargin;
    [self.addButton addTarget:self action:@selector(addPhotoFromLibrary) forControlEvents:UIControlEventTouchUpInside];
    
    
    
    _parentView = [[UIView alloc] initWithFrame:CGRectZero];
    [_parentView setBackgroundColor:[UIColor blackColor]];
    [_parentView addSubview:self.addButton];
    
    [_parentView addSubview:self.collectionView];
    //UIEdgeInsetsMake(CGFloat top, CGFloat left, CGFloat bottom, CGFloat right)
    UIEdgeInsets subViewButtonPadding = UIEdgeInsetsMake(10,10,-10,-20);
    [_addButton mas_makeConstraints:^(MASConstraintMaker *make) {
        
        make.top.equalTo(_addButton.superview.mas_top).with.offset(subViewButtonPadding.top);
        make.bottom.equalTo(_addButton.superview.mas_bottom).with.offset(subViewButtonPadding.bottom);
        make.right.equalTo(_addButton.superview.mas_right).with.offset(subViewButtonPadding.right);
        
        make.height.mas_equalTo(initHeight);
        make.width.mas_equalTo(initHeight);
        
        
    }];
    UIEdgeInsets collectionViewPadding = UIEdgeInsetsMake(10,20,-10,-20);
    [_collectionView mas_makeConstraints:^(MASConstraintMaker *make) {
        
        make.top.equalTo(_collectionView.superview.mas_top).with.offset(collectionViewPadding.top);
        make.left.equalTo(_collectionView.superview.mas_left).with.offset(collectionViewPadding.left);
        make.bottom.equalTo(_collectionView.superview.mas_bottom).with.offset(collectionViewPadding.bottom);
        make.right.equalTo(_addButton.mas_left).with.offset(-3);
        make.height.mas_equalTo(initHeight);
        
    }];
    
    
    [self.view addSubview:_parentView];
    UIEdgeInsets padding = UIEdgeInsetsMake(0,0,0,0);
    [_parentView mas_makeConstraints:^(MASConstraintMaker *make) {
        //        make.bottom.equalTo(self.toolbar.mas_top).with.offset(-4);
        
        if(@available(iOS 11, *)){
            
            make.left.equalTo(_parentView.superview.mas_safeAreaLayoutGuideLeft).with.offset(padding.left);
            make.right.equalTo(_parentView.superview.mas_safeAreaLayoutGuideRight).with.offset(padding.right);
        }else{
            make.right.equalTo(_parentView.superview.mas_right).with.offset(padding.right);
            make.left.equalTo(_parentView.superview.mas_left).with.offset(padding.left);
        }
        make.height.mas_equalTo(initHeight+(subViewButtonPadding.top*2));
        make.bottom.equalTo(self.toolbar.mas_top);
    }];
    
    CGRect tfrect = CGRectMake(10, _parentView.frame.origin.y-31-10, self.navigationController.view.frame.size.width-20, 31);
    IQTextView * textView = [[IQTextView alloc] initWithFrame:tfrect textContainer:nil];
    
    //    [[IQKeyboardManager sharedManager]setEnable:YES];
    [[IQKeyboardManager sharedManager] setShouldShowToolbarPlaceholder:YES];
    [[IQKeyboardManager sharedManager] setKeyboardDistanceFromTextField:initHeight];
    //    [[IQKeyboardManager sharedManager] setEnableAutoToolbar:YES];
    //    [[IQKeyboardManager sharedManager] setKeyboardAppearance:UIKeyboardAppearanceLight];
    [[IQKeyboardManager sharedManager] setShouldResignOnTouchOutside:YES];
    
    textView.autocapitalizationType = UITextAutocapitalizationTypeSentences;
    textView.autocorrectionType = UITextAutocorrectionTypeYes;
    textView.spellCheckingType = UITextSpellCheckingTypeYes;
    textView.backgroundColor = TEXTFIELD_BG_COLOR;
    textView.textColor = TEXTFIELD_TEXT_COLOR;
    
    textView.layer.cornerRadius=2;
    textView.layer.masksToBounds=YES;
    textView.placeholder = PLACEHOLDER_TEXT;
    textView.placeholderColor = [UIColor lightGrayColor];
    textView.toolbarPlaceholder = PLACEHOLDER_TEXT;
    textView.placeholderColor = [UIColor lightGrayColor]; // optional
    
    textView.font = [UIFont systemFontOfSize:14.0f];
    textView.returnKeyType = UIReturnKeyDone;
    textView.textAlignment = NSTextAlignmentLeft;
    textView.tag = 2;
    
    textView.delegate = self;
    
    textView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin;
    _textView = textView;
    if([self.selfPhotos count] >0){
        [_textView setText:[ [self.selfPhotos objectAtIndex:0] caption]];
        
        ((IQTextView*)_textView).toolbarPlaceholder = ([[ [self.selfPhotos objectAtIndex:0] caption] length]) == 0 ? PLACEHOLDER_TEXT : [NSString stringWithFormat:@"%lu/MAX_CHARACTER",(unsigned long)_textView.text.length];
        
    }
    
    
    
    [self.view addSubview:_textView];
    //    [_textView mas_makeConstraints:^(MASConstraintMaker *make) {
    //
    //        make.bottom.equalTo(_parentView.mas_top).with.offset(-10);
    ////        make.height.mas_equalTo(31);
    //
    //        if(@available(iOS 11, *)){
    //
    //            make.left.equalTo(_textView.superview.mas_safeAreaLayoutGuideLeft).with.offset(10);
    //            make.right.equalTo(_textView.superview.mas_safeAreaLayoutGuideRight).with.offset(-10);
    //        }else{
    //            make.right.equalTo(_textView.superview.mas_right).with.offset(-10);
    //            make.left.equalTo(_textView.superview.mas_left).with.offset(10);
    //        }
    ////        NSLog(@"_textView %@", _textView);
    //    }];
    //    [self.textView sizeToFit];
    //    [_textView setScrollEnabled:NO];
    
    
    UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageForResourcePath:[NSString stringWithFormat:format, @"toolbarBackWhite"] ofType:@"png" inBundle:[NSBundle bundleForClass:[self class]]]
                                                                   style:UIBarButtonItemStylePlain
                                                                  target:self
                                                                  action:@selector(backAction)];
    
    self.navigationItem.leftBarButtonItem = backButton;
    
    _backButton = backButton;
    
    
    UIBarButtonItem *trashButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageForResourcePath:[NSString stringWithFormat:format, @"bin"] ofType:@"png" inBundle:[NSBundle bundleForClass:[self class]]]
                                                                    style:UIBarButtonItemStylePlain
                                                                   target:self
                                                                   action:@selector(removePhoto)];
    //    NSString *trashString = @"\U000025C0\U0000FE0E"; //BLACK LEFT-POINTING TRIANGLE PLUS VARIATION SELECTOR
    //    trashButton.title = trashString;
    
    self.navigationItem.rightBarButtonItem = trashButton;
    
    _trashButton = trashButton;
    if([self.selfPhotos count] == 1){
        self.navigationItem.rightBarButtonItem.enabled = NO;
    }
    
    self.maximumImagesCount = (self.maximumImagesCount == 0)?100:self.maximumImagesCount;
    
    if([self.selfPhotos count] >= self.maximumImagesCount){
        self.addButton.enabled = NO;
    }
    [[IQKeyboardManager sharedManager] setEnable:YES];
    
}
    
-(void) viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
}
    
- (UIImage *)imageFromSystemBarButton:(UIBarButtonSystemItem)systemItem {
    // Holding onto the oldItem (if any) to set it back later
    // could use left or right, doesn't matter
    UIBarButtonItem *oldItem = self.navigationItem.rightBarButtonItem;
    
    UIBarButtonItem *tempItem = [[UIBarButtonItem alloc]
                                 initWithBarButtonSystemItem:systemItem
                                 target:nil
                                 action:nil];
    
    // Setting as our right bar button item so we can traverse its subviews
    self.navigationItem.rightBarButtonItem = tempItem;
    
    // Don't know whether this is considered as PRIVATE API or not
    UIView *itemView = (UIView *)[self.navigationItem.rightBarButtonItem performSelector:@selector(view)];
    
    UIImage *image = nil;
    // Traversing the subviews to find the ImageView and getting its image
    for (UIView *subView in itemView.subviews) {
        if ([subView isKindOfClass:[UIImageView class]]) {
            image = ((UIImageView *)subView).image;
            break;
        }
    }
    
    // Setting our oldItem back since we have the image now
    self.navigationItem.rightBarButtonItem = oldItem;
    
    return image;
}
    
- (void)initialisation {
    keyboardIsShown = NO;
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onKeyboardDidShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onKeyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
    BOOL displayActionButton = NO;
    BOOL displaySelectionButtons = NO;
    BOOL displayNavArrows = NO;
    BOOL enableGrid = NO;
    BOOL startOnGrid = NO;
    BOOL autoPlayOnAppear = NO;
    
    self.displayActionButton = displayActionButton;
    self.displayNavArrows = displayNavArrows;
    self.displaySelectionButtons = displaySelectionButtons;
    self.alwaysShowControls = displaySelectionButtons;
    self.zoomPhotosToFill = YES;
    self.enableGrid = enableGrid;
    self.startOnGrid = startOnGrid;
    self.enableSwipeToDismiss = NO;
    self.autoPlayOnAppear = autoPlayOnAppear;
    [self setCurrentPhotoIndex:0];
    
    // Do any additional setup after loading the view.
}
    
    
-(void)backAction{
    //    NSLog(@"backAction");
    if ([_selfDelegate respondsToSelector:@selector(dismissPhotoCaptionInputView:)]) {
        [_selfDelegate dismissPhotoCaptionInputView:self];
    }
}
    
-(void) getPhotosCaptions{
    if ([_selfDelegate respondsToSelector:@selector(photoCaptionInputView:captions:photos:preSelectedAssets:)]) {
        NSMutableArray *captions = [NSMutableArray array];
        NSMutableArray *photos = [NSMutableArray array];
        [self.selfPhotos enumerateObjectsUsingBlock:^(MWPhotoExt* obj, NSUInteger idx, BOOL * _Nonnull stop) {
            
            [captions addObject:obj.caption != nil ? [obj caption] : @""];
            [photos addObject:obj.photoData];
        }];
        [_selfDelegate photoCaptionInputView:self captions:captions photos:photos preSelectedAssets: self.preSelectedAssets];
    }
    if ([_selfDelegate respondsToSelector:@selector(photoCaptionInputView:captions:photos:preSelectedAssets:startEndTime:)]) {
        NSMutableArray *captions = [NSMutableArray array];
        NSMutableArray *photos = [NSMutableArray array];
        NSMutableArray *startEndTimes = [NSMutableArray array];
        [self.selfPhotos enumerateObjectsUsingBlock:^(MWPhotoExt* obj, NSUInteger idx, BOOL * _Nonnull stop) {
            
            [captions addObject:obj.caption != nil ? [obj caption] : @""];
            [photos addObject:obj.photoData];
            [startEndTimes addObject:
             obj.startEndTime != nil ?
             [obj startEndTime] :
             (obj.isVideo) ? @{
                               @"startTime":@(0.0f),
                               @"endTime":@(DEFAULT_VIDEO_LENGTH),
                               @"auto":@(YES)
                               } :
             [NSNull null]];
        }];
        
        id page = [self pageDisplayedAtIndex:[self currentIndex]];
        if(page != nil && [page isKindOfClass:[MWZoomingScrollView class]]){
            if([page respondsToSelector:@selector(resetPlayer)]){
                [page resetPlayer];
            }
        }
        
        [_selfDelegate photoCaptionInputView:self captions:captions photos:photos preSelectedAssets: self.preSelectedAssets startEndTime:startEndTimes];
    }
}
    
-(void)addPhotoFromLibrary{
    if(self.camera){
        [self launchCamera];
    }else{
        [self launchGMImagePicker];
    }
}
- (void)launchCamera
    {
        UIImagePickerController *picker = [[UIImagePickerController alloc] init];
        picker.sourceType = UIImagePickerControllerSourceTypeCamera;
        picker.videoMaximumDuration = self.videoMaximumDuration == 0 ? 15 : self.videoMaximumDuration;
        if(_allow_video){
            picker.mediaTypes = @[(NSString *)kUTTypeImage,(NSString *)kUTTypeMovie];
            picker.videoQuality = UIImagePickerControllerQualityTypeHigh;
        }else{
            picker.mediaTypes = @[(NSString *)kUTTypeImage];
        }
        picker.allowsEditing = NO;
        
        picker.delegate = self;
        picker.modalPresentationStyle = UIModalPresentationPopover;
        
        //    UIPopoverPresentationController *popPC = picker.popoverPresentationController;
        //    popPC.permittedArrowDirections = UIPopoverArrowDirectionAny;
        //    popPC.barButtonItem = self.addButton;
        
        //    [self showViewController:picker sender:self.addButton];
        [self presentViewController:picker animated:YES completion:nil];
    }
- (void)launchGMImagePicker
    {
        GMImagePickerController *picker = [[GMImagePickerController alloc] init:self.allow_video withAssets:self.preSelectedAssets delegate:self];
        
        if(self.allow_video){
            picker.mediaTypes = @[@(PHAssetMediaTypeImage),
                                  @(PHAssetMediaTypeVideo)];
            picker.customSmartCollections = @[@(PHAssetCollectionSubtypeSmartAlbumVideos),
                                              @(PHAssetCollectionSubtypeSmartAlbumFavorites),
                                              @(PHAssetCollectionSubtypeSmartAlbumRecentlyAdded),
                                              @(PHAssetCollectionSubtypeSmartAlbumPanoramas)];
        }else{
            picker.mediaTypes = @[@(PHAssetMediaTypeImage)];
            picker.customSmartCollections = @[@(PHAssetCollectionSubtypeSmartAlbumFavorites),
                                              @(PHAssetCollectionSubtypeSmartAlbumRecentlyAdded),
                                              @(PHAssetCollectionSubtypeSmartAlbumPanoramas)];
        }
        picker.title = NSLocalizedString(@"SELECT_AN_ALBUM",nil);
        picker.customDoneButtonTitle = NSLocalizedString(@"DONE",nil);
        picker.customCancelButtonTitle = NSLocalizedString(@"CANCEL",nil);
        
        picker.colsInPortrait = 3;
        picker.colsInLandscape = 5;
        picker.minimumInteritemSpacing = 2.0;
        picker.navigationBarTintColor = LIGHT_BLUE_COLOR;
        picker.toolbarTextColor = LIGHT_BLUE_COLOR;
        picker.toolbarTintColor = LIGHT_BLUE_COLOR;
        picker.showCameraButton = YES;
        picker.autoSelectCameraImages = YES;
        
        [self.navigationController presentViewController:picker animated:YES completion:nil];
        
    }
    
-(void)removePhoto{
    if([self.selfPhotos count] > 1){
        //        NSLog(@"removePhoto");
        //may have problem
//        MWPhotoExt *photo = [self.selfPhotos objectAtIndex:self.currentIndex];
        //        if([preSelectedAssets containsObject:photo.photoData]){
        //            [preSelectedAssets removeObject:photo.photoData];
        //        }
        [self.selfPhotos removeObjectAtIndex:self.currentIndex];
        [self.selfThumbs removeObjectAtIndex:self.currentIndex];
        [self.collectionView reloadData];
        [self reloadData];
        
        
        [_textView setText:[ [self.selfPhotos objectAtIndex:self.currentIndex] caption]];
        _textView.toolbarPlaceholder = PLACEHOLDER_TEXT;
        if([self.selfPhotos count]>1){
            self.navigationItem.rightBarButtonItem = _trashButton;
        }
        if([self.selfPhotos count]==1){
            self.navigationItem.rightBarButtonItem.enabled = NO;
        }
        [self resetTrimmerSubview];
        
    }
    if([self.selfPhotos count] >= self.maximumImagesCount){
        self.addButton.enabled = NO;
    }else{
        self.addButton.enabled = YES;
    }
    
}
    
-(void)reloadPhoto{
    //    NSLog(@"removePhoto");
    [self.collectionView reloadData];
    [self reloadData];
    self.navigationItem.rightBarButtonItem = _trashButton;
}
    
    
-(void) viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
}
    
#pragma mark UITextViewDelegate
    
-(void) onKeyboardDidShow :(NSNotification*)notification
    {
        if(!keyboardIsShown){
            //        NSDictionary* keyboardInfo = [notification userInfo];
            //        NSValue* keyboardFrameBegin = [keyboardInfo valueForKey:UIKeyboardFrameBeginUserInfoKey];
            //        _keyboardRect= [keyboardFrameBegin CGRectValue];
            //        BOOL isNotOffset = (self.navigationController.view.frame.origin.y == 0);
            //
            //        [self.navigationController.view setFrame:CGRectMake(0, 0, self.view.frame.size.width , self.view.frame.size.height)];
            //        [self animatetextView:_textView up:YES keyboardFrameBeginRect:_keyboardRect animation:isNotOffset];
            keyboardIsShown = YES;
            NSString * caption = [ [self.selfPhotos objectAtIndex:self.currentIndex] caption];
            ((IQTextView*)_textView).toolbarPlaceholder = ([caption length]) == 0 ? PLACEHOLDER_TEXT : [NSString stringWithFormat:@"%lu/%d",(unsigned long)_textView.text.length, MAX_CHARACTER];
        }
        
    }
    
-(void) onKeyboardWillHide :(NSNotification*)notification
    {
        if(keyboardIsShown){
            //        NSDictionary* keyboardInfo = [notification userInfo];
            //        NSValue* keyboardFrameBegin = [keyboardInfo valueForKey:UIKeyboardFrameBeginUserInfoKey];
            //        CGRect keyboardFrameBeginRect = [keyboardFrameBegin CGRectValue];
            //        [self animatetextView:_textView up:NO keyboardFrameBeginRect:keyboardFrameBeginRect animation:YES];
            [_textView setFrame:[self newFrameFromTextView:_textView]];
            
            keyboardIsShown = NO;
        }
        
    }
    
-(void)textViewDidChange:(UITextView *)textView{
    MWPhotoExt *photo = [self.selfPhotos objectAtIndex:self.currentIndex];
    
    [photo setCaption:textView.text];
    [self.selfPhotos replaceObjectAtIndex:self.currentIndex withObject:photo];
    IQTextView* iqTextView = (IQTextView*)textView;
    iqTextView.shouldHideToolbarPlaceholder = NO;
    iqTextView.toolbarPlaceholder = [NSString stringWithFormat:@"%lu/%d",(unsigned long)textView.text.length, MAX_CHARACTER];
    [_textView setFrame:[self newFrameFromTextView:textView]];
    
}
- (BOOL)textViewShouldEndEditing:(UITextView *)textView{
    return YES;
}
-(void)textViewDidBeginEditing:(UITextView *)textView
    {
        //    [self animatetextView:_textView up:YES keyboardFrameBeginRect:keyboardRect];
        textView.backgroundColor = TEXTFIELD_BG_COLOR;
        textView.textColor = TEXTFIELD_TEXT_COLOR;
    }
    
- (void)textViewDidEndEditing:(UITextView *)textView
    {
        //    [self animatetextView:_textView up:YES keyboardFrameBeginRect:_keyboardRect];
        //    [self animatetextView:textView up:NO :];
        textView.backgroundColor = TEXTFIELD_BG_COLOR;
        textView.textColor = TEXTFIELD_TEXT_COLOR;
        [textView setFrame:[self newFrameFromTextView:textView]];
        
    }
- (BOOL)textViewShouldReturn:(UITextView *)textView{
    //    NSLog(@"textViewShouldReturn:");
    if (textView.tag == 1) {
        UITextView *textView = (UITextView *)[self.navigationController.view viewWithTag:2];
        [textView becomeFirstResponder];
    }
    else {
        
        [textView resignFirstResponder];
        [textView setFrame:[self newFrameFromTextView:textView]];
        MWPhotoExt *photo = [self.selfPhotos objectAtIndex:self.currentIndex];
        
        [photo setCaption:textView.text];
        [self.selfPhotos replaceObjectAtIndex:self.currentIndex withObject:photo];
    }
    return YES;
}
    
    
- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    // Prevent crashing undo bug – see note below.
    IQTextView* iqTextView = (IQTextView*)textView;
    iqTextView.shouldHideToolbarPlaceholder = NO;
    iqTextView.toolbarPlaceholder = [NSString stringWithFormat:@"%lu/%d",(unsigned long)textView.text.length, MAX_CHARACTER];
    
    if(range.length + range.location > textView.text.length)
    {
        return NO;
    }
    if ([text isEqualToString:@"\n"]) {
        [textView resignFirstResponder];
        [textView setFrame:[self newFrameFromTextView:textView]];
        return NO;
    }
    NSUInteger newLength = [textView.text length] + [text length] - range.length;
    return newLength <= MAX_CHARACTER;
}
    
    
-(void)animatetextView:(UITextView*)textView up:(BOOL)up keyboardFrameBeginRect:(CGRect)keyboardFrameBeginRect animation:(BOOL) animation
    {
        
        const int movementDistance = -(keyboardFrameBeginRect.size.height ); // tweak as needed
        const float movementDuration = animation ? 0.3f : 0; // tweak as needed
        
        int movement = (up ? movementDistance : -movementDistance);
        
        [UIView beginAnimations: @"animatetextView" context: nil];
        [UIView setAnimationBeginsFromCurrentState: YES];
        [UIView setAnimationDuration: movementDuration];
        self.navigationController.view.frame = CGRectOffset(self.navigationController.view.frame, 0, movement);
        [UIView commitAnimations];
    }
    
#pragma mark UICollectionViewDelegate
    //
    //-(NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    //    return [self.photos count];
    //}
    
-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    
    return [self.selfThumbs count];
}
    
-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    MWGridCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"GridCell" forIndexPath:indexPath];
    if (!cell) {
        cell = [[MWGridCell alloc] init];
    }
    id <MWPhoto> photo = [self.selfThumbs objectAtIndex:indexPath.row];
    cell.photo = photo;
    
    cell.selectionMode = NO;
    cell.isSelected = NO;
    cell.index = indexPath.row;
    if(self.currentIndex == indexPath.item){
        
        cell.layer.borderWidth = 2.0;
        cell.layer.borderColor = LIGHT_BLUE_CGCOLOR;
        self.prevSelectItem = cell;
        
    }else{
        
        cell.layer.borderWidth = 0;
        cell.layer.borderColor = [[UIColor clearColor] CGColor];
    }
    UIImage *img = [self imageForPhoto:photo];
    if (img) {
        [cell displayImage];
    } else {
        [photo loadUnderlyingImageAndNotify];
    }
    return cell;
    
}
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
    {
        dispatch_async (dispatch_get_main_queue (), ^{
            [self setCurrentPhotoIndex:indexPath.item];
            
            //        [self.collectionView layoutIfNeeded];
            
            [self.collectionView scrollToItemAtIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:YES];
            
            if(self.prevSelectItem != NULL){
                
                [self.prevSelectItem setHighlighted: NO];
                self.prevSelectItem.layer.borderWidth = 0.0;
                self.prevSelectItem.layer.borderColor = [[UIColor clearColor] CGColor];
            }
            
            MWGridCell *cell = (MWGridCell*)[self.collectionView cellForItemAtIndexPath:indexPath];
            if(cell != NULL){
                
                cell.layer.borderWidth = 2.0;
                cell.layer.borderColor = LIGHT_BLUE_CGCOLOR;
                self.prevSelectItem = cell;
                
            }
            
            [self resetTrimmerSubview];
            MWPhotoExt *photo = [self.selfPhotos objectAtIndex:indexPath.item];
            if(!photo.isVideo){
                NSString * caption = [ [self.selfPhotos objectAtIndex:indexPath.item] caption];
                
                [self.collectionView scrollToItemAtIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:YES];
                
                [_textView setText:caption];
                [_textView setFrame:[self newFrameFromTextView:_textView]];
                [_textView setHidden:NO];
            }else{
                [_textView setHidden:YES];
            }
            
        });
    }
    
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    CGFloat initHeight = collectionView.frame.size.height;
    return CGSizeMake(initHeight, initHeight);
    
}
    
- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section {
    return 3;
}
    
- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section {
    return 3;
}
    
-(CGRect) newFrameFromTextView:(UITextView*)textView{
    
    float rows = (textView.contentSize.height - textView.textContainerInset.top - textView.textContainerInset.bottom) / textView.font.lineHeight;
    float newRow =  MAX(MIN(5.0,rows), 2);
    float newHeight = MAX(31,newRow*textView.font.lineHeight) ;
    if( @available(iOS 11, *) ){
        return CGRectMake( self.view.safeAreaInsets.left, _parentView.frame.origin.y-10-newHeight, self.view.frame.size.width-self.view.safeAreaInsets.right , newHeight);
    }else{
        return CGRectMake( 10, _parentView.frame.origin.y-10-newHeight, self.view.frame.size.width-20 , newHeight);
    }
}
    
- (UIImage *)imageForPhoto:(id<MWPhoto>)photo {
    if (photo) {
        // Get image or obtain in background
        if ([photo underlyingImage]) {
            return [photo underlyingImage];
        } else {
            [photo loadUnderlyingImageAndNotify];
        }
    }
    return nil;
}
    
    
#pragma mark MWPhotoBrowserDelegate
    
- (void)photoBrowser:(MWPhotoBrowser *)photoBrowser didDisplayPhotoAtIndex:(NSUInteger)index{
    if(self.collectionView != NULL){
        if(self.prevSelectItem != NULL){
            
            [self.prevSelectItem setHighlighted: NO];
            self.prevSelectItem.layer.borderWidth = 0.0;
            self.prevSelectItem.layer.borderColor = [[UIColor clearColor] CGColor];
        }
        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:index inSection:0];
        //        NSLog(@"index path  %@",indexPath);
        MWGridCell *cell = (MWGridCell*)[self.collectionView cellForItemAtIndexPath:indexPath];
        if(cell != NULL){
            [cell setHighlighted:YES];
            
            cell.layer.borderWidth = 2.0;
            cell.layer.borderColor = LIGHT_BLUE_CGCOLOR;
            self.prevSelectItem = cell;
        }
        
        dispatch_async (dispatch_get_main_queue (), ^{
            MWPhotoExt *photo = [self.selfPhotos objectAtIndex:indexPath.item];
            if(!photo.isVideo){
                NSString * caption = [ [self.selfPhotos objectAtIndex:indexPath.item] caption];
                
                [self.collectionView scrollToItemAtIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:YES];
                
                [_textView setText:caption];
                [_textView setFrame:[self newFrameFromTextView:_textView]];
                [_textView setHidden:NO];
            }else{
                [_textView setHidden:YES];
            }
            
        });
        if(needResetLayout){
            [self resetTrimmerSubview];
            needResetLayout = NO;
        }
        
    }
}
    
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView{
    [self resetTrimmerSubview];
}
    
-(void) resetTrimmerSubview{
    id page = [self pageDisplayedAtIndex:[self currentIndex]];
    //    if(page != nil && [page isKindOfClass:[MWZoomingScrollView class]]){
    //        MWZoomingScrollView *scrollView = (MWZoomingScrollView*)page;
    if([page respondsToSelector:@selector(resetTrimmerSubview)]){
        NSLog(@"resetTrimmerSubview");
        [page resetTrimmerSubview];
    }
    //    }
}
    
- (NSUInteger)numberOfPhotosInPhotoBrowser:(MWPhotoBrowser *)photoBrowser {
    return [self.selfPhotos count];
}
    
- (id <MWPhoto>)photoBrowser:(MWPhotoBrowser *)photoBrowser photoAtIndex:(NSUInteger)index {
    return [self.selfPhotos objectAtIndex:index];
}
    
- (MWCaptionView *)photoBrowser:(MWPhotoBrowser *)photoBrowser captionViewForPhotoAtIndex:(NSUInteger)index{
    //    MWPhoto *photo = [self.photos objectAtIndex:index];
    //    MWCaptionView *captionView = [[MWCaptionView alloc] initWithPhoto:photo];
    //    return captionView;
    return nil;
}
    
-(NSString*) photoBrowser:(MWPhotoBrowser *)photoBrowser titleForPhotoAtIndex:(NSUInteger)index{
    NSString* title = @"";
//    if ([_selfDelegate respondsToSelector:@selector(photoBrowser:titleForPhotoAtIndex:)]) {
//        title = [_selfDelegate photoCaptionInputView:self titleForPhotoAtIndex:index];
//    }else{
//        title = [NSString stringWithFormat:@"%lu %@ %lu", (unsigned long)(photoBrowser.currentIndex+1), NSLocalizedString(@"of", @"Used in the context: 'Showing 1 of 3 items'"), (unsigned long) [self.selfPhotos count]];
//    }
    return title;
}
    
- (void)photoBrowserDidFinishModalPresentation:(MWPhotoBrowser *)photoBrowser{
    
    
    //    [_navigationController dismissViewControllerAnimated:NO completion:nil ];
    if ([_selfDelegate respondsToSelector:@selector(dismissPhotoCaptionInputView:)]) {
        [_selfDelegate dismissPhotoCaptionInputView:self];
    }
    NSMutableArray *captions = [NSMutableArray array];
    NSMutableArray *photos = [NSMutableArray array];
    [self.selfPhotos enumerateObjectsUsingBlock:^(MWPhotoExt* obj, NSUInteger idx, BOOL * _Nonnull stop) {
        
        [captions addObject:obj.caption != nil ? [obj caption] : @""];
        [photos addObject:obj.photoData];
    }];
    if ([_selfDelegate respondsToSelector:@selector(photoCaptionInputView:captions:photos:preSelectedAssets:)] ) {
        id page = [self pageDisplayedAtIndex:[self currentIndex]];
        if(page != nil && [page isKindOfClass:[MWZoomingScrollView class]]){
            if([page respondsToSelector:@selector(resetPlayer)]){
                [page resetPlayer];
            }
        }
        [_selfDelegate photoCaptionInputView:self captions:captions photos:photos preSelectedAssets:self.preSelectedAssets];
    }
    
}
    
- (NSMutableArray*)photoBrowser:(MWPhotoBrowser *)photoBrowser buildToolbarItems:(UIToolbar*)toolBar{
    
    NSMutableArray *items = nil;
    if([self.selfDelegate respondsToSelector:@selector(photoBrowser:buildToolbarItems:)]){
        items = [self.selfDelegate photoBrowser:photoBrowser buildToolbarItems:toolBar];
    }else{
        items = [NSMutableArray new];
    }
    return items;
}
    
- (BOOL)photoBrowser:(MWPhotoBrowser *)photoBrowser setNavBarAppearance:(UINavigationBar *)navigationBar{
    
    [photoBrowser.navigationController setNavigationBarHidden:NO animated:NO];
    navigationBar.barStyle = UIBarStyleBlackOpaque;
    navigationBar.barTintColor = [UIColor whiteColor];
    navigationBar.tintColor = [UIColor whiteColor];
    
    //    CAGradientLayer *gradient = [CAGradientLayer layer];
    //    gradient.frame = self.navigationController.navigationBar.bounds;
    //    gradient.colors = [NSArray arrayWithObjects:(id)[[UIColor colorWithWhite:0.0f alpha:0.5f] CGColor], (id)[[UIColor colorWithWhite:0.0f alpha:0.0f] CGColor], nil];
    //    [navigationBar setBackgroundImage:[self imageFromLayer:gradient] forBarMetrics:UIBarMetricsDefault];
    
    [navigationBar setBackgroundImage:[UIImage new] forBarMetrics:UIBarMetricsDefault];
    navigationBar.shadowImage = [UIImage new];
    [navigationBar setTitleTextAttributes: @{NSForegroundColorAttributeName:[UIColor whiteColor]}];
    navigationBar.layer.borderWidth = 0;
    return YES;
}
-(void) photoBrowser:(MWPhotoBrowser*)photoBrowser controlsHidden:(BOOL)hidden animated:(BOOL)animated{
    if(animated){
        if(hidden){
            self.parentView.alpha = 0.0f;
        }else{
            self.parentView.alpha = 1.0f;
        }
    }
}
- (UIImage *)imageFromLayer:(CALayer *)layer
    {
        UIGraphicsBeginImageContext([layer frame].size);
        
        [layer renderInContext:UIGraphicsGetCurrentContext()];
        UIImage *outputImage = UIGraphicsGetImageFromCurrentImageContext();
        
        UIGraphicsEndImageContext();
        
        return outputImage;
    }
    
    
- (void)didReceiveMemoryWarning {
    self.collectionView = nil;
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
    
    
    
#pragma mark - Video
- (void)_playVideo:(NSURL *)videoURL atPhotoIndex:(NSUInteger)index {
    //    [self setVideoLoadingIndicatorVisible:NO atPageIndex:index];
    //    id page = [self pageDisplayedAtIndex:index];
    //    if(page != nil && [page isKindOfClass:[MWZoomingScrollViewExt class]]){
    //        MWZoomingScrollViewExt *scrollView = (MWZoomingScrollViewExt*)page;
    [self setVideoLoadingIndicatorVisible:NO atPageIndex:index];
    //        [scrollView onVideoTapped];
    //    }
    
}
    
- (void)setVideoLoadingIndicatorVisible:(BOOL)visible atPageIndex:(NSUInteger)pageIndex {
    //    if (_currentVideoLoadingIndicator && !visible) {
    //        [_currentVideoLoadingIndicator removeFromSuperview];
    //        _currentVideoLoadingIndicator = nil;
    //        [[self pageDisplayedAtIndex:pageIndex] playButton].hidden = NO;
    //    } else if (!_currentVideoLoadingIndicator && visible) {
    //        _currentVideoLoadingIndicator = [[UIActivityIndicatorView alloc] initWithFrame:CGRectZero];
    //        [_currentVideoLoadingIndicator sizeToFit];
    //        [_currentVideoLoadingIndicator startAnimating];
    //        [_pagingScrollView addSubview:_currentVideoLoadingIndicator];
    //        [self positionVideoLoadingIndicator];
    //        [[self pageDisplayedAtIndex:pageIndex] playButton].hidden = YES;
    //    }
}
    /*
     #pragma mark - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
     // Get the new view controller using [segue destinationViewController].
     // Pass the selected object to the new view controller.
     }
     */
    
    
    
    
#pragma mark - GMImagePickerControllerDelegate
    
    
    
- (NSPredicate *)predicateOfAssetType:(PHAssetMediaType)type
    {
        return [NSPredicate predicateWithBlock:^BOOL(PHAsset *asset, NSDictionary *bindings) {
            return (asset.mediaType == type);
        }];
    }
    
- (void)assetsPickerController:(GMImagePickerController *)picker didFinishPickingAssets:(NSArray *)assetArray
    {
        UIScreen *screen = [UIScreen mainScreen];
        CGFloat scale = screen.scale;
        // Sizing is very rough... more thought required in a real implementation
        CGFloat imageSize = MAX(screen.bounds.size.width, screen.bounds.size.height) * 1.5;
        CGSize imageTargetSize = CGSizeMake(imageSize * scale, imageSize * scale);
        CGSize thumbTargetSize = CGSizeMake(imageSize / 3.0 * scale, imageSize / 3.0 * scale);
        
        
        [picker.presentingViewController dismissViewControllerAnimated:YES completion:nil];
        //    [preSelectedAssets removeAllObjects];
        
        //    NSArray* backPhotos = [NSArray arrayWithArray:self.selfPhotos];
        //No sure if remo all data from list and add it back
        NSMutableArray *assets = [NSMutableArray arrayWithArray:assetArray];
        NSMutableArray *removeAssets = [NSMutableArray new];
        NSIndexSet *toBeRemoved = [self.selfPhotos indexesOfObjectsPassingTest:^BOOL(MWPhotoExt* obj, NSUInteger idx, BOOL *stop) {
            // The block is called for each object in the array.
            //remove item if not exist
            BOOL stillExist = NO;
            
            for(PHAsset * asset in assets){
                if([[obj photoData ] isEqualToString:asset.localIdentifier]){
                    [removeAssets addObject:asset];
                    stillExist = YES;
                }
            }
            return !stillExist;
        }];
        [assets removeObjectsInArray:removeAssets];
        [self.selfPhotos removeObjectsAtIndexes:toBeRemoved];
        [self.selfThumbs removeObjectsAtIndexes:toBeRemoved];
        
        
        
        
        //TODO not yet handle deselect action
        [assets enumerateObjectsUsingBlock:^(PHAsset*  _Nonnull asset, NSUInteger idx, BOOL * _Nonnull stop) {
            [self.selfPhotos addObject:[MWPhotoExt photoWithAsset:asset targetSize:imageTargetSize]];
            [self.selfThumbs addObject:[MWPhotoExt photoWithAsset:asset targetSize:thumbTargetSize]];
        }];
        [self setCurrentPhotoIndex:self.selfPhotos.count-1];
        [self reloadPhoto];
        if(self.selfPhotos.count>1){
            self.navigationItem.rightBarButtonItem.enabled = YES;
        }
        if([self.selfPhotos count] >= self.maximumImagesCount){
            self.addButton.enabled = NO;
        }
        needResetLayout = YES;
        [self resetTrimmerSubview];
        
        
        
    }
-(BOOL)assetsPickerController:(GMImagePickerController *)picker shouldSelectAsset:(PHAsset *)asset{
    NSPredicate *videoPredicate = [self predicateOfAssetType:PHAssetMediaTypeVideo];
    NSInteger nVideos = [picker.selectedAssets filteredArrayUsingPredicate:videoPredicate].count;
    PHAssetMediaType mediaType = [asset mediaType];
    if(nVideos >= MAX_VIDEO_ALERT && mediaType == PHAssetMediaTypeVideo){
        dispatch_async(dispatch_get_main_queue(), ^{
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"]
                                                                           message:NSLocalizedString(@"VIDEO_SELECTION_LIMIT", nil)
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction * okAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil)
                                                                style:UIAlertActionStyleDefault
                                                              handler:^(UIAlertAction * _Nonnull action) {
                                                                  [alert dismissViewControllerAnimated:YES completion:nil];
                                                              }];
            [alert addAction:okAction];
            [picker presentViewController:alert animated:YES completion:nil];
        });
        return NO;
    }else if([picker.selectedAssets count] >= self.maximumImagesCount){
        dispatch_async(dispatch_get_main_queue(), ^{
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:[[NSBundle mainBundle]
                                                                                    objectForInfoDictionaryKey:@"CFBundleDisplayName"]
                                                                           message:NSLocalizedString(@"IMAGE_SELECTION_LIMIT", nil)
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction * okAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil)
                                                                style:UIAlertActionStyleDefault
                                                              handler:^(UIAlertAction * _Nonnull action) {
                                                                  [alert dismissViewControllerAnimated:YES completion:nil];
                                                              }];
            [alert addAction:okAction];
            [picker presentViewController:alert animated:YES completion:nil];
            
        });
        return NO;
        
    }else{
        return YES;
    }
}
    //Optional implementation:
-(void)assetsPickerControllerDidCancel:(GMImagePickerController *)picker
    {
        //    NSLog(@"GMImagePicker: User pressed cancel button");
    }
    
- (BOOL)shouldSelectAllAlbumCell{
    return YES;
}
-(NSString*) controllerTitle{
    return NSLocalizedString(@"SELECT_AN_ALBUM",nil);
}
-(NSString*) controllerCustomDoneButtonTitle{
    return NSLocalizedString(@"DONE",nil);
}
-(NSString*) controllerCustomCancelButtonTitle{
    return NSLocalizedString(@"CANCEL",nil);
}
#pragma mark -  Accessor
-(NSArray*) preSelectedAssets{
    if([self.selfPhotos count] > 0){
        NSArray *result = [self.selfPhotos valueForKey:@"photoData"];
        return result;
    }
    return nil;
}
    
    //lock orientation
    
- (void)viewLayoutMarginsDidChange{
    [super viewLayoutMarginsDidChange];
    [_textView setFrame:[self newFrameFromTextView:_textView]];
}
-(BOOL)shouldAutorotate {
    return YES;
}
    
-(UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait|UIInterfaceOrientationMaskLandscapeLeft|UIInterfaceOrientationMaskLandscapeRight;
}
    
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
    return YES;
}
    
- (BOOL)prefersStatusBarHidden {
    return NO;
}
    
- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleDefault;
}
    
-(NSBundle*) getBundle{
    return [NSBundle bundleForClass:[self superclass]];
}
-(MWZoomingScrollView *) InitMWZoomingScrollView {
    MWZoomingScrollViewExt *scrollView= [[MWZoomingScrollViewExt alloc] initWithPhotoBrowser:self];
    return scrollView;
}
    
#pragma mark - Camera Delegate
    
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info
{
    [picker.presentingViewController dismissViewControllerAnimated:YES completion:nil];
    
    
    __block MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.mode = MBProgressHUDModeAnnularDeterminate;
    hud.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.3];
    hud.label.text = NSLocalizedString(@"LOADING", nil);
    __weak __typeof(&*self)weakSelf = self;
    [hud showAnimated:YES];
    if ([PHObject class]) {
        NSString *mediaType = info[UIImagePickerControllerMediaType];
        
        
        dispatch_semaphore_t sema = dispatch_semaphore_create(0);
        __block PHAssetChangeRequest *assetRequest;
        __block PHObjectPlaceholder *placeholder;
        void (^completeHandler)(BOOL,NSError*) = ^(BOOL success,NSError* error){
            __strong __typeof(&*weakSelf)strongSelf = weakSelf;
            
            if (success) {
                
                NSLog(@"localIdentifier %@", placeholder.localIdentifier);
                
                dispatch_semaphore_signal(sema);
                UIScreen *screen = [UIScreen mainScreen];
                CGFloat scale = screen.scale;
                // Sizing is very rough... more thought required in a real implementation
                CGFloat imageSize = MAX(screen.bounds.size.width, screen.bounds.size.height) * 1.5;
                CGSize imageTargetSize = CGSizeMake(imageSize * scale, imageSize * scale);
                CGSize thumbTargetSize = CGSizeMake(imageSize / 3.0 * scale, imageSize / 3.0 * scale);
                
                PHFetchResult<PHAsset*> *fetchResult = [PHAsset fetchAssetsWithLocalIdentifiers: @[placeholder.localIdentifier] options:nil];
                PHAsset *asset = [fetchResult firstObject];
                if(asset){
                    [strongSelf.selfPhotos addObject:[MWPhotoExt photoWithAsset:asset targetSize:imageTargetSize]];
                    [strongSelf.selfThumbs addObject:[MWPhotoExt photoWithAsset:asset targetSize:thumbTargetSize]];
                    
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [strongSelf setCurrentPhotoIndex:self.selfPhotos.count-1];
                        [strongSelf reloadPhoto];
                        if(strongSelf.selfPhotos.count>1){
                            strongSelf.navigationItem.rightBarButtonItem.enabled = YES;
                        }
                        if([strongSelf.selfPhotos count] >= self.maximumImagesCount){
                            strongSelf.addButton.enabled = NO;
                        }
                        needResetLayout = YES;
                        [hud hideAnimated:YES];
                    });
                    
                }
                
            }
            else {
                NSLog(@"%@", error);
                dispatch_semaphore_signal(sema);
            }
        };
        
        if ([mediaType isEqualToString:(NSString *)kUTTypeImage]) {
            UIImage *image = info[UIImagePickerControllerOriginalImage];
            
            [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
                
                [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
                    assetRequest = [PHAssetChangeRequest creationRequestForAssetFromImage:image];
                    placeholder = [assetRequest placeholderForCreatedAsset];
                    
                } completionHandler:completeHandler];
                
            }];
        }else if ([mediaType isEqualToString:(NSString *)kUTTypeMovie]) {
            // Save to the album
            __block NSURL *movieUrl = info[UIImagePickerControllerMediaURL];
            [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
                
                [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
                    
                    
                    assetRequest = [PHAssetChangeRequest creationRequestForAssetFromVideoAtFileURL:movieUrl];
                    placeholder = [assetRequest placeholderForCreatedAsset];
                    
                    
                } completionHandler:completeHandler];
                
            }];
        }
    }
    
}
    
-(void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [picker.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

//-(void)image:(UIImage *)image finishedSavingWithError:(NSError *)error contextInfo:(void *)contextInfo
//{
//    if (error) {
//        UIAlertController *alertViewController = [UIAlertController alertControllerWithTitle:@"Image Not Saved" message:@"Sorry, unable to save the new image!" preferredStyle:UIAlertControllerStyleAlert];
//        [alertViewController addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
//            [alertViewController dismissViewControllerAnimated:YES completion:nil];
//        }]];
//        [self presentViewController:alertViewController animated:YES completion:nil];
//    }
//
//    // Note: The image view will auto refresh as the photo's are being observed in the other VCs
//}
@end
