import 'package:flutter/foundation.dart';

/// Which distractions are blocked. Defaults are strict; each one is a toggle.
@immutable
class BlockerConfig {
  const BlockerConfig({
    this.blockReels = true,
    this.blockDmReels = true,
    this.blockExplore = true,
    this.blockStories = true,
    this.blockSuggested = true,
  });

  /// Reels tab, the `/reels/` feed, profile reels tabs and reel posts in the feed.
  final bool blockReels;

  /// Single reels at `/reel/<id>`, e.g. the ones friends send you in DMs.
  final bool blockDmReels;

  /// The Explore grid. Explore links open plain Search instead.
  final bool blockExplore;

  /// The stories tray at the top of the feed and `/stories/` pages.
  final bool blockStories;

  /// "Suggested for you", suggested posts/reels and sponsored posts.
  final bool blockSuggested;

  factory BlockerConfig.fromJson(Map<String, dynamic> json) {
    const d = BlockerConfig();
    bool read(String key, bool fallback) {
      final v = json[key];
      return v is bool ? v : fallback;
    }

    return BlockerConfig(
      blockReels: read('blockReels', d.blockReels),
      blockDmReels: read('blockDmReels', d.blockDmReels),
      blockExplore: read('blockExplore', d.blockExplore),
      blockStories: read('blockStories', d.blockStories),
      blockSuggested: read('blockSuggested', d.blockSuggested),
    );
  }

  Map<String, dynamic> toJson() => {
        'blockReels': blockReels,
        'blockDmReels': blockDmReels,
        'blockExplore': blockExplore,
        'blockStories': blockStories,
        'blockSuggested': blockSuggested,
      };

  BlockerConfig copyWith({
    bool? blockReels,
    bool? blockDmReels,
    bool? blockExplore,
    bool? blockStories,
    bool? blockSuggested,
  }) =>
      BlockerConfig(
        blockReels: blockReels ?? this.blockReels,
        blockDmReels: blockDmReels ?? this.blockDmReels,
        blockExplore: blockExplore ?? this.blockExplore,
        blockStories: blockStories ?? this.blockStories,
        blockSuggested: blockSuggested ?? this.blockSuggested,
      );

  @override
  bool operator ==(Object other) =>
      other is BlockerConfig &&
      other.blockReels == blockReels &&
      other.blockDmReels == blockDmReels &&
      other.blockExplore == blockExplore &&
      other.blockStories == blockStories &&
      other.blockSuggested == blockSuggested;

  @override
  int get hashCode => Object.hash(
      blockReels, blockDmReels, blockExplore, blockStories, blockSuggested);

  @override
  String toString() => 'BlockerConfig(${toJson()})';
}
