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

#import "GameKitHelper.h"
#import "GCLeaderboardScore.h"

static NSString* kCachedAchievementsFile = @"CachedAchievements.archive";

@implementation GameKitHelper
@synthesize isGameCenterAvailable;
@synthesize lastError;
@synthesize achievementsDictionary;

static GameKitHelper *instanceOfGameKitHelper;

#pragma mark Singleton stuff
+(id) alloc {
   @synchronized(self) {
      NSAssert(instanceOfGameKitHelper == nil, @"Attempted to allocate a second instance of the singleton: GameKitHelper");
      instanceOfGameKitHelper = [super alloc];
      return instanceOfGameKitHelper;
   }
   // to avoid compiler warning
   return nil;
}

+(GameKitHelper*) sharedGameKitHelper {
   @synchronized(self) {
      if (instanceOfGameKitHelper == nil) {
         instanceOfGameKitHelper = [[GameKitHelper alloc] init];
      }
      return instanceOfGameKitHelper;
   }
   // to avoid compiler warning
   return nil;
}

#pragma mark Init & Dealloc

-(id) init {
   if ((self = [super init])) {
      achievementsDictionary = [[NSMutableDictionary alloc] init];
      
      // Test for Game Center availability
      Class gameKitLocalPlayerClass = NSClassFromString(@"GKLocalPlayer");
      bool isLocalPlayerAvailable = (gameKitLocalPlayerClass != nil);
      
      // Test if device is running iOS 4.1 or higher
      NSString* reqSysVer = @"4.1";
      NSString* currSysVer = [[UIDevice currentDevice] systemVersion];
      bool isOSVer41 = ([currSysVer compare:reqSysVer options:NSNumericSearch] != NSOrderedAscending);
      
      isGameCenterAvailable = (isLocalPlayerAvailable && isOSVer41);
      NSLog(@"GameCenter available = %@", isGameCenterAvailable ? @"YES" : @"NO");
        
      [self registerForLocalPlayerAuthChange];
   }
   
   return self;
}

-(void) dealloc {
   CCLOG(@"dealloc %@", self);
   instanceOfGameKitHelper = nil;
   [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(void)setDelegate:(id<GameKitHelperProtocol>)newDelegate {
   delegate = newDelegate;
}

#pragma mark setLastError

-(void) setLastError:(NSError*)error {
   lastError = [error copy];
   
   if (lastError) {
      NSLog(@"GameKitHelper ERROR: %@", [[lastError userInfo] description]);
   }
}

#pragma mark Player Authentication

-(void) authenticateLocalPlayer {
   if (isGameCenterAvailable == NO)
      return;
    
   GKLocalPlayer* localPlayer = [GKLocalPlayer localPlayer];
   if (localPlayer.authenticated == NO) {
      [localPlayer authenticateWithCompletionHandler:^(NSError* error)
         {
            [self setLastError:error];
            if (error == nil)
            {
                
            }
         }];
   }
}

-(void) onLocalPlayerAuthenticationChanged {
   [delegate onLocalPlayerAuthenticationChanged];
}

-(void) registerForLocalPlayerAuthChange {
   if (isGameCenterAvailable == NO)
      return;
    
   // Register to receive notifications when local player authentication status changes
   NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
   [nc addObserver:self
         selector:@selector(onLocalPlayerAuthenticationChanged)
            name:GKPlayerAuthenticationDidChangeNotificationName
          object:nil];
}

#pragma mark Friends & Player Info

-(void) getLocalPlayerFriends {
   if (isGameCenterAvailable == NO)
      return;
   
   GKLocalPlayer* localPlayer = [GKLocalPlayer localPlayer];
   if (localPlayer.authenticated) {
      // First, get the list of friends (player IDs)
      [localPlayer loadFriendsWithCompletionHandler:^(NSArray* friends, NSError* error)
         {
             [self setLastError:error];
             [delegate onFriendListReceived:friends];
         }];
   }
}

-(void) getPlayerInfo:(NSArray*)playerList {
   if (isGameCenterAvailable == NO)
      return;
    
   // Get detailed information about a list of players
   if ([playerList count] > 0) {
      [GKPlayer loadPlayersForIdentifiers:playerList withCompletionHandler:^(NSArray* players, NSError* error)
         {
             [self setLastError:error];
             [delegate onPlayerInfoReceived:players];
         }];
   }
}

#pragma mark Scores & Leaderboard

-(void) submitScore:(int64_t)score category:(NSString*)category
{
   if (isGameCenterAvailable == NO)
      return;
    
   GKScore* gkScore = [[GKScore alloc] initWithCategory:category];
   gkScore.value = score;
    
   [gkScore reportScoreWithCompletionHandler:^(NSError* error)
     {
         [self setLastError:error];
         
         bool success = (error == nil);
         [delegate onScoresSubmitted:success];
     }];
}

-(void) getLocalPlayerHighScore {
   if (isGameCenterAvailable == NO)
      return;
   
   GKLeaderboard *leaderboard = [[GKLeaderboard alloc] init];
   leaderboard.playerScope = GKLeaderboardPlayerScopeGlobal;
   if (leaderboard != nil) {
      leaderboard.timeScope = GKLeaderboardTimeScopeAllTime;
      leaderboard.category = LEADERBOARD_IDENTIFIER;
      leaderboard.range = NSMakeRange(1, 10);
      
      [leaderboard loadScoresWithCompletionHandler:^(NSArray* scores, NSError* error)
       {
          [self setLastError:error];
          [delegate onLocalPlayerScoreReceived:leaderboard.localPlayerScore];
       }];
   }
}

-(void) getScoresAndAlias {
   [self getScoresAndAliasForLeaderboard:nil];
}

-(void) getScoresAndAliasForLeaderboard:(GKLeaderboard *)leaderboardRequest {
   NSMutableDictionary * playerScores = [[NSMutableDictionary alloc] init];
   
   if (leaderboardRequest == nil) {
      leaderboardRequest = [[GKLeaderboard alloc] init];
      leaderboardRequest.playerScope = GKLeaderboardPlayerScopeFriendsOnly;
      leaderboardRequest.timeScope = GKLeaderboardTimeScopeAllTime;
      leaderboardRequest.category = LEADERBOARD_IDENTIFIER;
      leaderboardRequest.range = NSMakeRange(1,100);
   }
   
   [leaderboardRequest loadScoresWithCompletionHandler: ^(NSArray *scores, NSError *error) {
      if (error != nil)
         [self setLastError:error];
      if (scores != nil) {
         NSMutableArray *retrievePlayerIDs = [[NSMutableArray alloc] init];
         GCLeaderboardScore *me;
         
         for (GKScore *s in scores) {
            [retrievePlayerIDs addObject:s.playerID];
            
            GCLeaderboardScore *playerScore = [[GCLeaderboardScore alloc] init];
            playerScore.playerID = s.playerID;
            playerScore.score = (int)s.value;
            playerScore.rank = s.rank;
            playerScores[s.playerID] = playerScore;
            
            if ([s.playerID isEqualToString: leaderboardRequest.localPlayerScore.playerID])
               me = playerScore;
         }
         
         if (me == nil) {
            me = [[GCLeaderboardScore alloc] init];
            me.playerID = leaderboardRequest.localPlayerScore.playerID;
            me.score = leaderboardRequest.localPlayerScore.value;
            me.alias = @"Me";
            
            playerScores[me.playerID] = me;
         }
         
         [GKPlayer loadPlayersForIdentifiers:retrievePlayerIDs withCompletionHandler:^(NSArray *playerArray, NSError *error) {
            if (error != nil)
               [self setLastError:error];
            
             for (GKPlayer* p in playerArray) {
                GCLeaderboardScore *playerScore = playerScores[p.playerID];
                
                playerScore.alias = p.alias;
                
                [p loadPhotoForSize:GKPhotoSizeSmall withCompletionHandler:^(UIImage *photo, NSError *error) {
                   
                   if (photo != nil)
                      playerScore.photo = photo;
                   else
                      playerScore.photo = [UIImage imageNamed:@"wordpress_avatar.jpg"];
                      
                   if (error != nil)
                      NSLog(@"Could not load photo for player: %@", p.playerID);
                }];
             }
             
             [delegate onScoresAndAliasForLeaderboardReceived:playerScores];
          }];
      }
   }];
}

#pragma mark Achievements
-(void) loadAchievements
{
   [GKAchievement loadAchievementsWithCompletionHandler:^(NSArray *achievements, NSError *error)
      {
         if (error == nil) {
            for (GKAchievement* achievement in achievements) {
               achievement.showsCompletionBanner = YES;
               [achievementsDictionary setObject:achievement forKey:achievement.identifier];
            }
         }
         else
            [self setLastError:error];
      }];
}

-(GKAchievement*) getAchievementForIdentifier:(NSString*) identifier {
   GKAchievement *achievement = [achievementsDictionary objectForKey:identifier];
   if (achievement == nil) {
      achievement = [[GKAchievement alloc] initWithIdentifier:identifier];
      achievement.showsCompletionBanner = YES;
      [achievementsDictionary setObject:achievement forKey:identifier];
   }
   
   return achievement;
}

- (void) reportAchievementIdentifier: (NSString*) identifier percentComplete: (float) percent {
   if (percent > 100.f)
      percent = 100.f;
   else if (percent < 0)
      percent = 0;
   
   GKAchievement *achievement = [self getAchievementForIdentifier:identifier];
   if (achievement) {
      if (percent > achievement.percentComplete) {
         achievement.percentComplete = percent;
         [achievement reportAchievementWithCompletionHandler:^(NSError *error)
          {
             if (error != nil)
                [self setLastError:error];
          }];
      }
   }
}

- (void) resetAchievements {
   achievementsDictionary = [[NSMutableDictionary alloc] init];
   [GKAchievement resetAchievementsWithCompletionHandler:^(NSError *error)
   {
       if (error != nil)
          [self setLastError:error];
   }];
}



#pragma mark Views (Leaderboard, Achievements)

-(UIViewController*) getRootViewController {
   return [UIApplication sharedApplication].keyWindow.rootViewController;
}

-(void) presentViewController:(UIViewController*)vc {
   UIViewController* rootVC = [self getRootViewController];
   [rootVC presentModalViewController:vc animated:YES];
}

-(void) dismissModalViewController {
   UIViewController* rootVC = [self getRootViewController];
   [rootVC dismissModalViewControllerAnimated:YES];
}

// Leaderboards

-(void) showLeaderboard {
   if (isGameCenterAvailable == NO)
      return;
   
   GKLeaderboardViewController* leaderboardVC = [[GKLeaderboardViewController alloc] init];
   if (leaderboardVC != nil) {
      leaderboardVC.leaderboardDelegate = self;
      [self presentViewController:leaderboardVC];
   }
}

-(void) leaderboardViewControllerDidFinish:(GKLeaderboardViewController*)viewController {
   [self dismissModalViewController];
   [delegate onLeaderboardViewDismissed];
}

// Achievements

-(void) showAchievements {
   if (isGameCenterAvailable == NO)
      return;
   
   GKAchievementViewController* achievementsVC = [[GKAchievementViewController alloc] init];
   if (achievementsVC != nil) {
      achievementsVC.achievementDelegate = self;
      [self presentViewController:achievementsVC];
   }
}

-(void) achievementViewControllerDidFinish:(GKAchievementViewController*)viewController {
   [self dismissModalViewController];
   [delegate onAchievementsViewDismissed];
}

@end
