//
//  DetailsViewController.m
//  atSistemasLectorRSS
//
//  Created by Oscar Rodriguez Garrucho on 9/6/17.
//  Copyright © 2017 Oscar Rodriguez Garrucho. All rights reserved.
//

#import "DetailsViewController.h"
#import "AppDelegate.h"
#import "News+CoreDataClass.h"

@interface DetailsViewController ()

@end

@implementation DetailsViewController

@synthesize session;
NSUInteger taskIdentifier;
NSURLSessionDownloadTask *downloadTask;
News *news;

// Abrimos en el navegador por defecto el link de la noticia
- (IBAction)safariButtonPressed:(UIBarButtonItem *)sender {
    
    NSString *urlString = [NSString stringWithFormat:@"%@", news.url];
    NSString *trimmedString = [urlString stringByReplacingOccurrencesOfString:@" " withString:@""];
    trimmedString = [trimmedString stringByReplacingOccurrencesOfString:@"\n" withString:@""]; // elimina el salto de línea
    NSLog(@"%@", trimmedString);
    UIApplication *application = [UIApplication sharedApplication];
    NSURL *URL = [NSURL URLWithString:trimmedString];
    [application openURL:URL options:@{} completionHandler:^(BOOL success) {
        if (success) {
            NSLog(@"Opened url: %@", trimmedString);
        }
    }];
}

- (void)viewDidLoad {
    [super viewDidLoad];
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    // Cargamos la noticia según el ID que le pasamos desde MainTableViewController
    NSManagedObjectContext *context = ((AppDelegate*)[[UIApplication sharedApplication] delegate]).persistentContainer.viewContext;
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"News"];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"identifier == %d", self.newsIdentifier];
    [fetchRequest setPredicate:predicate];
    NSArray *mArray = [[context executeFetchRequest:fetchRequest error:nil] mutableCopy];
    news = [mArray objectAtIndex:0];
    self.titleLabel.text = news.title;
    self.descriptionTexView.text = news.body;
    
    
    self.syncSpinner.hidden = NO;
    [self.syncSpinner startAnimating];
    NSArray *mStrings = [news.image componentsSeparatedByString:@"/"];
    NSString *fileName = [mStrings objectAtIndex:[mStrings count] - 1];
    NSLog(@"%@", fileName);
    
    // Si ya existe la imagen, la colocamos directamente, si no,
    // la descargamos con el link de la imagen y la colocamos cuando
    // esté descargada al 100% en la carpeta "testFolder"
    if ([self existsFileAtPath:fileName]){
        self.syncSpinner.hidden = YES;
        [self.syncSpinner stopAnimating];
    }
    else {
        [self downloadImageTask:news.image];
    }
    
}

-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [session invalidateAndCancel];
}




// Mandamos crear una tarea de descarga de la imagen y la inicializamos
-(void)downloadImageTask:(NSString *)urlImage{
    
    NSURLSessionConfiguration *sessionConfiguration = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:@"es.oscargarrucho.atSistemasLectorRSS"];
    sessionConfiguration.HTTPMaximumConnectionsPerHost = 5;
    session = [NSURLSession sessionWithConfiguration:sessionConfiguration delegate:self delegateQueue:nil];
    
    downloadTask = [session downloadTaskWithURL:[NSURL URLWithString:urlImage]];
    downloadTask.priority=NSURLSessionTaskPriorityLow;
    
    // Keep the new task identifier.
    taskIdentifier = downloadTask.taskIdentifier;
    NSLog(@"Start download with task: %lu", (unsigned long)taskIdentifier);
    
    // Start the task.
    [downloadTask resume];
}

// Comprobamos que exista ya la imagen, y de ser así, la cargamos en el imagenView directamente.
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
    
    appDir =  [appDir stringByAppendingFormat:@"/%@",fileName]; // We can change the name here
    
    if([fileManager fileExistsAtPath:appDir])
    {
        dispatch_async(dispatch_get_main_queue(), ^(void)
                       {
                           [self.image setImage:[UIImage imageWithContentsOfFile:appDir]];
                           NSLog(@"Image loaded successfully -> %@", appDir);
                       });
        return YES;
    }
    return NO;

}

#pragma mark - Download task data source
// While is downloading...
-(void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite{
    if (totalBytesExpectedToWrite == NSURLSessionTransferSizeUnknown) {
        NSLog(@"Unknown transfer size");
    }
    else{
        
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            
            double downloaded = ((double)totalBytesWritten / (double)totalBytesExpectedToWrite) * 100;
            NSLog(@"Download... %f %%", downloaded);
        }];
    }
}

// Finish downloading...
-(void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location{
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error;
    
    //getting application's document directory path
    NSArray * tempArray = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *docsDir = [tempArray objectAtIndex:0];
    
    //adding a new folder to the documents directory path
    NSString *appDir = [docsDir stringByAppendingPathComponent:@"/testFolder/"];
    
    //Checking for directory existence and creating if not already exists
    if(![fileManager fileExistsAtPath:appDir])
    {
        [fileManager createDirectoryAtPath:appDir withIntermediateDirectories:NO attributes:nil error:&error];
    }
    
    appDir =  [appDir stringByAppendingFormat:@"/%@",[[downloadTask response] suggestedFilename]]; // We can change the name here
    
    //checking for file existence and deleting if already present.
    if([fileManager fileExistsAtPath:appDir])
    {
        NSLog([fileManager removeItemAtPath:appDir error:&error]?@"deleted":@"not deleted");
    }
    
    //moving the file from temp location to app's own directory
    BOOL fileCopied = [fileManager moveItemAtPath:[location path] toPath:appDir error:&error];
    NSLog(fileCopied ? @"Yes" : @"No");
    NSLog(@"%@", appDir);
    
    // Main thread work (UI usually)
    dispatch_async(dispatch_get_main_queue(), ^(void)
                   {
                       // Main thread work (UI usually)
                       [self.image setImage:[UIImage imageWithContentsOfFile:appDir]];
                       NSLog(@"Image loaded successfully -> %@", appDir);
                       self.syncSpinner.hidden = YES;
                       [self.syncSpinner stopAnimating];
                   });
    
    
}



@end
