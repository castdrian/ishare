# ishare
sharex-like screen capture utility for macOS

## Custom Uploader Request Specification
ishare performs a `POST` request to the specified endpoint, containing all configuartions that are defined in the custom uploader.\
The screencapture or recording that was taken is appended to the multipart/form-data body under the `image` or `video` key respectively.

## Custom Uploader Specification

The ishare custom uploader spec allows you to define the configuration for uploading files to a custom endpoint.\
ishare is configured to support and open `.iscu` files by default.

### Specification Details

- **name** (string):\
  The name of the custom uploader. Use this value to identify the uploader instance or provide a user-friendly name.
  
- **requestUrl** (string):\
  The URL where the files should be uploaded. Replace `example.com/upload` with the actual URL of the upload endpoint.
  
- **headers** (optional, object):\
  Additional headers to include in the request. It should be a dictionary of key-value pairs, where each key represents the header name and the value represents the header value.
  
- **formData** (optional, object):\
  Additional form data to be included in the request payload. It should be a dictionary of key-value pairs, where each key represents the form field name and the value represents the form field value.
  
- **responseProp** (string):\
  The property name in the response JSON that contains the uploaded file URL. Replace `"url"` with the actual property name returned in the response.

### Example

```json
{
  "name": "ishare custom uploader",
  "requestUrl": "example.com/upload",
  "headers": { "Authorization": "Basic 0123456789" },
  "formData": { "key": "value" },
  "responseProp": "url"
}
```

In this example, the custom uploader is configured to upload files to `example.com/upload`. It includes an authorization header and a form field. The uploaded file URL is expected to be available in the specified property of the response JSON.

Feel free to adjust the specification details according to your requirements.
