//
//  Unit_Cannon.h
//  TurnWars
//
//  Created by Fahim Farook on 23/4/12.
//  Copyright (c) 2012 RookSoft Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"
#import "Unit.h"

@interface Unit_Cannon : Unit {
    
}

-(id)initWithTheGame:(HelloWorldLayer *)_game tileDict:(NSMutableDictionary *)tileDict owner:(int)_owner;
-(BOOL)canWalkOverTile:(TileData *)td;

@end
