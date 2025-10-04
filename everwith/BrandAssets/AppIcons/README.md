# EverWith App Icon Generation

## App Icon Specification

The EverWith app icon follows these specifications:

- **Form:** Circle with subtle inner glow
- **Fill:** Gold→Sky gradient (Honey Gold #F4C35A → Sky #9EC9FF)
- **Mark:** EW monogram centered, white, 84% of safe area width, rounded terminals
- **Style:** Clean, modern, warm, respectful

## Required Sizes

### iOS
- 1024x1024 (App Store)
- 180x180 (iPhone 6 Plus, 6s Plus, 7 Plus, 8 Plus, X, XS, XS Max, 11 Pro Max, 12 Pro Max, 13 Pro Max, 14 Plus, 15 Plus)
- 167x167 (iPad Pro 12.9")
- 152x152 (iPad Pro 11")
- 120x120 (iPhone 6, 6s, 7, 8, SE 2nd gen, 12 mini, 13 mini, 14, 15)
- 87x87 (iPhone 6 Plus, 6s Plus, 7 Plus, 8 Plus, X, XS, XS Max, 11 Pro Max, 12 Pro Max, 13 Pro Max, 14 Plus, 15 Plus)
- 80x80 (iPad, iPad Air, iPad mini)
- 60x60 (iPhone 6, 6s, 7, 8, SE 2nd gen, 12 mini, 13 mini, 14, 15)

### Android
- 512x512 (Google Play Store)
- 192x192 (Android)
- 144x144 (Android)
- 96x96 (Android)
- 72x72 (Android)
- 48x48 (Android)

## Design Guidelines

1. **Gradient:** Use radial gradient from Honey Gold (#F4C35A) to Sky (#9EC9FF)
2. **Monogram:** "EW" in white, semibold weight, rounded design
3. **Glow:** Subtle inner glow from top-left
4. **Shadow:** Soft drop shadow on the monogram
5. **Accessibility:** Ensure sufficient contrast for all sizes

## Generation Methods

### Method 1: Using SwiftUI (Recommended)
Use the `AppIconView` in the project to generate icons programmatically.

### Method 2: Design Tools
- Use Figma, Sketch, or Adobe Illustrator
- Create a 1024x1024 base design
- Export at all required sizes
- Ensure crisp edges at all sizes

### Method 3: Automated Script
Run the `generate_app_icons.swift` script to generate all required sizes.

## File Naming Convention

- iOS: `AppIcon-{size}.png` (e.g., `AppIcon-1024.png`)
- Android: `ic_launcher_{size}.png` (e.g., `ic_launcher_512.png`)

## Quality Checklist

- [ ] All sizes generated
- [ ] Gradient renders correctly at all sizes
- [ ] Monogram is crisp and readable
- [ ] No pixelation or blurriness
- [ ] Consistent visual weight across sizes
- [ ] Proper contrast ratios maintained
- [ ] Tested on actual devices
