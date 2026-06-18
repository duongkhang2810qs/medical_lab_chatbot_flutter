# Blood Test Assistant

A Flutter application for scanning blood test reports, reviewing OCR-extracted indicators, and receiving AI-assisted explanations through a conversational interface.

The project follows a feature-first, layered architecture to keep presentation, domain logic, infrastructure, configuration, and reusable UI components clearly separated.

> [!IMPORTANT]
> This application is intended for informational and educational use only. It must not be used as a substitute for diagnosis, treatment, or advice from a qualified healthcare professional.

## Table of Contents

- [Overview](#overview)
- [Key Features](#key-features)
- [Architecture](#architecture)
- [Project Structure](#project-structure)
- [Technology Stack](#technology-stack)
- [Prerequisites](#prerequisites)
- [Getting Started](#getting-started)
- [Runtime Configuration](#runtime-configuration)
- [Backend API Contract](#backend-api-contract)
- [Code Quality](#code-quality)
- [Testing](#testing)
- [Error Handling](#error-handling)
- [Security and Privacy](#security-and-privacy)
- [Known Limitations](#known-limitations)
- [Contributing](#contributing)
- [License](#license)

## Overview

Blood Test Assistant provides a guided workflow for processing laboratory reports:

1. Scan a document or select an image from the device gallery.
2. Upload the image to the OCR service.
3. Review and correct the extracted indicators, units, and reference ranges.
4. Confirm the data and request an AI-generated analysis.
5. Continue the conversation with follow-up questions in the same session.

The application keeps each conversation isolated through a UUID-based session identifier and displays AI responses using Markdown formatting.

## Key Features

- Document scanning with automatic page boundary detection.
- Image import from the device gallery.
- OCR extraction through a multipart HTTP API.
- Editable blood-test indicators before submission.
- Automatic `Low`, `Normal`, and `High` status calculation.
- Medical unit suggestions based on a local ontology.
- AI-assisted analysis of confirmed laboratory indicators.
- Session-based conversational follow-up.
- Markdown rendering for structured responses.
- Confirmed-data drawer for quick reference.
- Centralized API configuration and request timeouts.
- User-friendly handling of timeouts, network failures, invalid JSON, and non-success HTTP responses.

## Architecture

The codebase uses a **feature-first layered architecture**.

```text
Presentation
    ↓
Controller / State Management
    ↓
Domain Models
    ↓
Data Services
    ↓
Remote APIs and Device Services
```

### Layers

| Layer | Responsibility |
| --- | --- |
| `core` | Shared configuration, theme, colors, exceptions, and utilities. |
| `domain` | Business entities and domain-specific rules. |
| `data` | HTTP clients, OCR integration, and device image acquisition. |
| `presentation` | Screens, widgets, controllers, and user interaction. |

### Design Principles

- Single responsibility for classes and files.
- Dependency injection through constructors where practical.
- Immutable public collections exposed by controllers.
- Centralized exception mapping for infrastructure failures.
- Feature isolation to reduce coupling between chat and OCR modules.
- Small reusable widgets instead of large screen files.

## Project Structure

```text
lib/
├── main.dart
├── app.dart
├── core/
│   ├── config/
│   │   └── app_config.dart
│   ├── constants/
│   │   └── app_colors.dart
│   ├── errors/
│   │   └── app_exception.dart
│   ├── theme/
│   │   └── app_theme.dart
│   └── utils/
│       └── status_color.dart
└── features/
    ├── chat/
    │   ├── data/
    │   │   └── services/
    │   │       └── chat_api_service.dart
    │   ├── domain/
    │   │   └── models/
    │   │       └── chat_message.dart
    │   └── presentation/
    │       ├── controllers/
    │       │   └── chat_controller.dart
    │       ├── pages/
    │       │   └── chat_screen.dart
    │       └── widgets/
    │           ├── chat_input_area.dart
    │           ├── chat_message_bubble.dart
    │           └── confirmed_data_drawer.dart
    └── ocr/
        ├── data/
        │   └── services/
        │       ├── document_image_service.dart
        │       └── ocr_api_service.dart
        ├── domain/
        │   ├── models/
        │   │   └── ocr_item.dart
        │   └── ontology/
        │       └── medical_ontology.dart
        └── presentation/
            ├── pages/
            │   └── ocr_review_screen.dart
            └── widgets/
                └── ocr_item_card.dart
```

## Technology Stack

- Flutter and Dart.
- `http` for REST and multipart requests.
- `uuid` for conversation session identifiers.
- `google_mlkit_document_scanner` for document scanning.
- `image_picker` for gallery image selection.
- `flutter_markdown` for rendering assistant responses.

The corresponding packages must be declared in the project's `pubspec.yaml`.

## Prerequisites

Before running the application, ensure that the following are available:

- A current stable Flutter SDK.
- A configured Android or iOS development environment.
- A physical device or supported emulator.
- A reachable OCR backend service.
- A reachable chat and analysis backend service.

Verify the local Flutter installation:

```bash
flutter doctor
```

## Getting Started

### 1. Install dependencies

From the project root, run:

```bash
flutter pub get
```

### 2. Verify the project

```bash
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
```

If the project does not yet contain a `test/` directory, run formatting against `lib` only and add tests before production release.

### 3. Configure the backend host

The application reads the backend IP address from the `API_IP` compile-time variable. See [Runtime Configuration](#runtime-configuration).

### 4. Run the application

```bash
flutter run --dart-define=API_IP=192.168.1.10
```

The mobile device and backend services must be able to reach each other over the network.

## Runtime Configuration

Configuration is centralized in:

```text
lib/core/config/app_config.dart
```

The current service layout is:

| Service | Base URL |
| --- | --- |
| OCR | `http://<API_IP>:8001/api/v1` |
| Chat and analysis | `http://<API_IP>:8002/api/v1` |

The default development IP is defined in source code. Override it without modifying the code:

```bash
flutter run --dart-define=API_IP=192.168.1.10
```

Release examples:

```bash
flutter build apk --release \
  --dart-define=API_IP=192.168.1.10
```

```bash
flutter build ios --release \
  --dart-define=API_IP=192.168.1.10
```

> [!WARNING]
> `dart-define` values are compile-time configuration, not secret storage. Never place API keys, passwords, private tokens, or other credentials in the mobile application.

## Backend API Contract

The Flutter client expects three backend endpoints.

### Send a chat message

```http
POST /api/v1/chat
Content-Type: application/json; charset=UTF-8
```

Request:

```json
{
  "text": "What does a high WBC value mean?",
  "session_id": "uuid-session-id"
}
```

Successful response:

```json
{
  "status": "success",
  "answer": "Markdown-formatted assistant response"
}
```

### Analyze confirmed indicators

```http
POST /api/v1/analyze
Content-Type: application/json; charset=UTF-8
```

Request:

```json
{
  "session_id": "uuid-session-id",
  "indicators": [
    {
      "test_name": "WBC",
      "value": "8.5",
      "unit": "10^9/L",
      "ref_range": {
        "ref_min": 4.0,
        "ref_max": 10.0
      },
      "status": "Normal"
    }
  ]
}
```

Successful response:

```json
{
  "status": "success",
  "summary": "Markdown-formatted analysis"
}
```

### Extract indicators from an image

```http
POST /api/v1/extract
Content-Type: multipart/form-data
```

Multipart field:

| Field | Type | Description |
| --- | --- | --- |
| `file` | File | Blood-test report image. |

Successful response:

```json
{
  "status": "success",
  "ocr_table": [
    {
      "test_name": "WBC",
      "value": "8.5",
      "unit": "10^9/L",
      "ref_range": {
        "ref_min": 4.0,
        "ref_max": 10.0
      }
    }
  ]
}
```

For an application-level failure, the services are expected to return a JSON object containing:

```json
{
  "status": "error",
  "message": "Human-readable error description"
}
```

## Code Quality

Recommended checks before opening a pull request:

```bash
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
```

Suggested repository-level quality controls:

- Enable stricter rules in `analysis_options.yaml`.
- Run formatting, static analysis, and tests in CI.
- Require reviewed pull requests before merging.
- Keep infrastructure code behind services or repositories.
- Avoid business logic directly inside widgets.
- Keep public APIs documented and intentionally small.

## Testing

Automated tests are not included in this refactored `lib` package. A production project should add coverage for the following areas.

### Unit tests

- `OcrItem.recalculateStatus()` boundary conditions.
- JSON serialization and deserialization.
- `ChatController` loading and message transitions.
- Error mapping in API services.
- Session reset behavior.

### Widget tests

- Message bubble rendering.
- Input controls while requests are in progress.
- OCR row editing and deletion.
- Confirmed-data drawer output.
- Navigation between chat and OCR review screens.

### Integration tests

- Gallery and scanner workflows.
- OCR upload and review flow.
- Confirm-and-analyze flow.
- New-conversation reset flow.

HTTP clients and services are constructor-injected where practical, which allows test doubles to be supplied without changing UI code.

## Error Handling

The data services translate common infrastructure failures into user-facing application errors, including:

- Request timeout.
- Socket and network failure.
- Interrupted HTTP connection.
- Non-2xx HTTP status code.
- Invalid JSON response.
- Unexpected response structure.
- Backend responses whose `status` is not `success`.

Current request timeouts are defined in `AppConfig`:

| Request | Timeout |
| --- | --- |
| OCR extraction | 30 seconds |
| Chat and analysis | 90 seconds |

## Security and Privacy

Laboratory reports may contain personal and sensitive health information. Before deploying the application, consider the following controls:

- Use HTTPS for all API communication.
- Add authentication and authorization to backend services.
- Avoid logging report images, extracted values, or assistant conversations.
- Define retention and deletion policies for uploaded images and generated analyses.
- Encrypt sensitive data at rest on the server.
- Validate file type, size, and content on the backend.
- Apply request limits and abuse protection.
- Obtain appropriate user consent before processing health data.
- Review applicable healthcare and privacy regulations in the deployment region.
- Provide a clear privacy policy and medical disclaimer.

The color-based status shown by the application is calculated from user-reviewed reference ranges. It must not be interpreted as a diagnosis.

## Known Limitations

- The client currently supports a single scanned page per OCR request.
- API hosts and ports are fixed except for the `API_IP` value.
- The application uses `ChangeNotifier` rather than a dedicated state-management package.
- Authentication is not implemented in the provided client code.
- Offline persistence and retry queues are not implemented.
- Automated tests are not included in this refactored package.
- User-facing application text is currently Vietnamese.

## Contributing

1. Create a branch from the main development branch.
2. Keep changes focused and aligned with the existing architecture.
3. Add or update tests for behavioral changes.
4. Run formatting, static analysis, and tests locally.
5. Open a pull request with a clear description and verification steps.

Example branch names:

```text
feature/ocr-history
fix/chat-timeout-message
refactor/api-client
```

Use clear, imperative commit messages where possible:

```text
feat: add OCR history screen
fix: preserve messages after request failure
refactor: isolate chat API response parsing
```

## License

No license file is included in this package. Add an appropriate `LICENSE` file before publishing, distributing, or accepting external contributions.
