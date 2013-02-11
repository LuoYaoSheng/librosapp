//
//  FileService.h
//  Libros
//
//  Created by Sean Hess on 1/18/13.
//  Copyright (c) 2013 Sean Hess. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "File.h"

#define FileFormatText @"html"
#define FileFormatAudio @"mp3"

@interface FileService : NSObject

+(FileService*)shared;

-(void)loadFilesForBook:(NSString*)bookId cb:(void(^)(void))cb;
-(void)downloadFiles:(NSArray*)files progress:(void(^)(float))cb complete:(void(^)(void))cb;

-(NSArray*)byBookId:(NSString*)bookId;

-(NSURL*)url:(File*)file;
-(NSString*)localPath:(File*)file;
-(NSString*)readAsText:(File*)file;

-(NSArray*)filterFiles:(NSArray*)array byFormat:(NSString*)format;

-(void)removeFiles:(NSArray*)files;

@end
