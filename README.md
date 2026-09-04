# Gradient Candidates

iOS 17.0 / Rootless jailbreak / Theos

This first prototype targets the stock Simplified Chinese keyboard by identifying
short UILabel instances inside keyboard/input-set view hierarchies and painting
their text with a blue-to-purple linear gradient.

## Build

Install Theos and an iPhoneOS SDK, then:

    make clean
    make package FINALPACKAGE=1

The resulting Debian package will be under `./packages/`.

The Makefile uses Theos' `rootless` package scheme, which places the package
contents under `/var/jb` and uses the rootless install architecture.

## Important

This is a prototype heuristic rather than a claim that Apple's iOS 17 private
keyboard hierarchy is stable. If it colors extra keyboard labels or misses the
candidate labels on a particular 17.0 build, the class/frame filter in
`Tweak.xm` should be tightened after inspecting that device's view hierarchy.

The two gradient colors are currently hard-coded in `Tweak.xm`:
blue -> purple.
