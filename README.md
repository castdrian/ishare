# ishare
clean and unbloated screen capture utility for macOS

[![castdrian - ishare](https://img.shields.io/static/v1?label=castdrian&message=ishare&color=blue&logo=github)](https://github.com/castdrian/ishare "Go to GitHub repo")
[![stars - ishare](https://img.shields.io/github/stars/castdrian/ishare?style=social)](https://github.com/castdrian/ishare)
[![forks - ishare](https://img.shields.io/github/forks/castdrian/ishare?style=social)](https://github.com/castdrian/ishare)

[![Build and Release App](https://github.com/castdrian/ishare/workflows/Build%20and%20Release%20App/badge.svg)](https://github.com/castdrian/ishare/actions?query=workflow:"Build+and+Release+App")
[![GitHub release](https://img.shields.io/github/release/castdrian/ishare?include_prereleases=&sort=semver&color=blue)](https://github.com/castdrian/ishare/releases/)
[![License](https://img.shields.io/badge/License-GPL_v3-blue)](#license)
[![issues - ishare](https://img.shields.io/github/issues/castdrian/ishare)](https://github.com/castdrian/ishare/issues)

star amount for homebrew cask:\
![](https://progress-bar.dev/25/?width=240)

<div>
  <a href="https://github.com/castdrian/ishare/releases/latest/download/ishare_macOS.zip" download>
    <img src="https://www.dmo-app.com/wp-content/uploads/2022/05/mac-download-button-1.png" alt="Download Latest Release" width="200">
  </a>
</div>

<br>

<a href="https://discord.gg/sX4KYzu5pX"><img src="https://discord.com/api/guilds/844574704698130492/widget.png?style=banner2" alt="Discord Server"></a>

## Features
- Capture and record screens, windows or a custom region
- Upload the media files to built-in or custom uploaders
- Profit
- ???

## Custom Uploader Request Specification
ishare performs a `POST` request to the specified endpoint, containing all configurations that are defined in the custom uploader.\
The screencapture or recording that was taken is appended to the multipart/form-data body under the `image` or `video` key respectively (can be overriden).

## Custom Uploader Specification

The ishare custom uploader spec allows you to define the configuration for uploading files to a custom endpoint.\
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

## Post Media Task Plugin Specification

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

## License

Released under [GPL v3](/LICENSE) by [@castdrian](https://github.com/castdrian).
