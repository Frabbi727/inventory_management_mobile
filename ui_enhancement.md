# 📱 Mobile Salesman App – UI Enhancement (Production Ready)

---

# 🎯 Objective

Improve UI/UX of existing Flutter app without changing:

- API layer ❌
- Repository ❌
- Models ❌
- Business logic ❌

Focus only on:

- UI flow
- screen clarity
- usability
- speed of order taking

---

# 🧠 Business Summary

Salesman creates order using:

1. Customer (required)
2. Products (required)
3. Optional:
    - discount
    - note

Backend handles:
- stock validation
- pricing
- totals

Mobile app:
👉 only shows preview

---

# 🔄 Final Order Flow

Start Order (FAB)
→ Customer
→ Products
→ Cart
→ Confirm
→ Success

---

# 🪜 Stepper Design (IMPORTANT)

Use top horizontal stepper:

Customer → Products → Cart → Confirm

## Rules

- ✔ completed
- ● current
- ○ pending

## Behavior

- clickable
- allow back navigation
- do NOT block strictly
- show inline warnings instead

---

# 🧭 Navigation

## Bottom Tabs

- Home
- Orders
- Customers
- Profile

## FAB

+ New Order

👉 Only entry point for order flow

---

# 📱 Screen Responsibilities

## 1. Customer Screen

Action:
→ Select customer

UI:
- search by name/phone
- list
- add customer button

Rule:
- must select before proceeding

---

## 2. Product Screen

Action:
→ Add products

UI:
- product list
- stock visible
- price visible
- quantity stepper

Rule:
- no product detail page needed
- fast add to cart

---

## 3. Cart Screen (CORE)

Action:
→ Adjust order

UI:
- selected customer
- cart items
- discount input
- note input
- sticky footer

### Sticky Footer

Subtotal: ৳XXX  
Total: ৳XXX

[ Confirm Order ]

---

## 4. Confirm Screen

Action:
→ Final review

UI:
- customer
- items
- totals

Message:
⚠️ Final total will be confirmed by server

---

## 5. Success Screen

Action:
→ Done

UI:
- order number
- total
- customer

Buttons:
- New Order
- View Orders

---

# ⚡ UX Rules

1. Customer must be selected first
2. Stock must always be visible
3. Total must update instantly
4. Avoid popup errors
5. Use inline validation
6. Confirm button always visible
7. Minimum taps

---

# 🧩 Required UI Components

Create reusable widgets:

- StepperWidget
- ProductCard
- CartItemWidget
- SummaryFooter
- CustomerTile

---

# 🔧 Refactor Strategy

## DO NOT TOUCH

- API calls
- repository
- backend contract

## ONLY UPDATE

- screens
- widgets
- navigation

---

# 🤖 CODEX PROMPTS (IMPORTANT)

---

## Prompt 1: Stepper Integration

Refactor order flow UI to include a top horizontal stepper.

Steps:
- Customer
- Products
- Cart
- Confirm

Requirements:
- reusable widget
- highlight current step
- clickable steps
- allow back navigation
- no business logic change

---

## Prompt 2: Order Flow Fix

Refactor navigation flow:

- enforce customer → products → cart → confirm
- customer must be selected first
- use stepper navigation
- keep existing API calls unchanged

---

## Prompt 3: Product UI

Improve product list UI:

- show stock clearly
- show selling price
- add quantity stepper
- allow direct add to cart
- no backend change

---

## Prompt 4: Cart UI

Improve cart screen:

- add sticky footer
- show subtotal and total
- inline stock validation
- quantity stepper
- confirm button always visible

---

## Prompt 5: Customer Screen

Improve customer selection:

- search by name or phone
- list view
- select button
- add customer option
- return selected customer

---

# 🚀 Final Goal

Make app:

- fast for salesman
- easy to understand
- low error rate
- clean UI
- business aligned

---

# ✅ Summary

This update will:

- improve order speed
- reduce mistakes
- keep backend untouched
- align UI with business flow