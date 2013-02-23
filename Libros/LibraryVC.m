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
#import "LibraryBookCell.h"
#import "LibraryBookCoverCell.h"

@interface LibraryVC () <NSFetchedResultsControllerDelegate, LibraryBookCellDelegate, UIActionSheetDelegate, UITableViewDelegate, UITableViewDataSource, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout>

@property (nonatomic, strong) NSFetchedResultsController * fetchedResultsController;
@property (nonatomic, strong) Book * selectedBook;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@end



@implementation LibraryVC

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.collectionView registerClass:[LibraryBookCoverCell class] forCellWithReuseIdentifier:@"LibraryBookCover"];
    
    self.fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:UserService.shared.libraryBooks managedObjectContext:ObjectStore.shared.context sectionNameKeyPath:nil cacheName:nil];
    [self.fetchedResultsController setDelegate:self];
   
    NSError *error = nil;
    [self.fetchedResultsController performFetch:&error];
    [self.tableView reloadData];
    [self.collectionView reloadData];
}

- (void)viewWillAppear:(BOOL)animated {
    [self.navigationController setNavigationBarHidden:NO animated:animated];
}

- (void)viewDidAppear:(BOOL)animated {
    if (self.loadBook) {
        NSIndexPath * indexPath = [self.fetchedResultsController indexPathForObject:self.loadBook];
        [self.tableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionNone];
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
    [self.tableView reloadData];
}

- (IBAction)didTapLayoutButton:(id)sender {
    // hide the table and show the collection view!
}


-(NSInteger)numberOfBooksInSection:(NSInteger)section {
    id<NSFetchedResultsSectionInfo> sectionInfo = [self.fetchedResultsController.sections objectAtIndex:section];
    return [sectionInfo numberOfObjects];
}



#pragma mark - Table view data source

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
    static NSString *CellIdentifier = @"LibraryBookCell";
    LibraryBookCell *cell = (LibraryBookCell*)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[LibraryBookCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    Book * book = [self.fetchedResultsController objectAtIndexPath:indexPath];
    cell.delegate = self;
    cell.book = book;
    return cell;
}

-(BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

-(void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    Book * book = [self.fetchedResultsController objectAtIndexPath:indexPath];
    [UserService.shared archiveBook:book];
    
    // Need to delete local files, otherwise, what is the point?
    
    [self.fetchedResultsController performFetch:nil];
    [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
}

-(NSString*)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath {
    return @"Archive";
}


#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    Book * book = [self.fetchedResultsController objectAtIndexPath:indexPath];
    
    if (book.audioFilesValue && book.textFilesValue) {
        if (book.preferredFormatValue) {
            if (book.preferredFormatValue == BookFormatAudio)
                [self showPlayer:book];
            else
                [self showReader:book];
        }
        else {
            [self promptForFormat:book];
        }
    }
    
    else if (book.audioFilesValue) {
        [self showPlayer:book];
    }
    
    else {
        [self showReader:book];
    }
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
    NSLog(@"WAHOO %@", indexPath);
    static NSString * cellId = @"LibraryBookCover";
    UICollectionViewCell * cell = [self.collectionView dequeueReusableCellWithReuseIdentifier:cellId forIndexPath:indexPath];
    // TODO add image view and WORK IT
    cell.backgroundColor = [UIColor redColor];
    return cell;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return CGSizeMake(96, 140);
}

// This is the SECTION inset. not the cell inset. OHHHH
- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section{
    return UIEdgeInsetsMake(8, 8, 8, 8);
}

- (CGFloat) collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section {
    return 8;
}

- (CGFloat) collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section {
    return 8;
}





- (void)promptForFormat:(Book*)book {
    self.selectedBook = book;
    UIActionSheet * actionSheet = [UIActionSheet new];
    actionSheet.actionSheetStyle = UIActionSheetStyleBlackTranslucent;
    actionSheet.delegate = self;
    [actionSheet setTitle:@"Which format?"];
    [actionSheet addButtonWithTitle:@"Texto"];
    [actionSheet addButtonWithTitle:@"Audio"];
    [actionSheet showInView:self.view];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 0) {
        [self showReader:self.selectedBook];
    }
    else {
        [self showPlayer:self.selectedBook];
    }
}

- (void)showReader:(Book*)book {
    [self setBook:book preferredFormat:BookFormatText];
    ReaderVC * readervc = [ReaderVC new];
    readervc.book = book;
    [self.navigationController pushViewController:readervc animated:YES];
}

- (void)showPlayer:(Book*)book {
    NSLog(@"AUDIO PLAYER");
    [self setBook:book preferredFormat:BookFormatAudio];
    book.preferredFormatValue = BookFormatAudio;
}

- (void)setBook:(Book*)book preferredFormat:(NSInteger)format {
    book.preferredFormatValue = format;
    [self.tableView reloadData];
}

- (void)didTapText:(Book *)book {
    [self showReader:book];
}

- (void)didTapAudio:(Book *)book {
    [self showPlayer:book];
}

//-(void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex {}

@end
