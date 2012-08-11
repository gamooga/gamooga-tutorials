//
//  Multiplayer.m
//  TurnWars
//
//  Created by Kishore Annapureddy on 12/08/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "Multiplayer.h"
@implementation Multiplayer
+(Multiplayer *)sharedInstance
{
    static Multiplayer *singleton;
    @synchronized(self) {
        if (singleton == nil) {
            singleton = [[Multiplayer alloc] init];
        }
        return singleton;
    }
}
-(GamoogaClient *)getGc
{
    if (!gc) {
        // NOTE: Argument to be passed is the IP address of the development server.
        gc = [[GamoogaClient alloc] initWithDevServer:@"127.0.0.1"];
    }
    return gc;
}
-(void)resetGc
{
    gc = nil;
}
@end