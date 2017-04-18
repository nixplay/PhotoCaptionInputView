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

@interface PhotoCaptionInputViewController ()

@end

@implementation PhotoCaptionInputViewController
@synthesize browser = _browser;
@synthesize collectionView = _collectionView;
@synthesize addButton = _addButton;
@synthesize textfield = _textfield;
@synthesize navigationController = _navigationController;

#pragma mark - Init

- (id)init {
    if ((self = [super init])) {
        [self _initialisation];
    }
    return self;
}

-(id)initWithPhotos:(NSArray*)photos thumbnails:(NSArray*)thumbnails{
    if ((self = [super init])) {
        [self _initialisation];
        self.photos = [NSMutableArray arrayWithArray:photos];
        self.thumbs = thumbnails;
    }
    return self;
    
}
- (id)initWithCoder:(NSCoder *)decoder {
    if ((self = [super initWithCoder:decoder])) {
        [self _initialisation];
    }
    return self;
}
- (void)viewDidLoad {
    [super viewDidLoad];
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
    self.browser = [[MWPhotoBrowser alloc] initWithDelegate:self];
    self.browser.displayActionButton = displayActionButton;
    self.browser.displayNavArrows = displayNavArrows;
    self.browser.displaySelectionButtons = displaySelectionButtons;
    self.browser.alwaysShowControls = displaySelectionButtons;
    self.browser.zoomPhotosToFill = YES;
    self.browser.enableGrid = enableGrid;
    self.browser.startOnGrid = startOnGrid;
    self.browser.enableSwipeToDismiss = NO;
    self.browser.autoPlayOnAppear = autoPlayOnAppear;
    [self.browser setCurrentPhotoIndex:0];
}
-(void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if(self.photos == nil || [self.photos count] == 0){
        NSMutableArray *photos = [[NSMutableArray alloc] init];
        
        NSMutableArray *thumbs = [[NSMutableArray alloc] init];
        
        MWPhoto * photo = [MWPhoto photoWithURL:[NSURL URLWithString:@"http://farm4.static.flickr.com/3779/9522424255_28a5a9d99c_b.jpg"]];
        photo.caption = @"Tube";
        [photos addObject:photo];
        [thumbs addObject:[MWPhoto photoWithURL:[NSURL URLWithString:@"http://farm4.static.flickr.com/3779/9522424255_28a5a9d99c_q.jpg"]]];
        photo = [MWPhoto photoWithURL:[NSURL URLWithString:@"http://farm4.static.flickr.com/3777/9522276829_fdea08ffe2_b.jpg"]];
        photo.caption = @"Flat White at Elliot's";
        [photos addObject:photo];
        [thumbs addObject:[MWPhoto photoWithURL:[NSURL URLWithString:@"http://farm4.static.flickr.com/3777/9522276829_fdea08ffe2_q.jpg"]]];
        photo = [MWPhoto photoWithURL:[NSURL URLWithString:@"http://farm9.static.flickr.com/8379/8530199945_47b386320f_b.jpg"]];
        photo.caption = @"Woburn Abbey";
        [photos addObject:photo];
        [thumbs addObject:[MWPhoto photoWithURL:[NSURL URLWithString:@"http://farm9.static.flickr.com/8379/8530199945_47b386320f_q.jpg"]]];
        photo = [MWPhoto photoWithURL:[NSURL URLWithString:@"http://farm9.static.flickr.com/8364/8268120482_332d61a89e_b.jpg"]];
        photo.caption = @"Frosty walk";
        [photos addObject:photo];
        [thumbs addObject:[MWPhoto photoWithURL:[NSURL URLWithString:@"http://farm9.static.flickr.com/8364/8268120482_332d61a89e_q.jpg"]]];
        
        self.photos = photos;
        self.thumbs = thumbs;
    }
    
    
    UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:self.browser];
   
    float initY = self.view.frame.size.height * (11.0/12.0)-10;
    float initHeight = self.view.frame.size.height * (1.0/12.0);
    
    UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
    [flowLayout setItemSize:CGSizeMake(initHeight, initHeight)];
    [flowLayout setScrollDirection:UICollectionViewScrollDirectionHorizontal];
    flowLayout.sectionInset = UIEdgeInsetsMake(0, 25, 0, 25);
    flowLayout.itemSize = CGSizeMake(50, 50);
    flowLayout.minimumLineSpacing = 2;
    flowLayout.minimumInteritemSpacing = 2;
    flowLayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    
    UIView * graoupView = [[UIView alloc]initWithFrame:CGRectMake(0,
                                                                 initY,
                                                                 self.view.frame.size.width,
                                                                  initHeight)];
    
    self.collectionView = [[UICollectionView alloc]initWithFrame:
                           CGRectMake(0,
                                      initY,
                                      self.view.frame.size.width-initHeight,
                                      initHeight) collectionViewLayout:flowLayout
                                  ];
    self.collectionView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth;
    
    [self.collectionView registerClass:[MWGridCell class] forCellWithReuseIdentifier:@"GridCell"];
    
    
    [self.collectionView setCollectionViewLayout:flowLayout];
    
    self.collectionView.delegate = self;
    self.collectionView.dataSource = self;
    
    self.addButton = [[UIButton alloc]initWithFrame:CGRectMake(self.collectionView.frame.origin.x + self.collectionView.frame.size.width,
                                                               initY,
                                                               initHeight,
                                                               initHeight
                                                               ) ];
    
    NSString *format = @"PhotoCaptionInputView.bundle/%@";
    [self.addButton setImage:[UIImage imageForResourcePath:[NSString stringWithFormat:format, @"add_button"] ofType:@"png" inBundle:[NSBundle bundleForClass:[self class]]]  forState:UIControlStateNormal];
    self.addButton.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth;
    [nc.view addSubview:self.addButton];

    [nc.view addSubview:self.collectionView];
    
    
    CGRect rect = CGRectMake(0, initY-32, self.view.frame.size.width, 31);
    UITextField *textfield = [[UITextField alloc] initWithFrame:rect];
    
    textfield.backgroundColor = [UIColor whiteColor];
    textfield.textColor = [UIColor blackColor];
    textfield.font = [UIFont systemFontOfSize:14.0f];
    textfield.borderStyle = UITextBorderStyleRoundedRect;
    textfield.clearButtonMode = UITextFieldViewModeWhileEditing;
    textfield.returnKeyType = UIReturnKeyDone;
    textfield.textAlignment = NSTextAlignmentLeft;
    textfield.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    textfield.tag = 2;
    textfield.autocapitalizationType = UITextAutocapitalizationTypeNone;
    textfield.autocorrectionType = UITextAutocorrectionTypeNo;
    
    textfield.delegate = self;
    
    textfield.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth;
    _textfield = textfield;
    [nc.view addSubview:_textfield];
    
    
    [self presentViewController:nc animated:NO completion:^{
        
    }];
    _navigationController = nc;
}
- (void)_initialisation {
    

    
    // Do any additional setup after loading the view.
}

-(void) viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
//    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardDidShowNotification object:nil];
//    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardDidHideNotification object:nil];
}

#pragma mark UITextFieldDelegate

-(void) onKeyboardDidShow :(NSNotification*)notification
{
    NSDictionary* keyboardInfo = [notification userInfo];
    NSValue* keyboardFrameBegin = [keyboardInfo valueForKey:UIKeyboardFrameBeginUserInfoKey];
    _keyboardRect = [keyboardFrameBegin CGRectValue];
    [self animateTextField:_textfield up:YES keyboardFrameBeginRect:_keyboardRect];
}

-(void) onKeyboardWillHide :(NSNotification*)notification
{
//    NSDictionary* keyboardInfo = [notification userInfo];
//    NSValue* keyboardFrameBegin = [keyboardInfo valueForKey:UIKeyboardFrameBeginUserInfoKey];
//    CGRect keyboardFrameBeginRect = [keyboardFrameBegin CGRectValue];
    [self animateTextField:_textfield up:NO keyboardFrameBeginRect:_keyboardRect];
}

-(void)textFieldDidBeginEditing:(UITextField *)textField
{
//    [self animateTextField:_textfield up:YES keyboardFrameBeginRect:keyboardRect];
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
//    [self animateTextField:_textfield up:YES keyboardFrameBeginRect:_keyboardRect];
//    [self animateTextField:textField up:NO :];
}
- (BOOL)textFieldShouldReturn:(UITextField *)textField{
    NSLog(@"textFieldShouldReturn:");
    if (textField.tag == 1) {
        UITextField *textField = (UITextField *)[self.view viewWithTag:2];
        [textField becomeFirstResponder];
    }
    else {
        
        [textField resignFirstResponder];
        MWPhoto *photo = self.prevSelectItem.photo;
        
        [photo setCaption:textField.text];
    }
    return YES;
}

-(void)animateTextField:(UITextField*)textField up:(BOOL)up keyboardFrameBeginRect:(CGRect)keyboardFrameBeginRect
{
    const int movementDistance = -keyboardFrameBeginRect.size.height+(self.view.frame.size.height-textField.frame.origin.y-textField.frame.size.height); // tweak as needed
    const float movementDuration = 0.3f; // tweak as needed
    
    int movement = (up ? movementDistance : -movementDistance);
    
    [UIView beginAnimations: @"animateTextField" context: nil];
    [UIView setAnimationBeginsFromCurrentState: YES];
    [UIView setAnimationDuration: movementDuration];
    _navigationController.view.frame = CGRectOffset(_navigationController.view.frame, 0, movement);
    [UIView commitAnimations];
}

#pragma mark UICollectionViewDelegate
//
//-(NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
//    return [self.photos count];
//}

-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    
    return [self.thumbs count];
}

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    MWGridCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"GridCell" forIndexPath:indexPath];
    if (!cell) {
        cell = [[MWGridCell alloc] init];
    }
    id <MWPhoto> photo = [self.thumbs objectAtIndex:indexPath.row];
    cell.photo = photo;
    
    cell.selectionMode = NO;
    cell.isSelected = NO;
    cell.index = indexPath.row;

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
        [self.browser setCurrentPhotoIndex:indexPath.item];
        
        [self.collectionView layoutIfNeeded];
        
        [self.collectionView scrollToItemAtIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:YES];
        
        [_textfield setText:[ [self.photos objectAtIndex:indexPath.item] caption]];
    });
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
        }
        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:index inSection:0];
        NSLog(@"index path  %@",indexPath);
        MWGridCell *cell = (MWGridCell*)[self.collectionView cellForItemAtIndexPath:indexPath];
        if(cell != NULL){
            [cell setHighlighted:YES];
            self.prevSelectItem = cell;
            
            [_textfield setText:[[self.photos objectAtIndex:index] caption]];
             dispatch_async (dispatch_get_main_queue (), ^{
                 [self.collectionView layoutIfNeeded];
                 [self.collectionView scrollToItemAtIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:YES];
             });
        }
        
    }
}
- (NSUInteger)numberOfPhotosInPhotoBrowser:(MWPhotoBrowser *)photoBrowser {
    return [self.photos count];
}

- (id <MWPhoto>)photoBrowser:(MWPhotoBrowser *)photoBrowser photoAtIndex:(NSUInteger)index {
    return [self.photos objectAtIndex:index];
}

- (MWCaptionView *)photoBrowser:(MWPhotoBrowser *)photoBrowser captionViewForPhotoAtIndex:(NSUInteger)index{
//    MWPhoto *photo = [self.photos objectAtIndex:index];
//    MWCaptionView *captionView = [[MWCaptionView alloc] initWithPhoto:photo];
//    return captionView;
    return nil;
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

@end
