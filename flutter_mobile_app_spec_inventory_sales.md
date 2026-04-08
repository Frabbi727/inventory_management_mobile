# Software Requirements Specification (SRS)

## Mobile Salesman App
### Inventory + Sales + Order Management System

### Based on Existing Web Salesman Business Logic

---

# 1. Introduction

## 1.1 Purpose
This document defines the software requirements for the Flutter mobile salesman application. The mobile app will use the same backend business rules as the existing Laravel web salesman system. It is not a separate business process. It is another client of the same system.

This document includes:
- business logic
- functional requirements
- API requirements
- validation rules
- technical guidance
- step-by-step Codex prompts

## 1.2 Intended Audience
This document is intended for:
- business owner
- Flutter developer
- Laravel developer
- QA tester
- Codex or AI coding assistant

## 1.3 Technology Stack
- **Mobile App:** Flutter
- **Backend API:** Laravel
- **Authentication:** Bearer token
- **API Format:** JSON

## 1.4 Product Scope
The mobile app is used by field salesmen to:
- log in
- load products and stock
- search or create customers
- build cart
- apply discount
- submit order
- view final order details
- view own order history
- logout

The app must stay aligned with the web salesman flow and backend business rules.

---

# 2. Overall Business Description

## 2.1 Business Context
The business already has a web-based salesman flow. The mobile app must follow the same backend business.

That means:
- products come from the same product database
- customers come from the same customer database
- stock comes from the same inventory records
- orders are saved into the same order system
- stock deduction uses the same inventory logic
- order history follows the same role-based visibility rules

## 2.2 Core Principle
**Mobile previews, backend decides.**

The mobile app may calculate preview values for better user experience, but the backend is the final authority for:
- stock validation
- selling price
- subtotal
- discount validation
- discount amount
- grand total
- order confirmation
- stock deduction
- stock movement creation

## 2.3 User Role
The mobile app is mainly for the **Salesman** role.

A salesman can:
- log in
- see products
- see stock
- search customer
- create customer
- take order
- apply discount
- submit order
- view own order history
- view order details
- logout

---

# 3. Business Logic

## 3.1 Login Business Flow
1. Salesman opens the app.
2. Salesman enters login credentials.
3. App sends login request to backend.
4. Backend authenticates the user.
5. Backend returns token and logged-in user data.
6. App stores token and user info locally.
7. App redirects to home screen.

## 3.2 Product Loading Business Flow
1. Salesman opens the product list screen.
2. App calls product list API.
3. Backend returns paginated active products.
4. App shows product information including stock.
5. Salesman can search by product name or SKU.

## 3.3 Customer Handling Business Flow
1. Salesman searches an existing customer by name or phone.
2. If found, salesman selects the customer.
3. If not found, salesman creates a new customer.
4. Backend saves the customer.
5. App attaches the selected customer to the current order.

## 3.4 Order Creation Business Flow
1. Salesman adds products to cart.
2. Salesman updates quantity.
3. App validates preview quantity against current visible stock.
4. App calculates line totals and subtotal for preview.
5. Salesman optionally adds discount.
6. App previews discount amount and grand total.
7. Salesman confirms order.
8. App sends minimal order request to backend.
9. Backend re-validates customer, products, stock, and discount.
10. Backend loads current selling prices.
11. Backend calculates subtotal, discount amount, and grand total.
12. Backend creates the confirmed order.
13. Backend saves order items.
14. Backend deducts stock.
15. Backend creates stock movement entries.
16. Backend returns final order details.
17. App shows invoice/order detail screen.

## 3.5 Order History Business Flow
1. Salesman opens order history.
2. App calls order history API.
3. Backend returns paginated order list.
4. If logged-in user is salesman, backend scopes orders to that salesman.
5. Salesman taps an order.
6. App loads order details.
7. Backend returns full order data.
8. App displays order details.

## 3.6 Logout Business Flow
1. Salesman taps logout.
2. App may call logout API.
3. App clears token and user session.
4. App redirects to login screen.

---

# 4. Functional Requirements

## 4.1 Authentication Module
### Features
- login
- logout
- current profile fetch
- token persistence
- session restore on app restart

### Requirements
- app must allow login using login identifier and password
- token must be stored locally after successful login
- app must support session check on startup
- app must clear token and user info on logout

---

## 4.2 Product Module
### Features
- product list
- product search
- product details
- stock display

### Requirements
- app must load paginated products from backend
- app must show product name, SKU, selling price, stock, and unit when available
- app must allow search by query parameter `q`
- app may filter active products only if backend supports that query

---

## 4.3 Customer Module
### Features
- customer search
- customer details
- create customer
- select customer for order

### Requirements
- app must allow searching customer by name or phone
- app must allow creating a customer with required fields
- app must return the selected customer to the order flow

---

## 4.4 Cart Module
### Features
- add product to cart
- update quantity
- remove product
- clear cart
- preview subtotal

### Requirements
- cart must prevent invalid quantities
- quantity must never be less than 1
- app should warn if quantity exceeds visible stock
- cart should calculate preview line total and preview subtotal

---

## 4.5 Discount Module
### Features
- fixed amount discount
- percentage discount
- discount preview

### Requirements
- discount type must support `amount` and `percentage`
- amount discount must not exceed subtotal in preview logic
- percentage discount must stay between 0 and 100 in preview logic
- preview grand total must never be negative

---

## 4.6 Order Module
### Features
- create order
- submit order
- show order result
- view order details
- view order history

### Requirements
- order submit requires customer selection
- order submit requires at least one item
- product lines in a request must be distinct
- app must send minimal payload to backend
- backend response must be used as final order truth

---

## 4.7 Profile Module
### Features
- show user info
- logout

### Requirements
- app must display basic logged-in user information
- app must provide logout action

---

# 5. Business Rules

1. Only authenticated active users can access protected APIs.
2. Salesman can only see his own orders where backend role rules apply.
3. Customer is required before order submit.
4. At least one order item is required.
5. Each order line must use a different product.
6. Quantity must be greater than 0.
7. Quantity must not exceed available stock.
8. Visible stock in the app is preview only; backend checks stock again during order creation.
9. Selling price comes from backend product data and is finalized by backend during order creation.
10. Supported discount types are `amount` and `percentage`.
11. Amount discount cannot exceed subtotal.
12. Percentage discount must be between 0 and 100.
13. Grand total cannot become negative.
14. Successful order creation must:
   - generate `order_no`
   - save order as `confirmed`
   - save order items
   - deduct stock
   - write stock movement rows
15. Logout must clear token and local session data.
16. Mobile app must not treat preview totals as final totals.
17. Mobile app should not send authoritative price and total fields unless backend explicitly requires them.

---

# 6. API Requirements

## 6.1 Base Configuration
- Base URL: `https://ordermanage.b2bhaat.com`
- API Prefix: `/api`

## 6.2 Protected Request Headers
Current production requires protected requests to use:
```http
X-Authorization: Bearer {token}
Accept: application/json
Content-Type: application/json
```

### Important Note
The current production host strips the standard `Authorization` header before Laravel receives it. Because of that, the mobile app must currently support `X-Authorization` for protected APIs.

If the server is fixed later, the app can be updated to use standard:
```http
Authorization: Bearer {token}
```

## 6.3 API Groups
### Auth
- `POST /api/login`
- `POST /api/logout`
- `GET /api/me`

### Products
- `GET /api/products`
- `GET /api/products/{id}`

### Customers
- `GET /api/customers`
- `GET /api/customers/{id}`
- `POST /api/customers`

### Orders
- `GET /api/orders`
- `GET /api/orders/{id}`
- `POST /api/orders`

---

# 7. Endpoint Specifications

## 7.1 Login
### Endpoint
`POST /api/login`

### Request
```json
{
  "login": "salesman@example.com",
  "password": "secret",
  "device_name": "flutter-mobile"
}
```

### Success Response Shape
```json
{
  "message": "Login successful.",
  "data": {
    "token": "plain-text-token",
    "token_type": "Bearer",
    "user": {
      "id": 1,
      "name": "Salesman Name",
      "email": "sales@example.com",
      "phone": "01700000000",
      "status": "active",
      "role": {
        "id": 3,
        "name": "Salesman",
        "slug": "salesman"
      }
    }
  }
}
```

### Notes
- backend accepts normalized `login`
- login identifier may be email or phone depending on backend logic

---

## 7.2 Logout
### Endpoint
`POST /api/logout`

### Success Response
```json
{
  "message": "Logout successful."
}
```

---

## 7.3 Me / Profile
### Endpoint
`GET /api/me`

### Success Response
```json
{
  "data": {
    "id": 1,
    "name": "Salesman Name",
    "email": "sales@example.com",
    "phone": "01700000000",
    "status": "active",
    "role": {
      "id": 3,
      "name": "Salesman",
      "slug": "salesman"
    }
  }
}
```

---

## 7.4 Product List
### Endpoint
`GET /api/products`

### Query Params
- `q`
- `status`
- `page`

### Example
```http
GET /api/products?q=milk&status=active&page=1
```

### Product Item Shape
```json
{
  "id": 10,
  "name": "Product Name",
  "sku": "SKU-001",
  "purchase_price": 80,
  "selling_price": 100,
  "minimum_stock_alert": 5,
  "status": "active",
  "current_stock": 42,
  "category": {
    "id": 2,
    "name": "Category Name"
  },
  "unit": {
    "id": 1,
    "name": "Piece",
    "short_name": "pc"
  }
}
```

### Recommendation
If salesmen should not see cost price, backend should remove `purchase_price` from the mobile-facing product resource.

---

## 7.5 Product Details
### Endpoint
`GET /api/products/{id}``

### Response
```json
{
  "data": {
    "id": 10,
    "name": "Product Name",
    "sku": "SKU-001",
    "purchase_price": 80,
    "selling_price": 100,
    "minimum_stock_alert": 5,
    "status": "active",
    "current_stock": 42,
    "category": {
      "id": 2,
      "name": "Category Name"
    },
    "unit": {
      "id": 1,
      "name": "Piece",
      "short_name": "pc"
    }
  }
}
```

---

## 7.6 Customer List / Search
### Endpoint
`GET /api/customers`

### Query Params
- `q`
- `phone`
- `page`

### Example
```http
GET /api/customers?q=rahim&page=1
GET /api/customers?phone=017
```

### Customer Item Shape
```json
{
  "id": 5,
  "name": "Customer Name",
  "phone": "01700000000",
  "address": "Full address",
  "area": "Mirpur",
  "created_by": {
    "id": 1,
    "name": "Salesman Name"
  }
}
```

---

## 7.7 Customer Details
### Endpoint
`GET /api/customers/{id}`

### Response
```json
{
  "data": {
    "id": 5,
    "name": "Customer Name",
    "phone": "01700000000",
    "address": "Full address",
    "area": "Mirpur",
    "created_by": {
      "id": 1,
      "name": "Salesman Name"
    }
  }
}
```

---

## 7.8 Create Customer
### Endpoint
`POST /api/customers`

### Request
```json
{
  "name": "Customer Name",
  "phone": "01700000000",
  "address": "Full address",
  "area": "Mirpur"
}
```

### Validation
- `name`: required
- `phone`: required
- `address`: required
- `area`: optional

### Success Response
```json
{
  "message": "Customer created successfully.",
  "data": {
    "id": 5,
    "name": "Customer Name",
    "phone": "01700000000",
    "address": "Full address",
    "area": "Mirpur",
    "created_by": {
      "id": 1,
      "name": "Salesman Name"
    }
  }
}
```

---

## 7.9 Order History
### Endpoint
`GET /api/orders`

### Query Params
- `status`
- `customer_id`
- `start_date`
- `end_date`
- `page`

### Example
```http
GET /api/orders?status=confirmed&start_date=2026-04-01&end_date=2026-04-08
```

### Notes
- if logged-in user is salesman, backend scopes results to that salesman

---

## 7.10 Order Details
### Endpoint
`GET /api/orders/{id}`

### Response
```json
{
  "data": {
    "id": 99,
    "order_no": "ORD-ABC12345",
    "order_date": "2026-04-08",
    "subtotal": 1500,
    "discount_type": "amount",
    "discount_value": 100,
    "discount_amount": 100,
    "grand_total": 1400,
    "status": "confirmed",
    "note": "Deliver quickly",
    "customer": {
      "id": 5,
      "name": "Customer Name",
      "phone": "01700000000"
    },
    "salesman": {
      "id": 1,
      "name": "Salesman Name"
    },
    "items": [
      {
        "id": 1,
        "product_id": 10,
        "product_name": "Product Name",
        "quantity": 2,
        "unit_price": 100,
        "line_total": 200,
        "product": {
          "id": 10,
          "sku": "SKU-001",
          "unit": {
            "id": 1,
            "name": "Piece",
            "short_name": "pc"
          }
        }
      }
    ]
  }
}
```

### Security Requirement
Backend must ensure a salesman cannot access another salesman’s order details.

---

## 7.11 Create Order
### Endpoint
`POST /api/orders`

### Request
```json
{
  "customer_id": 5,
  "order_date": "2026-04-08",
  "note": "Deliver quickly",
  "discount_type": "amount",
  "discount_value": 100,
  "items": [
    {
      "product_id": 10,
      "quantity": 2
    },
    {
      "product_id": 11,
      "quantity": 1
    }
  ]
}
```

### Validation
- `customer_id`: required
- `order_date`: required
- `note`: optional
- `discount_type`: optional, `amount` or `percentage`
- `discount_value`: optional numeric
- `items`: required array, minimum 1
- `items.*.product_id`: required, distinct
- `items.*.quantity`: required, greater than 0

### Important Backend Behavior
- server loads product selling prices
- server calculates `subtotal`
- server calculates `discount_amount`
- server calculates `grand_total`
- server checks stock inside transaction
- server deducts stock on success
- server creates stock movement rows

### Success Response
```json
{
  "message": "Order created successfully.",
  "data": {
    "id": 99,
    "order_no": "ORD-ABC12345",
    "order_date": "2026-04-08",
    "subtotal": 1500,
    "discount_type": "amount",
    "discount_value": 100,
    "discount_amount": 100,
    "grand_total": 1400,
    "status": "confirmed",
    "note": "Deliver quickly",
    "customer": {
      "id": 5,
      "name": "Customer Name",
      "phone": "01700000000"
    },
    "salesman": {
      "id": 1,
      "name": "Salesman Name"
    },
    "items": []
  }
}
```

### Mobile Payload Rule
The mobile app should not send authoritative values such as:
- `unit_price`
- `line_total`
- `subtotal`
- `discount_amount`
- `grand_total`

The backend must derive those values.

---

# 8. Error Handling Requirements

## 8.1 Validation Error Shape
Recommended backend error format for Flutter compatibility:
```json
{
  "message": "The given data was invalid.",
  "errors": {
    "items.0.quantity": ["Quantity exceeds available stock."]
  }
}
```

## 8.2 Errors the App Must Handle
- invalid login
- unauthorized token
- expired session
- forbidden/inactive user
- missing customer
- missing items
- duplicate product lines
- quantity exceeds stock
- invalid discount
- invalid product
- invalid customer
- network failure
- server error

## 8.3 UX Requirement
The app must show validation and business rule errors in a readable and user-friendly way.

---

# 9. Flutter Data Model Requirements

The mobile app should define models for:
- UserRole
- AuthUser
- LoginResponse
- ProductCategory
- ProductUnit
- Product
- CustomerCreatedBy
- Customer
- CartItem
- DiscountInput
- OrderItemRequest
- CreateOrderRequest
- OrderSalesman
- OrderCustomer
- OrderItemProductUnit
- OrderItemProduct
- OrderItem
- Order
- PaginatedResponse<T>

## 9.1 Model Notes
- pagination links may be null
- nested objects must be parsed safely
- numeric values should be parsed carefully
- optional fields should be nullable where necessary

---

# 10. UI Requirements

## 10.1 Screens
- Splash / Session Check
- Login Screen
- Home Screen
- Product List Screen
- Product Detail Screen (optional)
- Customer Search Screen
- Add Customer Screen
- Cart / Order Builder Screen
- Discount Input Dialog or Bottom Sheet
- Order Summary Screen
- Invoice / Order Success Screen
- Order History Screen
- Order Details Screen
- Profile Screen

## 10.2 UX Requirements
- order creation should require minimal taps
- stock must be visible while ordering
- subtotal and discount preview should update quickly
- loading states must be visible
- empty states must be clear
- validation errors must be understandable

---

# 11. Suggested Flutter Architecture

```text
lib/
 ┣ core/
 ┃ ┣ network/
 ┃ ┃ ┣ api_client.dart
 ┃ ┃ ┣ api_exception.dart
 ┃ ┃ ┗ api_endpoints.dart
 ┃ ┣ storage/
 ┃ ┃ ┣ token_storage.dart
 ┃ ┃ ┗ user_storage.dart
 ┃ ┣ constants/
 ┃ ┗ utils/
 ┣ features/
 ┃ ┣ auth/
 ┃ ┃ ┣ data/
 ┃ ┃ ┃ ┣ models/
 ┃ ┃ ┃ ┣ datasources/
 ┃ ┃ ┃ ┗ repositories/
 ┃ ┃ ┗ presentation/
 ┃ ┃   ┣ controllers/
 ┃ ┃   ┗ pages/
 ┃ ┣ products/
 ┃ ┣ customers/
 ┃ ┣ cart_orders/
 ┃ ┣ invoice/
 ┃ ┗ profile/
 ┣ shared/
 ┃ ┣ widgets/
 ┃ ┗ helpers/
 ┗ main.dart
```

---

# 12. Non-Functional Requirements

## 12.1 Performance
- product list should load efficiently
- product search should be responsive
- cart updates should feel instant
- order submission must show progress clearly

## 12.2 Reliability
- token should persist safely
- unauthorized responses should redirect properly
- app should handle network failures cleanly
- app should remain usable after recoverable API failures

## 12.3 Security
- token must be stored safely
- protected requests must include required auth header
- app must not trust local preview totals as final totals

## 12.4 Maintainability
- code should use feature-based organization
- repositories and models should be reusable
- API client should be centralized
- validation and error handling should be standardized

---

# 13. Step-by-Step Development Plan

## Phase 1: Foundation
- create Flutter project structure
- create API endpoints constants
- create reusable API client
- support `X-Authorization` header
- create token storage
- create user storage
- create splash/session logic

## Phase 2: Authentication
- create login request model
- create login response model
- create auth user and role models
- create auth repository
- create login state management
- build login screen
- build logout and profile load

## Phase 3: Products
- create product-related models
- create product repository
- create product list state management
- create product list UI
- add product search
- add product details if needed

## Phase 4: Customers
- create customer models
- create customer repository
- create customer search UI
- create add customer UI
- support customer selection

## Phase 5: Cart and Discount
- create cart item model
- create discount input model
- create cart controller/service
- add stock preview validation
- add discount calculator
- build cart and order summary UI

## Phase 6: Order Submission
- create order request models
- create order repository
- create order submit state management
- submit order to backend
- handle validation and stock errors

## Phase 7: Invoice and History
- create order response models
- build invoice / success screen
- create order history models
- create order history repository
- build order history UI
- build order details UI

## Phase 8: Profile and Cleanup
- create profile screen
- finalize logout flow
- improve loading and empty states
- improve validation message handling
- refactor reusable widgets

---

# 14. Codex Master Prompt

```text
I am building a Flutter mobile salesman app for an Inventory + Sales + Order Management System.

Backend is already built in Laravel.
The mobile app must follow the same business rules as the existing web salesman flow.
It is not a separate system. It is another client of the same backend.

Main business flow:
1. Salesman logs in.
2. App stores bearer token and user info.
3. Salesman loads products and sees current stock.
4. Salesman searches existing customers or creates a new customer.
5. Salesman adds products to cart and sets quantities.
6. App previews subtotal, discount amount, and grand total.
7. Salesman confirms order.
8. Backend re-validates stock, price, and discount rules.
9. Backend creates confirmed order, deducts stock, and returns order details.
10. Salesman can view own order history and open any order detail.

Business rules:
- only authenticated users can access protected APIs
- customer is required before order submit
- at least one order item is required
- each order line must use a different product
- quantity must be greater than 0
- quantity must not exceed available stock
- stock shown in app is preview only, backend validates again
- discount types: amount and percentage
- amount discount cannot exceed subtotal
- percentage discount must be between 0 and 100
- grand total cannot be negative
- mobile must not send authoritative subtotal, discount_amount, or grand_total
- backend is final source of truth for totals

API note:
- current production uses X-Authorization: Bearer <token> for protected requests because the normal Authorization header is being stripped before Laravel receives it

Tech requirements:
- Flutter app only
- feature-based structure
- reusable API client
- token storage
- repository layer
- state management
- production-friendly code
- build step by step

Start with Phase 1 only:
- project structure
- API endpoints constants
- API client
- token storage
- splash/session flow
Explain each generated file clearly.
```

---

# 15. Codex Step-by-Step Prompts

## Prompt 1: Project Structure
```text
Create a clean Flutter project structure for a mobile salesman app that follows an existing Laravel backend business.
Use feature-based folders for:
- auth
- products
- customers
- cart_orders
- invoice
- profile
Also add core folders for:
- network
- storage
- constants
- utils
Explain the folder structure clearly.
```

## Prompt 2: API Endpoints
```text
Create a Flutter file for API endpoint constants for a Laravel backend.
Include:
- login
- logout
- me
- products
- product details
- customers
- customer details
- orders
- order details
Keep the file reusable and clean.
```

## Prompt 3: API Client
```text
Create a reusable Flutter API client for a Laravel backend.
Requirements:
- base URL support
- GET and POST methods
- common JSON headers
- support X-Authorization header for protected requests
- clean exception handling
- suitable for protected APIs
Explain each file clearly.
```

## Prompt 4: Token and User Storage
```text
Create Flutter storage services for:
- saving access token
- reading access token
- clearing access token
- saving basic logged-in user info
- clearing saved user info
Use a clean abstraction that is production-friendly.
```

## Prompt 5: Splash / Session Check
```text
Create a Flutter splash or session check flow.
If token exists, go to a home screen placeholder.
If token does not exist, go to login screen.
Keep the implementation simple and clean.
```

## Prompt 6: Login Models
```text
Create Flutter models for login request, login response, user role, and authenticated user.
The backend is Laravel and returns bearer token plus nested user role information.
Add fromJson and toJson methods where appropriate.
```

## Prompt 7: Auth Repository
```text
Create a Flutter auth repository using the reusable API client.
Support:
- login
- logout
- get current profile
Use token-based authentication and clean model parsing.
```

## Prompt 8: Login State Management
```text
Create Flutter state management for the login flow.
Handle:
- loading
- success
- error
- token save
- user save
Keep it clean and production-friendly.
```

## Prompt 9: Login UI
```text
Build a Flutter login screen for the salesman app.
Requirements:
- login field that can accept email or phone
- password field
- login button
- loading indicator
- error message handling
On success, navigate to home screen placeholder.
```

## Prompt 10: Product Models
```text
Create Flutter models for product list and product details.
Support fields such as:
- id
- name
- sku
- selling_price
- current_stock
- minimum_stock_alert
- status
- category
- unit
Parse nested category and unit safely.
```

## Prompt 11: Product Repository
```text
Create Flutter repository and data source for products.
Support:
- paginated product list
- search by q
- fetch product details
Use X-Authorization bearer token authentication.
```

## Prompt 12: Product List State and UI
```text
Create Flutter state management and UI for product list.
Requirements:
- load paginated list
- search products
- show name, SKU, stock, selling price, unit
- show loading and error states
- keep UI simple for salesman use
```

## Prompt 13: Customer Models
```text
Create Flutter models for customer list, customer details, and created_by user summary.
Support fields:
- id
- name
- phone
- address
- area
- created_by
```

## Prompt 14: Customer Repository
```text
Create Flutter repository and data source for customers.
Support:
- search by q
- search by phone
- fetch customer details
- create customer
Use X-Authorization bearer token authentication.
```

## Prompt 15: Customer Search and Add UI
```text
Build Flutter customer search and add-customer flow.
Requirements:
- search existing customer by name or phone
- show list results
- allow new customer creation
- validate name, phone, and address
- return selected customer into order flow
```

## Prompt 16: Cart Models
```text
Create Flutter models for CartItem, DiscountInput, OrderItemRequest, and CreateOrderRequest.
The mobile app should send minimal authoritative order payload to backend.
Do not include subtotal, discount_amount, or grand_total in CreateOrderRequest unless the backend specifically requires them.
```

## Prompt 17: Cart Controller
```text
Create Flutter cart controller or service.
Support:
- add product to cart
- prevent duplicate item issues
- update quantity
- remove item
- clear cart
- calculate line totals and subtotal for preview
- validate quantity against available stock
```

## Prompt 18: Discount Calculator
```text
Create reusable Flutter discount calculation logic.
Support:
- amount discount
- percentage discount
Return preview values for:
- subtotal
- discount amount
- grand total
Ensure grand total never becomes negative.
```

## Prompt 19: Order Builder and Summary UI
```text
Build Flutter order builder and order summary screens.
Requirements:
- selected customer display
- cart items list
- quantity update
- stock visibility
- discount type and value input
- subtotal preview
- discount preview
- grand total preview
- note input
- confirm order button
```

## Prompt 20: Order Repository
```text
Create Flutter repository and data source for order APIs.
Support:
- create order
- get order list
- get order details
Use X-Authorization bearer token authentication and parse nested order models carefully.
```

## Prompt 21: Order Submit State Handling
```text
Create Flutter state management for order submission.
Handle:
- loading
- success
- validation errors from backend
- stock-related failure messages
- general failure messages
- clear cart after success
```

## Prompt 22: Invoice / Order Success UI
```text
Build Flutter invoice or order success screen.
Show:
- order number
- customer information
- item list
- subtotal
- discount type and value
- discount amount
- grand total
- order date
Keep the screen readable and business-friendly.
```

## Prompt 23: Order History Models
```text
Create Flutter models for order history list and order details.
Support nested customer, salesman, item, product, and unit objects.
Also support paginated list responses.
```

## Prompt 24: Order History UI
```text
Build Flutter order history and order details screens.
Requirements:
- list own orders
- support date/status filters if convenient
- show loading, error, and empty states
- open full order details on tap
```

## Prompt 25: Profile and Logout UI
```text
Build Flutter profile screen and logout flow.
Requirements:
- show logged-in user info
- logout button
- call logout API if available
- clear token and saved user data
- navigate back to login screen
```

## Prompt 26: Error Handling and Cleanup
```text
Review the Flutter salesman app and improve:
- API error parsing
- unauthorized handling
- validation messages
- loading states
- empty states
- reusable widgets
Do not change business logic.
```

---

# 16. Recommended Build Order

1. project structure
2. API endpoints
3. API client
4. token storage
5. splash/session flow
6. login models
7. auth repository
8. login state management
9. login UI
10. product models
11. product repository
12. product UI
13. customer models
14. customer repository
15. customer UI
16. cart models
17. cart controller
18. discount calculator
19. order builder UI
20. order repository
21. order submit handling
22. invoice screen
23. order history models
24. order history UI
25. profile and logout
26. cleanup

---

# 17. Final Summary

This mobile salesman app is a Flutter client for the same Laravel backend business used by the existing web salesman system.

Its main responsibilities are:
- secure login
- product and stock visibility
- customer search and creation
- fast order taking
- preview discount and totals
- backend-confirmed order submission
- order history access
- safe logout

The most important implementation rule is:
**mobile previews, backend decides.**

