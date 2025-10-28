# Everwith - Complete Feature List & Architecture

## App Overview
**Everwith** is an AI-powered photo restoration and enhancement mobile app for iOS. It provides users with various AI-powered tools to restore, merge, and transform their photos using advanced image processing technology.

---

## Core Features

### 1. AUTHENTICATION SYSTEM
**Screens:**
- **Modern Authentication View**
  - Sign in with Email/Password
  - Sign up with Email/Password  
  - Sign in with Google (OAuth)
  - Guest mode (quick access without account)
  - Password visibility toggle
  - Form validation and error handling
  - Smooth animations and modern UI

**Functionality:**
- Email/password authentication with validation
- Google Sign-In integration
- Guest mode for quick access
- Session management
- Auto-login persistence
- Secure authentication with backend API

---

### 2. ONBOARDING FLOW
**Screens:**
- **OnboardingView** (4-step carousel)
  - Welcome card: "Welcome to Everwith - Where memories come alive"
  - Photo Restore card: "Restore Old Photos"
  - Memory Merge card: "Create Together"
  - Premium card: "Unlock Premium"

**Features:**
- Progress indicator showing card position
- Smooth transitions between cards
- Photo library permission request
- Alternative: Files picker if permission denied
- Privacy Policy & Terms of Service links
- Animated entrance effects
- Guided first-time user experience

---

### 3. MAIN TAB NAVIGATION
**Custom Tab Bar** (Bottom navigation):
1. **Home Tab** - Featured flows and quick access
2. **My Memories Tab** - Gallery of created images
3. **Premium Tab** - Subscription and credit purchases
4. **Settings Tab** - Account and preferences

**Tab Bar Features:**
- Glassmorphic design
- Smooth animations
- Badge indicators
- Premium tab highlighting
- Responsive layout

---

## AI-POWERED PHOTO FLOWS

### 4. PHOTO RESTORE FLOW ⭐ PRIMARY FEATURE
**Purpose:** Restore old, faded, or damaged photos to HD quality

**Flow Steps:**
1. **Upload View**
   - Photo picker interface
   - Image preview
   - Continue button (shows credit cost)
   - Back to home option

2. **Processing View**
   - Circular progress indicator with gradient
   - Loading animation with pulsing effects
   - Progress percentage display
   - "Processing your photo..." status
   - App logo in center of progress circle
   - Shimmer effects on progress bar

3. **Result View**
   - Before/After toggle (side-by-side comparison)
   - Save to photo library
   - Share functionality
   - "Try Another" button
   - Full-screen image viewer

**Credit Cost:** 1 credit per restoration

---

### 5. MEMORY MERGE FLOW ⭐ PRIMARY FEATURE
**Purpose:** Combine two photos to create a merged image together

**Flow Steps:**
1. **Upload View**
   - Two photo upload slots (Subject A & Subject B)
   - Different upload cards for each subject
   - Image previews
   - Continue button

2. **Style Selection View**
   - 4 merge styles:
     - **Realistic:** Natural and lifelike
     - **Warm Vintage:** Nostalgic sepia tones  
     - **Soft Glow:** Gentle emotional haze
     - **Film Look:** Cinematic contrast
   - Style preview with icons and descriptions
   - Gradient indicators for each style
   - Continue button

3. **Processing View** (same as Photo Restore)

4. **Result View**
   - Merged image display
   - Save functionality
   - Share functionality  
   - "Try Another" button

**Credit Cost:** 2 credits per merge

---

### 6. TIMELINE COMPARISON FLOW
**Purpose:** "Me Then vs Me Now" - show aging progression

**Flow Steps:**
1. **Upload View**
   - Single photo selection
   - Age/timeline selection options
   - Target age specification
   
2. **Processing View**

3. **Result View**

**Credit Cost:** 2 credits (same as merge)

**Features:**
- Shows current appearance vs future/aged appearance

---

### 7. CELEBRITY FLOW
**Purpose:** "Famous Frame" - celebrity transformation effect

**Flow Steps:**
1. **Upload View**
   - Single photo selection
   - Celebrity style selection:
     - Movie Star
     - Fashion Model
     - Red Carpet
     - Magazine Cover
   
2. **Processing View**

3. **Result View**

**Credit Cost:** 2 credits

---

### 8. REUNITE FLOW
**Purpose:** "Lost Connection" - Reunite loved ones in one photo

**Flow Steps:**
1. **Upload View**
   - Multiple photo selection
   - Background prompt customization
   - Default: "warm emotional background"

2. **Processing View**

3. **Result View**

**Credit Cost:** 2 credits

**Features:**
- Combines faces of people who were never photographed together
- Customizable emotional backgrounds

---

### 9. FAMILY FLOW
**Purpose:** "Family Legacy" - Preserve family memories together

**Flow Steps:**
1. **Upload View**
   - Multiple photo selection
   - Family style options:
     - Enhanced
     - Vintage
     - Warm tones
     - Professional
   
2. **Processing View**

3. **Result View**

**Credit Cost:** 2 credits

---

## HOME SCREEN

### 10. HOME VIEW
**Layout:**
- **Header Section:**
  - Welcome message with user name
  - Credits badge showing available credits
  - Tagline: "Bring your memories to life today"

- **Get Started Section:**
  - "Choose how you'd like to transform your memories"
  - Two main feature cards:
    1. **Photo Restore Card**
       - "Make old photos HD again"
       - Icon: photo.badge.plus
       - Tap to navigate to Photo Restore Flow
   
    2. **Memory Merge Card**
       - "Bring old memories together"
       - Icon: heart.circle.fill
       - Tap to navigate to Memory Merge Flow

- **Explore AI Magic Section:**
  - 2-column grid of AI feature suggestions:
    1. Me Then vs Me Now (Timeline)
    2. Childhood Smile (Restore)
    3. Famous Frame (Celebrity)
    4. Lost Connection (Reunite)
    5. Family Legacy (Family)
  - Each card shows emoji, title, and caption
  - Images for preview

- **Go Premium Section:**
  - "Get unlimited creations with premium features"
  - Premium highlight card showing:
     - HD exports
     - Instant results
     - No watermark
     - "Cancel anytime • Secure App Store billing"

**Features:**
- Staggered entrance animations
- Recent images carousel (optional)
- Trust bar with:
  - Lock shield icon: "Your photos are private"
  - Star icon: "Rated 4.9★"
  - Photo icon: "54k+ memories"

---

## MEMORY GALLERY

### 11. MY MEMORIES VIEW
**Purpose:** Gallery of all processed/created images

**Layout:**
- **Header:** "My Memories"
- **Stats Section:** 3 stat cards showing:
  - Total Memories count
  - Restored count (restore type)
  - Merged count (merge type)

- **Grid:** 2-column grid layout
  - Image thumbnails
  - Type badge (Restored/Merged/etc)
  - Date created (relative time)
  - Tap to view full-screen

- **Actions:**
  - Clear Cache button (with confirmation alert)
  - Delete functionality
  - Share functionality
  - Save functionality

**Features:**
- AsyncImage loading with progress indicators
- Empty state view when no memories exist
- Color-coded type badges
- Relative date formatting ("2 days ago")
- Full-screen detail view on tap
- Pull-to-refresh

---

## PREMIUM & MONETIZATION

### 12. PAYWALL VIEW
**Purpose:** Subscription and credit purchase interface

**Triggers:**
- Post result (after seeing result)
- Before save (saving requires premium/credits)
- Queue priority (skip the wait)
- Credit needed (insufficient credits)
- General (from tab bar)

**Layout:**
- **Hero Section:**
  - Result preview (if triggered from result)
  - App benefits messaging
  - Animated elements

- **Features Showcase:**
  - Unlimited processing
  - Priority queue access
  - HD exports
  - No watermark
  - All AI styles unlocked

- **Pricing Section:**
  - Subscription tiers:
    - Premium Monthly: £X.XX/month
    - Premium Yearly: £XX.XX/year (best value)
  - Credit packs:
    - 5 credits
    - 15 credits (Popular)
    - 50 credits (Best value)

- **Trial Information:**
  - "Cancel anytime"
  - "Secure billing through App Store"

- **Action Buttons:**
  - "Get Premium" or "Buy Credits"
  - "Maybe Later" (dismiss)
  - "Restore Purchases"

- **Footer:**
  - Privacy Policy link
  - Terms of Service link
  - Subscription management info

**Purchase Success:**
- Shows after successful purchase
- Celebration animation
- "Welcome to Premium" messaging

---

### 13. CREDIT STORE VIEW
**Purpose:** One-time credit purchases

**Packages:**
- 5 credits - £4.99
- 15 credits - £9.99 (Popular badge)
- 50 credits - £24.99 (Best Value badge)

**Features:**
- Each package shows credits and price
- "Credits never expire" messaging
- "1 credit = 1 photo processed" explanation
- "Use for any photo mode"
- "No subscription required"

**Layout:**
- Hero icon with credits symbol
- Package cards with selection state
- Benefits list
- Purchase button

---

## SETTINGS

### 14. SETTINGS VIEW
**Sections:**

**Account Section:**
- Email display
- Current plan (Free/Premium)
- Credit balance
- Sign in button (if not logged in)

**Subscription Section:**
- Upgrade to Premium
- Restore Purchases

**Preferences Section:**
- Dark Mode toggle
- Notifications toggle

**Support Section:**
- Contact Support
- Report Bug
- Send Feedback

**Legal Section:**
- Privacy Policy (full text)
- Terms of Service (full text)
- Delete Account (with confirmation)

**Version Section:**
- Version number
- Build number

**Sign Out:**
- Sign out button with confirmation alert

---

## FEEDBACK

### 15. FEEDBACK VIEW
**Purpose:** Contact support and send feedback

**Quick Actions:**
- Contact Support (email)
- Report a Bug (with template)
- Send Feedback
- Rate in App Store

**Features:**
- Feedback type selection
- Text input area
- Submit button
- Success state
- Email composer integration

---

## RECURRING COMPONENTS

### Progress Animation
- Circular progress with gradient ring
- Pulsing animation
- Progress percentage
- Loading dots animation
- "Processing..." status text
- Queue mode with estimated time
- Premium upsell for queue skipping

### Before/After Toggle
- Slider or button toggle
- Label overlay ("Before"/"After")
- Smooth transitions
- Full-screen image display

### Upload Cards
- Dashed border style
- Plus icon when empty
- Image preview when selected
- Tap to select photo
- Multiple upload slots for merge flows

### Continue Button
- Shows credit cost for free users
- Diamond icon with credit count
- Gradient background
- Disabled when no selection
- Primary CTA in flows

### Result Action Buttons
- Save Photo button (with state: saved/unsaved)
- Share button
- Try Another button

---

## NAVIGATION FLOW

```
App Launch
  ↓
Onboarding (first time only)
  ↓
Authentication Check
  ├─→ Guest Access
  ├─→ Signed In
  └─→ Sign In Prompt
  ↓
MainTabView
  ├─→ Home
  │   ├─→ Photo Restore Flow
  │   ├─→ Memory Merge Flow
  │   ├─→ Timeline Comparison Flow
  │   ├─→ Celebrity Flow
  │   ├─→ Reunite Flow
  │   └─→ Family Flow
  │
  ├─→ My Memories
  │   └─→ Detail View
  │
  ├─→ Premium
  │   ├─→ PaywallView
  │   └─→ Purchase Success
  │
  └─→ Settings
      ├─→ Credit Store
      ├─→ Feedback
      └─→ Auth View
```

---

## MONETIZATION MODEL

### Credit System
- **Free users:** Limited credits (trial credits)
- **Credit costs:**
  - Photo Restore: 1 credit
  - Memory Merge: 2 credits
  - All other AI features: 2 credits
- **One-time purchases available**
- **Credits never expire**

### Subscription Model
- **Premium Monthly:** Unlimited access
- **Premium Yearly:** Best value
- **Features:**
  - Unlimited processing
  - Priority queue (no waiting)
  - HD exports
  - No watermarks
  - All AI styles
  - Premium-only features

### Queue System
- Free users: Process in queue (estimated wait time)
- Premium users: Immediate processing
- Queue upsell: "Skip the wait" button

---

## TECHNICAL STACK

### Frontend
- SwiftUI
- iOS 15.0+
- RevenueCat (in-app purchases)
- Google Sign-In SDK
- PhotosPicker
- UIKit integration (for some views)

### Backend
- Python (FastAPI)
- PostgreSQL database
- Image processing service
- Authentication API
- Subscription management API
- Image upload/processing endpoints

### Key Services
- **MonetizationManager:** Handles credits, subscriptions, queue
- **ImageProcessingService:** Uploads, processes images
- **AuthenticationService:** Login, signup, session management
- **RevenueCatService:** In-app purchases, subscription status
- **SessionManager:** User session state

---

## UI/UX DESIGN SYSTEM

### Colors
- **Deep Plum:** Primary text color
- **Soft Plum:** Secondary text color
- **Blush Pink to Rose Magenta:** Primary brand gradient
- **Honey Gold:** Premium highlighting
- **Card Shadow:** Soft shadows

### Typography
- **Headers:** Bold, Rounded design, 28-32pt
- **Body:** Regular/Medium, 16-17pt
- **Captions:** Medium, 14pt
- **Small:** Regular, 12-13pt

### Animations
- Spring animations (response: 0.6, damping: 0.8)
- Staggered entrance effects
- Scale and opacity transitions
- Pulsing effects on progress indicators
- Smooth page transitions

### Responsive Design
- Adaptive spacing based on screen size
- Adaptive font sizes (min/max scaling)
- Safe area handling
- Small screen optimizations

---

## FEATURES BY SCREEN

### Home Screen
- Welcome header with user greeting
- Credits display
- Two primary feature cards (Restore & Merge)
- AI Magic exploration grid (5 features)
- Premium CTA section
- Trust indicators

### My Memories Screen
- Stats overview (Total, Restored, Merged)
- 2-column image grid
- Empty state handling
- Detail view sheet
- Cache management

### Premium Screen
- Hero section with preview
- Features list
- Pricing tables (subscription + credits)
- Trial information
- Action buttons
- Legal links
- Restore purchases

### Settings Screen
- Account information
- Subscription status
- Preferences toggles
- Support links
- Legal documents
- Version info
- Sign out

### Authentication Screen
- Email/password forms
- Google Sign-In
- Guest mode
- Password visibility toggle
- Form validation
- Error handling

---

## USER JOURNEY EXAMPLES

### Journey 1: First-Time Photo Restore
1. Launch app
2. Complete onboarding
3. Grant photo permissions
4. Land on Home screen
5. Tap "Photo Restore" card
6. Select photo from library
7. See credit cost (1 credit)
8. Tap "Continue" (or purchase credits if needed)
9. View processing animation
10. See result with before/after toggle
11. Save or share the restored photo

### Journey 2: Memory Merge
1. From Home, tap "Memory Merge"
2. Upload Subject A photo
3. Upload Subject B photo
4. Select merge style
5. Process (costs 2 credits)
6. View merged result
7. Save to library
8. Share with family

### Journey 3: Upgrade to Premium
1. Try to process photo
2. See "Insufficient credits" paywall
3. View Premium benefits
4. Select Premium Monthly or Yearly
5. Complete purchase via App Store
6. See success screen
7. Return to processing with unlimited access

---

## API ENDPOINTS (Backend)

### Authentication
- POST `/api/auth/register`
- POST `/api/auth/login`
- POST `/api/auth/google`
- GET `/api/auth/me`

### Image Processing
- POST `/api/v1/upload`
- POST `/api/v1/restore`
- POST `/api/v1/together`
- POST `/api/v1/timeline`
- POST `/api/v1/celebrity`
- POST `/api/v1/reunite`
- POST `/api/v1/family`

### History
- GET `/api/v1/images` (with pagination)

---

## DATA MODELS

### User
- id, email, name, profileImageURL, provider, createdAt

### ProcessedImage
- id, userId, imageType, originalImageUrl, processedImageUrl, createdAt

### Subscription
- tier, status, startDate, endDate

### Credits
- userId, creditsRemaining, totalCredits

---

## CONFIGURATION

### Environments
- Development (localhost:8000 on simulator)
- Production (Heroku URL)

### Feature Flags
- Queue system toggle
- Premium features access control
- Google Sign-In availability

---

## ANALYTICS & TRACKING

### Events Tracked
- First photo upload
- First result viewed
- Feature usage (restore, merge, etc.)
- Purchase events
- Save events
- Share events
- Credit purchases
- Subscription events

---

This document provides a comprehensive overview of all features, flows, screens, and functionality in the Everwith app.

