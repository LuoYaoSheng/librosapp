//
//  BookService.h
//  Libros
//
//  Created by Sean Hess on 1/10/13.
//  Copyright (c) 2013 Sean Hess. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Book.h"

@interface BookService : NSObject

+(BookService*)shared;
-(void)loadStore;
-(void)loadStoreWithCb:(void(^)(void))cb;

-(NSFetchRequest*)allBooks;
-(NSFetchRequest*)popular;
-(NSPredicate*)searchForText:(NSString*)text;

-(NSPredicate*)filterByType:(BookFilter)filter;

//-(NSString*)priceString:(Book*)book;
-(void)sendBookPurchased:(Book*)book;

-(NSArray*)firstRunBooks;

@end
