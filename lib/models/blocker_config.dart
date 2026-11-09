import 'package:flutter/foundation.dart';

/// Which Instagram features are blocked. Same model on iOS and Android.
@immutable
class BlockerConfig {
  const BlockerConfig({
    this.blockReels = true,
    this.blockStories = true,
    this.blockExplore = true,
    this.blockSuggested = false,
  });

  final bool blockReels;
  final bool blockStories;
  final bool blockExplore;
  final bool blockSuggested;

  Map<String, dynamic> toJson() => {
        'blockReels': blockReels,
        'blockStories': blockStories,
        'blockExplore': blockExplore,
        'blockSuggested': blockSuggested,
      };

  factory BlockerConfig.fromJson(Map<String, dynamic> json) {
    const d = BlockerConfig();
    bool read(String k, bool fallback) =>
        json[k] is bool ? json[k] as bool : fallback;
    return BlockerConfig(
      blockReels: read('blockReels', d.blockReels),
      blockStories: read('blockStories', d.blockStories),
      blockExplore: read('blockExplore', d.blockExplore),
      blockSuggested: read('blockSuggested', d.blockSuggested),
    );
  }

  BlockerConfig copyWith({
    bool? blockReels,
    bool? blockStories,
    bool? blockExplore,
    bool? blockSuggested,
  }) =>
      BlockerConfig(
        blockReels: blockReels ?? this.blockReels,
        blockStories: blockStories ?? this.blockStories,
        blockExplore: blockExplore ?? this.blockExplore,
        blockSuggested: blockSuggested ?? this.blockSuggested,
      );

  @override
  bool operator ==(Object other) =>
      other is BlockerConfig &&
      other.blockReels == blockReels &&
      other.blockStories == blockStories &&
      other.blockExplore == blockExplore &&
      other.blockSuggested == blockSuggested;

  @override
  int get hashCode =>
      Object.hash(blockReels, blockStories, blockExplore, blockSuggested);
}
