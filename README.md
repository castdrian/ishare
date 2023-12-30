<p align="center">
  <img src="/ishare/Util/Assets.xcassets/AppIcon.appiconset/AppIcon-128.png" alt="ishare logo" width="100">
  <h1 align="center">ishare</h1>
  <p align="center">The definitive screen capture utility for macOS, designed with simplicity and efficiency in mind.</p>
</p>

<p align="center">
  <a href="https://github.com/sponsors/castdrian">
    <img src="https://img.shields.io/badge/sponsor-30363D?style=for-the-badge&logo=GitHub-Sponsors&logoColor=#white" alt="Sponsor">
  </a>
  <a href="https://ko-fi.com/castdrian">
    <img src="https://img.shields.io/badge/Ko--fi-F16061?style=for-the-badge&logo=ko-fi&logoColor=white" alt="Ko-FI">
  </a>
  <a href="https://discord.gg/sX4KYzu5pX">
    <img src="https://img.shields.io/badge/Discord-5865F2?style=for-the-badge&logo=discord&logoColor=white" alt="Discord">
  </a>
  <a href="https://github.com/castdrian/ishare">
    <img src="https://img.shields.io/badge/GitHub-100000?style=for-the-badge&logo=github&logoColor=white" alt="GitHub">
  </a>
</p>

<p align="center">
  <a href="https://github.com/castdrian/ishare/actions?query=workflow:'Build+and+Release+App'">
    <img src="https://github.com/castdrian/ishare/workflows/Build%20and%20Release%20App/badge.svg" alt="Build and Release App">
  </a>
  <a href="https://github.com/castdrian/ishare/releases/">
    <img src="https://img.shields.io/github/release/castdrian/ishare?include_prereleases=&sort=semver&color=blue" alt="GitHub release">
  </a>
  <a href="#license">
    <img src="https://img.shields.io/badge/License-GPL--3.0-blue" alt="License">
  </a>
  <a href="https://github.com/castdrian/ishare/issues">
    <img src="https://img.shields.io/github/issues/castdrian/ishare" alt="issues">
  </a>
  <a href="https://github.com/castdrian/ishare">
    <img src="https://img.shields.io/github/stars/castdrian/ishare?style=social" alt="stars">
  </a>
</p>
<p align="center">
  <sub align="center">Homebrew cask star goal</sub>
  <p align="center">
    <img src="https://progress-bar.dev/84/?width=500" alt="Homebrew cask star goal progress">
  </p>
</p>

---

<p align="center">
  <a href="https://github.com/castdrian/ishare/releases/latest/download/ishare_macOS.zip" download>
    <img src="https://www.dmo-app.com/wp-content/uploads/2022/05/mac-download-button-1.png" alt="Download Latest Release" width="200">
  </a>
</p>

## 🚀 Features
1. **Versatile Screen Capture**: 
    - **Custom Region**: Instantly and easily define and capture specific portions of your screen.
    - **Window Capture**: Capture individual application windows without any clutter.
    - **Entire Display Capture**: Snapshot your whole screen with a single action.

2. **Flexible Screen Recording**:
    - **Video Recording**: Record videos of entire screens or specific windows.
    - **GIF Recording**: Capture your moments in GIF format, perfect for quick shares.
    - **Customizable Codecs and Compression**: Fine-tune the parameters of the output video files.

3. **Easy Uploading**:
    - **Custom Upload Destinations**: Define your own server or service to upload your media.
    - **Built-in Imgur Uploader**: Quickly upload your results to Imgur automatically.

4. **High Customizability**:
    - **Custom Keybinds**: Set keyboard shortcuts that match your workflow.
    - **File Format Preferences**: Choose the formats for your screenshots (e.g. PNG, JPG) and recordings.
    - **Custom File Naming**: Define your own prefix for filenames, so you always know which app took the shot.
    - **Custom Save Path**: Decide where exactly on your system you want to save your captures and recordings.
    - **Application Exclusions**: Exclude specific apps from being recorded.

5. **Automatic Updates**: Always stay on the cutting edge with built-in automatic updates.

6. **Coming Soon - Post Media Task Plugins**: Expand the capabilities of the app with plugins that can process your media after capture.

![ishare_menu](https://github.com/iGerman00/ishare/assets/36676880/3a546afb-90ee-4b85-8b38-6029ccd67565)


## 🛠 Custom Uploader Setup

If you're looking to integrate a custom endpoint for uploads using ishare, you're in the right place! By default, ishare supports and opens `.iscu` files for configuration. They are text files containing JSON data and you can make your own:

**Note:** Version 2.0.0 introduces breaking changes. Follow the migration guide for updates and consider reinstallation if you encounter issues post-update.

<details>
  <summary>
    📝 Specification (2.0.0 and newer)
  </summary>

  The custom uploader specification since version 2.0.0 has the following structure:

```jsonc
{
    "name": "Custom Uploader Name",
    "requestURL": "https://uploader.com/upload",
    "headers": { // optional
        "Authorization": "Bearer YOUR_AUTH_TOKEN"
    },
    "formData": { // optional
        "additionalData": "value"
    },
    "fileFormName": "file", // optional
    "requestBodyType": "multipartFormData", // optional, can be "multipartFormData" or "binary"
    "responseURL": "https://uploader.com/{{jsonproperty}}",
    "deletionURL": "https://uploader.com/{{jsonproperty}}" // optional
}
```
<sup>All properties are case insensitive.</sup>

This new specification allows for more dynamic URL construction and handles deletion URLs.  
For `responseURL` and `deletionURL`, JSON properties that are derived from the response payload can be defined as `{{jsonProperty}}`. There is support for nesting (`upload.url`) and arrays (`files[0].url`).  

</details>

## ⚙️ Migration from Previous Specification
<details>
<summary>Click to expand</summary>

### Key changes
- `responseURL` replaces `responseProp`.
- New optional field `deletionURL`.
- Updated URL templating syntax.

### Migration steps
1. Replace `responseProp` with `responseURL`, ensuring the URL includes placeholders for dynamic values.
2. If your service provides a deletion link, add the `deletionURL` field.
3. Update URL placeholders to match the new syntax:  

For example, 
```json
"responseProp": "fileId"
```
Turns into:
```json
"responseURL": "{{fileId}}"
```

### Example migration
Before:

```json
{
    "name": "uploader",
    "requestURL": "https://uploader.com/upload",
    "responseProp": "fileUrl"
}
```

After:
```jsonc
{
    "name": "uploader",
    "requestURL": "https://uploader.com/upload",
    "responseURL": "{{fileUrl}}" // also supported: "https://uploader.com/{{fileId}}"
}
```
</details>

## 📤 Compatible Uploader Services
ishare is confirmed to be compatible with the following uploader services:
- [chibisafe](https://github.com/chibisafe/chibisafe)
- [lumen](https://github.com/ChecksumDev/lumen)
- [zipline](https://github.com/diced/zipline)

## 🤝 Contributors
[![Contributors](https://contrib.rocks/image?repo=castdrian/ishare)](https://github.com/castdrian/ishare/graphs/contributors)

## 🙌 Credits
- Special thanks to [Inna Strazhnik](https://www.behance.net/strazhnik) for the app icon

## 📜 License
Released under [GPL-3.0](/LICENSE) by [@castdrian](https://github.com/castdrian)
