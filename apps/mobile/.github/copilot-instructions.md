<!-- Use this file to provide workspace-specific custom instructions to Copilot. For more details, visit https://code.visualstudio.com/docs/copilot/copilot-customization#_use-a-githubcopilotinstructionsmd-file -->

# ShareDance - Copilot Instructions

## Project Overview
ShareDance is a Flutter mobile app for dance class management with reservation system and credits. It uses clean architecture with Bloc pattern for state management and Firebase as backend.

## Architecture Guidelines
- Follow Clean Architecture principles
- Use Bloc pattern for state management
- Organize code by features
- Separate data, domain, and presentation layers
- Use dependency injection for testability

## Code Style
- Use Dart conventions and linting rules
- Prefer const constructors when possible
- Use meaningful variable and function names
- Add proper documentation for public APIs
- Follow the established folder structure

## Firebase Integration
- Use appropriate Firebase services (Auth, Firestore, Storage, FCM)
- Handle Firebase exceptions properly
- Use streams for real-time data
- Implement proper error handling

## State Management
- Use Bloc for complex state management
- Create separate events, states, and blocs for each feature
- Use Equatable for comparing states and events
- Handle loading, success, and error states

## UI Guidelines
- Use the established design system (AppColors, AppTextStyles, AppSpacing)
- Follow Material 3 guidelines
- Make UI responsive with ScreenUtil
- Use proper error handling and loading states
- Implement proper accessibility features

## Testing
- Write unit tests for business logic
- Use bloc_test for testing blocs
- Mock external dependencies
- Test edge cases and error scenarios

## Firebase Functions
- Use TypeScript for Firebase Functions
- Implement proper validation and security rules
- Handle errors gracefully
- Use transactions for data consistency

## Security
- Validate user inputs
- Use Firebase Security Rules
- Implement proper authentication checks
- Don't expose sensitive data

## Performance
- Use pagination for large lists
- Implement proper caching strategies
- Optimize Firebase queries
- Use lazy loading when appropriate
