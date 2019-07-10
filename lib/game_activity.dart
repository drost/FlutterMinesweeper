import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_minesweeper/board_square.dart';

// Types of images available
enum ImageType {
  zero,
  one,
  two,
  three,
  four,
  five,
  six,
  seven,
  eight,
  bomb,
  facingDown,
  flagged,
}

final directions = List<Point<int>>.from(
  [
    const Point(-1, -1),
    const Point(0, -1),
    const Point(1, -1),
    const Point(-1, 0),
    const Point(1, 0),
    const Point(-1, 1),
    const Point(0, 1),
    const Point(1, 1)
  ],
);

class GameActivity extends StatefulWidget {
  @override
  _GameActivityState createState() => _GameActivityState();
}

class _GameActivityState extends State<GameActivity> {
  // Row and column count of the board
  int rowCount = 18;
  int columnCount = 10;

  // The grid of squares
  List<List<BoardSquare>> board;

  // "Opened" refers to being clicked already
  List<bool> openedSquares;

  // A flagged square is a square a user has added a flag on by long pressing
  List<bool> flaggedSquares;

  // Probability that a square will be a bomb
  int bombProbability = 20;
  int maxProbability = 100;

  int bombCount = 0;
  int squaresLeft;

  @override
  void initState() {
    super.initState();
    _initialiseGame();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        children: <Widget>[
          Container(
            color: Colors.grey,
            height: 60.0,
            width: double.infinity,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                InkWell(
                  onTap: () {
                    _initialiseGame();
                  },
                  child: CircleAvatar(
                    child: Icon(
                      Icons.tag_faces,
                      color: Colors.black,
                      size: 40.0,
                    ),
                    backgroundColor: Colors.yellowAccent,
                  ),
                )
              ],
            ),
          ),
          // The grid of squares
          GridView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columnCount,
            ),
            itemBuilder: (context, position) {
              // Get row and column number of square
              int rowNumber = (position / columnCount).floor();
              int columnNumber = (position % columnCount);

              Image image;

              if (openedSquares[position] == false) {
                if (flaggedSquares[position] == true) {
                  image = getImage(ImageType.flagged);
                } else {
                  image = getImage(ImageType.facingDown);
                }
              } else {
                if (board[rowNumber][columnNumber].hasBomb) {
                  image = getImage(ImageType.bomb);
                } else {
                  image = getImage(
                    getImageTypeFromNumber(
                        board[rowNumber][columnNumber].bombsAround),
                  );
                }
              }

              return InkWell(
                // Opens square
                onTap: () {
                  if (board[rowNumber][columnNumber].hasBomb) {
                    _handleGameOver();
                  }
                  _openTile(columnNumber, rowNumber);
                  if (squaresLeft <= bombCount) {
                    _handleWin();
                  }
                },
                // Flags square
                onLongPress: () {
                  if (openedSquares[position] == false) {
                    setState(() {
                      flaggedSquares[position] = !flaggedSquares[position];
                    });
                  }
                },
                splashColor: Colors.grey,
                child: Container(
                  color: Colors.grey,
                  child: image,
                ),
              );
            },
            itemCount: rowCount * columnCount,
          ),
        ],
      ),
    );
  }

  // Initialises all lists
  void _initialiseGame() {
    // Initialise all squares to having no bombs
    board = List.generate(rowCount, (i) {
      return List.generate(columnCount, (j) {
        return BoardSquare();
      });
    });

    // Initialise list to store which squares have been opened
    openedSquares = List.generate(rowCount * columnCount, (i) {
      return false;
    });

    flaggedSquares = List.generate(rowCount * columnCount, (i) {
      return false;
    });

    // Resets bomb count
    bombCount = 0;
    squaresLeft = rowCount * columnCount;

    // Randomly generate bombs
    Random random = new Random();
    for (int y = 0; y < rowCount; y++) {
      for (int x = 0; x < columnCount; x++) {
        int randomNumber = random.nextInt(maxProbability);
        if (randomNumber < bombProbability) {
          board[y][x].hasBomb = true;
          bombCount++;
        }
      }
    }

    // Check bombs around and assign numbers
    for (int y = 0; y < rowCount; y++) {
      for (int x = 0; x < columnCount; x++) {
        for (var dir in directions) {
          if (_isBomb(x + dir.x, y + dir.y)) {
            board[y][x].bombsAround++;
          }
        }
          }
        }

    setState(() {});
        }

  bool _isBomb(int x, int y) {
    if (!_isInsideGrid(x, y)) {
      return false;
        }
    if (board[y][x].hasBomb) {
      return true;
          }
    return false;
        }

  // This function opens other squares around the target square which don't have any bombs around them.
  // We use a recursive function which stops at squares which have a non zero number of bombs around them.
  void _openTile(int x, int y) {
    int position = (y * columnCount) + x;
    openedSquares[position] = true;
    squaresLeft = squaresLeft - 1;

    if (board[y][x].bombsAround == 0) {
      for (var dir in directions) {
        _openTileIfSafe(x + dir.x, y + dir.y);
        }
      }

    setState(() {});
        }

  bool _isInsideGrid(int x, int y) {
    if (x < 0 || y < 0 || x > columnCount - 1 || y > rowCount - 1) {
      return false;
        }
    return true;
      }

  void _openTileIfSafe(int x, int y) {
    if (!_isInsideGrid(x, y)) {
      return;
      }
    if (!board[y][x].hasBomb && openedSquares[(y * columnCount) + x] != true) {
      _openTile(x, y);
    }
  }

  // Function to handle when a bomb is clicked.
  void _handleGameOver() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Game Over!"),
          content: Text("You stepped on a mine!"),
          actions: <Widget>[
            FlatButton(
              onPressed: () {
                _initialiseGame();
                Navigator.pop(context);
              },
              child: Text("Play again"),
            ),
          ],
        );
      },
    );
  }

  void _handleWin() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Congratulations!"),
          content: Text("You Win!"),
          actions: <Widget>[
            FlatButton(
              onPressed: () {
                _initialiseGame();
                Navigator.pop(context);
              },
              child: Text("Play again"),
            ),
          ],
        );
      },
    );
  }

  Image getImage(ImageType type) {
    switch (type) {
      case ImageType.zero:
        return Image.asset('images/0.png');
      case ImageType.one:
        return Image.asset('images/1.png');
      case ImageType.two:
        return Image.asset('images/2.png');
      case ImageType.three:
        return Image.asset('images/3.png');
      case ImageType.four:
        return Image.asset('images/4.png');
      case ImageType.five:
        return Image.asset('images/5.png');
      case ImageType.six:
        return Image.asset('images/6.png');
      case ImageType.seven:
        return Image.asset('images/7.png');
      case ImageType.eight:
        return Image.asset('images/8.png');
      case ImageType.bomb:
        return Image.asset('images/bomb.png');
      case ImageType.facingDown:
        return Image.asset('images/facingDown.png');
      case ImageType.flagged:
        return Image.asset('images/flagged.png');
      default:
        return null;
    }
  }

  ImageType getImageTypeFromNumber(int number) {
    switch (number) {
      case 0:
        return ImageType.zero;
      case 1:
        return ImageType.one;
      case 2:
        return ImageType.two;
      case 3:
        return ImageType.three;
      case 4:
        return ImageType.four;
      case 5:
        return ImageType.five;
      case 6:
        return ImageType.six;
      case 7:
        return ImageType.seven;
      case 8:
        return ImageType.eight;
      default:
        return null;
    }
  }
}
