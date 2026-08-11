import 'package:flutter/material.dart';
import 'package:klutter/data/repositories/download_manager.dart';

class DownloadFloatingControl extends StatefulWidget {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  final Widget child;

  const DownloadFloatingControl({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  _DownloadFloatingControlState createState() =>
      _DownloadFloatingControlState();
}

class _DownloadFloatingControlState extends State<DownloadFloatingControl> {
  final DownloadManager _manager = DownloadManager.instance;
  double? _left;
  double? _top;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const double controlSize = 58.0;
        final double defaultLeft = constraints.maxWidth - controlSize - 16.0;
        final double defaultTop = constraints.maxHeight - controlSize - 90.0;
        final double left = _left ?? defaultLeft;
        final double top = _top ?? defaultTop;

        return Stack(
          children: [
            widget.child,
            AnimatedBuilder(
              animation: _manager,
              builder: (context, child) {
                if (!_manager.hasActiveDownloads) {
                  return SizedBox.shrink();
                }
                return Positioned(
                  left: left,
                  top: top,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _showDownloads,
                    onPanUpdate: (details) {
                      setState(() {
                        final nextLeft = left + details.delta.dx;
                        final nextTop = top + details.delta.dy;
                        _left = nextLeft
                            .clamp(0.0, constraints.maxWidth - controlSize)
                            .toDouble();
                        _top = nextTop
                            .clamp(0.0, constraints.maxHeight - controlSize)
                            .toDouble();
                      });
                    },
                    child: Material(
                      elevation: 8,
                      color: Theme.of(context).colorScheme.secondary,
                      shape: CircleBorder(),
                      child: SizedBox(
                        width: controlSize,
                        height: controlSize,
                        child: Icon(
                          Icons.file_download,
                          color: Colors.white,
                          size: 27,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  void _showDownloads() {
    final navigatorContext = DownloadFloatingControl.navigatorKey.currentContext;
    if (navigatorContext == null) return;

    showModalBottomSheet<void>(
      context: navigatorContext,
      builder: (sheetContext) {
        return SafeArea(
          child: AnimatedBuilder(
            animation: _manager,
            builder: (context, child) {
              final tasks = _manager.tasks;
              if (tasks.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('No active downloads'),
                );
              }
              return ConstrainedBox(
                constraints: BoxConstraints(maxHeight: 420),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                      child: Row(
                        children: [
                          Icon(Icons.file_download),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Downloads',
                              style: Theme.of(context).textTheme.headline6,
                            ),
                          ),
                          Text('${tasks.length}'),
                        ],
                      ),
                    ),
                    Divider(height: 1),
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: tasks.length,
                        itemBuilder: (context, index) {
                          final task = tasks[index];
                          final percent = (task.progress * 100).round();
                          final status =
                              task.state == DownloadTaskState.downloading
                                  ? '$percent% • ${task.completedPages}/${task.totalPages} pages'
                                  : 'Queued';
                          return ListTile(
                            leading: SizedBox(
                              width: 38,
                              height: 38,
                              child: CircularProgressIndicator(
                                value: task.progress,
                                strokeWidth: 3,
                              ),
                            ),
                            title: Text(
                              '${task.book.metadata.number} — ${task.book.name}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(height: 5),
                                LinearProgressIndicator(value: task.progress),
                                SizedBox(height: 4),
                                Text(status),
                              ],
                            ),
                            trailing: IconButton(
                              tooltip: 'Cancel download',
                              icon: Icon(Icons.close),
                              onPressed: task.cancelRequested
                                  ? null
                                  : () => _manager.cancel(task.book.id),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}
