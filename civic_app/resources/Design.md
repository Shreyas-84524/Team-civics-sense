# CivicFix — Design System

**Version:** 1.0
**Status:** Design Specification
**Project:** CivicFix
**Platforms:** Flutter Mobile + Flutter Web
**Design System:** CivicFix Design System
**Primary Audience:** Citizens
**Secondary Audience:** Government / Organization Users

---

# 1. Design Overview

CivicFix is designed as a trustworthy, accessible, modern civic platform that connects citizens with government organizations.

The visual language should communicate:

* Trust
* Reliability
* Transparency
* Civic responsibility
* Simplicity
* Accessibility
* Progress
* Community participation

The design must avoid looking overly corporate, governmental, or bureaucratic.

Instead, CivicFix should feel:

> **Modern enough for citizens, professional enough for government, and simple enough for everyone.**

---

# 2. Design Philosophy

The CivicFix interface should follow five primary principles.

## 2.1 Trust

The interface should immediately communicate that CivicFix is reliable.

Deep Navy is used as the primary trust color.

---

## 2.2 Clarity

Citizens should understand what they need to do without reading lengthy instructions.

Important actions should be visually obvious.

Example:

```text
Report an Issue
```

should be easier to find than secondary actions.

---

## 2.3 Transparency

The complaint lifecycle should be visually clear.

The user should always understand:

```text
What happened?
What is happening?
What happens next?
```

---

## 2.4 Accessibility

CivicFix may be used by people with different:

* Ages
* Technical abilities
* Languages
* Devices
* Internet connectivity

Therefore, the interface must prioritize readability and simplicity.

---

## 2.5 Civic Positivity

The interface should encourage constructive participation rather than making civic problems feel negative or bureaucratic.

The Fresh Mint accent helps communicate progress and positive action.

---

# 3. Brand Personality

CivicFix should feel:

| Attribute       | Direction   |
| --------------- | ----------- |
| Trustworthy     | High        |
| Professional    | High        |
| Friendly        | Medium-High |
| Modern          | High        |
| Minimal         | High        |
| Government-like | Medium      |
| Playful         | Low-Medium  |
| Technical       | Low         |
| Aggressive      | Very Low    |

The product should feel serious about civic problems without feeling intimidating.

---

# 4. Color Palette

The CivicFix primary palette is:

| Role       | Name        | Hex       |
| ---------- | ----------- | --------- |
| Primary    | Deep Navy   | `#12304A` |
| Secondary  | Civic Green | `#2E8B57` |
| Accent     | Fresh Mint  | `#7ED6A5` |
| Background | Off White   | `#F7F9F7` |
| Alert      | Amber       | `#F4B942` |

---

# 5. Primary Color — Deep Navy

```text
#12304A
```

Deep Navy is the primary CivicFix brand color.

## Use for

* Primary buttons.
* App bar elements.
* Navigation.
* Important headings.
* Active navigation states.
* Primary icons.
* Key branding elements.
* Government dashboard navigation.
* Authentication screens.

## Design meaning

Deep Navy represents:

* Trust.
* Stability.
* Authority.
* Reliability.
* Professionalism.

---

# 6. Secondary Color — Civic Green

```text
#2E8B57
```

Civic Green represents civic action and positive progress.

## Use for

* Success states.
* Resolved complaints.
* Positive actions.
* Progress indicators.
* Secondary buttons.
* Active status indicators.
* Confirmation messages.
* Civic participation elements.

## Design meaning

Civic Green represents:

* Growth.
* Action.
* Community.
* Progress.
* Resolution.

---

# 7. Accent Color — Fresh Mint

```text
#7ED6A5
```

Fresh Mint is used as a supporting accent.

## Use for

* Highlights.
* Selected cards.
* Subtle backgrounds.
* Achievement badges.
* Progress backgrounds.
* Map highlights.
* Decorative elements.
* Secondary visual emphasis.

Fresh Mint should generally **not replace Deep Navy for primary text or primary buttons**.

It should be used to add visual freshness without overwhelming the interface.

---

# 8. Background Color — Off White

```text
#F7F9F7
```

Off White is the primary application background.

## Use for

* Main application backgrounds.
* Screen backgrounds.
* Dashboard backgrounds.
* Empty spaces.
* Content areas.

The purpose is to create a softer appearance than pure white.

Avoid making every surface pure white.

---

# 9. Alert Color — Amber

```text
#F4B942
```

Amber communicates attention rather than failure.

## Use for

* Warnings.
* Pending actions.
* Pending synchronization.
* Attention-required states.
* Important notices.
* Offline indicators.

Amber should not be used as the default error color.

---

# 10. Supporting Colors

The five primary brand colors should remain dominant.

However, functional interfaces require additional neutral and semantic colors.

Recommended supporting colors:

| Role           | Suggested Color |
| -------------- | --------------- |
| Primary Text   | `#17212B`       |
| Secondary Text | `#5F6B73`       |
| Disabled Text  | `#9AA3A8`       |
| Border         | `#D9E0DC`       |
| Card           | `#FFFFFF`       |
| Error          | `#C62828`       |
| Success        | `#2E8B57`       |
| Warning        | `#F4B942`       |
| Info           | `#2F6F95`       |

These colors should support the brand palette rather than compete with it.

---

# 11. Color Usage Ratio

A recommended visual balance is:

```text
Off White / Neutral Background
        ↓
      ~60%

White / Neutral Surfaces
        ↓
      ~20%

Deep Navy
        ↓
      ~10%

Civic Green
        ↓
       ~6%

Fresh Mint
        ↓
       ~3%

Amber / Functional Colors
        ↓
       ~1%
```

These percentages are guidelines, not strict implementation requirements.

The interface should remain predominantly light and calm.

---

# 12. Color Hierarchy

The hierarchy should generally follow:

```text
Deep Navy
     ↓
Civic Green
     ↓
Fresh Mint
     ↓
Amber
```

Deep Navy should remain the strongest brand signal.

Civic Green should communicate positive action.

Fresh Mint should provide visual softness.

Amber should attract attention only when necessary.

---

# 13. Typography

CivicFix should use a clean, highly readable sans-serif typeface.

Recommended primary font:

```text
Inter
```

Alternative:

```text
Roboto
```

The final font should be configured centrally through the Flutter theme.

---

# 14. Typography Hierarchy

Recommended hierarchy:

| Style      |    Size | Weight    |
| ---------- | ------: | --------- |
| Display    |    32px | Bold      |
| H1         |    28px | Bold      |
| H2         |    24px | Semi-Bold |
| H3         |    20px | Semi-Bold |
| Body Large |    18px | Regular   |
| Body       |    16px | Regular   |
| Body Small |    14px | Regular   |
| Caption    |    12px | Regular   |
| Button     | 15–16px | Semi-Bold |

These values can be adjusted slightly depending on platform.

---

# 15. Typography Rules

## Headings

Use Deep Navy.

Example:

```text
My Complaints
```

## Body text

Use Primary Text.

## Supporting information

Use Secondary Text.

## Important status

Use semantic colors where appropriate.

Avoid using multiple bright colors simply to make text stand out.

---

# 16. Spacing System

CivicFix should use an 8-point spacing system.

Recommended values:

```text
4px
8px
12px
16px
24px
32px
40px
48px
64px
```

---

# 17. Standard Spacing

### Screen padding

```text
16px
```

Mobile screens may use:

```text
16px – 20px
```

### Card padding

```text
16px
```

### Section spacing

```text
24px
```

### Major section spacing

```text
32px
```

---

# 18. Border Radius

CivicFix should use moderately rounded components.

Recommended values:

```text
Small elements: 8px
Cards: 12px
Buttons: 10px
Large containers: 16px
Bottom sheets: 20px
```

Avoid excessive pill-shaped interfaces unless they serve a specific purpose.

---

# 19. Elevation and Shadows

The interface should use subtle elevation.

Cards should generally use:

* Low elevation.
* Soft shadows.
* Clear separation from the background.

Avoid heavy shadows.

The visual language should feel lightweight and modern.

---

# 20. Cards

Cards are an important component for:

* Complaints.
* Dashboard statistics.
* Rewards.
* Notifications.
* Hazard information.

Recommended structure:

```text
┌──────────────────────────────┐
│ Category                     │
│                              │
│ Large pothole near entrance  │
│                              │
│ In Progress                  │
│                              │
│ Updated 2 hours ago          │
└──────────────────────────────┘
```

Cards should use:

```text
Background: #FFFFFF
Border Radius: 12px
Padding: 16px
```

---

# 21. Buttons

Buttons should communicate clear hierarchy.

## Primary Button

Background:

```text
#12304A
```

Text:

```text
#FFFFFF
```

Example:

```text
+ Report an Issue
```

---

## Secondary Button

Possible treatment:

```text
Background: transparent
Border: #12304A
Text: #12304A
```

---

## Success Button

Use Civic Green when the action represents successful completion or confirmation.

```text
#2E8B57
```

---

## Disabled Button

Use muted neutral colors.

Disabled controls should not look interactive.

---

# 22. Button Shape

Recommended:

```text
Height: 48px
Radius: 10px
Horizontal Padding: 20px
```

For important mobile actions, 48px should be treated as the minimum comfortable touch target.

---

# 23. Floating Action Button

The citizen Home screen may use a prominent Report Issue action.

Example:

```text
        ┌──────────────┐
        │ + Report     │
        │    Issue     │
        └──────────────┘
```

The FAB/action may use Deep Navy or Civic Green depending on surrounding context.

The action should remain visually prominent without covering navigation or important content.

---

# 24. App Bar

The standard app bar should use:

```text
Background: #12304A
```

Text:

```text
#FFFFFF
```

Icons:

```text
#FFFFFF
```

Example:

```text
←   My Complaints
```

For lighter screens, a white/Off White app bar may be used where appropriate, but Deep Navy should remain the primary brand treatment.

---

# 25. Bottom Navigation

Citizen navigation:

```text
Home
Complaints
Map
Notifications
Profile
```

Recommended styling:

```text
Background: #FFFFFF
Active: #12304A
Inactive: #5F6B73
```

A subtle Fresh Mint highlight can be used behind the active icon if needed.

---

# 26. Navigation States

## Active

Use:

```text
Deep Navy
```

## Inactive

Use:

```text
Secondary Text
```

## Notification Badge

Use a semantic alert color where appropriate.

Do not make every notification badge Amber.

---

# 27. Complaint Status Colors

Status colors should be semantically consistent.

| Status      | Color       |
| ----------- | ----------- |
| Reported    | Deep Navy   |
| Verified    | Civic Green |
| Assigned    | Info Blue   |
| In Progress | Amber       |
| Resolved    | Civic Green |

The exact visual treatment may use icons and labels in addition to color.

---

# 28. Complaint Tracker

The tracker should be one of the strongest visual elements in the application.

Example:

```text
✓ Reported
│
✓ Verified
│
✓ Assigned
│
● In Progress
│
○ Resolved
```

Completed states:

```text
Civic Green
```

Current state:

```text
Deep Navy
```

Pending state:

```text
Neutral Gray
```

Attention state:

```text
Amber
```

---

# 29. Do Not Rely Only on Color

A complaint status must always include:

* Text.
* Icon or indicator.
* Position in tracker.

Example:

```text
✓ Resolved
```

rather than displaying only a green dot.

This improves accessibility.

---

# 30. Complaint Card Design

A complaint card should contain:

```text
Category
Complaint Title
Location
Status
Last Updated
Complaint ID
```

Example:

```text
ROADS

Large pothole near main entrance

📍 Main Road

● In Progress

Updated 2 hours ago

CF-2026-000001
```

---

# 31. Report Issue Screen

The Report Issue screen should prioritize simplicity.

Recommended order:

```text
Title
↓
Category
↓
Description
↓
Image
↓
Location
↓
Review
↓
Submit
```

Do not overload the screen with unnecessary fields.

---

# 32. Report Issue CTA

Primary action:

```text
Submit Complaint
```

Use Deep Navy.

The button should remain disabled until mandatory fields are valid.

---

# 33. Image Upload Component

Recommended design:

```text
┌──────────────────────────────┐
│                              │
│        + Add Photo           │
│                              │
│     Camera / Gallery         │
│                              │
└──────────────────────────────┘
```

After selection:

```text
┌─────────┐
│ Image   │
│ Preview │
└─────────┘
```

Include a remove/retry action.

---

# 34. Location Component

The location component should communicate clearly whether a valid location has been selected.

### Not selected

```text
📍 Select Location
```

### Selected

```text
📍 Main Road, Mumbai

Location confirmed
```

Use Civic Green for confirmation.

---

# 35. Home Screen

The citizen Home screen should immediately communicate the application's purpose.

Recommended structure:

```text
Good morning!

What would you like to report?

┌─────────────────────────────┐
│                             │
│       Report an Issue       │
│                             │
└─────────────────────────────┘

Your Complaints

[ Complaint Card ]

Nearby Hazards

[ Map Preview ]

Your Civic Progress

[ Points / Achievement ]
```

---

# 36. Dashboard Greeting

The greeting should be friendly but concise.

Example:

```text
Good morning, Shreyas
```

Avoid excessive decorative copy.

---

# 37. Government Dashboard

The government dashboard should prioritize information density while remaining easy to scan.

Recommended layout:

```text
Dashboard
──────────────────────────────

Total       Reported
120         24

Verified    Assigned
31          28

In Progress Resolved
17          20

Recent Complaints
──────────────────────────────

Complaint Table

──────────────────────────────

Hazard Map
```

---

# 38. Government Data Visualization

Charts should use the CivicFix palette.

Preferred hierarchy:

```text
Deep Navy
Civic Green
Fresh Mint
Amber
```

Avoid using many unrelated colors.

Charts should include:

* Labels.
* Legends where necessary.
* Tooltips.
* Accessible text equivalents where practical.

---

# 39. Government Complaint Table

The web interface may use a table for efficient management.

Columns may include:

```text
Complaint ID
Category
Location
Status
Priority
Department
Created
Updated
Action
```

The table should support:

* Sorting where useful.
* Filtering.
* Pagination.

---

# 40. Government Complaint Details

Recommended structure:

```text
Complaint ID

Title
Description

Evidence

Location

Citizen Information
[Only information authorized users need]

Department

Status

History

Actions
```

Government users should see only information required for their authorized responsibilities.

---

# 41. Assignment UI

Assignment should be simple.

Example:

```text
Department

[ Roads Department ▼ ]

Assigned To

[ Select User ▼ ]

        Assign Complaint
```

Successful assignment should use Civic Green feedback.

---

# 42. Status Update UI

Status updates should clearly communicate the next state.

Example:

```text
Current Status
In Progress

Change Status

[ Resolved ▼ ]

Update Message

[________________________]

        Update Complaint
```

---

# 43. Hazard Map Design

The map should remain visually clean.

Markers should represent issue categories.

Example:

```text
● Road
● Water
● Waste
● Drainage
● Street Light
```

However, marker color alone should not be the only differentiator.

Use:

* Icons.
* Labels.
* Category filters.

---

# 44. Map Marker Philosophy

Markers should communicate:

```text
What is the issue?
Where is it?
What is its status?
```

Selecting a marker opens a compact information card.

Example:

```text
Road Damage

Large pothole near entrance

Status: In Progress

View Complaint →
```

---

# 45. Notifications

Notifications should use a clean card/list design.

Example:

```text
✓ Complaint Verified

Your complaint CF-2026-000001
has been verified.

2 hours ago
```

Important notifications may use a subtle Fresh Mint or Amber background.

---

# 46. Notification Types

## Success

Use Civic Green.

Example:

```text
Complaint Resolved
```

## Information

Use Deep Navy or neutral treatment.

## Attention

Use Amber.

Example:

```text
Complaint requires additional information.
```

---

# 47. Rewards Screen

Rewards should feel positive without becoming overly gamified.

Recommended structure:

```text
Your Civic Progress

        420
       Points

────────────────────

Achievements

✓ First Report
✓ Civic Contributor
○ Community Helper
○ Active Citizen
```

Fresh Mint can be used to highlight progress.

---

# 48. Achievement Cards

Achievement cards should use:

* Soft Fresh Mint background.
* Deep Navy text.
* Civic Green completion indicator.

Locked achievements should use muted neutral styling.

---

# 49. Civic Assistant

The assistant should feel integrated into CivicFix rather than like a generic chatbot.

Example:

```text
┌─────────────────────────────┐
│ Civic Assistant             │
│                             │
│ How can I help you today?   │
│                             │
│ [ How do I report an issue? ]│
│ [ Track my complaint        ]│
│ [ Which category to choose? ]│
│                             │
│ Type your question...       │
└─────────────────────────────┘
```

---

# 50. Assistant Visual Style

Use:

```text
Background: Off White
Assistant Bubble: Fresh Mint
User Bubble: Deep Navy
Text: Appropriate high-contrast neutral
```

Avoid excessive chatbot decoration.

---

# 51. Profile Screen

Recommended structure:

```text
Profile Image

Name
Email

────────────────

My Complaints
Rewards

────────────────

Language
Notifications
Settings

────────────────

Logout
```

---

# 52. Settings

Settings should include:

* Language.
* Notifications.
* Account settings.
* Privacy information.
* App information.

The settings interface should remain simple.

---

# 53. Language Selection

Recommended:

```text
Language

○ English
○ हिन्दी
○ मराठी
```

The selected language should use Deep Navy or Civic Green as the selection indicator.

---

# 54. Offline State

Offline status should be noticeable but not disruptive.

Example:

```text
⚠ You're offline
Your complaint will be saved and synced when you're back online.
```

Use Amber.

Avoid full-screen blocking messages for a temporary offline state.

---

# 55. Sync Status

Each offline complaint may display:

```text
Pending Sync
Syncing
Synced
Sync Failed
```

Recommended visual hierarchy:

| State        | Treatment   |
| ------------ | ----------- |
| Pending Sync | Amber       |
| Syncing      | Deep Navy   |
| Synced       | Civic Green |
| Sync Failed  | Error Red   |

---

# 56. Error States

Errors should be clear and actionable.

Example:

```text
Unable to upload image

Please check your connection and try again.

[ Retry ]
```

Use error red sparingly.

Do not make the entire interface red.

---

# 57. Empty States

Empty states should be helpful.

Example:

```text
No complaints yet

Found a civic issue?
Report it and track its progress here.

[ Report an Issue ]
```

Use subtle Fresh Mint illustrations or icons where appropriate.

---

# 58. Loading States

Use:

* Skeleton loaders.
* Progress indicators.
* Button loading states.

Avoid displaying unnecessary full-screen loading indicators.

---

# 59. Confirmation States

Successful actions should provide immediate feedback.

Example:

```text
✓ Complaint Submitted

Your complaint has been successfully submitted.

Complaint ID

CF-2026-000001

[ Track Complaint ]
```

Use Civic Green for success confirmation.

---

# 60. Form Design

Forms should:

* Use clear labels.
* Avoid unnecessary fields.
* Show validation near the field.
* Use appropriate keyboard types.
* Maintain adequate spacing.
* Preserve entered information after recoverable errors.

---

# 61. Text Fields

Recommended:

```text
Border: #D9E0DC
Focus: #12304A
Error: #C62828
Background: #FFFFFF
Radius: 10px
```

Focused fields should have a clear but restrained visual change.

---

# 62. Input Labels

Labels should remain visible.

Prefer:

```text
Complaint Title
[_____________________]
```

rather than relying only on placeholder text.

---

# 63. Icons

Icons should use a consistent icon family.

Recommended:

```text
Material Symbols / Material Icons
```

Icons should primarily use:

```text
Deep Navy
Secondary Text
Civic Green
```

Avoid mixing unrelated icon styles.

---

# 64. Icon Semantics

Recommended:

| Function      | Icon Concept       |
| ------------- | ------------------ |
| Report        | Add / Flag         |
| Complaints    | Description        |
| Map           | Location           |
| Notifications | Notifications      |
| Profile       | Person             |
| Roads         | Road / Directions  |
| Water         | Water Drop         |
| Waste         | Delete / Recycling |
| Drainage      | Water / Pipeline   |
| Street Light  | Light              |
| Resolved      | Check Circle       |
| Warning       | Warning            |

---

# 65. Imagery

Images should feel:

* Real.
* Local.
* Human.
* Civic.
* Authentic.

Avoid excessive stock imagery showing generic government buildings.

Complaint evidence images should remain unaltered except for necessary compression/cropping.

---

# 66. Illustrations

Illustrations should be:

* Minimal.
* Friendly.
* Geometric.
* Simple.
* Consistent.

Use Fresh Mint and Deep Navy as dominant illustration colors.

---

# 67. Map Design

The map should not dominate the entire visual identity.

UI overlays such as:

* Filters.
* Search.
* Complaint cards.

should use clean white surfaces.

Brand colors should be reserved for meaningful interaction.

---

# 68. Accessibility

CivicFix must consider accessibility throughout the design.

Requirements:

* Adequate text contrast.
* Minimum comfortable touch targets.
* Clear focus states.
* Meaningful labels.
* Screen-reader-friendly controls.
* Status communicated using text and icons.
* Avoid tiny text.
* Avoid color-only communication.

---

# 69. Touch Targets

Interactive controls should generally provide at least:

```text
48 × 48 px
```

of touchable area where practical.

---

# 70. Contrast

Text and controls must maintain sufficient contrast against their backgrounds.

Particular attention should be given to:

```text
Fresh Mint
Amber
```

because lighter colors should not be used for small text on light backgrounds.

For example, avoid:

```text
Light text
on Fresh Mint background
```

when readability is compromised.

---

# 71. Responsive Design

The application has two major presentation environments.

## Mobile

Citizen application.

Priorities:

```text
Simplicity
Touch
Readable content
Quick actions
One-handed use
```

## Web

Government interface.

Priorities:

```text
Information density
Tables
Filtering
Analytics
Map interaction
Multi-column layouts
```

---

# 72. Mobile Layout

Recommended:

```text
┌──────────────────────┐
│ App Bar              │
├──────────────────────┤
│                      │
│ Main Content         │
│                      │
│                      │
├──────────────────────┤
│ Bottom Navigation    │
└──────────────────────┘
```

---

# 73. Web Layout

Recommended:

```text
┌─────────────────────────────────────────┐
│ Top Bar                                 │
├────────────┬────────────────────────────┤
│            │                            │
│ Sidebar    │ Main Content               │
│            │                            │
│            │                            │
│            │                            │
└────────────┴────────────────────────────┘
```

---

# 74. Government Sidebar

Recommended sections:

```text
Dashboard
Complaints
Map
Analytics
Profile
```

The active section should use Deep Navy with a subtle Fresh Mint or light background highlight.

---

# 75. Responsive Breakpoints

Exact breakpoints can be determined during implementation.

Conceptual categories:

```text
Mobile
Tablet
Desktop
Large Desktop
```

The government dashboard should make efficient use of wide screens without forcing excessive horizontal scrolling.

---

# 76. Design Tokens

The Flutter implementation should centralize design tokens.

Example conceptual structure:

```dart
class CivicFixColors {
  static const primary = Color(0xFF12304A);
  static const secondary = Color(0xFF2E8B57);
  static const accent = Color(0xFF7ED6A5);
  static const background = Color(0xFFF7F9F7);
  static const alert = Color(0xFFF4B942);
}
```

These values should be used throughout the application rather than repeatedly defining colors inside individual widgets.

---

# 77. Theme Architecture

Flutter should use centralized themes.

Conceptually:

```text
CivicFix Theme
      │
      ├── Colors
      ├── Typography
      ├── Buttons
      ├── Inputs
      ├── Cards
      ├── Navigation
      └── Component Styles
```

This ensures consistency between the Citizen UI and Government UI.

---

# 78. Component Reusability

Shared components should be placed in:

```text
lib/core/widgets/
```

Examples:

```text
CivicFixButton
CivicFixCard
CivicFixTextField
StatusBadge
ComplaintCard
LoadingState
EmptyState
ErrorState
```

---

# 79. User UI Design Separation

Citizen-specific components should remain inside:

```text
lib/User UI/
```

Government-specific components should remain inside:

```text
lib/Govt UI/
```

Shared design system components should remain inside:

```text
lib/core/
```

---

# 80. Design Consistency

The same visual language should exist across:

* Citizen mobile application.
* Government web application.

However, the information density may differ.

The Citizen UI should prioritize simplicity.

The Government UI should prioritize operational efficiency.

---

# 81. Citizen Design Personality

Citizen UI should feel:

```text
Friendly
Simple
Clear
Approachable
Positive
Trustworthy
```

Use:

* More whitespace.
* Larger touch targets.
* Strong visual hierarchy.
* Simple language.
* Prominent primary actions.

---

# 82. Government Design Personality

Government UI should feel:

```text
Professional
Structured
Efficient
Data-driven
Reliable
```

Use:

* Tables.
* Filters.
* Dashboards.
* Compact information cards.
* Clear status indicators.
* Map views.

---

# 83. Design Do's

### Do

* Use Deep Navy consistently.
* Use Civic Green for positive progress.
* Use Fresh Mint as a subtle accent.
* Use Off White as the primary background.
* Use Amber for attention.
* Maintain strong hierarchy.
* Keep reporting simple.
* Show complaint progress clearly.
* Use icons with status text.
* Maintain generous spacing.
* Keep interfaces accessible.

---

# 84. Design Don'ts

### Don't

* Use too many colors.
* Make every element green.
* Use Fresh Mint for small body text.
* Use Amber for everything important.
* Rely only on color to communicate status.
* Use heavy shadows.
* Overload citizens with information.
* Make government dashboards unnecessarily decorative.
* Use excessive animations.
* Hide important complaint information.
* Use inconsistent button styles.

---

# 85. Animation Principles

Animations should be:

* Fast.
* Subtle.
* Functional.

Useful animations include:

* Complaint submission confirmation.
* Tracker progress.
* Notification appearance.
* Map marker interaction.
* Loading transitions.

Avoid:

* Excessive bouncing.
* Long transitions.
* Decorative animations that slow down reporting.

---

# 86. Motion Timing

Recommended:

```text
Micro interaction:
100–200ms

Component transition:
200–300ms

Major transition:
300–400ms
```

These values are guidelines.

---

# 87. Microinteractions

Useful examples:

### Complaint Submitted

```text
✓
Complaint Submitted
```

### Status Changed

Tracker smoothly updates.

### Achievement Earned

Small positive animation.

### Offline

Small Amber connectivity indicator.

---

# 88. Design for Trust

Trust should be visible throughout the product.

Examples:

```text
Complaint ID
Status History
Last Updated
Assigned Department
Resolution Timestamp
```

The system should avoid hiding important progress information behind unnecessary screens.

---

# 89. Design for Transparency

The complaint tracker should be one of CivicFix's strongest design elements.

A citizen should be able to open a complaint and immediately understand:

```text
Current Status
Previous Actions
Latest Update
Responsible Department
```

---

# 90. Design for Reliability

Offline support should be communicated clearly.

Instead of:

```text
Upload Failed
```

prefer:

```text
Your complaint is safely saved on this device.

It will sync automatically when your connection returns.
```

This reinforces trust.

---

# 91. Design for Localization

The UI must accommodate longer translated text.

For example, buttons should not assume English text length.

Avoid fixed-width buttons where possible.

Layouts should support:

```text
English
Hindi
Marathi
```

without clipping.

---

# 92. Design for Government Workflow

Government interfaces should reduce unnecessary clicks.

For example:

```text
Complaint List
     ↓
Complaint Details
     ↓
Verify / Assign / Update
```

The most common actions should be immediately accessible.

---

# 93. Design for Citizen Workflow

Citizen reporting should minimize cognitive load.

Ideal flow:

```text
Report Issue
↓
Describe
↓
Locate
↓
Attach Evidence
↓
Submit
```

The citizen should not need to understand government organizational structure.

---

# 94. Design System Summary

The CivicFix visual system can be summarized as:

```text
                CIVICFIX
                   │
        ┌──────────┼──────────┐
        │          │          │
     TRUST       ACTION    PROGRESS
        │          │          │
   Deep Navy   Civic Green Fresh Mint
        │          │          │
        └──────────┼──────────┘
                   │
               Off White
                   │
             Calm Interface
                   │
                Amber
                   │
              Attention
```

---

# 95. Core Color Reference

For implementation, use these exact brand values:

```text
PRIMARY
Deep Navy
#12304A

SECONDARY
Civic Green
#2E8B57

ACCENT
Fresh Mint
#7ED6A5

BACKGROUND
Off White
#F7F9F7

ALERT
Amber
#F4B942
```

---

# 96. Recommended Flutter Theme Mapping

Conceptually:

```text
primary
    → #12304A

secondary
    → #2E8B57

tertiary / accent
    → #7ED6A5

surface / background
    → #F7F9F7

warning
    → #F4B942

error
    → #C62828

text
    → #17212B
```

The final Flutter `ColorScheme` should be generated and validated according to the application's accessibility requirements rather than blindly assigning every brand color to a Material role.

---

# 97. Design Implementation Priority

When implementing the design system, follow this order:

```text
1. Colors
      ↓
2. Typography
      ↓
3. Spacing
      ↓
4. Buttons
      ↓
5. Inputs
      ↓
6. Cards
      ↓
7. Navigation
      ↓
8. Status Components
      ↓
9. Complaint Components
      ↓
10. Maps
      ↓
11. Dashboards
      ↓
12. Animations
```

---

# 98. Design Definition of Done

The design system is considered ready when:

* [ ] Brand colors are centralized.
* [ ] Typography is centralized.
* [ ] Spacing system is defined.
* [ ] Button styles are consistent.
* [ ] Input styles are consistent.
* [ ] Card styles are consistent.
* [ ] Navigation is consistent.
* [ ] Complaint statuses have defined visual treatments.
* [ ] Citizen UI follows the design system.
* [ ] Government UI follows the design system.
* [ ] Mobile layouts are responsive.
* [ ] Web layouts are responsive.
* [ ] Accessibility has been considered.
* [ ] Localization does not break layouts.
* [ ] Offline states have clear visual treatment.
* [ ] Error and empty states are defined.
* [ ] Shared components are reusable.

---

# 99. Final Design Principle

CivicFix should never make the citizen think:

> "Where do I go now?"

The design should always make the next action obvious.

The interface should guide users naturally through:

```text
IDENTIFY
   ↓
REPORT
   ↓
TRACK
   ↓
UNDERSTAND
   ↓
RESOLVE
```

---

# 100. Final Design Statement

> **CivicFix combines the trust of Deep Navy, the civic action of Civic Green, the optimism of Fresh Mint, the calmness of Off White, and the attention of Amber to create a civic platform that feels trustworthy, accessible, modern, and human.**

The design system exists to support one fundamental product goal:

> **Make civic problem reporting simple and make the resolution journey visible.**
