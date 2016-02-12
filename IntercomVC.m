//
//  IntercomVC.m
//  BunkeredDowns
//
//  Created by Adam Wilson on 2/3/16.
//  Copyright © 2016 Adam Wilson. All rights reserved.
//

#import "IntercomVC.h"

@interface IntercomVC () <MKConnectionDelegate, MKServerModelDelegate, MKAudioDelegate>
{
    MKAudio *audio;
    MKConnection *conn;
    NSFileHandle* pipeReadHandle;
    NSPipe* pipe;
    
    FloorVC *parentVC;
}
@end

@implementation IntercomVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    audio = [MKAudio sharedAudio];
    [[MKVersion sharedVersion] setOpusEnabled:YES];
    
    MKAudioSettings settings;
    settings.codec = MKCodecFormatOpus;
    settings.opusForceCELTMode = NO;
    settings.transmitType = MKTransmitTypeVAD;
    settings.vadKind = MKVADKindSignalToNoise;
    settings.vadMax = .7;
    settings.vadMin = .2;
    settings.enableVadGate = YES;
    settings.vadGateTimeSeconds = 1;
    settings.amplification = .5;
    settings.volume = 10;
    settings.enableComfortNoise = NO;
    settings.enableEchoCancellation = NO;
    [audio updateAudioSettings:&settings];
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:YES];
    parentVC = (FloorVC *)self.presentingViewController;
}


- (IBAction)startIntercom:(id)sender {
    [self loginToMumbleServer];
    [self pipe];
}

- (IBAction)endIntercom:(id)sender {
    [audio stop];
    [conn disconnect];
}

-(void)pipe{
    pipe = [NSPipe pipe];
    pipeReadHandle = [pipe fileHandleForReading];
    dup2([[pipe fileHandleForWriting] fileDescriptor], fileno(stderr));
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleNotification:)
                                                 name:NSFileHandleReadCompletionNotification
                                               object:pipeReadHandle];
    [pipeReadHandle readInBackgroundAndNotify];
}

- (void) handleNotification:(NSNotification*)notification {
    
    NSString* str = [[NSString alloc] initWithData:[[notification userInfo] objectForKey:NSFileHandleNotificationDataItem] encoding:NSASCIIStringEncoding];
    
    // Do something with str...
    if ([str containsString:@"Fatal"]) {
        [audio stop];
        [conn disconnect];
        [pipeReadHandle readInBackgroundAndNotify];
        [self loginToMumbleServer];
    }else if ([str containsString:@"UDP"]) {
        close([[pipe fileHandleForWriting]fileDescriptor]);
        pipeReadHandle = nil;
    }else{
        if (pipeReadHandle){
            [pipeReadHandle readInBackgroundAndNotify];
        }
    }
    [textLabel setText:str];
}

#define MUMBLE_SERVER @“SERVER_IP”
#define MUMBLE_SERVER_PORT SERVER_PORT
#define MUMBLE_SERVER_PASS @“SERVER_PASS”
- (void)loginToMumbleServer
{
    conn = [[MKConnection alloc] init];
    conn.delegate = self;
    [conn setIgnoreSSLVerification:YES];
    [conn connectToHost:MUMBLE_SERVER port:MUMBLE_SERVER_PORT];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)connection:(MKConnection *)conn unableToConnectWithError:(NSError *)err
{
    NSLog(@"Error: %@", err.localizedDescription);
}

-(void)connectionOpened:(MKConnection *)connection
{
    [connection authenticateWithUsername:@“NAME” password:@“PASSWORD” accessTokens:nil];
    
    MKServerModel *serverModel = [[MKServerModel alloc] initWithConnection:connection];
    [serverModel registerConnectedUser];
    [audio start];
}

-(void)serverModel:(MKServerModel *)model joinedServerAsUser:(MKUser *)user withWelcomeMessage:(MKTextMessage *)msg
{
    NSLog(@"authenticated");
}

-(void)connection:(MKConnection *)conn trustFailureInCertificateChain:(NSArray *)chain
{
    NSLog(@"failure trust");
}

-(void)connection:(MKConnection *)conn rejectedWithReason:(MKRejectReason)reason explanation:(NSString *)explanation
{
    NSLog(@"rejected: %@", explanation);
}

-(void)connection:(MKConnection *)conn closedWithError:(NSError *)err
{
    NSLog(@"closed %@", err.localizedDescription);
}

-(void)serverModel:(MKServerModel *)model userJoined:(MKUser *)user
{
    NSLog(@"joined");
}
@end
