# FluentFly Utilities

This directory contains utility classes and helper functions for the FluentFly mobile application.

## Files

### animation_utils.dart
Comprehensive animation management system with:
- **Preloading**: Critical animations are preloaded on app startup
- **Error Handling**: Automatic fallback to fallback_pulse.json on errors
- **Caching**: Compositions are cached for better performance
- **Easy API**: Simple methods to build animations with error handling

## Available Animations

1. **app_intro_plane.json** - Animated plane for splash/intro screen
2. **ai_tutor_talking.json** - AI avatar talking animation
3. **success_confetti.json** - Celebration animation for achievements
4. **blue_wave_loader.json** - Loading indicator with wave animation
5. **flying_xp_coins.json** - XP coins animation for rewards
6. **audio_wave_mic.json** - Microphone recording animation
7. **happy_feedback_star.json** - Positive feedback animation
8. **sad_robot_retry.json** - Error/retry animation
9. **floating_shapes_bg.json** - Background decoration animation
10. **progress_trophy.json** - Level up/achievement trophy animation
11. **fallback_pulse.json** - Fallback animation for errors

## Usage

### Basic Animation

```dart
import 'package:mobile/utils/animation_utils.dart';

// Simple animation with error handling
AnimationUtils.buildAnimation(
  path: AnimationUtils.aiTutorTalking,
  width: 200,
  height: 200,
  repeat: true,
)
```

### Using Extension Method

```dart
// Even simpler with extension
AnimationUtils.aiTutorTalking.toLottie(
  width: 200,
  height: 200,
  repeat: true,
)
```

### Synced Animation (with audio)

```dart
// Animation that syncs with audio playback
AnimationUtils.buildSyncedAnimation(
  path: AnimationUtils.aiTutorTalking,
  isPlaying: isAudioPlaying,
  width: 200,
  height: 200,
)
```

### Custom Animation with Callback

```dart
AnimationUtils.buildAnimation(
  path: AnimationUtils.successConfetti,
  width: 300,
  height: 300,
  repeat: false,
  onLoaded: () {
    print('Animation loaded!');
  },
)
```

## Preloading

Critical animations are automatically preloaded in `main.dart`:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Preload animations
  await AnimationUtils.preloadAnimations();
  
  runApp(MyApp());
}
```

Preloaded animations:
- app_intro_plane
- ai_tutor_talking
- blue_wave_loader
- fallback_pulse
- audio_wave_mic

## Error Handling

All animations automatically fall back to `fallback_pulse.json` if they fail to load. If even the fallback fails, a CircularProgressIndicator is shown.

```dart
// This will show fallback_pulse.json if the animation fails
AnimationUtils.buildAnimation(
  path: 'assets/lottie/nonexistent.json',
  width: 100,
  height: 100,
)
```

## Cache Management

```dart
// Get cache size
final size = AnimationUtils.getCacheSize();

// Clear cache to free memory
AnimationUtils.clearCache();

// Get cached composition
final composition = AnimationUtils.getCachedComposition(
  AnimationUtils.aiTutorTalking
);
```

## Best Practices

1. **Use preloaded animations** for critical UI elements
2. **Always use AnimationUtils.buildAnimation()** instead of LottieBuilder.asset() directly
3. **Set appropriate sizes** to avoid layout issues
4. **Use repeat: false** for one-time animations (confetti, success)
5. **Use repeat: true** for looping animations (loading, talking)
6. **Sync animations with audio** using buildSyncedAnimation()

## Performance Tips

- Preloaded animations load instantly
- Cached compositions reduce memory usage
- Fallback animations ensure smooth UX even on errors
- Use appropriate sizes to avoid unnecessary rendering
