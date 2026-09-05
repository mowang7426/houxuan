# KBGlow v1.0.4

## v1.0.4 settings fixes
- Unified animation/color state and cross-process preference synchronization.
- All switches/sliders now notify the tweak immediately.
- Reset restores explicit defaults instead of relying on implicit reads.
- Fixed glow animation so duration/opacity are actually reflected.
- Kept the existing RootHide injection scope and keyboard glow implementation.


RootHide/Theos jailbreak tweak for keyboard key glow effects.

## v1.0.3 fixes
- Removed nested KBGlowPrefs/Makefile that caused RootHide `Root.plist: No such file or directory` staging failure.
- Animation selection uses PSSwitchCell instead of buttonAction.
- Color selection uses PSSwitchCell and cross-process Darwin notification.
- Keyboard input is detected from UIWindow sendEvent, covering internal keyboard key view classes.
- Preference icon is supplied at 24x24 and 48x48.
