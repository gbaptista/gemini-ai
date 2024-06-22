# Gemini AI

A Ruby Gem for interacting with [Gemini](https://deepmind.google/technologies/gemini/) through [Vertex AI](https://cloud.google.com/vertex-ai), [Generative Language API](https://ai.google.dev/api/rest), or [AI Studio](https://makersuite.google.com), Google's generative AI services.

![The logo shows a gemstone split into red and blue halves, symbolizing Ruby programming and Gemini AI. It's surrounded by a circuit-like design on a dark blue backdrop.](https://raw.githubusercontent.com/gbaptista/assets/main/gemini-ai/ruby-gemini-ai.png)

> _This Gem is designed to provide low-level access to Gemini, enabling people to build abstractions on top of it. If you are interested in more high-level abstractions or more user-friendly tools, you may want to consider [Nano Bots](https://github.com/icebaker/ruby-nano-bots) 💎 🤖._

## TL;DR and Quick Start

```ruby
gem 'gemini-ai', '~> 4.0.0'
```

```ruby
require 'gemini-ai'

# With an API key
client = Gemini.new(
  credentials: {
    service: 'generative-language-api',
    api_key: ENV['GOOGLE_API_KEY']
  },
  options: { model: 'gemini-pro', server_sent_events: true }
)

# With a Service Account Credentials File
client = Gemini.new(
  credentials: {
    service: 'vertex-ai-api',
    file_path: 'google-credentials.json',
    region: 'us-east4'
  },
  options: { model: 'gemini-pro', server_sent_events: true }
)

# With Application Default Credentials
client = Gemini.new(
  credentials: {
    service: 'vertex-ai-api',
    region: 'us-east4'
  },
  options: { model: 'gemini-pro', server_sent_events: true }
)

result = client.stream_generate_content({
  contents: { role: 'user', parts: { text: 'hi!' } }
})
```

Result:
```ruby
[{ 'candidates' =>
   [{ 'content' => {
        'role' => 'model',
        'parts' => [{ 'text' => 'Hello! How may I assist you?' }]
      },
      'finishReason' => 'STOP',
      'safetyRatings' =>
      [{ 'category' => 'HARM_CATEGORY_HARASSMENT', 'probability' => 'NEGLIGIBLE' },
       { 'category' => 'HARM_CATEGORY_HATE_SPEECH', 'probability' => 'NEGLIGIBLE' },
       { 'category' => 'HARM_CATEGORY_SEXUALLY_EXPLICIT', 'probability' => 'NEGLIGIBLE' },
       { 'category' => 'HARM_CATEGORY_DANGEROUS_CONTENT', 'probability' => 'NEGLIGIBLE' }] }],
   'usageMetadata' => {
     'promptTokenCount' => 2,
     'candidatesTokenCount' => 8,
     'totalTokenCount' => 10
   } }]
```

## Index

- [TL;DR and Quick Start](#tldr-and-quick-start)
- [Index](#index)
- [Setup](#setup)
  - [Installing](#installing)
  - [Credentials](#credentials)
    - [Option 1: API Key (Generative Language API)](#option-1-api-key-generative-language-api)
    - [Option 2: Service Account Credentials File (Vertex AI API)](#option-2-service-account-credentials-file-vertex-ai-api)
    - [Option 3: Application Default Credentials (Vertex AI API)](#option-3-application-default-credentials-vertex-ai-api)
    - [Required Data](#required-data)
  - [Custom Version](#custom-version)
- [Available Models](#available-models)
- [Usage](#usage)
  - [Client](#client)
  - [Methods](#methods)
    - [Chat](#chat)
      - [stream_generate_content](#stream_generate_content)
        - [Receiving Stream Events](#receiving-stream-events)
        - [Without Events](#without-events)
      - [generate_content](#generate_content)
    - [Embeddings](#embeddings)
      - [predict](#predict)
      - [embed_content](#embed_content)
  - [Modes](#modes)
    - [Text](#text)
    - [Image](#image)
    - [Video](#video)
  - [Streaming vs. Server-Sent Events (SSE)](#streaming-vs-server-sent-events-sse)
    - [Server-Sent Events (SSE) Hang](#server-sent-events-sse-hang)
    - [Non-Streaming](#non-streaming)
  - [Back-and-Forth Conversations](#back-and-forth-conversations)
  - [Safety Settings](#safety-settings)
  - [System Instructions](#system-instructions)
  - [JSON Format Responses](#json-format-responses)
    - [JSON Schema](#json-schema)
  - [Tools (Functions) Calling](#tools-functions-calling)
  - [New Functionalities and APIs](#new-functionalities-and-apis)
  - [Request Options](#request-options)
    - [Adapter](#adapter)
    - [Timeout](#timeout)
  - [Error Handling](#error-handling)
    - [Rescuing](#rescuing)
    - [For Short](#for-short)
    - [Errors](#errors)
- [Development](#development)
  - [Purpose](#purpose)
  - [Publish to RubyGems](#publish-to-rubygems)
  - [Updating the README](#updating-the-readme)
- [Resources and References](#resources-and-references)
- [Disclaimer](#disclaimer)

## Setup

### Installing

```sh
gem install gemini-ai -v 4.0.0
```

```sh
gem 'gemini-ai', '~> 4.0.0'
```

### Credentials

- [Option 1: API Key (Generative Language API)](#option-1-api-key-generative-language-api)
- [Option 2: Service Account Credentials File (Vertex AI API)](#option-2-service-account-credentials-file-vertex-ai-api)
- [Option 3: Application Default Credentials (Vertex AI API)](#option-3-application-default-credentials-vertex-ai-api)
- [Required Data](#required-data)

> ⚠️ DISCLAIMER: Be careful with what you are doing, and never trust others' code related to this. These commands and instructions alter the level of access to your Google Cloud Account, and running them naively can lead to security risks as well as financial risks. People with access to your account can use it to steal data or incur charges. Run these commands at your own responsibility and due diligence; expect no warranties from the contributors of this project.

#### Option 1: API Key (Generative Language API)

You need a [Google Cloud](https://console.cloud.google.com) [_Project_](https://cloud.google.com/resource-manager/docs/creating-managing-projects), and then you can generate an API Key through the Google Cloud Console [here](https://console.cloud.google.com/apis/credentials).

You also need to enable the _Generative Language API_ service in your Google Cloud Console, which can be done [here](https://console.cloud.google.com/apis/library/generativelanguage.googleapis.com).


Alternatively, you can generate an API Key through _Google AI Studio_ [here](https://makersuite.google.com/app/apikey). However, this approach will automatically create a project for you in your Google Cloud Account.

#### Option 2: Service Account Credentials File (Vertex AI API)

You need a [Google Cloud](https://console.cloud.google.com) [_Project_](https://cloud.google.com/resource-manager/docs/creating-managing-projects) and a [_Service Account_](https://cloud.google.com/iam/docs/service-account-overview) to use [Vertex AI](https://cloud.google.com/vertex-ai) API.

After creating them, you need to enable the Vertex AI API for your project by clicking `Enable` here: [Vertex AI API](https://console.cloud.google.com/apis/library/aiplatform.googleapis.com).

You can create credentials for your _Service Account_ [here](https://console.cloud.google.com/apis/credentials), where you will be able to download a JSON file named `google-credentials.json` that should have content similar to this:

```json
{
  "type": "service_account",
  "project_id": "YOUR_PROJECT_ID",
  "private_key_id": "a00...",
  "private_key": "-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n",
  "client_email": "PROJECT_ID@PROJECT_ID.iam.gserviceaccount.com",
  "client_id": "000...",
  "auth_uri": "https://accounts.google.com/o/oauth2/auth",
  "token_uri": "https://oauth2.googleapis.com/token",
  "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
  "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/..."
}
```

You need to have the necessary [policies](https://cloud.google.com/iam/docs/policies) (`roles/aiplatform.user` and possibly `roles/ml.admin`) in place to use the Vertex AI API.

You can add them by navigating to the [IAM Console](https://console.cloud.google.com/iam-admin/iam) and clicking on the _"Edit principal"_ (✏️ pencil icon) next to your _Service Account_.

Alternatively, you can add them through the [gcloud CLI](https://cloud.google.com/sdk/gcloud) as follows:

```sh
gcloud projects add-iam-policy-binding PROJECT_ID \
  --member='serviceAccount:PROJECT_ID@PROJECT_ID.iam.gserviceaccount.com' \
  --role='roles/aiplatform.user'
```

Some people reported having trouble accessing the API, and adding the role `roles/ml.admin` fixed it:

```sh
gcloud projects add-iam-policy-binding PROJECT_ID \
  --member='serviceAccount:PROJECT_ID@PROJECT_ID.iam.gserviceaccount.com' \
  --role='roles/ml.admin'
```

If you are not using a _Service Account_:
```sh
gcloud projects add-iam-policy-binding PROJECT_ID \
  --member='user:YOUR@MAIL.COM' \
  --role='roles/aiplatform.user'

gcloud projects add-iam-policy-binding PROJECT_ID \
  --member='user:YOUR@MAIL.COM' \
  --role='roles/ml.admin'
```

#### Option 3: Application Default Credentials (Vertex AI API)

Similar to [Option 2](#option-2-service-account-credentials-file-vertex-ai-api), but you don't need to download a `google-credentials.json`. [_Application Default Credentials_](https://cloud.google.com/docs/authentication/application-default-credentials) automatically find credentials based on the application environment.

For local development, you can generate your default credentials using the [gcloud CLI](https://cloud.google.com/sdk/gcloud) as follows:

```sh
gcloud auth application-default login 
```

For more details about alternative methods and different environments, check the official documentation:
[Set up Application Default Credentials](https://cloud.google.com/docs/authentication/provide-credentials-adc)

#### Required Data

After choosing an option, you should have all the necessary data and access to use Gemini.

**Option 1**, for API Key:

```ruby
{
  service: 'generative-language-api',
  api_key: 'GOOGLE_API_KEY'
}
```

Remember that hardcoding your API key in code is unsafe; it's preferable to use environment variables:

```ruby
{
  service: 'generative-language-api',
  api_key: ENV['GOOGLE_API_KEY']
}
```

**Option 2**: For the Service Account, provide a `google-credentials.json` file and a `REGION`:

```ruby
{
  service: 'vertex-ai-api',
  file_path: 'google-credentials.json',
  region: 'us-east4'
}
```

**Option 3**: For _Application Default Credentials_, omit both the `api_key` and the `file_path`:

```ruby
{
  service: 'vertex-ai-api',
  region: 'us-east4'
}
```

As of the writing of this README, the following regions support Gemini:
```text
Iowa (us-central1)
Las Vegas, Nevada (us-west4)
Montréal, Canada (northamerica-northeast1)
Northern Virginia (us-east4)
Oregon (us-west1)
Seoul, Korea (asia-northeast3)
Singapore (asia-southeast1)
Tokyo, Japan (asia-northeast1)
```

You can follow here if new regions are available: [Gemini API](https://cloud.google.com/vertex-ai/docs/generative-ai/model-reference/gemini)

You might want to explicitly set a Google Cloud Project ID, which you can do as follows:

```ruby
{
  service: 'vertex-ai-api',
  project_id: 'PROJECT_ID'
}
```

### Custom Version

By default, the gem uses the `v1` version of the APIs. You may want to use a different version:

```ruby
# With an API key
client = Gemini.new(
  credentials: {
    service: 'generative-language-api',
    api_key: ENV['GOOGLE_API_KEY'],
    version: 'v1beta'
  },
  options: { model: 'gemini-pro', server_sent_events: true }
)

# With a Service Account Credentials File
client = Gemini.new(
  credentials: {
    service: 'vertex-ai-api',
    file_path: 'google-credentials.json',
    region: 'us-east4',
    version: 'v1beta'
  },
  options: { model: 'gemini-pro', server_sent_events: true }
)

# With Application Default Credentials
client = Gemini.new(
  credentials: {
    service: 'vertex-ai-api',
    region: 'us-east4',
    version: 'v1beta'
  },
  options: { model: 'gemini-pro', server_sent_events: true }
)
```

## Available Models

These models are accessible to the repository **author** as of May 2025 in the `us-east4` region. Access to models may vary by region, user, and account. All models here are expected to work, if you can access them. This is just a reference of what a "typical" user may expect to have access to right away:

| Model                                    | Vertex AI | Generative Language |
|------------------------------------------|:---------:|:-------------------:|
| gemini-pro-vision                        |    ✅     |          🔒         |
| gemini-pro                               |    ✅     |          ✅         |
| gemini-1.5-pro-preview-0514              |    ✅     |          🔒         |
| gemini-1.5-pro-preview-0409              |    ✅     |          🔒         |
| gemini-1.5-pro                           |    🔒     |          🔒         |
| gemini-1.5-flash-preview-0514            |    ✅     |          🔒         |
| gemini-1.5-flash                         |    🔒     |          🔒         |
| gemini-1.0-pro-vision-latest             |    🔒     |          🔒         |
| gemini-1.0-pro-vision-001                |    ✅     |          🔒         |
| gemini-1.0-pro-vision                    |    ✅     |          🔒         |
| gemini-1.0-pro-latest                    |    🔒     |          ✅         |
| gemini-1.0-pro-002                       |    ✅     |          🔒         |
| gemini-1.0-pro-001                       |    ✅     |          ✅         |
| gemini-1.0-pro                           |    ✅     |          ✅         |
| gemini-ultra                             |    🔒     |          🔒         |
| gemini-1.0-ultra                         |    🔒     |          🔒         |
| gemini-1.0-ultra-001                     |    🔒     |          🔒         |
| text-embedding-preview-0514              |    🔒     |          🔒         |
| text-embedding-preview-0409              |    🔒     |          🔒         |
| text-embedding-004                       |    ✅     |          ✅         |
| embedding-001                            |    🔒     |          ✅         |
| text-multilingual-embedding-002          |    ✅     |          🔒         |
| textembedding-gecko-multilingual@001     |    ✅     |          🔒         |
| textembedding-gecko-multilingual@latest  |    ✅     |          🔒         |
| textembedding-gecko@001                  |    ✅     |          🔒         |
| textembedding-gecko@002                  |    ✅     |          🔒         |
| textembedding-gecko@003                  |    ✅     |          🔒         |
| textembedding-gecko@latest               |    ✅     |          🔒         |

You can follow new models at:

- [Google models](https://cloud.google.com/vertex-ai/generative-ai/docs/learn/models)
  - [Model versions and lifecycle](https://cloud.google.com/vertex-ai/generative-ai/docs/learn/model-versioning)

This is [the code](https://gist.github.com/gbaptista/d7390901293bce81ee12ff4ec5fed62c) used for generating this table that you can use to explore your own access.

## Usage

### Client
Ensure that you have all the [required data](#required-data) for authentication.

Create a new client:
```ruby
require 'gemini-ai'

# With an API key
client = Gemini.new(
  credentials: {
    service: 'generative-language-api',
    api_key: ENV['GOOGLE_API_KEY']
  },
  options: { model: 'gemini-pro', server_sent_events: true }
)

# With a Service Account Credentials File
client = Gemini.new(
  credentials: {
    service: 'vertex-ai-api',
    file_path: 'google-credentials.json',
    region: 'us-east4'
  },
  options: { model: 'gemini-pro', server_sent_events: true }
)

# With Application Default Credentials
client = Gemini.new(
  credentials: {
    service: 'vertex-ai-api',
    region: 'us-east4'
  },
  options: { model: 'gemini-pro', server_sent_events: true }
)
```

### Methods

#### Chat

##### stream_generate_content

###### Receiving Stream Events

Ensure that you have enabled [Server-Sent Events](#streaming-vs-server-sent-events-sse) before using blocks for streaming:

```ruby
client.stream_generate_content(
  { contents: { role: 'user', parts: { text: 'hi!' } } }
) do |event, parsed, raw|
  puts event
end
```

Event:
```ruby
{ 'candidates' =>
  [{ 'content' => {
       'role' => 'model',
       'parts' => [{ 'text' => 'Hello! How may I assist you?' }]
     },
     'finishReason' => 'STOP',
     'safetyRatings' =>
     [{ 'category' => 'HARM_CATEGORY_HARASSMENT', 'probability' => 'NEGLIGIBLE' },
      { 'category' => 'HARM_CATEGORY_HATE_SPEECH', 'probability' => 'NEGLIGIBLE' },
      { 'category' => 'HARM_CATEGORY_SEXUALLY_EXPLICIT', 'probability' => 'NEGLIGIBLE' },
      { 'category' => 'HARM_CATEGORY_DANGEROUS_CONTENT', 'probability' => 'NEGLIGIBLE' }] }],
  'usageMetadata' => {
    'promptTokenCount' => 2,
    'candidatesTokenCount' => 8,
    'totalTokenCount' => 10
  } }
```

###### Without Events

You can use `stream_generate_content` without events:

```ruby
result = client.stream_generate_content(
  { contents: { role: 'user', parts: { text: 'hi!' } } }
)
```

In this case, the result will be an array with all the received events:

```ruby
[{ 'candidates' =>
   [{ 'content' => {
        'role' => 'model',
        'parts' => [{ 'text' => 'Hello! How may I assist you?' }]
      },
      'finishReason' => 'STOP',
      'safetyRatings' =>
      [{ 'category' => 'HARM_CATEGORY_HARASSMENT', 'probability' => 'NEGLIGIBLE' },
       { 'category' => 'HARM_CATEGORY_HATE_SPEECH', 'probability' => 'NEGLIGIBLE' },
       { 'category' => 'HARM_CATEGORY_SEXUALLY_EXPLICIT', 'probability' => 'NEGLIGIBLE' },
       { 'category' => 'HARM_CATEGORY_DANGEROUS_CONTENT', 'probability' => 'NEGLIGIBLE' }] }],
   'usageMetadata' => {
     'promptTokenCount' => 2,
     'candidatesTokenCount' => 8,
     'totalTokenCount' => 10
   } }]
```

You can mix both as well:
```ruby
result = client.stream_generate_content(
  { contents: { role: 'user', parts: { text: 'hi!' } } }
) do |event, parsed, raw|
  puts event
end
```

##### generate_content

```ruby
result = client.generate_content(
  { contents: { role: 'user', parts: { text: 'hi!' } } }
)
```

Result:
```ruby
{ 'candidates' =>
  [{ 'content' => { 'parts' => [{ 'text' => 'Hello! How can I assist you today?' }], 'role' => 'model' },
     'finishReason' => 'STOP',
     'index' => 0,
     'safetyRatings' =>
     [{ 'category' => 'HARM_CATEGORY_SEXUALLY_EXPLICIT', 'probability' => 'NEGLIGIBLE' },
      { 'category' => 'HARM_CATEGORY_HATE_SPEECH', 'probability' => 'NEGLIGIBLE' },
      { 'category' => 'HARM_CATEGORY_HARASSMENT', 'probability' => 'NEGLIGIBLE' },
      { 'category' => 'HARM_CATEGORY_DANGEROUS_CONTENT', 'probability' => 'NEGLIGIBLE' }] }],
  'promptFeedback' =>
  { 'safetyRatings' =>
    [{ 'category' => 'HARM_CATEGORY_SEXUALLY_EXPLICIT', 'probability' => 'NEGLIGIBLE' },
     { 'category' => 'HARM_CATEGORY_HATE_SPEECH', 'probability' => 'NEGLIGIBLE' },
     { 'category' => 'HARM_CATEGORY_HARASSMENT', 'probability' => 'NEGLIGIBLE' },
     { 'category' => 'HARM_CATEGORY_DANGEROUS_CONTENT', 'probability' => 'NEGLIGIBLE' }] } }
```

As of the writing of this README, only the `generative-language-api` service supports the `generate_content` method; `vertex-ai-api` does not.

#### Embeddings

##### predict

Vertex AI API generates embeddings through the `predict` method ([documentation](https://cloud.google.com/vertex-ai/generative-ai/docs/embeddings/get-text-embeddings)), and you need a client set up to use an embedding model (e.g. `text-embedding-004`):

```ruby
result = client.predict(
  { instances: [{ content: 'What is life?' }],
    parameters: { autoTruncate: true } }
)
```

Result:
```ruby
{ 'predictions' =>
  [{ 'embeddings' =>
     { 'statistics' => { 'truncated' => false, 'token_count' => 4 },
       'values' =>
       [-0.006861076690256596,
        0.00020840796059928834,
        -0.028549950569868088,
        # ...
        0.0020092015620321035,
        0.03279878571629524,
        -0.014905261807143688] } }],
  'metadata' => { 'billableCharacterCount' => 11 } }
```

##### embed_content

Generative Language API generates embeddings through the `embed_content` method ([documentation](https://ai.google.dev/api/rest/v1/models/embedContent)), and you need a client set up to use an embedding model (e.g. `text-embedding-004`):

```ruby
result = client.embed_content(
  { content: { parts: [{ text: 'What is life?' }] } }
)
```

Result:
```ruby
{ 'embedding' =>
  { 'values' =>
    [-0.0065307906,
     -0.0001632607,
     -0.028370803,

     0.0019950708,
     0.032798845,
     -0.014878989] } }
```

### Modes

#### Text

```ruby
result = client.stream_generate_content({
  contents: { role: 'user', parts: { text: 'hi!' } }
})
```

Result:
```ruby
[{ 'candidates' =>
   [{ 'content' => {
        'role' => 'model',
        'parts' => [{ 'text' => 'Hello! How may I assist you?' }]
      },
      'finishReason' => 'STOP',
      'safetyRatings' =>
      [{ 'category' => 'HARM_CATEGORY_HARASSMENT', 'probability' => 'NEGLIGIBLE' },
       { 'category' => 'HARM_CATEGORY_HATE_SPEECH', 'probability' => 'NEGLIGIBLE' },
       { 'category' => 'HARM_CATEGORY_SEXUALLY_EXPLICIT', 'probability' => 'NEGLIGIBLE' },
       { 'category' => 'HARM_CATEGORY_DANGEROUS_CONTENT', 'probability' => 'NEGLIGIBLE' }] }],
   'usageMetadata' => {
     'promptTokenCount' => 2,
     'candidatesTokenCount' => 8,
     'totalTokenCount' => 10
   } }]
```

#### Image

![A black and white image of an old piano. The piano is an upright model, with the keys on the right side of the image. The piano is sitting on a tiled floor. There is a small round object on the top of the piano.](https://raw.githubusercontent.com/gbaptista/assets/main/gemini-ai/piano.jpg)

> _Courtesy of [Unsplash](https://unsplash.com/photos/greyscale-photo-of-grand-piano-czPs0z3-Ggg)_

Switch to the `gemini-pro-vision` model:

```ruby
client = Gemini.new(
  credentials: { service: 'vertex-ai-api', region: 'us-east4' },
  options: { model: 'gemini-pro-vision', server_sent_events: true }
)
```

Then, encode the image as [Base64](https://en.wikipedia.org/wiki/Base64) and add its [MIME type](https://developer.mozilla.org/en-US/docs/Web/HTTP/Basics_of_HTTP/MIME_types/Common_types):

```ruby
require 'base64'

result = client.stream_generate_content(
  { contents: [
    { role: 'user', parts: [
      { text: 'Please describe this image.' },
      { inline_data: {
        mime_type: 'image/jpeg',
        data: Base64.strict_encode64(File.read('piano.jpg'))
      } }
    ] }
  ] }
)
```

The result:
```ruby
[{ 'candidates' =>
   [{ 'content' =>
      { 'role' => 'model',
        'parts' =>
        [{ 'text' =>
           ' A black and white image of an old piano. The piano is an upright model, with the keys on the right side of the image. The piano is' }] },
      'safetyRatings' =>
      [{ 'category' => 'HARM_CATEGORY_HARASSMENT', 'probability' => 'NEGLIGIBLE' },
       { 'category' => 'HARM_CATEGORY_HATE_SPEECH', 'probability' => 'NEGLIGIBLE' },
       { 'category' => 'HARM_CATEGORY_SEXUALLY_EXPLICIT', 'probability' => 'NEGLIGIBLE' },
       { 'category' => 'HARM_CATEGORY_DANGEROUS_CONTENT', 'probability' => 'NEGLIGIBLE' }] }] },
 { 'candidates' =>
   [{ 'content' => { 'role' => 'model', 'parts' => [{ 'text' => ' sitting on a tiled floor. There is a small round object on the top of the piano.' }] },
      'finishReason' => 'STOP',
      'safetyRatings' =>
      [{ 'category' => 'HARM_CATEGORY_HARASSMENT', 'probability' => 'NEGLIGIBLE' },
       { 'category' => 'HARM_CATEGORY_HATE_SPEECH', 'probability' => 'NEGLIGIBLE' },
       { 'category' => 'HARM_CATEGORY_SEXUALLY_EXPLICIT', 'probability' => 'NEGLIGIBLE' },
       { 'category' => 'HARM_CATEGORY_DANGEROUS_CONTENT', 'probability' => 'NEGLIGIBLE' }] }],
   'usageMetadata' => { 'promptTokenCount' => 263, 'candidatesTokenCount' => 50, 'totalTokenCount' => 313 } }]
```

#### Video

https://gist.github.com/assets/29520/f82bccbf-02d2-4899-9c48-eb8a0a5ef741

> ALT: A white and gold cup is being filled with coffee. The coffee is dark and rich. The cup is sitting on a black surface. The background is blurred.

> _Courtesy of [Pexels](https://www.pexels.com/video/pouring-of-coffee-855391/)_

Switch to the `gemini-pro-vision` model:

```ruby
client = Gemini.new(
  credentials: { service: 'vertex-ai-api', region: 'us-east4' },
  options: { model: 'gemini-pro-vision', server_sent_events: true }
)
```

Then, encode the video as [Base64](https://en.wikipedia.org/wiki/Base64) and add its [MIME type](https://developer.mozilla.org/en-US/docs/Web/HTTP/Basics_of_HTTP/MIME_types/Common_types):

```ruby
require 'base64'

result = client.stream_generate_content(
  { contents: [
    { role: 'user', parts: [
      { text: 'Please describe this video.' },
      { inline_data: {
        mime_type: 'video/mp4',
        data: Base64.strict_encode64(File.read('coffee.mp4'))
      } }
    ] }
  ] }
)
```

The result:
```ruby
[{"candidates"=>
   [{"content"=>
      {"role"=>"model",
       "parts"=>
        [{"text"=>
           " A white and gold cup is being filled with coffee. The coffee is dark and rich. The cup is sitting on a black surface. The background is blurred"}]},
     "safetyRatings"=>
      [{"category"=>"HARM_CATEGORY_HARASSMENT", "probability"=>"NEGLIGIBLE"},
       {"category"=>"HARM_CATEGORY_HATE_SPEECH", "probability"=>"NEGLIGIBLE"},
       {"category"=>"HARM_CATEGORY_SEXUALLY_EXPLICIT", "probability"=>"NEGLIGIBLE"},
       {"category"=>"HARM_CATEGORY_DANGEROUS_CONTENT", "probability"=>"NEGLIGIBLE"}]}],
  "usageMetadata"=>{"promptTokenCount"=>1037, "candidatesTokenCount"=>31, "totalTokenCount"=>1068}},
 {"candidates"=>
   [{"content"=>{"role"=>"model", "parts"=>[{"text"=>"."}]},
     "finishReason"=>"STOP",
     "safetyRatings"=>
      [{"category"=>"HARM_CATEGORY_HARASSMENT", "probability"=>"NEGLIGIBLE"},
       {"category"=>"HARM_CATEGORY_HATE_SPEECH", "probability"=>"NEGLIGIBLE"},
       {"category"=>"HARM_CATEGORY_SEXUALLY_EXPLICIT", "probability"=>"NEGLIGIBLE"},
       {"category"=>"HARM_CATEGORY_DANGEROUS_CONTENT", "probability"=>"NEGLIGIBLE"}]}],
  "usageMetadata"=>{"promptTokenCount"=>1037, "candidatesTokenCount"=>32, "totalTokenCount"=>1069}}]
```

### Streaming vs. Server-Sent Events (SSE)

[Server-Sent Events (SSE)](https://en.wikipedia.org/wiki/Server-sent_events) is a technology that allows certain endpoints to offer streaming capabilities, such as creating the impression that "the model is typing along with you," rather than delivering the entire answer all at once.

You can set up the client to use Server-Sent Events (SSE) for all supported endpoints:
```ruby
client = Gemini.new(
  credentials: { ... },
  options: { model: 'gemini-pro', server_sent_events: true }
)
```

Or, you can decide on a request basis:
```ruby
client.stream_generate_content(
  { contents: { role: 'user', parts: { text: 'hi!' } } },
  server_sent_events: true
)
```

With Server-Sent Events (SSE) enabled, you can use a block to receive partial results via events. This feature is particularly useful for methods that offer streaming capabilities, such as `stream_generate_content`:

```ruby
client.stream_generate_content(
  { contents: { role: 'user', parts: { text: 'hi!' } } }
) do |event, parsed, raw|
  puts event
end
```

Event:
```ruby
{ 'candidates' =>
  [{ 'content' => {
       'role' => 'model',
       'parts' => [{ 'text' => 'Hello! How may I assist you?' }]
     },
     'finishReason' => 'STOP',
     'safetyRatings' =>
     [{ 'category' => 'HARM_CATEGORY_HARASSMENT', 'probability' => 'NEGLIGIBLE' },
      { 'category' => 'HARM_CATEGORY_HATE_SPEECH', 'probability' => 'NEGLIGIBLE' },
      { 'category' => 'HARM_CATEGORY_SEXUALLY_EXPLICIT', 'probability' => 'NEGLIGIBLE' },
      { 'category' => 'HARM_CATEGORY_DANGEROUS_CONTENT', 'probability' => 'NEGLIGIBLE' }] }],
  'usageMetadata' => {
    'promptTokenCount' => 2,
    'candidatesTokenCount' => 8,
    'totalTokenCount' => 10
  } }
```

Even though streaming methods utilize Server-Sent Events (SSE), using this feature doesn't necessarily mean streaming data. For example, when `generate_content` is called with SSE enabled, you will receive all the data at once in a single event, rather than through multiple partial events. This occurs because `generate_content` isn't designed for streaming, even though it is capable of utilizing Server-Sent Events.

#### Server-Sent Events (SSE) Hang

Method calls will _hang_ until the server-sent events finish, so even without providing a block, you can obtain the final results of the received events:

```ruby
result = client.stream_generate_content(
  { contents: { role: 'user', parts: { text: 'hi!' } } },
  server_sent_events: true
)
```

Result:
```ruby
[{ 'candidates' =>
   [{ 'content' => {
        'role' => 'model',
        'parts' => [{ 'text' => 'Hello! How may I assist you?' }]
      },
      'finishReason' => 'STOP',
      'safetyRatings' =>
      [{ 'category' => 'HARM_CATEGORY_HARASSMENT', 'probability' => 'NEGLIGIBLE' },
       { 'category' => 'HARM_CATEGORY_HATE_SPEECH', 'probability' => 'NEGLIGIBLE' },
       { 'category' => 'HARM_CATEGORY_SEXUALLY_EXPLICIT', 'probability' => 'NEGLIGIBLE' },
       { 'category' => 'HARM_CATEGORY_DANGEROUS_CONTENT', 'probability' => 'NEGLIGIBLE' }] }],
   'usageMetadata' => {
     'promptTokenCount' => 2,
     'candidatesTokenCount' => 8,
     'totalTokenCount' => 10
   } }]
```

#### Non-Streaming

Depending on the service, you can use the [`generate_content`](#generate_content) method, which does not stream the answer.

You can also use methods designed for streaming without necessarily processing partial events; instead, you can wait for the result of all received events:

```ruby
result = client.stream_generate_content({
  contents: { role: 'user', parts: { text: 'hi!' } },
  server_sent_events: false
})
```

Result:
```ruby
[{ 'candidates' =>
   [{ 'content' => {
        'role' => 'model',
        'parts' => [{ 'text' => 'Hello! How may I assist you?' }]
      },
      'finishReason' => 'STOP',
      'safetyRatings' =>
      [{ 'category' => 'HARM_CATEGORY_HARASSMENT', 'probability' => 'NEGLIGIBLE' },
       { 'category' => 'HARM_CATEGORY_HATE_SPEECH', 'probability' => 'NEGLIGIBLE' },
       { 'category' => 'HARM_CATEGORY_SEXUALLY_EXPLICIT', 'probability' => 'NEGLIGIBLE' },
       { 'category' => 'HARM_CATEGORY_DANGEROUS_CONTENT', 'probability' => 'NEGLIGIBLE' }] }],
   'usageMetadata' => {
     'promptTokenCount' => 2,
     'candidatesTokenCount' => 8,
     'totalTokenCount' => 10
   } }]
```

### Back-and-Forth Conversations

To maintain a back-and-forth conversation, you need to append the received responses and build a history for your requests:

```rb
result = client.stream_generate_content(
  { contents: [
    { role: 'user', parts: { text: 'Hi! My name is Purple.' } },
    { role: 'model', parts: { text: "Hello Purple! It's nice to meet you." } },
    { role: 'user', parts: { text: "What's my name?" } }
  ] }
)
```

Result:
```ruby
[{ 'candidates' =>
   [{ 'content' =>
      { 'role' => 'model',
        'parts' => [
          { 'text' => "Purple.\n\nYou told me your name was Purple in your first message to me.\n\nIs there anything" }
        ] },
      'safetyRatings' =>
      [{ 'category' => 'HARM_CATEGORY_HARASSMENT', 'probability' => 'NEGLIGIBLE' },
       { 'category' => 'HARM_CATEGORY_HATE_SPEECH', 'probability' => 'NEGLIGIBLE' },
       { 'category' => 'HARM_CATEGORY_SEXUALLY_EXPLICIT', 'probability' => 'NEGLIGIBLE' },
       { 'category' => 'HARM_CATEGORY_DANGEROUS_CONTENT', 'probability' => 'NEGLIGIBLE' }] }] },
 { 'candidates' =>
   [{ 'content' => { 'role' => 'model', 'parts' => [{ 'text' => ' else I can help you with today, Purple?' }] },
      'finishReason' => 'STOP',
      'safetyRatings' =>
      [{ 'category' => 'HARM_CATEGORY_HARASSMENT', 'probability' => 'NEGLIGIBLE' },
       { 'category' => 'HARM_CATEGORY_HATE_SPEECH', 'probability' => 'NEGLIGIBLE' },
       { 'category' => 'HARM_CATEGORY_SEXUALLY_EXPLICIT', 'probability' => 'NEGLIGIBLE' },
       { 'category' => 'HARM_CATEGORY_DANGEROUS_CONTENT', 'probability' => 'NEGLIGIBLE' }] }],
   'usageMetadata' => {
     'promptTokenCount' => 24,
     'candidatesTokenCount' => 31,
     'totalTokenCount' => 55
   } }]
```

### Safety Settings

You can [configure safety attributes](https://cloud.google.com/vertex-ai/generative-ai/docs/multimodal/configure-safety-attributes) for your requests.

Harm Categories:
> `HARM_CATEGORY_UNSPECIFIED`, `HARM_CATEGORY_HARASSMENT`, `HARM_CATEGORY_HATE_SPEECH`, `HARM_CATEGORY_SEXUALLY_EXPLICIT`, `HARM_CATEGORY_DANGEROUS_CONTENT`.

Thresholds:
> `BLOCK_NONE`, `BLOCK_ONLY_HIGH`, `BLOCK_MEDIUM_AND_ABOVE`, `BLOCK_LOW_AND_ABOVE`, `HARM_BLOCK_THRESHOLD_UNSPECIFIED`.

Example:
```ruby
client.stream_generate_content(
  {
    contents: { role: 'user', parts: { text: 'hi!' } },
    safetySettings: [
      {
        category: 'HARM_CATEGORY_UNSPECIFIED',
        threshold: 'BLOCK_ONLY_HIGH'
      },
      {
        category: 'HARM_CATEGORY_HARASSMENT',
        threshold: 'BLOCK_ONLY_HIGH'
      },
      {
        category: 'HARM_CATEGORY_HATE_SPEECH',
        threshold: 'BLOCK_ONLY_HIGH'
      },
      {
        category: 'HARM_CATEGORY_SEXUALLY_EXPLICIT',
        threshold: 'BLOCK_ONLY_HIGH'
      },
      {
        category: 'HARM_CATEGORY_DANGEROUS_CONTENT',
        threshold: 'BLOCK_ONLY_HIGH'
      }
    ]
  }
)
```

Google started to block the usage of `BLOCK_NONE` unless:

> _User has requested a restricted HarmBlockThreshold setting BLOCK_NONE. You can get access either (a) through an allowlist via your Google account team, or (b) by switching your account type to monthly invoiced billing via this instruction: https://cloud.google.com/billing/docs/how-to/invoiced-billing_

### System Instructions

Some models support [system instructions](https://cloud.google.com/vertex-ai/generative-ai/docs/learn/prompts/system-instructions):

```ruby
client.stream_generate_content(
  { contents: { role: 'user', parts: { text: 'Hi! Who are you?' } },
    system_instruction: { role: 'user', parts: { text: 'Your name is Neko.' } } }
)
```

Output:
```text
Hi! I'm  Neko, a factual language model from Google AI.
```

```ruby
client.stream_generate_content(
  { contents: { role: 'user', parts: { text: 'Hi! Who are you?' } },
    system_instruction: {
      role: 'user', parts: [
        { text: 'You are a cat.' },
        { text: 'Your name is Neko.' }
      ]
    } }
)
```

Output:
```text
Meow! I'm Neko, a fluffy and playful cat. :3
```

### JSON Format Responses

> _As of the writing of this README, only the `vertex-ai-api` service and `gemini` models version `1.5` support this feature._

The Gemini API provides a configuration parameter to [request a response in JSON](https://ai.google.dev/gemini-api/docs/api-overview#json) format:

```ruby
require 'json'

result = client.stream_generate_content(
  {
    contents: {
      role: 'user',
      parts: {
        text: 'List 3 random colors.'
      }
    },
    generation_config: {
      response_mime_type: 'application/json'
    }

  }
)

json_string = result
              .map { |response| response.dig('candidates', 0, 'content', 'parts') }
              .map { |parts| parts.map { |part| part['text'] }.join }
              .join

puts JSON.parse(json_string).inspect
```

Output:
```ruby
{ 'colors' => ['Dark Salmon', 'Indigo', 'Lavender'] }
```

#### JSON Schema

> _As of the writing of this README, only the `vertex-ai-api` service and `gemini` models version `1.5` support this feature._

You can also provide a [JSON Schema](https://json-schema.org) for the expected JSON output:

```ruby
require 'json'

result = client.stream_generate_content(
  {
    contents: {
      role: 'user',
      parts: {
        text: 'List 3 random colors.'
      }
    },
    generation_config: {
      response_mime_type: 'application/json',
      response_schema: {
        type: 'object',
        properties: {
          colors: {
            type: 'array',
            items: {
              type: 'object',
              properties: {
                name: {
                  type: 'string'
                }
              }
            }
          }
        }
      }
    }
  }
)

json_string = result
              .map { |response| response.dig('candidates', 0, 'content', 'parts') }
              .map { |parts| parts.map { |part| part['text'] }.join }
              .join

puts JSON.parse(json_string).inspect
```

Output:

```ruby
{ 'colors' => [
  { 'name' => 'Lavender Blush' },
  { 'name' => 'Medium Turquoise' },
  { 'name' => 'Dark Slate Gray' }
] }
```

### Tools (Functions) Calling

> As of the writing of this README, only the `vertex-ai-api` service and the `gemini-pro` model [supports](https://cloud.google.com/vertex-ai/docs/generative-ai/multimodal/function-calling#supported_models) tools (functions) calls.

You can provide specifications for [tools (functions)](https://cloud.google.com/vertex-ai/docs/generative-ai/multimodal/function-calling) using [JSON Schema](https://json-schema.org) to generate potential calls to them:

```ruby
input = {
  tools: {
    function_declarations: [
      {
        name: 'date_and_time',
        description: 'Returns the current date and time in the ISO 8601 format for a given timezone.',
        parameters: {
          type: 'object',
          properties: {
            timezone: {
              type: 'string',
              description: 'A string represents the timezone to be used for providing a datetime, following the IANA (Internet Assigned Numbers Authority) Time Zone Database. Examples include "Asia/Tokyo" and "Europe/Paris". If not provided, the default timezone is the user\'s current timezone.'
            }
          }
        }
      }
    ]
  },
  contents: [
    { role: 'user', parts: { text: 'What time is it?' } }
  ]
}

result = client.stream_generate_content(input)
```

Which may return a request to perform a call:
```ruby
[{ 'candidates' =>
   [{ 'content' => {
        'role' => 'model',
        'parts' => [{ 'functionCall' => {
          'name' => 'date_and_time',
          'args' => { 'timezone' => 'local' }
        } }]
      },
      'finishReason' => 'STOP',
      'safetyRatings' =>
      [{ 'category' => 'HARM_CATEGORY_HARASSMENT', 'probability' => 'NEGLIGIBLE' },
       { 'category' => 'HARM_CATEGORY_HATE_SPEECH', 'probability' => 'NEGLIGIBLE' },
       { 'category' => 'HARM_CATEGORY_SEXUALLY_EXPLICIT', 'probability' => 'NEGLIGIBLE' },
       { 'category' => 'HARM_CATEGORY_DANGEROUS_CONTENT', 'probability' => 'NEGLIGIBLE' }] }],
   'usageMetadata' => { 'promptTokenCount' => 5, 'totalTokenCount' => 5 } }]
```

Based on these results, you can perform the requested calls and provide their outputs:
```ruby
gem 'tzinfo', '~> 2.0', '>= 2.0.6'
```

```ruby
require 'tzinfo'
require 'time'

function_calls = result.dig(0, 'candidates', 0, 'content', 'parts').filter do |part|
  part.key?('functionCall')
end

function_parts = []

function_calls.each do |function_call|
  next unless function_call['functionCall']['name'] == 'date_and_time'

  timezone = function_call.dig('functionCall', 'args', 'timezone')

  time = if !timezone.nil? && timezone != '' && timezone.downcase != 'local'
           TZInfo::Timezone.get(timezone).now
         else
           Time.now
         end

  function_output = time.iso8601

  function_parts << {
    functionResponse: {
      name: function_call['functionCall']['name'],
      response: {
        name: function_call['functionCall']['name'],
        content: function_output
      }
    }
  }
end

input[:contents] << result.dig(0, 'candidates', 0, 'content')
input[:contents] << { role: 'function', parts: function_parts }
```

This will be equivalent to the following final input:
```ruby
{ tools: { function_declarations: [
  { name: 'date_and_time',
    description: 'Returns the current date and time in the ISO 8601 format for a given timezone.',
    parameters: {
      type: 'object',
      properties: {
        timezone: {
          type: 'string',
          description: "A string represents the timezone to be used for providing a datetime, following the IANA (Internet Assigned Numbers Authority) Time Zone Database. Examples include \"Asia/Tokyo\" and \"Europe/Paris\". If not provided, the default timezone is the user's current timezone."
        }
      }
    } }
] },
  contents: [
    { role: 'user', parts: { text: 'What time is it?' } },
    { role: 'model',
      parts: [
        { functionCall: { name: 'date_and_time', args: { timezone: 'local' } } }
      ] },
    { role: 'function',
      parts: [{ functionResponse: {
        name: 'date_and_time',
        response: {
          name: 'date_and_time',
          content: '2023-12-13T21:15:11-03:00'
        }
      } }] }
  ] }
```

With the input properly arranged, you can make another request:
```ruby
result = client.stream_generate_content(input)
```

Which will result in:
```ruby
[{ 'candidates' =>
   [{ 'content' => { 'role' => 'model', 'parts' => [{ 'text' => 'It is 21:15.' }] },
      'finishReason' => 'STOP',
      'safetyRatings' =>
      [{ 'category' => 'HARM_CATEGORY_HARASSMENT', 'probability' => 'NEGLIGIBLE' },
       { 'category' => 'HARM_CATEGORY_HATE_SPEECH', 'probability' => 'NEGLIGIBLE' },
       { 'category' => 'HARM_CATEGORY_SEXUALLY_EXPLICIT', 'probability' => 'NEGLIGIBLE' },
       { 'category' => 'HARM_CATEGORY_DANGEROUS_CONTENT', 'probability' => 'NEGLIGIBLE' }] }],
   'usageMetadata' => { 'promptTokenCount' => 5, 'candidatesTokenCount' => 9, 'totalTokenCount' => 14 } }]
```

### New Functionalities and APIs

Google may launch a new endpoint that we haven't covered in the Gem yet. If that's the case, you may still be able to use it through the `request` method. For example, `stream_generate_content` is just a wrapper for `models/gemini-pro:streamGenerateContent` (Generative Language API) or `publishers/google/models/gemini-pro:streamGenerateContent` (Vertex AI API), which you can call directly like this:

```ruby
# Generative Language API
result = client.request(
  'models/gemini-pro:streamGenerateContent',
  { contents: { role: 'user', parts: { text: 'hi!' } } },
  request_method: 'POST',
  server_sent_events: true
)
```

```ruby
# Vertex AI API
result = client.request(
  'publishers/google/models/gemini-pro:streamGenerateContent',
  { contents: { role: 'user', parts: { text: 'hi!' } } },
  request_method: 'POST',
  server_sent_events: true
)
```

### Request Options

#### Adapter

To enable streaming, the gem uses [Faraday](https://github.com/lostisland/faraday) with the [Typhoeus](https://github.com/typhoeus/typhoeus) adapter by default.

You can use a different adapter if you want:

```ruby
require 'faraday/net_http'

client = Gemini.new(
  credentials: { service: 'vertex-ai-api', region: 'us-east4' },
  options: {
    model: 'gemini-pro',
    connection: { adapter: :net_http }
  }
)
```

#### Timeout

You can set the maximum number of seconds to wait for the request to complete with the `timeout` option:

```ruby
client = Gemini.new(
  credentials: { service: 'vertex-ai-api', region: 'us-east4' },
  options: {
    model: 'gemini-pro',
    connection: { request: { timeout: 5 } }
  }
)
```

You can also have more fine-grained control over [Faraday's Request Options](https://lostisland.github.io/faraday/#/customization/request-options?id=request-options) if you prefer:

```ruby
client = Gemini.new(
  credentials: { service: 'vertex-ai-api', region: 'us-east4' },
  options: {
    model: 'gemini-pro',
    connection: {
      request: {
        timeout: 5,
        open_timeout: 5,
        read_timeout: 5,
        write_timeout: 5
      }
    }
  }
)
```


### Error Handling

#### Rescuing

```ruby
require 'gemini-ai'

begin
  client.stream_generate_content({
    contents: { role: 'user', parts: { text: 'hi!' } }
  })
rescue Gemini::Errors::GeminiError => error
  puts error.class # Gemini::Errors::RequestError
  puts error.message # 'the server responded with status 500'

  puts error.payload
  # { contents: [{ role: 'user', parts: { text: 'hi!' } }],
  #   generationConfig: { candidateCount: 1 },
  #   ...
  # }

  puts error.request
  # #<Faraday::ServerError response={:status=>500, :headers...
end
```

#### For Short

```ruby
require 'gemini-ai/errors'

begin
  client.stream_generate_content({
    contents: { role: 'user', parts: { text: 'hi!' } }
  })
rescue GeminiError => error
  puts error.class # Gemini::Errors::RequestError
end
```

#### Errors

```ruby
GeminiError

MissingProjectIdError
UnsupportedServiceError
BlockWithoutServerSentEventsError

RequestError
```

## Development

```bash
bundle
rubocop -A

bundle exec ruby spec/tasks/run-client.rb
```

### Purpose

This Gem is designed to provide low-level access to Gemini, enabling people to build abstractions on top of it. If you are interested in more high-level abstractions or more user-friendly tools, you may want to consider [Nano Bots](https://github.com/icebaker/ruby-nano-bots) 💎 🤖.

### Publish to RubyGems

```bash
gem build gemini-ai.gemspec

gem signin

gem push gemini-ai-4.0.0.gem
```

### Updating the README

Install [Babashka](https://babashka.org):

```sh
curl -s https://raw.githubusercontent.com/babashka/babashka/master/install | sudo bash
```

Update the `template.md` file and then:

```sh
bb tasks/generate-readme.clj
```

Trick for automatically updating the `README.md` when `template.md` changes:

```sh
sudo pacman -S inotify-tools # Arch / Manjaro
sudo apt-get install inotify-tools # Debian / Ubuntu / Raspberry Pi OS
sudo dnf install inotify-tools # Fedora / CentOS / RHEL

while inotifywait -e modify template.md; do bb tasks/generate-readme.clj; done
```

Trick for Markdown Live Preview:
```sh
pip install -U markdown_live_preview

mlp README.md -p 8076
```

## Resources and References

These resources and references may be useful throughout your learning process.

- [Google AI for Developers](https://ai.google.dev)
- [Get started with the Gemini API ](https://ai.google.dev/docs)
- [Getting Started with the Vertex AI Gemini API with cURL](https://github.com/GoogleCloudPlatform/generative-ai/blob/main/gemini/getting-started/intro_gemini_curl.ipynb)
- [Gemini API Documentation](https://cloud.google.com/vertex-ai/docs/generative-ai/model-reference/gemini)
- [Vertex AI API Documentation](https://cloud.google.com/vertex-ai/docs/reference)
  - [REST Documentation](https://cloud.google.com/vertex-ai/docs/reference/rest)
  - [Get text embeddings](https://cloud.google.com/vertex-ai/generative-ai/docs/embeddings/get-text-embeddings)
  - [Use system instructions](https://cloud.google.com/vertex-ai/generative-ai/docs/learn/prompts/system-instructions)
  - [Configure safety attributes](https://cloud.google.com/vertex-ai/generative-ai/docs/multimodal/configure-safety-attributes)
- [Google models](https://cloud.google.com/vertex-ai/generative-ai/docs/learn/models)
  - [Model versions and lifecycle](https://cloud.google.com/vertex-ai/generative-ai/docs/learn/model-versioning)
- [Google DeepMind Gemini](https://deepmind.google/technologies/gemini/)
- [Stream responses from Generative AI models](https://cloud.google.com/vertex-ai/docs/generative-ai/learn/streaming)
- [Function calling](https://cloud.google.com/vertex-ai/docs/generative-ai/multimodal/function-calling)

## Disclaimer

This is not an official Google project, nor is it affiliated with Google in any way.

This software is distributed under the [MIT License](https://github.com/gbaptista/gemini-ai/blob/main/LICENSE). This license includes a disclaimer of warranty. Moreover, the authors assume no responsibility for any damage or costs that may result from using this project. Use the Gemini AI Ruby Gem at your own risk.
