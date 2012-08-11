//
//  TileData.h
//  TurnWars
//
//  Created by Fahim Farook on 23/4/12.
//  Copyright (c) 2012 RookSoft Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"
#import "HelloWorldLayer.h"

@class HelloWorldLayer;

@interface TileData : CCNode {
    HelloWorldLayer * theGame;
    BOOL selectedForMovement;
    BOOL selectedForAttack;
    int movementCost;
    CGPoint position;
    TileData * parentTile;
    int hScore;
    int gScore;
    int fScore;
    NSString * tileType;
}

@property (nonatomic,readwrite) CGPoint position;
@property (nonatomic,assign) TileData * parentTile;
@property (nonatomic,readwrite) int movementCost;
@property (nonatomic,readwrite) BOOL selectedForAttack;
@property (nonatomic,readwrite) BOOL selectedForMovement;
@property (nonatomic,readwrite) int hScore;
@property (nonatomic,readwrite) int gScore;
@property (nonatomic,assign) NSString * tileType;

+(id)nodeWithTheGame:(HelloWorldLayer *)_game movementCost:(int)_movementCost position:(CGPoint)_position tileType:(NSString *)_tileType;
-(id)initWithTheGame:(HelloWorldLayer *)_game movementCost:(int)_movementCost position:(CGPoint)_position tileType:(NSString *)_tileType;
-(int)getGScore;
-(int)getGScoreForAttack;
-(int)fScore;

@end
