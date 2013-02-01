//
//  GenreService.h
//  Libros
//
//  Created by Sean Hess on 2/1/13.
//  Copyright (c) 2013 Sean Hess. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GenreService : NSObject

+(GenreService*)shared;
-(void)load;

-(NSFetchRequest*)allGenres;
-(NSFetchRequest*)booksByGenre:(NSString*)genre;

@end
