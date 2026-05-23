import 'package:flutter/material.dart';

/// A widget that wraps a side panel (detail/edit/add) with a draggable resize handle on its leading edge.
/// This mimics VS Code's resizable panel behavior.
class ResizablePanel extends StatefulWidget {
  final Widget child;
  final double initialWidth;
  final double minWidth;
  final double maxWidth;
  /// Called whenever the width changes (optional, for external state sync)
  final ValueChanged<double>? onWidthChanged;

  const ResizablePanel({
    super.key,
    required this.child,
    this.initialWidth = 400,
    this.minWidth = 280,
    this.maxWidth = 700,
    this.onWidthChanged,
  });

  @override
  State<ResizablePanel> createState() => _ResizablePanelState();
}

class _ResizablePanelState extends State<ResizablePanel> {
  late double _width;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _width = widget.initialWidth;
  }

  void _onDragUpdate(DragUpdateDetails d) {
    // Panel is on the RIGHT side. Dragging LEFT (negative dx) = resize wider
    // Since RTL, left divider means dx positive = narrower, negative = wider
    setState(() {
      _width = (_width - d.delta.dx).clamp(widget.minWidth, widget.maxWidth);
    });
    widget.onWidthChanged?.call(_width);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _width,
      child: Row(
        children: [
          // Drag Handle — thin vertical bar on the LEFT edge of the panel
          MouseRegion(
            cursor: SystemMouseCursors.resizeLeftRight,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onHorizontalDragStart: (_) => setState(() => _isDragging = true),
              onHorizontalDragUpdate: _onDragUpdate,
              onHorizontalDragEnd: (_) => setState(() => _isDragging = false),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 6,
                height: double.infinity,
                color: _isDragging
                    ? Colors.blue.withValues(alpha: 0.35)
                    : Colors.transparent,
                child: Center(
                  child: AnimatedOpacity(
                    opacity: _isDragging ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 150),
                    child: Container(
                      width: 2,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.blue.shade400,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          // The actual panel content fills remaining space
          Expanded(child: widget.child),
        ],
      ),
    );
  }
}
