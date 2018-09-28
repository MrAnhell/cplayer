# cplayer

A player for ApolloTV, written in Dart for the Flutter framework.

## Getting Started

### iOS

Add the following to `Info.plist` in `/ios/Runner/`:

```xml
<key>NSAppTransportSecurity</key>
<dict>
  <key>NSAllowsArbitraryLoads</key>
  <true/>
</dict>
```

### Android

Add the following to `AndroidManifest.xml` if it's not already present.

```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.WAKE_LOCK" />
```