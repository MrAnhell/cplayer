import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class CPlayerProgress extends StatefulWidget {

  final VideoPlayerController controller;

  final Color activeColor;
  final Color inactiveColor;

  const CPlayerProgress(this.controller, {
    Key key,
    @required this.activeColor,
    @required this.inactiveColor
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _CPlayerProgressState();

}

class _CPlayerProgressState extends State<CPlayerProgress> {

  VoidCallback listener;
  VideoPlayerController get controller => widget.controller;

  Slider _slider;
  double _sliderValue = 0.0;

  _CPlayerProgressState(){
    listener = (){
      setState(() {});
    };
  }

  @override
  void initState(){
    super.initState();
    controller.addListener(listener);
  }

  @override
  void deactivate() {
    controller.removeListener(listener);
    super.deactivate();
  }

  @override
  Widget build(BuildContext context) {

    _slider = new Slider(
        value: (
            controller.value.position != null ?
            controller.value.position.inMilliseconds.toDouble()
                : 0.0
        ),
        onChanged: (newValue){
          controller.seekTo(new Duration(milliseconds: newValue.toInt()));
        },
        onChangeStart: (oldValue){
          controller.pause();
        },
        onChangeEnd: (newValue){
          controller.seekTo(new Duration(milliseconds: newValue.toInt()));
          controller.play();
        },
        min: 0.0,
        max: (
            controller.value.duration != null ?
            controller.value.duration.inMilliseconds.toDouble()
                : 0.0
        ),
        // Watched: side of the slider between thumb and minimum value.
        activeColor: widget.activeColor,
        // To watch: side of the slider between thumb and maximum value.
        inactiveColor: widget.inactiveColor
    );
    return _slider;

  }

}