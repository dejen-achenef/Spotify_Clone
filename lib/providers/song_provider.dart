import 'dart:convert';
import 'dart:io';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/song.dart';
import '../homepage/services/api.dart';

// Repeat mode for playback (off, repeat all, repeat one)
enum RepeatMode { off, all, one }

class SongProvider extends ChangeNotifier {
 // Playback controls
 bool shuffle = false;
 RepeatMode repeatMode = RepeatMode.off;
 double _volume = 1.0;
 double _previousVolume = 1.0;
 // playback rate (1.0 == normal)
 double _playbackRate = 1.0;
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

  // Downloaded/offline songs
  List<Song> downloadedSongs = [];

  // Add a song to recently played list
  void _addToRecentlyPlayed(Song song) {
    recentlyPlayed.insert(0, song);
    // keep a limited history
    if (recentlyPlayed.length > 50) {
      recentlyPlayed.removeLast();
    }
    notifyListeners();
  }

  // Download a song for offline play
  Future<void> downloadSong(Song song) async {
    final api = Api();
    final path = await api.fetchSongFile(song);
    if (path.isNotEmpty) {
      song.filePath = path;
      // avoid duplicates
      final exists = downloadedSongs.any((s) => s.artist == song.artist && s.title == song.title);
      if (!exists) {
        downloadedSongs.add(song);
        await saveToDownloadedSongs(downloadedSongs);
        notifyListeners();
      }
    }
  }

  Future<void> saveToDownloadedSongs(List<Song> songs) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> list = songs.map((s) => json.encode({
          'artist': s.artist,
          'title': s.title,
          'genre': s.genre,
          'release_date': s.releaseDate,
          'audio_url': s.audioUrl,
          'image_url': s.imageUrl,
          'file_path': s.filePath,
        })).toList();
    await prefs.setStringList('downloaded-songs', list);
  }

  Future<void> fetchDownloadedFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList('downloaded-songs') ?? <String>[];
    downloadedSongs = list.map((str) {
      final m = json.decode(str) as Map<String, dynamic>;
      return Song(
        artist: m['artist'] ?? '',
        title: m['title'] ?? '',
        genre: m['genre'] ?? '',
        releaseDate: m['release_date'] ?? '',
        audioUrl: m['audio_url'],
        imageUrl: m['image_url'],
        filePath: m['file_path'],
      );
    }).toList();
    notifyListeners();
  }

  bool isDownloaded(Song song) {
    return downloadedSongs.any((s) => s.artist == song.artist && s.title == song.title);
  }

  // Queue helpers
  void addToQueue(Song song) {
    queue.add(song);
    notifyListeners();
  }

  // Skip to next (uses queue)
  Future<void> skipNext() async {
    if (queue.isNotEmpty) {
      final next = shuffle ? (queue..shuffle()).removeAt(0) : queue.removeAt(0);
      final api = Api();
      final path = await api.fetchSongFile(next);
      if (path.isNotEmpty) {
        await playSong(File(path), next);
      }
    }
  }

  // Skip to previous (uses recently played)
  Future<void> skipPrevious() async {
    if (recentlyPlayed.length >= 2) {
      final prev = recentlyPlayed[1];
      final api = Api();
      final path = await api.fetchSongFile(prev);
      if (path.isNotEmpty) {
        await playSong(File(path), prev);
        // remove the duplicated entry
        recentlyPlayed.removeAt(1);
      }
    }
  }

  SongProvider() {
    _audioPlayer.setVolume(_volume);
    // Load persisted playback settings and stored lists
    loadPlaybackPrefs();
    fetchSongsFromStorage();
    fetchLocalsFromStorage();
    fetchDownloadedFromStorage();

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
          // play next in queue
          skipNext();
        } else if (repeatMode == RepeatMode.all) {
          _audioPlayer.seek(Duration.zero);
          _audioPlayer.resume();
        } else {
          stopSong();
        }
        if (playingFile != null) {
          try {
            playingFile?.delete();
          } catch (e) {}
        }
        _song = Song(
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

  // Seek forward/back by seconds
  void seekBy(int seconds) {
    Duration newPos = _position + Duration(seconds: seconds);
    if (newPos < Duration.zero) newPos = Duration.zero;
    if (newPos > _duration) newPos = _duration;
    _audioPlayer.seek(newPos);
    notifyListeners();
  }

  IconData get playingIcon => _playingIcon;

 // Controls
 Future<void> _savePrefs() async {
   final p = await SharedPreferences.getInstance();
   await p.setString('repeat-mode', repeatMode.name);
   await p.setDouble('volume', _volume);
   await p.setDouble('playback-rate', _playbackRate);
   await p.setBool('shuffle', shuffle);
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
   _playbackRate = p.getDouble('playback-rate') ?? 1.0;
   _audioPlayer.setVolume(_volume);
   // apply playback rate
   try {
     // Most audioplayers versions support passing a double
     _audioPlayer.setPlaybackRate(_playbackRate);
   } catch (e) {
     // ignore if not supported
   }
   final savedShuffle = p.getBool('shuffle');
   if (savedShuffle != null) shuffle = savedShuffle;
   notifyListeners();
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

 void toggleShuffle() {
   shuffle = !shuffle;
   _savePrefs();
   notifyListeners();
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

 // Playback rate controls
 double get playbackRate => _playbackRate;

 Future<void> setPlaybackRate(double rate) async {
   _playbackRate = rate;
   try {
     _audioPlayer.setPlaybackRate(_playbackRate);
   } catch (e) {}
   await _savePrefs();
   notifyListeners();
 }

 // Expose mute state to the UI
 bool get isMuted => _volume == 0;

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
