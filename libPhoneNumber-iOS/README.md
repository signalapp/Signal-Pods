# Signal's fork of [libPhoneNumber-iOS][]

This is Signal's fork of libPhoneNumber-iOS, which is an Objective-C port of [Google's libphonenumber][libphonenumber].

## How to update metadata from libphonenumber

If you want the latest metadata from libphonenumber...

1. Clone this fork.
1. Check out the version of [libphonenumber][] (not libPhoneNumber-iOS) that you want to pull metadata from. Remember this `<path>`.
1. From the project root, run `LIBPHONENUMBER=<path> make metadata`. Use the `<path>` you remembered in the prior step.
1. Commit the changes to the `signal-master` branch and push the changes.
1. Update the dependency in the [Signal iOS project][signal-ios] as normal (using `bundle exec pod update libPhoneNumber-iOS`).

[libPhoneNumber-iOS]: https://github.com/iziz/libPhoneNumber-iOS
[libphonenumber]: https://github.com/google/libphonenumber
[signal-ios]: https://github.com/signalapp/Signal-iOS
