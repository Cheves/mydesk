// 浮动拖动球：用于在安卓端拖动远程桌面画布

import 'package:flutter/material.dart';
import 'package:flutter_hbb/common.dart';
import 'package:flutter_hbb/models/model.dart';

const double _kDragBallSize = 48.0;
const double _kSpaceToEdge = 20.0;
final Color _kDragBallColor = Colors.blue.withOpacity(0.7);
final Color _kDragBallActiveColor = Colors.blueAccent.withOpacity(0.8);

class FloatingDragBall extends StatefulWidget {
  final FFI ffi;
  const FloatingDragBall({
    super.key,
    required this.ffi,
  });

  @override
  State<FloatingDragBall> createState() => _FloatingDragBallState();
}

class _FloatingDragBallState extends State<FloatingDragBall> {
  Offset _position = Offset.zero;
  bool _isInitialized = false;
  bool _isDragging = false;
  Offset? _dragStartPosition;

  CanvasModel get _canvasModel => widget.ffi.canvasModel;
  FfiModel get _ffiModel => widget.ffi.ffiModel;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _resetPosition();
    });
  }

  void _resetPosition() {
    if (!mounted) return;
    setState(() {
      final size = MediaQuery.of(context).size;
      // 默认位置：右下角
      _position = Offset(
        size.width - _kDragBallSize - _kSpaceToEdge,
        size.height - _kDragBallSize - _kSpaceToEdge,
      );
      _isInitialized = true;
    });
  }

  void _onPanStart(DragStartDetails details) {
    setState(() {
      _isDragging = true;
      _dragStartPosition = _position;
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (!_isDragging) return;

    final context = this.context;
    final size = MediaQuery.of(context).size;
    
    // 更新球的位置（限制在屏幕内）
    setState(() {
      Offset newPosition = _position + details.delta;
      newPosition = Offset(
        newPosition.dx.clamp(_kSpaceToEdge, size.width - _kDragBallSize - _kSpaceToEdge),
        newPosition.dy.clamp(_kSpaceToEdge, size.height - _kDragBallSize - _kSpaceToEdge),
      );
      _position = newPosition;
    });

    // 使用 details.delta 直接获取拖动增量，用于平移画布
    // 平移画布（上下左右）
    _canvasModel.panX(details.delta.dx);
    _canvasModel.panY(details.delta.dy);
  }

  void _onPanEnd(DragEndDetails details) {
    setState(() {
      _isDragging = false;
      _dragStartPosition = null;
    });
  }

  void _onPanCancel() {
    setState(() {
      _isDragging = false;
      _dragStartPosition = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    // 仅在安卓端且控制非移动设备时显示
    if (!isAndroid || _ffiModel.isPeerMobile || !_isInitialized) {
      return Offstage();
    }

    return Positioned(
      left: _position.dx,
      top: _position.dy,
      child: GestureDetector(
        onPanStart: _onPanStart,
        onPanUpdate: _onPanUpdate,
        onPanEnd: _onPanEnd,
        onPanCancel: _onPanCancel,
        child: Container(
          width: _kDragBallSize,
          height: _kDragBallSize,
          decoration: BoxDecoration(
            color: _isDragging ? _kDragBallActiveColor : _kDragBallColor,
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withOpacity(0.5),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            Icons.pan_tool,
            color: Colors.white,
            size: _kDragBallSize * 0.5,
          ),
        ),
      ),
    );
  }
}

