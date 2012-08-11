//
//  Building_HQ.h
//  TurnWars
//
//  Created by Fahim Farook on 27/4/12.
//  Copyright (c) 2012 RookSoft Pte. Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"
#import "Building.h"

@interface Building_HQ : Building {
    
}

+(id)nodeWithTheGame:(HelloWorldLayer *)_game tileDict:(NSMutableDictionary *)tileDict owner:(int)_owner;
-(id)initWithTheGame:(HelloWorldLayer *)_game tileDict:(NSMutableDictionary *)tileDict owner:(int)_owner;

@end
