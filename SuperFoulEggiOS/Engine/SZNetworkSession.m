#import "SZNetworkSession.h"
#import "SZEngineConstants.h"
#import "SZEggFactory.h"
#import "SZEggBase.h"
#import "SZSettings.h"
#import "SZEggFactory.h"

typedef NS_ENUM(char, SZMessageType) {
	SZMessageTypeNone = 0,
	SZMessageTypeMove = 1,
	SZMessageTypeStartGame = 2,
	SZMessageTypeStartRound = 3,
	SZMessageTypeReadyForNextEgg = 4
};

typedef NS_ENUM(char, SZRemoteMoveType) {
	SZRemoteMoveTypeNone = 0,
	SZRemoteMoveTypeLeft = 1,
	SZRemoteMoveTypeRight = 2,
	SZRemoteMoveTypeDown = 3,
	SZRemoteMoveTypeRotateClockwise = 4,
	SZRemoteMoveTypeRotateAnticlockwise = 5,
	SZRemoteMoveTypeDrop = 6
};

typedef struct {
	SZMessageType messageType;
} SZMessage;

typedef struct {
	SZMessage message;
	SZRemoteMoveType moveType;
} SZMoveMessage;

typedef struct {
	SZMessage message;
	char speed;
	char height;
	char eggColours;
	char gamesPerMatch;
	int randomEggSeed;
} SZStartGameMessage;

typedef struct {
	SZMessage message;
	int randomEggSeed;
} SZRoundStartMessage;

typedef struct {
	SZMessage message;
	char playerNumber;
} SZReadyForNextEggMessage;

static NSString * const SZSessionId = @"com.simianzombie.superfoulegg";
static NSString * const SZDisplayName = @"Player";

@implementation SZNetworkSession

+ (SZNetworkSession *)sharedSession {
	static SZNetworkSession *sharedSession = nil;
	static dispatch_once_t onceToken;

	dispatch_once(&onceToken, ^{
		sharedSession = [[SZNetworkSession alloc] init];
	});

	return sharedSession;
}

- (void)dealloc {
	[_session release];
	[_highestPeerId release];
	[_nextEggAcknowledgements release];

	[super dealloc];
}

- (void)startWithPlayerCount:(NSUInteger)playerCount {

	_playerCount = playerCount;

	[_session release];
	[_highestPeerId release];
	_highestPeerId = nil;

	_session = [[GKSession alloc] initWithSessionID:SZSessionId displayName:SZDisplayName sessionMode:GKSessionModePeer];
	_session.delegate = self;
	_session.available = YES;

	_highestPeerId = [_session.peerID retain];

	NSLog(@"%@", _session.peerID);

	[_session setDataReceiveHandler:self withContext:nil];

	_voteCount = 0;
	
	_state = SZNetworkSessionStateWaitingForPeers;

	[_nextEggAcknowledgements release];
	_nextEggAcknowledgements = [[NSMutableDictionary dictionary] retain];
}

- (void)session:(GKSession *)session connectionWithPeerFailed:(NSString *)peerID withError:(NSError *)error {

}

- (void)session:(GKSession *)session didFailWithError:(NSError *)error {

}

- (void)session:(GKSession *)session didReceiveConnectionRequestFromPeer:(NSString *)peerID {
	[session acceptConnectionFromPeer:peerID error:nil];
}

- (void)session:(GKSession *)session peer:(NSString *)peerID didChangeState:(GKPeerConnectionState)state {
	switch (state) {
		case GKPeerStateAvailable:
			[session connectToPeer:peerID withTimeout:20];
			break;
		case GKPeerStateConnected:

			if ([_highestPeerId compare:peerID] == NSOrderedAscending) {
				[_highestPeerId release];
				_highestPeerId = [peerID retain];
			}

			if ([session peersWithConnectionState:GKPeerStateConnected].count == _playerCount - 1) {
				_state = SZNetworkSessionStateGatheredPeers;
			}
			
			break;
		case GKPeerStateConnecting:
			break;
		case GKPeerStateDisconnected:
			break;
		case GKPeerStateUnavailable:
			break;
	}
}

- (void)receiveData:(NSData *)data
		   fromPeer:(NSString *)peerId
		  inSession:(GKSession *)session
			context:(void *)context {

	SZMessage *message = (SZMessage *)[data bytes];

	switch (message->messageType) {
		case SZMessageTypeMove:
			[self parseMoveMessage:(SZMoveMessage *)[data bytes] peerId:peerId];
			break;
		case SZMessageTypeStartGame:
			[self parseStartGameMessage:(SZStartGameMessage *)[data bytes] peerId:peerId];
			break;
		case SZMessageTypeStartRound:
			[self parseStartRoundMessage:(SZRoundStartMessage *)[data bytes] peerId:peerId];
			break;
		case SZMessageTypeReadyForNextEgg:
			[self parseReadyForNextEggMessage:(SZReadyForNextEggMessage *)[data bytes] peerId:peerId];
			break;
		case SZMessageTypeNone:
			break;
	}
}

- (void)parseReadyForNextEggMessage:(SZReadyForNextEggMessage *)message peerId:(NSString *)peerId {
	
	NSLog(@"Received ready for next egg message");

	NSNumber *playerNumber = @(message->playerNumber);

	if (_nextEggAcknowledgements[playerNumber]) {
		_nextEggAcknowledgements[playerNumber] = @([_nextEggAcknowledgements[playerNumber] intValue] + 1);
	} else {
		_nextEggAcknowledgements[playerNumber] = @1;
	}

	int count = [_nextEggAcknowledgements[playerNumber] intValue];

	if (count == [_session peersWithConnectionState:GKPeerStateConnected].count + 1) {

		NSLog(@"Player %@ is ready for a new egg", playerNumber);

		[_nextEggAcknowledgements removeObjectForKey:playerNumber];

		if (![_highestPeerId isEqualToString:_session.peerID]) {
			playerNumber = @(1 - message->playerNumber);
		}

		[[NSNotificationCenter defaultCenter] postNotificationName:SZRemoteReadyForNextEggNotification object:nil userInfo:@{ @"PlayerNumber": playerNumber }];
	}
}

- (void)parseMoveMessage:(SZMoveMessage *)moveMessage peerId:(NSString *)peerId {
	switch (moveMessage->moveType) {
		case SZRemoteMoveTypeNone:
			break;
		case SZRemoteMoveTypeDown:
			[[NSNotificationCenter defaultCenter] postNotificationName:SZRemoteMoveDownNotification object:nil];
			break;
		case SZRemoteMoveTypeLeft:
			[[NSNotificationCenter defaultCenter] postNotificationName:SZRemoteMoveLeftNotification object:nil];
			break;
		case SZRemoteMoveTypeRight:
			[[NSNotificationCenter defaultCenter] postNotificationName:SZRemoteMoveRightNotification object:nil];
			break;
		case SZRemoteMoveTypeDrop:
			[[NSNotificationCenter defaultCenter] postNotificationName:SZRemoteDropNotification object:nil];
			break;
		case SZRemoteMoveTypeRotateAnticlockwise:
			[[NSNotificationCenter defaultCenter] postNotificationName:SZRemoteRotateAnticlockwiseNotification object:nil];
			break;
		case SZRemoteMoveTypeRotateClockwise:
			[[NSNotificationCenter defaultCenter] postNotificationName:SZRemoteRotateClockwiseNotification object:nil];
			break;
	}
}

- (void)parseStartGameMessage:(SZStartGameMessage *)message peerId:(NSString *)peerId {

	NSLog(@"Received start game message");

	NSAssert(_state == SZNetworkSessionStateGatheredPeers || _state == SZNetworkSessionStateWaitingForGameStart, @"Illegal state when receiving start message");

	++_voteCount;

	if ([peerId isEqualToString:_highestPeerId]) {
		[SZSettings sharedSettings].height = message->height;
		[SZSettings sharedSettings].eggColours = message->eggColours;
		[SZSettings sharedSettings].speed = message->speed;
		[SZSettings sharedSettings].gamesPerMatch = message->gamesPerMatch;
		[SZSettings sharedSettings].randomEggSeed = message->randomEggSeed;
	}

	if (_voteCount == [_session peersWithConnectionState:GKPeerStateConnected].count + 1) {
		_state = SZNetworkSessionStateActive;

		_voteCount = 0;

		[[NSNotificationCenter defaultCenter] postNotificationName:SZRemoteStartGameNotification object:nil];
	}
}

- (void)parseStartRoundMessage:(SZRoundStartMessage *)message peerId:(NSString *)peerId {

	NSLog(@"Received start round message");

	if (_state != SZNetworkSessionStateWaitingForRoundStart) _voteCount = 0;

	_state = SZNetworkSessionStateWaitingForRoundStart;

	++_voteCount;
	
	if ([peerId isEqualToString:_highestPeerId]) {
		[SZSettings sharedSettings].randomEggSeed = message->randomEggSeed;

		NSLog(@"Seed: %d", message->randomEggSeed);
	}

	if (_voteCount == [_session peersWithConnectionState:GKPeerStateConnected].count + 1) {

		_voteCount = 0;

		[[NSNotificationCenter defaultCenter] postNotificationName:SZRemoteStartRoundNotification object:nil];

		_state = SZNetworkSessionStateActive;

		NSLog(@"Round started");
	}
}

- (void)sendData:(NSData *)data {
	[_session sendDataToAllPeers:data withDataMode:GKSendDataReliable error:nil];
}

- (void)sendStartRound {

	NSLog(@"Sending round message");

	SZRoundStartMessage message;

	message.message.messageType = SZMessageTypeStartRound;
	message.randomEggSeed = rand();

	[self parseStartRoundMessage:&message peerId:_session.peerID];

	[self sendData:[NSData dataWithBytes:&message length:sizeof(message)]];
}

- (void)sendStartGame {

	NSLog(@"%d", _state);

	NSLog(@"Sending start game message");

	NSAssert(_state == SZNetworkSessionStateGatheredPeers, @"Illegal state when trying to start game");

	_state = SZNetworkSessionStateWaitingForGameStart;

	SZStartGameMessage message;

	message.message.messageType = SZMessageTypeStartGame;
	message.eggColours = [SZSettings sharedSettings].eggColours;
	message.height = [SZSettings sharedSettings].height;
	message.gamesPerMatch = [SZSettings sharedSettings].gamesPerMatch;
	message.speed = [SZSettings sharedSettings].speed;
	message.randomEggSeed = rand();

	[self parseStartGameMessage:&message peerId:_session.peerID];

	[self sendData:[NSData dataWithBytes:&message length:sizeof(message)]];

	NSLog(@"Start game sent");
}

- (void)sendLiveBlockMoveLeft {
	SZMoveMessage message;

	message.message.messageType = SZMessageTypeMove;
	message.moveType = SZRemoteMoveTypeLeft;

	[self sendData:[NSData dataWithBytes:&message length:sizeof(message)]];
}

- (void)sendLiveBlockMoveRight {
	SZMoveMessage message;

	message.message.messageType = SZMessageTypeMove;
	message.moveType = SZRemoteMoveTypeRight;

	[self sendData:[NSData dataWithBytes:&message length:sizeof(message)]];
}

- (void)sendLiveBlockMoveDown {
	SZMoveMessage message;

	message.message.messageType = SZMessageTypeMove;
	message.moveType = SZRemoteMoveTypeDown;

	[self sendData:[NSData dataWithBytes:&message length:sizeof(message)]];
}

- (void)sendLiveBlockDrop {
	SZMoveMessage message;

	message.message.messageType = SZMessageTypeMove;
	message.moveType = SZRemoteMoveTypeDrop;

	[self sendData:[NSData dataWithBytes:&message length:sizeof(message)]];
}

- (void)sendLiveBlockRotateClockwise {
	SZMoveMessage message;

	message.message.messageType = SZMessageTypeMove;
	message.moveType = SZRemoteMoveTypeRotateClockwise;

	[self sendData:[NSData dataWithBytes:&message length:sizeof(message)]];
}

- (void)sendLiveBlockRotateAnticlockwise {
	SZMoveMessage message;

	message.message.messageType = SZMessageTypeMove;
	message.moveType = SZRemoteMoveTypeRotateAnticlockwise;

	[self sendData:[NSData dataWithBytes:&message length:sizeof(message)]];
}

- (void)sendReadyForNextEgg:(char)playerNumber {
	SZReadyForNextEggMessage message;

	message.message.messageType = SZMessageTypeReadyForNextEgg;

	// Player 0 on the top peer is player 1 on the other peer.  This will need
	// to be more complex to support more than two players.
	
	if ([_session.peerID isEqualToString:_highestPeerId]) {
		message.playerNumber = playerNumber;
	} else {
		message.playerNumber = 1 - playerNumber;
	}

	[self parseReadyForNextEggMessage:&message peerId:_session.peerID];

	[self sendData:[NSData dataWithBytes:&message length:sizeof(message)]];
}

@end
