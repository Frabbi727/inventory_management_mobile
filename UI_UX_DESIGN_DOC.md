# UI/UX Design Document
## Inventory Management & Sales Mobile App

> **Purpose:** This document describes all screens, user flows, and interaction patterns for the Inventory Management & Sales app. It is intended for use with Claude Design (or any UI/UX design tool) to produce a professional, polished interface. The underlying business logic remains unchanged — this document is a design brief only.

---

## 1. Business Overview

A **B2B field sales mobile app** used by salesmen to:
- Take customer orders on the go
- Browse products and check live stock levels
- Create and manage customers
- Track order history

**Primary User:** Field Salesman (single role, no admin panel in mobile)

**Core Principle:** Mobile is for fast order entry. The backend is the final authority on pricing, stock deduction, and totals.

---

## 2. Brand & Design Direction

### Personality
**Professional · Clean · Fast · Trustworthy**

The app is a work tool — not a consumer app. Design should feel like a confident B2B SaaS product: structured, clear, minimal friction.

### Recommended Visual Style
- **Color Palette:** Deep navy/indigo primary (`#1A237E` or similar), white surfaces, accent teal/green for success states, amber for warnings
- **Typography:** Roboto or Inter — readable at small sizes, strong hierarchy
- **Iconography:** Outlined icons (Material or Lucide) — consistent weight
- **Density:** Medium-density UI — show enough info per screen without overwhelming
- **Cards:** Rounded corners (8–12px), subtle shadow (elevation 1–2), white on light grey background
- **Spacing:** 16px base grid, 8px increments

### Tone of Micro-copy
Short, action-oriented. "Select Customer", "Add to Order", "Place Order" — not "Click here to proceed to the next step".

---

## 3. App Structure

```
App
├── Splash Screen
├── Login Screen
└── Home (Bottom Navigation)
    ├── [Tab 1] Dashboard
    ├── [Tab 2] Orders
    ├── [Tab 3] Customers
    └── [Tab 4] Profile
        └── (FAB) New Order Flow
            ├── Step 1 — Select Customer
            │   ├── Customer Search
            │   └── Add New Customer
            ├── Step 2 — Add Products
            ├── Step 3 — Review Cart
            ├── Step 4 — Confirm Order
            └── Order Success
```

---

## 4. Screen-by-Screen Design Specifications

---

### 4.1 Splash Screen

**Purpose:** Session restoration — check if user is already logged in.

**Layout:**
- Full-screen centered layout
- App logo (large, centered vertically at ~40% height)
- App name below logo
- Subtle circular progress indicator at bottom center
- Background: Brand primary color or a clean gradient

**Interaction:**
- Auto-transitions to Login or Home — no user action required
- Duration: ~1.5–2s

**Design Notes:**
- Keep it minimal — this is just a loading moment
- Consider a subtle fade-in animation for the logo

---

### 4.2 Login Screen

**Purpose:** Authenticate the salesman with email/phone + password.

**Layout (single scrollable form):**

```
┌─────────────────────────────┐
│                             │
│        [App Logo]           │
│      Welcome Back           │
│   Sign in to continue       │
│                             │
│  ┌─────────────────────┐   │
│  │  Email or Phone      │   │
│  └─────────────────────┘   │
│                             │
│  ┌─────────────────────┐   │
│  │  Password        👁  │   │
│  └─────────────────────┘   │
│                             │
│  [         Sign In        ] │  ← Primary CTA button, full width
│                             │
│   (Error message area)      │
│                             │
└─────────────────────────────┘
```

**States:**
- Default
- Loading (button shows spinner, inputs disabled)
- Error (inline error below the form, highlight affected field)

**Design Notes:**
- Password field has a show/hide toggle (eye icon)
- "Sign In" button uses brand primary color, full-width, rounded
- Keyboard type: email for login field, secure for password
- No "Remember Me" or "Forgot Password" — not in scope

---

### 4.3 Home Screen (Shell)

**Purpose:** Main container with bottom navigation and FAB.

**Bottom Navigation Tabs:**

| # | Icon | Label |
|---|------|-------|
| 1 | Home | Dashboard |
| 2 | Receipt | Orders |
| 3 | People | Customers |
| 4 | Person | Profile |

**FAB (Floating Action Button):**
- Position: Bottom-right, above bottom nav
- Icon: `+` or `add_shopping_cart`
- Label (extended): "New Order"
- Color: Accent color (teal or green)
- Visible on all tabs

**Design Notes:**
- Active tab icon + label uses primary color
- Inactive tab uses grey
- FAB should have a slight shadow lift to stand out
- Consider hiding FAB on Profile tab

---

### 4.4 Dashboard Tab (Tab 1)

**Purpose:** At-a-glance view of the salesman's current draft/active order and quick stats.

**Layout:**

```
┌─────────────────────────────┐
│  Good morning, [Name]  🌤  │  ← Personalized greeting
│  Monday, 25 May 2026        │
├─────────────────────────────┤
│                             │
│  ┌───────────────────────┐  │
│  │  📦 Current Draft     │  │  ← Draft order card (if exists)
│  │  Customer: John & Co  │  │
│  │  3 items · ৳ 4,500    │  │
│  │  [Continue Order →]   │  │
│  └───────────────────────┘  │
│                             │
│  Quick Actions              │
│  ┌──────┐  ┌──────┐        │
│  │ New  │  │ View │        │
│  │Order │  │Orders│        │
│  └──────┘  └──────┘        │
│                             │
└─────────────────────────────┘
```

**States:**
- With draft order: Shows draft summary card + "Continue Order" button
- No draft: Shows "Start a New Order" prompt with illustration
- Loading: Skeleton cards

**Design Notes:**
- Greeting section gives the app a human touch
- Draft order card uses a warm accent (e.g., amber border) to signal "in progress"
- Quick action tiles are secondary — FAB is the primary entry point

---

### 4.5 Orders Tab (Tab 2)

**Purpose:** Browse the salesman's full order history, tap to see details.

**Layout:**

```
┌─────────────────────────────┐
│  Orders                     │
│  ─────────────────────────  │
│  ┌───────────────────────┐  │
│  │ #ORD-0042             │  │
│  │ ABC Traders           │  │
│  │ 5 items  ·  ৳ 12,500  │  │
│  │ 24 May 2026      [→]  │  │
│  └───────────────────────┘  │
│  ┌───────────────────────┐  │
│  │ #ORD-0041             │  │
│  │ ...                   │  │
│  └───────────────────────┘  │
│  ...                        │
│  [Loading more...]          │  ← Infinite scroll indicator
└─────────────────────────────┘
```

**Order Card Fields:**
- Order number (bold, primary color)
- Customer name
- Item count + grand total
- Order date
- Status badge (if applicable)

**States:**
- Loading: Skeleton list items (3–4 placeholder cards)
- Loaded: Scrollable list
- End of list: "No more orders" message
- Empty: Illustration + "No orders yet. Tap + to create one."
- Error: Retry button

**Design Notes:**
- Cards should have a clean divider or slight shadow separation
- Date formatted as "24 May 2026" — not timestamp
- Status badge if order has a status field (pending, confirmed, etc.)
- Infinite scroll — load more silently as user scrolls near bottom

---

### 4.6 Order Details Screen

**Purpose:** Full view of a single order — customer, items, pricing breakdown.

**Layout:**

```
┌─────────────────────────────┐
│ ← Order #ORD-0042           │  ← AppBar with back button
│ 24 May 2026 · Confirmed     │
├─────────────────────────────┤
│  CUSTOMER                   │
│  ABC Traders                │
│  📞 01700-000000            │
├─────────────────────────────┤
│  ITEMS  (5)                 │
│  ┌─────────────────────┐   │
│  │ Product Name        │   │
│  │ 3 units × ৳500 = ৳1,500 │
│  └─────────────────────┘   │
│  ... more items             │
├─────────────────────────────┤
│  PRICING SUMMARY            │
│  Subtotal          ৳ 12,000 │
│  Discount (5%)    − ৳  600 │
│  ─────────────────────────  │
│  Grand Total       ৳ 11,400 │
├─────────────────────────────┤
│  NOTE                       │
│  "Deliver before noon"      │
└─────────────────────────────┘
```

**Design Notes:**
- Section headers in small caps or muted label style
- Pricing summary uses a bordered card with subtle background tint
- Grand total in large bold text
- Note section only shown if note exists
- Salesman info section (name) visible if needed

---

### 4.7 Customers Tab (Tab 3)

**Purpose:** Browse all customers, search, and tap to use in an order.

**Layout:**

```
┌─────────────────────────────┐
│  Customers                  │
│  ┌─────────────────────┐   │
│  │ 🔍 Search customers  │   │  ← Search bar, always visible
│  └─────────────────────┘   │
│  ─────────────────────────  │
│  ┌───────────────────────┐  │
│  │ 👤 ABC Traders        │  │
│  │    📞 01700-000000    │  │
│  │    📍 Mirpur, Dhaka   │  │
│  └───────────────────────┘  │
│  ...                        │
└─────────────────────────────┘
```

**Customer Card Fields:**
- Name (bold)
- Phone number
- Area/Address

**States:**
- Search active: Filtered results update on type (debounced)
- No results: "No customers found. Add one below." + "Add Customer" button
- Loading: Skeleton cards

**Design Notes:**
- Search bar is always visible (sticky top), not collapsed
- Debounced search — no need for a "Search" button
- List is paginated with infinite scroll

---

### 4.8 Profile Tab (Tab 4)

**Purpose:** Show logged-in user info and provide logout option.

**Layout:**

```
┌─────────────────────────────┐
│                             │
│        👤                   │
│     [User Name]             │
│     Salesman                │  ← Role badge
│                             │
│  ─────────────────────────  │
│  📧 user@example.com        │
│  📞 01700-000000            │
│                             │
│  ─────────────────────────  │
│                             │
│  [      Sign Out       ]    │  ← Outlined or danger-tinted button
│                             │
└─────────────────────────────┘
```

**Design Notes:**
- Avatar placeholder (initials in colored circle, no photo upload)
- Role badge: small chip ("Salesman") below name
- Sign Out button should be visually distinct — red tint or outlined with warning color
- Confirm dialog before logout: "Are you sure you want to sign out?"

---

## 5. New Order Flow (Multi-Step)

This is the most important flow in the app. The FAB launches a full-screen modal or a new route with a stepper.

### 5.0 Flow Overview

```
FAB Tap
   ↓
[Step 1] Select Customer
   ↓
[Step 2] Add Products
   ↓
[Step 3] Review Cart
   ↓
[Step 4] Confirm & Submit
   ↓
Order Success Screen
```

### Stepper Design

**Top stepper bar** (persistent across all steps):
```
● ─────── ○ ─────── ○ ─────── ○
Customer  Products   Cart    Confirm
```
- Active step: filled circle, label bold
- Completed step: checkmark circle, primary color
- Future step: empty circle, grey
- Progress bar or line connects steps

**Navigation:**
- "Back" button (top-left or bottom-left)
- "Next" / "Continue" button (bottom-right, primary)
- Bottom bar contains Back + Next for thumb reach

---

### 5.1 Step 1 — Select Customer

**Purpose:** Pick an existing customer or create a new one for this order.

**Layout:**

```
┌─────────────────────────────┐
│ ← New Order     Step 1 of 4 │
│ Select Customer             │
│ ─────────────────────────── │
│  ┌─────────────────────┐   │
│  │ 🔍 Search by name/phone│ │
│  └─────────────────────┘   │
│                             │
│  ┌───────────────────────┐  │
│  │ ☑ ABC Traders  ✓     │  │  ← Selected state
│  │   01700-000000        │  │
│  └───────────────────────┘  │
│  ┌───────────────────────┐  │
│  │   XYZ Suppliers       │  │
│  │   01800-111111        │  │
│  └───────────────────────┘  │
│                             │
│  + Add New Customer         │  ← Text link / secondary button
│                             │
│  ─────────────────────────  │
│  [     Continue →          ]│
└─────────────────────────────┘
```

**States:**
- Selected customer: Card gets a check icon + border highlight
- Loading search results: Skeleton rows
- "Continue" button: Disabled (grey) until a customer is selected

**Design Notes:**
- Only one customer can be selected at a time
- Selection persists if user navigates back

---

### 5.2 Add New Customer (Sub-screen from Step 1)

**Purpose:** Create a new customer and return them as selected.

**Layout:**

```
┌─────────────────────────────┐
│ ← Add New Customer          │
│ ─────────────────────────── │
│  Name *                     │
│  ┌─────────────────────┐   │
│  │ Full Name            │   │
│  └─────────────────────┘   │
│                             │
│  Phone *                    │
│  ┌─────────────────────┐   │
│  │ 01X-XXXXXXXX         │   │
│  └─────────────────────┘   │
│                             │
│  Address                    │
│  ┌─────────────────────┐   │
│  │ Street / Area        │   │
│  └─────────────────────┘   │
│                             │
│  Area                       │
│  ┌─────────────────────┐   │
│  │ Dhaka / Chittagong…  │   │
│  └─────────────────────┘   │
│                             │
│  [     Save Customer       ]│
└─────────────────────────────┘
```

**Design Notes:**
- `*` required fields (Name, Phone)
- Inline validation errors below each field on submit
- On success: navigates back and auto-selects the new customer

---

### 5.3 Step 2 — Add Products

**Purpose:** Browse products and add them to the cart.

**Layout:**

```
┌─────────────────────────────┐
│ ← New Order     Step 2 of 4 │
│ Add Products                │
│ ─────────────────────────── │
│  ┌─────────────────────┐   │
│  │ 🔍 Search products   │   │
│  └─────────────────────┘   │
│                             │
│  ┌───────────────────────┐  │
│  │ Product Name          │  │
│  │ SKU: ABC-001          │  │
│  │ Stock: 120 pcs        │  │
│  │ ৳ 500 / pcs  [+ Add] │  │  ← Add button per product
│  └───────────────────────┘  │
│  ┌───────────────────────┐  │
│  │ ...                   │  │
│  └───────────────────────┘  │
│                             │
│  ─────────────────────────  │
│  🛒 3 items added           │  ← Cart summary chip / bottom bar
│  [     Review Cart →       ]│
└─────────────────────────────┘
```

**Product Card Fields:**
- Product name (bold)
- SKU (small, muted)
- Stock level with color indicator: green (healthy), amber (low), red (critical)
- Selling price + unit
- "Add" button — taps once to add, shows quantity stepper if already in cart

**States:**
- Product not in cart: Shows `[+ Add]` button
- Product in cart: Shows `[− 2 +]` quantity stepper inline
- Out of stock: Card is muted, "Out of Stock" badge, no add button
- Cart has items: Bottom bar shows count + "Review Cart" button
- Cart is empty: "Review Cart" button is disabled

**Design Notes:**
- Search is debounced — updates list as user types
- Infinite scroll for product list
- Cart item count badge should also appear on the FAB / step indicator
- Low stock warning: amber text, e.g., "Only 5 left"

---

### 5.4 Step 3 — Review Cart

**Purpose:** Review and adjust items, apply discount, add notes.

**Layout:**

```
┌─────────────────────────────┐
│ ← New Order     Step 3 of 4 │
│ Review Cart                 │
│ ─────────────────────────── │
│  ┌───────────────────────┐  │
│  │ Product A             │  │
│  │ [−] 2 [+]   ৳ 1,000  │  │  ← Qty stepper + line total
│  │                  [🗑] │  │  ← Remove icon
│  └───────────────────────┘  │
│  ┌───────────────────────┐  │
│  │ Product B             │  │
│  │ [−] 1 [+]   ৳   500  │  │
│  └───────────────────────┘  │
│                             │
│  Discount                   │
│  ┌──────────────┐ ┌──────┐ │
│  │ Amount/Value │ │ % ৳  │ │  ← Discount type toggle + value
│  └──────────────┘ └──────┘ │
│                             │
│  Note (optional)            │
│  ┌─────────────────────┐   │
│  │ Any delivery notes…  │   │
│  └─────────────────────┘   │
│                             │
│  ─────────────────────────  │
│  Subtotal          ৳ 1,500  │
│  Discount         − ৳  75  │
│  ─────────────────────────  │
│  Estimated Total   ৳ 1,425  │  ← "Estimated" — final set by server
│                             │
│  [     Continue →          ]│
└─────────────────────────────┘
```

**Design Notes:**
- Pricing summary is an "estimate" — label must say "Estimated Total" or have a small info icon
- Discount type toggle: Chip/segmented control with "৳ Fixed" and "% Percent"
- Removing all items: Warn user ("Cart will be empty. Go back?")
- Discount validation happens inline

---

### 5.5 Step 4 — Confirm Order

**Purpose:** Final review before submission. Read-only summary.

**Layout:**

```
┌─────────────────────────────┐
│ ← New Order     Step 4 of 4 │
│ Confirm Order               │
│ ─────────────────────────── │
│  CUSTOMER                   │
│  ABC Traders · 01700-000000 │
│                             │
│  ORDER ITEMS  (3)           │
│  Product A × 2    ৳ 1,000  │
│  Product B × 1    ৳   500  │
│  ...                        │
│                             │
│  PRICING                    │
│  Subtotal          ৳ 1,500  │
│  Discount (5%)    − ৳   75  │
│  Estimated Total   ৳ 1,425  │
│                             │
│  ⚠ Final total confirmed    │
│    by server after placing  │
│                             │
│  NOTE                       │
│  "Deliver before noon"      │
│                             │
│  ─────────────────────────  │
│  [     Place Order         ]│
└─────────────────────────────┘
```

**States:**
- Default: All info visible, "Place Order" enabled
- Submitting: Button shows loading spinner, all tappable elements disabled
- Error: Error banner at top, button re-enabled

**Design Notes:**
- Server disclaimer (⚠) must be visible and clear but not alarming — use an info color, not red
- "Place Order" is the highest-priority CTA — make it large and bold
- Consider a haptic feedback + animation on successful submission

---

### 5.6 Order Success Screen

**Purpose:** Confirmation that the order was placed. Show final server-confirmed details.

**Layout:**

```
┌─────────────────────────────┐
│                             │
│          ✅                 │
│    Order Placed!            │
│                             │
│   Order #ORD-0043           │
│   ABC Traders               │
│   Grand Total: ৳ 1,425      │
│                             │
│  ─────────────────────────  │
│                             │
│  [   View Order Details   ] │  ← Secondary button
│  [     New Order          ] │  ← Primary button
│                             │
└─────────────────────────────┘
```

**Design Notes:**
- Large success checkmark (animated — scale/bounce in)
- Order number prominent and copyable (tap to copy)
- Two CTAs: "View Order Details" (go to order detail screen) and "New Order" (restart flow)
- No automatic redirect — let the salesman decide next action

---

## 6. Empty States

Every list screen needs a designed empty state. These should use a simple illustration + text + optional CTA.

| Screen | Illustration Idea | Message | CTA |
|--------|------------------|---------|-----|
| Orders (empty) | Box with magnifying glass | "No orders yet" | "Create New Order" |
| Customers (no results) | Person with question mark | "No customers found" | "Add New Customer" |
| Product search (no results) | Empty shelf | "No products match your search" | Clear search |
| Dashboard (no draft) | Clipboard | "Ready to take an order?" | "Start New Order" |

---

## 7. Loading & Error States

### Loading Skeletons
All list screens should use **skeleton loading** (shimmer effect) instead of a spinner for perceived performance:
- Orders list: 3–4 skeleton cards
- Products list: 3–5 skeleton product rows
- Customers list: 3–4 skeleton customer rows

### Error States
When an API call fails, show:
- Icon (warning or network icon)
- Short message: "Couldn't load orders. Check your connection."
- "Try Again" button

### Inline Validation Errors
Form fields show errors below the input in red on:
- Form submission attempt
- Blur (when user leaves a required field empty)

---

## 8. Navigation Patterns

| Gesture / Action | Behavior |
|-----------------|----------|
| Back button (AppBar) | Pop screen or go to previous step |
| Swipe right (Android) | Back navigation |
| FAB tap | Open new order flow |
| Tab tap | Switch tab (no history push) |
| Order card tap | Navigate to Order Details |
| Customer card tap | Select customer (in flow) |
| Product "Add" tap | Adds to cart (no navigation) |
| Order Success "New Order" | Reset order flow and start fresh |
| Logout confirm | Navigate to Login, clear stack |

---

## 9. Key UX Principles

1. **Thumb-friendly:** Primary CTAs at the bottom. Critical actions within thumb reach.
2. **Minimal taps to order:** FAB → Select Customer → Add Product → Submit should take as few taps as possible.
3. **No dead ends:** Every error state has a recovery path (retry, back, add new).
4. **Clarity over cleverness:** Labels are literal. "Place Order" not "Proceed". "Sign Out" not "Exit".
5. **Trust through feedback:** Every action gives visible feedback — loading state, success message, or error.
6. **Backend is truth:** Show "Estimated" total until server confirms. Never mislead the salesman about final price.
7. **Fast product search:** Debounced search in product list is critical for speed — salesmen know product names.

---

## 10. Screen Inventory (Full List)

| # | Screen Name | Type | Route |
|---|-------------|------|-------|
| 1 | Splash | Full-screen | `/splash` |
| 2 | Login | Full-screen | `/login` |
| 3 | Home Shell | Container | `/home` |
| 4 | Dashboard | Tab | (tab 0) |
| 5 | Orders List | Tab | (tab 1) |
| 6 | Order Details | Push | `/orders/details` |
| 7 | Customers List | Tab | (tab 2) |
| 8 | Profile | Tab | (tab 3) |
| 9 | New Order — Step 1 (Customer) | Push | `/orders/new` |
| 10 | Add New Customer | Push | `/customers/add` |
| 11 | New Order — Step 2 (Products) | Step | (step 1) |
| 12 | New Order — Step 3 (Cart) | Step | (step 2) |
| 13 | New Order — Step 4 (Confirm) | Step | (step 3) |
| 14 | Order Success | Push | `/orders/success` |

---

## 11. Interaction Micro-details

- **Add to cart tap:** Brief scale animation on the + button (scale 1 → 1.2 → 1)
- **Order success checkmark:** Draw or bounce-in animation
- **Step progress:** Animated transition between stepper steps (slide left)
- **Cart count badge:** Number badge on cart icon animates when count changes
- **Pull to refresh:** Standard pull-to-refresh on Orders and Customers lists
- **Discount toggle:** Smooth slide animation on segment switch
- **Logout confirm:** Bottom sheet dialog, not a small alert popup

---

*End of UI/UX Design Document*
*Version: 1.0 | App: Inventory Management & Sales Mobile | Platform: iOS + Android (Flutter)*
