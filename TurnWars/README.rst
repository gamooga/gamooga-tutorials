TurnWars + Gamooga
===================

Introduction
------------
In this tutorial, we have converted the game of TurnWars from Ray Wenderlich website to make it actually multiplayer over internet using Gamooga. The original game was a "pass your device" style multiplayer game. Original tutorials are here: Part 1: www.raywenderlich.com/12022/how-to-make-a-turn-based-strategy-game-part-1 and Part 2: www.raywenderlich.com/12110/how-to-make-a-turn-based-strategy-game-part-2

In this tutorial, we want to convert original game: http://www.youtube.com/watch?v=1zmNwyAQtjU into real multiplayer: http://www.youtube.com/watch?v=v6I5xyFe5Uw. (Both are ~35 sec  videos, you will like the conversion).

This is a standalone tutorial and does not require you to readup the previous tutorials. But since we will be changing already written game code, it helps to have a bit of an understanding of how everything is laid out. I recommend you to skim through the code, more importantly the two files: ``HelloWorldLayer.m`` and ``Unit.m``. You can download the game code from Part 2 link.

What is Gamooga?
----------------
Gamooga provides you with realtime multipalyer communication infrasctructure so you need not worry about anything server side! You just integrate the client libraries and upload the required server side message processing scripts onto Gamooga cluster and you are done.

Gamooga has a concept of ``room`` and ``session``. For a single app uploaded to Gamooga, a single instance of ``room`` can exist and multiple instances of ``session`` can exist. A ``room`` is meant to be used as a lobby, a match making area or for general teaming up before users join the actual game by creating a new ``session``.

Implementation
--------------
To convert from "pass your device" multiplayer to real multiplayer, we will use Gamooga's room to match users. A user will connect to room and then checks for waiting users. If there's no user waiting, he will create a new session and wait for another user to join the session. If there's a user waiting, he will connect to the same session as the waiting user and their game starts.

We will use the session to send out moves, attacks and end of turns of one user to another.

Setup
-----
1. Download the source code of TurnWars from http://www.raywenderlich.com/12110/how-to-make-a-turn-based-strategy-game-part-2
2. Extract it and you have a folder 'TurnWars'. With in 'TurnWars' folder you have TurnWars.xcodeproject. Open it in XCode.
3. To develop using Gamooga, you require to download the SDK from http://www.gamooga.com/dev/docs/sdk.html#installation-on-mac-os-x
4. Extract downloaded SDK zip into 'TurnWars' folder. It should create a 'gamooga-sdk' folder (highlighted in red below).
5. Install 'lunatic_python-1.0-py2.6-macosx10.6.mpkg.zip' available in 'gamooga-sdk/dev-server' folder.
6. Create folder 'gamlet' in folder 'TurnWars' (highlighted in red below).
7. Open Terminal and cd into 'TurnWars' directory and run development server with: ``python2.6 ./gamooga-sdk/dev-server/gamooga.py ./gamlet``
8. Now from TurnWars/gamooga-sdk/api/ios drag 'GamoogaClient.h' into source tree and 'libgamoogaclient.a' into Frameworks group of source tree.

.. image:: //raw.github.com/gamooga/gamooga-tutorials/master/TurnWars/img/dir.png

Add Multiplayer class
---------------------
In XCode, add a new Objective-C class in your project - ``Multiplayer.m`` and ``Multiplayer.h``. Copy the following content into them.

Multiplayer.h:

.. code-block:: obj-c

    #import "GamoogaClient.h"
    @interface Multiplayer : NSObject
    {
        GamoogaClient *gc;
    }
    +(Multiplayer *)sharedInstance;
    -(GamoogaClient *)getGc;
    -(void)resetGc;
    @end

Multiplayer.m:

.. code-block:: obj-c

    #import "Multiplayer.h"
    @implementation Multiplayer
    +(Multiplayer *)sharedInstance
    {
        static Multiplayer *singleton;
        @synchronized(self) {
            if (singleton == nil) {
                singleton = [[Multiplayer alloc] init];
            }
            return singleton;
        }
    }
    -(GamoogaClient *)getGc
    {
        if (!gc) {
            // NOTE: Argument to be passed is the IP address of the development server.
            gc = [[GamoogaClient alloc] initWithDevServer:@"127.0.0.1"];
        }
        return gc;
    }
    -(void)resetGc
    {
        gc = nil;
    }
    @end

Multiplayer is a singleton class that manages GamoogaClient. Please note that the argument to ``initWithDevServer`` is IP ``127.0.0.1``. This is the IP the game attempts to connect to when its run. Since we are running both the server and the client (iOS simulator) on the same machine we are specifying ``127.0.0.1``. We will change it to your local LAN IP when testing on real device.

Connect to Gamooga and related UI
---------------------------------

Now we connect to Gamooga server from the game and add the relevant UI. Add the following private variables to HelloWorldLayer.h:

.. code-block:: obj-c

    CCLabelBMFont *startLabel;
    CCLayerColor *startLayer;

In ``HelloWorldLayer.m``, import ``Multiplayer.h``:

.. code-block:: obj-c

    #import "Multiplayer.h"

In ``HelloWorldLayer.m`` again, add the following method:

.. code-block:: obj-c

    -(void)showStartScreen {
        CGSize wins = [[CCDirector sharedDirector] winSize];
        startLabel = [CCLabelBMFont labelWithString:@"Starting..." fntFile:@"Font_silver_size17.fnt"];
        [startLabel setPosition:ccp(wins.width/2.0, wins.height/2.0)];
        ccColor4B c = {0,0,0,200};
        startLayer = [CCLayerColor layerWithColor:c];
        [self addChild:startLayer z:21];
        [startLayer addChild:startLabel];
    }

The above code adds a slight transparent layer on top of our game showing the message "Starting..."

Add the followng to end of ``init`` method of ``HelloWorldLayer.m``:

.. code-block:: obj-c

    [self showStartScreen];
    // Retrieve GamoogaClient instance from Multiplayer singleton class
    GamoogaClient *gc = [[Multiplayer sharedInstance] getGc];
    // Add a callback to be called on receiving the "join" message
    [gc onMessageCallback:@selector(onMPMsgJoin:) withTarget:self forType:@"join"];
    // Connect to room
    [gc connectToRoomWithAppId:0 andAppUuid:@"-any-"];
    [startLabel setString:@"Checking for users..."];

In effect, when the game starts, we are showing the relevant message when connecting to Gamooga. We retrieve the ``GamoogaClient`` instance from ``Multiplayer`` singleton and add a callback to respond to "join" message. We then connect to Gamooga room on the server side.

You can run the project now in simulator, you should see a transparent layer with message "Checking for users...". Also you should see a "GAMOOGA: Connected" message in the console output (Gamooga client emits similar log messages for every event which are highly helpful for you while debugging). Please make sure you have already started Gamooga development server in a Terminal as mentioned in step 7 of `Setup`_.

Your game output should look like:

.. image:: //raw.github.com/gamooga/gamooga-tutorials/master/TurnWars/img/first.png

Also the project output console (Shift+Cmd+c) should look like below:

.. image:: //raw.github.com/gamooga/gamooga-tutorials/master/TurnWars/img/console.png

Server side matchmaking
-----------------------
Now that we are connecting from our game to the server side room, lets add the room code to do the required match making. Create a file called ``room.lua`` in ``TurnWars/gamlet`` directory and add the following code into it:

.. code-block:: lua

    -- store the pending sessions in this array
    sessions_pending = {}

    -- callback called when a new user connects to room
    -- conn_id is the connection identifier
    gamooga.onconnect(function(conn_id)
        -- if there is no session pending
        if sessions_pending[1] == nil then
            -- send a "join" message to connecting user with data '-1'
            -- meaning that there is no pending session and he should create new
            gamooga.send(conn_id, "join", -1)
        else
        -- if there is a session pending
            -- pop the session id from the pending list
            sess_id = table.remove(sessions_pending, 1)
            -- and send it as part to the "join" message to the user
            gamooga.send(conn_id, "join", sess_id)
        end
    end)

    -- callback called when a 'create' message is sent from a session to room
    -- sess_id is the session id of the session which sent the message
    -- (ignore the second variable _ )
    gamooga.onsessionmsg("create", function(sess_id, _)
        -- this message is sent when a new session is created which is waiting for
        -- another user, hence we add the sess_id to pending session list
        table.insert(sessions_pending, sess_id)
    end)

In the above code, as soon a user connects, the function passed to gamooga.onconnect is called. In that callback, we check if there is a session pending in session_pending list. If not, we send the current user a "join" message with -1 as the data. If there is a pending session, we send the current user a "join" message with the session id of the waiting session he can join.

Also, when a session sends a "create" message to the room, the function passed to gamooga.onsessionmsg meant for "create" message is called. Session sends this message when a user creates a session and is waiting for a another user to join, as we will see below. Hence we add it to the list of pending sessions.

Client side matchmaking changes
-------------------------------
We now have to capability of simple matchmaking of users on the server side. Server sends a "join" message. We need to respond to "join" message to create a new session or join an already created one. We do that now. Add the following method to ``HelloWorldLayer.m``:

.. code-block:: obj-c

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

In the above code, the session id sent from the server side is received by the above method (remember, we have already added onMPMsgJoin as the selector to be called when "join" message is received). We retrieve the session id and check if its -1, if so we create a new session otherwise connect to the session ``sess_id``. Also add the following methods which are called by above method:

.. code-block:: obj-c

    // Get GamoogaClient and create and connect to a new session
    -(void)mpCreateConnectToSession
    {
        GamoogaClient *gc = [[Multiplayer sharedInstance] getGc];
        [gc createConnectToSessionWithAppId:0 andAppUuid:@"-any-"];
        [self mpAddCallbacks];
    }
    // Get GamoogaClient and connect to the session
    -(void)mpConnectToSession:(int)sess_id
    {
        GamoogaClient *gc = [[Multiplayer sharedInstance] getGc];
        [gc connectToSessionWithSessId:sess_id andAppUuid:@"-any-"];
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

In the above code, we created/connected to a session as required and added callbacks for different messages that we expect to receive from server side session.

Gamooga session
---------------

Lets look at the session part of the server side. The following is the matchmaking part of session. Create a file ``session.lua`` in ``TurnWars/gamlet`` folder and add the following code into it:

.. code-block:: lua

    first_user = nil
    second_user = nil

    -- callback called as soon as a new user connects to the session
    gamooga.onconnect(function(conn_id)
        -- if first user is not nil, implying this is the second user joining
        if first_user ~= nil then
            -- store the second user's connection id
            second_user = conn_id
            -- send a "start" message to both the users with their player ids
            gamooga.send(first_user, "start", 1)
            gamooga.send(second_user, "start", 2)
        else
        -- if its the first user joining the session
            -- store the first user's connection id
            first_user = conn_id
            -- send a "wait" message to the first user since he is waiting for another user
            gamooga.send(first_user, "wait", "")
            -- also send a message to room, to let it know that this session is a pending session
            gamooga.sendtoroom("create", "")
        end
    end)

In the above code we have handled first user and second user joining the session. When first user joins the session, we send him a "wait" message and let the room know that this is a pending session. When a second user joins the session, we send both of them a "start" message along with their player ids to start the game. Now lets handle these messages on the client side.

"wait" and "start" messages on client side
------------------------------------------

We need to know the player id of user for move control and proper game play. Add ``@property`` to ``HelloWorldLayer.h``:

.. code-block:: obj-c

    @property (nonatomic, readwrite) int myPlayerId;

and also the private variable ``myPlayerId`` to ``HelloWorldLayer.h``:

.. code-block:: obj-c

    int myPlayerId;

Add a ``@synthesize`` at the top of ``HelloWorldLayer.m`` for this property:

.. code-block:: obj-c

    @synthesize myPlayerId;

Add the following methods to ``HelloWorldLayer.m`` (Please note that we have already specified them as callbaks for messages in "mpAddCallbacks" method above):

.. code-block:: obj-c

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

The first callback ``onMPMsgWait`` which runs at the first user who is waiting for another user, we just change the start label to contain appropriate message. The next callback ``onMPMsgStart`` is executed in response to the "start" message from the server. Please note that both users are sent the "start" message and we need to do the right thing at each user, let the first user know that its his turn and let the second user know that its not his turn. We use ``playerTurn`` to figure that out. At start of game ``playerTurn`` is 1 indicating its first user's turn. Also, we set ``myPlayerId`` to 1 at first user and 2 at second user. So we check if ``playerTurn`` is equal to ``myPlayerId`` to determine first and second user and do things appropriately.

At this point you can test the game with two players. Start one instance on simulator and the other on actual device. You can see that first user will wait for a second user and once second user joins, game starts at both the users.

    NOTE: Since the device also needs to connect to the development server, change the IP address argument of ``initWithDevServer`` in ``Multiplayer.m`` to an IP that is reachable by the device too, may be your local LAN IP of the development server.

Now that the game has started, we need to handle moves at each user.

Handle moves
------------

Add the following if at the top of ``CCTouchBegan`` method in ``Unit.m``:

.. code-block:: obj-c

    // Handle touches
    -(BOOL)ccTouchBegan:(UITouch *)touch withEvent:(UIEvent *)event {
        // If its not the player's turn disallow the move               // *** added ***
        if ([theGame myPlayerId] != [theGame playerTurn]) {             // *** added ***
            return NO;                                                  // *** added ***
        }                                                               // *** added ***
        // Was a unit belonging to the non-active player touched? If yes, do not handle the touch
        ...
    }

The above code rejects touch if its not user's turn.

Now we need to transmit the move from the valid user to the other user. He selects the unit, moves to another square and hits 'Stay'. As soon as he hits Stay, we want the other user to receive the move. Change ``doStay`` method of ``Unit.m`` as below to achieve it:

.. code-block:: obj-c

    // Stay on the current tile
    -(void)doStay {
        ...
        [theGame unselectUnit];
        [theGame sendMoveOfUnit:self]; // *** added ***
        // 3 - Check for victory conditions
        ...
    }

We added a line calling the method ``sendMoveOfUnit`` of ``HelloWorldLayer``. Add a method declaration into ``HelloWorldLayer.h``:

.. code-block:: obj-c

    -(void)sendMoveOfUnit:(Unit *)unit;

and the method body into ``HelloWorldLayer.m``:

.. code-block:: obj-c

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

We are determining the units of the player who made the move and are sending the index of moved unit in the set of units and the final position of the unit in tile coordinates to server. Now handle the message of type "move" on the server side. Add the following to ``session.lua`` anywhere:

.. code-block:: lua

    -- Callback executed when a message of type "move" is received from client
    -- the second argument is the dictionary sent from the client side
    gamooga.onmessage("move", function(conn_id, move)
        -- if we received the message from first user
        if first_user == conn_id then
            -- send the same dictionary received to the second user
            gamooga.send(second_user, "move", move)
        else
            -- else (we received the message from second user), send the dictionary to the first user
            gamooga.send(first_user, "move", move)
        end
    end)

What the above code does is pretty simple: if we receive the "move" message from first user, send it to the second user and vice versa.

Handling other user's move
--------------------------
In the above section, one user made the move and we sent it to the server and the server in turn sent it to the other user. Hence the other user receives a "move" message from server with the move data. We need use this data and show the move. Fill up the ``onMPMsgmove`` method (remember, we already added that to be executed when a "move" message is received in ``mpAddCallbacks`` above):

.. code-block:: obj-c

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

In the above code, we determine the set of units whose unit is moved. We assign to ``units`` the set of units of the other player. And determine the unit to be moved using the index sent in the message. And then move the unit to the required position using the coordinates in the message.

``doMarkedMovement`` in ``Unit.m`` also displays a "Stay","Cancel" menu after movement, which should not happen at this user since its not his move. So in ``popStepAndAnimate`` in ``Unit.m`` make changes as below:

.. code-block:: obj-c

    -(void)popStepAndAnimate {  
        ...
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
        ...
    }

We embed part of the code that is responsible for detecting possible attack and showing the menu with in an 'if' condition which is true only at the owner of the unit. Hence now the menu doesnot show up when we are showing the other user's move.

At this point, you should be able to make a move at one user and see it at another user. Multiplayer in action! Just start two instances - one in simulator and other in actual device - and you should be able to test it.

Handling end turn
-----------------
User moves as many units as he wants and finally hits 'End turn'. We need to comminicate 'End Turn' to other user too. Change ``doEndTurn`` to add lines shown below:

.. code-block:: obj-c

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
        ...
    }

We just send the message of type "endturn" to the server. On server side in session, we receive "endturn" and send it to the other user. Add the following to ``session.lua``:

.. code-block:: lua

    -- on receiving "endturn" send the message to other user
    gamooga.onmessage("endturn", function(conn_id, _)
        if first_user == conn_id then
            gamooga.send(second_user, "endturn", _)
        else
            gamooga.send(first_user, "endturn", _)
        end
    end)

At the other user on client side, on receiving "endturn" message we execute ``onMPMsgEndturn`` as specified in ``mpAddCallbacks``. We will now fill up the ``onMPMsgEndturn`` method:

.. code-block:: obj-c

    -(void)onMPMsgEndturn:(id)_
    {
        [self doEndTurn];
    }

We just call doEndTurn.

Essentially what is happening is - when one user ends his turn, ``doEndTurn`` is called, in ``doEndTurn`` we send a "endturn" message to server, the server in turn sends "endturn" to the other user and at the other user ``doEndTurn`` is called. Effectively we called ``doEndTurn`` at both users.

You might be wondering why the ``if (myPlayerId == playerTurn)`` in ``doEndTurn`` was required. Please understand that in the above method with out the if, when ``doEndTurn`` is called at one user it also triggers ``doEndTurn`` at other user. Hence the following endless loop is possible:

    ``doEndTurn`` at first user -> "endturn" message at server -> "endturn" message at second user -> ``doEndTurn`` at second user -> "endturn" message at server -> "endturn" message at first user -> ``doEndTurn`` at first user ... (infinite loop)

That 'if' breaks the loop after ``doEndTurn`` is called once at both users.

Also change the following methods in ``HelloWorldLayer.m``:

``setPlayerTurnLabel``:

.. code-block:: obj-c

    // Set the turn label to display the current turn
    -(void)setPlayerTurnLabel {
        // Set the label value for the current player
        //[turnLabel setString:[NSString stringWithFormat:@"Player %d's turn",playerTurn]]; // *** commented ***
        if (playerTurn == myPlayerId) {                                                     // *** added ***
            [turnLabel setString:@"Your turn"];                                             // *** added ***
            [endTurnBtn setVisible:YES];                                                    // *** added ***
        } else {                                                                            // *** added ***
            [turnLabel setString:@"Other player's turn"];                                   // *** added ***
            [endTurnBtn setVisible:NO];                                                     // *** added ***
        }                                                                                   // *** added ***
        // Change the label colour based on the player
        ...
    }

``showEndTurnTransition``:

.. code-block:: obj-c

    // Fancy transition to show turn switch/end
    -(void)showEndTurnTransition {
        ...
        // Add a label showing the player turn to the black layer
        //CCLabelBMFont * turnLbl = [CCLabelBMFont labelWithString:[NSString stringWithFormat:@"Player %d's turn",playerTurn] fntFile:@"Font_silver_size17.fnt"];
                                                                            // *** commented above line ***
        CCLabelBMFont *turnLbl = [CCLabelBMFont labelWithString: [NSString stringWithFormat:(playerTurn == myPlayerId)?@"Your turn":@"Other player's turn"] fntFile:@"Font_silver_size17.fnt"];
                                                                            // *** added above line ***
        [layer addChild:turnLbl];
        ...
    }

The above code changes just makes sure proper messages are shown and "End turn" is shown and hidden properly.

Also the top left turn information is not properly displayed. Lets make it proper, make the following changes in ``addMenu`` method in ``HelloWorldLayer.m``:

.. code-block:: obj-c

    // Add the user turn menu
    -(void)addMenu {
        ...
        [self addChild:turnLabel];
        [turnLabel setPosition:ccp(5,wins.height-[hud boundingBox].size.height/2)]; // *** changed ***
        [turnLabel setAnchorPoint:ccp(0,0.5)];                                      // *** added ***
        // Set the turn label to display the current turn
        ...
    }

At this point you should be able to make moves in one user, end turn at one user and make moves at the other user and end his turn too. All the game is functional except handling of attacks. Just start two instances - one simulator, one device - and experience real multiplayer in action!

Handling attacks
----------------

Implementation of handling attacks has become a bit convuluted given the way original code was written. Hence you will see hacky ways of getting the attacks functional across users. Feel free to skip this part and go to `Deployment`_ section, there is nothing new as far as usage of Gamooga is concerned, its very similar to handling of moves.

Change ``doMarkedAttack`` to following in ``Unit.m``:

.. code-block:: obj-c

    -(void)doMarkedAttack:(TileData *)targetTileData {
        ...
        [attackedUnit attackedBy:self firstAttack:YES];
        // Keep this unit in the curren location
        //[self doStay];                                                  // *** commented ***
        [self doStayWithMPSend:NO];                                       // *** added ***
        if ([theGame myPlayerId] == self.owner) {                         // *** added ***
            [theGame sendMoveAndAttackOfUnit:self attacked:attackedUnit]; // *** added ***
        }                                                                 // *** added ***
    }

``doMarkedAttack`` is the method called when a user attacks other user. Hence in this method, we send the move and attack information to the other user. Also note that this method also calls ``doStay`` which also sends move message to other user which we need to avoid, so change ``doStay`` like below:

.. code-block:: obj-c

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
            [theGame sendMoveOfUnit:self];
        }                                     // *** added ***
        ...
    }

We changed ``doStay`` method into ``doStayWithMPSend:(BOOL)toSend`` and added an ``if (toSend)`` around ``[theGame sendMoveOfUnit:self]`` to prevent sending message if ``toSend`` is false. Also added a ``doStay`` method to call ``doStayWithMPSend`` with YES to imitate the original behavior. Essentially we added a ``doStay`` function with ability to bypass sending the "move" message to server.

Now lets add ``sendMoveAndAttackOfUnit:attacked:`` method called in ``doMarkedAttack`` above to ``HelloWorldLayer`` to send the attack and move information to other player.

Add the following method signature to ``HelloWordLayer.h``:

.. code-block:: obj-c

    -(void)sendMoveAndAttackOfUnit:(Unit *)unit attacked:(Unit *)attackedUnit;

And add the following method body to ``HelloWorldLayer.m``:

.. code-block:: obj-c

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

Similar to ``sendMoveOfUnit``, this method extracts the final positions of unit and the index of the unit along with the tile coordinates of the attack to the server in a "moveattack" message. The server in turn sends them to the other user. Add the following to ``session.lua``:

.. code-block:: lua

    gamooga.onmessage("moveattack", function(conn_id, move)
        if first_user == conn_id then
            gamooga.send(second_user, "moveattack", move)
        else
            gamooga.send(first_user, "moveattack", move)
        end
    end)

Now we need to handle the "moveattack" data at the other user. Add the method ``onMPMsgMoveattack`` which has already been specified as the callback to "moveattack" message:

.. code-block:: obj-c

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
        // [unit doMarkedAttack:atd]; // (calling move and attach like this indicidually doesnot suffice)
        // move and then attack after move is complete
        [unit doMarkedMovement:td withCallback:@selector(doMarkedAttack:) ofObject:unit data:atd];
    }

In the above method, we retrieve the tile to move to, tile to fire on and then the unit. We can move to the final tile using ``doMarkedMovement``, but then we also need to call ``doMarkedAttack`` after move animation is complete. Its not possible by just calling:

.. code-block:: obj-c

    [unit doMarkedMovement:td];
    [unit doMarkedAttack:atd];

This will attack but you will see the fire animation while the movement is going on which is not what we want. Hence we add a method ``doMarkedMovement:withCallback:ofObject:data:`` to ``Unit.m`` to add the ability to call a method after the move animation is complete. Add a method declaration to ``Unit.h``:

.. code-block:: obj-c

    -(void)doMarkedMovement:(TileData *)targetTileData withCallback:(SEL)cb ofObject:(id)obj data:(id)data;

Now change ``doMarkedMovement`` in ``Unit.m`` like below:

.. code-block:: obj-c

    -(void)doMarkedMovement:(TileData *)targetTileData {
        [self doMarkedMovement:targetTileData withCallback:nil ofObject:nil data:nil];                          // *** added ***
    }                                                                                                           // *** added ***
                                                                                                                // *** added ***
    -(void)doMarkedMovement:(TileData *)targetTileData withCallback:(SEL)cb ofObject:(id)obj data:(id)data {    // *** added ***
        if (moving)
            return;
        ...
        do {
            ...
            if (CGPointEqualToPoint(_currentTile.position, targetTileData.position)) {
                //[self constructPathAndStartAnimationFromStep:_currentTile];                                      // *** commented ***
                [self constructPathAndStartAnimationFromStep:_currentTile withCallback:cb ofObject:obj data:data]; // *** added ***
                ...
            }
            ...
        } while (...);
    }

With the above change we are just passing along ``cb``,``obj`` and ``data`` passed to ``doMarkedMovement`` to ``constructPathAndStartAnimationFromStep``. Now change ``constructPathAndStartAnimationFromStep`` like below:

.. code-block:: obj-c

    //-(void)constructPathAndStartAnimationFromStep:(TileData *)tile {                                                   // *** commented ***
    -(void)constructPathAndStartAnimationFromStep:(TileData *)tile withCallback:(SEL)cb ofObject:(id)obj data:(id)data { // *** added ***
        ...
        } while (tile != nil); 
        if (obj != nil) {                                                                                      // *** added ***
            [self runAction:[CCSequence actions:[CCDelayTime actionWithDuration:0.4*[movementPath count]+0.1], // *** added ***
                             [CCCallFuncO actionWithTarget:obj selector:cb object:data],nil]];                 // *** added ***
        }                                                                                                      // *** added ***
        [self popStepAndAnimate];
    }

We change the method to call the passed callback after the move animation is complete. Note that move animation takes 0.4*[movementPath*count] seconds (check popStepAndAnimate method for this) and hence we set up the callback to be called after 0.4*[movementPath*count] + 0.1 seconds.

The callback we send to doMarkedMovement is ``doMarkedAttack`` and hence it is called after move animation is complete and we now see the fire animation at appropriate time.

NOTE: ``popStepAndAnimate`` function is responsible for movement of units. One ``popStepAndAnimate`` schedules itself to be called until all steps are called. A better way to implement fire animation would have been to have it execute after all ``popStepAndAnimate`` methods are executed. But to carry the ``cb``,``obj`` and ``data`` across the multiple invocations appeared to be more hacky than using delay to time the fire animation. Hence the above implementation.

Now we have the real multiplayer game fully ready: moves, attacks and endturns work perfectly at both the users. Time to deploy in cloud!

Deployment
----------

1. Register on Gamooga's website
2. Login
3. Click on 'My Gamlets' in the top menu
4. Zip the ``gamlet`` folder and upload it by clicking 'Upload new gamlet' in 'My Gamlets' page
5. Now that the gamlet is uploaded, note the gamlet id and uuid from its dashboard
6. In ``HelloWordLayer.m``, change your ``connectToRoom`` and ``createConnectToSession`` method arguemnts to use the noted id and uuid
7. Also change ``connectToSession`` uuid argument to use the noted uuid
8. Change ``getGc`` method of ``Multiplayer.m`` to initialize GamoogaClient as: ``gc = [[GamoogaClient alloc] init];`` instead of ``gc = [[GamoogaClient alloc] initWithDevServer:@"a.b.c.d"];``

Done! Run your game now and it connects to Gamooga cloud instead of your development server.

    NOTE: To have your game connect to development server, just revert the 8th step. You need not change the id and uuid arguments.

Queries
-------
If you have any queries, please file an issue into the repository so anyone can respond to it. If you want to contact us you can mail us at: support [at] gamooga [dot] com
