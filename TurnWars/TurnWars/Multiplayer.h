//
//  Multiplayer.h
//  TurnWars
//
//  Created by Kishore Annapureddy on 12/08/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "GamoogaClient.h"
@interface Multiplayer : NSObject
{
    GamoogaClient *gc;
}
+(Multiplayer *)sharedInstance;
-(GamoogaClient *)getGc;
-(void)resetGc;
@end