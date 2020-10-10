/*
* @auther : Mark
* @date : 2020-09-27
* @ide : VSCode
*/

import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'math_help.dart';

class NodirectionView extends StatefulWidget {
  NodirectionView(
      {@required this.child,
      this.height = double.infinity,
      this.width = double.infinity,
      this.dumpingEdge = const EdgeInsets.all(50),
      this.duration = const Duration(milliseconds: 100)});

  /// 子视图中不允许使用无限尺寸,包括
  /// [ListView] / [GridView]
  final Widget child;

  /// 高度
  final double height;

  /// 宽度
  final double width;

  /// 最大阻尼边距
  /// 超过范围后不会阻止移动,而是增大滑动阻力
  final EdgeInsets dumpingEdge;

  /// 动画时长 目前仅针对回弹动画
  final Duration duration;

  @override
  _NodirectionViewState createState() => _NodirectionViewState();
}

class _NodirectionViewState extends State<NodirectionView>
    with SingleTickerProviderStateMixin {
  NodirectionScrollController _scrollController;
  AnimationController _animationController;
  @override
  void initState() {
    super.initState();
    _animationController =
        AnimationController(vsync: this, duration: widget.duration);
    _scrollController = NodirectionScrollController(
        animationController: _animationController,
        position: NodirectionScrollPosition(dumpingEdge: widget.dumpingEdge));
  }

  @override
  void dispose() {
    super.dispose();
    _scrollController.dispose();
    _animationController.dispose();
  }

  void _onPangestureUpdate(PointerMoveEvent details) {
    _scrollController.appendOffset(details.delta);
  }

  void _onPangestureEnd(PointerUpEvent details) {
    _reloadPosition();
  }

  void _onPangestureCancel(PointerCancelEvent event) {
    _reloadPosition();
  }

  void _reloadPosition() {
    _scrollController.animateToFixPoint();
  }

  bool _animationInProgressing() =>
      (_animationController.status != AnimationStatus.forward &&
          _animationController.status != AnimationStatus.reverse);

  @override
  Widget build(BuildContext context) {
    Widget child = TickerMode(
      child: _NodirectionScrollView(
        offset: _scrollController.position,
        child: widget.child,
        panCancelCallBack: _onPangestureCancel,
        panEndCallBack: _onPangestureEnd,
        panUpdateCallBack: _onPangestureUpdate,
      ),
      enabled: !_animationInProgressing(),
    );

    return Container(
        height: widget.height,
        width: widget.width,
        color: Colors.transparent,
        child: child);
  }
}

// ignore: must_be_immutable
class _NodirectionScrollView extends SingleChildRenderObjectWidget {
  _NodirectionScrollView(
      {Widget child,
      Key key,
      @required this.offset,
      this.panUpdateCallBack,
      this.panCancelCallBack,
      this.panEndCallBack})
      : super(key: key, child: child);

  final NodirectionPanUpdateCallBack panUpdateCallBack;
  final NodirectionPanCancelCallBack panCancelCallBack;
  final NodirectionPanEndCallBack panEndCallBack;

  /// 坐标对象
  final NodirectionScrollPosition offset;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return NodirectionScrollRender(
        position: offset,
        panUpdateCallBack: panUpdateCallBack,
        panCancelCallBack: panCancelCallBack,
        panEndCallBack: panEndCallBack);
  }

  @override
  void updateRenderObject(
      BuildContext context, NodirectionScrollRender renderObject) {
    renderObject.offset = offset;
  }
}

/// 滑动控制器
class NodirectionScrollController {
  NodirectionScrollController(
      {AnimationController animationController,
      NodirectionScrollPosition position}) {
    _setAnimation(animationController);
    if (position != null) {
      _position = position;
    }
  }

  // 滑动位置
  NodirectionScrollPosition _position = NodirectionScrollPosition.zero();
  NodirectionScrollPosition get position => _position;

  // 下一个移动目标
  Offset _nextAimOffset;
  Offset _indexOffset;

  // 动画
  AnimationController _animation;
  void _setAnimation(AnimationController animation) {
    if (animation == null) return;
    if (animation == _animation) return;
    if (_animation != null) {
      _animation
        ..removeListener(_animateProgressingListener)
        ..removeStatusListener(_animateStatusListener);
    }
    _animation = animation;
    _animation
      ..addListener(_animateProgressingListener)
      ..addStatusListener(_animateStatusListener);
  }

  // 添加偏移距离
  void appendOffset(Offset offset) {
    _indexOffset = _position.offset;
    _position.appendOffset(offset);
  }

  // 动态移动
  // @param offset 绝对坐标
  void animateTo(Offset offset) {
    if (_animation == null) return;
    if (offset == null) return;
    _nextAimOffset = offset;
    _indexOffset = position.offset;
    _animation.forward(from: 0.0);
  }

  // 移动到最佳悬停点
  void animateToFixPoint() {
    animateTo(position.holdingPoint());
  }

  // 动画监听
  void _animateProgressingListener() {
    if (_nextAimOffset == null || _indexOffset == null) return;
    if (_animation.status == AnimationStatus.completed ||
        _animation.status == AnimationStatus.dismissed) return;
    Offset stepOffset = Offset(
        _indexOffset.dx -
            (_indexOffset.dx - _nextAimOffset.dx) * _animation.value,
        _indexOffset.dy -
            (_indexOffset.dy - _nextAimOffset.dy) * _animation.value);
    position.moveTo(stepOffset);
  }

  // 动画状态监听
  void _animateStatusListener(AnimationStatus status) {
    if (status == AnimationStatus.forward ||
        status == AnimationStatus.reverse) {
      return;
    }
    if (_nextAimOffset != null && _animation.value != 0) {
      _position.moveTo(_nextAimOffset);
      _nextAimOffset = null;
    }
  }

  void dispose() {
    _animation?.removeListener(_animateProgressingListener);
    _animation?.removeStatusListener(_animateStatusListener);
  }
}

/// 滑动偏移点坐标
class NodirectionScrollPosition extends ChangeNotifier {
  NodirectionScrollPosition(
      {double dx = 0,
      double dy = 0,
      this.dumpingEdge = const EdgeInsets.all(50)}) {
    this.dx = dx;
    this.dy = dy;
  }
  static NodirectionScrollPosition zero() =>
      NodirectionScrollPosition(dx: 0, dy: 0, dumpingEdge: EdgeInsets.zero);
  double dx;
  double dy;

  // 阻尼距离
  final EdgeInsets dumpingEdge;

  // 当前偏移距离
  Offset get offset => Offset(dx, dy);

  // 内容区大小
  Size _contentSize;
  set contentSize(Size contentsize) {
    if (contentsize == null) return;
    _contentSize = contentsize;
  }

  // 容器大小
  Size _containerSize;
  set containerSize(Size containerSize) {
    if (containerSize == null) return;
    _containerSize = containerSize;
  }

  bool sizeReady() => _contentSize != null && _containerSize != null;

  // 保持悬停位置,寻找最佳停靠点
  Offset holdingPoint() {
    if (!sizeReady()) return offset;
    double holdx, holdy;
    if (offset.dx > 0) {
      holdx = 0;
    } else if (offset.dx < (_containerSize.width - _contentSize.width)) {
      holdx = _containerSize.width - _contentSize.width;
    } else {
      holdx = offset.dx;
    }

    if (offset.dy > 0) {
      holdy = 0;
    } else if (offset.dy < (_containerSize.height - _contentSize.height)) {
      holdy = _containerSize.height - _contentSize.height;
    } else {
      holdy = offset.dy;
    }
    return Offset(holdx, holdy);
  }

  void appendOffset(Offset offset) {
    this.dx = _formula(this.dx, offset.dx, Axis.horizontal);
    this.dy = _formula(this.dy, offset.dy, Axis.vertical);
    update();
  }

  void moveTo(Offset offset) {
    this.dx = offset.dx;
    this.dy = offset.dy;
    update();
  }

  /// 更新位置信息
  void update() => this..notifyListeners();

  /// 重置位置
  void reload() => this
    ..dx = 0
    ..dy = 0
    ..notifyListeners();

  /// 点在内容区域内
  bool pointInContent(Offset point, {bool tolerant = false}) {
    return valueInContent(point.dx, Axis.horizontal, tolerant: tolerant) &&
        valueInContent(point.dy, Axis.vertical, tolerant: tolerant);
  }

  /// 数值是否在内容区间的对应方向内
  bool valueInContent(double value, Axis direction, {bool tolerant = false}) {
    if (!sizeReady()) return false;
    double start, end;
    if (direction == Axis.horizontal) {
      start = tolerant ? dumpingEdge.left : 0;
      end = (_containerSize.width - _contentSize.width) +
          (tolerant ? dumpingEdge.right : 0);
    } else {
      start = tolerant ? dumpingEdge.top : 0;
      end = (_containerSize.height - _contentSize.height) +
          (tolerant ? dumpingEdge.bottom : 0);
    }
    return (value >= min(start, end) && value <= max(start, end));
  }

  /// 计算阻尼距离
  /// 此处需要优化为曲线方程,否则边距超大时会有阶梯效果,不够平滑
  double _formula(double index, double step, Axis direction) {
    double dep;
    double nextVal = index + step;
    double factor = 0;
    if (valueInContent(index + step, direction)) {
      return index + step;
    }
    if (direction == Axis.horizontal) {
      if (index > 0) {
        factor = dumpingEdge.left;
      } else {
        factor = dumpingEdge.right;
      }
    } else {
      if (index > 0) {
        factor = dumpingEdge.top;
      } else {
        factor = dumpingEdge.bottom;
      }
    }
    double force = (nextVal < 0 ? -nextVal : nextVal) / factor;
    if (force < 0.3) {
      dep = 0.7;
    } else if (force < 0.6) {
      dep = 0.4;
    } else if (force < 1.0) {
      dep = 0.2;
    } else {
      dep = 0.1;
    }
    return index + dep * step;
  }

  @override
  String toString() {
    return "Position Offset($dx,$dy) contentSize : $_contentSize containerSize : $_containerSize";
  }
}

class _NodirectionScrollParentData extends ContainerBoxParentData<RenderBox> {}

/// 滑动回调
typedef NodirectionPanUpdateCallBack = void Function(PointerMoveEvent);

/// 滑动取消回调
typedef NodirectionPanCancelCallBack = void Function(PointerCancelEvent);

/// 滑动结束回调
typedef NodirectionPanEndCallBack = void Function(PointerUpEvent);

class NodirectionScrollRender extends RenderBox
    with
        RenderBoxContainerDefaultsMixin<RenderBox,
            _NodirectionScrollParentData>,
        ContainerRenderObjectMixin<RenderBox, _NodirectionScrollParentData>,
        RenderObjectWithChildMixin {
  // Init
  NodirectionScrollRender(
      {@required NodirectionScrollPosition position,
      this.panUpdateCallBack,
      this.panCancelCallBack,
      this.panEndCallBack}) {
    _position = position ?? NodirectionScrollPosition.zero();
    _position.addListener(markNeedsPaint);
  }

  final NodirectionPanUpdateCallBack panUpdateCallBack;
  final NodirectionPanCancelCallBack panCancelCallBack;
  final NodirectionPanEndCallBack panEndCallBack;

  /// 针对event的滑动距离追踪
  double _eventTracker = 0;

  // 滑动偏移量
  NodirectionScrollPosition _position;
  NodirectionScrollPosition get offset => _position;
  set offset(NodirectionScrollPosition value) {
    if (value == null) return;
    if (value == _position) return;
    if (attached) _position.removeListener(markNeedsPaint);
    _position = value;
    if (attached) _position.addListener(markNeedsPaint);
    markNeedsPaint();
  }

  @override
  void markNeedsPaint() {
    if (!attached) return;
    super.markNeedsPaint();
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    context.pushClipRect(needsCompositing, offset, Offset.zero & size,
        (context, offset) {
      context.paintChild(this.child, this.offset.offset + offset);
      if (this.child.attached) {
        _position.contentSize = (child as RenderBox).size;
      }
    });
  }

  @override
  void setupParentData(RenderObject child) {
    if (child is! _NodirectionScrollParentData)
      child.parentData = _NodirectionScrollParentData();
  }

  @override
  void performLayout() {
    super.performLayout();
    BoxConstraints subConstraints = BoxConstraints(
      minWidth: constraints.maxWidth,
      minHeight: constraints.maxHeight,
      maxHeight: double.infinity, //constraints.maxHeight - this.offset.dy,
      maxWidth: double.infinity, //constraints.maxWidth - this.offset.dx,
    );
    this.child.layout(subConstraints, parentUsesSize: false);
    _position.containerSize = size;
  }

  @override
  bool hitTest(BoxHitTestResult result, {Offset position}) {
    if (size.contains(position)) {
      if (child.attached &&
          (child as RenderBox).hitTest(result, position: position)) {
        result.add(BoxHitTestEntry(child, position));
      }
      result.add(BoxHitTestEntry(this, position));
      if (result.path.length > 0) return true;
    }
    return false;
  }

  /// 不处理点击事件
  @override
  void handleEvent(PointerEvent event, BoxHitTestEntry entry) {
    super.handleEvent(event, entry);
    if (entry.target != this) return;
    switch (event.runtimeType) {
      case PointerMoveEvent:
        _eventTracker += (abs(event.delta.dx) + abs(event.delta.dy));
        if (panUpdateCallBack != null) panUpdateCallBack(event);
        break;
      case PointerCancelEvent:
        if (0 != _eventTracker && panCancelCallBack != null)
          panCancelCallBack(event);
        break;
      case PointerUpEvent:
        if (0 != _eventTracker && panEndCallBack != null) panEndCallBack(event);
        break;
      case PointerDownEvent:
        _eventTracker = 0;
        break;
      default:
    }
  }

  @override
  bool get isRepaintBoundary => true;

  @override
  bool get sizedByParent => true;
}
