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
#define LIGHT_BLUE_COLOR [UIColor colorWithRed:(99/255.0f)  green:(176/255.0f)  blue:(228.0f/255.0f) alpha:1.0]
#define LIGHT_BLUE_CGCOLOR [LIGHT_BLUE_COLOR CGColor]
@interface PhotoCaptionInputViewController ()<GMImagePickerControllerDelegate>{
    NSMutableArray* preSelectedAssets;
    UIView* hightlightView;
    BOOL keyboardIsShown;
    float textViewOrigY;
}
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
        if(_preselectedAssets == nil){
            preSelectedAssets = [NSMutableArray array];
        }else{
            preSelectedAssets = [NSMutableArray arrayWithArray:_preselectedAssets];
        }
        
        if(_selfPhotos == nil){
            [NSException raise:@"PhotoCaptionInputViewController photos is nil" format:@"PhotoCaptionInputViewController photos can not be nil."];
        }
        if(_selfThumbs == nil){
            [NSException raise:@"PhotoCaptionInputViewController thumbnail is nil" format:@"PhotoCaptionInputViewController thumbnail can not be nil."];
        }
        _selfDelegate = delegate;
        self.delegate = self;
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
    for(int i = 0 ;i < [self.selfPhotos count] ; i++){
        printf("{\n\"previewUrl\":\"%s\",\n", [[[self.selfPhotos objectAtIndex:i] photoData] cStringUsingEncoding:NSUTF8StringEncoding]);
    
        printf("\"thumbnailUrl\":\"%s\"\n},\n", [[[self.selfThumbs objectAtIndex:i] photoData] cStringUsingEncoding:NSUTF8StringEncoding]);
    }
//    if(self.selfPhotos == nil || [self.selfThumbs count] == 0){
//        NSMutableArray *photos = [[NSMutableArray alloc] init];
//        
//        NSMutableArray *thumbs = [[NSMutableArray alloc] init];
//        
//        MWPhotoExt * photo = [MWPhotoExt photoWithURL:[NSURL URLWithString:@"http://farm4.static.flickr.com/3779/9522424255_28a5a9d99c_b.jpg"]];
//        photo.caption = @"Tube";
//        [photos addObject:photo];
//        [thumbs addObject:[MWPhotoExt photoWithURL:[NSURL URLWithString:@"http://farm4.static.flickr.com/3779/9522424255_28a5a9d99c_q.jpg"]]];
//        photo = [MWPhotoExt photoWithURL:[NSURL URLWithString:@"http://farm4.static.flickr.com/3777/9522276829_fdea08ffe2_b.jpg"]];
//        photo.caption = @"Flat White at Elliot's";
//        [photos addObject:photo];
//        [thumbs addObject:[MWPhotoExt photoWithURL:[NSURL URLWithString:@"http://farm4.static.flickr.com/3777/9522276829_fdea08ffe2_q.jpg"]]];
//        photo = [MWPhotoExt photoWithURL:[NSURL URLWithString:@"http://farm9.static.flickr.com/8379/8530199945_47b386320f_b.jpg"]];
//        photo.caption = @"Woburn Abbey";
//        [photos addObject:photo];
//        [thumbs addObject:[MWPhotoExt photoWithURL:[NSURL URLWithString:@"http://farm9.static.flickr.com/8379/8530199945_47b386320f_q.jpg"]]];
//        photo = [MWPhotoExt photoWithURL:[NSURL URLWithString:@"http://farm9.static.flickr.com/8364/8268120482_332d61a89e_b.jpg"]];
//        photo.caption = @"Frosty walk";
//        [photos addObject:photo];
//        [thumbs addObject:[MWPhotoExt photoWithURL:[NSURL URLWithString:@"http://farm9.static.flickr.com/8364/8268120482_332d61a89e_q.jpg"]]];
//        
//        self.selfPhotos = photos;
//        self.selfThumbs = thumbs;
//    }
//    
    
    
    float initY = self.navigationController.view.frame.size.height * (11.0/12.0)-5;
    float initHeight = self.navigationController.view.frame.size.height * (1.0/12.0);
    
    UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
    [flowLayout setItemSize:CGSizeMake(initHeight, initHeight)];
    [flowLayout setScrollDirection:UICollectionViewScrollDirectionHorizontal];
    flowLayout.sectionInset = UIEdgeInsetsMake(0, 25, 0, 25);
    flowLayout.itemSize = CGSizeMake(initHeight, initHeight);
    flowLayout.minimumLineSpacing = 2;
    flowLayout.minimumInteritemSpacing = 2;
    flowLayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    
//    UIView * graoupView = [[UIView alloc]initWithFrame:CGRectMake(0,
//                                                                  initY,
//                                                                  self.navigationController.view.frame.size.width,
//                                                                  initHeight)];
    
    CGRect rect = CGRectMake(0,
                             initY-5,
                             self.navigationController.view.frame.size.width-initHeight,
                             initHeight);
    
    self.collectionView = [[UICollectionView alloc]initWithFrame:rect
                            collectionViewLayout:flowLayout
                           ];
    self.collectionView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth;
    
    [self.collectionView registerClass:[MWGridCell class] forCellWithReuseIdentifier:@"GridCell"];
    
    
    [self.collectionView setCollectionViewLayout:flowLayout];
    
    self.collectionView.delegate = self;
    self.collectionView.dataSource = self;
    
    self.addButton = [[UIButton alloc]initWithFrame:CGRectMake(self.collectionView.frame.origin.x + self.collectionView.frame.size.width,
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
    
    textViewOrigY = initY-40;
    CGRect tfrect = CGRectMake(0, textViewOrigY, self.navigationController.view.frame.size.width, 31);
    UITextView * textView = [[UITextView alloc] initWithFrame:tfrect textContainer:nil];
    textView.backgroundColor = [UIColor blackColor];
    textView.textColor = [UIColor whiteColor];
    
    textView.layer.cornerRadius=0.0f;
    textView.layer.masksToBounds=YES;
    textView.placeholder = NSLocalizedString(@"Add a caption…(0/160)", nil);
    textView.placeholderColor = [UIColor lightGrayColor]; // optional

    textView.font = [UIFont systemFontOfSize:14.0f];
//    textView.borderStyle = UITextBorderStyleRoundedRect;
//    textView.clearButtonMode = UITextViewViewModeWhileEditing;
    textView.returnKeyType = UIReturnKeyDone;
    textView.textAlignment = NSTextAlignmentLeft;
//    textView.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    textView.tag = 2;
    textView.autocapitalizationType = UITextAutocapitalizationTypeNone;
    textView.autocorrectionType = UITextAutocorrectionTypeNo;
    
    textView.delegate = self;
    
    textView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    _textView = textView;
    
    [_textView setText:[ [self.selfPhotos objectAtIndex:0] caption]];
    
    
    [self.navigationController.view addSubview:_textView];
    
    

    UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageForResourcePath:[NSString stringWithFormat:format, @"toolbarBackWhite"] ofType:@"png" inBundle:[NSBundle bundleForClass:[self class]]]
                                                                   style:UIBarButtonItemStylePlain
                                                                  target:self
                                                                  action:@selector(backAction)];
    
    self.navigationItem.leftBarButtonItem = backButton;
    
    _backButton = backButton;
    
    
    UIBarButtonItem *trashButton = [[UIBarButtonItem alloc] initWithImage:[ self imageFromSystemBarButton:UIBarButtonSystemItemTrash]
                                                                   style:UIBarButtonItemStylePlain
                                                                  target:self
                                                                  action:@selector(removePhoto)];
    NSString *trashString = @"\U000025C0\U0000FE0E"; //BLACK LEFT-POINTING TRIANGLE PLUS VARIATION SELECTOR
    trashButton.title = trashString;
    
    self.navigationItem.rightBarButtonItem = trashButton;
    
    _trashButton = trashButton;
    
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
    NSLog(@"backAction");
    if ([_selfDelegate respondsToSelector:@selector(dismissPhotoCaptionInputView:)]) {
        [_selfDelegate dismissPhotoCaptionInputView:self];
    }
//    if ([_selfDelegate respondsToSelector:@selector(photoCaptionInputView:captions:photos:preSelectedAssets:)]) {
//        NSMutableArray *captions = [NSMutableArray array];
//        NSMutableArray *photos = [NSMutableArray array];
//        [self.selfPhotos enumerateObjectsUsingBlock:^(MWPhotoExt* obj, NSUInteger idx, BOOL * _Nonnull stop) {
//            
//            [captions addObject:obj.caption != nil ? [obj caption] : @" "];
//            [photos addObject:obj.photoData];
//        }];
//        [_selfDelegate photoCaptionInputView:self captions:captions photos:photos preSelectedAssets:preSelectedAssets];
//    }
}

-(void) getPhotosCaptions{
    if ([_selfDelegate respondsToSelector:@selector(photoCaptionInputView:captions:photos:preSelectedAssets:)]) {
        NSMutableArray *captions = [NSMutableArray array];
        NSMutableArray *photos = [NSMutableArray array];
        [self.selfPhotos enumerateObjectsUsingBlock:^(MWPhotoExt* obj, NSUInteger idx, BOOL * _Nonnull stop) {
            
            [captions addObject:obj.caption != nil ? [obj caption] : @" "];
            [photos addObject:obj.photoData];
        }];
        [_selfDelegate photoCaptionInputView:self captions:captions photos:photos preSelectedAssets:preSelectedAssets];
    }
}

-(void)addPhotoFromLibrary{
    [self launchGMImagePicker];
}
- (void)launchGMImagePicker
{
    GMImagePickerController *picker = [[GMImagePickerController alloc] init:NO withAssets:preSelectedAssets delegate:self];
    
    picker.title = NSLocalizedString(@"Select an Album",nil);
    picker.customDoneButtonTitle = NSLocalizedString(@"Done",nil);
    picker.customCancelButtonTitle = NSLocalizedString(@"Cancel",nil);
 
    picker.colsInPortrait = 3;
    picker.colsInLandscape = 5;
    picker.minimumInteritemSpacing = 2.0;
    picker.navigationBarTintColor = LIGHT_BLUE_COLOR;
    picker.toolbarTextColor = LIGHT_BLUE_COLOR;
    picker.toolbarTintColor = LIGHT_BLUE_COLOR;
    //    picker.allowsMultipleSelection = NO;
    //    picker.confirmSingleSelection = YES;
    //    picker.confirmSingleSelectionPrompt = @"Do you want to select the image you have chosen?";
    
        picker.showCameraButton = YES;
        picker.autoSelectCameraImages = YES;
    
//    picker.modalPresentationStyle = UIModalPresentationPopover;
    
    //    picker.mediaTypes = @[@(PHAssetMediaTypeImage)];
    
    //    picker.pickerBackgroundColor = [UIColor blackColor];
    //    picker.pickerTextColor = [UIColor whiteColor];
    //    picker.toolbarBarTintColor = [UIColor darkGrayColor];
    //    picker.toolbarTextColor = [UIColor whiteColor];
    //    picker.toolbarTintColor = [UIColor redColor];
    //    picker.navigationBarBackgroundColor = [UIColor blackColor];
    //    picker.navigationBarTextColor = [UIColor whiteColor];
    //    picker.navigationBarTintColor = [UIColor redColor];
    //    picker.pickerFontName = @"Verdana";
    //    picker.pickerBoldFontName = @"Verdana-Bold";
    //    picker.pickerFontNormalSize = 14.f;
    //    picker.pickerFontHeaderSize = 17.0f;
    //    picker.pickerStatusBarStyle = UIStatusBarStyleLightContent;
    //    picker.useCustomFontForNavigationBar = YES;
    
//    UIPopoverPresentationController *popPC = picker.popoverPresentationController;
//    popPC.permittedArrowDirections = UIPopoverArrowDirectionAny;
//    popPC.sourceView = _gmImagePickerButton;
//    popPC.sourceRect = _gmImagePickerButton.bounds;
    //    popPC.backgroundColor = [UIColor blackColor];
    
//    [self showViewController:picker sender:nil];
    [self.navigationController presentViewController:picker animated:YES completion:nil];
}

-(void)removePhoto{
    if([self.selfPhotos count] > 0){
        NSLog(@"removePhoto");
        //may have problem
        MWPhotoExt *photo = [self.selfPhotos objectAtIndex:self.currentIndex];
        if([preSelectedAssets containsObject:photo.photoData]){
            [preSelectedAssets removeObject:photo.photoData];
        }
        [self.selfPhotos removeObjectAtIndex:self.currentIndex];
        [self.selfThumbs removeObjectAtIndex:self.currentIndex];
        [self.collectionView reloadData];
        [self reloadData];
        
        
        [_textView setText:[ [self.selfPhotos objectAtIndex:self.currentIndex] caption]];
        if([self.selfPhotos count]>1){
            self.navigationItem.rightBarButtonItem = _trashButton;
        }
        if([self.selfPhotos count]==0){
            self.navigationItem.rightBarButtonItem = nil;
        }
    }
    
}

-(void)reloadPhoto{
    NSLog(@"removePhoto");
    [self.collectionView reloadData];
    [self reloadData];
    self.navigationItem.rightBarButtonItem = _trashButton;
}


-(void) viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
//    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardDidShowNotification object:nil];
//    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardDidHideNotification object:nil];
}

#pragma mark UITextViewDelegate

-(void) onKeyboardDidShow :(NSNotification*)notification
{
    if(!keyboardIsShown){
        NSDictionary* keyboardInfo = [notification userInfo];
        NSValue* keyboardFrameBegin = [keyboardInfo valueForKey:UIKeyboardFrameBeginUserInfoKey];
        _keyboardRect= [keyboardFrameBegin CGRectValue];
        BOOL isNotOffset = (self.navigationController.view.frame.origin.y == 0);
        
        [self.navigationController.view setFrame:CGRectMake(0, 0, self.view.frame.size.width , self.view.frame.size.height)];
        [self animatetextView:_textView up:YES keyboardFrameBeginRect:_keyboardRect animation:isNotOffset];
        keyboardIsShown = YES;
    }
    
}

-(void) onKeyboardWillHide :(NSNotification*)notification
{
    if(keyboardIsShown){
        NSDictionary* keyboardInfo = [notification userInfo];
        NSValue* keyboardFrameBegin = [keyboardInfo valueForKey:UIKeyboardFrameBeginUserInfoKey];
        CGRect keyboardFrameBeginRect = [keyboardFrameBegin CGRectValue];
        [self animatetextView:_textView up:NO keyboardFrameBeginRect:keyboardFrameBeginRect animation:YES];
        keyboardIsShown = NO;
    }
    
}

-(void)textViewDidChange:(UITextView *)textView{
    MWPhotoExt *photo = [self.selfPhotos objectAtIndex:self.currentIndex];
    
    [photo setCaption:textView.text];
    [self.selfPhotos replaceObjectAtIndex:self.currentIndex withObject:photo];
    
}
- (BOOL)textViewShouldEndEditing:(UITextView *)textView{
    return YES;
}
-(void)textViewDidBeginEditing:(UITextView *)textView
{
//    [self animatetextView:_textView up:YES keyboardFrameBeginRect:keyboardRect];
    textView.backgroundColor = [UIColor whiteColor];
    textView.textColor = [UIColor blackColor];
}

- (void)textViewDidEndEditing:(UITextView *)textView
{
//    [self animatetextView:_textView up:YES keyboardFrameBeginRect:_keyboardRect];
//    [self animatetextView:textView up:NO :];
    textView.backgroundColor = [UIColor blackColor];
    textView.textColor = [UIColor whiteColor];
}
- (BOOL)textViewShouldReturn:(UITextView *)textView{
    NSLog(@"textViewShouldReturn:");
    if (textView.tag == 1) {
        UITextView *textView = (UITextView *)[self.navigationController.view viewWithTag:2];
        [textView becomeFirstResponder];
    }
    else {
        
        [textView resignFirstResponder];
        [textView setFrame:[self newFarameFromTextView:textView]];
        MWPhotoExt *photo = [self.selfPhotos objectAtIndex:self.currentIndex];
        
        [photo setCaption:textView.text];
        [self.selfPhotos replaceObjectAtIndex:self.currentIndex withObject:photo];
    }
    return YES;
}


- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    // Prevent crashing undo bug – see note below.
    if(range.length + range.location > textView.text.length)
    {
        return NO;
    }
    if ([text isEqualToString:@"\n"]) {
        [textView resignFirstResponder];
        [textView setFrame:[self newFarameFromTextView:textView]];
        return NO;
    }
    NSUInteger newLength = [textView.text length] + [text length] - range.length;
    return newLength <= 160;
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

        [_textView setFrame:[self newFarameFromTextView:_textView]];
    });
}

-(CGRect) newFarameFromTextView:(UITextView*)textView{
    CGRect originFrame = textView.frame;
    float rows = (textView.contentSize.height - textView.textContainerInset.top - textView.textContainerInset.bottom) / textView.font.lineHeight;
    float newRow =  MAX(MIN(5.0,rows), 2);
    float newHeight = newRow*textView.font.lineHeight ;
    float yOffset = ((newRow-1)*textView.font.lineHeight);
    CGRect newFrame = CGRectMake( originFrame.origin.x, textViewOrigY-yOffset, originFrame.size.width, newHeight);
    textView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin;
    return newFrame;
//    return textView.frame;
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
        NSLog(@"index path  %@",indexPath);
        MWGridCell *cell = (MWGridCell*)[self.collectionView cellForItemAtIndexPath:indexPath];
        if(cell != NULL){
            [cell setHighlighted:YES];
            
            cell.layer.borderWidth = 2.0;
            cell.layer.borderColor = LIGHT_BLUE_CGCOLOR;
            self.prevSelectItem = cell;
            [self.collectionView reloadData];
            [_textView setText:[[self.selfPhotos objectAtIndex:index] caption]];
            [_textView setFrame:[self newFarameFromTextView:_textView]];
            [_textView scrollsToTop];
             dispatch_async (dispatch_get_main_queue (), ^{
                 [self.collectionView layoutIfNeeded];
                 [self.collectionView scrollToItemAtIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:YES];
             });
        }
        
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
    if ([_selfDelegate respondsToSelector:@selector(photoCaptionInputView:captions:photos:preSelectedAssets:)]) {
        NSMutableArray *captions = [NSMutableArray array];
        NSMutableArray *photos = [NSMutableArray array];
        [self.selfPhotos enumerateObjectsUsingBlock:^(MWPhotoExt* obj, NSUInteger idx, BOOL * _Nonnull stop) {
            
            [captions addObject:obj.caption != nil ? [obj caption] : @" "];
            [photos addObject:obj.photoData];
        }];
        [_selfDelegate photoCaptionInputView:self captions:captions photos:photos preSelectedAssets:preSelectedAssets];
    }
    
}


- (void)didReceiveMemoryWarning {
    self.collectionView = nil;
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
    [preSelectedAssets removeAllObjects];
    
    NSIndexSet *toBeRemoved = [self.selfPhotos indexesOfObjectsPassingTest:^BOOL(MWPhotoExt* obj, NSUInteger idx, BOOL *stop) {
        // The block is called for each object in the array.
        NSURL* url = [NSURL URLWithString:[ obj photoData]];
        BOOL removeIt = (![url isFileReferenceURL] && ![[ obj photoData] hasPrefix:@"http"]) ;
        return removeIt;
    }];
    [self.selfPhotos removeObjectsAtIndexes:toBeRemoved];
    
    toBeRemoved = [self.selfThumbs indexesOfObjectsPassingTest:^BOOL(MWPhotoExt* obj, NSUInteger idx, BOOL *stop) {
        // The block is called for each object in the array.
        NSURL* url = [NSURL URLWithString:[ obj photoData]];
        BOOL removeIt = (![url isFileReferenceURL] && ![[ obj photoData] hasPrefix:@"http"]) ;
        return removeIt;
    }];
    [self.selfThumbs removeObjectsAtIndexes:toBeRemoved];
    
    [picker.presentingViewController dismissViewControllerAnimated:YES completion:nil];
    
    NSLog(@"GMImagePicker: User ended picking assets. Number of selected items is: %lu", (unsigned long)assetArray.count);
    
    UIScreen *screen = [UIScreen mainScreen];
    CGFloat scale = screen.scale;
    // Sizing is very rough... more thought required in a real implementation
    CGFloat imageSize = MAX(screen.bounds.size.width, screen.bounds.size.height) * 1.5;
    CGSize imageTargetSize = CGSizeMake(imageSize * scale, imageSize * scale);
    CGSize thumbTargetSize = CGSizeMake(imageSize / 3.0 * scale, imageSize / 3.0 * scale);
    //TODO not yet handle deselect action
    [assetArray enumerateObjectsUsingBlock:^(PHAsset*  _Nonnull asset, NSUInteger idx, BOOL * _Nonnull stop) {
        
        NSLog(@"obj.localIdentifier %@",asset.localIdentifier );
        
        
        BOOL preselected = NO;
        for (NSString * localidentifier in preSelectedAssets){
            if([localidentifier isEqualToString:asset.localIdentifier]){
                preselected = YES;
                break;
            }
        }
        if(!preselected){
            [preSelectedAssets addObject:asset.localIdentifier];
            [self.selfPhotos addObject:[MWPhotoExt photoWithAsset:asset targetSize:imageTargetSize]];
            [self.selfThumbs addObject:[MWPhotoExt photoWithAsset:asset targetSize:thumbTargetSize]];
        }
    }];
    [self setCurrentPhotoIndex:self.selfPhotos.count-1];
    [self reloadPhoto];
    
}

//Optional implementation:
-(void)assetsPickerControllerDidCancel:(GMImagePickerController *)picker
{
    NSLog(@"GMImagePicker: User pressed cancel button");
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


@end
