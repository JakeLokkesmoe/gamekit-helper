// Copyright (c) 2014 Jake Lokkesmoe

// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:

// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

#import "cocos2d.h"
#import <GameKit/GameKit.h>

#define LEADERBOARD_IDENTIFIER @"com.companyname.category.leaderboard"

@protocol GameKitHelperProtocol

-(void) onLocalPlayerAuthenticationChanged;

-(void) onFriendListReceived:(NSArray*)friends;
-(void) onPlayerInfoReceived:(NSArray*)players;

-(void) onScoresSubmitted:(bool)success;
-(void) onScoresReceived:(NSArray*)scores;
-(void) onLocalPlayerScoreReceived:(GKScore*)score;
-(void) onScoresAndAliasForLeaderboardReceived:(NSDictionary*) playerScores;

-(void) onLeaderboardViewDismissed;
-(void) onAchievementsViewDismissed;

@end


@interface GameKitHelper : NSObject <GKLeaderboardViewControllerDelegate, GKAchievementViewControllerDelegate> {
   id<GameKitHelperProtocol> delegate;
}

@property (nonatomic, readonly) bool isGameCenterAvailable;
@property (nonatomic, readonly) NSError* lastError;
@property (nonatomic, retain, readonly) NSMutableDictionary* achievementsDictionary;

+(GameKitHelper*) sharedGameKitHelper;

-(void)setDelegate:(id<GameKitHelperProtocol>)newDelegate;

// Player authentication, info
-(void) authenticateLocalPlayer;
-(void) getLocalPlayerFriends;
-(void) getPlayerInfo:(NSArray*)players;

// Scores
-(void) submitScore:(int64_t)score category:(NSString*)category;
-(void) getLocalPlayerHighScore;
-(void) getScoresAndAlias;
-(void) getScoresAndAliasForLeaderboard:(GKLeaderboard *)leaderboardRequest;

// Achievements
-(void) loadAchievements;
-(GKAchievement*) getAchievementForIdentifier:(NSString*) identifier;
-(void) reportAchievementIdentifier:(NSString*) identifier percentComplete: (float) percent;
-(void) resetAchievements;

// Game Center Views
-(void) showLeaderboard;
-(void) showAchievements;

@end
