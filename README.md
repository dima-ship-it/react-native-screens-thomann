# This is a Fork for Thomann
In order to fix a problem with Accessibility / VoiceOver, this project was forked and patched. 

## Bug we are fixing
The problem that we are fixing is that dialogues or snackbars appeared behind Modals after switching to native-navigation. After a fix for that, VoiceOver became broken for the whole app. 

The reason for that is that we had to introduce FullScreenOverlay from react-native-screens which is shown on every screen (due to the fact that bottom sheets / snackbars are used on almost every screen)

### How we fix it
- We add a new prop called `accessibilityEnabled`
- The prop is set to TRUE by default. This is required because if you set it to FALSE, RN will not call it. You need to send the value as FALSE from RN side. 
- We use the prop in FullScreenOverlay to enable or disable the accessibility
- Core idea: 
    - When no full screen overlay is necessary, `accessibilityEnabled` is false. This tells the OS to ignore it (it's not visible anyway). 
    - When full screen overlay is necessary (e.g. when you show a dialogue) then `accessibilityEnabled` is true. 
    
## Contribution and Integration
- If you need to contribute or make changes: 
    - Clone the library on your machine
    - Make the changes
    - Increase the version in package.json 
    - Run `yarn prepare-locally`
    - Commit *all* the changes & push them (important: `yarn prepare-locally` will generate/modify `lib` folder --> you NEED to push it too)
    - Create a tag that matches the version in package.json, e.g. `git tag 4.11.1-thomann.4`
    - Push a tag `git push origin 4.11.1-thomann.4`
    - Finally you can integrate the new version into the app (see below)
- You can integrate the library like this:  
`"react-native-screens": "git+https://github.com/dima-ship-it/react-native-screens-thomann.git#4.11.1-thomann.4"`
^the last parameter is the new tag that you created. 
- Run `yarn purge` and you should be good to go! 🚀

<img src="https://user-images.githubusercontent.com/16062886/117443651-c13d9500-af38-11eb-888d-b6a0b580760c.png" width="100%" alt="React Native Screens by Software Mansion" >

This project aims to expose native navigation container components to React Native. It is not designed to be used as a standalone library but rather as a dependency of a [full-featured navigation library](https://github.com/react-navigation/react-navigation).

## Fabric

To learn about how to use `react-native-screens` with Fabric architecture, head over to [Fabric README](README-Fabric.md). Instructions on how to run Fabric Example within this repo can be found in the [FabricExample README](FabricExample/README.md).

## Supported platforms

- [x] iOS
- [x] Android
- [x] tvOS
- [x] visionOS
- [x] Windows
- [x] Web

## Installation

### iOS

Installation on iOS is completely handled with auto-linking, if you have ensured pods are installed after adding this module, no other actions are necessary.

### Android

On Android the View state is not persisted consistently across Activity restarts, which can lead to crashes in those cases. It is recommended to override the native Android method called on Activity restarts in your main Activity, to avoid these crashes.

For most people using an app built from the react-native template, that means editing `MainActivity.java`, likely located in `android/app/src/main/java/<your package name>/MainActivity.java`

You should add this code, which specifically discards any Activity state persisted during the Activity restart process, to avoid inconsistencies that lead to crashes.
Please note that the override code should not be placed inside `MainActivityDelegate`, but rather directly in `MainActivity`.

<details open>
<summary>Java</summary>

```java
import android.os.Bundle;

public class MainActivity extends ReactActivity {

    //...code

    //react-native-screens override
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(null);
    }

    public static class MainActivityDelegate extends ReactActivityDelegate {
        //...code
    }
}
```

</details>

<details>
<summary>Kotlin</summary>

```kotlin
import android.os.Bundle;

class MainActivity: ReactActivity() {

    //...code

    //react-native-screens override
    override fun onCreate(savedInstanceState: Bundle?) {
      super.onCreate(null);
    }
}
```

</details>

For people that must handle cases like this, there is [a more detailed discussion of the difficulties in a series of related comments](https://github.com/software-mansion/react-native-screens/issues/17#issuecomment-424704633).

<details>
<summary>Need to use a custom Kotlin version?</summary>
<br>

Since `v3.6.0` `react-native-screens` has been rewritten with Kotlin. Kotlin version used in this library defaults to `1.4.10`.

If you need to use a different Kotlin version, set `kotlinVersion` ext property in your project's `android/build.gradle` and the library will use this version accordingly:

```
buildscript {
    ext {
        ...
        kotlinVersion = "1.4.10"
    }
}
```

**Disclaimer**: `react-native-screens` requires Kotlin `1.3.50` or higher.

</details>

### Windows

Installation on Windows should be completely handled with auto-linking when using React Native Windows 0.63+. For earlier versions, you must [manually link](https://microsoft.github.io/react-native-windows/docs/native-modules-using) the native module.

## How can I take advantage of that?

Screens are already integrated with the React Native's most popular navigation library [react-navigation](https://github.com/react-navigation/react-navigation) and [Expo](https://expo.io).

## Supported react-native version

Below we present tables with mapping of the library version to the last supported react-native version. These tables are for the `4.x` line of the library. For compat tables 
of `3.x` line please see [readme on the `3.x` branch](https://github.com/software-mansion/react-native-screens/tree/3.x?tab=readme-ov-file#supported-react-native-version).

### Support for Paper

Paper is the default rendering system for React Native versions prior to 0.76.

| library version | react-native version |
| --------------- | -------------------- |
| 4.9.0+          | 0.76.0+              |
| 4.5.0+          | 0.74.0+              |
| 4.0.0+          | 0.72.0+              |

### Support for Fabric

[Fabric](https://reactnative.dev/architecture/fabric-renderer) is React Native's new rendering system.

Here's a table with summary of supported `react-native` versions when Fabric is turned on.

| library version | react-native version |
| --------------- | -------------------- |
| 4.5.0+          | 0.77.0+              |
| 4.0.0+          | 0.76.0+              |

## Usage with [react-navigation](https://github.com/react-navigation/react-navigation)

> [!CAUTION]
> JS API of the native stack has been moved from `react-native-screens/native-stack` to `@react-navigation/native-stack` since version v6. Currently, native stack v5 (imported from `react-native-screens/native-stack`) is deprecated and will be removed in the upcoming **minor** release. `react-native-screens` v4 will support only `@react-navigation/native-stack` v7.

Screens support is built into [react-navigation](https://github.com/react-navigation/react-navigation) starting from version [2.14.0](https://github.com/react-navigation/react-navigation/releases/tag/2.14.0) for all the different navigator types (stack, tab, drawer, etc).

To configure react-navigation to use screens instead of plain RN Views for rendering screen views, simply add this library as a dependency to your project:

```bash
# bare React Native project
yarn add react-native-screens

# if you use Expo managed workflow
npx expo install react-native-screens
```

Just make sure that the version of [react-navigation](https://github.com/react-navigation/react-navigation) you are using is 2.14.0 or higher.

You are all set 🎉 – when screens are enabled in your application code react-navigation will automatically use them instead of relying on plain React Native Views.

### Experimental support for `react-freeze`

> You have to use React Native 0.68 or higher, react-navigation 5.x or 6.x and react-native-screens >= v3.9.0

Since `v3.9.0`, `react-native-screens` comes with experimental support for [`react-freeze`](https://github.com/software-mansion-labs/react-freeze). It uses the React `Suspense` mechanism to prevent parts of the React component tree from rendering, while keeping its state untouched.

To benefit from this feature, enable it in your entry file (e.g. `App.js`) with this snippet:

```js
import { enableFreeze } from 'react-native-screens';

enableFreeze(true);
```

Want to know more? Check out [react-freeze README](https://github.com/software-mansion-labs/react-freeze#readme)

Found a bug? File an issue [here](https://github.com/software-mansion/react-native-screens/issues) or directly in [react-freeze repository](https://github.com/software-mansion-labs/react-freeze/issues).

### Disabling `react-native-screens`

If, for whatever reason, you'd like to disable native screens support and use plain React Native Views add the following code in your entry file (e.g. `App.js`):

```js
import { enableScreens } from 'react-native-screens';

enableScreens(false);
```

You can also disable the usage of native screens per navigator with [`detachInactiveScreens`](https://reactnavigation.org/docs/stack-navigator#detachinactivescreens).

### Using `createNativeStackNavigator` with React Navigation

To take advantage of the native stack navigator primitive for React Navigation that leverages `UINavigationController` on iOS and `Fragment` on Android, please refer:

- for React Navigation >= v6 to the [Native Stack Navigator part of React Navigation documentation](https://reactnavigation.org/docs/native-stack-navigator)

## `FullWindowOverlay`

Native `iOS` component for rendering views straight under the `Window`. Based on `RCTPerfMonitor`. You should treat it as a wrapper, providing full-screen, transparent view which receives no props and should ideally render one child `View`, being the root of its view hierarchy. For the example usage, see https://github.com/software-mansion/react-native-screens/blob/main/apps/src/tests/Test1096.tsx

## Interop with [react-native-navigation](https://github.com/wix/react-native-navigation)

React-native-navigation library already uses native containers for rendering navigation scenes so wrapping these scenes with `<ScreenContainer>` or `<Screen>` component does not provide any benefits. Yet if you would like to build a component that uses screens primitives under the hood (for example a view pager component) it is safe to use `<ScreenContainer>` and `<Screen>` components for that as these work out of the box when rendered on react-native-navigation scenes.

## Interop with other libraries

This library should work out of the box with all existing react-native libraries. If you experience problems with interoperability please [report an issue](https://github.com/software-mansion/react-native-screens/issues).

## Guide for navigation library authors

If you are building a navigation library you may want to use `react-native-screens` to have control over which parts of the React component tree are attached to the native view hierarchy.
To do that, `react-native-screens` provides you with the components documented [here](https://github.com/software-mansion/react-native-screens/tree/main/guides/GUIDE_FOR_LIBRARY_AUTHORS.md).

## Common problems

### Problems with header on iOS

- [Focused search bar causes new screens to have incorrect header](https://github.com/software-mansion/react-native-screens/issues/996)
- [Scrollable content gets cut off by the header with a search bar](https://github.com/software-mansion/react-native-screens/issues/1120)
- [RefreshControl does not work properly with NativeStackNavigator and largeTitle](https://github.com/software-mansion/react-native-screens/issues/395)

#### Solution

Use `ScrollView` with prop `contentInsetAdjustmentBehavior=“automatic”` as a main container of the screen and set `headerTranslucent: true` in screen options.

### Other problems

| Problem                                                                                                                                                  | Solution                                                                                                    |
| -------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------- |
| [SVG component becomes transparent when goBack](https://github.com/software-mansion/react-native-screens/issues/773)                                     | [related PRs](https://github.com/software-mansion/react-native-screens/issues/773#issuecomment-783469792)   |
| [Memory leak while moving from one screen to another in the same stack](https://github.com/software-mansion/react-native-screens/issues/843)             | [explanation](https://github.com/software-mansion/react-native-screens/issues/843#issuecomment-832034119)   |
| [LargeHeader stays small after pop/goBack/swipe gesture on iOS 14+](https://github.com/software-mansion/react-native-screens/issues/649)                 | [potential fix](https://github.com/software-mansion/react-native-screens/issues/649#issuecomment-712199895) |
| [`onScroll` and `onMomentumScrollEnd` of previous screen triggered in bottom tabs](https://github.com/software-mansion/react-native-screens/issues/1183) | [explanation](https://github.com/software-mansion/react-native-screens/issues/1183#issuecomment-949313111)  |

## Contributing

There are many ways to contribute to this project. See [CONTRIBUTING](https://github.com/software-mansion/react-native-screens/tree/main/guides/CONTRIBUTING.md) guide for more information. Thank you for your interest in contributing!

## License

React native screens library is licensed under [The MIT License](LICENSE).

## Credits

This project has been build and is maintained thanks to the support from [Shopify](https://shopify.com), [Expo.io](https://expo.io), and [Software Mansion](https://swmansion.com).

[![shopify](https://avatars1.githubusercontent.com/u/8085?v=3&s=100 'Shopify.com')](https://shopify.com)
[![expo](https://avatars2.githubusercontent.com/u/12504344?v=3&s=100 'Expo.io')](https://expo.io)
[![swm](https://logo.swmansion.com/logo?color=white&variant=desktop&width=150&tag=react-native-reanimated-github 'Software Mansion')](https://swmansion.com)

## React Native Screens is created by Software Mansion

Since 2012 [Software Mansion](https://swmansion.com) is a software agency with experience in building web and mobile apps. We are Core React Native Contributors and experts in dealing with all kinds of React Native issues. We can help you build your next dream product – [Hire us](https://swmansion.com/contact/projects?utm_source=screens&utm_medium=readme).
