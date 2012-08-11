//
//  HelloWorldLayer.m
//  TurnWars_start
//
//  Created by Pablo Ruiz on 04/04/12.
//  Copyright __MyCompanyName__ 2012. All rights reserved.
//


// Import the interfaces
#import "HelloWorldLayer.h"
#import "GameConfig.h"
#import "Unit.h"
#import "Unit_Soldier.h"
#import "Unit_Tank.h"
#import "Unit_Cannon.h"
#import "Unit_Helicopter.h"
#import "SimpleAudioEngine.h"
#import "Multiplayer.h"

// HelloWorldLayer implementation
@implementation HelloWorldLayer

@synthesize tileDataArray;
@synthesize p1Units;
@synthesize p2Units;
@synthesize playerTurn;
@synthesize selectedUnit;
@synthesize actionsMenu;
@synthesize myPlayerId;

+(CCScene *) scene
{
	// 'scene' is an autorelease object.
	CCScene *scene = [CCScene node];
	
	// 'layer' is an autorelease object.
	HelloWorldLayer *layer = [HelloWorldLayer node];
	
	// add layer as a child to scene
	[scene addChild: layer];
	
	// return the scene
	return scene;
}

-(id)init {
	if ((self=[super init])) {
        self.isTouchEnabled = YES;
		[self createTileMap];
		// Load units
		p1Units = [[NSMutableArray alloc] initWithCapacity:10];
		p2Units = [[NSMutableArray alloc] initWithCapacity:10];
		[self loadUnits:1];
		[self loadUnits:2];
		// Set up turns
		playerTurn = 1;
		// Create building arrays
		p1Buildings = [[NSMutableArray alloc] initWithCapacity:10];
		p2Buildings = [[NSMutableArray alloc] initWithCapacity:10];
		// Load buildings
		[self loadBuildings:1];
		[self loadBuildings:2];
		[self addMenu];
		// Play background music
		[[SimpleAudioEngine sharedEngine] playBackgroundMusic:@"Five Armies.mp3" loop:YES];
        [self showStartScreen];
        // Retrieve GamoogaClient instance from Multiplayer singleton class
        GamoogaClient *gc = [[Multiplayer sharedInstance] getGc];
        // Add a callback to be called on receiving the "join" message
        [gc onMessageCallback:@selector(onMPMsgJoin:) withTarget:self forType:@"join"];
        // Connect to room
        [gc connectToRoomWithAppId:0 andAppUuid:@"-later-"];
        [startLabel setString:@"Checking for users..."];
	}
	return self;
}

// This method is called in response to a "join" message received.
// The data sent by server side along with "join" message is received
// by this method as the first argument. Since we sent a number from 
// the server side, we receive it here as NSNumber.
-(void)onMPMsgJoin:(NSNumber *)sess_id_
{
    // Update the startLabel showing the appropriate message
    [startLabel setString:@"Joining a session..."];
    // Reset GamoogaClient since we now need to create/connect to a session
    // and we done with the room
    [[Multiplayer sharedInstance] resetGc];
    int sess_id = [sess_id_ intValue];
    // If the received session id is -1...
    if (sess_id == -1) {
        // ...we create a new session
        [self mpCreateConnectToSession];
    } else {
        // ...else we connect to the session
        [self mpConnectToSession:(int)sess_id];
    }
}

// Get GamoogaClient and create and connect to a new session
-(void)mpCreateConnectToSession
{
    GamoogaClient *gc = [[Multiplayer sharedInstance] getGc];
    [gc createConnectToSessionWithAppId:0 andAppUuid:@"-later-"];
    [self mpAddCallbacks];
}
// Get GamoogaClient and connect to the session
-(void)mpConnectToSession:(int)sess_id
{
    GamoogaClient *gc = [[Multiplayer sharedInstance] getGc];
    [gc connectToSessionWithSessId:sess_id andAppUuid:@"-later-"];
    [self mpAddCallbacks];
}
// During the game play, we can expect the following messages from server side session,
// hence added the required callbacks.
-(void)mpAddCallbacks
{
    GamoogaClient *gc = [[Multiplayer sharedInstance] getGc];
    [gc onMessageCallback:@selector(onMPMsgWait:) withTarget:self forType:@"wait"];
    [gc onMessageCallback:@selector(onMPMsgStart:) withTarget:self forType:@"start"];
    [gc onMessageCallback:@selector(onMPMsgMove:) withTarget:self forType:@"move"];
    [gc onMessageCallback:@selector(onMPMsgMoveAttack:) withTarget:self forType:@"moveattack"];
    [gc onMessageCallback:@selector(onMPMsgEndturn:) withTarget:self forType:@"endturn"];
    [gc onMessageCallback:@selector(onMPMsgUsergone:) withTarget:self forType:@"usergone"];
}

-(void)onMPMsgMoveAttack:(NSDictionary *)move
{
    // retrieve the tile data of the tile to move to
    TileData *td = [self getTileData:ccp([(NSNumber *)[move objectForKey:@"x"] floatValue],[(NSNumber *)[move objectForKey:@"y"] floatValue])];
    // retrieve the tile data of the tile to attack
    TileData *atd = [self getTileData:ccp([(NSNumber *)[move objectForKey:@"ax"] floatValue],[(NSNumber *)[move objectForKey:@"ay"] floatValue])];
    // determine the units
    NSMutableArray *units;
    if (myPlayerId == 1) {
        units = p2Units;
    } else {
        units = p1Units;
    }
    // get the unit using the index obtained from other user
    Unit *unit = [units objectAtIndex:[(NSNumber *)[move objectForKey:@"u"] integerValue]];
    // [unit doMarkedMovement:td];
    // [unit doMarkedAttack:atd]; // (calling move and attach like this individually doesnot suffice)
    // move and then attack after move is complete
    [unit doMarkedMovement:td withCallback:@selector(doMarkedAttack:) ofObject:unit data:atd];
}


// Called when a "wait" message is received from the server side
-(void)onMPMsgWait:(id)_
{
    // We change the start label appropriately to show that user is waiting for another user.
    [startLabel setString:@"Waiting for opponent..."];
}

// Called when a "start" message is received from the server side.
// Two users have joined the game and the game can now start.
-(void)onMPMsgStart:(NSNumber *)mypid
{
    // set the player id to the number sent from the server side,
    // either 1 or 2 for first or second user
    myPlayerId = [mypid intValue];
    // Check if its my turn ie. playerTurn is equal to myPlayerId
    // (playerTurn is 1 at game start so the condition is true at first user
    // and false at second user initially)
    if (playerTurn == myPlayerId) {
        // Its my turn
        [turnLabel setString:@"Your turn"];
        [endTurnBtn setVisible:YES];
    } else {
        // Its not my turn
        [turnLabel setString:@"Other player's turn"];
        // Hide the end turn button since he cannot end his turn as its not hit turn
        [endTurnBtn setVisible:NO];
    }
    // remove the start layer as the game has started
    [self removeLayer:startLayer];
}

// Callback called when "move" message is received,
// the `move` argument contains the dictionary sent from the server
// which was in turn sent from the other user
-(void)onMPMsgMove:(NSDictionary *)move
{
    // Get the tile data for the tile coordinates in the data sent
    TileData *td = [self getTileData:ccp([(NSNumber *)[move objectForKey:@"x"] floatValue],[(NSNumber *)[move objectForKey:@"y"] floatValue])];
    NSMutableArray *units;
    // Figure out the set of units whose unit has moved -
    // If my player id is 1, it means I received the move of player 2
    // else (if my player id is 2), it means I received the move of player 1
    // assign units accordingly
    if (myPlayerId == 1) {
        units = p2Units;
    } else {
        units = p1Units;
    }
    // Get the unit to be moved based on the index obtained from the other user.
    // NOTE: We are relying on the fact that indices of individual units at each player remain the same,
    // and since its the same code and units are added similarly into p1Units and p2Units at each player,
    // the indices are guaranteed to be the same.
    Unit *unit = [units objectAtIndex:[(NSNumber *)[move objectForKey:@"u"] integerValue]];
    // Now move the unit to the required position
    [unit doMarkedMovement:td];
}

-(void)sendMoveOfUnit:(Unit *)unit
{
    NSMutableArray *units;
    // determine which set of units it is
    if (myPlayerId == 1) {
        units = p1Units;
    } else {
        units = p2Units;
    }
    GamoogaClient *gc = [[Multiplayer sharedInstance] getGc];
    // Get the tile coordinate the unit has moved to
    CGPoint pos = [self tileCoordForPosition:unit.mySprite.position];
    // Create a dictionary with the index of unit in its set of units and the final position it is in
    NSDictionary *data = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:[units indexOfObject:unit]],@"u",[NSNumber numberWithFloat:pos.x],@"x",[NSNumber numberWithFloat:pos.y],@"y", nil];
    // Finally, send it to the server in message of type "move"
    [gc sendMessage:data withType:@"move"];
}

-(void)onMPMsgEndturn:(id)_
{
    [self doEndTurn];
}

-(void)showStartScreen {
    CGSize wins = [[CCDirector sharedDirector] winSize];
    startLabel = [CCLabelBMFont labelWithString:@"Starting..." fntFile:@"Font_silver_size17.fnt"];
    [startLabel setPosition:ccp(wins.width/2.0, wins.height/2.0)];
    ccColor4B c = {0,0,0,200};
    startLayer = [CCLayerColor layerWithColor:c];
    [self addChild:startLayer z:21];
    [startLayer addChild:startLabel];
}

// on "dealloc" you need to release all your retained objects
-(void)dealloc {
	[tileDataArray release];
	[p1Units release];
	[p2Units release];
	[p1Buildings release];
	[p2Buildings release];
	[super dealloc];
}

-(void)createTileMap {
    // 1 - Create the map
    tileMap = [CCTMXTiledMap tiledMapWithTMXFile:@"StageMap.tmx"];        
    [self addChild:tileMap];
    // 2 - Get the background layer
    bgLayer = [tileMap layerNamed:@"Background"];
    // 3 - Get information for each tile in background layer
    tileDataArray = [[NSMutableArray alloc] initWithCapacity:5];
    for(int i = 0; i< tileMap.mapSize.height;i++) {
        for(int j = 0; j< tileMap.mapSize.width;j++) {
            int movementCost = 1;
            NSString * tileType = nil;
            int tileGid=[bgLayer tileGIDAt:ccp(j,i)];
            if (tileGid) {
                NSDictionary *properties = [tileMap propertiesForGID:tileGid];
                if (properties) {
                    movementCost = [[properties valueForKey:@"MovementCost"] intValue];
                    tileType = [properties valueForKey:@"TileType"];
                }
            }
            TileData * tData = [TileData nodeWithTheGame:self movementCost:movementCost position:ccp(j,i) tileType:tileType];
            [tileDataArray addObject:tData];
        } 
    }
}

// Get the scale for a sprite - 1 for normal display, 2 for retina
-(int)spriteScale {
    if (IS_HD)
        return 2;
    else
        return 1;
}

// Get the height for a tile based on the display type (retina or SD)
-(int)getTileHeightForRetina {
    if (IS_HD)
        return TILE_HEIGHT_HD;
	else
		return TILE_HEIGHT;
}

// Return tile coordinates (in rows and columns) for a given position
-(CGPoint)tileCoordForPosition:(CGPoint)position {
    CGSize tileSize = CGSizeMake(tileMap.tileSize.width,tileMap.tileSize.height);
    if (IS_HD) {
        tileSize = CGSizeMake(tileMap.tileSize.width/2,tileMap.tileSize.height/2);
    }
    int x = position.x / tileSize.width;
    int y = ((tileMap.mapSize.height * tileSize.height) - position.y) / tileSize.height;
    return ccp(x, y);
}

// Return the position for a tile based on its row and column
-(CGPoint)positionForTileCoord:(CGPoint)position {
    CGSize tileSize = CGSizeMake(tileMap.tileSize.width,tileMap.tileSize.height);
    if (IS_HD) {
        tileSize = CGSizeMake(tileMap.tileSize.width/2,tileMap.tileSize.height/2);
    }
    int x = position.x * tileSize.width + tileSize.width/2;
    int y = (tileMap.mapSize.height - position.y) * tileSize.height - tileSize.height/2;
    return ccp(x, y);
}

// Get the surrounding tiles (above, below, to the left, and right) of a given tile based on its row and column
-(NSMutableArray *)getTilesNextToTile:(CGPoint)tileCoord {
    NSMutableArray * tiles = [NSMutableArray arrayWithCapacity:4]; 
    if (tileCoord.y+1<tileMap.mapSize.height)
        [tiles addObject:[NSValue valueWithCGPoint:ccp(tileCoord.x,tileCoord.y+1)]];
    if (tileCoord.x+1<tileMap.mapSize.width)
        [tiles addObject:[NSValue valueWithCGPoint:ccp(tileCoord.x+1,tileCoord.y)]];
    if (tileCoord.y-1>=0)
        [tiles addObject:[NSValue valueWithCGPoint:ccp(tileCoord.x,tileCoord.y-1)]];
    if (tileCoord.x-1>=0)
        [tiles addObject:[NSValue valueWithCGPoint:ccp(tileCoord.x-1,tileCoord.y)]];
    return tiles;
}

// Get the TileData for a tile at a given position
-(TileData *)getTileData:(CGPoint)tileCoord {
    for (TileData * td in tileDataArray) {
        if (CGPointEqualToPoint(td.position, tileCoord)) {
            return td;
        }
    }
    return nil;
}

-(void)loadUnits:(int)player {
    CCTMXObjectGroup * unitsObjectGroup = [tileMap objectGroupNamed:[NSString stringWithFormat:@"Units_P%d",player]];
    NSMutableArray * units = nil;
    if (player ==1)
        units = p1Units;
    if (player ==2)
        units = p2Units;
    for (NSMutableDictionary * unitDict in [unitsObjectGroup objects]) {
        NSMutableDictionary * d = [NSMutableDictionary dictionaryWithDictionary:unitDict];
        NSString * unitType = [d objectForKey:@"Type"];
        NSString *classNameStr = [NSString stringWithFormat:@"Unit_%@",unitType];
        Class theClass = NSClassFromString(classNameStr);
        Unit * unit = [theClass nodeWithTheGame:self tileDict:d owner:player];
        [units addObject:unit];
    } 
}

// Check specified tile to see if there's any other unit (from either player) in it already
-(Unit *)otherUnitInTile:(TileData *)tile {
    for (Unit *u in p1Units) {
        if (CGPointEqualToPoint([self tileCoordForPosition:u.mySprite.position], tile.position))
            return u;
    }
    for (Unit *u in p2Units) {
        if (CGPointEqualToPoint([self tileCoordForPosition:u.mySprite.position], tile.position))
            return u;
    }
    return nil;
}

// Check specified tile to see if there's an enemy unit in it already
-(Unit *)otherEnemyUnitInTile:(TileData *)tile unitOwner:(int)owner {
    if (owner == 1) {
        for (Unit *u in p2Units) {
            if (CGPointEqualToPoint([self tileCoordForPosition:u.mySprite.position], tile.position))
                return u;
        }
    } else if (owner == 2) {
        for (Unit *u in p1Units) {
            if (CGPointEqualToPoint([self tileCoordForPosition:u.mySprite.position], tile.position))
                return u;
        }
    }
    return nil;
}

// Mark the specified tile for movement, if it hasn't been marked already
-(BOOL)paintMovementTile:(TileData *)tData {
    CCSprite *tile = [bgLayer tileAt:tData.position];
    if (!tData.selectedForMovement) {
        [tile setColor:ccBLUE];
        tData.selectedForMovement = YES;
        return NO;
    }
    return YES;
}

// Set the color of a tile back to the default color
-(void)unPaintMovementTile:(TileData *)tileData {
    CCSprite * tile = [bgLayer tileAt:tileData.position];
    [tile setColor:ccWHITE];
}

// Select specified unit
-(void)selectUnit:(Unit *)unit {
    selectedUnit = nil;
    selectedUnit = unit;
}

// Deselect the currently selected unit
-(void)unselectUnit {
    if (selectedUnit) {
        [selectedUnit unselectUnit];
    }
    selectedUnit = nil;
}

-(void)ccTouchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
	for (UITouch *touch in touches) {
		// Get the location of the touch
		CGPoint location = [touch locationInView: [touch view]];
		// Convert the touch location to OpenGL coordinates
		location = [[CCDirector sharedDirector] convertToGL: location];
		// Get the tile data for the tile at touched position
		TileData * td = [self getTileData:[self tileCoordForPosition:location]];
		// Move to the tile if we can move there
        if ((td.selectedForMovement && ![self otherUnitInTile:td]) || ([self otherUnitInTile:td] == selectedUnit)) {
            [selectedUnit doMarkedMovement:td];
        }
		else if(td.selectedForAttack) {
			// Attack the specified tile
			[selectedUnit doMarkedAttack:td];
			// Deselect the unit
			[self unselectUnit];
		} else {
			// Tapped a non-marked tile. What do we do?
			if (selectedUnit.selectingAttack) {
				// Was in the process of attacking - cancel attack and show menu
				selectedUnit.selectingAttack = NO;
				[self unPaintAttackTiles];
				[self showActionsMenu:selectedUnit canAttack:YES];
			} else if (selectedUnit.selectingMovement) {
				// Was in the process of moving - just remove marked tiles and await further action
				selectedUnit.selectingMovement = NO;
				[selectedUnit unMarkPossibleMovement];
				[self unselectUnit];
			}
		}
	}
}

-(void)showActionsMenu:(Unit *)unit canAttack:(BOOL)canAttack {
    // 1 - Get the window size
    CGSize wins = [[CCDirector sharedDirector] winSize];
    // 2 - Create the menu background
    contextMenuBck = [CCSprite spriteWithFile:@"popup_bg.png"];
    [self addChild:contextMenuBck z:19];
    // 3 - Create the menu option labels
    CCLabelBMFont * stayLbl = [CCLabelBMFont labelWithString:@"Stay" fntFile:@"Font_dark_size15.fnt"];
    CCMenuItemLabel * stayBtn = [CCMenuItemLabel itemWithLabel:stayLbl target:unit selector:@selector(doStay)];
    CCLabelBMFont * attackLbl = [CCLabelBMFont labelWithString:@"Attack" fntFile:@"Font_dark_size15.fnt"];
    CCMenuItemLabel * attackBtn = [CCMenuItemLabel itemWithLabel:attackLbl target:unit selector:@selector(doAttack)];
    CCLabelBMFont * cancelLbl = [CCLabelBMFont labelWithString:@"Cancel" fntFile:@"Font_dark_size15.fnt"];
    CCMenuItemLabel * cancelBtn = [CCMenuItemLabel itemWithLabel:cancelLbl target:unit selector:@selector(doCancel)];
    // 4 - Create the menu
    actionsMenu = [CCMenu menuWithItems:nil];
    // 5 - Add Stay button
    [actionsMenu addChild:stayBtn];
    // 6 - Add the Attack button only if the current unit can attack
    if (canAttack) {
        [actionsMenu addChild:attackBtn];
    }
    // 7 - Add the Cancel button
    [actionsMenu addChild:cancelBtn];
    // 8 - Add the menu to the layer
    [self addChild:actionsMenu z:19];
    // 9 - Position menu
    [actionsMenu alignItemsVerticallyWithPadding:5];
    if (unit.mySprite.position.x > wins.width/2) {
        [contextMenuBck setPosition:ccp(100,wins.height/2)];
        [actionsMenu setPosition:ccp(100,wins.height/2)];
    } else {
        [contextMenuBck setPosition:ccp(wins.width-100,wins.height/2)];
        [actionsMenu setPosition:ccp(wins.width-100,wins.height/2)];
    }
}

-(void)removeActionsMenu {
    // Remove the menu from the layer and clean up
    [contextMenuBck.parent removeChild:contextMenuBck cleanup:YES];
    contextMenuBck = nil;
    [actionsMenu.parent removeChild:actionsMenu cleanup:YES];
    actionsMenu = nil;
}

// Add the user turn menu
-(void)addMenu {
    // Get window size
    CGSize wins = [[CCDirector sharedDirector] winSize];
    // Set up the menu background and position
    CCSprite * hud = [CCSprite spriteWithFile:@"uiBar.png"];
    [self addChild:hud];
    [hud setPosition:ccp(wins.width/2,wins.height-[hud boundingBox].size.height/2)];
    // Set up the label showing the turn 
    turnLabel = [CCLabelBMFont labelWithString:[NSString stringWithFormat:@"Player %d's turn",playerTurn] fntFile:@"Font_dark_size15.fnt"];
    [self addChild:turnLabel];
    [turnLabel setPosition:ccp([turnLabel boundingBox].size.width/2 + 5,wins.height-[hud boundingBox].size.height/2)];
    // Set the turn label to display the current turn
    [self setPlayerTurnLabel];
    // Create End Turn button
    endTurnBtn = [CCMenuItemImage itemFromNormalImage:@"uiBar_button.png" selectedImage:@"uiBar_button.png" target:self selector:@selector(doEndTurn)];
    CCMenu * menu = [CCMenu menuWithItems:endTurnBtn, nil];
    [self addChild:menu];
    [menu setPosition:ccp(0,0)];
    [endTurnBtn setPosition:ccp(wins.width - 3 - [endTurnBtn boundingBox].size.width/2, wins.height - [endTurnBtn boundingBox].size.height/2 - 3)];
}

// End the turn, passing control to the other player
-(void)doEndTurn {
    // Do not do anything if a unit is selected
    if (selectedUnit)
        return;
    if (myPlayerId == playerTurn) { // (why this if ???)                            // *** added ***
        // Send a message of type "endturn" to the server                           // *** added ***
        [[[Multiplayer sharedInstance] getGc] sendMessage:@"" withType:@"endturn"]; // *** added ***
    }                                                                               // *** added ***
	// Play sound
	[[SimpleAudioEngine sharedEngine] playEffect:@"btn.wav"];
    // Switch players depending on who's currently selected
    if (playerTurn ==1) {
        playerTurn = 2;
    } else if (playerTurn ==2) {
        playerTurn = 1;
    }
    // Do a transition to signify the end of turn
    [self showEndTurnTransition];
    // Set the turn label to display the current turn
    [self setPlayerTurnLabel];
}

// Set the turn label to display the current turn
-(void)setPlayerTurnLabel {
    // Set the label value for the current player
    //[turnLabel setString:[NSString stringWithFormat:@"Player %d's turn",playerTurn]];
    if (playerTurn == myPlayerId) {                                                     // *** added ***
        [turnLabel setString:@"Your turn"];                                             // *** added ***
        [endTurnBtn setVisible:YES];                                                    // *** added ***
    } else {                                                                            // *** added ***
        [turnLabel setString:@"Other player's turn"];                                   // *** added ***
        [endTurnBtn setVisible:NO];                                                     // *** added ***
    }                                                                                   // *** added ***
    // Change the label colour based on the player
    if (playerTurn ==1) {
        [turnLabel setColor:ccRED];
    } else if (playerTurn == 2) {
        [turnLabel setColor:ccBLUE];
    }
}

// Fancy transition to show turn switch/end
-(void)showEndTurnTransition {
    // Create a black layer
    ccColor4B c = {0,0,0,0};
    CCLayerColor *layer = [CCLayerColor layerWithColor:c];
    [self addChild:layer z:20];
    // Add a label showing the player turn to the black layer
    //CCLabelBMFont * turnLbl = [CCLabelBMFont labelWithString:[NSString stringWithFormat:@"Player %d's turn",playerTurn] fntFile:@"Font_silver_size17.fnt"];
    // *** commented above line ***
    CCLabelBMFont *turnLbl = [CCLabelBMFont labelWithString: [NSString stringWithFormat:(playerTurn == myPlayerId)?@"Your turn":@"Other player's turn"] fntFile:@"Font_silver_size17.fnt"];
    // *** added above line ***
    [layer addChild:turnLbl];
    [turnLbl setPosition:ccp([CCDirector sharedDirector].winSize.width/2,[CCDirector sharedDirector].winSize.height/2)];
    // Run an action which fades in the black layer, calls the beginTurn method, fades out the black layer, and finally removes it
    [layer runAction:[CCSequence actions:[CCFadeTo actionWithDuration:1 opacity:150],[CCCallFunc actionWithTarget:self selector:@selector(beginTurn)],[CCFadeTo actionWithDuration:1 opacity:0],[CCCallFuncN actionWithTarget:self selector:@selector(removeLayer:)], nil]];
}

-(void)sendMoveAndAttackOfUnit:(Unit *)unit attacked:(Unit *)attackedUnit
{
    NSMutableArray *units,*otherunits;
    // determine the units
    if (myPlayerId == 1) {
        units = p1Units;
        otherunits = p2Units;
    } else {
        units = p2Units;
        otherunits = p1Units;
    }
    GamoogaClient *gc = [[Multiplayer sharedInstance] getGc];
    // get the tile coordinates of final position
    CGPoint pos = [self tileCoordForPosition:unit.mySprite.position];
    // get the tile coordinates of attack position
    CGPoint attackpos = [self tileCoordForPosition:attackedUnit.mySprite.position];
    // data to be sent: index of the unit moved, its final position and its attack position
    NSDictionary *data = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:[units indexOfObject:unit]],@"u",[NSNumber numberWithFloat:pos.x],@"x",[NSNumber numberWithFloat:pos.y],@"y",[NSNumber numberWithInt:[otherunits indexOfObject:attackedUnit]],@"au",[NSNumber numberWithFloat:attackpos.x],@"ax",[NSNumber numberWithFloat:attackpos.y],@"ay", nil];
    // now send the data as part of "moveattack" message to server
    [gc sendMessage:data withType:@"moveattack"];
}

// Begin the next turn
-(void)beginTurn {
    // Activate the units for the active player
    if (playerTurn ==1) {
        [self activateUnits:p2Units];
    } else if (playerTurn ==2) {
        [self activateUnits:p1Units];
    }
}

// Remove the black layer added for the turn change transition
-(void)removeLayer:(CCNode *)n {
    [n.parent removeChild:n cleanup:YES];
}

// Activate all the units in the specified array (called from beginTurn passing the units for the active player)
-(void)activateUnits:(NSMutableArray *)units {
    for (Unit *unit in units) {
        [unit startTurn];
    }
}

// Check the specified tile to see if it can be attacked
-(BOOL)checkAttackTile:(TileData *)tData unitOwner:(int)owner {
	// Is this tile already marked for attack, if so, we don't need to do anything further
	// If not, does the tile contain an enemy unit? If yes, we can attack this tile
    if (!tData.selectedForAttack && [self otherEnemyUnitInTile:tData unitOwner:owner]!= nil) {
        tData.selectedForAttack = YES;
        return NO;
    }
    return YES;
}

// Paint the given tile as one that can be attacked
-(BOOL)paintAttackTile:(TileData *)tData {
    CCSprite * tile = [bgLayer tileAt:tData.position];
    [tile setColor:ccRED];
    return YES;
}

// Remove the attack marking from all tiles
-(void)unPaintAttackTiles {
    for (TileData * td in tileDataArray) {
        [self unPaintAttackTile:td];
    }
}

// Remove the attack marking from a specific tile
-(void)unPaintAttackTile:(TileData *)tileData {
    CCSprite * tile = [bgLayer tileAt:tileData.position];
    [tile setColor:ccWHITE];
}

// Calculate the damage inflicted when one unit attacks another based on the unit type
-(int)calculateDamageFrom:(Unit *)attacker onDefender:(Unit *)defender {
    if ([attacker isKindOfClass:[Unit_Soldier class]]) {
        if ([defender isKindOfClass:[Unit_Soldier class]]) {
            return 5;
        } else if ([defender isKindOfClass:[Unit_Helicopter class]]) {
            return 1;
        } else if ([defender isKindOfClass:[Unit_Tank class]]) {
            return 2;
        } else if ([defender isKindOfClass:[Unit_Cannon class]]) {
            return 4;
        }
    } else if ([attacker isKindOfClass:[Unit_Tank class]]) {
        if ([defender isKindOfClass:[Unit_Soldier class]]) {
            return 6;
        } else if ([defender isKindOfClass:[Unit_Helicopter class]]) {
            return 3;
        } else if ([defender isKindOfClass:[Unit_Tank class]]) {
            return 5;
        } else if ([defender isKindOfClass:[Unit_Cannon class]]) {
            return 8;
        }
    } else if ([attacker isKindOfClass:[Unit_Helicopter class]]) {
        if ([defender isKindOfClass:[Unit_Soldier class]]) {
            return 7;
        } else if ([defender isKindOfClass:[Unit_Helicopter class]]) {
            return 4;
        } else if ([defender isKindOfClass:[Unit_Tank class]]) {
            return 7;
        } else if ([defender isKindOfClass:[Unit_Cannon class]]) {
            return 3;
        }
    } else if ([attacker isKindOfClass:[Unit_Cannon class]]) {
        if ([defender isKindOfClass:[Unit_Soldier class]]) {
            return 6;
        } else if ([defender isKindOfClass:[Unit_Helicopter class]]) {
            return 0;
        } else if ([defender isKindOfClass:[Unit_Tank class]]) {
            return 8;
        } else if ([defender isKindOfClass:[Unit_Cannon class]]) {
            return 8;
        }
    }
    return 0;
}

// Check if each player has run out of units
-(void)checkForMoreUnits {
    if ([p1Units count]== 0) {
        [self showEndGameMessageWithWinner:2];
    } else if([p2Units count]== 0) {
        [self showEndGameMessageWithWinner:1];
    }
}

// Show winning message for specified player
-(void)showEndGameMessageWithWinner:(int)winningPlayer {
    // Create black layer
    ccColor4B c = {0,0,0,0};
    CCLayerColor * layer = [CCLayerColor layerWithColor:c];
    [self addChild:layer z:20];
    // Add background image to new layer
    CCSprite * bck = [CCSprite spriteWithFile:@"victory_bck.png"];
    [layer addChild:bck];
    [bck setPosition:ccp([CCDirector sharedDirector].winSize.width/2,[CCDirector sharedDirector].winSize.height/2)];
    // Create winning message
    CCLabelBMFont * turnLbl = [CCLabelBMFont labelWithString:[NSString stringWithFormat:@"Player %d wins!",winningPlayer]  fntFile:@"Font_dark_size15.fnt"];
    [layer addChild:turnLbl];
    [turnLbl setPosition:ccp([CCDirector sharedDirector].winSize.width/2,[CCDirector sharedDirector].winSize.height/2-30)];
    // Fade in new layer, show it for 2 seconds, call method to remove layer, and finally, restart game
    [layer runAction:[CCSequence actions:[CCFadeTo actionWithDuration:1 opacity:150],[CCDelayTime actionWithDuration:2],[CCCallFuncN actionWithTarget:self selector:@selector(removeLayer:)],[CCCallFunc actionWithTarget:self selector:@selector(restartGame)], nil]];
}

// Restart game
-(void)restartGame {
    [[CCDirector sharedDirector] replaceScene:[CCTransitionJumpZoom transitionWithDuration:1 scene:[HelloWorldLayer scene]]];
}

// Load buildings for layer
-(void)loadBuildings:(int)player {
    // Get building object group from tilemap
    CCTMXObjectGroup *buildingsObjectGroup = [tileMap objectGroupNamed:[NSString stringWithFormat:@"Buildings_P%d",player]];
    // Get the correct building array based on the current player
    NSMutableArray *buildings = nil;
    if (player == 1)
        buildings = p1Buildings;
    if (player == 2)
        buildings = p2Buildings;
    // Iterate over the buildings in the array, adding them to the game
    for (NSMutableDictionary *buildingDict in [buildingsObjectGroup objects]) {
        // Get the building type
        NSMutableDictionary *d = [NSMutableDictionary dictionaryWithDictionary:buildingDict];
        NSString *buildingType = [d objectForKey:@"Type"];
        // Get the right building class based on type
        NSString *classNameStr = [NSString stringWithFormat:@"Building_%@",buildingType];
        Class theClass = NSClassFromString(classNameStr);
        // Create the building
        Building *building = [theClass nodeWithTheGame:self tileDict:d owner:player];
        [buildings addObject:building];
    }
}

// Return the first matching building (if any) on the given tile
-(Building *)buildingInTile:(TileData *)tile {
    // Check player 1's buildings
    for (Building *u in p1Buildings) {
        if (CGPointEqualToPoint([self tileCoordForPosition:u.mySprite.position], tile.position))
            return u;
    }
    // Check player 2's buildings
    for (Building *u in p2Buildings) {
        if (CGPointEqualToPoint([self tileCoordForPosition:u.mySprite.position], tile.position))
            return u;
    }
    return nil;
}

@end
