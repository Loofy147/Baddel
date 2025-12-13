# Baddel

## Performance Considerations

To ensure a smooth and responsive user experience, this application follows key Flutter performance best practices.

### Const Constructors

Stateless widgets and their properties (such as `TextStyle`, `EdgeInsets`, and `BoxDecoration`) are declared as `const` wherever possible. This allows Flutter's rendering engine to cache these widget instances and avoid unnecessary rebuilds, leading to significant improvements in UI performance. This practice is applied consistently throughout the app, particularly in UI-heavy screens like the `HomeDeckScreen`.
