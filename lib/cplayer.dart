library cplayer;

import 'dart:async';

import 'package:cplayer/ui/cplayer_progress.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:screen/screen.dart';
import 'package:video_player/video_player.dart';


class ApolloTVPlayer extends StatefulWidget {

  final String url;
  final Color primaryColor;
  final Color accentColor;
  final Color highlightColor;

  ApolloTVPlayer({
    Key key,
    @required this.url,
    this.primaryColor,
    this.accentColor,
    this.highlightColor
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => ApolloTVPlayerState();

}

class ApolloTVPlayerState extends State<ApolloTVPlayer> {

  static const _platform = const MethodChannel('xyz.apollotv/casting');

  VideoPlayerController _controller;
  bool _isPlaying = false;
  bool _isControlsVisible = true;

  int _total = 0;

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
      setState(() {

      });

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

      // Set up controller, and autoplay.
      _controller.setLooping(false);
      _controller.setVolume(1.0);
      _controller.play();

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
        title: 'SocksPlayer',
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
            body: Stack(
                alignment: Alignment.bottomCenter,
                children: <Widget>[
                  Center(
                      child: _controller.value.initialized
                          ? InkWell(
                          child: AspectRatio(
                              aspectRatio: _controller.value.aspectRatio,
                              child: VideoPlayer(_controller)
                          )
                      )
                          : Container()
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


                                ],
                              )
                          )
                      )
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
    double milliseconds = millis.toDouble();
    int seconds = ((milliseconds / 1000) % 60).round();
    int minutes = ((milliseconds / (1000*60)) % 60).round();
    int hours   = ((milliseconds / (1000*60*60)) % 24).round();

    String output =
        (hours > 0 ? hours.toString().padLeft(2, '0') + ":" : "") +
            minutes.toString().padLeft(2, '0') + ":" +
            seconds.toString().padLeft(2, '0');

    return output;
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

}