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
    📝 Specification (Version 2.0.0)
  </summary>

  The custom uploader specification in version 2.0.0 has the following structure:

```json
{
    "name": "Custom Uploader Name",
    "requestUrl": "https://your-upload-url.com/upload",
    "headers": { // optional
        "Authorization": "Bearer YOUR_AUTH_TOKEN"
    },
    "formData": { // optional
        "additionalData": "value"
    },
    "fileFormName": "file", // optional
    "requestBodyType": "multipartFormData", // optional, choice of multipartFormData and binary
    "responseURL": "https://your-upload-url.com/{{jsonproperty}}",
    "deletionURL": "https://your-upload-url.com/delete/{{jsonproperty}}" // optional
}
```

This new specification allows for more dynamic URL construction and handling deletion URLs.

</details>

## ⚙️ Migration Guide from Previous Specification
<details>
<summary>Click to expand</summary>

### Key Changes in Specification
- `responseURL` replaces `responseProp`.
- New optional field `deletionURL`.
- Updated URL templating syntax.

### Migration Steps
1. Replace `responseProp` with `responseURL`, ensuring the URL includes placeholders for dynamic values.
2. If your service supports deletion, add the `deletionURL` field.
3. Update URL placeholders to match the new syntax. For instance, `{fileId}` replaces `{responsePropName}`.

### Example Migration
Previous spec:

```json
{
    "name": "uploader",
    "requestUrl": "https://uploader.com/upload",
    "responseProp": "fileUrl"
}
```

New spec:
```json
{
    "name": "uploader",
    "requestUrl": "https://uploader.com/upload",
    "responseURL": "{{fileUrl}}" // can be concatenated: "https://uploader.com/{{property}}"
}
```
</details>

## 📤 Compatible Uploader Services
ishare is confirmed to be compatible with the following uploader services:
- [chibisafe](https://github.com/chibisafe/chibisafe)
- [lumen](https://github.com/ChecksumDev/lumen)

## 🤝 Contributors
[![Contributors](https://contrib.rocks/image?repo=castdrian/ishare)](https://github.com/castdrian/ishare/graphs/contributors)

## 🙌 Credits
- Special thanks to [Inna Strazhnik](https://www.behance.net/strazhnik) for the app icon

## 📜 License
Released under [GPL-3.0](/LICENSE) by [@castdrian](https://github.com/castdrian)
