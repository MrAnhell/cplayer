library cplayer;

import 'dart:async';

import 'package:cplayer/ui/cplayer_progress.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:screen/screen.dart';
import 'package:video_player/video_player.dart';


class CPlayer extends StatefulWidget {

  final String url;
  final Color primaryColor;
  final Color accentColor;
  final Color highlightColor;

  CPlayer({
    Key key,
    @required this.url,
    this.primaryColor,
    this.accentColor,
    this.highlightColor
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => CPlayerState();

}

class CPlayerState extends State<CPlayer> {

  static const _platform = const MethodChannel('xyz.apollotv/casting');

  VideoPlayerController _controller;
  bool _isPlaying = false;
  bool _isControlsVisible = true;
  bool _isLoading = true;
  int _aspectRatio = 0;
  int _total = 0;

  Function _getCenterPanel = (){
    return Container();
  };

  @override
  void initState(){
    super.initState();

    // Disable screen rotation and UI
    SystemChrome.setEnabledSystemUIOverlays([]);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeRight,
      DeviceOrientation.landscapeLeft,
    ]);

    // Activate wake-lock
    Screen.keepOn(true);

    // Start the video controller
    _controller = VideoPlayerController.network(
        widget.url
    )..addListener(() {
      setState(() {});

      final bool isPlaying = _controller.value.isPlaying;
      if(isPlaying != _isPlaying){
        setState((){
          _isPlaying = isPlaying;
        });
      }
    })..initialize().then((_){
      // VIDEO PLAYER: Ensure the first frame is shown after the video is
      // initialized, even before the play button has been pressed.
      setState((){});

      // Hide loading bar
      _isLoading = false;

      // Set up controller, and autoplay.
      _controller.setLooping(false);
      _controller.setVolume(1.0);
      _controller.play();

      Timer(Duration(seconds: 5), (){
        _isControlsVisible = false;
      });

      _total = _controller.value.duration.inMilliseconds;
    });
  }

  @override
  void deactivate() {
    // Dispose controller
    _controller.setVolume(0.0);
    _controller.dispose();

    // Cancel wake-lock
    Screen.keepOn(false);

    // Re-enable screen rotation and UI
    SystemChrome.setEnabledSystemUIOverlays(SystemUiOverlay.values);
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);

    // Pass to super
    super.deactivate();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'CPlayer',
        theme: new ThemeData(
            brightness: Brightness.dark,
            primaryColor: widget.primaryColor,
            accentColor: widget.accentColor,
            highlightColor: widget.highlightColor,
            backgroundColor: Colors.black
        ),

        // Remove debug banner - because it's annoying.
        debugShowCheckedModeBanner: false,

        // Layout
        home: Scaffold(
          backgroundColor: Colors.black,
            body: Stack(
                alignment: Alignment.bottomCenter,
                children: <Widget>[
                  GestureDetector(
                    onTap: (){
                      _isControlsVisible = !_isControlsVisible;
                    },
                    child: Center(
                        child: _controller.value.initialized
                            ? InkWell(
                            child: AspectRatio(
                                aspectRatio: buildAspectRatio(_aspectRatio, context, _controller),
                                child: VideoPlayer(_controller)
                            )
                        )
                            : Container(child: CircularProgressIndicator(
                          valueColor: new AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
                        ))
                    )
                  ),

                  new AnimatedOpacity(
                      opacity: _isControlsVisible ? 1.0 : 0.0,
                      duration: new Duration(milliseconds: 200),
                      child: Container(
                          height: 52.0,
                          color: Theme.of(context).dialogBackgroundColor,
                          child: Padding(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 10.0,
                                  vertical: 3.0
                              ),
                              child: Row(
                                children: <Widget>[
                                  /* Play/pause button */
                                  new Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 5.0),
                                      child: new InkWell(
                                          onTap: (){
                                            if(_controller.value.isPlaying) {
                                              _controller.pause();
                                            }else{
                                              _controller.play();
                                            }
                                          },
                                          child: new Icon(
                                              (_controller.value.isPlaying ?
                                              Icons.pause :
                                              Icons.play_arrow
                                              ),
                                              size: 32.0,
                                              color: Theme.of(context).textTheme.button.color
                                          )
                                      )
                                  ),

                                  /* Progress Label */
                                  new Padding(
                                      padding: EdgeInsets.only(left: 5.0),
                                      child: new Text(
                                          "${formatTimestamp(
                                              _controller.value.position.inMilliseconds
                                          )} / ${formatTimestamp(_total)}",
                                          maxLines: 1,
                                          style: TextStyle(
                                              fontSize: 14.0
                                          )
                                      )
                                  ),

                                  /* Progress Bar */
                                  new Expanded(
                                      child: new Padding(
                                          padding: EdgeInsets.symmetric(
                                              horizontal: 5.0
                                          ),
                                          child: new CPlayerProgress(
                                            _controller,
                                            activeColor: Theme.of(context).primaryColor,
                                            inactiveColor: Theme.of(context).backgroundColor,
                                          )
                                      )
                                  ),

                                  new Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 5.0),
                                      child: new InkWell(
                                          onTap: (){
                                            if(!_controller.value.isPlaying) {
                                              return;
                                            }

                                            if(_aspectRatio < RATIOS.length - 1) {
                                              _aspectRatio++;
                                            }else{
                                              _aspectRatio = 0;
                                            }

                                            /* BEGIN: show center panel */
                                            _getCenterPanel = (){
                                              return Container(
                                                  child: new Padding(
                                                      padding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 15.0),
                                                      child: Column(
                                                        mainAxisSize: MainAxisSize.min,

                                                        children: <Widget>[
                                                          Icon(
                                                            Icons.aspect_ratio,
                                                            size: 48,
                                                          ),

                                                          Padding(
                                                              padding: EdgeInsets.only(top: 10),
                                                              child: Text(
                                                                  "Aspect Ratio",
                                                                  style: TextStyle(
                                                                      fontFamily: "GlacialIndifference",
                                                                      fontSize: 20
                                                                  )
                                                              )
                                                          ),

                                                          Padding(
                                                              padding: EdgeInsets.only(top: 5),
                                                              child: Text(RATIOS[_aspectRatio])
                                                          )
                                                        ],
                                                      )
                                                  ),

                                                  decoration: BoxDecoration(
                                                      color: const Color(0xAF000000),
                                                      borderRadius: BorderRadius.circular(5.0)
                                                  )
                                              );
                                            };

                                            new Timer(Duration(seconds: 5), (){
                                              _getCenterPanel = (){
                                                return Container();
                                              };
                                            });
                                            /* END: show center panel */
                                          },
                                          child: new Icon(
                                              Icons.aspect_ratio,
                                              size: 24.0,
                                              color: Theme.of(context).textTheme.button.color
                                          )
                                      )
                                  )
                                ],
                              )
                          )
                      )
                  ),

                  new AnimatedOpacity(
                    opacity: _controller.value.isBuffering ? 1.0 : 0.0,
                    duration: new Duration(milliseconds: 200),
                    child: Center(
                        child: Container(child: CircularProgressIndicator(
                            valueColor: new AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor)
                        ))
                    )
                  ),

                  Center(
                    child: (_getCenterPanel())
                  )
                ]
            )
        )
    );
  }

  ///
  /// Formats a timestamp in milliseconds.
  ///
  String formatTimestamp(int millis){
    int seconds = ((millis ~/ 1000)%60);
    int minutes = ((millis ~/ (1000*60))%60);
    int hours = ((millis ~/ (1000*60*60))%24);

    String hourString = (hours < 10) ? "0" + hours.toString() : hours.toString();
    String minutesString = (minutes < 10) ? "0" + minutes.toString() : minutes.toString();
    String secondsString = (seconds < 10) ? "0" + seconds.toString() : seconds.toString();

    return hourString + ":" + minutesString + ":" + secondsString;
  }

  ///
  /// Casts to a Chromecast or Airplay device
  ///
  Future<Null> _beginCasting() async {
    try {
      await _platform.invokeMethod('beginCasting');
    } on PlatformException catch (e) {
      print("Failed to begin casting on platform: ${e.message}");
    }
  }

  static const Map<int, String> RATIOS = {
    0: "Default",
    1: "Fit to Screen",
    2: "3:2",
    3: "16:9",
    4: "18:9",
    5: "21:9"
  };

  ///
  /// Returns a generated aspect ratio.
  /// Choices: fit, 3-2, 16-9, default.
  ///
  double buildAspectRatio(int ratio, BuildContext context, VideoPlayerController controller){
    switch(ratio) {
      case 1: /* FIT */
        return MediaQuery.of(context).size.width / MediaQuery.of(context).size.height;

      case 2: /* 3:2 */
        return 3/2;

      case 3: /* 16:9 */
        return 16/9;

      case 4: /* 18:9 */
        return 18/9;

      case 5: /* 21/9 */
        return 21/9;

      default:
        return controller.value.aspectRatio;
    }
  }

}