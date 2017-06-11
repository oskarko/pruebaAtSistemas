//
//  MainTableViewController.m
//  atSistemasLectorRSS
//
//  Created by Oscar Rodriguez Garrucho on 9/6/17.
//  Copyright © 2017 Oscar Rodriguez Garrucho. All rights reserved.
//

#import "MainTableViewController.h"
#import "RSSNewsCustomCell.h"
#import "AppDelegate.h"
#import "DetailsViewController.h"
#import "News+CoreDataClass.h"


@interface MainTableViewController ()

@end

@implementation MainTableViewController

@synthesize marrXMLData;
@synthesize mstrXMLString;
@synthesize mdictXMLPart;



NSXMLParser * rssParser;
NSDictionary *attributeImg;


- (void)viewDidLoad {
    [super viewDidLoad];
    [self startParsing];
}


-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self.tableView reloadData];
}

- (void)startParsing
{
    NSXMLParser *xmlparser = [[NSXMLParser alloc] initWithContentsOfURL:[NSURL URLWithString:@"http://www.nasa.gov/rss/dyn/lg_image_of_the_day.rss"]];
    [xmlparser setDelegate:self];
    [xmlparser parse];
    
    // Utilizamos CoreData a modo de Caché para persistir los datos
    if (marrXMLData.count != 0) {
        [self deleteAllObjectsFromCoreData];
        [self deleteAllImagesDownloaded];
        [self saveDataToCoreData];
    }
    [self reloadFromCoreData];
    [self.tableView reloadData];
}

// Si obtuvimos datos, los guardamos en CoreData parseándolos correctamente
-(void)saveDataToCoreData {
    
    NSManagedObjectContext *context = ((AppDelegate*)[[UIApplication sharedApplication] delegate]).persistentContainer.viewContext;
    
    for (int i = 0; i <[marrXMLData count]; i++){
        
        NSManagedObject *transaction = [NSEntityDescription insertNewObjectForEntityForName:@"News" inManagedObjectContext:context];
        
        NSString *mTitle = [marrXMLData objectAtIndex:i][@"title"];
        NSString *mBody = [marrXMLData objectAtIndex:i][@"description"];
        
        [transaction setValue:[NSNumber numberWithInt:(1+i)] forKey:@"identifier"];
        [transaction setValue:[mTitle stringByReplacingOccurrencesOfString:@"\n" withString:@""] forKey:@"title"];
        [transaction setValue:[mBody stringByReplacingOccurrencesOfString:@"\n" withString:@""] forKey:@"body"];
        [transaction setValue:[marrXMLData objectAtIndex:i][@"img"] forKey:@"image"];
        [transaction setValue:[marrXMLData objectAtIndex:i][@"link"] forKey:@"url"];
        
        // Convert string to date object
        NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
        [dateFormat setDateFormat:@"dd MMM yyyy HH:mm:ss Z"];
        NSString *stringDate = [NSString stringWithFormat:@"%@", [marrXMLData objectAtIndex:i][@"pubDate"]];
        stringDate = [stringDate stringByReplacingOccurrencesOfString:@"\n" withString:@""];
        stringDate = [stringDate stringByReplacingOccurrencesOfString:@"EDT" withString:@""];
        stringDate = [stringDate stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        stringDate = [NSString stringWithFormat:@"%@%@", stringDate, @":00 +0000"];
        stringDate = [stringDate componentsSeparatedByString:@", "][1];
        NSDate *date = [[NSDate alloc] init];
        date = [dateFormat dateFromString:stringDate]; // elimina el salto de línea
        [transaction setValue:date forKey:@"date"];
        
        // Save the context
        NSError *error = nil;
        if (![context save:&error]) {
            NSLog(@"Save Failed! %@ %@", error, [error localizedDescription]);
        }
        else {
            //NSLog(@"Saved correctly! id: %d", i + 1);
        }
        
    }

}

// Vaciamos completamente CoreData
-(void)deleteAllObjectsFromCoreData {
    
    NSManagedObjectContext *context = ((AppDelegate*)[[UIApplication sharedApplication] delegate]).persistentContainer.viewContext;
    NSFetchRequest *allNews = [[NSFetchRequest alloc] init];
    [allNews setEntity:[NSEntityDescription entityForName:@"News" inManagedObjectContext:context]];
    [allNews setIncludesPropertyValues:NO];
    
    NSError *error = nil;
    NSArray *news = [context executeFetchRequest:allNews error:&error];
    
    for (NSManagedObject *rssnews in news) {
        [context deleteObject:rssnews];
    }
    NSError *saveError = nil;
    [context save:&saveError];
}

// Borramos todas las imágenes descargadas en la carpeta interna "testFolder"
-(void)deleteAllImagesDownloaded {
    //getting application's document directory path
    NSArray * tempArray = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *docsDir = [tempArray objectAtIndex:0];
    
    //adding a new folder to the documents directory path
    NSString *appDir = [docsDir stringByAppendingPathComponent:@"/testFolder"];
    [[NSFileManager defaultManager] removeItemAtPath:appDir error:nil];
}

// Cargamos todos los datos de CoreData en el Array para posteriormente colocarlos en el ListView
-(void)reloadFromCoreData {
    NSManagedObjectContext *context = ((AppDelegate*)[[UIApplication sharedApplication] delegate]).persistentContainer.viewContext;
    NSFetchRequest *allNews = [[NSFetchRequest alloc] init];
    [allNews setEntity:[NSEntityDescription entityForName:@"News" inManagedObjectContext:context]];
    [allNews setIncludesPropertyValues:NO];
    // ordenamos de más recientes a más antiguas
    NSSortDescriptor *sort = [[NSSortDescriptor alloc] initWithKey:@"date" ascending:NO selector:@selector(localizedStandardCompare:)];
    [allNews setSortDescriptors:@[sort]];
    
    NSError *error = nil;
    NSArray *news = [context executeFetchRequest:allNews error:&error];
    
    marrXMLData = [[NSMutableArray alloc] init];
    
    for (NSManagedObject *rssnews in news) {
        mdictXMLPart = [[NSMutableDictionary alloc] init];
        News *mNews = (News *) rssnews;
        [mdictXMLPart setObject:mNews.title forKey:@"title"];
        [mdictXMLPart setObject:mNews.body forKey:@"description"];
        [mdictXMLPart setObject:mNews.url forKey:@"link"];
        [mdictXMLPart setObject:mNews.image forKey:@"img"];
        [marrXMLData addObject:mdictXMLPart];
    }
}

// Método para comprobar si existe una imagen o no. Se usará para cargar las imágenes o dejar la que viene por defecto.
-(BOOL)existsFileAtPath:(NSString *)fileName {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    //getting application's document directory path
    NSArray * tempArray = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *docsDir = [tempArray objectAtIndex:0];
    
    //adding a new folder to the documents directory path
    NSString *appDir = [docsDir stringByAppendingPathComponent:@"/testFolder/"];
    
    //Checking for directory existence and creating if not already exists
    if(![fileManager fileExistsAtPath:appDir])
    {
        return NO;
    }
    
    //retrieving the filename from the response and appending it again to the path
    //this path "appDir" will be used as the target path
    appDir =  [appDir stringByAppendingFormat:@"/%@",fileName]; // We can change the name here
    
    //checking for file existence and deleting if already present.
    if([fileManager fileExistsAtPath:appDir])
    {
        return YES;
    }
    return NO;
    
}

#pragma mark - Parser methods
- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict;
{
    if ([elementName isEqualToString:@"rss"]) {
        marrXMLData = [[NSMutableArray alloc] init];
    }
    if ([elementName isEqualToString:@"item"]) {
        mdictXMLPart = [[NSMutableDictionary alloc] init];
    }
    if ([elementName isEqualToString:@"enclosure"]) {
        attributeImg = attributeDict;
    }
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string;
{
    if (!mstrXMLString) {
        mstrXMLString = [[NSMutableString alloc] initWithString:string];
    }
    else {
        [mstrXMLString appendString:string];
    }
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName;
{

    if ([elementName isEqualToString:@"title"]
        || [elementName isEqualToString:@"pubDate"] || [elementName isEqualToString:@"description"] || [elementName isEqualToString:@"link"]) {
        [mdictXMLPart setObject:mstrXMLString forKey:elementName];
    }
    
    if ([elementName isEqualToString:@"enclosure"])
    {
        [mdictXMLPart setObject:attributeImg[@"url"] forKey:@"img"];
    }
    if ([elementName isEqualToString:@"item"]) {
        [marrXMLData addObject:mdictXMLPart];

    }
    mstrXMLString = nil;
    attributeImg = nil;

}



#pragma mark - Table view data source
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == 0) {
        return 100;
    }
    else {
        return 80;
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [marrXMLData count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    // Configure the cell...
    RSSNewsCustomCell *cell = [tableView dequeueReusableCellWithIdentifier:@"RSSNewsCell" forIndexPath:indexPath];
    
    cell.lblTitle.text = [[[marrXMLData objectAtIndex:indexPath.row] valueForKey:@"title"] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    cell.lblinfo.text = [[[marrXMLData objectAtIndex:indexPath.row] valueForKey:@"description"] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSArray *mStrings = [[[marrXMLData objectAtIndex:indexPath.row] valueForKey:@"img"] componentsSeparatedByString:@"/"];
    NSString *fileName = [mStrings objectAtIndex:[mStrings count] - 1];
    
    // Si tenemos la imagen descargada, la mostramos.
    if ([self existsFileAtPath:fileName]){
        NSArray * tempArray = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *docsDir = [tempArray objectAtIndex:0];
        
        NSString *appDir = [docsDir stringByAppendingPathComponent:[NSString stringWithFormat:@"%@/%@", @"/testFolder/", fileName]];
        
        [cell.imgView setImage:[UIImage imageWithContentsOfFile:appDir]];
    }

    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    DetailsViewController *detailsViewController = nil;
    detailsViewController = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"details"];
    detailsViewController.newsIdentifier=(int)indexPath.row + 1; // el pasamos el número de fila seleccionada
    [self.navigationController pushViewController:detailsViewController animated:YES];
}





@end
