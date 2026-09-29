/// Calculates points earned based on the attempt number.
///
/// - 1st attempt (index 0): 10 points
/// - 2nd attempt (index 1): 8 points
/// - 3rd attempt (index 2): 5 points
/// - Failed all 3 attempts: 0 points
class ScoreCalculator {
  ScoreCalculator._();

  /// Returns the points awarded for a given attempt number.
  ///
  /// [attemptNumber] is 1-based (1, 2, or 3).
  /// Returns 0 for any attempt number outside 1-3.
  static int getPointsForAttempt(int attemptNumber) {
    switch (attemptNumber) {
      case 1:
        return 10;
      case 2:
        return 8;
      case 3:
        return 5;
      default:
        return 0;
    }
  }

  /// Maximum number of attempts allowed per flag.
  static const int maxAttempts = 3;
}
