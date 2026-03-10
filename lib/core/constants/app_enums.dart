enum RecommendationAction {
  buy,
  watch,
  avoid,
}

enum RiskMode {
  conservative,
  balanced,
  aggressive,
}

enum MarketMode {
  bullish,
  sideways,
  neutral,
  volatile,
  bearish,
  weakLiquidity,
}

enum SignalStatus {
  active,
  tp1Hit,
  tp2Hit,
  stopLossHit,
  expired,
  cancelled,
}

enum FinalOutcome {
  fullWin,
  partialWin,
  loss,
  expired,
  cancelled,
}
