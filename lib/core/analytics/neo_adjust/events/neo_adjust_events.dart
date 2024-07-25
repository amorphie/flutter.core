enum NeoAdjustEvent {
  loginBurganDev("iny5ey"),
  successfulLoginBurganDev("er87u8"),
  loginBurganProd("2ew684"),
  successfulLoginBurganProd("mnzzjk"),
  loginBurganPrep("iny5ey"),
  successfulLoginBurganPrep("er87u8"),
  loginOnDev("ms55wo"),
  successfulLoginOnDev("afflvo"),
  loginOnProd("mw31tx"),
  successfulLoginOnProd("acoffg"),
  loginOnPrep("7w6p70"),
  successfulLoginOnPrep("be2cqy");

  static NeoAdjustEvent? getAdjustEventFromString(String eventName) {
    switch (eventName) {
      case "loginBurganDev":
        return NeoAdjustEvent.loginBurganDev;
      case "successfulLoginBurganDev":
        return NeoAdjustEvent.successfulLoginBurganDev;
      case "loginBurganProd":
        return NeoAdjustEvent.loginBurganProd;
      case "successfulLoginBurganProd":
        return NeoAdjustEvent.successfulLoginBurganProd;
      case "loginBurganPrep":
        return NeoAdjustEvent.loginBurganPrep;
      case "successfulLoginBurganPrep":
        return NeoAdjustEvent.successfulLoginBurganPrep;
      case "loginOnDev":
        return NeoAdjustEvent.loginOnDev;
      case "successfulLoginOnDev":
        return NeoAdjustEvent.successfulLoginOnDev;
      case "loginOnProd":
        return NeoAdjustEvent.loginOnProd;
      case "successfulLoginOnProd":
        return NeoAdjustEvent.successfulLoginOnProd;
      case "loginOnPrep":
        return NeoAdjustEvent.loginOnPrep;
      case "successfulLoginOnPrep":
        return NeoAdjustEvent.successfulLoginOnPrep;
    }
    return null;
  }

  const NeoAdjustEvent(this.id);
  final String id;
}
