Super Foul Egg
==============

This is an iOS port of Super Foul Egg, itself a clone of Puyo Puyo released
for the Commodore Amiga in 1995.  It is a port of the OSX version, which was a
re-write of Really Bad Eggs, which was itself a remake of Super Foul Egg for the
Nintendo DS.


Game Mechanics
--------------

Coloured eggs drop down the screen in pairs.  They can be rotated in clockwise
and anticlockwise directions.  The objective is to arrange eggs of the same
colour so that their edges touch and the eggs connect.  When four or more eggs
of the same colour are connected in a chain, the eggs disappear from the grid
and any eggs above them drop down to fill the vacated space.  A number of
garbage eggs is dumped into the opponent's grid corresponding to the number of
eggs removed.  The amount of garbage eggs increases dramatically if:

 - More than four eggs are connected in a single chain;
 - Several chains are removed at once;
 - The removal of a chain causes eggs to fall, which in turn makes additional
   chains of eggs.


Game Types
----------

Super Foul Egg features two basic game types.  The first is a single-player
practice mode.  Play continues until the grid fills with eggs to the point that
no more eggs can be placed.

The second is a two-player mode against the CPU.  Each time chains are made in
this mode, garbage eggs are dumped into the opponent's grid.

A two-player mode that uses an adhoc local network between two iPads is in the
works.


Menu System
-----------

When the game starts a menu system is presented.  Tap the options to select
them.

The menus are as follows:

 - **Game Type**: Choose from the practice game type or easy/medium/hard/insane
   player-vs-AI types.
 - **Speed**: Choose the speed at which the eggs drop down the grid.  Faster
   speeds mean less time to think.
 - **Height**: Choose the starting height.  The number corresponds to the rows
   of garbage eggs added to the grid at the start of the game.  More rows mean
   the game is initially faster paced and harder.
 - **Colours**: The number of different colours of eggs in the game.  Each
   additional colour reduces the chance of a particular colour egg being
   created, making it more difficult to set up elaborate sequences of egg
   chains.
 - **Best Of**: The number of games per match.


Controls
--------

 * Move shape left:            Swipe left
 * Move shape right:           Swipe right
 * Drop shape:                 Swipe down with two fingers
 * Rotate clockwise:           Tap
 * Rotate anticlockwise:       Tap with two fingers
 * Pause:                      Tap the pause icon (bottom-right of the screen)
 * Exit:                       Tap the exit icon (top-right of the screen)


Garbage Eggs
------------

Garbage eggs are grey eggs that do not connect with any other eggs.  The only
way to remove a garbage egg from the grid is to remove another egg adjacent to
it.

The number of garbage eggs generated by chains is calculated via two forumulae.
For the first group of chains the formula is:

    blocks - 3

If the player creates a chain of 5 blocks, the garbage created is:

    5 - 3 = 2

If the player creates a chain of 5 blocks and a chain of 6 blocks
simultaneously, the garbage created is:

    5 + 6 - 3 = 8

In subsequent groups of chains, the formula is as follows:

    blocks - 4 + 6

So, if the player creates a chain of 5 blocks, which falls to create a chain of
7 blocks, the formulae are:

    5 - 3     = 2  (first chain)
    7 - 4 + 6 = 9  (second chain)
              = 11 (total)


Changes from the OSX Version
----------------------------

Each successive version of Super Foul Egg makes tweaks and changes from the
version that preceded it.  Differences from the OSX version are:

 * The AI is multithreaded for extra speed;
 * The control system is designed specifically for a touch screen device;
 * The two-player mode is currently unavailable;
 * Hard drop (eggs drop automatically when swiped down) is forced on and soft
   drop is not available.


Requirements
------------

To play the game you will need an iPad running iOS 5.0.  It's tricky to play on
the simulator as it's designed around touch gestures, but it's playable.  To
compile the sourcecode you will need at least Xcode 4.6.


Credits and Acknowledgements
----------------------------

 - Coding, reverse engineering and remixing        - **Antony Dzeryn**
 - Original graphics and sounds                    - **David & Michael Hay**
 - Simian Zombie logo                              - **John Clay**


Links
-----

 - [Development blog][1]
 - [BitBucket page][2]
 - [OSX version][3]
 - [DS version][4]
 - [Cocos2D][5]

  [1]: http://simianzombie.com
  [2]: http://bitbucket.org/ant512/superfouleggios
  [3]: http://bitbucket.org/ant512/superfoulegg
  [4]: http://bitbucket.org/ant512/reallybadeggs
  [5]: http://www.cocos2d-iphone.org


Email
-----

  Contact me at <ant@simianzombie.com>.