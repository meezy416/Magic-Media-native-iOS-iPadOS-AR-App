# Magic Media

Magic Media is an experimental native iOS/iPadOS application that focuses on augmenting physical forms of media such as magazines, dollar bills, instruction manuals, etc. It delivers its users various options to interact with several sections of the physical media with images/text and then convert them into videos or 3D models specifically. This will help the user understand the information better in various ways of interaction, which is majorly made possible by AR. It also supports voice commands to help the user navigate through the app and have a more friendly and immersive experience.

On a personal note, I strongly believe that Augmented Reality is going to be a key element of the Digital Information Age very soon. This project also aims at delivering an insight into the future of technology and the way we are going to experience the world around us in the coming years. 

**Award**

This project won the Best Project (Audience Choice) Award under the Augmented Reality Projects category at the Festival of Animation - Fall 2020 at The George Washington University, Washington D.C., USA.

## For a quick insight of this project, check out this small video: https://youtu.be/hn3tAm9B468

<p align="center">
  <img src="https://github.com/ivedants/Magic-Media-native-iOS-iPadOS-AR-App/blob/main/Image%2011.gif" />
</p>

**Made Using**

1. Xcode 12
2. Swift 5 
3. ARKit
4. SceneKit
5. RealityKit
6. Apple Speech Framework
7. Supabase (Postgres, Storage, Auth) — powers the community-uploaded triggers described below

## Table of Contents

- [Getting Started](#getting-started)
- [AR Application Design](#AR-application-design)
  - [App triggering AR](#app-triggering-ar)
  - [Combines real and virtual worlds to deliver a wholesome experience](#combines-real-and-virtual-worlds-to-deliver-a-wholesome-experience)
  - [Interactive in real-time](#interactive-in-real-time)
  - [Image registered in 3D](#image-registered-in-3d)
  - [Includes virtual objects and digital content](#includes-virtual-objects-and-digital-content)
  - [Includes narration, music, and sounds as appropriate](#Includes-narration-music-and-sounds-as-appropriate)
  - [Accepts voice commands](#accepts-voice-commands)
- [Integration](#integration)
- [User Experience](#user-experience)
- [Community Triggers (Supabase Backend)](#community-triggers-supabase-backend)
- [Appendix: Lessons Learned (My personal journey throughout this project)](#Appendix-lessons-learned-my-personal-journey-throughout-this-project)
  

## Getting Started

**NOTE:** In order to experience audio within the app, make sure your device is not in silent mode. You can augment any one, ten, or twenty US dollar bill with this app along with some physical media that this version supports. The physical media files that the app supports are in a folder called **“Supported Physical Media”**. Make sure to either access these files on a tablet kept horizontally surface or print them in preferably two pages (side by side) format. For any queries, suggestions, or collaborations regarding this project, please contact me at ivedantshrivastava@gmail.com.

**User Guidelines - Simple instructions about how to install the app and enjoy the AR experience**

This will help you to easily install and enjoy the app on your supported iOS/iPadOS device(s).

**Testing details:**

The app has been tested with iPhone 12 Pro Max and iPad Pro (2020, 4th generation). The minimum supported iOS version is now **iOS 16.0** (raised from 14.1, since the Supabase Swift SDK requires it). The app does not run in the iOS Simulator — it calls `fatalError()` on launch if `ARWorldTrackingConfiguration.isSupported` is false, which is always the case on Simulator (no camera). A real ARKit-capable device is required.

**Installing the app:**

1. Open Xcode on your app and connect your iPhone or iPad to your Mac using cable.
2. Open the “Magic Media.xcodeproj” file from the project folder on your Mac using Xcode.
3. Copy `MagicKettle/Secrets.example.plist` to `MagicKettle/Secrets.plist` (git-ignored) and fill in your own Supabase project's URL and anon key — see [Community Triggers](#community-triggers-supabase-backend) below for how to set that project up. The app won't launch without this file.
4. If Xcode hasn't already resolved the Supabase Swift package, go to File → Add Package Dependencies and add `https://github.com/supabase/supabase-swift` if it isn't listed under the project's Package Dependencies.
5. Once the Xcode file is open, select your iPhone/iPad among the available set of devices among target devices menu in the top panel.

![alt text](https://github.com/ivedants/MagicMedia/blob/main/Image%201.png)

6. In the Project Navigator panel, go to “Signing and Capabilities” tab and select “Team”. If you don’t have an existing team, press “Add an account...” and login using your Apple ID and password. If you're using your own bundle identifier, make sure "Sign In with Apple" is enabled as a capability here and on the matching App ID in your Apple Developer account (Certificates, IDs & Profiles → Identifiers) — required for the community upload feature's sign-in.

![alt text](https://github.com/ivedants/MagicMedia/blob/main/Image%202.png)

7. Now, you can press the “Build” button on the top left corner for building the app on your iPhone or iPad. Make sure the device is unlocked while the app is being built.
8. If the app doesn’t open and give a permissions error on your device, then head over to Settings -> Your name (at the very top of the screen) -> Scroll down to a button that says “Developer” and then give permission for the app to run on your iPhone/iPad.
9. This should get the app working on your iPhone/iPad and now, you’re all set to enjoy its features.

## AR Application Design

### App triggering AR: 

The app triggers the AR based on markers through image tracking on vertical and horizontal surfaces. The various images/text on the target physical media will be marked and converted into AR objects or interactive videos once the user points the device camera towards them.

<p align="center">
  <img src="https://github.com/ivedants/MagicMedia/blob/main/Image%204.gif" />
</p>

### Combines real and virtual worlds to deliver a wholesome experience:

Besides getting the real experience from the digital or hard copy of the target physical media, the users will also be able to learn more about specific topics and sections through videos or 3D models triggered by AR.

<p align="center">
  <img src="https://github.com/ivedants/MagicMedia/blob/main/Image%205.gif" />
</p>

### Interactive in real-time:

The AR elements of the app are interactive in real-time. The user can also pause/play the video triggered by the AR at their ease.

<p align="center">
  <img src="https://github.com/ivedants/MagicMedia/blob/main/Image%206.gif" />
</p>

### Image registered in 3D:

The app recognizes certain images on the target physical media and register them in 3D in order to build an AR element for them and enhance the user’s overall interactive experience.

<p align="center">
  <img src="https://github.com/ivedants/MagicMedia/blob/main/Image%207.gif" />
</p>

### Includes virtual objects and digital content: 

The app triggers virtual objects for certain section like advertisements for personal care products, furniture, food recipes, etc. as 3D objects and digital content such as videos for some trending interviews, book recommendations, product/service reviews, advertisements, etc. For any one, ten, or twenty dollar bill, the app triggers virtual objects for the front side of the bill, thus revealing more about the
person featured on the target dollar bill and video for the back side of the bill, thus sharing more information about the dollar bill. Besides this, the app also triggers instructional videos on top of images featured on instruction manuals.

<p align="center">
  <img src="https://github.com/ivedants/MagicMedia/blob/main/Image%208.gif" />
</p>

### Includes narration, music, and sounds as appropriate: 

The app includes narration, music, and sounds in various AR elements that require it as explained above. In order to have a quick preview, check out the preview video of this project at: https://youtu.be/hn3tAm9B468

### Accepts voice commands: 

The app includes appropriate voice commands such as what it can do, where would the user find something specific that they might be looking for, etc.

<p align="center">
  <img src="https://github.com/ivedants/MagicMedia/blob/main/Image%209.gif" />
</p>

## Integration

Magic Media is a native iOS/iPadOS app made using Apple ARKit, RealityKit, SceneKit, and Speech Framework. It is developed using Swift 5 programming language in Xcode 12 IDE.

### The Build process:

First, all the assets were gathered and put in Xcode which included all the sounds, 3D models, videos, and images used for this app. After setting up the development environment and target devices, the libraries were imported. There are various functions that have been created to play sounds, render models or videos in scenes nodes or video nodes respectively on top of planes created for tracked images that are registered in 3D. The Speech Framework has been used to add Speech Recognition to the app so that it can use the device microphone to listen for voice input from the user. Then the recognized speech text is analyzed to check for voice commands and the identified commands are then executed.

## User Experience

In order to give users a very user-friendly and immersive experience, the app always **implements a quick AR coaching session** for the users to learn about detecting vertical and horizontal surfaces for the app to track the images in the physical environment. The app **also takes user privacy into account** by asking the users for permission to access their camera to detect the images and microphone for the voice commands. **Since the current version of the app works with a limited set of physical media, it also supports any one, ten, and twenty US dollar bill. This helps in adding more creativity and complexity.** The front side of the bill renders a 3D model with a famous quote of the person featured on that dollar bill whereas the back side of the bill plays a video on top of it, informing more about the making of that dollar bill. The virtual objects and digital content help enhance the whole reading and interacting experience for the users. On top of this, the users can make use of voice commands to get the most out of the app by saying specific phrases to activate those commands, which also help them navigate throughout their experience.

## Community Triggers (Supabase Backend)

The app's original AR triggers (the dollar bills, instruction manuals, etc. described above) are bundled with the app itself — adding a new one means shipping a new binary. On top of that, the app also supports **community-uploaded triggers**: a signed-in user can upload their own target photo plus a video or audio clip, and once approved it becomes trackable by anyone using the app, without an app update.

**How it works:**

- **Auth**: Sign in with Apple, via Supabase Auth's Apple provider (`ViewController.swift`'s `signInTapped()`).
- **Upload**: `UploadViewController.swift` lets a signed-in user pick a target image and a video/audio file, and uploads both to private Supabase Storage buckets (`trigger-targets`, `trigger-content`), then inserts a row into the `triggers` table with `status = 'pending'`.
- **Moderation**: pending triggers are invisible to everyone except their uploader until manually flipped to `status = 'approved'` in Supabase Studio's table editor. This keeps the app compliant with App Store Guideline 1.2 (user-generated content needs a moderation path) without a dedicated admin app.
- **Fetching**: on launch, `TriggerService.swift` fetches all `approved` triggers, downloads their target image and content via short-lived signed URLs, and builds `ARReferenceImage`s from them at runtime (`ARReferenceImage(cgImage:orientation:physicalWidth:)`) — these are merged into the same `ARImageTrackingConfiguration` as the bundled images in `ViewController.swift`'s `loadCommunityTriggers()`.
- **Reporting**: `ReportContentHelper.swift` lets any signed-in user flag an actively-tracked community trigger, which inserts a row into the `reports` table for review.

**Setting up your own backend:**

1. Create a Supabase project (or reuse an existing one — the schema lives entirely in its own tables/buckets and won't collide with anything else in the same project).
2. Apply the migration at `supabase/migrations/0001_magic_media_triggers.sql` — it creates the `triggers` and `reports` tables with Row Level Security policies, and the two private Storage buckets.
3. In Supabase Studio → Authentication → Providers → Apple, enable the provider using a Sign In with Apple key from your Apple Developer account (Team ID, Key ID, and the key's `.p8` contents), and set the Client ID to your app's bundle identifier.
4. Copy `MagicKettle/Secrets.example.plist` to `MagicKettle/Secrets.plist` and fill in your project's URL and anon key (Project Settings → API in Supabase Studio).
5. To approve an upload, find its row in the `triggers` table in Supabase Studio and change `status` from `pending` to `approved`.

## Appendix: Lessons Learned (My personal journey throughout this project)

The first and foremost lesson to be learned while making a native iOS application for AR is that it does require a prerequisite of having a strong background in object-oriented programming or programming with Swift. There are many elements that come into play together when an application like Magic Media is made. First, there are the new ARKit and RealityKit SDKs that have to be studied thoroughly in order to understand the possibilities and limitations of AR within the Apple Development Ecosystem.

It took some efforts to be able to find the appropriate 3D Models to be used within the app. These 3D models are rendered on top of plane nodes generated over the tracked images that trigger them. 

The most challenging part of this project has been the implementation of voice commands. In order to implement them, the basic requirement is to recognize speech, which can be done using Speech Framework. Although I followed the tutorials available online for Speech Framework and Speech Recognition, I faced a major issue initially which was a “SIGABRT” error that always led to an app crash every time the app would try to listen for speech. This was eventually solved by trying another implementation method through the Apple documentation on Speech Framework and Speech Recognition.

Another lesson that I learned while making this app is that the voice commands could not place or render any 3D object or video on its own since they can only be rendered using tracked images, as the app can use only one type of anchor for its renderer function and image anchor is the only anchor that I could use here. I hope there is a way to include multiple type of anchors within the same application in the future so that the possibilities are more.

# Author

Vedant Shrivastava (GitHub: https://github.com/ivedants ; Email: ivedantshrivastava@gmail.com)
