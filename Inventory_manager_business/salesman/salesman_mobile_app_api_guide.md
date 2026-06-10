# Salesman Mobile App - API Integration Guide

## 1. Overview
This document provides a complete guide for integrating the Flutter Salesman App with the Laravel backend API. It details the business logic, API endpoints, request/response formats, and error handling.

**Base URL:** `https://your-domain.com/api`  
**Authentication:** All protected endpoints require a `Bearer` token in the `Authorization` header.

---

## 2. Business Flow: Salesman Order Taking

1.  **Login:** Salesman authenticates to start their session.
2.  **View Products:** Salesman views the product catalog with real-time stock.
3.  **Select Customer:** Salesman searches for an existing customer or creates a new one.
4.  **Build Cart:** Salesman adds products to a local cart, respecting stock limits.
5.  **Apply Discount:** Salesman applies a discount (fixed amount or percentage).
6.  **Submit Order:** Salesman confirms the order, which is sent to the backend.
7.  **View History:** Salesman can review their past orders.

---

## 3. API Endpoints

### Module: Authentication

#### 3.1. Login
- **Purpose:** Authenticate a salesman and retrieve an API token.
- **Endpoint:** `POST /login`
- **Request Body:**
  ```json
  {
    "email": "salesman@example.com",
    "password": "password"
  }
  ```
- **Success Response (200 OK):**
  ```json
  {
    "token": "YOUR_AUTH_TOKEN",
    "user": {
      "id": 1,
      "name": "Salesman Name",
      "email": "salesman@example.com",
      "roles": ["salesman"]
    }
  }
  ```
- **Error Response (401 Unauthorized):**
  ```json
  { "message": "Unauthorized" }
  ```

#### 3.2. Logout
- **Purpose:** Invalidate the user's token and end the session.
- **Endpoint:** `POST /logout`
- **Headers:** `Authorization: Bearer <token>`
- **Success Response (200 OK):**
  ```json
  { "message": "Logged out successfully" }
  ```

---

### Module: Profile

#### 3.3. Get Logged-in User
- **Purpose:** Fetch the profile of the currently authenticated user.
- **Endpoint:** `GET /me`
- **Headers:** `Authorization: Bearer <token>`
- **Success Response (200 OK):**
  ```json
  {
    "id": 1,
    "name": "Salesman Name",
    "email": "salesman@example.com",
    "roles": ["salesman"]
  }
  ```

---

### Module: Products

#### 3.4. Get Product List
- **Purpose:** Fetch the list of available products with stock levels.
- **Endpoint:** `GET /products`
- **Headers:** `Authorization: Bearer <token>`
- **Query Parameters:**
  - `search` (string, optional): Filter products by name or SKU.
  - `page` (int, optional): For pagination.
- **Success Response (200 OK):**
  ```json
  {
    "data": [
      {
        "id": 101,
        "name": "Product A",
        "sku": "PA-001",
        "selling_price": 150.00,
        "current_stock": 50
      }
    ],
    "meta": { "total": 1, "current_page": 1, "last_page": 1 }
  }
  ```

---

### Module: Customers

#### 3.5. Search/List Customers
- **Purpose:** Find an existing customer by name or phone number.
- **Endpoint:** `GET /customers`
- **Headers:** `Authorization: Bearer <token>`
- **Query Parameters:**
  - `search` (string, optional): Search term for name or phone.
- **Success Response (200 OK):**
  ```json
  {
    "data": [
      {
        "id": 201,
        "name": "Customer Shop",
        "phone": "1234567890",
        "address": "123 Main St"
      }
    ],
    "meta": { ... }
  }
  ```

#### 3.6. Create Customer
- **Purpose:** Add a new customer to the system.
- **Endpoint:** `POST /customers`
- **Headers:** `Authorization: Bearer <token>`
- **Request Body:**
  ```json
  {
    "name": "New Retail Store",
    "phone": "0987654321",
    "address": "456 Market Ave"
  }
  ```
- **Success Response (201 Created):**
  ```json
  {
    "id": 202,
    "name": "New Retail Store",
    "phone": "0987654321",
    "address": "456 Market Ave"
  }
  ```
- **Error Response (422 Unprocessable Entity):**
  ```json
  {
    "message": "The given data was invalid.",
    "errors": { "phone": ["The phone has already been taken."] }
  }
  ```

---

### Module: Orders

#### 3.7. Create Order
- **Purpose:** Submit a new sales order.
- **Endpoint:** `POST /orders`
- **Headers:** `Authorization: Bearer <token>`
- **Request Body:**
  ```json
  {
    "customer_id": 201,
    "items": [
      { "product_id": 101, "quantity": 10, "unit_price": 150.00 }
    ],
    "discount_type": "percentage",
    "discount_value": 5,
    "note": "Urgent delivery requested."
  }
  ```
- **Success Response (201 Created):**
  ```json
  {
    "id": 301,
    "order_no": "ORD-2024-001",
    "grand_total": 1425.00,
    "status": "pending",
    "items": [ ... ],
    ...
  }
  ```
- **Error Response (422 Unprocessable Entity):**
  ```json
  {
    "message": "The given data was invalid.",
    "errors": { "items.0.quantity": ["The quantity for Product A exceeds available stock."] }
  }
  ```

#### 3.8. Get Order History
- **Purpose:** Fetch a list of orders placed by the salesman.
- **Endpoint:** `GET /orders`
- **Headers:** `Authorization: Bearer <token>`
- **Success Response (200 OK):**
  ```json
  {
    "data": [
      {
        "id": 301,
        "order_no": "ORD-2024-001",
        "customer_name": "Customer Shop",
        "grand_total": 1425.00,
        "status": "confirmed",
        "created_at": "2024-01-01T12:00:00Z"
      }
    ],
    "meta": { ... }
  }
  ```

#### 3.9. Get Order Details
- **Purpose:** Fetch the full details of a single order.
- **Endpoint:** `GET /orders/{id}`
- **Headers:** `Authorization: Bearer <token>`
- **Success Response (200 OK):**
  ```json
  {
    "id": 301,
    "order_no": "ORD-2024-001",
    "customer_name": "Customer Shop",
    "grand_total": 1425.00,
    "status": "confirmed",
    "items": [
      {
        "product_name": "Product A",
        "quantity": 10,
        "unit_price": 150.00,
        "line_total": 1500.00
      }
    ],
    ...
  }
  ```
