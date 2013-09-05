//
//  StoreSearchVCViewController.m
//  Libros
//
//  Created by Sean Hess on 2/1/13.
//  Copyright (c) 2013 Sean Hess. All rights reserved.
//

#import "StoreSearchVC.h"
#import "Book.h"
#import "Author.h"
#import "StoreBookCell.h"
#import "StoreBookResultsVC.h"
#import "AuthorService.h"
#import "BookService.h"
#import "StoreDetailsVC.h"
#import "ObjectStore.h"
#import "MetricsService.h"
#import "Appearance.h"

#define DEFAULT_TABLE_CELL_HEIGHT 44

@interface StoreSearchVC () <UIScrollViewDelegate>
@property (weak, nonatomic) IBOutlet UISearchBar * searchBar;
@property (weak, nonatomic) IBOutlet UITableView * tableView;

@property (strong, nonatomic) NSFetchedResultsController * authorResults;
@property (strong, nonatomic) NSFetchedResultsController * bookResults;

@end

@implementation StoreSearchVC

- (id)init {
    self = [super init];
    if (self) {
        [self initialize];
    }
    return self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        [self initialize];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self initialize];
    }
    return self;
}

- (void)initialize {
    self.title = NSLocalizedString(@"Search",nil);
    [self.tabBarItem setFinishedSelectedImage:[UIImage imageNamed:@"tabbar-icon-search-selected"] withFinishedUnselectedImage:[UIImage imageNamed:@"tabbar-icon-search"]];
}

- (void)viewWillAppear:(BOOL)animated {
    [self.navigationController setNavigationBarHidden:YES animated:YES];
    [MetricsService storeSearchLoad];
    NSIndexPath * selectedRow = [self.tableView indexPathForSelectedRow];
    if (selectedRow)
        [self.tableView deselectRowAtIndexPath:selectedRow animated:YES];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.tableView.backgroundColor = Appearance.background;
    
    [self.searchBar becomeFirstResponder];
    
    self.authorResults = [[NSFetchedResultsController alloc] initWithFetchRequest:AuthorService.shared.allAuthors managedObjectContext:ObjectStore.shared.context sectionNameKeyPath:nil cacheName:nil];
    self.bookResults = [[NSFetchedResultsController alloc] initWithFetchRequest:BookService.shared.allBooks managedObjectContext:ObjectStore.shared.context sectionNameKeyPath:nil cacheName:nil];
}

- (void)didReceiveMemoryWarning
{
}

- (void)performSearch:(NSString*)searchText {
    NSError * error = nil;
    self.authorResults.fetchRequest.predicate = [AuthorService.shared searchForText:searchText];
    self.bookResults.fetchRequest.predicate = [BookService.shared searchForText:searchText];
    [self.authorResults performFetch:&error];
    [self.bookResults performFetch:&error];
    [self.tableView reloadData];
}

-(NSFetchedResultsController*)resultsForSection:(NSInteger)section {
    return (section == 0) ? self.authorResults : self.bookResults;
}


#pragma UITableViewDelegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if ([self resultsForSection:section] == self.authorResults) return NSLocalizedString(@"Authors",nil);
    return NSLocalizedString(@"Books",nil);
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    id<NSFetchedResultsSectionInfo> sectionInfo = [[self resultsForSection:section].sections objectAtIndex:0];
    return [sectionInfo numberOfObjects];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSIndexPath * innerIndexPath = [NSIndexPath indexPathForRow:indexPath.row inSection:0];
    
    if ([self resultsForSection:indexPath.section] == self.authorResults) {
        return [self tableView:tableView cellForAuthorAtIndexPath:innerIndexPath];
    }
    
    else {
        return [self tableView:tableView cellForBookAtIndexPath:innerIndexPath];
    }
}

-(UITableViewCell *)tableView:(UITableView*)tableView cellForAuthorAtIndexPath:(NSIndexPath*)indexPath {
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = (UITableViewCell*)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        cell.selectedBackgroundView = Appearance.tableSelectedBackgroundView;
    }
    
    Author * author = [self.authorResults objectAtIndexPath:indexPath];
    cell.textLabel.text = author.name;
    return cell;
}

-(UITableViewCell *)tableView:(UITableView*)tableView cellForBookAtIndexPath:(NSIndexPath*)indexPath {
    static NSString *CellIdentifier = @"StoreBookCell";
    StoreBookCell *cell = (StoreBookCell*)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[StoreBookCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    Book * book = [self.bookResults objectAtIndexPath:indexPath];
    cell.book = book;
    return cell;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) return DEFAULT_TABLE_CELL_HEIGHT;
    else return STORE_BOOK_CELL_HEIGHT;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSFetchedResultsController * fetchedResults = [self resultsForSection:indexPath.section];
    NSIndexPath * innerIndexPath = [NSIndexPath indexPathForRow:indexPath.row inSection:0];
    
    if (fetchedResults == self.authorResults) {
        Author * author = [fetchedResults objectAtIndexPath:innerIndexPath];
        StoreBookResultsVC * results = [StoreBookResultsVC new];
        results.fetchRequest = [[AuthorService shared] booksByAuthor:author.name];
        results.title = author.name;
        [self.navigationController pushViewController:results animated:YES];
    }
    
    else {
        Book * book = [fetchedResults objectAtIndexPath:innerIndexPath];
        StoreDetailsVC * details = [StoreDetailsVC new];
        details.book = book;
        [self.navigationController pushViewController:details animated:YES];
    }
}


#pragma mark - UIScrollViewDelegate

-(void)scrollViewDidScroll:(UIScrollView *)scrollView {
    [self.searchBar resignFirstResponder];
    [self enableCancelButton];
}

#pragma UISearchBarDelegate

- (void)enableCancelButton {
    for (UIView *possibleButton in self.searchBar.subviews)
    {
        if ([possibleButton isKindOfClass:[UIButton class]])
        {
            ((UIButton*)possibleButton).enabled = YES;
            break;
        }
    }
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    // if the search has at least 2 letters!
    if (searchText.length >= 2)
        [self performSearch:searchBar.text];
    else [self performSearch:@""];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    [searchBar resignFirstResponder];
    [self performSearch:searchBar.text];
    [self enableCancelButton];
}


- (void)searchBarCancelButtonClicked:(UISearchBar *) searchBar {
    [searchBar resignFirstResponder];
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

//- (BOOL)searchBarShouldBeginEditing:(UISearchBar *)searchBar {}
//- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {}
//- (BOOL)searchBarShouldEndEditing:(UISearchBar *)searchBar {}
//- (BOOL)searchBar:(UISearchBar *)searchBar shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {}
//
//- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {}
//- (void)searchBarBookmarkButtonClicked:(UISearchBar *)searchBar {}
//- (void)searchBarResultsListButtonClicked:(UISearchBar *)searchBar {}
//
//- (void)searchBar:(UISearchBar *)searchBar selectedScopeButtonIndexDidChange:(NSInteger)selectedScope {};

@end
