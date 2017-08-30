//
//  PhotoCaptionInputViewController.m
//  Pods
//
//  Created by James Kong on 12/4/2017.
//
//

#import "PhotoCaptionInputViewController.h"
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

#define LIGHT_BLUE_COLOR [UIColor colorWithRed:(99/255.0f)  green:(176/255.0f)  blue:(228.0f/255.0f) alpha:1.0]
#define LIGHT_BLUE_CGCOLOR [LIGHT_BLUE_COLOR CGColor]
#define TEXTFIELD_BG_COLOR [UIColor whiteColor]
#define TEXTFIELD_TEXT_COLOR [UIColor blackColor]
#define MAX_CHARACTER 160
#define PLACEHOLDER_TEXT [NSString stringWithFormat:@"%@(0/%d)", NSLocalizedString(@"Add a caption…",nil) , MAX_CHARACTER]
#define LAYOUT_START_Y 10.5f
#define BUNDLE_UIIMAGE(imageNames) [UIImage imageNamed:[NSString stringWithFormat:@"%@.bundle/%@", NSStringFromClass([self class]), imageNames]]
#define BIN_UIIMAGE BUNDLE_UIIMAGE(@"images/bin.png")
@interface PhotoCaptionInputViewController ()<GMImagePickerControllerDelegate>{
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
    float initHeight = self.navigationController.view.frame.size.height * (1.0/12.0);
    textViewOrigYRatio = (initY-30) / self.navigationController.view.frame.size.height;
    UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
    [flowLayout setItemSize:CGSizeMake(initHeight, initHeight)];
    [flowLayout setScrollDirection:UICollectionViewScrollDirectionHorizontal];
    //    flowLayout.sectionInset = UIEdgeInsetsMake(5, 25, 5, 25);
    flowLayout.itemSize = CGSizeMake(initHeight, initHeight);
    flowLayout.minimumLineSpacing = 3;
    flowLayout.minimumInteritemSpacing = 3;
    flowLayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    
    CGRect rect = CGRectMake(5,
                             initY,
                             self.navigationController.view.frame.size.width-initHeight-15,
                             initHeight);
    
    self.collectionView = [[UICollectionView alloc]initWithFrame:rect
                                            collectionViewLayout:flowLayout
                           ];
    self.collectionView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth;
    
    [self.collectionView registerClass:[MWGridCell class] forCellWithReuseIdentifier:@"GridCell"];
    self.collectionView.backgroundColor = [UIColor clearColor];
    
    [self.collectionView setCollectionViewLayout:flowLayout];
    
    self.collectionView.delegate = self;
    self.collectionView.dataSource = self;
    
    self.addButton = [[UIButton alloc]initWithFrame:CGRectMake(self.navigationController.view.frame.size.width-initHeight-5,
                                                               rect.origin.y,
                                                               initHeight,
                                                               initHeight
                                                               ) ];
    
    NSString *format = @"PhotoCaptionInputView.bundle/%@";
    [self.addButton setImage:[UIImage imageForResourcePath:[NSString stringWithFormat:format, @"add_button"] ofType:@"png" inBundle:[NSBundle bundleForClass:[self class]]]  forState:UIControlStateNormal];
    self.addButton.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleLeftMargin;
    [self.addButton addTarget:self action:@selector(addPhotoFromLibrary) forControlEvents:UIControlEventTouchUpInside];
    
    [self.navigationController.view addSubview:self.addButton];
    
    [self.navigationController.view addSubview:self.collectionView];
    
    
    CGRect tfrect = CGRectMake(5, textViewOrigYRatio * self.navigationController.view.frame.size.height, self.navigationController.view.frame.size.width-10, 31);
    IQTextView * textView = [[IQTextView alloc] initWithFrame:tfrect textContainer:nil];
    
    //    [[IQKeyboardManager sharedManager]setEnable:YES];
    [[IQKeyboardManager sharedManager] setShouldShowToolbarPlaceholder:YES];
    [[IQKeyboardManager sharedManager] setKeyboardDistanceFromTextField:initHeight];
    //    [[IQKeyboardManager sharedManager] setEnableAutoToolbar:YES];
    //    [[IQKeyboardManager sharedManager] setKeyboardAppearance:UIKeyboardAppearanceLight];
    //    [[IQKeyboardManager sharedManager] setShouldResignOnTouchOutside:YES];
    
    
    //    textView.autocorrectionType = UITextAutocorrectionTypeYes;
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
    textView.autocapitalizationType = UITextAutocapitalizationTypeNone;
    textView.autocorrectionType = UITextAutocorrectionTypeYes;
    
    textView.delegate = self;
    
    textView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    _textView = textView;
    if([self.selfPhotos count] >0){
        [_textView setText:[ [self.selfPhotos objectAtIndex:0] caption]];
        
        ((IQTextView*)_textView).toolbarPlaceholder = ([[ [self.selfPhotos objectAtIndex:0] caption] length]) == 0 ? PLACEHOLDER_TEXT : [NSString stringWithFormat:@"%lu/MAX_CHARACTER",(unsigned long)_textView.text.length];
        
    }
    
    
    
    [self.navigationController.view addSubview:_textView];
    
    
    
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
            [startEndTimes addObject:obj.startEndTime != nil ? [obj startEndTime] : (obj.isVideo) ? @{@"startTime":@(0.0f),
                                                                                                      @"endTime":@(10.0f)}:[NSNull null]];
        }];
        [_selfDelegate photoCaptionInputView:self captions:captions photos:photos preSelectedAssets: self.preSelectedAssets startEndTime:startEndTimes];
    }
}

-(void)addPhotoFromLibrary{
    [self launchGMImagePicker];
}
- (void)launchGMImagePicker
{
    GMImagePickerController *picker = [[GMImagePickerController alloc] init:NO withAssets:self.preSelectedAssets delegate:self];
    
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
    picker.title = NSLocalizedString(@"Select an Album",nil);
    picker.customDoneButtonTitle = NSLocalizedString(@"Done",nil);
    picker.customCancelButtonTitle = NSLocalizedString(@"Cancel",nil);
    
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
        MWPhotoExt *photo = [self.selfPhotos objectAtIndex:self.currentIndex];
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
        
        [self.collectionView layoutIfNeeded];
        
        [self.collectionView scrollToItemAtIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:YES];
        
        if(self.prevSelectItem != NULL){
            
            [self.prevSelectItem setHighlighted: NO];
            self.prevSelectItem.layer.borderWidth = 0.0;
            self.prevSelectItem.layer.borderColor = [[UIColor clearColor] CGColor];
        }
        
        //        [self.delegate photoBrowser:self didDisplayPhotoAtIndex:indexPath.item];
        MWGridCell *cell = (MWGridCell*)[self.collectionView cellForItemAtIndexPath:indexPath];
        if(cell != NULL){
            
            cell.layer.borderWidth = 2.0;
            cell.layer.borderColor = LIGHT_BLUE_CGCOLOR;
            self.prevSelectItem = cell;
            
        }
        
        
        [_textView setText:[ [self.selfPhotos objectAtIndex:indexPath.item] caption]];
        ((IQTextView*)_textView).toolbarPlaceholder = ([[ [self.selfPhotos objectAtIndex:indexPath.item] caption] length]) == 0 ? PLACEHOLDER_TEXT : [NSString stringWithFormat:@"%lu/%d",(unsigned long)_textView.text.length, MAX_CHARACTER];
        [_textView setFrame:[self newFrameFromTextView:_textView]];
        
    });
}
- (void)jumpToPageAtIndex:(NSUInteger)index animated:(BOOL)animated{
    [super jumpToPageAtIndex:index animated:animated];
    [self resetTrimmerSubview];
}
-(CGRect) newFrameFromTextView:(UITextView*)textView{
    //    if(!keyboardIsShown){
    if(self.navigationController.view.frame.size.height > self.navigationController.view.frame.size.width){
        float initY = self.navigationController.view.frame.size.height * (LAYOUT_START_Y/12.0)-9;
        textViewOrigYRatio = (initY-30) / self.navigationController.view.frame.size.height;
    }else{
        float initY = self.navigationController.view.frame.size.height * (9.0/12.0)-10;
        textViewOrigYRatio = (initY-30) / self.navigationController.view.frame.size.height;
    }
    CGRect originFrame = textView.frame;
    float rows = (textView.contentSize.height - textView.textContainerInset.top - textView.textContainerInset.bottom) / textView.font.lineHeight;
    float newRow =  MAX(MIN(5.0,rows), 2);
    float newHeight = newRow*textView.font.lineHeight ;
    float yOffset = ((newRow-1)*textView.font.lineHeight);
    CGRect newFrame = CGRectMake( originFrame.origin.x, (textViewOrigYRatio * self.navigationController.view.frame.size.height)-yOffset, originFrame.size.width, newHeight);
    textView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin;
    return newFrame;
    //    }else{
    //        return textView.frame;
    //    }
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
            [self.collectionView reloadData];
            [_textView setText:[[self.selfPhotos objectAtIndex:index] caption]];
            ((IQTextView*)_textView).toolbarPlaceholder = ([[ [self.selfPhotos objectAtIndex:0] caption] length]) == 0 ? PLACEHOLDER_TEXT : [NSString stringWithFormat:@"%lu/%d",(unsigned long)_textView.text.length, MAX_CHARACTER];
            [_textView setFrame:[self newFrameFromTextView:_textView]];
            //            [_textView scrollsToTop];
            dispatch_async (dispatch_get_main_queue (), ^{
                [self.collectionView layoutIfNeeded];
                [self.collectionView scrollToItemAtIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:YES];
            });
            
        }
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
    if(page != nil && [page isKindOfClass:[MWZoomingScrollViewExt class]]){
        MWZoomingScrollViewExt *scrollView = (MWZoomingScrollViewExt*)page;
        NSLog(@"resetTrimmerSubview");
        [scrollView resetTrimmerSubview];
    }
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
    if ([_selfDelegate respondsToSelector:@selector(photoBrowser:titleForPhotoAtIndex:)]) {
        title = [_selfDelegate photoCaptionInputView:self titleForPhotoAtIndex:index];
    }else{
        title = [NSString stringWithFormat:@"%lu %@ %lu", (unsigned long)(photoBrowser.currentIndex+1), NSLocalizedString(@"of", @"Used in the context: 'Showing 1 of 3 items'"), (unsigned long) [self.selfPhotos count]];
    }
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
    navigationBar.barStyle = UIBarStyleDefault;
    navigationBar.barTintColor = [UIColor whiteColor];
    navigationBar.tintColor = [UIColor whiteColor];
    
//    CAGradientLayer *gradient = [CAGradientLayer layer];
//    gradient.frame = self.navigationController.navigationBar.bounds;
//    gradient.colors = [NSArray arrayWithObjects:(id)[[UIColor colorWithWhite:0.0f alpha:0.5f] CGColor], (id)[[UIColor colorWithWhite:0.0f alpha:0.0f] CGColor], nil];
//    [navigationBar setBackgroundImage:[self imageFromLayer:gradient] forBarMetrics:UIBarMetricsDefault];
    
    [navigationBar setBackgroundImage:[UIImage new] forBarMetrics:UIBarMetricsDefault];
    navigationBar.shadowImage = [UIImage new];
    [navigationBar setTitleTextAttributes: @{NSForegroundColorAttributeName:[UIColor whiteColor]}];
    //    navigationBar.shadowImage = [[UIImage alloc] init];
    navigationBar.layer.borderWidth = 0;
    
    
    return YES;
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

- (void)assetsPickerController:(GMImagePickerController *)picker didFinishPickingAssets:(NSArray *)assetArray
{
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
    
    [picker.presentingViewController dismissViewControllerAnimated:YES completion:nil];
    
    
    UIScreen *screen = [UIScreen mainScreen];
    CGFloat scale = screen.scale;
    // Sizing is very rough... more thought required in a real implementation
    CGFloat imageSize = MAX(screen.bounds.size.width, screen.bounds.size.height) * 1.5;
    CGSize imageTargetSize = CGSizeMake(imageSize * scale, imageSize * scale);
    CGSize thumbTargetSize = CGSizeMake(imageSize / 3.0 * scale, imageSize / 3.0 * scale);
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
    
    if([picker.selectedAssets count] >= self.maximumImagesCount){
        dispatch_async(dispatch_get_main_queue(), ^{
            UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:[[NSBundle mainBundle]
                                                                         objectForInfoDictionaryKey:@"CFBundleDisplayName"]
                                                                message:NSLocalizedString(@"IMAGE_SELECTION_LIMIT", nil)
                                                               delegate:self
                                                      cancelButtonTitle:NSLocalizedString(@"OK", nil)
                                                      otherButtonTitles:nil, nil];
            [alertView show];
            
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
    return NSLocalizedString(@"Select an Album",nil);
}
-(NSString*) controllerCustomDoneButtonTitle{
    return NSLocalizedString(@"Done",nil);
}
-(NSString*) controllerCustomCancelButtonTitle{
    return NSLocalizedString(@"Cancel",nil);
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

-(BOOL)shouldAutorotate {
    return NO;
}

-(UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
    return NO;
}

- (BOOL)prefersStatusBarHidden {
    return NO;
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

-(NSBundle*) getBundle{
    return [NSBundle bundleForClass:[self superclass]];
}
-(MWZoomingScrollView *) InitMWZoomingScrollView {
    MWZoomingScrollViewExt *scrollView= [[MWZoomingScrollViewExt alloc] initWithPhotoBrowser:self];
    [scrollView setMDelegate:self];
    return scrollView;
}
-(void) zoomingScrollView:(MWZoomingScrollViewExt*) zoomingScrollViewExt photo:(id<MWPhoto>)photo startTime:(CGFloat)startTime endTime:(CGFloat) endTime{
    NSDictionary *startEndTime = [[NSDictionary alloc] initWithObjectsAndKeys:
                                  @(startTime), @"startTime",
                                  @(endTime), @"endTime",
                                  nil];
    [self.selfPhotos enumerateObjectsUsingBlock:^(MWPhotoExt* obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if([obj.photoData isEqualToString:((MWPhotoExt*)photo).photoData]){
            if(obj.startEndTime != nil){
//                float oldStartTime = [[obj.startEndTime valueForKey:@"startTime"] floatValue];
//                float oldEndTime = [[obj.startEndTime valueForKey:@"endTime"] floatValue];
//                if(oldStartTime != startTime || oldEndTime != endTime ){
//                    [zoomingScrollViewExt setStartTime:[[obj.startEndTime valueForKey:@"startTime"] floatValue]
//                                           endTime:[[obj.startEndTime valueForKey:@"endTime"] floatValue]];
//                }
            }else{
                obj.startEndTime = startEndTime;
                
//                [zoomingScrollViewExt setStartTime:[[obj.startEndTime valueForKey:@"startTime"] floatValue]
//                                           endTime:[[obj.startEndTime valueForKey:@"endTime"] floatValue]];
            }
            *stop = YES;
            return;
        }
    }];
}
@end


