# Contributing to ShaydZ AVMo

Thank you for your interest in contributing to ShaydZ AVMo! This document provides guidelines and instructions for contributing to this open-source project.

## Code of Conduct

By participating in this project, you agree to abide by our [Code of Conduct](CODE_OF_CONDUCT.md).

## How Can I Contribute?

### Reporting Bugs

- Check if the bug has already been reported in the Issues section.
- Use the bug report template when creating a new issue.
- Include detailed steps to reproduce the bug.
- Include screenshots if applicable.
- Specify your environment (iOS version, device, etc.).

### Suggesting Enhancements

- Check if the enhancement has already been suggested in the Issues section.
- Use the feature request template when creating a new issue.
- Clearly describe the feature and its benefits.
- Consider how the feature aligns with the project's goals.

### Pull Requests

1. Fork the repository.
2. Create a new branch for your changes.
3. Make your changes.
4. Write or update tests as needed.
5. Ensure all tests pass.
6. Update documentation as needed.
7. Submit a pull request.

## Development Setup

1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/ShaydZ-AVMo.git
   cd ShaydZ-AVMo
   ```

2. Open the project in Xcode:
   ```bash
   open ShaydZ-AVMo.xcodeproj
   ```

3. Install dependencies (if using CocoaPods or Swift Package Manager):
   ```bash
   # For CocoaPods
   pod install
   
   # For Swift Package Manager
   xcodebuild -resolvePackageDependencies
   ```

## Architecture Overview

ShaydZ AVMo follows the MVVM (Model-View-ViewModel) architecture and consists of the following components:

- **iOS Client**: SwiftUI-based frontend app
- **Virtual Machine Backend**: For hosting virtual Android environments
- **API Gateway**: For managing client-server communication
- **Authentication Service**: For user authentication and authorization

## Coding Standards

- Follow Swift style guide.
- Write meaningful commit messages.
- Document your code using standard documentation comments.
- Write unit tests for new features.

## Testing

- Write unit tests for models and view models.
- Write UI tests for critical user flows.
- Ensure all tests pass before submitting a pull request.

## Documentation

- Update README.md with any necessary changes.
- Document new features or changes in behavior.
- Update API documentation if applicable.

## Releasing

The release process is managed by the core team. Once your contribution is merged, it will be included in the next release according to the project's release schedule.

## License

By contributing to this project, you agree that your contributions will be licensed under the project's [MIT License](LICENSE).
