//
//  MyScene.m
//  SimpleFlappyBird
//
//  Created by Ashish Chandwani on 3/10/14.
//  Copyright (c) 2014 Ashish Chandwani. All rights reserved.
//

#import "MyScene.h"

@interface MyScene() {
    SKSpriteNode* _bird;
}
@end

@implementation MyScene

-(id)initWithSize:(CGSize)size {    
    if (self = [super initWithSize:size]) {
        /* Setup your scene here */
        SKTexture* birdTexture1 = [SKTexture textureWithImageNamed:@"Bird1"];
        birdTexture1.filteringMode = SKTextureFilteringNearest;
        
        _bird = [SKSpriteNode spriteNodeWithTexture:birdTexture1];
        [_bird setScale:2.0];
        _bird.position = CGPointMake(self.frame.size.width / 4, CGRectGetMidY(self.frame));
        [self addChild:_bird];
    }
    return self;
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    /* Called when a touch begins */

    
}

-(void)update:(CFTimeInterval)currentTime {
    /* Called before each frame is rendered */
}

@end
