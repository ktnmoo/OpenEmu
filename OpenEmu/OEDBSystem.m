/*
 Copyright (c) 2011, OpenEmu Team
 
 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions are met:
     * Redistributions of source code must retain the above copyright
       notice, this list of conditions and the following disclaimer.
     * Redistributions in binary form must reproduce the above copyright
       notice, this list of conditions and the following disclaimer in the
       documentation and/or other materials provided with the distribution.
     * Neither the name of the OpenEmu Team nor the
       names of its contributors may be used to endorse or promote products
       derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY OpenEmu Team ''AS IS'' AND ANY
 EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 DISCLAIMED. IN NO EVENT SHALL OpenEmu Team BE LIABLE FOR ANY
 DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
  LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "OEDBSystem.h"
#import "OESystemPlugin.h"
#import "OESystemController.h"
#import "OELibraryDatabase.h"

NSString * const OEDBSystemsChangedNotificationName = @"OEDBSystemsChanged";
@implementation OEDBSystem

+ (id)systemFromPlugin:(OESystemPlugin *)plugin inDatabase:(OELibraryDatabase *)database
{
    NSString *systemIdentifier = [plugin systemIdentifier];
    OEDBSystem *system = [database systemWithIdentifier:systemIdentifier];
    
    if(system) return system;
    
    NSManagedObjectContext *moc = [database managedObjectContext];
    
    system = [[OEDBSystem alloc] initWithEntity:[self entityDescriptionInContext:moc] insertIntoManagedObjectContext:moc];
    // TODO: get archive id(s) from plugin
    [system setSystemIdentifier:systemIdentifier];
    [system setLastLocalizedName:[system name]];
    
    return system;
}

+ (id)systemForPluginIdentifier:(NSString *)identifier inDatabase:(OELibraryDatabase *)database
{
    return [database systemWithIdentifier:identifier];
}

+ (id)systemForArchiveID:(NSNumber *)archiveID
{
    return [self systemForArchiveID:archiveID inDatabase:[OELibraryDatabase defaultDatabase]];
}

+ (id)systemForArchiveID:(NSNumber *)archiveID inDatabase:(OELibraryDatabase *)database
{
    return [database systemWithArchiveID:archiveID];
}

+ (id)systemForArchiveName:(NSString *)name
{
    return [self systemForArchiveName:name inDatabase:[OELibraryDatabase defaultDatabase]];
}

+ (id)systemForArchiveName:(NSString *)name inDatabase:(OELibraryDatabase *)database
{
    return [database systemWithArchiveName:name];
}

+ (id)systemForArchiveShortName:(NSString *)shortName
{
    return [self systemForArchiveShortName:shortName inDatabase:[OELibraryDatabase defaultDatabase]];
}

+ (id)systemForArchiveShortName:(NSString *)shortName inDatabase:(OELibraryDatabase *)database
{
    return [database systemWithArchiveShortname:shortName];
}

+ (id)systemForURL:(NSURL *)url DEPRECATED_ATTRIBUTE
{
    return [self systemForURL:url inDatabase:[OELibraryDatabase defaultDatabase]];
}

+ (id)systemForURL:(NSURL *)url inDatabase:(OELibraryDatabase *)database DEPRECATED_ATTRIBUTE
{
    return [database systemForHandlingRomAtURL:url];
}

+ (NSArray*)systemsForFileWithURL:(NSURL *)url
{
    return [self systemsForFileWithURL:url error:nil];
}
+ (NSArray*)systemsForFileWithURL:(NSURL *)url error:(NSError**)error
{
    return [self systemsForFileWithURL:url inDatabase:[OELibraryDatabase defaultDatabase] error:error];
}
+ (NSArray*)systemsForFileWithURL:(NSURL *)url inDatabase:(OELibraryDatabase *)database
{
    return [self systemsForFileWithURL:url inDatabase:[OELibraryDatabase defaultDatabase] error:nil];
}
+ (NSArray*)systemsForFileWithURL:(NSURL *)url inDatabase:(OELibraryDatabase *)database error:(NSError**)error
{
    NSString *path = [url absoluteString];
    NSArray *validPlugins = [[OESystemPlugin allPlugins] filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(OESystemPlugin * evaluatedObject, NSDictionary *bindings) {
        return [[evaluatedObject controller] canHandleFile:path];
    }]];
    
    NSMutableArray *validSystems = [NSMutableArray arrayWithCapacity:[validPlugins count]];
    [validPlugins enumerateObjectsUsingBlock:^(OESystemPlugin *obj, NSUInteger idx, BOOL *stop) {
        NSString *systemIdentifier = [obj systemIdentifier];
        OEDBSystem *system = [database systemWithIdentifier:systemIdentifier];
            [validSystems addObject:system];
    }];

    return validSystems;
}
#pragma mark -
#pragma mark Core Data utilities

+ (NSString *)entityName
{
    return @"System";
}

+ (NSEntityDescription *)entityDescriptionInContext:(NSManagedObjectContext *)context
{
    return [NSEntityDescription entityForName:[self entityName] inManagedObjectContext:context];
}

#pragma mark -
#pragma mark Data Model Properties
@dynamic lastLocalizedName, shortname, systemIdentifier, archiveID, archiveName, archiveShortname, enabled;

#pragma mark -
#pragma mark Data Model Relationships
@dynamic games;
- (NSMutableSet*)mutableGames
{
    return [self mutableSetValueForKey:@"games"];
}

#pragma mark -

- (OESystemPlugin *)plugin
{
    NSString *systemIdentifier = [self systemIdentifier];
    OESystemPlugin *plugin = [OESystemPlugin gameSystemPluginForIdentifier:systemIdentifier];
    
    return plugin;
}

- (NSImage *)icon
{
    return [[self plugin] systemIcon];
}

- (NSString *)name
{
    return [[self plugin] systemName] ? : [self lastLocalizedName];
}

@end
