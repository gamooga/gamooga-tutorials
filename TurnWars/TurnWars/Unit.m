//
//  Unit.m
//  TurnWars
//
//  Created by Fahim Farook on 23/4/12.
//  Copyright (c) 2012 RookSoft Ltd. All rights reserved.
//

#import "Unit.h"
#import "Unit_Soldier.h"
#import "SimpleAudioEngine.h"

#define kACTION_MOVEMENT 0
#define kACTION_ATTACK 1

@implementation Unit

@synthesize mySprite,owner,hasRangedWeapon;
@synthesize selectingMovement;
@synthesize selectingAttack;

+(id)nodeWithTheGame:(HelloWorldLayer *)_game tileDict:(NSMutableDictionary *)tileDict owner:(int)_owner {
	// Dummy method - implemented in sub-classes
	return nil;
}

-(id)init {
    if ((self=[super init])) {
        state = kStateUngrabbed;
        hp = 10;
		spOpenSteps = [[NSMutableArray alloc] init];
		spClosedSteps = [[NSMutableArray alloc] init];
		movementPath = [[NSMutableArray alloc] init];
    }
    return self;
}

// Create the sprite and HP label for each unit
-(void)createSprite:(NSMutableDictionary *)tileDict {
    int x = [[tileDict valueForKey:@"x"] intValue]/[theGame spriteScale];
    int y = [[tileDict valueForKey:@"y"] intValue]/[theGame spriteScale];
    int width = [[tileDict valueForKey:@"width"] intValue]/[theGame spriteScale];
    int height = [[tileDict valueForKey:@"height"] intValue];
    int heightInTiles = height/[theGame getTileHeightForRetina];
    x += width/2;
    y += (heightInTiles * [theGame getTileHeightForRetina]/(2*[theGame spriteScale]));
    mySprite = [CCSprite spriteWithFile:[NSString stringWithFormat:@"%@_P%d.png",[tileDict valueForKey:@"Type"],owner]];
    [self addChild:mySprite];
    mySprite.userData = self;
    mySprite.position = ccp(x,y);
    hpLabel = [CCLabelBMFont labelWithString:[NSString stringWithFormat:@"%d",hp] fntFile:@"Font_dark_size12.fnt"];
    [mySprite addChild:hpLabel];
    [hpLabel setPosition:ccp([mySprite boundingBox].size.width-[hpLabel boundingBox].size.width/2,[hpLabel boundingBox].size.height/2)];
}

// Can the unit walk over the given tile?
-(BOOL)canWalkOverTile:(TileData *)td {
    return YES;
}

// Update the HP value display
-(void)updateHpLabel {
    [hpLabel setString:[NSString stringWithFormat:@"%d",hp]];
    [hpLabel setPosition:ccp([mySprite boundingBox].size.width-[hpLabel boundingBox].size.width/2,[hpLabel boundingBox].size.height/2)];
}

-(void)onEnter {
    [[CCTouchDispatcher sharedDispatcher] addTargetedDelegate:self priority:0 swallowsTouches:YES];
    [super onEnter];
}

-(void)onExit {	
    [[CCTouchDispatcher sharedDispatcher] removeDelegate:self];
    [super onExit];
}	

// Was this unit below the point that was touched?
-(BOOL)containsTouchLocation:(UITouch *)touch {
    if (CGRectContainsPoint([mySprite boundingBox], [self convertTouchToNodeSpaceAR:touch])) {
        return YES;
    }
    return NO;
}

// Handle touches
-(BOOL)ccTouchBegan:(UITouch *)touch withEvent:(UIEvent *)event {
    // If its not the player's turn disallow the move               // *** added ***
    if ([theGame myPlayerId] != [theGame playerTurn]) {             // *** added ***
        return NO;                                                  // *** added ***
    }                                                               // *** added ***

	// Was a unit belonging to the non-active player touched? If yes, do not handle the touch
	if (([theGame.p1Units containsObject:self] && theGame.playerTurn == 2) || ([theGame.p2Units containsObject:self] && theGame.playerTurn == 1)) 
		return NO;
	// If the action menu is showing, do not handle any touches on unit
	if (theGame.actionsMenu)
		return NO;
	// If the current unit is the selected unit, do not handle any touches
	if (theGame.selectedUnit == self) 
		return NO;
	// If this unit has moved already, do not handle any touches
	if (movedThisTurn) 
		return NO;
    if (state != kStateUngrabbed) 
        return NO;
    if (![self containsTouchLocation:touch]) 
        return NO;
    state = kStateGrabbed;
    [theGame unselectUnit];
    [self selectUnit];
    return YES;
}

-(void)ccTouchEnded:(UITouch *)touch withEvent:(UIEvent *)event {
    state = kStateUngrabbed;
}

-(void)dealloc {
	[movementPath release]; 
	movementPath = nil;
	[spOpenSteps release]; 
	spOpenSteps = nil;
	[spClosedSteps release]; 
	spClosedSteps = nil;
    [super dealloc];
}

// Select this unit
-(void)selectUnit {
    [theGame selectUnit:self];
	// Make the selected unit slightly bigger
    mySprite.scale = 1.2;
	// If the unit was not moved this turn, mark it as possible to move
    if (!movedThisTurn) {
        selectingMovement = YES;
        [self markPossibleAction:kACTION_MOVEMENT];
    }    
}

// Deselect this unit
-(void)unselectUnit {
	// Reset the sprit back to normal size
    mySprite.scale =1;
    selectingMovement = NO;
    selectingAttack = NO;
    [self unMarkPossibleMovement];
	[self unMarkPossibleAttack];
}

// Remove the "possible-to-move" indicator
-(void)unMarkPossibleMovement {
    for (TileData * td in theGame.tileDataArray) {
        [theGame unPaintMovementTile:td];
        td.parentTile = nil;
        td.selectedForMovement = NO;
    }
}

// Carry out specified action for this unit
-(void)markPossibleAction:(int)action {    
    // Get the tile where the unit is standing
    TileData *startTileData = [theGame getTileData:[theGame tileCoordForPosition:mySprite.position]];
    [spOpenSteps addObject:startTileData];
    [spClosedSteps addObject:startTileData];
    // If we are selecting movement, paint the tiles
    if (action == kACTION_MOVEMENT) {
        [theGame paintMovementTile:startTileData]; 
    }
	else if (action == kACTION_ATTACK) {
		[theGame checkAttackTile:startTileData unitOwner:owner];
	}
    int i =0;
    // For each tile in the list, beginning with the start tile
    do {
        TileData * _currentTile = ((TileData *)[spOpenSteps objectAtIndex:i]);
        // You get every 4 tiles surrounding the current tile
        NSMutableArray * tiles = [theGame getTilesNextToTile:_currentTile.position];
        for (NSValue * tileValue in tiles) {
            TileData * _neighbourTile = [theGame getTileData:[tileValue CGPointValue]];
            // If you already dealt with it, you ignore it.
            if ([spClosedSteps containsObject:_neighbourTile]) {
                // Ignore it
                continue; 
            }
            // If there is an enemy on the tile and you are moving, ignore it. You can't move there.
            if (action == kACTION_MOVEMENT && [theGame otherEnemyUnitInTile:_neighbourTile unitOwner:owner]) {
                // Ignore it
                continue;
            }
            // If you are moving and this unit can't walk over that tile type, ignore it.
            if (action == kACTION_MOVEMENT && ![self canWalkOverTile:_neighbourTile]) {
                // Ignore it
                continue;
            }
            _neighbourTile.parentTile = nil;
            _neighbourTile.parentTile = _currentTile;
            // If you can move over there, paint it.
            if (action == kACTION_MOVEMENT) {
                [theGame paintMovementTile:_neighbourTile];
            }
			else if (action == kACTION_ATTACK) {
				[theGame checkAttackTile:_neighbourTile unitOwner:owner];
			}
            // Check how much it costs to move to or attack that tile.
            if (action == kACTION_MOVEMENT) {
                if ([_neighbourTile getGScore]> movementRange) {
                    continue;
                }
			} else if (action == kACTION_ATTACK) {
				// Is the tile not in attack range?
				if ([_neighbourTile getGScoreForAttack]> attackRange) {
					// Ignore it
					continue;
				}
			}
            [spOpenSteps addObject:_neighbourTile];
            [spClosedSteps addObject:_neighbourTile];
        }
        i++;
    } while (i < [spOpenSteps count]);
    [spClosedSteps removeAllObjects];
    [spOpenSteps removeAllObjects];
}

-(void)insertOrderedInOpenSteps:(TileData *)tile {
	// Compute the step's F score
	int tileFScore = [tile fScore]; 
	int count = [spOpenSteps count];
	// This will be the index at which we will insert the step
	int i = 0; 
	for (; i < count; i++) {
		// If the step's F score is lower or equals to the step at index i
		if (tileFScore <= [[spOpenSteps objectAtIndex:i] fScore]) { 			// Then you found the index at which you have to insert the new step
            // Basically you want the list sorted by F score
			break;
		}
	}
	// Insert the new step at the determined index to preserve the F score ordering
	[spOpenSteps insertObject:tile atIndex:i];
}

-(int)computeHScoreFromCoord:(CGPoint)fromCoord toCoord:(CGPoint)toCoord {
	// Here you use the Manhattan method, which calculates the total number of steps moved horizontally and vertically to reach the
	// final desired step from the current step, ignoring any obstacles that may be in the way
	return abs(toCoord.x - fromCoord.x) + abs(toCoord.y - fromCoord.y);
}

-(int)costToMoveFromTile:(TileData *)fromTile toAdjacentTile:(TileData *)toTile {
	// Because you can't move diagonally and because terrain is just walkable or unwalkable the cost is always the same.
	// But it has to be different if you can move diagonally and/or if there are swamps, hills, etc...
	return 1;
}

//-(void)constructPathAndStartAnimationFromStep:(TileData *)tile {                                                   // *** commented ***
-(void)constructPathAndStartAnimationFromStep:(TileData *)tile withCallback:(SEL)cb ofObject:(id)obj data:(id)data { // *** added ***
	[movementPath removeAllObjects];
	// Repeat until there are no more parents
	do {
		// Don't add the last step which is the start position (remember you go backward, so the last one is the origin position ;-)
		if (tile.parentTile != nil) {
		    // Always insert at index 0 to reverse the path
		    [movementPath insertObject:tile atIndex:0]; 
		}
		// Go backward
		tile = tile.parentTile; 
	} while (tile != nil);
    if (obj != nil) {                                                                                      // *** added ***
        [self runAction:[CCSequence actions:[CCDelayTime actionWithDuration:0.4*[movementPath count]+0.1], // *** added ***
                         [CCCallFuncO actionWithTarget:obj selector:cb object:data],nil]];                 // *** added ***
    }                                                                                                      // *** added ***
    [self popStepAndAnimate];
}

-(void)popStepAndAnimate {	
	// 1 - Check if the unit is done moving
	if ([movementPath count] == 0) {
		// 1.1 - Mark the unit as not moving
		moving = NO;
		[self unMarkPossibleMovement];
        if (owner == [theGame myPlayerId]) {                // *** added ***
            // 1.2 - Mark the tiles that can be attacked
            [self markPossibleAction:kACTION_ATTACK];
            // 1.3 - Check for enemies in range
            BOOL enemiesAreInRange = NO;
            for (TileData *td in theGame.tileDataArray) {
                if (td.selectedForAttack) {
                    enemiesAreInRange = YES;
                    break;
                }
            }
            // 1.4 - Show the menu and enable the Attack option if there are enemies in range
            [theGame showActionsMenu:self canAttack:enemiesAreInRange];
        } else {                                            // *** added ***
            [mySprite setColor:ccGRAY];                     // *** added ***
        }                                                   // *** added ***
		return;
	}
	// Play move sound
	[[SimpleAudioEngine sharedEngine] playEffect:@"move.wav"];
	// 2 - Get the next step to move toward
	TileData *s = [movementPath objectAtIndex:0];
	// Prepare the action and the callback
	id moveAction = [CCMoveTo actionWithDuration:0.4 position:[theGame positionForTileCoord:s.position]];
	id moveCallback = [CCCallFunc actionWithTarget:self selector:@selector(popStepAndAnimate)]; // set the method itself as the callback
	// Remove the step
	[movementPath removeObjectAtIndex:0];
	// Play actions
	[mySprite runAction:[CCSequence actions:moveAction, moveCallback, nil]];
}

-(void)doMarkedMovement:(TileData *)targetTileData {
    [self doMarkedMovement:targetTileData withCallback:nil ofObject:nil data:nil];
}

-(void)doMarkedMovement:(TileData *)targetTileData withCallback:(SEL)cb ofObject:(id)obj data:(id)data {
    if (moving)
        return;
    moving = YES;
    CGPoint startTile = [theGame tileCoordForPosition:mySprite.position];
    tileDataBeforeMovement = [theGame getTileData:startTile];
    [self insertOrderedInOpenSteps:tileDataBeforeMovement];
    do {
        TileData * _currentTile = ((TileData *)[spOpenSteps objectAtIndex:0]);
        CGPoint _currentTileCoord = _currentTile.position;
        [spClosedSteps addObject:_currentTile];
        [spOpenSteps removeObjectAtIndex:0];
        // If the currentStep is the desired tile coordinate, you are done!
        if (CGPointEqualToPoint(_currentTile.position, targetTileData.position)) {
            //[self constructPathAndStartAnimationFromStep:_currentTile];
            [self constructPathAndStartAnimationFromStep:_currentTile withCallback:cb ofObject:obj data:data]; // *** added ***
            // Set to nil to release unused memory
            [spOpenSteps removeAllObjects]; 
            // Set to nil to release unused memory
            [spClosedSteps removeAllObjects]; 
            break;
        }
        NSMutableArray * tiles = [theGame getTilesNextToTile:_currentTileCoord];
        for (NSValue * tileValue in tiles) {
            CGPoint tileCoord = [tileValue CGPointValue];
            TileData * _neighbourTile = [theGame getTileData:tileCoord];
            if ([spClosedSteps containsObject:_neighbourTile]) {
                continue;
            }
            if ([theGame otherEnemyUnitInTile:_neighbourTile unitOwner:owner]) {
                // Ignore it
                continue; 
            }
            if (![self canWalkOverTile:_neighbourTile]) {
                // Ignore it
                continue; 
            }
            int moveCost = [self costToMoveFromTile:_currentTile toAdjacentTile:_neighbourTile];
            NSUInteger index = [spOpenSteps indexOfObject:_neighbourTile];
            if (index == NSNotFound) {
                _neighbourTile.parentTile = nil;
                _neighbourTile.parentTile = _currentTile;
                _neighbourTile.gScore = _currentTile.gScore + moveCost;
                _neighbourTile.hScore = [self computeHScoreFromCoord:_neighbourTile.position toCoord:targetTileData.position];
                [self insertOrderedInOpenSteps:_neighbourTile];
            } else {
                // To retrieve the old one (which has its scores already computed ;-)
                _neighbourTile = [spOpenSteps objectAtIndex:index]; 
                // Check to see if the G score for that step is lower if you use the current step to get there
                if ((_currentTile.gScore + moveCost) < _neighbourTile.gScore) {
                    // The G score is equal to the parent G score + the cost to move from the parent to it
                    _neighbourTile.gScore = _currentTile.gScore + moveCost;
                    // Now you can remove it from the list without being afraid that it can't be released
                    [spOpenSteps removeObjectAtIndex:index];
                    // Re-insert it with the function, which is preserving the list ordered by F score
                    [self insertOrderedInOpenSteps:_neighbourTile];
                }
            }
        }
    } while ([spOpenSteps count]>0);
}

// add the following method
-(void)doStay
{
    [self doStayWithMPSend:YES];
}

// Stay on the current tile
-(void)doStayWithMPSend:(BOOL)toSend {
	// Play menu selection sound
	[[SimpleAudioEngine sharedEngine] playEffect:@"btn.wav"];
    // 1 - Remove the context menu since we've taken an action
    [theGame removeActionsMenu];
    movedThisTurn = YES;
    // 2 - Turn the unit tray to indicate that it has moved
    [mySprite setColor:ccGRAY];
    [theGame unselectUnit];
    if (toSend) {                         // *** added ***
        [theGame sendMoveOfUnit:self]; // *** added ***
    }
    // 3 - Check for victory conditions
    if ([self isKindOfClass:[Unit_Soldier class]]) {
        // If this is a Soldier unit and it is standing over an enemy building, the player wins.
		// Get the building on the current tile
		Building *buildingBelow = [theGame buildingInTile:[theGame getTileData:[theGame tileCoordForPosition:mySprite.position]]];
		// Is there a building?
		if (buildingBelow) {
			// Is the building owned by the other player?
			if (buildingBelow.owner != self.owner) {
				NSLog(@"Building captured!!!");
				// Show end game message
				[theGame showEndGameMessageWithWinner:self.owner];
			}
		}
    }
}

// Attack another unit
-(void)doAttack {
	// Play menu selection sound
	[[SimpleAudioEngine sharedEngine] playEffect:@"btn.wav"];
    // 1 - Remove the context menu since we've taken an action
    [theGame removeActionsMenu];
    // 2 - Check if any tile has been selected for attack
    for (TileData *td in theGame.tileDataArray) {
        if (td.selectedForAttack) {
            // 3 - Mark the selected tile as attackable
            [theGame paintAttackTile:td];
        }
    }
    selectingAttack = YES;
}

// Cancel the move for the current unit and go back to previous position
-(void)doCancel {
	// Play menu selection sound
	[[SimpleAudioEngine sharedEngine] playEffect:@"btn.wav"];
    // Remove the context menu since we've taken an action
    [theGame removeActionsMenu];
    // Move back to the previous tile
    mySprite.position = [theGame positionForTileCoord:tileDataBeforeMovement.position];
    [theGame unselectUnit];
}

// Activate this unit for play
-(void)startTurn {
    // Mark the unit as not having moved for this turn
    movedThisTurn = NO;
    // Mark the unit as not having attacked this turn
    attackedThisTurn = NO;
    // Change the unit overlay colour from gray (inactive) to white (active)
    [mySprite setColor:ccWHITE];
}

// Remove attack selection marking from all tiles
-(void)unMarkPossibleAttack {
    for (TileData *td in theGame.tileDataArray) {
        [theGame unPaintAttackTile:td];
        td.parentTile = nil;
        td.selectedForAttack = NO;
    }
}

// Attack the specified tile
-(void)doMarkedAttack:(TileData *)targetTileData {
    // Mark the unit as having attacked this turn
    attackedThisTurn = YES;
    // Get the attacked unit
    Unit *attackedUnit = [theGame otherEnemyUnitInTile:targetTileData unitOwner:owner];
    // Let the attacked unit handle the attack
    [attackedUnit attackedBy:self firstAttack:YES];
    // Keep this unit in the curren location
    //[self doStay];
    [self doStayWithMPSend:NO];                                       // *** added ***
    if ([theGame myPlayerId] == self.owner) {                         // *** added ***
        [theGame sendMoveAndAttackOfUnit:self attacked:attackedUnit]; // *** added ***
    }                                                                 // *** added ***
}

// Handle the attack from another unit
-(void)attackedBy:(Unit *)attacker firstAttack:(BOOL)firstAttack {
    // Create the damage data since we need to pass this information on to another method
    NSMutableDictionary *damageData = [NSMutableDictionary dictionaryWithCapacity:2];
    [damageData setObject:attacker forKey:@"attacker"];
    [damageData setObject:[NSNumber numberWithBool:firstAttack] forKey:@"firstAttack"];
    // Create explosion sprite
    CCSprite *explosion = [CCSprite spriteWithFile:@"explosion_1.png"];
    [self addChild:explosion z:10];
    [explosion setPosition:mySprite.position];
    // Create explosion animation
    CCAnimation *animation = [CCAnimation animation];
    for (int i=1;i<=7;i++) {
        [animation addFrameWithFilename: [NSString stringWithFormat:@"explosion_%d.png", i]];
    }
    id action = [CCAnimate actionWithDuration:0.5 animation:animation restoreOriginalFrame:NO];
	// Play damage sound
	[[SimpleAudioEngine sharedEngine] playEffect:@"hurt.wav"];
    // Run the explosion animation, call method to remove explosion once it's done and finally calculate damage from attack    
    [explosion runAction: [CCSequence actions: action,
	   [CCCallFuncN actionWithTarget:self selector:@selector(removeExplosion:)], 
	   [CCCallFuncO actionWithTarget:self selector:@selector(dealDamage:) object:damageData],
	   nil]];
}

// Calculate damage from attack
-(void)dealDamage:(NSMutableDictionary *)damageData {
    // 1 - Get the attacker from the passed in data dictionary
    Unit *attacker = [damageData objectForKey:@"attacker"];
    // 2 - Calculate damage
    hp -= [theGame calculateDamageFrom:attacker onDefender:self];
    // 3 - Is the unit dead?
    if (hp<=0) {
		// Unit destroyed sound
		[[SimpleAudioEngine sharedEngine] playEffect:@"explosion.wav"];
        // 4 - Unit is dead - remove it from game
        [self.parent removeChild:self cleanup:YES];
        if ([theGame.p1Units containsObject:self]) {
            [theGame.p1Units removeObject:self];
        } else if ([theGame.p2Units containsObject:self]) {
            [theGame.p2Units removeObject:self];
        }
		[theGame checkForMoreUnits];
    } else {
        // 5 - Update HP for unit
        [self updateHpLabel];
        // 6 - Call attackedBy: on the attacker so that damage can be calculated for the attacker
        if ([[damageData objectForKey:@"firstAttack"] boolValue] && !attacker.hasRangedWeapon && !self.hasRangedWeapon) {
            [attacker attackedBy:self firstAttack:NO];
			
        }
    }
}

// Clean up after explosion
-(void)removeExplosion:(CCSprite *)e {
    // Remove the explosion sprite
    [e.parent removeChild:e cleanup:YES];
}

@end
