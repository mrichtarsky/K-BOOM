# K-BOOM

Celebrating 25 years of coding by reviving an old school project!

Video for the lazy: [Building from source and game play](https://www.youtube.com/watch?v=crKoZoDhFl8)

You can either build from source or run the binaries:

### Running the binaries

- Download and install [DOSBox](https://www.dosbox.com/download.php?main=1)
- Mount the directory and run `K-BOOM!.EXE`
- See [Gameplay](#Gameplay) below

### Building from source

- Prerequisites: Windows (sorry)
- Download and install [Turbo Pascal (With DOSBox)](https://turbopascal-wdb.sourceforge.io/doku.php/download)
- Start it. A console window pops up with the familiar Turbo Pascal interface.
- `File` -> `Change dir...` and navigate to the directory containing this repo. Click `OK`.
- `File` -> `Open` and choose `K-BOOM.PAS`
- `Options` -> `Compiler` and tick the checkmark for `286 instructions`. Close the dialog via `OK`.
- `Compile` -> `Make`. After a few seconds this should be successful.
- `Run` -> `Run`

## Gameplay

- After the fake Doom startup screen you can configure the keyboard (`Ja` = `Yes`). Configuration will be saved for next time. Sorry, language is German.
- Next up is the intro with some nice pictures of our school, and a tribute to our computer science class :)
- In the menu, use `Cursor Up/Down`. You can choose how many games need to be won to win the series (go to second menu entry and hit `Cursor Left/Right`)
- When you are ready, `Start Game`
- The aim is to be the last survivor. The player who survives most often wins the series. There are three human-controlled players, no AI. You can place bombs to blow up rocks. your opponents, or yourself. Bombs will also trigger explosions of other bombs in their range.
- Default controls:
    - Player 1: `W/A/S/D` for movement, `Left Ctrl` for bomb, `Tab` for kick
    - Player 2: `Cursor keys` for movement, `Right Ctrl` for bomb, `Enter` for kick
    - Player 3: `U/H/J/K` for movement, `B` for bomb, `V` for kick
    - It's probably a bit cramped playing like that. I only had a laptop available - perhaps a good idea to use a full keyboard and use the numblock for Player 3.
- Power-ups:
    - **Bomb**: You can place multiple bombs at the same time (one at the beginning, up to nine possible)
    - **+1/-1**: Range of your bomb increases/decreases
    - **Yellow bomb**: Now you can destroy multiple wall segments at once

## Remarks

This is a clone of [Atomic Bomberman](https://en.wikipedia.org/wiki/Atomic_Bomberman), a great multiplayer game we spent countless hours playing after school. So for our computer science school class project we built this game as a hommage.

- Code: Martin Richtarsky
- Graphics: Martin Hagenberg

Some details:

- Written in 1997 on a [Intel 80486](https://de.wikipedia.org/wiki/Intel_80486)
- However, at school we only had slow [Intel 80286](https://en.wikipedia.org/wiki/Intel_80286) machines, and it had to run there ;)
- Code is [Turbo Pascal](https://en.wikipedia.org/wiki/Turbo_Pascal) with inline assembly for fast drawing
- Video mode is the famous [13h](https://en.wikipedia.org/wiki/Mode_13h): 320x200, 256 colors. Linear framebuffer, ideal for fast drawing. It's possible to calculate the address of a pixel `(x, y)` in the buffer without expensive multiplication since `320 == (2**6 + 2**8)`, which are two shifts and one add. The colors are drawn from a palette, and changing the palette changes all pixels of that color on the screen. So it's possible to do smooth fadeouts even on a 80286.
- The game fit on a floppy disk ([3.5" 1.44MB](https://en.wikipedia.org/wiki/Floppy_disk#3%C2%BD-inch_disk) if I recall correctly)
- We wanted to include a video. But video playback on 80286 is not that easy due to the limits of the machine. It also had to fit on the floppy disk. A custom compression and assembly decoder was the solution.
- PCX was the image format back in the day
- The source has very... inconsistent indentation
- Let's say I write better code now ;)
- Bomb kicking was possible in the original Atomic Bomberman and this game here has hotkeys for it. I'm not sure it's implemented though.
- I still love the Turbo Pascal experience. Very fast compiles! (TP was developed by Anders Heljsberg, who went on to build C# and TypeScript)

## Endorsements

"It's as good as FIFA 22 - and FIFA is the best game ever!" -- Unnamed family member
