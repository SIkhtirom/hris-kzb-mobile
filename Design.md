# App Design System & UI/UX Guidelines

## 1. Brand Identity & Assets
*   **Logo**: `logo-kzb.jpg` (KZB Globe Logo). Used primarily on the Splash Screen and Login/Auth boundaries.
*   **Theme Vibe**: Clean, modern, professional, and accessible.

## 2. Color Palette
*   **Primary Accent (Teal/Mint)**: `Hex: #48CFCB` (Used for active states, icons in dashboard, FAB, and primary buttons like "PROSES").
*   **Background (Global)**: `Hex: #FAFAFA` to `#FFFFFF` (Clean white to prevent visual clutter).
*   **Surface/Cards**: `Hex: #FFFFFF` (Pure white for cards with subtle shadows to create depth).
*   **Text Primary**: `Hex: #333333` (For headings and main body text).
*   **Text Secondary**: `Hex: #888888` (For subtitles, placeholders, and empty states).
*   **Splash Screen Background**: Match the prominent Sky Blue from the KZB logo or use clean white to let the logo pop.

## 3. Typography
*   **Font Family**: Primary sans-serif (Inter, Roboto, or Poppins).
*   **Headings**: Bold, prominent. (e.g., Dashboard "Selamat Pagi" is 24px+ Bold).
*   **Body**: Regular, 14px - 16px.
*   **Placeholders/Labels**: 12px - 14px, medium weight.

## 4. Component Library Rules

### 4.1. Cards (Dashboard Features)
*   **Border Radius**: 12px to 16px.
*   **Border/Shadow**: Very subtle gray border (`1px solid #EAEAEA`) OR a soft drop shadow (`box-shadow: 0 4px 6px rgba(0,0,0,0.05)`).
*   **Alignment**: Flexbox Column, Center aligned (Icon on top, text below).
*   **Spacing**: Padding ~16px to 20px inside the card.

### 4.2. Form Elements (Inputs & Dropdowns)
*   **Border Radius**: 8px to 12px.
*   **Border Color**: Light gray (`#DDDDDD`).
*   **Padding**: `12px 16px` for comfortable touch targets.
*   **Font Size**: 14px to 16px to prevent iOS auto-zoom and ensure readability.

### 4.3. Buttons
*   **Primary Action (e.g., "PROSES")**: Full width with a 16px margin on left/right, standard height (~48px), Primary Accent Color background, White text, Bold.
*   **Floating Action Button (FAB)**: 56x56px, circular, Primary Accent Color, positioned bottom-right (`bottom: 24px, right: 24px`), with a prominent drop shadow.

### 4.4. Upload & Action Squares
*   **Layout**: Square aspect ratio (~80x80px).
*   **Border**: `1px solid #DDDDDD`, rounded corners (12px).
*   **Icon**: Centered, large, gray.

## 5. Navigation
*   **Top Bar**: Minimalist. Back arrow on the far left. Centered Title. Optional action on the far right (e.g., list icon). Background must be white and blend seamlessly or have a very faint bottom border.
*   **Bottom Bar**: 3 equidistant icons (Home, Document, More). Active state colored in Primary Accent, inactive in gray. Top border `1px solid #EAEAEA`.

## 6. UX Behaviors & Animations
*   **App Launch**: Display Splash Screen (`logo-kzb.jpg`) fading out smoothly after 1.5 - 2 seconds or when initial data loads.
*   **Page Transitions**: Implement a 200ms - 300ms fade or slide transition between screens to prevent abrupt jumps.
*   **Loading States**:
    *   Use skeleton loaders for Dashboard data.
    *   Use a global `SmoothLoader` (overlay spinner/indicator) when submitting forms (e.g., clicking "PROSES" in Reimbursement) or waiting for GPS coordinates in "Mulai Kunjungan".