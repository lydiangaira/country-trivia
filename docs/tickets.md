# Country Trivia App — Execution Tickets

## Ticket Summary

| ID | Title | Phase | Depends On | Concurrent With |
|----|-------|-------|------------|-----------------|
| T-01 | Project scaffolding & dependencies | 1 | — | T-02 |
| T-02 | Core constants & utilities | 1 | — | T-01 |
| T-03 | CountryModel with JSON parsing | 1 | T-02 | T-04 |
| T-04 | LocalStorageService (SharedPreferences) | 1 | T-02 | T-03 |
| T-05 | CountryApi with HTTP client | 1 | T-02 | T-03, T-04 |
| T-06 | CountryRepository implementation | 1 | T-03, T-04, T-05 | — |
| T-07 | Data layer unit tests (≥80% coverage) | 1 | T-06 | — |
| T-08 | GameState entity & ScoreCalculator | 2 | T-02 | — |
| T-09 | GameViewModel with full state machine | 2 | T-06, T-08 | — |
| T-10 | ViewModel unit tests (≥80% coverage) | 2 | T-09 | — |
| T-11 | FlagImage widget with caching | 3 | T-03 | T-12, T-13, T-14 |
| T-12 | AnswerButton & OptionsGrid widgets | 3 | T-08 | T-11, T-13, T-14 |
| T-13 | ScoreBar widget | 3 | T-08 | T-11, T-12, T-14 |
| T-14 | FeedbackOverlay widget | 3 | T-08 | T-11, T-12, T-13 |
| T-15 | HomeView screen | 3 | T-09, T-13 | T-16 |
| T-16 | GameView screen | 3 | T-09, T-11, T-12, T-14 | T-15 |
| T-17 | ResultView screen | 3 | T-09, T-14 | T-15, T-16 |
| T-18 | Provider wiring in main.dart | 3 | T-06, T-09, T-15, T-16, T-17 | — |
| T-19 | Loading states & error handling | 4 | T-18 | T-20 |
| T-20 | Persistence verification & full game loop test | 4 | T-18 | T-19 |
| T-21 | Widget tests for critical user flows | 4 | T-18 | T-19, T-20 |
| T-22 | Integration test — full game flow | 5 | T-19, T-20, T-21 | — |
| T-23 | Edge case handling & final QA | 5 | T-22 | — |

---

## Execution Order & Concurrency Graph

```
Phase 1 (Data Layer)
════════════════════
T-01 ──┬── T-03 ──┐
       │           ├── T-06 ── T-07
T-02 ──┼── T-04 ──┤
       │           │
       └── T-05 ──┘

Phase 2 (Domain & ViewModel)
════════════════════════════
T-02 ── T-08 ──┐
               ├── T-09 ── T-10
T-06 ──────────┘

Phase 3 (UI)
═════════════
T-03 ──┬── T-11 ──┐
       │           │
T-08 ──┼── T-12 ──┼── T-16 ──┐
       │           │          │
       ├── T-13 ──┤          ├── T-18
       │           │          │
       └── T-14 ──┘          │
                  │          │
T-09 + T-13 ── T-15 ─────────┤
                  │          │
T-09 + T-14 ── T-17 ─────────┘

Phase 4 (Polish)
═════════════════
T-18 ──┬── T-19 ──┐
       │           ├── T-21
       ├── T-20 ──┤
       │           │
       └── T-20 ──┘

Phase 5 (QA)
═════════════
T-19 + T-20 + T-21 ── T-22 ── T-23
```

---

## Detailed Tickets

### T-01: Project Scaffolding & Dependencies

| Field | Value |
|-------|-------|
| **Phase** | 1 — Data Layer |
| **Depends on** | — |
| **Concurrent with** | T-02 |
| **Estimated effort** | 0.5 day |

**Description:**
Create the Flutter project and configure all dependencies.

**Tasks:**
- Run `flutter create country_trivia`
- Add dependencies to `pubspec.yaml`: `provider`, `http`, `shared_preferences`, `cached_network_image`, `flutter_cache_manager`
- Add dev dependencies: `mockito`, `build_runner`, `coverage`, `lcov`
- Run `flutter pub get`
- Verify project builds with `flutter analyze`

**Acceptance criteria:**
 [K] Project compiles, `flutter analyze` passes with no errors

---

### T-02: Core Constants & Utilities

| Field | Value |
|-------|-------|
| **Phase** | 1 — Data Layer |
| **Depends on** | — |
| **Concurrent with** | T-01 |
| **Estimated effort** | 0.5 day |

**Description:**
Create shared constants and utility classes used across layers.

**Tasks:**
- Create `lib/core/constants/api_constants.dart` with API base URLs and flag CDN pattern
- Create `lib/core/utils/score_calculator.dart` with point values (10/8/5/0)
- Create `lib/core/cache/flag_cache_manager.dart` with custom `CacheManager` config

**Acceptance criteria:**
 [K] Constants and utilities compile, score calculator returns correct values for all attempt numbers

---

### T-03: CountryModel with JSON Parsing

| Field | Value |
|-------|-------|
| **Phase** | 1 — Data Layer |
| **Depends on** | T-02 |
| **Concurrent with** | T-04, T-05 |
| **Estimated effort** | 0.5 day |

**Description:**
Implement the data model for country information.

**Tasks:**
- Create `lib/data/models/country_model.dart`
- Implement `fromJson` factory constructor
- Add `flagUrl` getter that constructs the Flag CDN URL
- Add validation: filter out entries with missing `name` or `cca2`

**Acceptance criteria:** [K] Model correctly parses valid JSON, handles missing fields gracefully

---

### T-04: LocalStorageService (SharedPreferences)

| Field | Value |
|-------|-------|
| **Phase** | 1 — Data Layer |
| **Depends on** | T-02 |
| **Concurrent with** | T-03, T-05 |
| **Estimated effort** | 0.5 day |

**Description:**
Implement local persistence for score and solved flags.

**Tasks:**
- Create `lib/data/services/local_storage_service.dart`
- Implement `getScore()` / `setScore(int)`
- Implement `getSolvedFlags()` / `addSolvedFlag(String cca2)`
- Implement `resetSolvedFlags()`
- Handle type conversion and missing key edge cases

**Acceptance criteria:** [K] All CRUD operations work correctly with SharedPreferences

---

### T-05: CountryApi with HTTP Client

| Field | Value |
|-------|-------|
| **Phase** | 1 — Data Layer |
| **Depends on** | T-02 |
| **Concurrent with** | T-03, T-04 |
| **Estimated effort** | 0.5 day |

**Description:**
Implement the HTTP client for fetching country data.

**Tasks:**
- Create `lib/data/services/country_api.dart`
- Implement `fetchAllCountries()` using `http` package
- Parse JSON response into `List<CountryModel>`
- Add error handling for non-200 status codes
- Support dependency injection of `http.Client` for testability

**Acceptance criteria:** [K] API returns parsed country list on success, throws on HTTP errors

---

### T-06: CountryRepository Implementation

| Field | Value |
|-------|-------|
| **Phase** | 1 — Data Layer |
| **Depends on** | T-03, T-04, T-05 |
| **Concurrent with** | — |
| **Estimated effort** | 0.5 day |

**Description:**
Implement the repository that coordinates API and local storage.

**Tasks:**
- Create `lib/data/repositories/country_repository.dart`
- Implement `fetchAllCountries()` — delegates to `CountryApi`
- Implement `getSolvedFlags()` / `markSolved()` — delegates to `LocalStorageService`
- Implement `getScore()` / `addScore()` — delegates to `LocalStorageService`
- Implement `resetSolvedFlags()` — clears solved flags only (preserves score)

**Acceptance criteria:** [K] All repository methods delegate correctly to API and storage

---

### T-07: Data Layer Unit Tests (≥80% Coverage)

| Field | Value |
|-------|-------|
| **Phase** | 1 — Data Layer |
| **Depends on** | T-06 |
| **Concurrent with** | — |
| **Estimated effort** | 1 day |

**Description:**
Write comprehensive unit tests for all data layer components.

**Tasks:**
- Create `test/helpers/mock_client.dart` — shared `MockClient` factory
- Create `test/unit/data/country_model_test.dart` — JSON parsing, edge cases
- Create `test/unit/data/country_api_test.dart` — success, error, filtering
- Create `test/unit/data/local_storage_service_test.dart` — CRUD operations
- Create `test/unit/data/country_repository_test.dart` — delegation logic
- Run `flutter test --coverage` and verify ≥ 80% on data layer

**Acceptance criteria:** [K] Coverage report shows ≥ 80% for `lib/data/`, all tests pass

---

### T-08: GameState Entity & ScoreCalculator

| Field | Value |
|-------|-------|
| **Phase** | 2 — Domain & ViewModel |
| **Depends on** | T-02 |
| **Concurrent with** | — |
| **Estimated effort** | 0.5 day |

**Description:**
Implement domain entities and scoring logic.

**Tasks:**
- Create `lib/domain/entities/game_state.dart` with `GameState` class and `AttemptResult` enum
- Implement `ScoreCalculator` in `lib/core/utils/score_calculator.dart`
- Add `getPointsForAttempt(int attemptNumber)` → 10, 8, 5, or 0
- Add unit tests for `ScoreCalculator`

**Acceptance criteria:** [K] ScoreCalculator returns correct points for attempts 1-3 and 0 for failures

---

### T-09: GameViewModel with Full State Machine

| Field | Value |
|-------|-------|
| **Phase** | 2 — Domain & ViewModel |
| **Depends on** | T-06, T-08 |
| **Concurrent with** | — |
| **Estimated effort** | 1.5 days |

**Description:**
Implement the ViewModel containing all game logic and state management.

**Tasks:**
- Create `lib/presentation/viewmodels/game_viewmodel.dart`
- Implement `initialize()` — fetch countries, load solved flags, set up first round
- Implement `submitAnswer(String selectedName)` — validate, score, update state
- Implement `nextRound()` — advance to next unsolved country or trigger game complete
- Implement `resetGame()` — clear solved flags and restart
- Implement distractor selection algorithm (1 correct + 3 random, shuffled)
- Handle edge cases: empty country list, < 4 countries remaining, duplicate names

**Acceptance criteria:** [K] All state transitions work correctly, scoring is accurate, no repeat flags

---

### T-10: ViewModel Unit Tests (≥80% Coverage)

| Field | Value |
|-------|-------|
| **Phase** | 2 — Domain & ViewModel |
| **Depends on** | T-09 |
| **Concurrent with** | — |
| **Estimated effort** | 1 day |

**Description:**
Write comprehensive unit tests for the GameViewModel.

**Tasks:**
- Create `test/helpers/mock_repositories.dart` — `MockCountryRepository`
- Create `test/unit/presentation/game_viewmodel_test.dart`
- Test `initialize()` — success, empty list, error handling
- Test `submitAnswer()` — correct on 1st/2nd/3rd attempt, wrong answers, post-completion submission
- Test `nextRound()` — advance, game complete detection
- Test `resetGame()` — clears state and restarts
- Run `flutter test --coverage` and verify ≥ 80% on ViewModel

**Acceptance criteria:** [K] Coverage report shows ≥ 80% for `game_viewmodel.dart`, all tests pass

---

### T-11: FlagImage Widget with Caching

| Field | Value |
|-------|-------|
| **Phase** | 3 — UI |
| **Depends on** | T-03 |
| **Concurrent with** | T-12, T-13, T-14 |
| **Estimated effort** | 0.5 day |

**Description:**
Implement the flag image widget with multi-level caching.

**Tasks:**
- Create `lib/presentation/widgets/flag_image.dart`
- Use `CachedNetworkImage` with `FlagCacheManager`
- Add loading placeholder (`CircularProgressIndicator`)
- Add error widget (`Icons.broken_image`)
- Configure `memCacheWidth` for memory optimization

**Acceptance criteria:** [K] Widget renders flag from cache on second load, shows placeholder/error states

---

### T-12: AnswerButton & OptionsGrid Widgets

| Field | Value |
|-------|-------|
| **Phase** | 3 — UI |
| **Depends on** | T-08 |
| **Concurrent with** | T-11, T-13, T-14 |
| **Estimated effort** | 0.5 day |

**Description:**
Implement the answer selection UI components.

**Tasks:**
- Create `lib/presentation/widgets/answer_button.dart`
- Create `lib/presentation/widgets/options_grid.dart`
- Style buttons with default/correct/wrong/disabled states
- Support 2x2 grid layout
- Add `onSelected` callback

**Acceptance criteria:** [K] Buttons render correctly, trigger callbacks, show appropriate visual states

---

### T-13: ScoreBar Widget

| Field | Value |
|-------|-------|
| **Phase** | 3 — UI |
| **Depends on** | T-08 |
| **Concurrent with** | T-11, T-12, T-14 |
| **Estimated effort** | 0.5 day |

**Description:**
Implement the score and attempt indicator display.

**Tasks:**
- Create `lib/presentation/widgets/score_bar.dart`
- Display current score
- Display attempt indicator (e.g., "Attempt 1 of 3")
- Make it responsive and theme-aware

**Acceptance criteria:** [K] Score and attempt number display correctly, layout is clean

---

### T-14: FeedbackOverlay Widget

| Field | Value |
|-------|-------|
| **Phase** | 3 — UI |
| **Depends on** | T-08 |
| **Concurrent with** | T-11, T-12, T-13 |
| **Estimated effort** | 0.5 day |

**Description:**
Implement the feedback overlay for correct/wrong/reveal states.

**Tasks:**
- Create `lib/presentation/widgets/feedback_overlay.dart`
- Implement `CorrectFeedback` — green, shows points earned
- Implement `WrongFeedback` — red, "Try again" message
- Implement `RevealFeedback` — orange, shows correct answer
- Add "Next" button callback

**Acceptance criteria:** [K] All three feedback variants render correctly with appropriate styling

---

### T-15: HomeView Screen

| Field | Value |
|-------|-------|
| **Phase** | 3 — UI |
| **Depends on** | T-09, T-13 |
| **Concurrent with** | T-16, T-17 |
| **Estimated effort** | 0.5 day |

**Description:**
Implement the home/landing screen.

**Tasks:**
- Create `lib/presentation/views/home_view.dart`
- Display current score from ViewModel
- Add "Play" button → navigate to `GameView`
- Add brief instructions text

**Acceptance criteria:** [K] Home screen displays score, navigates to game on button press

---

### T-16: GameView Screen

| Field | Value |
|-------|-------|
| **Phase** | 3 — UI |
| **Depends on** | T-09, T-11, T-12, T-14 |
| **Concurrent with** | T-15, T-17 |
| **Estimated effort** | 1 day |

**Description:**
Implement the main game screen.

**Tasks:**
- Create `lib/presentation/views/game_view.dart`
- Compose `ScoreBar`, `FlagImage`, `OptionsGrid`, `FeedbackOverlay`
- Use `Consumer<GameViewModel>` for reactive updates
- Handle answer submission → feedback → next round flow
- Navigate to `ResultView` on game complete

**Acceptance criteria:** [K] Full game loop works: flag display → answer → feedback → next

---

### T-17: ResultView Screen

| Field | Value |
|-------|-------|
| **Phase** | 3 — UI |
| **Depends on** | T-09, T-14 |
| **Concurrent with** | T-15, T-16 |
| **Estimated effort** | 0.5 day |

**Description:**
Implement the game-complete/reset screen.

**Tasks:**
- Create `lib/presentation/views/result_view.dart`
- Display final score
- Show "Game Complete" message
- Add "Play Again" button → calls `resetGame()` and navigates to `GameView`

**Acceptance criteria:** [K] Result screen shows final score, reset button restarts game

---

### T-18: Provider Wiring in main.dart

| Field | Value |
|-------|-------|
| **Phase** | 3 — UI |
| **Depends on** | T-06, T-09, T-15, T-16, T-17 |
| **Concurrent with** | — |
| **Estimated effort** | 0.5 day |

**Description:**
Wire up all providers and navigation in the app entry point.

**Tasks:**
- Update `lib/main.dart` with `MultiProvider` setup
- Register `CountryRepository` as `Provider`
- Register `GameViewModel` as `ChangeNotifierProvider`
- Set up `MaterialApp` with routes for `HomeView`, `GameView`, `ResultView`
- Initialize ViewModel on startup

**Acceptance criteria:** [K] App launches, providers resolve correctly, navigation works

---

### T-19: Loading States & Error Handling

| Field | Value |
|-------|-------|
| **Phase** | 4 — Polish |
| **Depends on** | T-18 |
| **Concurrent with** | T-20, T-21 |
| **Estimated effort** | 0.5 day |

**Description:**
Add loading indicators and error handling throughout the app.

**Tasks:**
- Add `isLoading` state to ViewModel (if not already present)
- Show loading spinner during API fetch
- Add error state with retry button for failed API calls
- Add `try/catch` around all async operations
- Show user-friendly error messages via `SnackBar`

**Acceptance criteria:** [K] Loading states visible during data fetch, errors show retry option

---

### T-20: Persistence Verification & Full Game Loop Test

| Field | Value |
|-------|-------|
| **Phase** | 4 — Polish |
| **Depends on** | T-18 |
| **Concurrent with** | T-19, T-21 |
| **Estimated effort** | 0.5 day |

**Description:**
Verify persistence and full game loop work correctly.

**Tasks:**
- Test: play a round → kill app → relaunch → score and solved flags persist
- Test: solve all countries → verify game-complete screen appears
- Test: reset → verify solved flags cleared, score preserved
- Test: flag images load from cache on second app launch
- Document any persistence bugs found

**Acceptance criteria:** [K] All persistence scenarios pass, full game loop works end-to-end

---

### T-21: Widget Tests for Critical User Flows

| Field | Value |
|-------|-------|
| **Phase** | 4 — Polish |
| **Depends on** | T-18 |
| **Concurrent with** | T-19, T-20 |
| **Estimated effort** | 1 day |

**Description:**
Write widget tests for key user interactions.

**Tasks:**
- Create `test/widget/game_view_test.dart`
- Test: tapping correct answer shows correct feedback
- Test: tapping wrong answer shows wrong feedback
- Test: three wrong answers reveal correct answer
- Test: "Next" button advances to next flag
- Test: navigation from Home → Game → Result

**Acceptance criteria:** [K] All widget tests pass, critical flows verified

---

### T-22: Integration Test — Full Game Flow

| Field | Value |
|-------|-------|
| **Phase** | 5 — QA |
| **Depends on** | T-19, T-20, T-21 |
| **Concurrent with** | — |
| **Estimated effort** | 1 day |

**Description:**
Write end-to-end integration tests.

**Tasks:**
- Create `integration_test/app_test.dart`
- Test: complete game flow from launch to game-complete
- Test: persistence across app restart (integration level)
- Test: score accumulation across multiple rounds
- Test: reset flow

**Acceptance criteria:** [K] Integration tests pass on emulator/device

---

### T-23: Edge Case Handling & Final QA

| Field | Value |
|-------|-------|
| **Phase** | 5 — QA |
| **Depends on** | T-22 |
| **Concurrent with** | — |
| **Estimated effort** | 1 day |

**Description:**
Handle edge cases and perform final quality assurance.

**Tasks:**
- Handle: empty API response
- Handle: network failure during gameplay
- Handle: < 4 unsolved countries remaining
- Handle: duplicate country names in options
- Handle: app killed mid-round
- Run `flutter test --coverage` → verify final coverage report
- Run `flutter analyze` → fix all warnings
- Manual testing on physical device (if available)

**Acceptance criteria:** [K] All edge cases handled gracefully, coverage ≥ 80% on data + ViewModel, no analyzer warnings

---

## Concurrency Summary

The following ticket groups can be executed in parallel by different developers/agents:

| Parallel Group | Tickets | Rationale |
|----------------|---------|-----------|
| **Group A** | T-01, T-02 | Both are independent setup tasks |
| **Group B** | T-03, T-04, T-05 | All depend only on T-02, no interdependencies |
| **Group C** | T-11, T-12, T-13, T-14 | All depend only on T-03/T-08, no interdependencies |
| **Group D** | T-15, T-16, T-17 | All depend on T-09 + widgets, no interdependencies |
| **Group E** | T-19, T-20, T-21 | All depend only on T-18, no interdependencies |

---

## Critical Path

The longest dependency chain that determines minimum project duration:

```
T-01/T-02 → T-03/T-04/T-05 → T-06 → T-07 → T-09 → T-10 → T-16 → T-18 → T-19/T-20/T-21 → T-22 → T-23
```

**Minimum estimated duration:** ~9-10 days (with parallel execution)
**Sequential duration:** ~14 days (no parallelism)
