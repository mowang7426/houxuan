# KBGlow v1.0.4

RootHide/Theos jailbreak tweak for keyboard key glow effects.

## v1.0.4 fixes
- Removed nested KBGlowPrefs/Makefile that caused RootHide `Root.plist: No such file or directory` staging failure.
- Animation selection uses PSSwitchCell instead of buttonAction.
- Color selection uses PSSwitchCell and cross-process Darwin notification.
- Keyboard input is detected from UIWindow sendEvent, covering internal keyboard key view classes.
- Preference icon is supplied at 24x24 and 48x48.


### WeType / 微信输入法

The RootHide filter explicitly includes `com.tencent.wetype` and `com.tencent.wetype.keyboard`. The keyboard extension is the process that needs the tweak injected for keyboard visual effects.
