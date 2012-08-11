//
//  Building_HQ.m
//  TurnWars
//
//  Created by Fahim Farook on 27/4/12.
//  Copyright (c) 2012 RookSoft Pte. Ltd. All rights reserved.
//

#import "Building_HQ.h"

@implementation Building_HQ

+(id)nodeWithTheGame:(HelloWorldLayer *)_game tileDict:(NSMutableDictionary *)tileDict owner:(int)_owner {
	return [[[self alloc] initWithTheGame:_game tileDict:tileDict owner:_owner] autorelease];
}

-(id)initWithTheGame:(HelloWorldLayer *)_game tileDict:(NSMutableDictionary *)tileDict owner:(int)_owner {
	if ((self=[super init])) {
		theGame = _game;
        owner= _owner;
        [self createSprite:tileDict];
        [theGame addChild:self z:1];
	}
	return self;
}

@end
