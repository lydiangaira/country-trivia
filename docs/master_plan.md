# Country Trivia App - Master Plan

## 1. Project Overview

A Flutter trivia game where users identify a country by its flag. Each round presents one flag image and four country names. Users have up to three attempts per flag, with decreasing point rewards. The game tracks solved flags, prevents repeats until all countries are exhausted, and persists both score and progress across sessions.

### Core Requirements

| # | Requirement | Details |
|---|-------------|---------|
| 1 | Display flag + 4 country names | One correct, three random distractors |
| 2 | Scoring system | 1st attempt: 10 pts, 2nd: 8 pts, 3rd: 5 pts, fail: 0 pts |
| 3 | Reveal on exhaustion | After 3 wrong attempts, show correct answer |
| 4 | No repeat flags | Solved flags are excluded from future rounds |
| 5 | Reset when all exhausted | After all countries are solved, game resets |
| 6 | Persistence | Score and solved flags survive app restarts |
| 7 | MVVM + Provider | Clean architecture with Provider for state management |
| 8 | Code coverage | ≥ 80% coverage on data sources and ViewModels |
| 9 | Flag image caching | Disk + memory caching for all flag images |

---

## 2. Architecture

### 2.1 Pattern: MVVM (Model-View-ViewModel) with Provider

```
┌─────────────────────────────────────────────────────────┐
│                    PRESENTATION LAYER                    │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  │
│  │   Views       │  │  ViewModels  │  │   Provider   │  │
│  │  (Widgets)    │◄─┤  (ChangeNoti-│◄─┤  (DI / State │  │
│  │              │  │   fier)      │  │   Injection) │  │
│  └──────────────┘  └──────┬───────┘  └──────────────┘  │
│                           │                              │
├───────────────────────────┼──────────────────────────────┤
│                    DOMAIN LAYER                          │
│                  ┌────────┴────────┐                     │
│                  │  Repositories   │                     │
│                  │  (Interfaces)   │                     │
│                  └────────┬────────┘                     │
├───────────────────────────┼──────────────────────────────┤
│                     DATA LAYER                           │
│  ┌──────────────┐  ┌──────┴───────┐  ┌──────────────┐  │
│  │ Country API  │  │  Local Store │  │  Flag CDN    │  │
│  │ (REST)       │  │  (SharedPref)│  │  (Images)    │  │
│  └──────────────┘  └──────────────┘  └──────────────┘  │
└─────────────────────────────────────────────────────────┘
```

### 2.2 Layer Responsibilities

| Layer | Responsibility | Key Classes |
|-------|---------------|-------------|
| **Data** | API calls, JSON parsing, local persistence | `CountryApi`, `LocalStorageService`, `CountryModel` |
| **Domain** | Business logic, repository contracts | `CountryRepository` (abstract), `GameRepository` |
| **Presentation** | UI rendering, user interaction, state exposure | `GameViewModel`, `HomeView`, `GameView`, `ResultView` |

---

## 3. Data Layer

### 3.1 External APIs

#### Country API
- **Endpoint:** `https://restcountries.com/v3.1/all` (or the Postman-documented equivalent)
- **Fields used:** `name.common`, `cca2` (ISO 3166-1 alpha-2 code)
- **Response handling:** Parse JSON list, extract `name.common` and `cca2`, filter out entries with missing data

#### Flag CDN
- **Pattern:** `https://flagcdn.com/w320/{iso}.png`
- **Usage:** `Image.network('https://flagcdn.com/w320/${country.cca2.toLowerCase()}.png')`

#### Flag Image Caching Strategy

Flag images are cached at multiple levels to minimize network usage and improve load times:

| Cache Level | Mechanism | Details |
|-------------|-----------|---------|
| **Memory cache** | `CachedNetworkImage` in-memory LRU | Fastest access; evicted on memory pressure |
| **Disk cache** | `cached_network_image` + `flutter_cache_manager` | Persistent across app restarts; stored in app temp directory |
| **Cache duration** | 7 days default | Configurable via `CacheManager` stale period |
| **Cache key** | Flag CDN URL (unique per ISO code) | Automatic deduplication |

**Implementation:**

```dart
// lib/presentation/widgets/flag_image.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class FlagImage extends StatelessWidget {
  final String url;
  final double width;

  const FlagImage({required this.url, this.width = 320, super.key});

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: url,
      width: width,
      fit: BoxFit.cover,
      placeholder: (context, url) => SizedBox(
        width: width,
        height: width * 0.67,
        child: const Center(child: CircularProgressIndicator()),
      ),
      errorWidget: (context, url, error) => SizedBox(
        width: width,
        height: width * 0.67,
        child: const Center(
          child: Icon(Icons.broken_image, size: 48, color: Colors.grey),
        ),
      ),
      memCacheWidth: width.toInt(),  // Memory cache size optimization
    );
  }
}
```

**Cache configuration (optional custom manager):**

```dart
// lib/core/cache/flag_cache_manager.dart
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class FlagCacheManager extends CacheManager {
  static const key = 'flagCache';

  static final FlagCacheManager _instance = FlagCacheManager._();

  factory FlagCacheManager() => _instance;

  FlagCacheManager._()
      : super(
          Config(
            key,
            stalePeriod: const Duration(days: 7),
            maxNrOfCacheObjects: 500,  // ~500 countries max
            repo: JsonCacheInfoRepository(databaseName: key),
            fileService: HttpFileService(),
          ),
        );
}
```

### 3.2 Data Models

```dart
// lib/data/models/country_model.dart
class CountryModel {
  final String name;    // common name
  final String cca2;    // ISO alpha-2 code (lowercase for flag URL)

  const CountryModel({required this.name, required this.cca2});

  factory CountryModel.fromJson(Map<String, dynamic> json) {
    return CountryModel(
      name: json['name']['common'] as String,
      cca2: json['cca2'] as String,
    );
  }

  String get flagUrl => 'https://flagcdn.com/w320/${cca2.toLowerCase()}.png';
}
```

### 3.3 Local Persistence

**Package:** `shared_preferences`

| Key | Type | Description |
|-----|------|-------------|
| `user_score` | `int` | Cumulative points across all rounds |
| `solved_flags` | `List<String>` | ISO codes of correctly identified countries |
| `total_countries` | `int` | Total available countries (for reset detection) |

```dart
// lib/data/services/local_storage_service.dart
class LocalStorageService {
  static const _scoreKey = 'user_score';
  static const _solvedKey = 'solved_flags';

  Future<int> getScore();
  Future<void> setScore(int score);
  Future<Set<String>> getSolvedFlags();
  Future<void> addSolvedFlag(String cca2);
  Future<void> resetSolvedFlags();
}
```

### 3.4 Repository Implementation

```dart
// lib/data/repositories/country_repository.dart
class CountryRepository {
  final CountryApi _api;
  final LocalStorageService _storage;

  CountryRepository(this._api, this._storage);

  Future<List<CountryModel>> fetchAllCountries();
  Future<Set<String>> getSolvedFlags();
  Future<void> markSolved(String cca2);
  Future<int> getScore();
  Future<void> addScore(int points);
  Future<void> resetSolvedFlags();
}
```

---

## 4. Domain Layer

### 4.1 Game Logic

```dart
// lib/domain/entities/game_state.dart
enum AttemptResult { correct, wrong, gameComplete }

class GameState {
  final CountryModel currentFlag;
  final List<String> options;        // 4 country names (1 correct + 3 distractors)
  final int attemptNumber;           // 1, 2, or 3
  final int score;
  final Set<String> solvedFlags;
  final bool isComplete;             // true when all countries solved
}
```

### 4.2 Scoring Rules

| Attempt | Points |
|---------|--------|
| 1st (index 0) | 10 |
| 2nd (index 1) | 8 |
| 3rd (index 2) | 5 |
| Failed all 3 | 0 |

### 4.3 Distractor Selection Algorithm

1. Fetch all countries from API
2. Remove already-solved countries from the pool
3. Randomly select 1 correct answer + 3 distractors from remaining pool
4. Shuffle the 4 options
5. If pool < 4 countries remain, allow repeats of solved flags as distractors (or reset early)

---

## 5. Presentation Layer

### 5.1 ViewModel

```dart
// lib/presentation/viewmodels/game_viewmodel.dart
class GameViewModel extends ChangeNotifier {
  final CountryRepository _repository;

  GameState? _state;
  bool _isLoading = true;
  String? _feedbackMessage;  // "Correct!" / "Try again!" / reveal answer

  GameState? get state => _state;
  bool get isLoading => _isLoading;
  String? get feedbackMessage => _feedbackMessage;

  GameViewModel(this._repository);

  Future<void> initialize();
  Future<AttemptResult> submitAnswer(String selectedName);
  Future<void> nextRound();
  Future<void> resetGame();
}
```

### 5.2 ViewModel State Machine

```
                    ┌──────────┐
                    │  LOADING │
                    └────┬─────┘
                         │ fetch countries
                         ▼
                    ┌──────────┐
         ┌─────────│  PLAYING │─────────┐
         │         └────┬─────┘         │
         │              │               │
    wrong attempt   correct attempt   3rd wrong
         │              │               │
         ▼              ▼               ▼
    ┌─────────┐   ┌──────────┐   ┌───────────┐
    │ PLAYING │   │ REVEAL   │   │  REVEAL   │
    │(attempt │   │(correct) │   │  (failed) │
    │  2 or 3)│   └────┬─────┘   └─────┬─────┘
    └─────────┘        │               │
                       │  "Next"       │  "Next"
                       ▼               ▼
                  ┌──────────────────────┐
                  │   CHECK COMPLETE?    │
                  └──────────┬───────────┘
                             │
              ┌──────────────┼──────────────┐
              │ yes          │              │ no
              ▼              │              ▼
        ┌───────────┐        │        ┌──────────┐
        │ GAME_OVER │        │        │ PLAYING  │
        │  (reset)  │        │        │(new flag)│
        └───────────┘        │        └──────────┘
                             │
                             ▼
                       ┌──────────┐
                       │ GAME_OVER│
                       │  (reset) │
                       └──────────┘
```

### 5.3 Screens / Views

#### HomeView
- Displays current score (from persistent storage)
- "Play" button → navigates to GameView
- Brief instructions

#### GameView
- Flag image at top (loaded from Flag CDN)
- 4 answer buttons in a 2x2 grid
- Attempt indicator (e.g., "Attempt 1 of 3")
- Score display
- Feedback overlay on answer (correct/wrong/reveal)

#### ResultView (or overlay)
- Shows correct answer when revealed
- "Next Flag" button
- When all countries solved: "Game Complete — Reset" button

### 5.4 Widget Tree

```
GameView (Consumer<GameViewModel>)
├── Column
│   ├── ScoreBar (score, attempt indicator)
│   ├── FlagImage (CachedNetworkImage)
│   ├── OptionsGrid
│   │   ├── AnswerButton (×4)
│   │   └── ...
│   └── FeedbackOverlay (conditional)
│       ├── CorrectFeedback (green, points earned)
│       ├── WrongFeedback (red, "Try again")
│       └── RevealFeedback (orange, correct answer shown)
```

---

## 6. State Management with Provider

### 6.1 Provider Setup

```dart
// lib/main.dart
void main() {
  runApp(
    MultiProvider(
      providers: [
        Provider<CountryRepository>(
          create: (_) => CountryRepository(
            CountryApi(),
            LocalStorageService(),
          ),
        ),
        ChangeNotifierProvider<GameViewModel>(
          create: (ctx) => GameViewModel(
            ctx.read<CountryRepository>(),
          )..initialize(),
        ),
      ],
      child: const CountryTriviaApp(),
    ),
  );
}
```

### 6.2 State Consumption

```dart
// In widgets:
final viewModel = context.watch<GameViewModel>();
// or
final viewModel = context.read<GameViewModel>(); // for callbacks
```

### 6.3 Why Provider (over Bloc/Riverpod)

- Simpler learning curve
- Built on `InheritedWidget` (no code generation)
- Sufficient for this app's complexity
- `ChangeNotifier` is idiomatic Flutter

---

## 7. Testing & Code Coverage

### 7.1 Coverage Targets

| Layer | Target | Scope |
|-------|--------|-------|
| **Data sources** | ≥ 80% | `CountryApi`, `LocalStorageService`, `CountryRepository`, `CountryModel` |
| **ViewModels** | ≥ 80% | `GameViewModel` — all state transitions, scoring, reset logic |
| Domain | ≥ 70% | `GameState`, `ScoreCalculator` |
| Widgets | ≥ 50% | Critical user flows only (answer submission, navigation) |

### 7.2 Coverage Measurement

```bash
# Run tests with coverage
flutter test --coverage

# Generate HTML report
genhtml coverage/lcov.info -o coverage/html

# View report
open coverage/html/index.html
```

### 7.3 Test Strategy for Data Sources

```dart
// test/unit/data/country_api_test.dart
void main() {
  group('CountryApi', () {
    late MockClient mockClient;
    late CountryApi api;

    setUp(() {
      mockClient = MockClient();
      api = CountryApi(client: mockClient);
    });

    test('fetchAllCountries returns parsed countries on 200', () async {
      // Arrange
      mockClient.whenGet('/all', returns: jsonMockResponse);

      // Act
      final result = await api.fetchAllCountries();

      // Assert
      expect(result, isA<List<CountryModel>>());
      expect(result.length, 3);
      expect(result.first.name, 'United States');
      expect(result.first.cca2, 'US');
    });

    test('fetchAllCountries throws on non-200 status', () async {
      mockClient.whenGet('/all', returns: '', statusCode: 500);
      expect(() => api.fetchAllCountries(), throwsException);
    });

    test('fetchAllCountries filters out entries with missing name', () async {
      mockClient.whenGet('/all', returns: jsonWithMissingFields);
      final result = await api.fetchAllCountries();
      expect(result.every((c) => c.name.isNotEmpty && c.cca2.isNotEmpty), true);
    });
  });
}
```

### 7.4 Test Strategy for ViewModel

```dart
// test/unit/presentation/game_viewmodel_test.dart
void main() {
  group('GameViewModel', () {
    late MockCountryRepository mockRepo;
    late GameViewModel viewModel;

    setUp(() {
      mockRepo = MockCountryRepository();
      viewModel = GameViewModel(mockRepo);
    });

    group('initialize', () {
      test('loads countries and sets initial state', () async {
        // ...
      });
      test('handles empty country list gracefully', () async {
        // ...
      });
    });

    group('submitAnswer', () {
      test('awards 10 points on first correct attempt', () async {
        // ...
      });
      test('awards 8 points on second correct attempt', () async {
        // ...
      });
      test('awards 5 points on third correct attempt', () async {
        // ...
      });
      test('awards 0 points and reveals after third wrong attempt', () async {
        // ...
      });
      test('does not allow submission after round is complete', () async {
        // ...
      });
    });

    group('nextRound', () {
      test('advances to next unsolved country', () async {
        // ...
      });
      test('sets isComplete when all countries solved', () async {
        // ...
      });
    });

    group('resetGame', () {
      test('clears solved flags and restarts', () async {
        // ...
      });
    });
  });
}
```

### 7.5 Coverage Exclusions

The following are excluded from coverage metrics:
- `main.dart` (boilerplate)
- Auto-generated files (`*.g.dart`, `*.freezed.dart`)
- Pure UI widgets with no logic (layout-only builders)

---

## 8. Dependencies (pubspec.yaml)

```yaml
dependencies:
  flutter:
    sdk: flutter
  provider: ^6.1.1          # State management
  http: ^1.2.0              # API calls
  shared_preferences: ^2.2.2  # Local persistence
  cached_network_image: ^3.3.1  # Flag image caching
  flutter_cache_manager: ^3.3.1  # Cache management for flags

dev_dependencies:
  flutter_test:
    sdk: flutter
  mockito: ^5.4.2           # Mocking for tests
  build_runner: ^2.4.7      # Code generation (mockito)
  coverage: ^1.6.3          # Coverage measurement
  lcov: ^0.4.0              # LCOV report generation
```

---

## 9. Project File Structure

```
lib/
├── main.dart
├── app.dart
├── core/
│   ├── constants/
│   │   └── api_constants.dart
│   └── utils/
│       └── score_calculator.dart
├── data/
│   ├── models/
│   │   └── country_model.dart
│   ├── services/
│   │   ├── country_api.dart
│   │   └── local_storage_service.dart
│   └── repositories/
│       └── country_repository.dart
├── domain/
│   └── entities/
│       └── game_state.dart
└── presentation/
    ├── viewmodels/
    │   └── game_viewmodel.dart
    ├── views/
    │   ├── home_view.dart
    │   ├── game_view.dart
    │   └── result_view.dart
    └── widgets/
        ├── flag_image.dart
        ├── answer_button.dart
        ├── options_grid.dart
        ├── score_bar.dart
        └── feedback_overlay.dart

test/
├── unit/
│   ├── data/
│   │   ├── country_model_test.dart
│   │   ├── country_api_test.dart
│   │   ├── local_storage_service_test.dart
│   │   └── country_repository_test.dart
│   ├── domain/
│   │   └── score_calculator_test.dart
│   └── presentation/
│       └── game_viewmodel_test.dart
├── widget/
│   └── game_view_test.dart
└── helpers/
    ├── mock_client.dart
    └── mock_repositories.dart
```

---

## 10. Execution Plan (Milestones)

### Phase 1: Project Setup & Data Layer
1. Create Flutter project: `flutter create country_trivia`
2. Add dependencies to `pubspec.yaml`
3. Implement `CountryModel` with JSON parsing
4. Implement `CountryApi` with HTTP client
5. Implement `LocalStorageService` with SharedPreferences
6. Implement `CountryRepository`
7. **Verify:** Unit test API parsing and storage read/write
8. **Coverage gate:** `flutter test --coverage` → data layer ≥ 80%

### Phase 2: Domain & ViewModel
1. Define `GameState` entity
2. Implement `ScoreCalculator` utility
3. Implement `GameViewModel` with full state machine
4. **Verify:** Unit test ViewModel logic (scoring, attempt tracking, reset)
5. **Coverage gate:** `flutter test --coverage` → ViewModel ≥ 80%

### Phase 3: UI Implementation
1. Build `HomeView` with score display and play button
2. Build `GameView` with flag image (CachedNetworkImage), options grid, score bar
3. Build `AnswerButton` and `OptionsGrid` widgets
4. Build `FeedbackOverlay` (correct/wrong/reveal states)
5. Build `ResultView` for game-complete and reset
6. Wire up Provider in `main.dart`
7. **Verify:** Manual testing on emulator/device

### Phase 4: Polish & Persistence Verification
1. Add loading states and error handling
2. Verify flag image caching (memory + disk) across app restarts
3. Test persistence: kill app, relaunch, verify score/solved flags persist
4. Test full game loop: solve all countries → reset → play again
5. **Verify:** Widget tests for key user flows

### Phase 5: Testing & QA
1. Unit tests for ViewModel and ScoreCalculator
2. Widget tests for GameView interactions
3. Integration test for full game flow
4. Edge cases: empty API response, network failure, < 4 countries remaining
5. **Final coverage gate:** `flutter test --coverage` → data + ViewModel ≥ 80%

---

## 11. Edge Cases & Considerations

| Scenario | Handling |
|----------|----------|
| API fetch fails | Show error state with retry button |
| < 4 unsolved countries remain | Allow solved countries as distractors, or trigger early reset |
| Network image fails to load | Show placeholder with country name hidden |
| All countries solved | Show "Game Complete" screen with final score and reset button |
| User kills app mid-round | Score and solved flags already persisted; resume cleanly |
| Duplicate country names in options | Ensure distractors are distinct from correct answer |

---

## 12. API Reference

### Countries API
- **Base URL:** `https://restcountries.com/v3.1`
- **Endpoint:** `GET /all`
- **Key fields:** `name.common`, `cca2`
- **Postman docs:** https://documenter.getpostman.com/view/1134062/T1LJjU52

### Flag CDN
- **Pattern:** `https://flagcdn.com/w320/{iso}.png`
- **Example:** `https://flagcdn.com/w320/us.png` (for United States)
- **Sizes available:** 20, 40, 80, 160, 320, 640, 1280, 2560

---

## 13. Summary

This plan delivers a fully functional Country Trivia app using MVVM architecture with Provider for state management. The app fetches country data from REST Countries API, displays flags from Flag CDN with multi-level caching (memory + disk via `cached_network_image`), implements a 3-attempt scoring system (10/8/5 points), prevents flag repetition, resets after all countries are solved, and persists both score and progress using SharedPreferences. The phased execution plan ensures incremental development with verification at each step, including mandatory 80% code coverage gates for all data sources and ViewModels.
