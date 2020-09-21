# Migrate LocalStorage

This plugin can be used in conjunction with
[cordova-plugin-wkwebview-engine][plugin] or [cordova-ios 6.x][ios6] to persist
LocalStorage data & indexed db when migrating from `UIWebView` to `WKWebView`.
All related files will be copied over automatically during startup so the user
can simply pick up where they left of.

## How to use

Simply add the plugin to your cordova project via the cli:

```sh
cordova plugin add github:AyogoHealth/cordova-plugin-migrate-localstorage
```

## Notes

- LocalStorage or indexed db files are only copied over once and only if no
  LocalStorage or indexed db data exists for `WKWebView` yet. This means that
  if you've run your app with `WKWebView` before this plugin will likely not
  work.  
  To test if data is migrated over correctly:

    1. Delete the app from your emulator or device
    2. Remove the `cordova-plugin-wkwebview-engine` and `cordova-plugin-migrate-localstorage` plugins
    3. Run your app and store some data in LocalStorage
    4. Add both plugins back
    5. Run your app again. Your data should still be there!

- Once the data is copied over, it is not being synced back to `UIWebView` so
  any changes done in `WKWebView` will not persist should you ever move back to
  `UIWebView`. If you have a problem with this, let us know in the issues
  section!

## Background

One of the drawbacks of migrating Cordova apps to `WKWebView` is that
LocalStorage data does not persist between the two. Unfortunately,
[cordova-plugin-wkwebview-engine][plugin] and [cordova-ios 6.x][ios6] do not
offer a solution for this out of the box (see
https://issues.apache.org/jira/browse/CB-11974?jql=project%20%3D%20CB%20AND%20labels%20%3D%20wkwebview-known-issues).

[plugin]: https://github.com/apache/cordova-plugin-wkwebview-engine
[ios6]: https://cordova.apache.org/announcements/2020/06/01/cordova-ios-release-6.0.0.html
