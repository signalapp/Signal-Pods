# Signal's fork of [libPhoneNumber-iOS][]

This is Signal's fork of libPhoneNumber-iOS, which is an Objective-C port of [Google's libphonenumber][libphonenumber].

## How to update metadata from libphonenumber

If you want the latest metadata from libphonenumber...

1. Clone this fork.
1. Determine the version of libphonenumber (not libPhoneNumber-iOS) that you want to pull metadata from. For example, v1.2.3. You may wish to visit [the libphonenumber repo][libphonenumber].
1. From the project root, run `LIBPHONENUMBER_REF=v1.2.3 make update_metadata`, replacing the variable with whatever version you want. This script fetches metadata from the libphonenumber repo and updates a few files in this one. Most notably, it changes `libPhoneNumber/NBPhoneNumberMetaData.plist`.
1. Commit the changes to the `signal-master` and push the changes.

From there, you can update the dependency in the [Signal iOS project][signal-ios] as normal, likely using `bundle exec pod update libPhoneNumber-iOS`.

[libPhoneNumber-iOS]: https://github.com/iziz/libPhoneNumber-iOS
[libphonenumber]: https://github.com/google/libphonenumber
[signal-ios]: https://github.com/signalapp/Signal-iOS
