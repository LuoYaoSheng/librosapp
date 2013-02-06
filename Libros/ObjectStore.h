//
//  ObjectStore.h
//  Libros
//
//  Created by Sean Hess on 1/11/13.
//  Copyright (c) 2013 Sean Hess. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <RestKit/RestKit.h>
#import "User.h"

@interface ObjectStore : NSObject

@property (strong, nonatomic) RKObjectManager* objectManager;
@property (strong, nonatomic) RKManagedObjectStore * objectStore;
@property (readonly, nonatomic) NSManagedObjectContext * context;

// use [UserService main] instead of calling this
@property (strong, nonatomic) User* mainUser;

+ (ObjectStore*)shared;
- (void)saveContext;

- (RKEntityMapping*)mappingForEntityForName:(NSString*)entityName;
- (void)addResponseDescriptor:(RKResponseDescriptor*)descriptor;

// Simple way to sync objects whose urls have no parameters
// Will delete anything not matched
- (void)syncWithFetchRequest:(NSFetchRequest*)request forPath:(NSString*)path;

@end
