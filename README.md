[![Sponsor](https://img.shields.io/badge/sponsor-30363D?style=for-the-badge&logo=GitHub-Sponsors&logoColor=#white)](https://github.com/sponsors/castdrian)
[![Ko-FI](https://img.shields.io/badge/Ko--fi-F16061?style=for-the-badge&logo=ko-fi&logoColor=white)](https://ko-fi.com/castdrian)
[![Discord](https://img.shields.io/badge/Discord-5865F2?style=for-the-badge&logo=discord&logoColor=white)](https://discord.gg/sX4KYzu5pX)
[![GitHub](https://img.shields.io/badge/GitHub-100000?style=for-the-badge&logo=github&logoColor=white)](https://github.com/castdrian/ishare)
[![stars - ishare](https://img.shields.io/github/stars/castdrian/ishare?style=social)](https://github.com/castdrian/ishare)
<br>
[![Build and Release App](https://github.com/castdrian/ishare/workflows/Build%20and%20Release%20App/badge.svg)](https://github.com/castdrian/ishare/actions?query=workflow:"Build+and+Release+App")
[![GitHub release](https://img.shields.io/github/release/castdrian/ishare?include_prereleases=&sort=semver&color=blue)](https://github.com/castdrian/ishare/releases/)
[![License](https://img.shields.io/badge/License-GPL--3.0-blue)](#license)
[![issues - ishare](https://img.shields.io/github/issues/castdrian/ishare)](https://github.com/castdrian/ishare/issues)

# ishare
a clean and unbloated screen capture utility for macOS.

⭐ stars amount for homebrew cask 🍺 : \
![Homebrew](https://progress-bar.dev/49/?width=240)

<div>
  <a href="https://github.com/castdrian/ishare/releases/latest/download/ishare_macOS.zip" download>
    <img src="https://www.dmo-app.com/wp-content/uploads/2022/05/mac-download-button-1.png" alt="Download Latest Release" width="200">
  </a>
</div>

(yes this readme is ugly, sorry)
<br>

## 📷 Features
- Capture and record screens, windows or a custom region
- Upload the media files to built-in or custom uploaders
- Profit
- ???

## 📤 Custom Uploader Request Specification 
ishare performs a `POST` request to the specified endpoint, containing all configurations that are defined in the custom uploader.\
The screencapture or recording that was taken is appended to the multipart/form-data body under the `image` or `video` key respectively (can be overriden).

## 📤/⚙️ Custom Uploader Specification

The ishare custom uploader spec allows you to define the configuration for uploading files to a custom endpoint.
These can be created by yourself or existing projetcs ShareX compatibles such as [Zipline](https://zipline.diced.sh/), [ass](https://github.com/tycrek/ass#readme), etc.\

ishare is configured to support and open `.iscu` files by default.

<details>
  <summary>
    Specification Details
  </summary>
  
  - **name** (string):\
  The name of the custom uploader. Use this value to identify the uploader instance or provide a user-friendly name.
  
- **requestUrl** (string):\
  The URL where the files should be uploaded. Replace `example.com/upload` with the actual URL of the upload endpoint.
  
- **headers** (optional, object):\
  Additional headers to include in the request. It should be a dictionary of key-value pairs, where each key represents the header name and the value represents the header value.
  
- **formData** (optional, object):\
  Additional form data to be included in the request payload. It should be a dictionary of key-value pairs, where each key represents the form field name and the value represents the form field value.

- **fileFormName** (optional, string):\
  Optional override for the value used as in the file name field for the multipart/form-data request.
  
- **responseProp** (string):\
  The property name in the response JSON that contains the uploaded file URL. Replace `"url"` with the actual json accessors that lead to the property returned in the response.

Please note that for now, the custom uploader editor is broken. Please create one and export/edit the .iscu file generated directly with your favorite IDE.

</details>

<details>
  <summary>
    Example
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

In this example, the custom uploader is configured to upload files to `example.com/upload`. It includes an authorization header, a form field and a file form name override. The uploaded file URL is expected to be available in the specified property of the response JSON.

</details>

## 🔄 Post Media Task Plugin Specification

ishare allows you to script your own plugins that you can use as PMT (Post Media Task).

<details>
  <summary>
    Specification Details
  </summary>
  TBD
</details>

<details>
  <summary>
    Example
  </summary>
  TBD
</details>

## 👍 Credits
- Special thanks to [Inna Strazhnik](https://www.behance.net/strazhnik) for the app icon

## 📄 License

Released under [GPL-3.0](/LICENSE) by [@castdrian](https://github.com/castdrian).
