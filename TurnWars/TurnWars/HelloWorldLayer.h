//
//  HelloWorldLayer.h
//  TurnWars_start
//
//  Created by Pablo Ruiz on 04/04/12.
//  Copyright __MyCompanyName__ 2012. All rights reserved.
//

#import "cocos2d.h"
#import "TileData.h"
#import "Building.h"

@class Building;
@class TileData;
@class Unit;

// HelloWorldLayer
@interface HelloWorldLayer: CCLayer {
    CCTMXTiledMap *tileMap;
    CCTMXLayer *bgLayer;
    CCTMXLayer *objectLayer; 
    NSMutableArray * tileDataArray;
	NSMutableArray *p1Units;
	NSMutableArray *p2Units;
	Unit *selectedUnit;
	int playerTurn;
	CCMenu *actionsMenu;
	CCSprite *contextMenuBck;
	CCMenuItemImage *endTurnBtn;
	CCLabelBMFont *turnLabel;
	NSMutableArray *p1Buildings;
	NSMutableArray *p2Buildings;
    CCLabelBMFont *startLabel;
    CCLayerColor *startLayer;
    int myPlayerId;
}

@property (nonatomic, assign) NSMutableArray *tileDataArray;
@property (nonatomic, assign) NSMutableArray *p1Units;
@property (nonatomic, assign) NSMutableArray *p2Units;
@property (nonatomic, readwrite) int playerTurn;
@property (nonatomic, assign) Unit *selectedUnit;
@property (nonatomic, assign) CCMenu *actionsMenu;
@property (nonatomic, readwrite) int myPlayerId;

// returns a CCScene that contains the HelloWorldLayer as the only child
+(CCScene *)scene;
-(void)createTileMap;
-(int)spriteScale;
-(int)getTileHeightForRetina;
-(CGPoint)tileCoordForPosition:(CGPoint)position;
-(CGPoint)positionForTileCoord:(CGPoint)position;
-(NSMutableArray *)getTilesNextToTile:(CGPoint)tileCoord;
-(TileData *)getTileData:(CGPoint)tileCoord;
-(Unit *)otherUnitInTile:(TileData *)tile;
-(Unit *)otherEnemyUnitInTile:(TileData *)tile unitOwner:(int)owner;
-(BOOL)paintMovementTile:(TileData *)tData;
-(void)unPaintMovementTile:(TileData *)tileData;
-(void)selectUnit:(Unit *)unit;
-(void)unselectUnit;
-(void)showActionsMenu:(Unit *)unit canAttack:(BOOL)canAttack;
-(void)removeActionsMenu;
-(void)addMenu;
-(void)doEndTurn;
-(void)setPlayerTurnLabel;
-(void)showEndTurnTransition;
-(void)beginTurn;
-(void)removeLayer:(CCNode *)n;
-(void)activateUnits:(NSMutableArray *)units;
-(BOOL)checkAttackTile:(TileData *)tData unitOwner:(int)owner;
-(BOOL)paintAttackTile:(TileData *)tData;
-(void)unPaintAttackTiles;
-(void)unPaintAttackTile:(TileData *)tileData;
-(int)calculateDamageFrom:(Unit *)attacker onDefender:(Unit *)defender;
-(void)checkForMoreUnits;
-(void)showEndGameMessageWithWinner:(int)winningPlayer;
-(void)restartGame;
-(void)loadBuildings:(int)player;
-(Building *)buildingInTile:(TileData *)tile;
-(void)sendMoveOfUnit:(Unit *)unit;
-(void)sendMoveAndAttackOfUnit:(Unit *)unit attacked:(Unit *)attackedUnit;

@end
