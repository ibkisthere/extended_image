import 'package:flutter/material.dart';

import '../typedef.dart';
import 'gesture.dart';
import 'slide_page_handler.dart';
import 'utils.dart';

enum SlideAxis {
  both,
  horizontal,
  vertical,
}

// other widgets that are children of this slidePage - ExtendedImage.network(), get the slideType by accessing the ExtendedImageSlidePageState from higher up the widget tree
enum SlideType {
  wholePage,
  onlyImage,
}

class ExtendedImageSlidePage extends StatefulWidget {
  const ExtendedImageSlidePage({
    this.child,
    this.slidePageBackgroundHandler,
    this.slideScaleHandler,
    this.slideOffsetHandler,
    this.slideEndHandler,
    this.slideAxis = SlideAxis.both,
    this.resetPageDuration = const Duration(milliseconds: 500),
    this.slideType = SlideType.onlyImage,
    this.onSlidingPage,
    Key? key,
  }) : super(key: key);

  ///The [child] contained by the ExtendedImageGesturePage.
  final Widget? child;

  ///builder background when slide page
  final SlidePageBackgroundHandler? slidePageBackgroundHandler;

  ///customize scale of page when slide page - this is the method that is used to customize the scale on the slide page as it is moving, if it is not set, then the defaultSlideScaleHandler will be used
  final SlideScaleHandler? slideScaleHandler;

  ///customize offset when slide page
  final SlideOffsetHandler? slideOffsetHandler;

  ///call back of slide end
  ///decide whether pop page
  final SlideEndHandler? slideEndHandler;

  ///axis of slide
  ///both,horizontal,vertical
  final SlideAxis slideAxis;

  ///reset page position when slide end(not pop page)
  final Duration resetPageDuration;

  /// slide whole page or only image
  final SlideType slideType;

  /// on sliding page
  final OnSlidingPage? onSlidingPage;
  @override
  ExtendedImageSlidePageState createState() => ExtendedImageSlidePageState();
}

class ExtendedImageSlidePageState extends State<ExtendedImageSlidePage>
    with SingleTickerProviderStateMixin {
  bool _isSliding = false;

  ///whether is sliding page
  bool get isSliding => _isSliding;

  Size? _pageSize;
  Size get pageSize => _pageSize ?? context.size!;

  late AnimationController _backAnimationController;
  AnimationController get backAnimationController => _backAnimationController;
  Animation<Offset>? _backOffsetAnimation;
  Animation<Offset>? get backOffsetAnimation => _backOffsetAnimation;
  Animation<double>? _backScaleAnimation;
  Animation<double>? get backScaleAnimation => _backScaleAnimation;

  Offset _offset = Offset.zero;
  Offset get offset => _backAnimationController.isAnimating
      ? _backOffsetAnimation!.value
      : _offset;

  double _scale = 1.0;
  double get scale =>
      _backAnimationController.isAnimating ? backScaleAnimation!.value : _scale;

  bool _popping = false;

  @override
  void initState() {
    super.initState();
    _backAnimationController =
        AnimationController(vsync: this, duration: widget.resetPageDuration);
    _backAnimationController.addListener(_backAnimation);
  }

  @override
  void didUpdateWidget(ExtendedImageSlidePage oldWidget) {
    if (oldWidget.resetPageDuration != widget.resetPageDuration) {
      _backAnimationController.stop();
      _backAnimationController.dispose();
      _backAnimationController =
          AnimationController(vsync: this, duration: widget.resetPageDuration);
    }
    super.didUpdateWidget(oldWidget);
  }

  ExtendedImageGestureState? _extendedImageGestureState;
  ExtendedImageGestureState? get imageGestureState =>
      _extendedImageGestureState;
  ExtendedImageSlidePageHandlerState? _extendedImageSlidePageHandlerState;

// this function is called everytime the animation changes 
  void _backAnimation() {
    if (mounted) {
      setState(() {
        if (_backAnimationController.isCompleted) {
          _isSliding = false;
        }
      });
    }
    if (widget.slideType == SlideType.onlyImage) {
      _extendedImageGestureState?.slide();
      _extendedImageSlidePageHandlerState?.slide();
    }
    widget.onSlidingPage?.call(this);
  }



  @override
  void dispose() {
    _backAnimationController.removeListener(_backAnimation);
    _backAnimationController.dispose();
    super.dispose();
  }



  void slide(Offset value,
      {ExtendedImageGestureState? extendedImageGestureState,
      ExtendedImageSlidePageHandlerState? extendedImageSlidePageHandlerState}) {
    if (_backAnimationController.isAnimating) {
      return;
    }
    if (extendedImageGestureState != null) {
      assert(extendedImageGestureState.mounted);
    }
    _extendedImageGestureState = extendedImageGestureState;
    _extendedImageSlidePageHandlerState = extendedImageSlidePageHandlerState;


    // if (widget.slideAxis == SlideAxis.horizontal) {
    //   _offset += Offset(value.dx, 0.0);
    // } else if (widget.slideAxis == SlideAxis.vertical) {
    //   _offset += Offset(0.0, value.dy);
    // } else {
      _offset += value;
    // }
// the _offset value will either be gotten by invoking the slideOffsetHandler with the offset and the state (the slideScaleHandler modifies the value and gives us a new value) or we have the default offset normally
    _offset = widget.slideOffsetHandler?.call(
          _offset,
          state: this,
        ) ??
        _offset;

// the _scale value will either be gotten by invoking the slideScaleHandler with the offset (the slideScaleHandler modifies the value and gives us a new value) or we have the defaultSlideScaleHandler - it is actually a util
    _scale = widget.slideScaleHandler?.call(
          _offset,
          state: this,
        ) ??

        // this is the handler responsible for controlling the scale of the image - it comes from the utils
        defaultSlideScaleHandler(
            offset: _offset,
            pageSize: pageSize,
            pageGestureAxis: widget.slideAxis);

// add a slideBorderRadiusHandler

    if (_scale != 1.0 || _offset != Offset.zero) {
      _isSliding = true;
      if (widget.slideType == SlideType.onlyImage) {
        _extendedImageGestureState?.slide();
        _extendedImageSlidePageHandlerState?.slide();
      }

      if (mounted) {
        setState(() {});
      }
      widget.onSlidingPage?.call(this);
    }
  }



  void endSlide(ScaleEndDetails details) {
    if (mounted && _isSliding) {
      final bool popPage = widget.slideEndHandler?.call(
            _offset,
            state: this,
            details: details,
          ) ??
          defaultSlideEndHandler(
            offset: _offset,
            pageSize: pageSize,
            pageGestureAxis: widget.slideAxis,
          );

      if (popPage) {
        setState(() {
          _popping = true;
          _isSliding = false;
        });
        Navigator.pop(context);
      } else {
        //_isSliding=false;
        // when the slide has finished trigger the backAnimation for the hero for the sliding page
        if (_offset != Offset.zero || _scale != 1.0) {
          _backOffsetAnimation = _backAnimationController
              .drive(Tween<Offset>(begin: _offset, end: Offset.zero));
          _backScaleAnimation = _backAnimationController
              .drive(Tween<double>(begin: _scale, end: 1.0));
          _offset = Offset.zero;
          _scale = 1.0;
          _backAnimationController.reset();
          _backAnimationController.forward();
        } else {
          setState(() {
            // set isSliding to false because we are not sliding any more
            _isSliding = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // gets called first
    _pageSize = MediaQuery.of(context).size;
    final Color pageColor =
        widget.slidePageBackgroundHandler?.call(offset, pageSize) ??
            defaultSlidePageBackgroundHandler(
                offset: offset,
                pageSize: pageSize,
                color: Theme.of(context).dialogBackgroundColor,
                pageGestureAxis: widget.slideAxis);

    Widget? result = widget.child;
    // if the widget slideType is the wholePage
    if (widget.slideType == SlideType.wholePage) {
      // this is what actually performs the scaling and translating of the page
      // the scale is calculated based on the animation value
      // the offset is calculated based on the backOffsetAnimation
      // this is what we are using
      result = Transform.translate(
        offset: offset,
        child: Transform.scale(
          scale: scale,
          // we add a child
          child: result,
        ),
      );
      // result = Container(
      //   color: Colors.green,
      //   child: result,
      // );
    }

    result = Container(
      color: _popping ? Colors.transparent : pageColor,
      child: result,
    );

//    result = IgnorePointer(
//      ignoring: _isSliding,
//      child: result,
//    );

    return result;
  }

  void popPage() {
    setState(() {
      _popping = true;
    });
  }
}
