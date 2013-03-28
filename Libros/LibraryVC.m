//
//  LibraryVC.m
//  Libros
//
//  Created by Sean Hess on 1/10/13.
//  Copyright (c) 2013 Sean Hess. All rights reserved.
//

#import "LibraryVC.h"
#import "BookService.h"
#import "FileService.h"
#import "UserService.h"
#import "Book.h"
#import "ObjectStore.h"
#import "ReaderVC.h"
#import "StoreBookCell.h"
#import "LibraryBookCoverCell.h"
#import "MetricsService.h"
#import "Appearance.h"
#import "LibraryOpenAnimationView.h"
#import <QuartzCore/QuartzCore.h>
#import "StoreDetailsVC.h"

@interface LibraryVC () <NSFetchedResultsControllerDelegate, UIActionSheetDelegate, UITableViewDelegate, UITableViewDataSource, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout>

@property (nonatomic, strong) NSFetchedResultsController * fetchedResultsController;
@property (nonatomic, strong) Book * selectedBook;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (strong, nonatomic) UIButton *layoutButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *storeButton;
@end

// Image Size: 178 x 270

@implementation LibraryVC

- (void)viewDidLoad
{
    NSLog(@"LIBRARY");
    [super viewDidLoad];
    
    self.title = NSLocalizedString(@"Library", nil);
    self.storeButton.title = NSLocalizedString(@"Store",nil);
    
    self.tableView.backgroundColor = Appearance.background;
    self.collectionView.backgroundColor = Appearance.background;
    
    self.layoutButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.layoutButton.frame = CGRectMake(0, 0, 37, 17); // move it over a little (17x17 normally)
    [self.layoutButton addTarget:self action:@selector(didTapLayoutButton:) forControlEvents:UIControlEventTouchUpInside];
    [self.layoutButton setImage:[UIImage imageNamed:@"navbar-rows-icon.png"] forState:UIControlStateNormal];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:self.layoutButton];
    
    self.wantsFullScreenLayout = NO;
    self.navigationController.navigationBar.barStyle = UIBarStyleBlackOpaque;
    [self.navigationController setNavigationBarHidden:NO animated:NO];
    
    [self.collectionView registerClass:[LibraryBookCoverCell class] forCellWithReuseIdentifier:@"LibraryBookCover"];
    
    self.fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:UserService.shared.libraryBooks managedObjectContext:ObjectStore.shared.context sectionNameKeyPath:nil cacheName:nil];
    [self.fetchedResultsController setDelegate:self];
   
    NSError *error = nil;
    [self.fetchedResultsController performFetch:&error];
    // check for download when the CELL is loaded. Is on screen?
    [self.tableView reloadData];
    [self.collectionView reloadData];
}

- (void)viewWillAppear:(BOOL)animated {
    [MetricsService libraryLoad];
    self.wantsFullScreenLayout = NO;
    self.navigationController.navigationBar.barStyle = UIBarStyleBlackOpaque;
    [self.navigationController setNavigationBarHidden:NO animated:NO];
    NSIndexPath * selectedRow = [self.tableView indexPathForSelectedRow];
    if (selectedRow)
        [self.tableView deselectRowAtIndexPath:selectedRow animated:YES];
}

- (void)viewDidAppear:(BOOL)animated {
    if (self.loadBook) {
        NSIndexPath * indexPath = [self.fetchedResultsController indexPathForObject:self.loadBook];
        [self.tableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionNone];
        self.loadBook = nil;
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark NSFetchedResultsControllerDelegate methods

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    NSLog(@"LIBRARY change content");
    [self.tableView reloadData];
    [self.collectionView reloadData];
}

- (IBAction)didTapLayoutButton:(id)sender {
    // hide the table and show the collection view!
    if (self.collectionView.hidden) {
        self.collectionView.hidden = NO;
        self.tableView.hidden = YES;
        [self.layoutButton setImage:[UIImage imageNamed:@"navbar-rows-icon.png"] forState:UIControlStateNormal];
        [MetricsService libraryListLayout];
    }
    else {
        self.collectionView.hidden = YES;
        self.tableView.hidden = NO;
        [self.layoutButton setImage:[UIImage imageNamed:@"navbar-grid-icon.png"] forState:UIControlStateNormal];
        [MetricsService libraryGridLayout];
    }
}


-(NSInteger)numberOfBooksInSection:(NSInteger)section {
    id<NSFetchedResultsSectionInfo> sectionInfo = [self.fetchedResultsController.sections objectAtIndex:section];
    return [sectionInfo numberOfObjects];
}



#pragma mark - Table view data source

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return STORE_BOOK_CELL_HEIGHT;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self numberOfBooksInSection:section];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"StoreBookCell";
    StoreBookCell *cell = (StoreBookCell*)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[StoreBookCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    Book * book = [self.fetchedResultsController objectAtIndexPath:indexPath];
    cell.book = book;
    [UserService.shared checkRestartDownload:book];
    return cell;
}

-(BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    Book * book = [self.fetchedResultsController objectAtIndexPath:indexPath];
    return (book.isDownloadComplete);
}

-(void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    Book * book = [self.fetchedResultsController objectAtIndexPath:indexPath];
    [UserService.shared archiveBook:book];
    
    // Need to delete local files, otherwise, what is the point?
    
    [self.fetchedResultsController performFetch:nil];
    [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    [self.collectionView reloadData];
}

-(NSString*)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath {
    return NSLocalizedString(@"Archive",nil);
}


#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    Book * book = [self.fetchedResultsController objectAtIndexPath:indexPath];
    
    if (book.isDownloading)
        return [self showDetails:book];
    
    ReaderVC * readervc = [ReaderVC new];
    readervc.book = book;
    [self.navigationController pushViewController:readervc animated:YES];
}

#pragma mark - UICollectionViewDelegate
#pragma mark UICollectionViewDelegate

-(NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

// this gets called DURING first initialization
-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return [self numberOfBooksInSection:section];
}

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    // sizes correct at this point
    static NSString * cellId = @"LibraryBookCover";
    LibraryBookCoverCell * cell = (LibraryBookCoverCell*)[self.collectionView dequeueReusableCellWithReuseIdentifier:cellId forIndexPath:indexPath];
    Book * book = [self.fetchedResultsController objectAtIndexPath:indexPath];
    cell.book = book;
    [UserService.shared checkRestartDownload:book];
    return cell;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return CGSizeMake(106, 152);
}

// This is the SECTION inset. not the cell inset. OHHHH
- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section{
//    return UIEdgeInsetsMake(11, 11, 11, 11);
    return UIEdgeInsetsMake(8,0,0,0);
}

- (CGFloat) collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section {
//    return 11;
    return 0;
}

- (CGFloat) collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section {
//    return 11;
    return 0;
}

// This guy owns its own view

- (void) collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    Book * book = [self.fetchedResultsController objectAtIndexPath:indexPath];
    
    if (book.isDownloading)
        return [self showDetails:book];
    
    LibraryBookCoverCell * cell = (LibraryBookCoverCell*) [collectionView cellForItemAtIndexPath:indexPath];
    UIImage * image = [UIImage imageWithCGImage:cell.cachedImage.CGImage];
    CGRect frame = cell.cachedImageFrame;
    frame.origin.x += cell.frame.origin.x;
    frame.origin.y += cell.frame.origin.y;
    LibraryOpenAnimationView * view = [[LibraryOpenAnimationView alloc] initWithImage:image frame:frame];
    [self.view addSubview:view];
    
    [self.navigationController setNavigationBarHidden:YES animated:YES];
    
    // Now, animate it BIGGGGG
    [UIView animateWithDuration:0.3 animations:^{
        view.frame = self.view.frame;
    } completion:^(BOOL finished) {
        ReaderVC * readervc = [ReaderVC new];
        readervc.book = book;
        
        CATransition * transition = [CATransition animation];
        transition.duration = 0.3;
        transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionDefault];
        transition.type = kCATransitionFade;
        [self.navigationController.view.layer addAnimation:transition forKey:nil];
        [self.navigationController pushViewController:readervc animated:NO];
        
        [view removeFromSuperview];
    }];
}

- (void)showDetails:(Book*)book {
    StoreDetailsVC * details = [StoreDetailsVC new];
    details.book = book;
    [self.navigationController pushViewController:details animated:YES];
}

@end
