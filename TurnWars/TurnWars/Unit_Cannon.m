//
//  Unit_Cannon.m
//  TurnWars
//
//  Created by Fahim Farook on 23/4/12.
//  Copyright (c) 2012 RookSoft Ltd. All rights reserved.
//

#import "Unit_Cannon.h"

@implementation Unit_Cannon

+(id)nodeWithTheGame:(HelloWorldLayer *)_game tileDict:(NSMutableDictionary *)tileDict owner:(int)_owner {
	return [[[self alloc] initWithTheGame:_game tileDict:tileDict owner:_owner] autorelease];
}

-(id)initWithTheGame:(HelloWorldLayer *)_game tileDict:(NSMutableDictionary *)tileDict owner:(int)_owner {
	if ((self=[super init])) {
		theGame = _game;
        owner= _owner;
        movementRange = 3;
        attackRange = 1;
        [self createSprite:tileDict];
        [theGame addChild:self z:3];
	}
	return self;
}

-(BOOL)canWalkOverTile:(TileData *)td {
    if ([td.tileType isEqualToString:@"Mountain"] || [td.tileType isEqualToString:@"River"]) {
        return NO;
    }
    return YES;
}

@end 
