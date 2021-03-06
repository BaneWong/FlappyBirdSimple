//
//  MyScene.m
//  SimpleFlappyBird
//
//  Created by Ashish Chandwani on 3/10/14.
//  Copyright (c) 2014 Ashish Chandwani. All rights reserved.
//

#import "MyScene.h"


@interface MyScene() <SKPhysicsContactDelegate> {
    SKSpriteNode* _bird;
    SKColor* _skyColor;
    SKTexture* _pipeTexture1;
    SKTexture* _pipeTexture2;
    SKAction* _moveAndRemovePipes;
    SKNode* _moving;
    SKNode* _pipes; // parent for all pipe nodes
    SKLabelNode* _scoreLabelNode;
    NSInteger _score;
    BOOL _canRestart;
}
@end



@implementation MyScene

// Colliison detection bitmasks
static const uint32_t birdCategory  = 1 << 0; // 0001
static const uint32_t worldCategory = 1 << 1; // 0010
static const uint32_t pipeCategory  = 1 << 2; // 0100
static const uint32_t scoreCategory = 1 << 3; // 1000

// Parallax scrolling speed constants
static const float SKYLINE_MOVEMENT_SCALE = 0.01;
static const float GROUND_MOVEMENT_SCALE = 0.02;


// Sky color constant
static const float SKY_RED = 113.0/255.0;
static const float SKY_GREEN = 197.0/255.0;
static const float SKY_BLUE = 207.0/255.0;

// default flappybird impulse when touched
static const float TOUCH_IMPULSE = 6;

static NSInteger const kVerticalPipeGap = 100;

-(id)initWithSize:(CGSize)size {
    if (self = [super initWithSize:size]) {
        _canRestart = NO;
        self.physicsWorld.gravity = CGVectorMake(0.0, -5.0); // Set gravity
        self.physicsWorld.contactDelegate = self; // handle collisions
        
        // Setup sky
        _skyColor = [SKColor colorWithRed:SKY_RED green:SKY_GREEN blue:SKY_BLUE alpha:1.0];
        [self setBackgroundColor:_skyColor];
        
        // Dummy parent to stop moving entitites
        _moving = [SKNode node];
        [self addChild:_moving];
        
        _pipes = [SKNode node];
        [_moving addChild:_pipes];
        
        // Create ground
        SKTexture* groundTexture = [SKTexture textureWithImageNamed:@"Ground"];
        groundTexture.filteringMode = SKTextureFilteringNearest;
        
        // Ground animation for movement
        SKAction* moveGroundSprite = [SKAction moveByX:-groundTexture.size.width*2 y:0 duration:GROUND_MOVEMENT_SCALE * groundTexture.size.width*2];
        SKAction* resetGroundSprite = [SKAction moveByX:groundTexture.size.width*2 y:0 duration:0]; // instantly reset position
        SKAction* moveGroundSpritesForever = [SKAction repeatActionForever:[SKAction sequence:@[moveGroundSprite, resetGroundSprite]]];
        
        for (int i = 0; i < 2 + self.frame.size.width / (groundTexture.size.width * 2); ++i) {

            // Add some ground sprites
            SKSpriteNode* groundSprite = [SKSpriteNode spriteNodeWithTexture:groundTexture];
            [groundSprite setScale:2.0];
            groundSprite.position = CGPointMake(i * groundSprite.size.width, groundSprite.size.height / 2);
            [groundSprite runAction:moveGroundSpritesForever];
            [_moving addChild:groundSprite];
        }
        
        // Create ground physics container
        SKNode* groundContainer = [SKNode node];
        groundContainer.position = CGPointMake(0, groundTexture.size.height);
        groundContainer.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:CGSizeMake(self.frame.size.width, groundTexture.size.height*2)];
        groundContainer.physicsBody.dynamic = NO;
        
        groundContainer.physicsBody.categoryBitMask = worldCategory;
        
        [self addChild:groundContainer];
        
        // Create skyline
        SKTexture* skylineTexture = [SKTexture textureWithImageNamed:@"Skyline"];
        skylineTexture.filteringMode = SKTextureFilteringNearest;
        
        // Skyline animation for movement (different scale for parallax effect)
        SKAction* moveSkylineSprite = [SKAction moveByX:-skylineTexture.size.width*2 y:0 duration:SKYLINE_MOVEMENT_SCALE * skylineTexture.size.width*2];
        SKAction* resetSkylineSprite = [SKAction moveByX:skylineTexture.size.width*2 y:0 duration:0]; // instantly reset position
        SKAction* moveSkylineSpritesForever = [SKAction repeatActionForever:[SKAction sequence:@[moveSkylineSprite, resetSkylineSprite]]];

        
        for (int i = 0; i < 2 + self.frame.size.width / (groundTexture.size.width * 2); ++i) {
            
            // add some skyline sprites
            SKSpriteNode* skylineSprite = [SKSpriteNode spriteNodeWithTexture:skylineTexture];
            [skylineSprite setScale:2.0];
            skylineSprite.zPosition = -20;
            skylineSprite.position = CGPointMake(i * skylineSprite.size.width, skylineSprite.size.height / 2 + groundTexture.size.height * 2);
            [skylineSprite runAction:moveSkylineSpritesForever];
            [_moving addChild:skylineSprite];
        }
        
        [self initScore];
        [self initBird];
        [self initPipes]; // load the pipe textures and action
        

    }
    return self;
}

-(void) initScore {
    _score = 0;
    _scoreLabelNode = [SKLabelNode labelNodeWithFontNamed:@"MarkerFelt-Wide"];
    _scoreLabelNode.position = CGPointMake(CGRectGetMidX(self.frame), 3 * self.frame.size.height / 4);
    _scoreLabelNode.zPosition = 100;
    _scoreLabelNode.text = [NSString stringWithFormat:@"%d", _score];
    [self addChild:_scoreLabelNode];
}

-(void) initBird {
    // Setup bird
    SKTexture* birdTexture1 = [SKTexture textureWithImageNamed:@"Bird1"];
    birdTexture1.filteringMode = SKTextureFilteringNearest;
    SKTexture* birdTexture2 = [SKTexture textureWithImageNamed:@"Bird2"];
    birdTexture2.filteringMode = SKTextureFilteringNearest;
    
    // Cycle through the two flapping images forever
    SKAction* flap = [SKAction repeatActionForever:[SKAction animateWithTextures:@[birdTexture1, birdTexture2] timePerFrame:0.2]];
    _bird = [SKSpriteNode spriteNodeWithTexture:birdTexture1];
    [_bird setScale:2.0];
    _bird.position = CGPointMake(self.frame.size.width / 4, CGRectGetMidY(self.frame));
    [_bird runAction:flap];
    
    // Add physics to bird
    _bird.physicsBody = [SKPhysicsBody bodyWithCircleOfRadius:_bird.size.height / 2];
    _bird.physicsBody.dynamic = YES;
    _bird.physicsBody.allowsRotation = NO;
    
    _bird.physicsBody.categoryBitMask = birdCategory;
    _bird.physicsBody.collisionBitMask = worldCategory | pipeCategory; // the bird may collide with the world or pipes
    _bird.physicsBody.contactTestBitMask = worldCategory | pipeCategory; // notify me of world or pipe collisions
    
    [self addChild:_bird];
}

// load pipe textures and animations
-(void) initPipes {
    _pipeTexture1 = [SKTexture textureWithImageNamed:@"Pipe1"];
    _pipeTexture2 = [SKTexture textureWithImageNamed:@"Pipe2"];
    _pipeTexture1.filteringMode = SKTextureFilteringNearest;
    _pipeTexture2.filteringMode = SKTextureFilteringNearest;
    
    
    // set up pipe movement and removement
    CGFloat distanceToMove = self.frame.size.width + 2 * _pipeTexture1.size.width;
    SKAction* movePipes = [SKAction moveByX:-distanceToMove y:0 duration:0.01 * distanceToMove];
    SKAction* removePipes = [SKAction removeFromParent];
    _moveAndRemovePipes = [SKAction sequence:@[movePipes, removePipes]];
    
    // call spawnPipes regularly
    SKAction* spawn = [SKAction performSelector:@selector(spawnPipes) onTarget:self];
    SKAction* delay = [SKAction waitForDuration:2.0];
    SKAction* spawnThenDelay = [SKAction sequence:@[spawn, delay]];
    SKAction* spawnThenDelayForever = [SKAction repeatActionForever:spawnThenDelay];
    [self runAction:spawnThenDelayForever];
    
}

-(void) spawnPipes {
    SKNode* pipePair = [SKNode node];
    pipePair.position = CGPointMake(self.frame.size.width + _pipeTexture1.size.width, 0);
    pipePair.zPosition = -10;
    
    CGFloat y = arc4random() % (NSInteger) (self.frame.size.height / 3); // random pipe height
    
    SKSpriteNode* pipe1 = [SKSpriteNode spriteNodeWithTexture:_pipeTexture1];
    [pipe1 setScale:2];
    pipe1.position = CGPointMake(0, y);
    pipe1.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:pipe1.size];
    pipe1.physicsBody.dynamic = NO;
    pipe1.physicsBody.categoryBitMask = pipeCategory;
    pipe1.physicsBody.contactTestBitMask = birdCategory;
    
    SKSpriteNode* pipe2 = [SKSpriteNode spriteNodeWithTexture:_pipeTexture2];
    [pipe2 setScale:2];
    pipe2.position = CGPointMake(0, y + pipe1.size.height + kVerticalPipeGap);
    pipe2.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:pipe2.size];
    pipe2.physicsBody.dynamic = NO;
    pipe2.physicsBody.categoryBitMask = pipeCategory;
    pipe2.physicsBody.contactTestBitMask = birdCategory;
    
    [pipePair addChild:pipe1];
    [pipePair addChild:pipe2];
    
    // add a contact node as a child of the pipePair
    SKNode* contactNode = [SKNode node];
    contactNode.position = CGPointMake(pipe1.size.width + _bird.size.width / 2, CGRectGetMidY(self.frame));
    contactNode.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:CGSizeMake(pipe2.size.width, self.frame.size.height)];
    contactNode.physicsBody.dynamic = NO;
    contactNode.physicsBody.categoryBitMask = scoreCategory;
    contactNode.physicsBody.contactTestBitMask = birdCategory;
    [pipePair addChild:contactNode];
    
    [pipePair runAction:_moveAndRemovePipes];
    
    [_pipes addChild:pipePair];
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    /* Called when a touch begins */
    if(_moving.speed > 0) { // only allow input if the world is still moving
        _bird.physicsBody.velocity = CGVectorMake(0, 0); // avoid impulse accumlation per touch
        [_bird.physicsBody applyImpulse:CGVectorMake(0, TOUCH_IMPULSE)];
        
    } else if (_canRestart)  {
        [self resetScene];
    }
    
}

- (void) didBeginContact:(SKPhysicsContact *)contact {
    // Flash background if contact is detected
    if (_moving.speed > 0) {
        
        // Bird has contact with score entitiy
        // the first obj is a scorebox                                         or                    // the second object is a scorebox
        if( ( contact.bodyA.categoryBitMask & scoreCategory ) == scoreCategory || ( contact.bodyB.categoryBitMask & scoreCategory ) == scoreCategory ) {
            _score++;
            _scoreLabelNode.text = [NSString stringWithFormat:@"%d", _score];
            
            // Visual feedback for score increment (animation)
            [_scoreLabelNode runAction:[SKAction sequence:@[[SKAction scaleTo:1.5 duration:0.1], [SKAction scaleTo:1.0 duration:0.1]]]];
             
        } else { // bird collided with world
            
                
            _moving.speed = 0; // stop the world from moving
            _bird.physicsBody.collisionBitMask = worldCategory;
            
            [_bird runAction:[SKAction rotateByAngle:M_PI * _bird.position.y * 0.01 duration:_bird.position.y * 0.003] completion:^{
                _bird.speed = 0;
            }];
        
            [self removeActionForKey:@"flash"];
            
            [self runAction:[SKAction sequence:@[[SKAction repeatAction:[SKAction sequence:@[[SKAction runBlock:^{
                self.backgroundColor = [SKColor redColor];
            }], [SKAction waitForDuration:0.05], [SKAction runBlock:^{
                self.backgroundColor = _skyColor;
            }], [SKAction waitForDuration:0.05]]] count:4], [SKAction runBlock:^{
                _canRestart = YES;
            }]]] withKey:@"flash"];
        }
    }
}

// keeps value within a certain range
CGFloat clamp(CGFloat min, CGFloat max, CGFloat value) {
    if (value > max) {
        return max;
    } else if (value < min) {
        return min;
    } else {
        return value;
    }
}

-(void)update:(CFTimeInterval)currentTime {
    /* Called before each frame is rendered */
    if (_moving.speed > 0) {
    // modify the bird's pitch based on its velocity vector if the bird isn't dying
        _bird.zRotation = clamp( -1, 0.5, _bird.physicsBody.velocity.dy * ( _bird.physicsBody.velocity.dy < 0 ? 0.003 : 0.001 ) );
    }

    
}

- (void) resetScene {
    // Move bird to original position and reset properties
    _bird.position = CGPointMake(self.frame.size.width / 4, CGRectGetMidY(self.frame)); // reset to original position
    _bird.physicsBody.velocity = (CGVectorMake(0, 0));
    _bird.physicsBody.collisionBitMask = worldCategory | pipeCategory;
    _bird.speed = 1.0;
    _bird.zRotation = 0.0;
    
    // Remove all existing pipes
    [_pipes removeAllChildren];
    
    // Reset _canRestart
    _canRestart = NO;
    
    // Restart animation
    _moving.speed = 1;
    
    _score = 0;
    _scoreLabelNode.text = [NSString stringWithFormat:@"%d", _score];
}

@end
