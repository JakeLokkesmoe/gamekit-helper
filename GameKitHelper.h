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
