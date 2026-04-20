# Contributing to IdentityKit

Thank you for your interest in contributing to IdentityKit. This document explains how to get started, the standards we follow, and how to submit your work.

## Getting Started

### Prerequisites

- Xcode 16 or later
- Swift 5.10+
- macOS 14 (Sonoma) or later

### Setup

```bash
git clone https://github.com/user/identity-kit.git
cd identity-kit
swift build
swift test
```

The project is a standard Swift Package. Open `Package.swift` in Xcode or use the command line.

### Demo App

The demo app lives in `DemoApp/`. Open `DemoApp/IdentityKitDemo.xcodeproj` in Xcode and make sure the IdentityKit package resolves from the local checkout (it references `../`).

## Development Workflow

1. **Fork** the repository and create a feature branch from `main`.
2. **Make your changes** in small, focused commits.
3. **Run the tests** to confirm nothing is broken: `swift test`.
4. **Open a pull request** against `main`.

### Branch Naming

Use a descriptive prefix:

| Prefix      | Purpose          |
| ----------- | ---------------- |
| `feature/`  | New functionality |
| `fix/`      | Bug fix          |
| `refactor/` | Code improvement |
| `docs/`     | Documentation    |
| `ci/`       | CI/CD changes    |

Example: `feature/add-liveness-detection`

## Code Standards

### Swift Style

- Follow the [Swift API Design Guidelines](https://www.swift.org/documentation/api-design-guidelines/).
- Use `StrictConcurrency` — all targets enable it and new code must compile cleanly.
- Prefer value types (`struct`, `enum`) over reference types where practical.
- Keep public API surface minimal; default to `internal` access.

### Commit Messages

Write clear, imperative commit messages:

```
Add document-type classifier to CaptureModule

Introduces a lightweight on-device classifier that determines
document type (passport, ID card, driver licence) from the
captured image before sending it for processing.
```

### Testing

- Every public API change should include tests.
- Tests live in `Tests/` under the corresponding test target (e.g. `IdentityKitCoreTests`).
- Use descriptive test names: `test_documentValidator_rejectsExpiredPassport()`.
- Avoid network calls in unit tests; use mocks or stubs.

### Documentation

- Add `///` doc comments to all public types and methods.
- Update `CHANGELOG.md` with a summary of your change under the `[Unreleased]` section.

## Pull Request Guidelines

- Keep PRs focused on a single concern.
- Fill in the PR template (if one exists) with a summary and test plan.
- Ensure CI passes before requesting review.
- Be responsive to review feedback.

## Reporting Issues

Open a GitHub issue with:

- A clear title describing the problem.
- Steps to reproduce.
- Expected vs. actual behaviour.
- IdentityKit version and platform (iOS/macOS).

For security vulnerabilities, see [SECURITY.md](SECURITY.md).

## Licence

By contributing, you agree that your contributions will be licensed under the same licence as the project (see [LICENSE](LICENSE)).
