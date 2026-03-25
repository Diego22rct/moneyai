# Design System Documentation: Tactical Financial Precision

## 1. Overview & Creative North Star: "The Obsidian Monolith"
This design system is built upon the concept of **The Obsidian Monolith**. In a world of cluttered, loud fintech interfaces, we choose the opposite: a quiet, authoritative depth that feels like carved volcanic glass. This is not just a "dark mode" UI; it is an environment of extreme focus.

The "North Star" is **Tactile Minimalism**. We achieve a premium feel by moving away from standard grid-locked templates. We utilize intentional asymmetry, significant negative space (macro-white space), and overlapping glass layers to create a sense of architectural sophistication. The interface should feel expensive, precise, and immutable.

---

## 2. Colors: Tonal Depth & Accents
Our palette is restricted to the deepest ends of the spectrum, accented by a singular, razor-sharp emerald.

### The Foundation
*   **Surface & Background:** Use `surface` (#131313) for the primary canvas. For the deepest sense of immersion, use `surface_container_lowest` (#0E0E0E) for background-level page wraps.
*   **The Emerald Pulse:** Our primary accent is `primary` (#4EDEA3) with its core container at `primary_container` (#10B981). This is the only "color" allowed. It represents growth and action.

### The "No-Line" Rule
**Explicit Instruction:** Designers are prohibited from using 1px solid borders for sectioning or layout separation. Boundaries must be defined solely through:
1.  **Background Shifts:** Placing a `surface_container_low` section atop a `surface` background.
2.  **Shadow Depth:** Using ambient, diffused shadows to imply separation.
3.  **Negative Space:** Using the Spacing Scale (specifically `8` to `16`) to create mental dividers.

### Surface Hierarchy & Nesting
Treat the UI as physical layers. Each inner container should move one step "closer" to the user:
*   **Base:** `surface` (#131313)
*   **Secondary Content Area:** `surface_container_low` (#1C1B1B)
*   **Floating Cards/Modals:** `surface_container_high` (#2A2A2A)

### The Glass & Gradient Rule
To achieve "High-Fidelity" status, main CTAs and Hero sections should utilize a subtle linear gradient: 
`linear-gradient(135deg, #4EDEA3 0%, #10B981 100%)`.
For glass effects, use `surface_variant` at 60% opacity with a `24px` backdrop-blur.

---

## 3. Typography: Editorial Authority
We use **Manrope** exclusively. It is a geometric sans-serif that balances modern tech with high-end editorial feel.

*   **Display (Large/Medium):** Reserved for portfolio totals or market-moving headlines. Use `-0.02em` letter spacing to create a "tight," professional look.
*   **Headline (Small/Medium):** Used for section headers. Ensure `on_surface` color is used to maintain high contrast against the obsidian background.
*   **The Label System:** `label-md` and `label-sm` should be used for metadata. In this system, labels are often set in `on_surface_variant` (#BBCABF) to create a clear hierarchy between "Data" (bright) and "Context" (subdued).

---

## 4. Elevation & Depth: Tonal Layering
We reject traditional Material Design drop shadows. Instead, we use **Tonal Layering** and **Ambient Light**.

*   **The Layering Principle:** Depth is achieved by "stacking." A `surface_container_highest` (#353534) card should live on a `surface_container_low` (#1C1B1B) background. The contrast is the border.
*   **Ambient Shadows:** For floating elements (Modals/Popovers), use a shadow: `0px 24px 48px rgba(0, 0, 0, 0.5)`. The shadow must feel like an absence of light, not a grey smudge.
*   **The "Ghost Border" Fallback:** If accessibility requires a stroke, use `outline_variant` (#3C4A42) at **15% opacity**. It should be felt, not seen.
*   **Active Glows:** Active states for icons or buttons should use a very soft `primary` outer glow: `box-shadow: 0px 0px 12px rgba(78, 222, 163, 0.25)`.

---

## 5. Components: Precision Instruments

### Buttons
*   **Primary:** Solid `primary_container`. No border. High-contrast `on_primary_container` text.
*   **Secondary:** Glassmorphic. Background: `surface_variant` at 20% opacity. 1px "Ghost Border."
*   **Tertiary:** Text only using `primary` color, strictly for low-emphasis actions.

### Cards & Lists
*   **Rule:** Forbid the use of divider lines. 
*   **Implementation:** Use `surface_container_low` for the card background. Use `8` (2rem) padding from the spacing scale to separate internal list items. For visual grouping, use a subtle vertical 2px "accent bar" of `primary` on the far left of an active list item instead of a border.

### Input Fields
*   **State:** Default state is a `surface_container_highest` fill with no border. 
*   **Focus State:** Transition the background to `surface_bright` and add the "Active Glow" to the `primary` bottom-border (2px only).

### Additional Signature Component: The "Flux Ribbon"
For fintech data visualization (charts), use a `primary` stroke with a gradient fill that fades from `primary` (20% opacity) to `transparent` at the baseline. No grid lines on charts; use only 3 horizontal "Ghost" markers at 0%, 50%, and 100%.

---

## 6. Do's and Don'ts

### Do:
*   Use `surface_container_lowest` for the main app background to make the `primary` emerald pop.
*   Use extreme horizontal padding (e.g., `12` or `16`) on desktop views to create an editorial, "centered" feel.
*   Use thin-stroke icons (1.5px weight) to match the Manrope font weight.

### Don't:
*   **Never use purple, violet, or blue.** Even in data visualization, use shades of slate, emerald, and white.
*   Never use a 100% opaque border to separate content.
*   Never use standard "Material Blue" for links; all interactive elements are `primary` (#4EDEA3).
*   Avoid "boxy" layouts. Allow elements to overlap slightly (e.g., a floating card overlapping a header background) to create depth.