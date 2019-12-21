![logo](doc/logo.png)

[![Jappiejappie](https://img.shields.io/badge/twitch.tv-jappiejappie-purple?logo=twitch)](https://www.twitch.tv/jappiejappie)
[![Jappiejappie](https://img.shields.io/badge/youtube-jappieklooster-red?logo=youtube)](https://www.youtube.com/channel/UCQxmXSQEYyCeBC6urMWRPVw)
[![Build status](https://img.shields.io/travis/jappeace/cut-the-crap)](https://travis-ci.org/jappeace/cut-the-crap/builds/)
[![Jappiejappie](https://img.shields.io/badge/discord-jappiejappie-black?logo=discord)](https://discord.gg/Hp4agqy)

> Bless This Mess

Cut the crap is an automatic video editing program for streamers.
It can cut out uninteresting parts by detecting silences.
This was inspired by [jumpcutter](https://github.com/carykh/jumpcutter),
where this program can get better quality results
by using an (optional) dedicated microphone track.
This prevents cutting of [quieter consonants](https://youtu.be/DQ8orIurGxw?t=675)
for example.
Using ffmpeg more efficiently also produces faster results and
is less error prone.

Youtube has different requirements from streams then twitch does.
We want to cut out boring parts.
Jumpcut has solved that problem partly and this program
builds on top of that idea.
At the moment we use ffmpeg for silence detection, 
then we do some maths to figure out which segments are sounded,
which is combined into the output video.

In the future we will add support for a music track
which will not be chopped up.

# Use case
I'm using this program to record my [stream](https://www.twitch.tv/jappiejappie)
and upload it to my
[youtube channel](https://www.youtube.com/channel/UCQxmXSQEYyCeBC6urMWRPVw).

Feel free to use or modify this program however you like.
Pull requests are appreciated.

# Features

## Track based silence detection
It is possible to specify one audio output as speech track.
This will be used to for silence detection only.
The result is very precize silence detection.

## Seperate music track
Another track would be background and won't be modified at all.
In the end it just get's cut of how far it is.

This way we get good music and interesting stream.
Another idea is to remix an entirely different source of music
into the video, so we can play copyrighted music on stream
and youtube friendly music on youtube.

# Design
This project is mostly a wrapper around ffmpeg.
We use haskell for shell programing.

The [shelly](http://hackage.haskell.org/package/shelly) library was chosen in support of shell programming.
Originally we used [turtle](http://hackage.haskell.org/package/turtle),
but that library is much more complicated to use because it assumes you
want to do stream programming,
creating several unexpected bugs.
So we replaced it with shelly and noticabally reduced code complexity.
Now it's truly a 'dumb' wrapper around ffmpeg.
