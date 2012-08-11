//
//  Building.h
//  TurnWars
//
//  Created by Fahim Farook on 27/4/12.
//  Copyright (c) 2012 RookSoft Pte. Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"
#import "HelloWorldLayer.h"
#import "GameConfig.h"

@class HelloWorldLayer;

@interface Building : CCNode {
    HelloWorldLayer *theGame;
    CCSprite *mySprite;
    int owner;
}

@property (nonatomic,assign)CCSprite *mySprite;
@property (nonatomic,readwrite) int owner;

-(void)createSprite:(NSMutableDictionary *)tileDict;

@end
