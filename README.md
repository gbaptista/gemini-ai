# Gemini AI

A Ruby Gem for interacting with [Gemini](https://deepmind.google/technologies/gemini/) through [Vertex AI](https://cloud.google.com/vertex-ai) or [AI Studio](https://makersuite.google.com), Google's generative AI services.

![The logo shows a gemstone split into red and blue halves, symbolizing Ruby programming and Gemini AI. It's surrounded by a circuit-like design on a dark blue backdrop.](https://raw.githubusercontent.com/gbaptista/assets/main/gemini-ai/ruby-gemini-ai.png)

> _This Gem is designed to provide low-level access to Gemini, enabling people to build abstractions on top of it. If you are interested in more high-level abstractions or more user-friendly tools, you may want to consider [Nano Bots](https://github.com/icebaker/ruby-nano-bots) 💎 🤖._

## TL;DR and Quick Start

```ruby
gem 'gemini-ai', '~> 1.0'
```

```ruby
require 'gemini-ai'

# With an API key
client = Gemini.new(
  credentials: {
    service: 'generative-language-api',
    api_key: ENV['GOOGLE_API_KEY']
  },
  options: { model: 'gemini-pro', stream: false }
)

# With a Service Account
client = Gemini.new(
  credentials: {
    service: 'vertex-ai-api',
    file_path: 'google-credentials.json',
    project_id: 'PROJECT_ID',
    region: 'us-east4'
  },
  options: { model: 'gemini-pro', stream: false }
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
        - [Option 1: API Key](#option-1-api-key)
        - [Option 2: Service Account](#option-2-service-account)
        - [Required Data](#required-data)
- [Usage](#usage)
    - [Client](#client)
    - [Generate Content](#generate-content)
        - [Synchronous](#synchronous)
        - [Streaming](#streaming)
        - [Streaming Hang](#streaming-hang)
    - [Back-and-Forth Conversations](#back-and-forth-conversations)
    - [Tools (Functions) Calling](#tools-functions-calling)
    - [New Functionalities and APIs](#new-functionalities-and-apis)
- [Development](#development)
    - [Purpose](#purpose)
    - [Publish to RubyGems](#publish-to-rubygems)
    - [Updating the README](#updating-the-readme)
- [Resources and References](#resources-and-references)
- [Disclaimer](#disclaimer)

## Setup

### Installing

```sh
gem install gemini-ai -v 1.0.0
```

```sh
gem 'gemini-ai', '~> 1.0'
```

### Credentials

> ⚠️ DISCLAIMER: Be careful with what you are doing, and never trust others' code related to this. These commands and instructions alter the level of access to your Google Cloud Account, and running them naively can lead to security risks as well as financial risks. People with access to your account can use it to steal data or incur charges. Run these commands at your own responsibility and due diligence; expect no warranties from the contributors of this project.

#### Option 1: API Key

You need a [Google Cloud](https://console.cloud.google.com) [_Project_](https://cloud.google.com/resource-manager/docs/creating-managing-projects), and then you can generate an API Key through the Google Cloud Console [here](https://console.cloud.google.com/apis/credentials).

You also need to enable the _Generative Language API_ service in your Google Cloud Console, which can be done [here](https://console.cloud.google.com/apis/library/generativelanguage.googleapis.com).


Alternatively, you can generate an API Key through _Google AI Studio_ [here](https://makersuite.google.com/app/apikey). However, this approach will automatically create a project for you in your Google Cloud Account.

#### Option 2: Service Account

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

#### Required Data

After choosing an option, you should have all the necessary data and access to use Gemini.

For API Key:

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

Alternativelly, for Service Account, a `google-credentials.json` file, a `PROJECT_ID`, and a `REGION`:

```ruby
{
  service: 'vertex-ai-api',
  file_path: 'google-credentials.json',
  project_id: 'PROJECT_ID',
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
  options: { model: 'gemini-pro', stream: false }
)

# With a Service Account
client = Gemini.new(
  credentials: {
    service: 'vertex-ai-api',
    file_path: 'google-credentials.json',
    project_id: 'PROJECT_ID',
    region: 'us-east4'
  },
  options: { model: 'gemini-pro', stream: false }
)
```

### Generate Content

#### Synchronous

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

#### Streaming

You can set up the client to use streaming for all supported endpoints:
```ruby
client = Gemini.new(
  credentials: { ... },
  options: { model: 'gemini-pro', stream: true }
)
```

Or, you can decide on a request basis:
```ruby
client.stream_generate_content(
  { contents: { role: 'user', parts: { text: 'hi!' } } },
  stream: true
)
```

With streaming enabled, you can use a block to receive the results:

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

#### Streaming Hang

Method calls will _hang_ until the stream finishes, so even without providing a block, you can get the final results of the stream events:

```ruby
result = client.stream_generate_content(
  { contents: { role: 'user', parts: { text: 'hi!' } } },
  stream: true
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

### Tools (Functions) Calling

> As of the writing of this README, only the `gemini-pro` model [supports](https://cloud.google.com/vertex-ai/docs/generative-ai/multimodal/function-calling#supported_models) tools (functions) calls.

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

Google may launch a new endpoint that we haven't covered in the Gem yet. If that's the case, you may still be able to use it through the `request` method. For example, `stream_generate_content` is just a wrapper for `google/models/gemini-pro:streamGenerateContent`, which you can call directly like this:

```ruby
result = client.request(
  'streamGenerateContent',
  { contents: { role: 'user', parts: { text: 'hi!' } } }
)
```

## Development

```bash
bundle
rubocop -A
```

### Purpose

This Gem is designed to provide low-level access to Gemini, enabling people to build abstractions on top of it. If you are interested in more high-level abstractions or more user-friendly tools, you may want to consider [Nano Bots](https://github.com/icebaker/ruby-nano-bots) 💎 🤖.

### Publish to RubyGems

```bash
gem build gemini-ai.gemspec

gem signin

gem push gemini-ai-1.0.0.gem
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
- [Google DeepMind Gemini](https://deepmind.google/technologies/gemini/)
- [Stream responses from Generative AI models](https://cloud.google.com/vertex-ai/docs/generative-ai/learn/streaming)
- [Function calling](https://cloud.google.com/vertex-ai/docs/generative-ai/multimodal/function-calling)

## Disclaimer

This is not an official Google project, nor is it affiliated with Google in any way.

This software is distributed under the [MIT License](https://github.com/gbaptista/gemini-ai/blob/main/LICENSE). This license includes a disclaimer of warranty. Moreover, the authors assume no responsibility for any damage or costs that may result from using this project. Use the Gemini AI Ruby Gem at your own risk.
