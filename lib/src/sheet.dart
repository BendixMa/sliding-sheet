import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'util.dart';

part 'scrolling.dart';
part 'sheet_dialog.dart';
part 'specs.dart';

typedef SheetBuilder = Widget Function(BuildContext context, SheetState state);

typedef CustomScrollbarBuilder = Widget Function(BuildContext context, SheetState state, _SlidingSheetScrollController controller, Widget child);

typedef SheetListener = void Function(SheetState state);

typedef OnDismissPreventedCallback = void Function(bool backButton, bool backDrop);

/// A widget that can be dragged and scrolled in a single gesture and snapped
/// to a list of extents.
///
/// The [builder] parameter must not be null.
class SlidingSheet extends StatefulWidget {
  /// {@template sliding_sheet.builder}
  /// The builder for the main content of the sheet that will be scrolled if
  /// the content is bigger than the height that the sheet can expand to.
  /// {@endtemplate}
  final SheetBuilder builder;

  /// Builder for custom scrollbars, wraps whole widget returned by 'builder' function.
  /// 'customScrollbarBuilder comes with 'controller' parameter, which provides access to the inner ScrollController of sheet.
  /// Keep in mind that 'builder' wraps it's child in SingleChildScrollView(), so your custom scrollbar must be able to work with this widget as its child.
  ///
  /// If you want to use it with draggable_scrollbar package (https://pub.dev/packages/draggable_scrollbar),
  /// then manually change it's 'child' type from 'BoxScrollView' to 'SingleChildScrollView' in the source file.
  /// Then use it like this:
  /// SlidingSheet(
  ///   ...
  ///    customScrollbarBuilder: (context, state, scrollController, child) {
  ///      return DraggableScrollbar.semicircle(
  ///          controller: scrollController,
  ///          child: child
  ///     },
  ///   ...
  /// )
  final CustomScrollbarBuilder customScrollbarBuilder;

  /// {@template sliding_sheet.headerBuilder}
  /// The builder for a header that will be displayed at the top of the sheet
  /// that wont be scrolled.
  /// {@endtemplate}
  final SheetBuilder headerBuilder;

  /// Second header to be shown when sheet is collapsed
  final SheetBuilder collapsedHeaderBuilder;

  /// {@template sliding_sheet.footerBuilder}
  /// The builder for a footer that will be displayed at the bottom of the sheet
  /// that wont be scrolled.
  /// {@endtemplate}
  final SheetBuilder footerBuilder;

  /// {@template sliding_sheet.snapSpec}
  /// The [SnapSpec] that defines how the sheet should snap or if it should at all.
  /// {@endtemplate}
  final SnapSpec snapSpec;

  /// {@template sliding_sheet.duration}
  /// The base animation duration for the sheet. Swipes and flings may have a different duration.
  /// {@endtemplate}
  final Duration duration;

  /// {@template sliding_sheet.color}
  /// The background color of the sheet.
  /// {@endtemplate}
  final Color color;

  /// {@template sliding_sheet.backdropColor}
  /// The color of the shadow that is displayed behind the sheet.
  /// {@endtemplate}
  final Color backdropColor;

  /// {@template sliding_sheet.shadowColor}
  /// The color of the drop shadow of the sheet when [elevation] is > 0.
  /// {@endtemplate}
  final Color shadowColor;

  /// {@template sliding_sheet.elevation}
  /// The elevation of the sheet.
  /// {@endtemplate}
  final double elevation;

  /// {@template sliding_sheet.padding}
  /// The amount to inset the children of the sheet.
  /// {@endtemplate}
  final EdgeInsets padding;

  /// {@template sliding_sheet.addTopViewPaddingWhenAtFullscreen}
  /// If true, adds the top padding returned by
  /// `MediaQuery.of(context).viewPadding.top` to the [padding] when taking
  /// up the full screen.
  ///
  /// This can be used to easily avoid the content of the sheet from being
  /// under the statusbar, which is especially useful when having a header.
  /// {@endtemplate}
  final bool addTopViewPaddingOnFullscreen;

  /// {@template sliding_sheet.margin}
  /// The amount of the empty space surrounding the sheet.
  /// {@endtemplate}
  final EdgeInsets margin;

  /// {@template sliding_sheet.border}
  /// A border that will be drawn around the sheet.
  /// {@endtemplate}
  final Border border;

  /// {@template sliding_sheet.cornerRadius}
  /// The radius of the top corners of this sheet.
  /// {@endtemplate}
  final double cornerRadius;

  /// {@template sliding_sheet.cornerRadiusOnFullscreen}
  /// The radius of the top corners of this sheet when expanded to fullscreen.
  ///
  /// This parameter can be used to easily implement the common Material
  /// behaviour of sheets to go from rounded corners to sharp corners when
  /// taking up the full screen.
  /// {@endtemplate}
  final double cornerRadiusOnFullscreen;

  /// If true, will collapse the sheet when the sheets backdrop was tapped.
  final bool closeOnBackdropTap;

  /// {@template sliding_sheet.listener}
  /// A callback that will be invoked when the sheet gets dragged or scrolled
  /// with current state information.
  /// {@endtemplate}
  final SheetListener listener;

  /// {@template sliding_sheet.controller}
  /// A controller to control the state of the sheet.
  /// {@endtemplate}
  final SheetController controller;

  /// {@template sliding_sheet.scrollSpec}
  /// The [ScrollSpec] of the containing ScrollView.
  /// {@endtemplate}
  final ScrollSpec scrollSpec;

  /// {@template sliding_sheet.maxWidth}
  /// The maximum width of the sheet.
  ///
  /// Usually set for large screens. By default the [SlidingSheet]
  /// expands to the total available width.
  /// {@endtemplate}
  final double maxWidth;

  /// {@template sliding_sheet.maxWidth}
  /// The minimum height of the sheet the child return by the `builder`.
  ///
  /// By default, the sheet sizes itself as big as its child.
  /// {@endtemplate}
  final double minHeight;

  /// {@template sliding_sheet.closeSheetOnBackButtonPressed}
  /// If true, closes the sheet when it is open and prevents the route
  /// from being popped.
  /// {@endtemplate}
  final bool closeSheetOnBackButtonPressed;

  /// {@template sliding_sheet.isBackDropInteractable}
  /// If true, the backDrop will also be interactable so any gesture
  /// that is applied to the backDrop will be delegated to the sheet
  /// itself.
  /// {@endtemplate}
  final bool isBackdropInteractable;

  /// A widget that is placed behind the sheet.
  ///
  /// You can apply a parallax effect to this widget by
  /// setting the [parallaxSpec] parameter.
  final Widget body;

  /// {@template sliding_sheet.parallaxSpec}
  /// A [ParallaxSpec] to create a parallax effect.
  ///
  /// The parallax effect is an effect that appears when different layers of backgrounds
  /// are moved at different speeds and thereby create the effect of motion and depth. By moving
  /// the [SlidingSheet] faster than the [body] the depth effect is achieved.
  /// {@endtemplate}
  final ParallaxSpec parallaxSpec;

  /// {@template sliding_sheet.axisAlignment}
  /// How to align the sheet on the horizontal axis when the available width is bigger
  /// than the `maxWidth` of the sheet.
  ///
  /// The value must be in the range from `-1.0` (far left) and `1.0` (far right).
  ///
  /// Defaults to `0.0` (center).
  /// {@endTemplate}
  final double axisAlignment;

  // * SlidingSheetDialog fields

  final _SlidingSheetRoute route;

  /// {@template sliding_sheet.isDismissable}
  /// If false, the `SlidingSheetDialog` will not be dismissable.
  ///
  /// That means that the user wont be able to close the sheet using gestures or back button.
  /// {@endtemplate}
  final bool isDismissable;

  /// {@template sliding_sheet.onDismissPrevented}
  /// A callback that gets invoked when a user tried to dismiss the dialog
  /// while [isDimissable] is set to `true`.
  ///
  /// The `backButton` flag indicates whether the user tried to dismiss the sheet
  /// using the backButton, while the `backDrop` flag indicates whether the user tried
  /// to dismiss the sheet by tapping the backdrop.
  /// {@endtemplate}
  final OnDismissPreventedCallback onDismissPrevented;

  /// Sets the opacity for sheet background when it's minimized
  final double collapsedPanelOpacity;

  /// When enabled, sheet's children are faded out as sheet slides down.
  /// Enable this if you don't want sheet's content to be visible when collapsed.
  final bool fadeContentOnCollapse;

  /// Creates a sheet than can be dragged and scrolled in a single gesture to be
  /// placed inside you widget tree.
  ///
  /// The `builder` callback is used to build the main content of the sheet that
  /// will be scrolled if the content is bigger than the height that the sheet can expand to.
  ///
  /// The `headerBuilder` and `footerBuilder` can be used to build persistent widget on top
  /// and bottom respectively, that wont be scrolled but will delegate the interactions on
  /// them to the sheet.
  ///
  /// The `listener` callback is being invoked when the sheet gets dragged or scrolled
  /// with current state information.
  ///
  /// The `snapSpec` can be used to customize the snapping behavior. There you can custom snap
  /// extents, whether the sheet should snap at all, and how to position those snaps.
  ///
  /// If `addTopViewPaddingOnFullscreen` is set to true, the sheet will add the status bar height
  /// as a top padding to it in order to avoid the status bar it it is translucent.
  ///
  /// The `cornerRadiusOnFullscreen` parameter can be used to easily implement the common Material
  /// behaviour of sheets to go from rounded corners to sharp corners when
  /// taking up the full screen.
  ///
  /// The `body` parameter can be used to place a widget behind the sheet and a parallax effect can
  /// be applied to it using the `parallaxSpec` parameter.
  ///
  /// The `axisAlignment` parameter can be used to align the sheet on the horizontal axis when the available
  /// width is bigger than the `maxWidth` of the sheet.
  SlidingSheet({
    Key key,
    @required SheetBuilder builder,
    SheetBuilder headerBuilder,
    SheetBuilder collapsedHeaderBuilder,
    SheetBuilder footerBuilder,
    CustomScrollbarBuilder customScrollbarBuilder,
    SnapSpec snapSpec = const SnapSpec(),
    Duration duration = const Duration(milliseconds: 1000),
    Color color = Colors.white,
    Color backdropColor,
    Color shadowColor = Colors.black54,
    Curve curve = Curves.easeInCubic,
    double elevation = 0.0,
    EdgeInsets padding,
    bool addTopViewPaddingOnFullscreen = false,
    EdgeInsets margin,
    Border border,
    double cornerRadius = 0.0,
    double cornerRadiusOnFullscreen,
    bool closeOnBackdropTap = false,
    SheetListener listener,
    SheetController controller,
    ScrollSpec scrollSpec = const ScrollSpec(overscroll: false),
    double maxWidth = double.infinity,
    double minHeight,
    bool closeOnBackButtonPressed = false,
    bool isBackdropInteractable = false,
    Widget body,
    ParallaxSpec parallaxSpec,
    double axisAlignment = 0.0,
    double collapsedPanelOpacity = 1.0,
    bool fadeContentOnCollapse = false
  }) : this._(
          key: key,
          builder: builder,
      customScrollbarBuilder: customScrollbarBuilder,
          headerBuilder: headerBuilder,
      collapsedHeaderBuilder: collapsedHeaderBuilder,
          footerBuilder: footerBuilder,
          snapSpec: snapSpec,
          duration: duration,
          color: color,
          backdropColor: backdropColor,
          shadowColor: shadowColor,
          elevation: elevation,
          padding: padding,
          addTopViewPaddingOnFullscreen: addTopViewPaddingOnFullscreen,
          margin: margin,
          border: border,
          cornerRadius: cornerRadius,
          cornerRadiusOnFullscreen: cornerRadiusOnFullscreen,
          closeOnBackdropTap: closeOnBackdropTap,
          listener: listener,
          controller: controller,
          scrollSpec: scrollSpec,
          maxWidth: maxWidth,
          minHeight: minHeight,
          closeSheetOnBackButtonPressed: closeOnBackButtonPressed,
          isBackdropInteractable: isBackdropInteractable,
          body: body,
          parallaxSpec: parallaxSpec,
          axisAlignment: axisAlignment,
      collapsedPanelOpacity: collapsedPanelOpacity,
      fadeContentOnCollapse: fadeContentOnCollapse
        );

  SlidingSheet._({
    Key key,
    @required this.builder,
    @required this.headerBuilder,
    this.collapsedHeaderBuilder,
    this.customScrollbarBuilder,
    @required this.footerBuilder,
    @required this.snapSpec,
    @required this.duration,
    @required this.color,
    @required this.backdropColor,
    @required this.shadowColor,
    @required this.elevation,
    @required this.padding,
    @required this.addTopViewPaddingOnFullscreen,
    @required this.margin,
    @required this.border,
    @required this.cornerRadius,
    @required this.cornerRadiusOnFullscreen,
    @required this.closeOnBackdropTap,
    @required this.listener,
    @required this.controller,
    @required this.scrollSpec,
    @required this.maxWidth,
    @required this.minHeight,
    @required this.closeSheetOnBackButtonPressed,
    @required this.isBackdropInteractable,
    @required this.axisAlignment,
    this.body,
    this.parallaxSpec,
    this.route,
    this.isDismissable = true,
    this.onDismissPrevented,
    this.collapsedPanelOpacity = 1.0,
    this.fadeContentOnCollapse = false
  })  : assert(builder != null),
        assert(duration != null),
        assert(snapSpec != null),
        assert(snapSpec.snappings.length >= 2, 'There must be at least two snapping extents to snap in between.'),
        assert(snapSpec.minSnap != snapSpec.maxSnap || route != null, 'The min and max snaps cannot be equal.'),
        assert(isDismissable != null),
        assert(isBackdropInteractable != null),
        assert(axisAlignment != null && (axisAlignment >= -1.0 && axisAlignment <= 1.0)),
        super(key: key);

  @override
  _SlidingSheetState createState() => _SlidingSheetState();
}

class _SlidingSheetState extends State<SlidingSheet> with TickerProviderStateMixin {
  GlobalKey childKey;
  GlobalKey headerKey;
  GlobalKey footerKey;

  Widget child;
  Widget header;
  Widget collapsedHeader;
  Widget footer;

  Widget customScrollBar;
  BuildContext _context;

  List<double> snappings;

  double childHeight = 0;
  double headerHeight = 0;
  double collapsedHeaderHeight = 0;
  double footerHeight = 0;
  double availableHeight = 0;

  bool didCompleteInitialRoute = false;
  // Whether a dismiss was already triggered by the sheet itself
  // and thus further route pops can be safely ignored.
  bool dismissUnderway = false;
  // Whether the drag on a delegating widget (such as the backdrop)
  // did start, when the sheet was not fully collapsed.
  bool didStartDragWhenNotCollapsed = false;
  // The current sheet extent.
  _SheetExtent extent;
  // The currently assigned SheetController
  SheetController sheetController;
  // The ScrollController for the sheet.
  _SlidingSheetScrollController controller;

  // Whether the sheet has drawn its first frame.
  bool get isLaidOut => availableHeight > 0 && childHeight > 0;
  // The total height of all sheet components.
  double get sheetHeight => childHeight + headerHeight + footerHeight + padding.vertical + borderHeight;
  // The maxiumum height that this sheet will cover.
  double get maxHeight => math.min(sheetHeight, availableHeight);
  bool get isCoveringFullExtent => sheetHeight >= availableHeight;

  double get currentExtent => (extent?.currentExtent ?? minExtent).clamp(0.0, 1.0);
  set currentExtent(double value) => extent?.currentExtent = value;
  double get headerExtent => isLaidOut ? (headerHeight + (borderHeight / 2)) / availableHeight : 0.0;
  double get footerExtent => isLaidOut ? (footerHeight + (borderHeight / 2)) / availableHeight : 0.0;
  double get headerFooterExtent => headerExtent + footerExtent;
  double get minExtent => snappings[fromBottomSheet ? 1 : 0].clamp(0.0, 1.0);
  double get maxExtent => snappings.last.clamp(0.0, 1.0);
  double get initialExtent => snapSpec.initialSnap != null ? _normalizeSnap(snapSpec.initialSnap) : minExtent;

  bool get fromBottomSheet => widget.route != null;
  ScrollSpec get scrollSpec => widget.scrollSpec;
  SnapSpec get snapSpec => widget.snapSpec;
  SnapPositioning get snapPositioning => snapSpec.positioning;

  double get borderHeight => (widget.border?.top?.width ?? 0) * 2;
  EdgeInsets get padding {
    final begin = widget.padding ?? const EdgeInsets.all(0);

    if (!widget.addTopViewPaddingOnFullscreen || !isLaidOut) {
      return begin;
    }

    final statusBarHeight = MediaQuery.of(context).viewPadding.top;
    final end = begin.copyWith(top: begin.top + statusBarHeight);
    return EdgeInsets.lerp(begin, end, lerpFactor);
  }

  double get cornerRadius {
    if (widget.cornerRadiusOnFullscreen == null) return widget.cornerRadius;
    return lerpDouble(widget.cornerRadius, widget.cornerRadiusOnFullscreen, lerpFactor);
  }

  double get lerpFactor {
    if (maxExtent != 1.0 && isLaidOut) return 0.0;

    final snap = snappings[math.max(snappings.length - 2, 0)];
    return Interval(
      snap >= 0.7 ? snap : 0.85,
      1.0,
    ).transform(currentExtent);
  }

  /// Opacity value for backdrop, sheet content, background and collapsedHeader
  double opacity = 0.0;

  // The current state of this sheet.
  SheetState get state => SheetState(
        extent,
        extent: _reverseSnap(currentExtent),
        minExtent: _reverseSnap(minExtent),
        maxExtent: _reverseSnap(maxExtent),
        isLaidOut: isLaidOut,
      );

  @override
  void initState() {
    super.initState();
    // Assign the keys that will be used to determine the size of
    // the children.
    childKey = GlobalKey();
    headerKey = GlobalKey();
    footerKey = GlobalKey();

    _updateSnappingsAndExtent();

    // Call the listener when the extent or scroll position changes.
    void listener() {
      if (isLaidOut) {
        postFrame(() {
          final state = this.state;
          widget.listener?.call(state);
          sheetController?._state = state;
        });
      }
    }

    controller = _SlidingSheetScrollController(
      this,
    )..addListener(listener);

    extent = _SheetExtent(
      controller,
      isFromBottomSheet: fromBottomSheet,
      snappings: snappings,
      listener: (extent) => listener(),
    );

    _assignSheetController();

    _measure();

    if (fromBottomSheet) {
      _initBottomSheet();
    } else {
      // Set the inital extent after the first frame.
      postFrame(
        () => setState(
          () => currentExtent = initialExtent,
        ),
      );
    }
  }

  void _initBottomSheet() {
    postFrame(() {
      // Snap to the initial snap with a one frame delay when the
      // extents have been correctly calculated.
      snapToExtent(initialExtent);

      // When the route gets popped we animate fully out - not just
      // to the minExtent.
      widget.route.popped.then(
        (_) {
          if (!dismissUnderway) {
            dismissUnderway = true;
            controller.jumpTo(controller.offset);
            controller.snapToExtent(0.0, this, clamp: false);
          }
        },
      );

      Future.delayed(widget.duration, () => didCompleteInitialRoute = true);
    });
  }

  @override
  void didUpdateWidget(SlidingSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    _assignSheetController();

    // Animate to the next snap if the SnapSpec changed and the sheet
    // is currently not interacted with.
    if (oldWidget.snapSpec != snapSpec) {
      _updateSnappingsAndExtent();
      _nudgeToNextSnap();
    }
  }

  // Measure the height of all sheet components.
  void _measure() {
    postFrame(() {
      final RenderBox child = childKey?.currentContext?.findRenderObject();
      final RenderBox header = headerKey?.currentContext?.findRenderObject();
      final RenderBox footer = footerKey?.currentContext?.findRenderObject();

      final isChildLaidOut = child?.hasSize == true;
      childHeight = isChildLaidOut ? child.size.height : 0;

      final isHeaderLaidOut = header?.hasSize == true;
      headerHeight = isHeaderLaidOut ? header.size.height : 0;

      final isFooterLaidOut = footer?.hasSize == true;
      footerHeight = isFooterLaidOut ? footer.size.height : 0;

      _updateSnappingsAndExtent();
    });
  }

  // A snap is defined relative to its availableHeight.
  // Here we handle all available snap positions and normalize them
  // to the availableHeight.
  double _normalizeSnap(double snap) {
    void isValidRelativeSnap([String message]) {
      assert(
        SnapSpec._isSnap(snap) || (snap >= 0.0 && snap <= 1.0),
        message ?? 'Relative snap $snap is not in the range [0..1].',
      );
    }

    if (availableHeight > 0) {
      final maxPossibleExtent = isLaidOut ? (sheetHeight / availableHeight).clamp(0.0, 1.0) : 1.0;
      double extent = snap;
      switch (snapPositioning) {
        case SnapPositioning.relativeToAvailableSpace:
          isValidRelativeSnap();
          break;
        case SnapPositioning.relativeToSheetHeight:
          isValidRelativeSnap();
          extent = (snap * maxHeight) / availableHeight;
          break;
        case SnapPositioning.pixelOffset:
          extent = snap / availableHeight;
          break;
        default:
          return snap.clamp(0.0, 1.0);
      }

      if (snap == SnapSpec.headerSnap) {
        assert(header != null, 'There is no available header to snap to!');
        extent = headerExtent;
      } else if (snap == SnapSpec.footerSnap) {
        assert(footer != null, 'There is no available footer to snap to!');
        extent = footerExtent;
      } else if (snap == SnapSpec.headerFooterSnap) {
        assert(header != null || footer != null, 'There is neither a header nor a footer to snap to!');
        extent = headerFooterExtent;
      } else if (snap == double.infinity) {
        extent = maxPossibleExtent;
      }

      return math.min(extent, maxPossibleExtent).clamp(0.0, 1.0);
    } else {
      return snap.clamp(0.0, 1.0);
    }
  }

  // Reverse a normalized snap.
  double _reverseSnap(double snap) {
    if (isLaidOut && childHeight > 0) {
      switch (snapPositioning) {
        case SnapPositioning.relativeToAvailableSpace:
          return snap;
        case SnapPositioning.relativeToSheetHeight:
          return snap * (availableHeight / sheetHeight);
        case SnapPositioning.pixelOffset:
          return snap * availableHeight;
        default:
          return snap.clamp(0.0, 1.0);
      }
    } else {
      return snap.clamp(0.0, 1.0);
    }
  }

  void _updateSnappingsAndExtent() {
    snappings = snapSpec.snappings.map(_normalizeSnap).toList()..sort();

    if (extent != null) {
      extent
        ..snappings = snappings
        ..targetHeight = maxHeight
        ..childHeight = childHeight
        ..headerHeight = headerHeight
        ..footerHeight = footerHeight
        ..availableHeight = availableHeight
        ..maxExtent = maxExtent
        ..minExtent = minExtent;
    }
  }

  // Assign the controller functions to actual methods.
  void _assignSheetController() {
    // Always assing a SheetController to be able to inherit from it
    sheetController = widget.controller ?? SheetController();

    // Assign the controller functions to the state functions.
    sheetController._scrollTo = scrollTo;
    sheetController._snapToExtent = (snap, {duration, clamp}) {
      return snapToExtent(_normalizeSnap(snap), duration: duration, clamp: clamp);
    };
    sheetController._expand = () => snapToExtent(maxExtent);
    sheetController._collapse = () => snapToExtent(minExtent);

    if (!fromBottomSheet) {
      sheetController._rebuild = rebuild;
      sheetController._show = () async {
        if (state.isHidden) return snapToExtent(minExtent, clamp: false);
      };
      sheetController._hide = () async {
        if (state.isShown) return snapToExtent(0.0, clamp: false);
      };
    }
  }

  Future<void> snapToExtent(double snap, {Duration duration, double velocity = 0, bool clamp}) async {
    if (!isLaidOut) return;

    duration ??= widget.duration;
    if (!state.isAtTop) {
     // duration *= 0.5;
      await controller.animateTo(
        0,
        duration: duration,
        curve: Curves.easeInCubic,
      );
    }

    return controller.snapToExtent(
      snap,
      this,
      duration: duration,
      velocity: velocity,
      clamp: clamp ?? (!fromBottomSheet || (fromBottomSheet && snap != 0.0)),
    );
  }

  Future<void> scrollTo(double offset, {Duration duration, Curve curve}) async {
    if (!isLaidOut) return;

    duration ??= widget.duration;
    if (!extent.isAtMax) {
      duration *= 0.5;
      await snapToExtent(
        maxExtent,
        duration: duration,
      );
    }

    return controller.animateTo(
      offset,
      duration: duration ?? widget.duration,
      curve: curve ?? (!extent.isAtMax ? Curves.easeOutCirc : Curves.ease),
    );
  }

  void _nudgeToNextSnap() {
    if (!controller.inInteraction) {
      controller.delegateFling();
    }
  }

  void _pop(double velocity) {
    if (fromBottomSheet && !dismissUnderway && Navigator.canPop(context)) {
      dismissUnderway = true;
      Navigator.pop(context);
      snapToExtent(0.0, velocity: velocity);
    } else if (!fromBottomSheet) {
      final fraction = 1.0 - (((currentExtent - minExtent) / (maxExtent - minExtent)).clamp(0.0, 1.0) * 0.5);
      snapToExtent(minExtent, duration: widget.duration * fraction);
    }
  }

  void rebuild() {
    _callBuilders();
    _measure();
  }

  void _callBuilders() {
    if (_context != null) {
      header = _delegateInteractions(widget.headerBuilder?.call(_context, state,));
      collapsedHeader = _delegateInteractions(widget.collapsedHeaderBuilder?.call(_context, state));
      footer = _delegateInteractions(widget.footerBuilder?.call(_context, state));
      child = widget.builder?.call(_context, state);
    }
  }

  // Ensure that the sheet sizes itself correctly when the
  // constraints change.
  void _detectChangesInAvailableHeight(double previousHeight) {
    if (previousHeight > 0 && previousHeight != availableHeight) {
      _updateSnappingsAndExtent();

      final changeAdjustedExtent = ((currentExtent * previousHeight) / availableHeight).clamp(minExtent, maxExtent);

      bool isAroundFixedSnap = false;
      for (final snap in snappings) {
        isAroundFixedSnap = (snap - changeAdjustedExtent).abs() < 0.01;
        if (isAroundFixedSnap) {
          break;
        }
      }

      // Only update the currentExtent when its sitting at an extent that
      // is depenent on a fixed height, such as SnapSpec.headerSnap or absolute
      // snap values.
      if (isAroundFixedSnap) {
        currentExtent = changeAdjustedExtent;
      }
    }
  }

  void _handleChangesInChildSize() {
    _measure();
    postFrame(() {
      currentExtent = currentExtent.clamp(minExtent, maxExtent);
      _nudgeToNextSnap();
    });
  }

  void _onDismissPrevented({bool backButton = false, bool backDrop = false}) {
    widget.onDismissPrevented?.call(backButton, backDrop);
  }

  void _handleNonDismissableSnapBack() {
    // didEndScroll doesn't work reliably in ScrollPosition. There
    // should be a better solution to this problem.
    if (fromBottomSheet && !widget.isDismissable && currentExtent < minExtent) {
      snapToExtent(minExtent);
      _onDismissPrevented();
    }
  }

  @override
  Widget build(BuildContext context) {
    final result = Builder(
      builder: (context) {
        // The context used for the builders to allow
        // the children to inherit the SheetController
        _context = context;
        rebuild();

        return LayoutBuilder(
          builder: (context, constrainst) {
            final previousHeight = availableHeight;
            availableHeight = constrainst.biggest.height;
            _detectChangesInAvailableHeight(previousHeight);

            final sheet = NotificationListener<SizeChangedLayoutNotification>(
              onNotification: (notification) {
                _handleChangesInChildSize();
                return true;
              },
              // ValueListenableBuilder is used to update the sheet irrespective of its children.
              child: ValueListenableBuilder(
                valueListenable: extent._currentExtent,
                builder: (context, value, _) {
                  // Hide the sheet for the first frame until the extents are
                  // correctly measured.
                  return Visibility(
                    visible: isLaidOut,
                    maintainInteractivity: false,
                    maintainSemantics: true,
                    maintainSize: true,
                    maintainState: true,
                    maintainAnimation: true,
                    child: Stack(
                      children: <Widget>[
                        _buildBackdrop(),
                        _buildSheet(),
                      ],
                    ),
                  );
                },
              ),
            );

            if (widget.body == null) {
              return sheet;
            } else {
              return Stack(
                children: <Widget>[
                  _buildBody(),
                  sheet,
                ],
              );
            }
          },
        );
      },
    );

    if (!widget.closeSheetOnBackButtonPressed && !fromBottomSheet) {
      return result;
    }

    return WillPopScope(
      onWillPop: () async {
        if (fromBottomSheet) {
          if (!widget.isDismissable) {
            _onDismissPrevented(backButton: true);
            return false;
          } else {
            return true;
          }
        } else {
          if (!state.isCollapsed) {
            snapToExtent(minExtent);
            return false;
          } else {
            return true;
          }
        }
      },
      child: result,
    );
  }

  Widget _buildSheet() {
    final scrollingContent = _buildScrollView();
    return Align(
      alignment: Alignment(widget.axisAlignment, -1.0),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: widget.maxWidth ?? double.infinity,
        ),
        child: SizedBox.expand(
          child: FractionallySizedBox(
            heightFactor: isLaidOut ? currentExtent.clamp(headerFooterExtent, 1.0) : 1.0,
            alignment: Alignment.bottomCenter,
            child: FractionalTranslation(
              translation: Offset(
                0,
                headerFooterExtent > 0.0
                    ? (1 - (currentExtent.clamp(0.0, headerFooterExtent) / headerFooterExtent))
                    : 0.0,
              ),
              child: Stack(
                  children: <Widget>[
                    Opacity(
                      opacity: widget.collapsedPanelOpacity + opacity * (1.0 - widget.collapsedPanelOpacity),
                      child: _SheetContainer(
                          color: widget.color ?? Colors.white,
                          border: widget.border,
                          margin: widget.margin,
                          padding: EdgeInsets.fromLTRB(
                            padding.left,
                            header != null || collapsedHeader != null ? padding.top : 0.0,
                            padding.right,
                            footer != null ? padding.bottom : 0.0,
                          ),
                          elevation: widget.elevation,
                          shadowColor: widget.shadowColor,
                          customBorders: BorderRadius.vertical(
                            top: Radius.circular(cornerRadius),
                          ),
                        child: Container(height: childHeight + headerHeight + footerHeight),
                      )),

                    Opacity(
                      opacity: widget.fadeContentOnCollapse ? opacity : 1.0,
                    child: Column(
                      mainAxisSize: MainAxisSize.max,
                      children: <Widget>[
                        SizedBox(height: headerHeight),
                        Expanded(child: scrollingContent),
                        SizedBox(height: footerHeight),
                      ],
                    ),
                    ),

                    if (header != null && collapsedHeader != null)
                      Stack(children: <Widget>[
                        Opacity(
                            opacity: collapsedHeader!= null ? opacity : 1.0,
                            child: Align(
                          alignment: Alignment.topCenter,
                          child: SizeChangedLayoutNotifier(
                            key: headerKey,
                            child: IgnorePointer(ignoring: opacity < 0.5, child: header),
                          ),
                        )),
                        Opacity(
                            opacity: 1.0 - opacity,
                            child: Align(
                          alignment: Alignment.topCenter,
                          child: SizeChangedLayoutNotifier(
                            child: IgnorePointer(ignoring: opacity > 0.5, child: collapsedHeader),
                          ),
                        )),
                      ],),

                    if (header != null && collapsedHeader == null)
                      Align(
                        alignment: Alignment.topCenter,
                        child: SizeChangedLayoutNotifier(
                          key: headerKey,
                          child: header,
                        ),
                      ),
                    if (header == null && collapsedHeader != null)
                      Opacity(
                          opacity: 1.0 - opacity,
                          child: Align(
                            alignment: Alignment.topCenter,
                            child: SizeChangedLayoutNotifier(
                              key: headerKey,
                              child: IgnorePointer(ignoring: opacity > 0.5, child: collapsedHeader),
                            ),
                          )),
                    if (footer != null)
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: SizeChangedLayoutNotifier(
                          key: footerKey,
                          child: footer,
                        ),
                      ),
                  ],
                ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScrollView() {
     Widget scrollView = SingleChildScrollView(
          controller: controller,
          physics: scrollSpec.physics ?? const ScrollPhysics(),
          padding: EdgeInsets.only(
            top: header == null && collapsedHeader == null ? padding.top : 0.0,
            bottom: footer == null ? padding.bottom : 0.0,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: widget.minHeight ?? 0.0),
            child: SizeChangedLayoutNotifier(
              key: childKey,
              child: child,
            ),
          ),
        );

     if (widget.customScrollbarBuilder != null) {
       scrollView = widget.customScrollbarBuilder?.call(_context, state, controller, scrollView);
     }
     else if (scrollSpec.showScrollbar) {
       scrollView = Scrollbar(
           child: scrollView
       );
     }

    scrollView = Listener(
      onPointerUp: (event) => _handleNonDismissableSnapBack(),
      // Wrap the scrollView in a ScrollConfiguration to
      // remove the default overscroll effect.
      child: ScrollConfiguration(
        behavior: const ScrollBehavior(),
        child: scrollView,
      ),
    );

    // Add the overscroll if required again if required
    if (scrollSpec.overscroll) {
      scrollView = GlowingOverscrollIndicator(
        axisDirection: AxisDirection.down,
        color: scrollSpec.overscrollColor ?? Theme.of(context).accentColor,
        child: scrollView,
      );
    }

    return scrollView;
  }

  Widget _buildBody() {
    final spec = widget.parallaxSpec;
    if (spec == null || !spec.enabled || spec.amount <= 0.0) {
      return widget.body;
    }

    return ValueListenableBuilder(
      valueListenable: extent._currentExtent,
      // ignore: sort_child_properties_last
      child: widget.body,
      builder: (context, _, body) {
        final isBodyFaded = spec.fadeBody;
        final amount = spec.amount;
        final defaultMaxExtent = snappings.length > 2 ? snappings[snappings.length - 2] : this.maxExtent;
        final maxExtent = spec.endExtent != null ? _normalizeSnap(spec.endExtent) : defaultMaxExtent;
        assert(maxExtent > minExtent, 'The endExtent must be greater than the min snap extent you set on the SnapSpec');
        final maxOffset = (maxExtent - minExtent) * availableHeight;
        final fraction = ((currentExtent - minExtent) / (maxExtent - minExtent)).clamp(0.0, 1.0);

        return Transform.translate(
          offset: Offset(0.0, -(amount * maxOffset) * fraction),
          child: Opacity(
              opacity: isBodyFaded ? 1.0 - fraction : 1.0,
              child: body),
        );
//        return Padding(
//          padding: EdgeInsets.only(bottom: (amount * maxOffset) * fraction),
//          child: body,
//        );
      },
    );
  }

  Widget _buildBackdrop() {
    if (!widget.isDismissable && !dismissUnderway && didCompleteInitialRoute) {
      opacity = 1.0;
    } else if (currentExtent != 0.0) {
      if (fromBottomSheet) {
        opacity = (currentExtent / minExtent).clamp(0.0, 1.0);
      } else {
        final secondarySnap = snappings.length > 2 ? snappings[1] : maxExtent;
        opacity = ((currentExtent - minExtent) / (secondarySnap - minExtent)).clamp(0.0, 1.0);
      }
    }

    final backDrop = IgnorePointer(
      ignoring: opacity < 0.05,
      child: Opacity(
        opacity: opacity,
        child: Container(
          width: double.infinity,
          height: double.infinity,
          color: widget.backdropColor,
        ),
      ),
    );

    void onTap() => widget.isDismissable ? _pop(0.0) : _onDismissPrevented(backDrop: true);

    // see: https://github.com/BendixMa/sliding-sheet/issues/30
    if (opacity >= 0.05 || didStartDragWhenNotCollapsed) {
      if (widget.isBackdropInteractable) {
        return _delegateInteractions(backDrop, onTap: widget.closeOnBackdropTap ? onTap : null);
      } else if (widget.closeOnBackdropTap) {
        return GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.translucent,
          child: backDrop,
        );
      }
    }

    return backDrop;
  }

  Widget _delegateInteractions(Widget child, {VoidCallback onTap}) {
    if (child == null) return child;

    double start = 0;
    double end = 0;

    void onDragEnd([double velocity = 0.0]) {
      controller.delegateFling(velocity);

      // If a header was dragged, but the scroll view is not at the top
      // animate to the top when the drag has ended.
      if (!state.isAtTop && (start - end).abs() > 15) {
        controller.animateTo(0.0, duration: widget.duration * .5, curve: Curves.ease);
      }

      _handleNonDismissableSnapBack();
    }

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.translucent,
      onVerticalDragStart: (details) {
        start = details.localPosition.dy;
        end = start;

        didStartDragWhenNotCollapsed = currentExtent > snappings.first;
      },
      onVerticalDragUpdate: (details) {
        end = details.localPosition.dy;
        final delta = details.delta.dy;

        // Do not delegate upward drag when the sheet is fully expanded
        // because headers or backdrops should not be able to scroll the
        // sheet, only to drag it between min and max extent.
        final shouldDelegate = !delta.isNegative || currentExtent < maxExtent;
        if (shouldDelegate) {
          controller.delegateDrag(delta);
        }
      },
      onVerticalDragEnd: (details) {
        final deltaY = details.velocity.pixelsPerSecond.dy;
        final velocity = swapSign(deltaY);

        final shouldDelegate = !deltaY.isNegative || currentExtent < maxExtent;
        if (shouldDelegate) {
          onDragEnd(velocity);
        }

        setState(() => didStartDragWhenNotCollapsed = false);
      },
      onVerticalDragCancel: onDragEnd,
      child: child,
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}

/// A data class containing state information about the [_SlidingSheetState].
class SheetState {
  /// The current extent the sheet covers.
  final double extent;

  /// The minimum extent that the sheet will cover.
  final double minExtent;

  /// The maximum extent that the sheet will cover
  /// until it begins scrolling.
  final double maxExtent;

  /// Whether the sheet has finished measuring its children and computed
  /// the correct extents. This takes until the first frame was drawn.
  final bool isLaidOut;

  /// The progress between [minExtent] and [maxExtent] of the current [extent].
  /// A progress of 1 means the sheet is fully expanded, while
  /// a progress of 0 means the sheet is fully collapsed.
  final double progress;

  /// Whether the [SlidingSheet] has reached its maximum extent.
  final bool isExpanded;

  /// Whether the [SlidingSheet] has reached its minimum extent.
  final bool isCollapsed;

  /// Whether the [SlidingSheet] has a [scrollOffset] of zero.
  final bool isAtTop;

  /// Whether the [SlidingSheet] has reached its maximum scroll extent.
  final bool isAtBottom;

  /// Whether the sheet is hidden to the user.
  final bool isHidden;

  /// Whether the sheet is visible to the user.
  final bool isShown;

  final _SheetExtent _extent;
  SheetState(
    this._extent, {
    @required this.extent,
    @required this.isLaidOut,
    @required this.maxExtent,
    @required double minExtent,
    // On Bottomsheets it is possible for min and maxExtents to be the same (when you only set one snap).
    // Thus we have to account for this and set the minExtent to be zero.
  })  : minExtent = minExtent != maxExtent ? minExtent : 0.0,
        progress = isLaidOut ? ((extent - minExtent) / (maxExtent - minExtent)).clamp(0.0, 1.0) : 0.0,
        isExpanded = toPrecision(extent) >= toPrecision(maxExtent),
        isCollapsed = toPrecision(extent) <= toPrecision(minExtent),
        isAtTop = _extent?.isAtTop ?? true,
        isAtBottom = _extent?.isAtBottom ?? false,
        isHidden = extent <= 0.0,
        isShown = extent > 0.0;

  factory SheetState.inital() => SheetState(null, extent: 0.0, minExtent: 0.0, maxExtent: 1.0, isLaidOut: false);

  /// The current scroll offset of the Scrollable inside the sheet.
  double get scrollOffset => _extent?.scrollOffset ?? 0.0;

  /// The maximum amount the Scrollable inside the sheet can scroll.
  double get maxScrollExtent => _extent?.maxScrollExtent ?? 0.0;

  @override
  String toString() {
    return 'SheetState(extent: $extent, minExtent: $minExtent, maxExtent: $maxExtent, isLaidOut: $isLaidOut, progress: $progress, scrollOffset: $scrollOffset, maxScrollExtent: $maxScrollExtent, isExpanded: $isExpanded, isCollapsed: $isCollapsed, isAtTop: $isAtTop, isAtBottom: $isAtBottom, isHidden: $isHidden, isShown: $isShown)';
  }
}

/// A controller for a [SlidingSheet].
class SheetController {
  /// Inherit the [SheetController] from the closest [SlidingSheet].
  ///
  /// Every [SlidingSheet] has a [SheetController], even if you didn't assign
  /// one explicitly. This allows you to call functions on the controller from child
  /// widgets without having to pass a [SheetController] around.
  static SheetController of(BuildContext context) {
    return context.findAncestorStateOfType<_SlidingSheetState>()?.sheetController;
  }

  /// Animates the sheet to the [extent].
  ///
  /// The [extent] will be clamped to the minimum and maximum extent.
  /// If the scrolling child is not at the top, it will scroll to the top
  /// first and then animate to the specified extent.
  Future<void> snapToExtent(double extent, {Duration duration, bool clamp = true}) =>
      _snapToExtent?.call(extent, duration: duration, clamp: clamp);
  Future<void> Function(double extent, {Duration duration, bool clamp}) _snapToExtent;

  /// Animates the scrolling child to a specified offset.
  ///
  /// If the sheet is not fully expanded it will expand first and then
  /// animate to the given [offset].
  Future<void> scrollTo(double offset, {Duration duration, Curve curve}) =>
      _scrollTo?.call(offset, duration: duration, curve: curve);
  Future<void> Function(double offset, {Duration duration, Curve curve}) _scrollTo;

  /// Calls every builder function of the sheet to rebuild the widgets with
  /// the current [SheetState].
  ///
  /// This function can be used to reflect changes on the [SlidingSheet]
  /// without calling `setState(() {})` on the parent widget if that would be
  /// too expensive.
  void rebuild() => _rebuild?.call();
  VoidCallback _rebuild;

  /// Fully collapses the sheet.
  ///
  /// Short-hand for calling `snapToExtent(minExtent)`.
  Future<void> collapse() => _collapse?.call();
  Future<void> Function() _collapse;

  /// Fully expands the sheet.
  ///
  /// Short-hand for calling `snapToExtent(maxExtent)`.
  Future<void> expand() => _expand?.call();
  Future<void> Function() _expand;

  /// Reveals the [SlidingSheet] if it is currently hidden.
  Future<void> show() => _show?.call();
  Future<void> Function() _show;

  /// Slides the sheet off to the bottom and hides it.
  Future<void> hide() => _hide?.call();
  Future<void> Function() _hide;

  SheetState _state;
  SheetState get state => _state;
}

/// A custom [Container] for a [SlidingSheet].
class _SheetContainer extends StatelessWidget {
  final double borderRadius;
  final double elevation;
  final Border border;
  final BorderRadius customBorders;
  final EdgeInsets margin;
  final EdgeInsets padding;
  final Widget child;
  final Color color;
  final Color shadowColor;
  final List<BoxShadow> boxShadows;
  final AlignmentGeometry alignment;
  final BoxConstraints constraints;
  const _SheetContainer({
    Key key,
    this.borderRadius = 0.0,
    this.elevation = 0.0,
    this.border,
    this.customBorders,
    this.margin,
    this.padding = const EdgeInsets.all(0),
    this.child,
    this.color = Colors.transparent,
    this.shadowColor = Colors.black12,
    this.boxShadows,
    this.alignment,
    this.constraints,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final br = customBorders ?? BorderRadius.circular(borderRadius);

    final List<BoxShadow> boxShadow = boxShadows ?? elevation != 0
        ? [
            BoxShadow(
              color: shadowColor ?? Colors.black12,
              blurRadius: elevation,
              spreadRadius: 0,
            ),
          ]
        : const [];

    return Container(
      margin: margin,
      padding: padding,
      alignment: alignment,
      constraints: constraints,
      decoration: BoxDecoration(
        color: color,
        borderRadius: br,
        boxShadow: boxShadow,
        border: border,
        shape: BoxShape.rectangle,
      ),
      child: ClipRRect(
        borderRadius: br,
        child: child,
      ),
    );
  }
}
