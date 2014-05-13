# GameKit Helper

This project is a simple GameKit helper class created for a cocos2d iOS game.

## Features

* Simple interface for working with a leaderboard and achievements
* Loads a friends list that can be used to display personalized leaderboards
  or alert the player when he/she has pasesd a friends highscore.

### Future Plans

In the future I plan to add support for:

* Multiple Leaderboards
* Challenges

## How To Use

In your game controller, conform to the protocol `GameKitHelperProtocol`
``` objective-c
@interface GameController : CCScene <GameKitHelperProtocol>
``` 

Then during setup call:
``` objective-c
GKLocalPlayer* localPlayer = [GKLocalPlayer localPlayer];
GameKitHelper *gkHelper = [GameKitHelper sharedGameKitHelper];
gkHelper.delegate = self;
if (localPlayer.authenticated) {
    [gkHelper getScoresAndAlias];
    [gkHelper loadAchievements];
}
else {
    [gkHelper authenticateLocalPlayer];
}
```

Now all you have left to do is provide the implementations for the `GameKitHelperProtocol` methods inside of the implementation of your game controller.
``` objective-c
#pragma mark GameKitHelper delegate methods
-(void) onLocalPlayerAuthenticationChanged {
    GKLocalPlayer* localPlayer = [GKLocalPlayer localPlayer];
    CCLOG(@"LocalPlayer isAuthenticated changed to: %@", localPlayer.authenticated ? @"YES" : @"NO");
   
    if (localPlayer.authenticated) {
        GameKitHelper* gkHelper = [GameKitHelper sharedGameKitHelper];
        [gkHelper getScoresAndAlias];
        [gkHelper loadAchievements];
    }
}

-(void) onScoresAndAliasForLeaderboardReceived:(NSDictionary*) playerScores {
   CCLOG(@"onScoresAndAliasForLeaderboardReceived: %@", [playerScores description]);
    _playerScores = playerScores;
    _highscore = 0;
    [self displayScore];
}

-(void) onFriendListReceived:(NSArray*)friends {
    CCLOG(@"onFriendListReceived: %@", [friends description]);
    [[GameKitHelper sharedGameKitHelper] getPlayerInfo:friends];
}

-(void) onPlayerInfoReceived:(NSArray*)players {
    CCLOG(@"onPlayerInfoReceived: %@", [players description]);
}

-(void) onScoresSubmitted:(bool)success {
    CCLOG(@"onScoresSubmitted: %@", success ? @"YES" : @"NO");
}

-(void) onScoresReceived:(NSArray*)scores {
    CCLOG(@"onScoresReceived: %@", [scores description]);
}

-(void) onLocalPlayerScoreReceived:(GKScore*)score {
    CCLOG(@"onLocalPlayerScoreReceived: %lld", score.value);
    _highscore = score.value;
    [self displayScore];
}

-(void) onLeaderboardViewDismissed {
    CCLOG(@"onLeaderboardViewDismissed");
}

-(void) onAchievementsViewDismissed {
    CCLOG(@"onAchievementsViewDismissed");
}
```
