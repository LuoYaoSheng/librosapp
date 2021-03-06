//
//  LibraryBookCell.m
//  Libros
//
//  Created by Sean Hess on 2/11/13.
//  Copyright (c) 2013 Sean Hess. All rights reserved.
//

#define HORIZONTAL_ICON_SPACE 8
#define BUTTON_ICON_PADDING 12
#import "LibraryBookCell.h"
#import "Icons.h"
#import "ColoredButton.h"
#import "UIView+Nibs.h"

@interface LibraryBookCell ()
@property (nonatomic, strong) ColoredButton * audioButton;
@property (nonatomic, strong) ColoredButton * textButton;
@property (nonatomic, strong) UIView * buttonsView;
@property (nonatomic, strong) UIView * overlayView;
@property (nonatomic, strong) UILabel * overlayLabel;

@property (nonatomic) CGRect audioFrame;
@property (nonatomic) CGRect textFrame;
@end

@implementation LibraryBookCell


- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:reuseIdentifier];
    if (self) {
        
        UIImage * textIcon = Icons.text;
        self.textButton = [ColoredButton new];
        self.textButton.style = ColoredButtonStyleGray;
        [self.textButton addTarget:self action:@selector(tapButton:) forControlEvents:UIControlEventTouchUpInside];
        [self.textButton setImage:textIcon forState:UIControlStateNormal];
        
        UIImage * audioIcon = Icons.audio;
        self.audioButton = [ColoredButton new];
        self.audioButton.style = ColoredButtonStyleGray;
        [self.audioButton addTarget:self action:@selector(tapButton:) forControlEvents:UIControlEventTouchUpInside];
        [self.audioButton setImage:audioIcon forState:UIControlStateNormal];
        
        self.audioFrame = CGRectMake(0, 0, audioIcon.size.width + BUTTON_ICON_PADDING, audioIcon.size.height + BUTTON_ICON_PADDING);
        self.textFrame = CGRectMake(0, 0, textIcon.size.width + BUTTON_ICON_PADDING, textIcon.size.height-1 + BUTTON_ICON_PADDING);
        
        self.buttonsView = [UIView new];
        [self.buttonsView addSubview:self.textButton];
        [self.buttonsView addSubview:self.audioButton];
        self.accessoryView = self.buttonsView;
        
        self.overlayView = [UIView loadFromNibNamed:@"LibraryBookCellOverlay"];
        self.overlayView.frame = self.bounds;
        self.overlayView.hidden = YES;
        [self addSubview:self.overlayView];
    }
    return self;
}

- (void)setBook:(Book *)book {
    _book = book;
    
    self.textLabel.text = book.title;
    self.detailTextLabel.text = book.author;
    self.accessoryView = [self addTypeIcons:book];
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
    [super setEditing:editing animated:animated];
    self.overlayView.hidden = !editing;
    
    if (editing)
        self.accessoryView = nil;
    else
        self.accessoryView = self.buttonsView;
}

- (UIView*)addTypeIcons:(Book*)book {
    if (book.audioFiles && book.textFiles) {
        self.textButton.hidden = NO;
        self.audioButton.hidden = NO;
        
        CGRect audioFrame = self.audioFrame;
        audioFrame.origin.y = roundf((self.textFrame.size.height - audioFrame.size.height)/2);
        
        CGRect textFrame = self.textFrame;
        textFrame.origin.x = audioFrame.size.width + HORIZONTAL_ICON_SPACE;
        
        self.textButton.frame = textFrame;
        self.audioButton.frame = audioFrame;
        self.accessoryView.frame = CGRectMake(0, 0, textFrame.origin.x + textFrame.size.width, MAX(textFrame.size.height, audioFrame.size.height));
    }
    
    else if (book.audioFiles) {
        self.audioButton.frame = self.audioFrame;
        self.accessoryView.frame = self.audioFrame;
        self.textButton.hidden = YES;
        self.audioButton.hidden = NO;
    }
    
    else {
        self.textButton.frame = self.textFrame;
        self.accessoryView.frame = self.textFrame;
        self.textButton.hidden = NO;
        self.audioButton.hidden = YES;
    }
    
    return self.accessoryView;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
}
@end
