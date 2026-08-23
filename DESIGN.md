---
name: Context
description: A calm Night Atlas for deliberate Grok-first browsing.
colors:
  atlas-night: "#060A0F"
  atlas-raised: "#11161E"
  browser-surface: "#20242A"
  warm-white: "#F6F4EE"
  muted-white: "rgba(246, 244, 238, 0.66)"
  signal-blue: "#70B3F0"
typography:
  title:
    fontFamily: "-apple-system, BlinkMacSystemFont, SF Pro Display, sans-serif"
    fontSize: "28px"
    fontWeight: 700
    lineHeight: 1.1
  body:
    fontFamily: "-apple-system, BlinkMacSystemFont, SF Pro Text, sans-serif"
    fontSize: "17px"
    fontWeight: 400
    lineHeight: 1.62
  label:
    fontFamily: "-apple-system, BlinkMacSystemFont, SF Pro Text, sans-serif"
    fontSize: "14px"
    fontWeight: 650
    lineHeight: 1.2
rounded:
  control: "12px"
  action: "18px"
  card: "20px"
  browser-island: "28px"
  capsule: "999px"
spacing:
  tight: "4px"
  small: "8px"
  control: "12px"
  section: "24px"
components:
  action-primary:
    backgroundColor: "{colors.signal-blue}"
    textColor: "{colors.warm-white}"
    rounded: "{rounded.action}"
    padding: "18px"
  card:
    backgroundColor: "{colors.browser-surface}"
    textColor: "{colors.warm-white}"
    rounded: "{rounded.card}"
    padding: "16px"
---

# Design System: Context

## Overview

**Creative North Star: "The Night Atlas"**

Context feels like a quiet observatory built from native Apple controls: an abyssal field, sparse stars, warm white information, and one cool signal color. The atmosphere is present but restrained so the web page and the user's deliberate Grok handoff remain the focus.

Density stays calm on iPhone and opens up on iPad. Identity comes from the Context mark, the blue page-handoff action, and the recurring floating browser island—not from decorative copies of another browser.

**Key Characteristics:**

- Deep navy field with sparse, deterministic stars.
- Warm-white content and one sky-blue action color.
- Native SwiftUI materials, symbols, Dynamic Type, and device adaptation.
- Rounded cards and capsules with quiet one-pixel boundaries.
- Explicit state language: protection on, copied, shared, or unavailable.

## Colors

The palette is intentionally narrow: night creates the field, tonal surfaces create hierarchy, and signal blue identifies user-controlled action.

### Primary

- **Signal Blue** (#70B3F0): Primary Grok handoff actions, links, active controls, and reassuring status accents.

### Neutral

- **Atlas Night** (#060A0F): The new-tab and library field.
- **Atlas Raised** (#11161E): Deeper layered containers and site cards.
- **Browser Surface** (#20242A): Search islands, quick-link tiles, and privacy cards in dark appearance.
- **Warm White** (#F6F4EE): Primary type and high-emphasis symbols.
- **Muted White** (66% Warm White): Secondary explanations and inactive metadata.

### Named Rules

**The One Signal Rule.** Signal Blue identifies actions the user intentionally initiates; it does not decorate passive content.

**The Quiet Night Rule.** Stars remain sparse and low contrast. They establish place without reducing text legibility or competing with web content.

## Typography

**Body Font:** Apple system text face with native fallbacks

**Character:** Direct, compact, and platform-native. The app uses Dynamic Type roles rather than fixed custom display lettering; the public site uses the same system family at a larger responsive scale.

### Hierarchy

- **Title** (bold, native `title2` / approximately 28px): Product identity, sheet titles, and important sections.
- **Body** (regular, native `body` / 17px): Explanations, page metadata, and settings.
- **Label** (semibold, native `caption` to `subheadline`): Protection state, actions, and compact navigation.

### Named Rules

**The Native Scale Rule.** App text uses semantic Dynamic Type roles and must remain useful when the user enlarges text.

## Layout

The iPhone surface uses an 18-point horizontal content inset, 24–26 points between major sections, and a floating bottom browser island. Primary content remains in a vertical scroll view so enlarged text can reflow behind the safe-area inset.

On regular-width iPad, a 260-point native sidebar holds tabs and durable destinations. The main new-tab content is capped near 720 points while the night field fills the remaining canvas. Quick links use a four-column flexible grid; tab cards use an adaptive grid.

## Elevation & Depth

Depth comes from tonal layering, native materials, subtle one-pixel strokes, and a single ambient shadow under the floating browser island. Cards do not stack multiple decorative shadows. Modal sheets use system presentation behavior.

### Named Rules

**The Native Layer Rule.** Use system material when a control floats above web content; use opaque night surfaces when legibility and stable contrast matter more than translucency.

## Shapes

Controls are continuously rounded. Compact identity marks and fields use 12-point corners, primary actions use 18, cards use 16–20, and the browser island uses 28. Status indicators and small toolbar controls use capsules or circles. Borders are quiet, typically white or primary content at roughly 10–12% opacity.

## Components

### Buttons

- **Shape:** Continuously rounded (18px for primary action; capsule or circle for compact controls).
- **Primary:** Signal Blue with Warm White content and 18px internal padding.
- **Focus:** Native focus and accessibility behavior; do not replace semantic labels with unlabeled gestures.
- **Secondary:** Transparent or tonal surface with a subtle boundary and Signal Blue text when it represents navigation.

### Cards / Containers

- **Corner Style:** 16–20px continuous radius.
- **Background:** Browser Surface or low-opacity Warm White over Atlas Night.
- **Shadow Strategy:** Tonal layering at rest; ambient shadow only for the floating browser island.
- **Border:** One pixel at approximately 10–12% white.
- **Internal Padding:** 16–18px.

### Inputs / Fields

- **Style:** Native text fields inside a tonal capsule, with search icon and a clear semantic placeholder.
- **Focus:** Native keyboard, submit label, autocorrection, and capitalization behavior appropriate to URLs and search.
- **Disabled:** Native reduced emphasis; state remains readable in text.

### Navigation

The iPhone browser island groups the address field, tab count, Grok Bot action, and More menu. iPad uses a native sidebar for tabs, Ask Grok Bot, Library, and Settings. Page-level browsing controls appear only when a real page is open.

### Grok Handoff

The handoff is a first-class blue action. Its review sheet names the teammate, task, page URL, and optional readable text, then makes copy, share, and app opening separate explicit choices.

## Do's and Don'ts

### Do:

- **Do** lead AI-related browsing surfaces with the Context mark and the Signal Blue handoff action.
- **Do** use native iOS symbols, sheets, menus, labels, and Dynamic Type behavior.
- **Do** name persistent content truthfully: Quick Links are fixed; Bookmarks and History are user data.
- **Do** keep outbound page context reviewable before it leaves the device.

### Don't:

- **Don't** copy Comet branding, illustrations, or screen composition.
- **Don't** add extra accent colors, glossy high-chroma gradients, or dense star effects.
- **Don't** imply that opening Grok Bot automatically sends content or selects a named teammate.
- **Don't** present planned sync, default-browser, automation, or private-mode features as available.
