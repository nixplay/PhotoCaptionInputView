//
//  PhotoCaptionInputViewController.h
//  Pods
//
//  Created by James Kong on 12/4/2017.
//
//

#import <UIKit/UIKit.h>
#import <MWPhotoBrowser/MWPhotoBrowser.h>
@interface PhotoCaptionInputViewController : UIViewController <MWPhotoBrowserDelegate , UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout>


@property (nonatomic, strong) NSMutableArray *photos;
@property (nonatomic, strong) NSMutableArray *thumbs;
@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) UIButton *addButton;
@end
