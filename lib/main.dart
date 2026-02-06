import 'dart:math';

import 'package:flutter/material.dart';

void main() {
  runApp(const MinesweeperApp());
}

class MinesweeperApp extends StatelessWidget {
  const MinesweeperApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Minesweeper',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
      ),
      home: const MinesweeperPage(),
    );
  }
}

class MinesweeperPage extends StatefulWidget {
  const MinesweeperPage({super.key});

  @override
  State<MinesweeperPage> createState() => _MinesweeperPageState();
}

class _MinesweeperPageState extends State<MinesweeperPage> {
  static const int rows = 8;
  static const int cols = 8;
  static const int mineCount = 10;

  late List<List<Cell>> board;
  bool gameOver = false;
  bool gameWon = false;

  @override
  void initState() {
    super.initState();
    _resetGame();
  }

  void _resetGame() {
    board = List.generate(
      rows,
      (_) => List.generate(cols, (_) => Cell()),
    );

    final random = Random();
    int placed = 0;
    while (placed < mineCount) {
      final r = random.nextInt(rows);
      final c = random.nextInt(cols);
      if (!board[r][c].isMine) {
        board[r][c].isMine = true;
        placed++;
      }
    }

    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        if (!board[r][c].isMine) {
          board[r][c].neighborMines = _countNeighborMines(r, c);
        }
      }
    }

    gameOver = false;
    gameWon = false;
    setState(() {});
  }

  int _countNeighborMines(int row, int col) {
    int count = 0;
    for (int r = row - 1; r <= row + 1; r++) {
      for (int c = col - 1; c <= col + 1; c++) {
        if (r == row && c == col) {
          continue;
        }
        if (r >= 0 && r < rows && c >= 0 && c < cols && board[r][c].isMine) {
          count++;
        }
      }
    }
    return count;
  }

  void _revealCell(int row, int col) {
    if (gameOver || gameWon) return;

    final cell = board[row][col];
    if (cell.isRevealed || cell.isFlagged) return;

    setState(() {
      cell.isRevealed = true;

      if (cell.isMine) {
        gameOver = true;
        _revealAllMines();
        return;
      }

      if (cell.neighborMines == 0) {
        _revealEmptyNeighbors(row, col);
      }

      if (_hasWon()) {
        gameWon = true;
      }
    });
  }

  void _revealEmptyNeighbors(int row, int col) {
    final queue = <Point<int>>[Point(row, col)];

    while (queue.isNotEmpty) {
      final point = queue.removeLast();

      for (int r = point.x - 1; r <= point.x + 1; r++) {
        for (int c = point.y - 1; c <= point.y + 1; c++) {
          if (r < 0 || r >= rows || c < 0 || c >= cols) {
            continue;
          }

          final neighbor = board[r][c];
          if (neighbor.isRevealed || neighbor.isFlagged || neighbor.isMine) {
            continue;
          }

          neighbor.isRevealed = true;
          if (neighbor.neighborMines == 0) {
            queue.add(Point(r, c));
          }
        }
      }
    }
  }

  void _toggleFlag(int row, int col) {
    if (gameOver || gameWon) return;

    final cell = board[row][col];
    if (cell.isRevealed) return;

    setState(() {
      cell.isFlagged = !cell.isFlagged;
    });
  }

  void _revealAllMines() {
    for (final row in board) {
      for (final cell in row) {
        if (cell.isMine) {
          cell.isRevealed = true;
        }
      }
    }
  }

  bool _hasWon() {
    for (final row in board) {
      for (final cell in row) {
        if (!cell.isMine && !cell.isRevealed) {
          return false;
        }
      }
    }
    return true;
  }

  String _statusText() {
    if (gameOver) return 'Game Over! Tap reset to play again.';
    if (gameWon) return 'You won! Nice work.';
    return 'Tap to reveal · Long press to flag';
  }

  Color _cellColor(Cell cell) {
    if (cell.isRevealed) {
      if (cell.isMine) return Colors.red.shade300;
      return Colors.grey.shade300;
    }
    return Colors.teal.shade200;
  }

  Widget _buildCell(int row, int col) {
    final cell = board[row][col];

    Widget content;
    if (!cell.isRevealed) {
      content = Text(
        cell.isFlagged ? '🚩' : '',
        style: const TextStyle(fontSize: 20),
      );
    } else if (cell.isMine) {
      content = const Text('💣', style: TextStyle(fontSize: 20));
    } else if (cell.neighborMines > 0) {
      content = Text(
        '${cell.neighborMines}',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 18,
          color: Colors.indigo.shade700,
        ),
      );
    } else {
      content = const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: () => _revealCell(row, col),
      onLongPress: () => _toggleFlag(row, col),
      child: Container(
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: _cellColor(cell),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.black26),
        ),
        child: Center(child: content),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Minesweeper'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              _statusText(),
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _resetGame,
              child: const Text('Reset Game'),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.builder(
                itemCount: rows * cols,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: cols,
                ),
                itemBuilder: (context, index) {
                  final row = index ~/ cols;
                  final col = index % cols;
                  return _buildCell(row, col);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class Cell {
  bool isMine = false;
  bool isRevealed = false;
  bool isFlagged = false;
  int neighborMines = 0;
}
