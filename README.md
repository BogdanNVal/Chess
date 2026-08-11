# Chess — Chess Game with Graphical Interface (MATLAB)

A chess game written in MATLAB, with a board drawn in a custom graphical
interface (mouse drag & drop), position representation via bitboards, and a
custom move-search engine (minimax with alpha-beta pruning) for User vs
Robot mode.

## Screenshots

![Board at the starting position](docs/screenshots/tabla-initiala.png)
![A game in progress](docs/screenshots/partida.png)
![Check / checkmate highlighted](docs/screenshots/sah-mat.png)

## Features

- **Custom graphical interface**: an 8x8 board drawn with MATLAB App
  components (`uifigure`, `uiimage`), with pieces rendered from PNG images.
- **Drag & drop movement**: pieces are grabbed, dragged, and released with
  the mouse (`startDrag` / `dragging` / `stopDrag`), rather than by manually
  entering coordinates.
- **Two game modes**: User vs User (two players on the same board) and User
  vs Robot (against the computer).
- **Custom search engine**: minimax algorithm with alpha-beta pruning,
  configurable search depth, used by `Robot` to choose the optimal move.
- **Correct move generation** for each piece type (pawn, knight, bishop,
  rook, queen, king), filtering out moves that would leave one's own king
  in check.
- **Check, checkmate, and stalemate detection**, with visual highlighting
  of the square of the king in check and display of the game result on the
  interface.
- **Highlighting of the last move** made, directly on the board.
- **Loading a position from FEN** (Forsyth-Edwards Notation) — the standard
  starting position is loaded by default when the game opens and on reset.

## Tech stack

- MATLAB, object-oriented programming (`classdef`, `handle` classes)
- Position represented as **bitboards**: one `uint64` for each piece
  type + color combination (12 bitboards), plus auxiliary bitboards for
  white pieces, black pieces, and all occupied squares; bitwise operations
  (`bitand`, `bitor`, `bitxor`, `bitshift`, `bitget`, `bitset`) for fast
  querying and updating of the board
- Graphical interface: `uifigure`, `uiimage`, `WindowButtonDownFcn` /
  `WindowButtonMotionFcn` / `WindowButtonUpFcn` events for drag & drop
- **FEN** parsing for initializing and resetting the position (pieces, side
  to move, castling rights)
- Search: **minimax + alpha-beta pruning** (`Engine.m`), with position
  evaluation based on material value (pawn, knight, bishop, rook, queen,
  king)
- Custom classes for each game concept: `Bitboard` (the raw position),
  `Mutari` (Moves — move generation and validation), `Engine` (search for
  the optimal move), `Jucator` (Player — abstract class) with the
  `Utilizator` (User) and `Robot` implementations, `Joc` (Game — links the
  logic to the players), `Piesa` (Piece — a piece drawn on the interface),
  `Sah` (Chess — main window and mouse interaction)
- PNG images for the pieces, in the `img/` folder

## Running locally

1. Open MATLAB (R2020a or newer recommended, for full `uifigure`/`uiimage`
   support and the property type validation used in classes, e.g.
   `mutari Mutari`).
2. Set the `Sah/` folder (the one containing the `.m` files and the `img/`
   subfolder) as the **Current Folder** in MATLAB, or add it to the path —
   otherwise the classes and piece images won't be found (image paths are
   relative, e.g. `img/pion1.png`).
3. In the Command Window, start the game:
   ```matlab
   joc = Sah();
   ```
4. **User vs User** mode starts by default. To play against the computer,
   call:
   ```matlab
   joc.UtilizatorVsRobot(3); % 3 = the engine's search depth
   ```
   A greater depth means a stronger opponent, but also a longer thinking
   time (the search exhaustively explores the move tree down to the given
   depth).

## Technical decisions worth noting

- **Bitboards instead of a cell matrix**: bitwise operations are much
  faster than querying an `cell(8,8)` matrix piece by piece, which matters
  especially for the search engine, which explores hundreds/thousands of
  intermediate positions for each computed move.
- **A move is represented compactly as a vector `[startSquare, endSquare,
  movedPieceType, capturedPieceType]`**. The same format is used both by
  `actualizareTabla` (applies the move) and `anulareMutare` (undoes it
  exactly), which lets the engine make and unmake moves on the same
  `Bitboard`/`Mutari` object, without cloning the board at every node of
  the minimax tree.
- **A move's legality is checked by simulation**: each candidate move is
  temporarily applied to the board, a check is made for whether one's own
  king remains in check, and then the move is undone (`Mutari.valid`) —
  simpler to implement correctly than a static calculation of attack lines
  toward the king, though somewhat more costly.
- **Position evaluation is purely material-based** (the sum of the values
  of the pieces remaining on the board), with no positional factors
  (center control, king safety, pawn structure). Sufficient for a small
  search depth, but limits the engine's strength at greater depths.
- **Castling, en passant, and pawn promotion are not implemented**: the
  bitboard already stores the castling rights read from FEN (`flags`), but
  move generation doesn't yet use them to produce castling or en passant
  capture moves, and a pawn reaching the last rank isn't automatically
  promoted to another piece — this would require extending the move
  format and the board generation/update functions.

## Project structure

```
Sah/
  Sah/
    Sah.m                 -> main window, board drawing, mouse drag & drop
    Joc.m                 -> links the game logic (Mutari) to the two players
    Bitboard.m             -> position representation (uint64 bitboards), FEN, evaluation
    Mutari.m               -> move generation and validation for each piece type
    Engine.m               -> search engine (minimax + alpha-beta pruning)
    Jucator.m              -> abstract class for a player
    Utilizator.m            -> human player (moves received from the interface)
    Robot.m                 -> computer player (uses Engine to choose the move)
    Piesa.m                 -> a piece drawn on the interface (image + position)
    img/                     -> PNG images for the pieces (pawn, knight, bishop, rook, queen, king), white/black
```
