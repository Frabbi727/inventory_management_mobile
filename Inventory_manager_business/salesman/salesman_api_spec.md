# Salesman Mobile App API Specification (Detailed)

This document provides a detailed specification of the API endpoints, requests, and responses for the Salesman Mobile App. Use this as a guide for building data models and API clients in the mobile application.

---

## 1. Authentication

### 1.1. Login

- **Endpoint:** `POST /api/login`
- **Description:** Authenticates a user and returns an access token.

- **Request Body (application/json):**
  ```json
  {
    "email": "salesman@example.com",
    "password": "password"
  }
  ```

- **Success Response (200 OK):**
  ```json
  {
    "token": "1|aBcDeFgHiJkLmNoPqRsTuVwXyZ",
    "user": {
      "id": 10,
      "name": "John Doe",
      "email": "salesman@example.com",
      "roles": [
        "salesman"
      ]
    }
  }
  ```

- **Error Response (422 Unprocessable Entity):**
  ```json
  {
    "message": "The given data was invalid.",
    "errors": {
      "email": [
        "The email field is required."
      ]
    }
  }
  ```

### 1.2. Logout

- **Endpoint:** `POST /api/logout`
- **Description:** Invalidates the current access token.
- **Headers:** `Authorization: Bearer <token>`
- **Success Response (200 OK):**
  ```json
  {
    "message": "Logged out successfully"
  }
  ```

---

## 2. Profile

### 2.1. Get User Profile

- **Endpoint:** `GET /api/me`
- **Description:** Retrieves the authenticated user's profile.
- **Headers:** `Authorization: Bearer <token>`
- **Success Response (200 OK):**
  ```json
  {
    "id": 10,
    "name": "John Doe",
    "email": "salesman@example.com",
    "roles": [
      "salesman"
    ]
  }
  ```

---

## 3. Products

### 3.1. Get Product List

- **Endpoint:** `GET /api/products`
- **Description:** Retrieves a paginated list of products. Supports search.
- **Headers:** `Authorization: Bearer <token>`
- **Query Parameters:**
  - `search` (string, optional): Filter by name or SKU.
  - `page` (integer, optional): Page number for pagination.
- **Success Response (200 OK):**
  ```json
  {
    "data": [
      {
        "id": 1,
        "name": "Product A",
        "sku": "PA-001",
        "selling_price": 150.00,
        "current_stock": 50
      },
      {
        "id": 2,
        "name": "Product B",
        "sku": "PB-002",
        "selling_price": 250.50,
        "current_stock": 30
      }
    ],
    "meta": {
      "current_page": 1,
      "last_page": 5,
      "per_page": 15,
      "total": 75
    }
  }
  ```

---

## 4. Customers

### 4.1. Search Customers

- **Endpoint:** `GET /api/customers`
- **Description:** Searches for customers by name or phone.
- **Headers:** `Authorization: Bearer <token>`
- **Query Parameters:**
  - `search` (string, optional): Search term.
- **Success Response (200 OK):**
  ```json
  {
    "data": [
      {
        "id": 101,
        "name": "Customer Shop",
        "phone": "1234567890",
        "address": "123 Main St",
        "area": "Downtown"
      }
    ],
    "meta": {
      "total": 1
    }
  }
  ```

### 4.2. Create Customer

- **Endpoint:** `POST /api/customers`
- **Description:** Creates a new customer.
- **Headers:** `Authorization: Bearer <token>`
- **Request Body (application/json):**
  ```json
  {
    "name": "New General Store",
    "phone": "0987654321",
    "address": "456 Side St",
    "area": "Uptown"
  }
  ```
- **Success Response (201 Created):**
  ```json
  {
    "id": 102,
    "name": "New General Store",
    "phone": "0987654321",
    "address": "456 Side St",
    "area": "Uptown"
  }
  ```

---

## 5. Orders

### 5.1. Create Order

- **Endpoint:** `POST /api/orders`
- **Description:** Submits a new order.
- **Headers:** `Authorization: Bearer <token>`
- **Request Body (application/json):**
  ```json
  {
    "customer_id": 101,
    "items": [
      {
        "product_id": 1,
        "quantity": 5,
        "unit_price": 150.00
      },
      {
        "product_id": 2,
        "quantity": 2,
        "unit_price": 250.50
      }
    ],
    "discount_type": "percentage",
    "discount_value": 10,
    "note": "Deliver by 5 PM."
  }
  ```
- **Success Response (201 Created):**
  ```json
  {
    "id": 201,
    "order_no": "ORD-2024-00201",
    "customer_name": "Customer Shop",
    "subtotal": 1251.00,
    "discount_type": "percentage",
    "discount_value": 10,
    "discount_amount": 125.10,
    "grand_total": 1125.90,
    "status": "pending",
    "note": "Deliver by 5 PM.",
    "items": [
      {
        "product_name": "Product A",
        "unit_price": 150.00,
        "quantity": 5,
        "line_total": 750.00
      },
      {
        "product_name": "Product B",
        "unit_price": 250.50,
        "quantity": 2,
        "line_total": 501.00
      }
    ]
  }
  ```
- **Error Response (422 Unprocessable Entity):**
  ```json
  {
    "message": "The given data was invalid.",
    "errors": {
      "items.0.quantity": [
        "The quantity for Product A exceeds available stock."
      ]
    }
  }
  ```

---

## 6. Order History

### 6.1. Get Order History

- **Endpoint:** `GET /api/orders`
- **Description:** Retrieves the salesman's paginated order history.
- **Headers:** `Authorization: Bearer <token>`
- **Success Response (200 OK):**
  ```json
  {
    "data": [
      {
        "id": 201,
        "order_no": "ORD-2024-00201",
        "customer_name": "Customer Shop",
        "grand_total": 1125.90,
        "status": "pending",
        "created_at": "2024-07-30T10:00:00.000000Z"
      }
    ],
    "meta": {
      "current_page": 1,
      "last_page": 3,
      "total": 45
    }
  }
  ```

### 6.2. Get Order Details

- **Endpoint:** `GET /api/orders/{id}`
- **Description:** Retrieves full details for a specific order.
- **Headers:** `Authorization: Bearer <token>`
- **Success Response (200 OK):**
  ```json
  {
    "id": 201,
    "order_no": "ORD-2024-00201",
    "customer_name": "Customer Shop",
    "customer_phone": "1234567890",
    "customer_address": "123 Main St",
    "subtotal": 1251.00,
    "discount_type": "percentage",
    "discount_value": 10,
    "discount_amount": 125.10,
    "grand_total": 1125.90,
    "status": "pending",
    "note": "Deliver by 5 PM.",
    "created_at": "2024-07-30T10:00:00.000000Z",
    "items": [
      {
        "product_name": "Product A",
        "unit_price": 150.00,
        "quantity": 5,
        "line_total": 750.00
      },
      {
        "product_name": "Product B",
        "unit_price": 250.50,
        "quantity": 2,
        "line_total": 501.00
      }
    ]
  }
  ```
