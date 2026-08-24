/// Kind of media attached to a [Product] (TASK-068): a photo rendered in
/// catalog grids/detail screens, or a short product video with basic
/// playback controls. `principal`/color-specific rules only ever apply to
/// [photo] — a video never becomes the product's cover image.
enum ProductMediaType { photo, video }
