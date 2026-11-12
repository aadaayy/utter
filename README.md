# Utter

A voice keyboard for iPhone. Tap the mic, talk, and Utter types what you say
into any app, cleaned up: no "um" or "uh", repeated words dropped, and
punctuation and capitals added. Everything happens on the phone. Nothing you
say leaves it.

- English and Spanish, switched with one tap on the keyboard.
- Once you start, it keeps listening while you talk and stops after one
  minute of quiet. It counts down the last 15 seconds.
- Each sentence is typed as you pause. Tap **Raw words** to swap the last one
  back to exactly what you said.
- Say "new line", "new paragraph" or "scratch that" (or "nueva línea",
  "nuevo párrafo", "borra eso").

It needs iOS 26 or later. Speech to text is Apple's on-device speech engine.
Cleanup uses Apple's on-device language model where Apple Intelligence is on,
and simple built-in rules everywhere else.

## Put it on your iPhone (free Apple ID)

You need a Mac with Xcode 26 or later, and a USB cable.

1. Open `Utter.xcodeproj` in Xcode.
2. Pick the **Utter** project in the sidebar, then for each of the two
   targets, **Utter** and **UtterKeyboard**, open **Signing & Capabilities**
   and choose your Apple ID under **Team** (add it in Xcode > Settings >
   Accounts if it isn't there).
3. If Xcode says the bundle id isn't available, open the project's
   **Build Settings**, find `UTTER_BUNDLE_PREFIX` and change `com.albertoaday`
   to something of your own, like `com.yourname`. The app, keyboard and
   shared folder all follow it.
4. Plug in the iPhone, pick it at the top of Xcode, and press Run.
5. The first time, the iPhone asks you to trust the developer: open
   Settings > General > VPN & Device Management, tap your Apple ID and tap
   **Trust**. On a new iPhone, also turn on Settings > Privacy & Security >
   Developer Mode.

Then, on the iPhone:

1. Open Utter once. Allow the microphone and download the speech model for
   each language you want.
2. Settings > General > Keyboard > Keyboards > Add New Keyboard > **Utter**.
3. Tap **Utter** in that list and turn on **Allow Full Access**. The keyboard
   needs it to hand your words over from the app; nothing goes online.
4. In any app, hold the globe key and pick Utter.

With a free Apple ID, apps you install yourself stop opening after 7 days.
Plug in and press Run again to renew it; your settings stay.

## Why the app opens for a moment

iPhone keyboards aren't allowed to use the microphone. So the mic key opens
Utter, which starts listening and keeps listening in the background while you
go back to your app (swipe back or tap the top-left corner). The keyboard
types each sentence as Utter hears it.

## Checks

Every push runs the cleanup and hand-off logic tests on Linux, then builds
the app and screenshots every screen and keyboard state on each iPhone size,
from the 16e to the 18 Pro Max, plus the iPhone Duo folded and open. The
pictures go to the `screenshots` branch (or `screenshots-<branch>`).

Run the logic tests yourself with `swift test`.
