#import "SSH.h"
#import <NMSSH/NMSSH.h>

#define RPI_KEY @“******”
#define RPI_IP @“***.***.**.***”
#define RPI_PORT 22
#define RPI_USERNAME @“*****”
#define RPI_HDD @"/media/usbhdd/%@"

@interface SSH() <NMSSHSessionDelegate>
{
    NMSSHChannel *channel;
    NMSSHSession *session;
    dispatch_queue_t queue;
}

@end
@implementation SSH

-(instancetype)init
{
    self = [super init];
    
    //check for rsa key
    //NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    //NSString *documentsDirectory = [paths objectAtIndex:0];
    //NSString *filePath = [documentsDirectory stringByAppendingPathComponent: RPI_KEY];
    NSString *filePath = [[NSBundle mainBundle] pathForResource:RPI_KEY ofType:@""];
    NSString *rsa = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:nil];
    
    if (!rsa) {
    /*    NSString *pathToFile = [[NSBundle mainBundle] pathForResource:RPI_KEY ofType:@""];
        rsa = [NSString stringWithContentsOfFile:pathToFile encoding:NSUTF8StringEncoding error:nil];
        [rsa writeToFile:filePath atomically:YES encoding:NSUTF8StringEncoding error:nil];
        
        NSURL *url = [NSURL fileURLWithPath:filePath];
        NSError *error = nil;
        BOOL success = [url setResourceValue: [NSNumber numberWithBool: YES]
                                      forKey: NSURLIsExcludedFromBackupKey error: &error];
        if(!success){
            NSLog(@"Error excluding %@ from backup %@", [url lastPathComponent], error);
        }
    */
        NSLog(@"no key");
    }else {
        
        //create instances of channel and session
        session = [[NMSSHSession alloc] initWithHost:RPI_IP port:RPI_PORT andUsername:RPI_USERNAME];
        
        if (![session isConnected]) {
            [session connect];
        }
        
        if (session.isConnected) {
            [session authenticateByPublicKey:nil privateKey:filePath andPassword:nil];
            
            if (session.isAuthorized) {
                channel = [[NMSSHChannel alloc] initWithSession:session];
            }
        }
    }
    
    //create dispatch queue
    queue = dispatch_queue_create("bdqueue", NULL);
    return self;
}

-(BOOL)isConnected
{
    return session.isConnected;
}

-(void)disconnect
{
    [session disconnect];
}

-(void)connect
{
    [session connect];
}

-(void)sendCommand:(NSString *)command withArguments:(NSArray *)args
{
    if (args.count > 0) {
        //create string for arguments
        NSMutableString *base = [[NSMutableString alloc] initWithString:command];
        
        //iterate thru each argument in array
        for (NSString *argument in args){
            //append base with new argument
            [base appendString:[NSString stringWithFormat:@" \"%@\"",argument]];
        }
        
        //update command string with arguments
        command = base;
        NSLog(@"final command: %@", command);
        
    }
    dispatch_async(queue, ^{
        NSError *err;
        [channel execute:command error:&err];
        
        if (err) {
            NSLog(@"error:%@", err.description);
            self.isArduinoOnline = NO;
        }
    });
}

-(void)downloadFile:(NSString *)fileName
{
    //create path for file
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *filePathStatus = [documentsDirectory stringByAppendingPathComponent:fileName];
    
    //raspberry pi file directory
    NSString *rpiFileName = [NSString stringWithFormat:RPI_HDD, fileName];
    
    //downloads should hold up thread until completed
    //other routines require the downloaded file before operation
    dispatch_sync(queue, ^{
        BOOL t = [channel downloadFile:rpiFileName to:filePathStatus];
        
        if (t != 1) {
            NSLog(@"error");
            self.isArduinoOnline = NO;
        }else{
            self.isArduinoOnline = YES;
        }
        
        //sanity check for file
        NSFileManager *fileManager = [NSFileManager defaultManager];
        if (![fileManager fileExistsAtPath:filePathStatus]) {
            NSLog(@"file not found");
        }
    });
}

-(void)uploadFile:(NSString *)filePath
{
    //get audio file name
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *directoryPath = [documentsDirectory stringByAppendingString:@"/"];
    
    NSString *fileName = [filePath stringByReplacingOccurrencesOfString:directoryPath withString:@""];
    NSLog(@"filename for pi: %@", fileName);
    
    //raspberry pi file directory
    NSString *rpiFileName = [NSString stringWithFormat:RPI_HDD, fileName];
    
    //downloads should hold up thread until completed
    //other routines require the downloaded file before operation
    dispatch_sync(queue, ^{
        //BOOL t = [session.sftp writeContents:[NSData dataWithContentsOfFile:filePath] toFileAtPath:rpiFileName];
        BOOL t = [channel uploadFile:filePath to:rpiFileName];
        
        if (t != 1) {
            NSLog(@"error");
        }
    });
}


@end
