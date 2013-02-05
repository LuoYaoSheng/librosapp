//
//  StoreDetailsVC.m
//  Libros
//
//  Created by Sean Hess on 1/30/13.
//  Copyright (c) 2013 Sean Hess. All rights reserved.
//

#import "StoreDetailsVC.h"
#import "ColoredButton.h"
#import "HorizontalFlowView.h"
#import "Icons.h"
#import "UserService.h"
#import "FileService.h"
#import "MBProgressHUD.h"

@interface StoreDetailsVC ()

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *authorLabel;
@property (weak, nonatomic) IBOutlet ColoredButton *buyButton;
@property (weak, nonatomic) IBOutlet UITextView *descriptionTextView;
@property (weak, nonatomic) IBOutlet UILabel *formatsLabel;
@property (weak, nonatomic) IBOutlet HorizontalFlowView *iconsView;
@property (weak, nonatomic) IBOutlet UIImageView *audioIcon;
@property (weak, nonatomic) IBOutlet UIImageView *textIcon;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;

@property (strong, nonatomic) MBProgressHUD * hud;

@end

@implementation StoreDetailsVC

- (void)viewWillAppear:(BOOL)animated {
    [self.navigationController setNavigationBarHidden:NO animated:YES];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // any initialization of nib things needs to happen in here, not in initWithNibName! might not be there.
    self.iconsView.padding = 5;
    
    // We need to load the files for the book
    [[FileService shared] loadFilesForBook:self.book.bookId cb:^{}];
    
    self.titleLabel.text = self.book.title;
    self.authorLabel.text = [NSString stringWithFormat:@"%@", self.book.author];
    self.descriptionTextView.text = self.book.descriptionText;
    [self resizeContent];
    [self renderButtonAndDownload];
    
    [self.book addObserver:self forKeyPath:BookAttributes.downloaded options:NSKeyValueObservingOptionNew context:nil];
    [self.book addObserver:self forKeyPath:BookAttributes.purchased options:NSKeyValueObservingOptionNew context:nil];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:BookAttributes.downloaded]) {
        self.hud.progress = self.book.downloadedValue;
        [self renderButtonAndDownload];
    }
    
    else if ([keyPath isEqualToString:BookAttributes.purchased]) {
        [self renderButtonAndDownload];
    }
}

- (void)renderButtonAndDownload {
    self.buyButton.enabled = YES;
    
    if (!self.book.purchasedValue) {
        self.buyButton.style = ColoredButtonStyleGreen;
        NSString * buttonLabel = [NSString stringWithFormat:@"Buy for $%@", self.book.priceString];
        [self.buyButton setTitle:buttonLabel forState:UIControlStateNormal];
    }
    
    else {
        self.buyButton.style = ColoredButtonStyleGray;
        
        // well, I should use a total bytes thing so it actually updates
        if (self.book.downloadedValue < 1.0) {
            [self.buyButton setTitle:@"Downloading" forState:UIControlStateNormal];
            self.buyButton.enabled = NO;
            
            // only if it hasn't been displayed yet!
            if (!self.hud) {
                self.hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
                self.hud.mode = MBProgressHUDModeDeterminate;
                self.hud.labelText = @"Downloading Book";
                self.hud.progress = self.book.downloadedValue;
            }
        }
        
        else {
            [self.buyButton setTitle:@"View in Library" forState:UIControlStateNormal];
            [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
            self.hud = nil;
        }
    }
}

-(void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    [self resizeContent];
}

-(void)resizeContent {
    CGRect descriptionFrame = self.descriptionTextView.frame;
    descriptionFrame.size.height = self.descriptionTextView.contentSize.height;
    self.descriptionTextView.frame = descriptionFrame;
    
    self.scrollView.contentSize = CGSizeMake(self.view.bounds.size.width, self.descriptionTextView.frame.origin.y + self.descriptionTextView.frame.size.height);
}

-(void)viewDidLayoutSubviews {
    [self setFormats];
}

- (void)setFormats {
    if (self.book.audioFilesValue && self.book.textFilesValue) {
        self.textIcon.hidden = NO;
        self.audioIcon.hidden = NO;
        self.formatsLabel.text = @"Text and Audio";
    }
    
    else if (self.book.audioFilesValue) {
        self.textIcon.hidden = YES;
        self.audioIcon.hidden = NO;
        self.formatsLabel.text = @"Audiobook";
    }
    
    else {
        self.textIcon.hidden = NO;
        self.audioIcon.hidden = YES;
        self.formatsLabel.text = @"Text";
    }
    
    [self.iconsView flow];
    
    CGRect formatsLabelFrame = self.formatsLabel.frame;
    formatsLabelFrame.origin.x = self.iconsView.frame.origin.x + self.iconsView.frame.size.width + 5;
    self.formatsLabel.frame = formatsLabelFrame;
}

// is there any way to reattach to it?
// not really. I need to data bind instead of attaching here
- (IBAction)didTapBuy:(id)sender {
    
    if (self.book.purchased) {
        // TODO, view in library
        return;
    }
    
    [UserService.shared addBook:self.book];
    [self renderButtonAndDownload];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

-(void)dealloc {
    [self.book removeObserver:self forKeyPath:BookAttributes.downloaded];
    [self.book removeObserver:self forKeyPath:BookAttributes.purchased];
}

@end
