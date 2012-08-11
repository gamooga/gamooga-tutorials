//
//  Unit.h
//  TurnWars
//
//  Created by Fahim Farook on 23/4/12.
//  Copyright (c) 2012 RookSoft Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"
#import "HelloWorldLayer.h"
#import "GameConfig.h"
#import "TileData.h"

@interface Unit : CCNode <CCTargetedTouchDelegate> {
    HelloWorldLayer * theGame;
    CCSprite * mySprite;
    touchState state;
    int owner;
    BOOL hasRangedWeapon;
    BOOL moving;
    int movementRange;
    int attackRange;
    TileData * tileDataBeforeMovement;
    int hp;
    CCLabelBMFont * hpLabel;
    NSMutableArray *spOpenSteps;
    NSMutableArray *spClosedSteps;
    NSMutableArray * movementPath;
    BOOL movedThisTurn;
    BOOL attackedThisTurn;
    BOOL selectingMovement;
    BOOL selectingAttack;
}

@property (nonatomic,assign)CCSprite * mySprite;
@property (nonatomic,readwrite) int owner;
@property (nonatomic,readwrite) BOOL hasRangedWeapon;
@property (nonatomic,readwrite) BOOL selectingMovement;
@property (nonatomic,readwrite) BOOL selectingAttack;

+(id)nodeWithTheGame:(HelloWorldLayer *)_game tileDict:(NSMutableDictionary *)tileDict owner:(int)_owner;
-(void)createSprite:(NSMutableDictionary *)tileDict;
-(void)selectUnit;
-(void)unselectUnit;
-(void)unMarkPossibleMovement;
-(void)markPossibleAction:(int)action;
-(void)insertOrderedInOpenSteps:(TileData *)tile;
-(int)computeHScoreFromCoord:(CGPoint)fromCoord toCoord:(CGPoint)toCoord;
-(int)costToMoveFromTile:(TileData *)fromTile toAdjacentTile:(TileData *)toTile;
-(void)constructPathAndStartAnimationFromStep:(TileData *)tile;
-(void)popStepAndAnimate;
-(void)doMarkedMovement:(TileData *)targetTileData;
-(void)startTurn;
-(void)unMarkPossibleAttack;
-(void)doMarkedAttack:(TileData *)targetTileData;
-(void)attackedBy:(Unit *)attacker firstAttack:(BOOL)firstAttack;
-(void)dealDamage:(NSMutableDictionary *)damageData;
-(void)removeExplosion:(CCSprite *)e;
-(void)doMarkedMovement:(TileData *)targetTileData withCallback:(SEL)cb ofObject:(id)obj data:(id)data;

@end
