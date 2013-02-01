//
//  BookService.h
//  Libros
//
//  Created by Sean Hess on 1/10/13.
//  Copyright (c) 2013 Sean Hess. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BookService : NSObject

+(BookService*)shared;
-(void)loadStore;
-(NSFetchRequest*)popular;

@end
