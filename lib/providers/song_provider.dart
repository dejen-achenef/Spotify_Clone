import 'dart:convert';
import 'dart:io';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/song.dart';

class SongProvider extends ChangeNotifier {
 // Playback controls
 bool shuffle = false;
 RepeatMode repeatMode = RepeatMode.off;
 double _volume = 1.0;
 double _previousVolume = 1.0;
 Timer? _sleepTimer;

 // Queue and history
 final List<Song> queue = [];
 final List<Song> recentlyPlayed = [];
  bool _isPlaying = false;
  bool _isPaused = false;
  bool _isCurrentlyPlaying = false;
  Song _song = Song(
    artist: '',
    title: '',
    genre: '',
    releaseDate: '',
    audioUrl: '',
    imageUrl: '',
  );

  File? playingFile;

  int secondsDuration = 0;
  int minutesDuration = 0;

  IconData _playingIcon = Icons.play_arrow;

  AudioPlayer _audioPlayer = AudioPlayer()..setReleaseMode(ReleaseMode.stop);


  Duration _duration = Duration();
  Duration _position = Duration();

  List<Song> likedSongs = [];
  List<Song> likedLocals = [];

  SongProvider() {
    _audioPlayer.setVolume(_volume);

    _audioPlayer.onDurationChanged.listen((Duration duration) {
      _duration = duration;
      notifyListeners();
    });
    _audioPlayer.onPositionChanged.listen((Duration position) {
      _position = position;
      secondsDuration = _position.inSeconds.toInt() % 60;
      minutesDuration = _position.inMinutes.toInt();

      if (_position == _duration && _duration != Duration.zero) {
        // handle track end based on repeat/shuffle
        if (repeatMode == RepeatMode.one) {
          _audioPlayer.seek(Duration.zero);
          _audioPlayer.resume();
        } else if (queue.isNotEmpty) {
          final next = shuffle ? (queue..shuffle()).removeAt(0) : queue.removeAt(0);
          // Note: requires external file fetching; here we just stop for simplicity
          stopSong();
        } else if (repeatMode == RepeatMode.all) {
          _audioPlayer.seek(Duration.zero);
          _audioPlayer.resume();
        } else {
          stopSong();
        }
        if (playingFile != null) {
          playingFile!.delete();
        }
        _song = Song
          artist: '',
          title: '',
          genre: '',
          releaseDate: '',
          audioUrl: '',
          imageUrl: '',
        );
      }
      notifyListeners();
    });
  }

  Future<void> playSong(File file, Song song) async {
    _addToRecentlyPlayed(song);

    playingFile = file;
    _song = song;
    await _audioPlayer.play(DeviceFileSource(file.path));
    _isCurrentlyPlaying = true;
    _isPlaying = true;
    _playingIcon = Icons.pause;
    notifyListeners();
  }

  void resumeSong() {
    _audioPlayer.resume();
    _isPaused = false;
    _isPlaying = true;
    _playingIcon = Icons.pause;
    notifyListeners();
  }

  void pauseSong() {
    _audioPlayer.pause();
    _isPaused = true;
    _isPlaying = false;
    _playingIcon = Icons.play_arrow;
    notifyListeners();
  }

  void stopSong() {
    _sleepTimer?.cancel();

    _position = Duration.zero;
    _audioPlayer.stop();
    playingFile!.delete();
    _isCurrentlyPlaying = false;
    _isPlaying = false;
    _isPaused = false;
    notifyListeners();
  }

  void onPositionChanged(int secondsValue) {
    Duration newDur = Duration(seconds: secondsValue);
    _audioPlayer.seek(newDur);
    notifyListeners();
  }

  IconData get playingIcon => _playingIcon;

 // Controls
 Future<void> _savePrefs() async {
   final p = await SharedPreferences.getInstance();
   await p.setString('repeat-mode', repeatMode.name);
   await p.setDouble('volume', _volume);
 }

 Future<void> loadPlaybackPrefs() async {
   final p = await SharedPreferences.getInstance();
   final rm = p.getString('repeat-mode');
   if (rm != null) {
     repeatMode = RepeatMode.values.firstWhere(
       (e) => e.name == rm,
       orElse: () => RepeatMode.off,
     );
   }
   _volume = p.getDouble('volume') ?? 1.0;
   _audioPlayer.setVolume(_volume);
   notifyListeners();
 }

 void toggleShuffle() {
   shuffle = !shuffle;
   notifyListeners();
   _savePrefs();
 }

 void cycleRepeatMode() {
   switch (repeatMode) {
     case RepeatMode.off:
       repeatMode = RepeatMode.all;
       break;
     case RepeatMode.all:
       repeatMode = RepeatMode.one;
       break;
     case RepeatMode.one:
       repeatMode = RepeatMode.off;
       break;
   }
   notifyListeners();
   _savePrefs();
 }

 void toggleMute() {
   if (_volume > 0) {
     _previousVolume = _volume;
     _volume = 0;
   } else {
     _volume = _previousVolume;
   }
   _audioPlayer.setVolume(_volume);
   notifyListeners();
 }

 void startSleepTimer(Duration duration) {
   _sleepTimer?.cancel();
   _sleepTimer = Timer(duration, () {
     stopSong();
     notifyListeners();
   });
 }

  bool get isCurrentlyPlaying => _isCurrentlyPlaying;
  bool get isPlaying => _isPlaying;
  bool get isPaused => _isPaused;
  Song get playingSong => _song;
  Duration get position => _position;
  Duration get duration => _duration;

  void likeSong(Song song) {
    final exists = likedSongs.any((s) => s.artist == song.artist && s.title == song.title);
    if (!exists) {
      likedSongs.add(song);
      saveToLikedSongs(likedSongs);
      notifyListeners();
    }
  }

  void dislikeSong(Song song) {
    Song? findSong = likedSongs.firstWhere(
      (sg) => sg.artist == song.artist && sg.title == song.title,
    );
    removeFromLikedSongs(findSong);
    likedSongs.remove(findSong);
    notifyListeners();
  }

  void likeLocal(Song song) {
    likedLocals.add(song);
    saveToLikedLocals(likedLocals);
    notifyListeners();
  }

  void dislikeLocal(Song song) {
    Song? findSong = likedLocals.firstWhere(
      (sg) => sg.artist == song.artist && sg.title == song.title,
    );
    removeFromLikedLocals(findSong);
    likedLocals.remove(findSong);
    notifyListeners();
  }

  void saveToLikedSongs(List<Song> theSongs) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> likedString = theSongs
        .map(
          (liked) => liked.toString(),
        )
        .toList();
    await prefs.setStringList('liked-songs', likedString);
  }

  void saveToLikedLocals(List<Song> theSongs) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> likedString = likedLocals
        .map(
          (liked) => liked.toString(),
        )
        .toList();
    prefs.setStringList('liked-locals', likedString);
  }

  void removeFromLikedSongs(Song song) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> likedString = prefs.getStringList('liked-songs')!;

    List<Song> songs = [];

    for (var str in likedString) {
      Song sng = Song.fromString(str);

      if (sng.artist == song.artist && sng.title == song.title) {
        continue;
      }
      songs.add(Song.fromString(str));
    }
    saveToLikedSongs(songs);
  }

  void removeFromLikedLocals(Song song) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> likedString = prefs.getStringList('liked-locals')!;

    List<Song> songs = [];

    for (var str in likedString) {
      Song sng = Song.fromString(str);

      if (sng.artist == song.artist && sng.title == song.title) {
        continue;
      }
      songs.add(Song.fromString(str));
    }
    saveToLikedLocals(songs);
  }

  void fetchLocalsFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    //prefs.setStringList('liked-locals', []);
    List<String>? likedString = prefs.getStringList('liked-locals');

    List<Song> songs = [];

    for (var str in likedString!) {
      songs.add(Song.fromString(str));
    }
    likedLocals = songs;
    notifyListeners();
  }

  void fetchSongsFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final likedString = prefs.getStringList('liked-songs') ?? <String>[];
    final songs = <Song>[];
    for (var str in likedString) {
      songs.add(Song.fromString(str));
    }
    likedSongs = songs;
    notifyListeners();
  }
}
