# High score game with state stored on a block device

This example is a small, non-interactive game with high scores stored on a
block device. The unikernel can store multiple game states on the block device,
one sector per game slot.

The unikernel can be built the usual way:
```sh
$ mirage configure
$ make depends
$ make build
```

The unikernel needs a disk image to read and store its state. To create a disk
image with eight slots/sectors (assuming a sector size of 512 bytes):
```sh
$ dd if=/dev/zero of=disk.img count=8
```

You could run the game now, but the unikernel expects the disk to be
initialized, so you will get an error:

```sh
$ ./dist/lottery
2023-06-29 14:21:24 +02:00: ERR [application] Error reading state: bad magic; is this lottery data?
```

The unikernel comes with boot parameters so you can ask it to initialize or reset the game state:

```sh
$ ./dist/lottery --reset --slot 4
2023-06-29 14:29:16 +02:00: APP [application] Reset game slot 4.
$ ./dist/lottery --reset-all
2023-06-29 14:25:26 +02:00: APP [application] All 8 game slots reset.
```

Now we can play! The first game is always the easiest.

```sh
$ ./dist/lottery 
2023-06-29 14:31:38 +02:00: APP [application] YOU WON! You beat the old high score 0 with 2144007637!
2023-06-29 14:31:38 +02:00: INF [application] Saving new game state...
2023-06-29 14:31:38 +02:00: INF [application] Done!
2023-06-29 14:31:38 +02:00: APP [application] Thank you for playing! Exiting...
$ ./dist/lottery 
2023-06-29 14:31:40 +02:00: APP [application] YOU LOST! With 1466758588 you didn't beat the high score 2144007637
2023-06-29 14:31:40 +02:00: INF [application] Saving new game state...
2023-06-29 14:31:40 +02:00: INF [application] Done!
2023-06-29 14:31:40 +02:00: APP [application] Thank you for playing! Exiting...
$ ./dist/lottery 
2023-06-29 14:31:40 +02:00: APP [application] YOU WON! You beat the old high score 2144007637 with 2908584036!
2023-06-29 14:31:40 +02:00: INF [application] Saving new game state...
2023-06-29 14:31:40 +02:00: INF [application] Done!
2023-06-29 14:31:40 +02:00: APP [application] Thank you for playing! Exiting...
$ ./dist/lottery 
2023-06-29 14:31:41 +02:00: APP [application] YOU WON! You beat the old high score 2908584036 with 3112844487!
2023-06-29 14:31:41 +02:00: INF [application] Saving new game state...
2023-06-29 14:31:41 +02:00: INF [application] Done!
2023-06-29 14:31:41 +02:00: APP [application] Thank you for playing! Exiting...
```

Once we get tired of the increasing difficulty of the game we can take a break
and play the game using a different slot:

```sh
$ ./dist/lottery --slot 1
2023-06-29 14:33:41 +02:00: APP [application] YOU WON! You beat the old high score 0 with 650987892!
2023-06-29 14:33:41 +02:00: INF [application] Saving new game state...
2023-06-29 14:33:41 +02:00: INF [application] Done!
2023-06-29 14:33:41 +02:00: APP [application] Thank you for playing! Exiting...
$ ./dist/lottery --slot 1
2023-06-29 14:33:42 +02:00: APP [application] YOU WON! You beat the old high score 650987892 with 3449332189!
2023-06-29 14:33:42 +02:00: INF [application] Saving new game state...
2023-06-29 14:33:42 +02:00: INF [application] Done!
2023-06-29 14:33:42 +02:00: APP [application] Thank you for playing! Exiting...
$ ./dist/lottery --slot 1
2023-06-29 14:33:43 +02:00: APP [application] YOU LOST! With 3185798437 you didn't beat the high score 3449332189
2023-06-29 14:33:43 +02:00: INF [application] Saving new game state...
2023-06-29 14:33:43 +02:00: INF [application] Done!
2023-06-29 14:33:43 +02:00: APP [application] Thank you for playing! Exiting...
$ ./dist/lottery --slot 1
2023-06-29 14:33:44 +02:00: APP [application] YOU LOST! With 458063507 you didn't beat the high score 3449332189
2023-06-29 14:33:44 +02:00: INF [application] Saving new game state...
2023-06-29 14:33:44 +02:00: INF [application] Done!
2023-06-29 14:33:44 +02:00: APP [application] Thank you for playing! Exiting...
```
