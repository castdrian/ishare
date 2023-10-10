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
    <img src="https://progress-bar.dev/49/?width=500" alt="Homebrew cask star goal progress">
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

## 📤 Custom Uploader Requests

With ishare, you can easily set up your own custom uploader. Here's a simple guide:

1. **Endpoint and Method**: When you use a custom uploader, ishare will send a `POST` request to the endpoint you provide.
  
2. **Configurations**: All the settings you've defined for your custom uploader will be included in this request.
  
3. **Adding Your Media**:
   - For screenshots: They'll be added to the request body as `multipart/form-data` under the `image` key.
   - For recordings: They'll be under the `video` key.

   (P.S. If you'd like, you can change these default key names)

## 🛠 Custom Uploader Setup

If you're looking to integrate a custom endpoint for uploads using ishare, you're in the right place! By default, ishare supports and opens `.iscu` files for configuration. They are text files containing JSON data and you can make your own:

<details>
  <summary>
    📝 Specification
  </summary>
  
- **name** (string):\
  What would you like to call your custom uploader? This is its display name, making it easy to identify.
  
- **requestUrl** (string):\
  Where should ishare send the files? In the example, swap out `example.com/upload` with your specific upload URL.
  
- **headers** (optional, object):\
  Need to send any extra headers? Add them here as key-value pairs, with the key being the header name and the value being its associated data.
  
- **formData** (optional, object):\
  If you need extra form fields in the upload, specify them here. Similarly, use key-value pairs where the key is the form field name and the value is the field content.

- **fileFormName** (optional, string):\
  Want a different file name for the `multipart/form-data` request? Specify it here.
  
- **responseProp** (string):\
  Once the file is uploaded, where can we find its URL in the response? Swap out `"url"` for the specific JSON property path.

</details>

<details>
  <summary>
    🌟 Example Configuration
  </summary>
  
```json
{
  "name": "ishare custom uploader",
  "requestUrl": "example.com/upload",
  "headers": { "Authorization": "Basic 0123456789" },
  "formData": { "key": "value" },
  "fileFormName": "image",
  "responseProp": "url"
}
```

Above is an example custom uploader for ishare. It sends uploads to `example.com/upload`, uses an authorization header, and includes additional form data. In the response, it expects to receive JSON with the property `"url"` containing the URL of your upload.

</details>

## Post Media Task Plugin Specification

Soon, ishare will allow you to script your own plugins that you can use as PMTs (Post Media Tasks).

## 🙌 Credits
- Special thanks to [Inna Strazhnik](https://www.behance.net/strazhnik) for the app icon

## 📜 License
Released under [GPL-3.0](/LICENSE) by [@castdrian](https://github.com/castdrian)
