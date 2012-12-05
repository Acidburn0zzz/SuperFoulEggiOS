#import "SZEggFactory.h"
#import "SZRedEgg.h"
#import "SZBlueEgg.h"
#import "SZGreenEgg.h"
#import "SZYellowEgg.h"
#import "SZOrangeEgg.h"
#import "SZPurpleEgg.h"
#import "SZGarbageEgg.h"
#import "SZNetworkSession.h"

@implementation SZEggFactory

+ (SZEggFactory *)sharedFactory {
	static SZEggFactory *sharedFactory = nil;
	static dispatch_once_t onceToken;

	dispatch_once(&onceToken, ^{
		sharedFactory = [[SZEggFactory alloc] init];
	});

	return sharedFactory;
}

- (id)init {
	if ((self = [super init])) {
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receivedRemoteEgg:) name:SZRemoteEggDeliveryNotification object:nil];
	}

	return self;
}

- (void)receivedRemoteEgg:(NSNumber *)eggColour {
	SZEggColour colour = [eggColour intValue];

	[self addEggClassFromColour:colour];
}

- (void)setPlayerCount:(int)playerCount andEggColourCount:(int)eggColourCount {
	_playerCount = playerCount;
	_eggColourCount = eggColourCount;

	if (_playerEggListIndices) {		
		free(_playerEggListIndices);
	}

	_playerEggListIndices = malloc(sizeof(int) * playerCount);

	[_eggList release];

	_eggList = [[NSMutableArray alloc] init];

	[self clear];
}

- (void)dealloc {
	free(_playerEggListIndices);
	
	[_eggList release];
	[super dealloc];
}

- (void)clear {
	for (int i = 0; i < _playerCount; ++i) {
		_playerEggListIndices[i] = 0;
	}
	
	[_eggList removeAllObjects];
}

- (void)addRandomEggClass {
	[_eggList addObject:[self randomEggClass]];
}

- (void)addEggClassFromColour:(SZEggColour)value {
	[_eggList addObject:[self eggClassFromColour:value]];
}

- (void)expireUsedEggClasses {
	int minimumIndex = INT_MAX;
	
	// Locate the earliest-used egg in the list
	for (int i = 0; i < _playerCount; ++i) {
		if (_playerEggListIndices[i] < minimumIndex) minimumIndex = _playerEggListIndices[i];
	}
	
	// Reduce the indices of all players as we are going to trash everything
	// before the earliest-used egg
	for (int i = 0; i < _playerCount; ++i) {
		_playerEggListIndices[i] -= minimumIndex;
	}
	
	// Trash the unused eggs from the start of the array
	while (minimumIndex > 0) {
		[_eggList removeObjectAtIndex:0];
		--minimumIndex;
	}
}

- (Class)eggClassFromColour:(SZEggColour)value {
	switch (value) {
		case SZEggColourRed:
			return [SZRedEgg class];
		case SZEggColourBlue:
			return [SZBlueEgg class];
		case SZEggColourYellow:
			return [SZYellowEgg class];
		case SZEggColourPurple:
			return [SZPurpleEgg class];
		case SZEggColourGreen:
			return [SZGreenEgg class];
		case SZEggColourOrange:
			return [SZOrangeEgg class];
		case SZEggColourGarbage:
			return [SZGarbageEgg class];
		case SZEggColourNone:
			return nil;
	}

	// Included to silence compiler warning
	return [SZRedEgg class];
}

- (Class)randomEggClass {
	int colour = rand() % _eggColourCount;
	return [self eggClassFromColour:colour];
}

- (BOOL)hasEggsForPlayer:(int)playerNumber count:(int)count {
	int index = _playerEggListIndices[playerNumber] + count;

	return (index < _eggList.count);
}

- (SZEggColour)colourOfEgg:(SZEggBase *)egg {
	if ([egg class] == [SZRedEgg class]) {
		return SZEggColourRed;
	} else if ([egg class] == [SZOrangeEgg class]) {
		return SZEggColourOrange;
	} else if ([egg class] == [SZBlueEgg class]) {
		return SZEggColourBlue;
	} else if ([egg class] == [SZGreenEgg class]) {
		return SZEggColourGreen;
	} else if ([egg class] == [SZYellowEgg class]) {
		return SZEggColourYellow;
	} else if ([egg class] == [SZPurpleEgg class]) {
		return SZEggColourPurple;
	} else if ([egg class] == [SZRedEgg class]) {
		return SZEggColourGarbage;
	}

	return SZEggColourNone;
}

- (SZEggBase *)newEggForPlayerNumber:(int)playerNumber {
	int index = _playerEggListIndices[playerNumber]++;

	// If the player is requesting an egg past the end of the egg list,
	// we need to append a new pair before we can return it
	if (index == [_eggList count]) {
		[self addRandomEggClass];
	}

	// Initialise a new egg instance from the class at the current egglist
	// index that this player is using
	SZEggBase* egg = [[[_eggList objectAtIndex:index] alloc] init];
	
	// We can try to expire any old egg in the list now
	[self expireUsedEggClasses];

	return egg;
}

@end
