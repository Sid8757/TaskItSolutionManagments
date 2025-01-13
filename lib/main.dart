import 'package:flutter/material.dart';

/// Entrypoint of the application.
void main() {
  runApp(const MyApp());
}

/// [Widget] building the [MaterialApp].
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Dock(
            items: const [
              Icons.person,
              Icons.message,
              Icons.call,
              Icons.camera,
              Icons.photo,
            ],
            builder: (e, isDraggedOutsideContainer) {
              return Container(
                constraints: isDraggedOutsideContainer
                    ? const BoxConstraints(minWidth: 0)
                    : const BoxConstraints(minWidth: 48),
                height: 48,
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.primaries[e.hashCode % Colors.primaries.length],
                ),
                child: Center(child: Icon(e, color: Colors.white)),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Dock of the reorderable [items].
class Dock<T extends Object> extends StatefulWidget {
  const Dock({
    super.key,
    this.items = const [],
    required this.builder,
  });

  /// Initial [T] items to put in this [Dock].
  final List<T> items;

  /// Builder building the provided [T] item.
  final Widget Function(T, bool) builder;

  @override
  State<Dock<T>> createState() => _DockState<T>();
}

/// State of the [Dock] used to manipulate the [_items].
class _DockState<T extends Object> extends State<Dock<T>> {
  /// [T] items being manipulated.
  late final List<T> _items = widget.items.toList();
  T? _draggedItem;
  bool isDraggedOutsideContainer = false;

  final GlobalKey dockKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return Container(
      key: dockKey,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.black12,
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: _items.map((item) {
          return DragTarget<T>(
            onWillAccept: (data) => data != item,
            onAccept: (data) {
              setState(() {
                final oldIndex = _items.indexOf(data);
                final newIndex = _items.indexOf(item);
                _items.removeAt(oldIndex);
                _items.insert(newIndex, data);
              });
            },
            builder: (context, candidateData, rejectedData) {
              final isHovered = candidateData.isNotEmpty &&
                  candidateData.first == _draggedItem;

              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedContainer(
                    width: isHovered ? 48.0 : 0,
                    height: isHovered ? 48.0 : 0.0,
                    alignment: Alignment.center,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  ),
                  Draggable<T>(
                    data: item,
                    feedback: Opacity(
                      opacity: 0.7,
                      child: widget.builder(item, false),
                    ),
                    childWhenDragging: AnimatedOpacity(
                      opacity: 0.0,
                      duration: const Duration(milliseconds: 300),
                      child: AnimatedSize(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        child: isDraggedOutsideContainer
                            ? const SizedBox.shrink()
                            : widget.builder(item, false),
                      ),
                    ),
                    onDragStarted: () {
                      setState(() {
                        _draggedItem = item;
                        isDraggedOutsideContainer = false;
                      });
                    },
                    onDragUpdate: (details) {
                      final renderBox = dockKey.currentContext
                          ?.findRenderObject() as RenderBox?;
                      if (renderBox != null) {
                        final dockBoundary =
                            renderBox.localToGlobal(Offset.infinite) &
                                renderBox.size;
                        setState(() {
                          isDraggedOutsideContainer =
                              !dockBoundary.contains(details.globalPosition);
                        });
                      }
                    },
                    onDragEnd: (_) {
                      setState(() {
                        _draggedItem = null;
                        isDraggedOutsideContainer = false;
                      });
                    },
                    child: widget.builder(item, false),
                  ),
                ],
              );
            },
          );
        }).toList(),
      ),
    );
  }
}
