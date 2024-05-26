import 'package:example/common/widget/hero.dart';
import 'package:example/example_routes.dart';
import 'package:extended_image/extended_image.dart';
import 'package:ff_annotation_route_core/ff_annotation_route_core.dart';
import 'package:flutter/material.dart';

// this is the whole photo grid view
@FFRoute(
  name: 'fluttercandies://SimplePhotoView',
  routeName: 'SimplePhotoView',
  description: 'Simple demo for PhotoView.',
  exts: <String, dynamic>{
    'group': 'Simple',
    'order': 8,
  },
)
class SimplePhotoViewDemo extends StatefulWidget {
  @override
  _SimplePhotoViewDemoState createState() => _SimplePhotoViewDemoState();
}

class _SimplePhotoViewDemoState extends State<SimplePhotoViewDemo> {
  List<String> images = <String>[
    'https://photo.tuchong.com/14649482/f/601672690.jpg',
    'https://photo.tuchong.com/17325605/f/641585173.jpg',
    'https://photo.tuchong.com/3541468/f/256561232.jpg',
    'https://photo.tuchong.com/16709139/f/278778447.jpg',
    // why are we even using the "this is a video - maybe it was to serve as showcase to show that videos can be added , lets leave it"
    'This is an video',
    'https://photo.tuchong.com/5040418/f/43305517.jpg',
    'https://photo.tuchong.com/3019649/f/302699092.jpg'
  ];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SimplePhotoView'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(10.0),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 300,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemBuilder: (BuildContext context, int index) {
            final String url = images[index];

            // this represents the grid when we click on one of the and the input is received through the GestureDetector
            // it navigates to a new route - the PicSeiper Route

            return GestureDetector(
              child: AspectRatio(
                aspectRatio: 1.0,
                child: Hero(
                  tag: url,
                  child: url == 'This is an video'
                      ? Container(
                          alignment: Alignment.center,
                          child: const Text('This is an video'),
                        )
                      : ExtendedImage.network(
                          url,
                          fit: BoxFit.cover,
                        ),
                ),
              ),
              onTap: () {
                //navigate to the pic swiper when clicked, basically this page and the target page have a Hero with the same tag
                // so when they are clicked it does the Hero transition
                Navigator.of(context).pushNamed(
                    Routes.fluttercandiesSimplePicsWiper,
                    arguments: <String, dynamic>{
                      'url': url,
                      'images': images,
                    });
              },
            );
          },
          itemCount: images.length,
        ),
      ),
    );
  }
}

// This is the widget for the picSwiper lets see how it is

// The main child is ExtendedImageSlidePage - slide page - as in slide out of page not swiper , take note

// the child of ExtendedImageSlidePage is a GestureDetector - tapping it pops the SimplePicSwiper from the stack - lets comment it out , we don;t need it

// the child of GestureDetector is ExtendedImageGesturePageView.builder()

@FFRoute(
  name: 'fluttercandies://SimplePicsWiper',
  routeName: 'SimplePicsWiper',
  description: 'Simple demo for Simple Pics Wiper.',
  pageRouteType: PageRouteType.transparent,
)
class SimplePicsWiper extends StatefulWidget {
  const SimplePicsWiper({required this.url, required this.images});
  final String url;
  final List<String> images;
  @override
  _SimplePicsWiperState createState() => _SimplePicsWiperState();
}

class _SimplePicsWiperState extends State<SimplePicsWiper> {
  GlobalKey<ExtendedImageSlidePageState> slidePagekey =
      GlobalKey<ExtendedImageSlidePageState>();

  final List<int> _cachedIndexes = <int>[];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final int index = widget.images.indexOf(widget.url);
    _preloadImage(index - 1);
    _preloadImage(index + 1);
  }

// preloading image logic here
  void _preloadImage(int index) {
    if (_cachedIndexes.contains(index)) {
      return;
    }
    if (0 <= index && index < widget.images.length) {
      final String url = widget.images[index];
      if (url.startsWith('https:')) {
        precacheImage(ExtendedNetworkImageProvider(url, cache: true), context);
      }

      _cachedIndexes.add(index);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      // this is where the main computation for calculating the scale and translate goes on
      child: ExtendedImageSlidePage(
        key: slidePagekey,
        // child: GestureDetector(

        // this ExtendedGesturePageView is just a CustomPageView for supporting user Gestures , lets leave that for now , its quite complex
        child: ExtendedImageGesturePageView.builder(
          //page controller - it extends the class scrollController
          controller: ExtendedPageController(
            initialPage: widget.images.indexOf(widget.url),
            pageSpacing: 50,
            shouldIgnorePointerWhenScrolling: false,
          ),
          itemCount: widget.images.length,
          onPageChanged: (int page) {
            // when the page changes preload the image before and after the current page
            _preloadImage(page - 1);
            _preloadImage(page + 1);
          },
          itemBuilder: (BuildContext context, int index) {
            // when this itembuilder function is called , it rebuilds the pageView based as it updates the index , so a new mage from the images array is selected
            final String url = widget.images[index];
            // if it is a video , return slide page handler stuff - has a Hero as a child
            // if it is not a video, return the heroWidget as a child
            return url == 'This is an video'
                ?
                //The ExtendedImageSlidePageHandler is basically what enables the Sliding around the page functionality
                // we'll go deeper into it
                ExtendedImageSlidePageHandler(
                    child: Material(
                      child: Container(
                        alignment: Alignment.center,
                        color: Colors.yellow,
                        child: const Text('This is an video'),
                      ),
                    ),
                    // the ExtendedImageSlidePageHandler even the parameter
                    heroBuilderForSlidingPage: (Widget result) {
                      // print(" we are in the first block of execution");
                      //this is the hero for the page when we transition to clicking it in the SimplePhotoViewDemo widget
                      return Hero(
                        tag: url,
                        child: result,
                        flightShuttleBuilder: (BuildContext flightContext,
                            Animation<double> animation,
                            HeroFlightDirection flightDirection,
                            BuildContext fromHeroContext,
                            BuildContext toHeroContext) {
                          final Hero hero =
                              (flightDirection == HeroFlightDirection.pop
                                  ? fromHeroContext.widget
                                  : toHeroContext.widget) as Hero;
                          return hero.child;
                        },
                      );
                    },
                  )

                // this hero widget is a fancy wrapper around the actual Hero Widget - is has modifications, what can it do ?
                // and how is it different for the one for videos?
                //
                : HeroWidget(
                    child: ExtendedImage.network(
                      url,
                      enableSlideOutPage: true,
                      fit: BoxFit.contain,
                      mode: ExtendedImageMode.gesture,
                      initGestureConfigHandler: (ExtendedImageState state) {
                        return GestureConfig(
                          //you must set inPageView true if you want to use ExtendedImageGesturePageView
                          inPageView: true,
                          initialScale: 1.0,
                          maxScale: 5.0,
                          animationMaxScale: 6.0,
                          initialAlignment: InitialAlignment.center,
                        );
                      },
                    ),
                    tag: url,
                    slideType: SlideType.wholePage,
                    slidePagekey: slidePagekey,
                  );
          },
        ),
        //   onTap: () {
        //     slidePagekey.currentState!.popPage();
        //     Navigator.pop(context);
        //   },
        // ),
        slideAxis: SlideAxis.both,
        slideType: SlideType.wholePage,
      ),
    );
  }
}

// Another exception was thrown: A
// RenderConstraintsTransformBox overflowed by
// 7.4 pixels on the left
// and 7.4 pixels on the
//right.

//four sections

//header -SizedBox / Container Widget

//stories Horizontal SingleChildScrollView

//channels Horizontal SingleChildScrollView

//Discover  GridView.builder()
