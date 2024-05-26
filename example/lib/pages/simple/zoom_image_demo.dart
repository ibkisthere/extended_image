import 'package:example/main.dart';
import 'package:extended_image/extended_image.dart';
import 'package:ff_annotation_route_core/ff_annotation_route_core.dart';
import 'package:flutter/material.dart';

@FFRoute(
  name: 'fluttercandies://zoomimage',
  routeName: 'ImageZoom',
  description: 'Zoom and Pan.',
  exts: <String, dynamic>{
    'group': 'Simple',
    'order': 4,
  },
)
class ZoomImageDemo extends StatelessWidget {
  // you can handle gesture detail by yourself with key
  final GlobalKey<ExtendedImageGestureState> gestureKey =
      GlobalKey<ExtendedImageGestureState>();
  @override
  Widget build(BuildContext context) {
    return Material(
      child: Column(
        children: <Widget>[
          AppBar(
            title: const Text('zoom/pan image demo'),
            actions: <Widget>[
              IconButton(
                icon: const Icon(Icons.restore),
                onPressed: () {
                  gestureKey.currentState!.reset();
                  //you can also change zoom manual
                  //gestureKey.currentState.gestureDetails=GestureDetails();
                },
              )
            ],
          ),
          Expanded(
            child: ExtendedImage.network(
              imageTestUrl,
              fit: BoxFit.contain,
              // now when we return the GestureConfig - whether to be scroll , crop , zoom slide, depends on the mode we set which are enum values
              //enum ExtendedImageMode {
                //just show image
                // none,
                //support be to zoom,scroll
                // gesture,
                //support be to crop,rotate,flip
                // editor
              // }
              mode: ExtendedImageMode.gesture,
              extendedImageGestureKey: gestureKey,
              initGestureConfigHandler: (ExtendedImageState state) {
                // here it is used for configuring the settings of the zoom /pan gesture
                //the effects that you see are basically gesture controlled animation - think in that lane
                
                // The zooming in / out (tranforming larger or smaller effect) is essentially an animation - and GestureConfig is what controls it

                //  Both GestureConfig and GestureDetails are in the utils.dart 

                //GestureConfig 
                // the GestureConfig class is basically a class that is used to set the parameters for the GestureDriven animations - that is what we are returning, lets look at the parent 

                // GestureDetails -> this is a class that has methods that can be used to get information about the current gesture driven animation
                
                return GestureConfig(
                  minScale: 0.3,
                  animationMinScale: 0.2,
                  maxScale: 4.0,
                  animationMaxScale: 4.5,
                  //from 1.5 we start having some weird movements
                  speed: 1.0,
                  inertialSpeed: 100.0,
                  initialScale: 1.0,
                  inPageView: false,
                  initialAlignment: InitialAlignment.center,
                  reverseMousePointerScrollDirection: true,
                  gestureDetailsIsChanged: (GestureDetails? details) {
                    // its here in the GestureDetails
                    print(details?.totalScale);
                    print(details);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
