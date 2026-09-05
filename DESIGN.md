# DESIGN.md — StoreMate

> Design system reference for **StoreMate** (internal product name; app title "Store Mate", repo `store_manager_v2`).
> This document describes the *actual, shipped* UI so it can be fed into a design tool (Claude Design / Figma) to recreate, extend, or redesign screens consistently.
>
> Source of truth: `app/frontend/` (React 19 + Inertia.js, styled with Tailwind CSS v4). All values below are extracted from `app/frontend/styles/application/*.css` and the React components — not aspirational.

---

## 1. Product at a glance

StoreMate is an **internal back-office tool** for running a collectibles inventory business end to end: purchasing from suppliers, warehousing physical units, syncing orders from Shopify and WooCommerce, and linking each sold line item back to the exact physical unit that fulfilled it.

- **Audience:** internal operators / admins (not customer-facing). Density and information clarity matter more than marketing polish.
- **Tone:** utilitarian, dense, fast. A friendly cat mascot (😸) is the only playful element.
- **Surface:** desktop-first web app, fully responsive down to mobile. Full **light + dark mode** (driven by `prefers-color-scheme`).
- **Core entities (each has full CRUD screens):** Sales, Purchases, Warehouses, Products, Customers, Suppliers, Shipping Companies, Brands, Franchises, Versions, Colors, Sizes, Users, plus a Dashboard and a Debts view.

---

## 2. Brand & identity

| Element | Value |
| --- | --- |
| Product name | **StoreMate** (shown as `😸 StoreMate` in the nav) |
| Mascot / logo | 😸 cat emoji — used as the brand mark (nav, top-left) and as the footer "scroll to top" button |
| Personality | Lightweight, friendly-but-businesslike. Emoji are used as functional icons, not decoration. |
| Voice in UI | Short, direct labels ("Add New Record", "Log Out", "Debts"). The "Add New Record" action uses a 🐣 hatching-chick icon. |

There is **no heavy logo lockup** — the identity is the cat emoji + the wordmark in a bold grotesque typeface.

---

## 3. Design tokens

### 3.1 Typography

| Token | Family | Usage |
| --- | --- | --- |
| `--font-sans` | **Bricolage Grotesque**, sans-serif | UI text, headings — the primary face |
| `--font-nunito` | **Nunito**, sans-serif | Long-form / rich-text body (product descriptions, Tiptap editor content) |
| `--font-icn` | Noto Emoji / Apple Color Emoji / Segoe emoji stack | Emoji icons (`.icn` class) |

Headings use heavy weight and tighten on desktop:

| Level | Weight | Size (mobile → `lg:`) | Color |
| --- | --- | --- | --- |
| `h1` | `font-black` (900) | `text-3xl` → `text-6xl` | gray-900 / dark gray-50 |
| `h2` | `font-black` | `text-xl` → `text-2xl` | gray-800 / dark gray-100 |
| `h3` | `font-black` | `text-xl` | gray-800 / dark gray-100 |
| `h4` | `font-black` | `text-lg` | gray-800 / dark gray-100 |

Body text is the browser default size, antialiased, `scroll-smooth`. Buttons/links use an unusual fine-grained weight: `font-weight: 480` with `font-stretch: 98%` (slightly condensed, medium weight).

### 3.2 Color system

The palette is the **Tailwind default palette** (no custom brand hue). Neutral grays carry the layout; saturated colors are strictly **semantic**.

**Neutrals (structure & text)**
- Light mode: page = white / `gray-50`; text = `gray-800`/`gray-900`; muted = `gray-500`/`gray-600`; borders = `gray-100`–`gray-300`.
- Dark mode: page = `gray-900`; surfaces = `gray-800`; text = `gray-100`/`gray-200`; muted = `gray-400`; borders = `gray-700`/`gray-800`.

**Semantic accents**

| Meaning | Hue | Where it appears |
| --- | --- | --- |
| **Primary / submit** | `blue-600` (hover `blue-700`; dark `blue-900`) | Primary buttons (`.btn_blue`), submit inputs, file-upload button, select chips, checkbox checked state |
| **Link / hover accent** | `blue-600` | Underlined text links (`a.link`), link hover decoration |
| **Success / positive** | `lime` / green | `.btn_green`, completed progress bar (`.progress_end` lime-600), success flash (lime-100/lime-700) |
| **Destructive / danger** | `red` | `.btn_red` (red-100 bg / red-700 text, pill), error fields & labels (red-700), alert flash, "removed" X overlay (red-900), red checkbox |
| **Warning / selected** | `amber` | `.btn_amber`, selected table row (`tr.selected` amber-50 / dark amber-900/25) |
| **Info / interactive editable** | `sky` (light blue) | `.btn_lightblue`, inline-editable cell hover (sky-50), active tab, Tiptap active toolbar button |
| **Highlight** | `yellow` | `<mark>` highlight chips (yellow-100 / yellow-800); `.mark_gray` neutral variant |

> Rule for the designer: **never introduce a new brand hue.** Status meaning is encoded by these specific hues. Blue = "do the main thing", red = "danger/remove", lime = "done/good", amber = "selected/attention", sky = "editable/interactive".

### 3.3 Shape, elevation, motion

| Token | Value |
| --- | --- |
| Default radius | `rounded-sm` (buttons, inputs) |
| Pills | `rounded-full` (search inputs, tab bar, danger buttons, chips, progress bars) |
| Cards / sections | `rounded-lg` to `rounded-xl` |
| Borders | 1px, low-contrast (`gray-200/80` light, `gray-800` dark); table rows use `border-b-2` |
| Elevation | Mostly **flat** + borders. Real shadows only on: sticky table head, dropdown menu, dialog (`shadow-lg`), toasts (`shadow-xl`), active tab (`shadow-sm`). Dialog/dropdown/toast also use `backdrop-blur`. |
| Motion | `transition-all duration-150` on interactive elements; `duration-100` on table-row hover. Subtle, fast, no large animations. |
| Focus | `:focus-visible` → dashed 2px outline, `gray-300` (dark `gray-500`), offset 2px |

### 3.4 Spacing & layout grid

- **Container:** `container mx-auto` centered, `px-4` on mobile, edge-to-edge (`lg:px-0`) on desktop.
- **Main content rhythm:** top `mt-4` → `lg:mt-8`, generous bottom (`mb-24` → `lg:mb-60`) so content never sticks to the footer.
- **Responsive switch:** the single meaningful breakpoint is **`lg`**. Pattern everywhere: stack vertically on mobile (`flex-col`), go horizontal on desktop (`lg:flex-row`).
- **Wide sections:** `.section_wide` breaks out of the container (`lg:-mx-8`) so tables get more room.

---

## 4. Layout & page shell

```
┌───────────────────────────────────────────────┐
│ HEADER  😸 StoreMate        [nav links]  ☰      │  ← AppNavigation, sticky-feel, container width
├───────────────────────────────────────────────┤
│ MAIN (container, mx-auto)                       │
│   [Flash toasts — fixed, top-center overlay]    │
│   Breadcrumbs                                   │
│   <Page content>                                │
│     PageHeader:  H1 title (+ H3 subtitle)  menu │
│     section_border_base / cards / tables ...    │
├───────────────────────────────────────────────┤
│ FOOTER             😸  (click → scroll to top)  │
└───────────────────────────────────────────────┘
```

- **AppLayout** (`layouts/AppLayout.tsx`): `flex flex-col min-h-screen` → nav, main (flex-grow), footer.
- **AuthLayout** (`layouts/AuthLayout.tsx`): minimal centered shell for sign-in / password screens (no app nav).
- A decorative low-opacity SVG tile background (`body.wbg`) is available for certain pages.

---

## 5. Navigation

**Top bar, horizontal.** Brand left, links right. Links collapse responsibly.

- **Brand:** `😸 StoreMate` (cat icon + bold wordmark), gray-700.
- **Primary links (always visible), grouped with separators:**
  `Dashboard · Debts` | `Sales · Purchases · Warehouses` | `Products · Customers`
- **Overflow menu** — a hamburger (`Bars3Icon`) dropdown on the right containing the lower-traffic entities:
  `Suppliers · Shipping Companies` —divider— `Brands · Franchises` —divider— `Versions · Colors · Sizes` —divider— (admin only) `Users` — `Log Out`
- **Link style:** `uppercase tracking-wide` on mobile, `normal-case` on desktop; muted gray-500 → hover gray-900, subtle gray hover background.
- **Dropdown menu:** absolute, right-aligned, `w-50`, white (dark: blurred gray-900), `rounded-lg`, bordered; opens on hover or click (`data-open`).
- **Roles:** `guest` sees only "Log Out"; `admin` additionally sees "Users". Log out triggers a `window.confirm`.

---

## 6. Component inventory

These are the reusable building blocks in `app/frontend/components/`. Recreate these as Figma components/variants.

### 6.1 Buttons (`.btn_*`)

Base button: inline-flex, centered, `gap-1.5`, `px-2 py-1.5`, `rounded-sm`, gray-100 surface, hover gray-200, weight 480.

| Variant | Class | Look | Use |
| --- | --- | --- | --- |
| Default | (base) | gray fill | secondary actions |
| Primary | `.btn_blue` / `input[type=submit]` | blue-600 fill, white text, `h-10` | main / submit |
| Danger | `.btn_red` (often `+ .btn_rounded`) | red-100 fill, red-700 text, pill | destroy / remove |
| Success | `.btn_green` | lime tint | confirm-positive |
| Warning | `.btn_amber` | amber tint | caution |
| Info | `.btn_lightblue` | sky tint | interactive/secondary-emphasis |
| Tiny | `.btn_xs` | text-xs, tight padding | inline table actions |
| Pill | `.btn_rounded` | `rounded-full` | chips / compact actions |
| Undo | `.undo` | transparent, red text on hover | inline undo |
| Text link | `a.link` | inline, underlined (gray-400 → blue on hover) | inline links in prose |

The `<Button>` React component exposes `variant="primary" | "danger" | "default"`.

### 6.2 Forms (`forms.css`, `FormControl`, `FormInput`, `FormRow`, `FormSmartSelect`, `ResourceForm`, `FormError`, `FormSectionHeading`)

- **Text inputs / selects / textareas:** full-width, `h-10` (textarea `min-h-24`), `rounded-sm`, white surface, border gray-300/80, `pl-3 pr-10`. Selects render a custom chevron icon.
- **Search input:** `rounded-full`, `px-4`.
- **Checkbox:** custom 20×20, gray-300 border → blue-600 when checked with a white check SVG; `.red` modifier for destructive checkboxes.
- **Radio:** custom filled-ring style.
- **File input:** the file button is a blue-600 **pill**; generous vertical padding.
- **Layout:** `.form_row` = stacked on mobile, two-up row on desktop, `gap-4`. `.form_section_item` = bordered, rounded-xl card grouping a form section with `form_section_item_header` (title + actions) and `form_section_item_body`.
- **Validation:** `.field_with_errors` turns labels and borders red-700 (dark red-400); `.text_error` for messages. (Zod + `formSchema.ts` drive client validation.)
- **Highlight chips:** `<mark>` = yellow pill; `.mark_gray` = neutral pill.
- Supporting widgets: **SmartSelect / FormSmartSelect** (react-select, themed via CSS vars in `theme.css` + `reactSelectStyles.ts`), **TagSelect** (tagging), **DynamicNestedForm / NestedFormContainer** (add/remove repeating rows), **DestroyCheckbox**, **ImageUploader** (Active Storage), **TiptapEditor** (rich text, Nunito body, sky active toolbar buttons).

### 6.3 Tables (`tables.css`, `SearchableTableSection`, `ResourceIndexPage`)

The dominant data surface.

- Full-width, `table-auto`, `border-collapse`, bottom-bordered.
- **Sticky header:** `thead` sticks to top with `backdrop-blur-md`, translucent white/dark bg, and a soft shadow line. (`.thead_static` opts out.)
- **Header cells:** gray-600, semibold, bottom-aligned.
- **Rows:** `border-b-2` gray-100; hover gray-50; `.hoverable` → pointer cursor (whole-row click → detail, via `rowNavigation.ts`); `tr.selected` → amber background.
- **Inline cell editing:** `.inline_editable` cells show a sky tint + ring on hover and reveal a sky edit button; powered by `inline-cell-editing/InlineCellEditor` + `useInlineCellForm` (the project's signature interaction — edit a value directly in the table without leaving the page; sibling editors coordinate, recently-saved cells flash).

### 6.4 Cards (`cards.css`)

Stat/summary cards: `.cards` = responsive flex row, `.card` = gray-50 surface, bordered, `rounded-lg`, `pl/pt/pr-4 pb-8`. Inside: `h5` = small gray-500 label, `p` = larger value (`text-base lg:text-lg`). Used for dashboard metrics and record summaries.

### 6.5 Sections & containers (`layout.css`)

- `.section_border_base` / `.table_card` / `.form_section_item`: bordered, `rounded-xl`, horizontal-scroll on mobile. The standard "panel" wrapper.
- `.section_wide`: full-bleed beyond the container on desktop.
- `.page_search`: top bar of an index page holding the SearchBar + actions (responsive row).
- `.table_actions`: right-aligned action cell.

### 6.6 Dialogs / modals (`dialogs.css`, `SyncModal`, `MoveToWarehouseForm`)

- Native `<dialog>`: full-screen overlay, `backdrop-blur-sm`, `bg-gray-300/50`, centered, `z-999`; body scroll locks when open.
- `.dialog_content`: white (dark gray-900), `rounded-lg`, `shadow-lg`, `max-w-3xl`, nudged slightly upward on desktop.
- Escape-to-close (`useCloseOnEscape`), visibility hooks (`useModalVisibility`), confirm flows (`useConfirmAction`).
- Examples: **SyncModal** (trigger Shopify/Woo sync), **MoveToWarehouseForm** (move inventory between warehouses).

### 6.7 Tabs (`tabs.css`)

Segmented control: `.tab_bar` = pill container (gray-200/50), `.tab_btn` = pill buttons, active tab (`aria-selected="true"`) = white surface + `shadow-sm`. iOS-style segmented switch.

### 6.8 Flash messages / toasts (`widgets.css`, `flash-messages/FlashMessages`, `useFlash`)

- `.flash_toast_region`: fixed, top-center, `max-w-5xl`, overlays content (pointer-events pass-through except the toast).
- `.flash_toast`: `rounded-xl`, `shadow-xl`, `backdrop-blur`. `data-kind="notice"` → lime; `data-kind="alert"` → red.

### 6.9 Breadcrumbs (`breadcrumbs.css`, `breadcrumbs/Breadcrumbs`, `useBreadcrumbTrail`)

Trail below the nav, above page content. Built from the current Inertia page.

### 6.10 Misc widgets

- **PaymentProgressBar** / `.progress_container`: thin (`h-4`) `rounded-full` bar; right-aligned bold tiny amount label; full state → lime (`.progress_end`). Used for supplier-payment / debt progress.
- **Pagination** (`pagination.css`, Kaminari-backed): page navigation under tables.
- **ImageGallery / ZoomableThumbnail / ImageUploader** (`gallery.css`, `images.css`): product imagery, zoom-on-hover thumbnails, drag-and-drop upload (`@dnd-kit`).
- **`.rectangle_with_x`**: red diagonal-cross overlay marking a removed/cancelled item.
- **SearchBar / SearchResultsEmpty**, **CopyToClipboardButton**, **ErrorNotice**, **TipMark** (tooltip/hint marker).
- **Store icons:** `.icon_shopify`, `.icon_woo` — used to mark which channel a Sale/Product came from.

### 6.11 Icons

- **Heroicons** (`@heroicons/react`, 24px outline) for UI glyphs (e.g. hamburger `Bars3Icon`).
- **Emoji icons** via `.icn`: 😸 brand, 🐣 "Add New Record", etc. Treat emoji as legitimate iconography in this product.

---

## 7. Screen patterns (CRUD blueprint)

Every business entity follows the same four-screen Inertia pattern. Reuse this skeleton when designing any new entity.

| Screen | Composition |
| --- | --- |
| **Index** (`Index.tsx`) | `ResourceIndexPage` = `PageHeader` (H1 + "🐣 Add New Record" link) → `.section_border_base .section_wide` → `SearchableTableSection` (SearchBar in `.page_search` + sticky-header table + Pagination). Rows hoverable → navigate to Show. |
| **Show** (`Show.tsx`) | `PageHeader` (title + action `menu`) → `.section_wide` stack of sub-sections composed from `./Show/*` components (details, line items, actions). Often includes inline-editable cells, image gallery, progress bars. |
| **New / Edit** (`New.tsx` / `Edit.tsx`) | `PageHeader` → `ResourceForm` with `FormRow`/`FormControl`/`FormSmartSelect`, `form_section_item` panels, submit = `.btn_blue`. Errors via `field_with_errors`. |

`PageHeader`: `nav_header` with an `<hgroup>` (H1 + optional H3 subtitle) on the left and a `<menu class="nav_menu">` of action buttons on the right. Stacks vertically on mobile.

**Dashboard** (`pages/Dashboard/Index.tsx`) is the home screen — summary cards + debts overview (sale debts, supplier debts) and sync triggers. **Debts** (`Dashboard/Debts.tsx`) is a dedicated financial view (paginated, searchable).

---

## 8. Interaction & behavior principles

- **Server-driven SPA:** Inertia.js — full page props come from Rails, navigation feels instant (`prefetch` on nav links), no client router. Designs should assume server-rendered data, not client-side fetching.
- **Inline editing first:** editing a single field happens *in place* in tables (sky-tinted editable cells) rather than navigating to an edit form, wherever practical. This is the product's signature interaction.
- **Whole-row navigation:** index table rows are clickable to open the record.
- **Confirm destructive actions:** `window.confirm` guards log-out and removals.
- **Keyboard & a11y:** focus-visible dashed outlines, `aria-*` on nav dropdown/menus/tabs, escape-to-close on dialogs. Maintain these in new designs.
- **Dark mode parity:** every component must have a dark variant; never design light-only.
- **Mobile:** everything reflows to a single column at `< lg`; tables get horizontal scroll inside bordered panels; nav links uppercase and wrap.

---

## 9. Tech context (for handoff fidelity)

- **Stack:** Rails 8 (Inertia) + **React 19** + **Vite** + **Tailwind CSS v4** (`@theme` tokens). Rich text via **Tiptap**, selects via **react-select**, drag-and-drop via **@dnd-kit**, validation via **Zod**, images via Active Storage.
- **Styling model:** Tailwind utility classes in JSX **plus** a set of semantic component classes defined in `app/frontend/styles/application/*.css` (`.btn_*`, `.card`, `.tab_bar`, `.flash_toast`, etc.). When designing, map to these semantic classes — they are the de-facto component contract.
- **Where things live:** tokens → `styles/application/theme.css` + `base.css`; component styles → one CSS file per concern (`buttons`, `forms`, `tables`, `cards`, `dialogs`, `tabs`, `navigation`, `widgets`, …); React components → `app/frontend/components/`; screens → `app/frontend/pages/<Entity>/`.

---

## 10. Quick-start checklist for a new screen

1. Wrap in the app shell (nav + breadcrumbs + footer come from `AppLayout`).
2. Lead with a `PageHeader` (H1 in Bricolage Grotesque `font-black`, optional H3 subtitle, right-aligned action menu).
3. Put content in a bordered `rounded-xl` panel (`section_border_base`); use `section_wide` for tables.
4. Use the **Tailwind default palette** with the **semantic hue rules** from §3.2 — blue = primary, red = danger, lime = success, amber = selected, sky = editable.
5. Default radius `rounded-sm`; pills (`rounded-full`) for search, tabs, danger buttons, chips, progress.
6. Provide a **dark-mode** variant for every surface.
7. Make it reflow to one column below `lg`.
8. Prefer **inline editing** in tables over separate edit forms where it fits.

---

*This file documents the current design system as implemented. If the UI changes, update the relevant `styles/application/*.css` reference and this file together.*
