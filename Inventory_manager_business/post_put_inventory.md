# Inventory Manager Write API Docs

This document covers the changed write APIs for the inventory manager mobile app.

It focuses on:

- `POST`
- `PUT`
- `DELETE`

It is based on the current live backend contract in this project.

## Authentication

Send these headers on protected requests:

```http
Accept: application/json
Content-Type: application/json
X-Authorization: Bearer <token>
```

If your environment supports the standard header, this also works:

```http
Authorization: Bearer <token>
```

## Role Access Summary

### Inventory manager can use

- `POST /api/products`
- `PUT /api/products/{id}`
- `POST /api/purchases`
- `PUT /api/purchases/{id}`
- `POST /api/inventory-manager/barcode/products`
- `PUT /api/inventory-manager/barcode/products/{barcode}`

### Inventory manager cannot use

- `DELETE /api/products/{id}`
- `DELETE /api/purchases/{id}`

Those delete routes are admin-only.

## 1. POST `/api/products`

Create a product from the main product API.

### Allowed roles

- `admin`
- `inventory_manager`

### Simple product request

```json
{
"name": "Mobile Simple Product",
"sku": "MOBILE-SIMPLE-001",
"barcode": "1234567890123",
"category_id": 1,
"subcategory_id": 1,
"unit_id": 1,
"purchase_price": 120.00,
"selling_price": 150.00,
"minimum_stock_alert": 10,
"status": "active"
}
```

### Variant product request

```json
{
"name": "Mobile Variant Product",
"sku": "MOBILE-VARIANT-001",
"barcode": "1234567890999",
"category_id": 1,
"subcategory_id": 1,
"unit_id": 1,
"purchase_price": 220.00,
"selling_price": 350.00,
"minimum_stock_alert": 5,
"status": "active",
"has_variants": true,
"variant_attributes": [
{
"name": "Color",
"values": ["Red", "Blue"]
},
{
"name": "Size",
"values": ["M", "L"]
}
],
"variant_quantities": {
"color-red__size-m": 5,
"color-red__size-l": 2,
"color-blue__size-m": 1,
"color-blue__size-l": 0
}
}
```

### Important rules

- `name` is required
- `category_id` is required
- `unit_id` is required
- `minimum_stock_alert` is required
- `status` is required
- simple products require `purchase_price`
- simple products require `selling_price`
- `subcategory_id` is optional
- `sku` must be unique if provided
- `barcode` must be unique if provided
- if `has_variants = true`, variant configuration must be valid

### Success response

Status: `201 Created`

```json
{
"message": "Product created successfully.",
"data": {
"id": 1,
"name": "Mobile Simple Product"
}
}
```

## 2. PUT `/api/products/{id}`

Update a product from the main product API.

### Allowed roles

- `admin`
- `inventory_manager`

### Request

```json
{
"name": "Mobile Updated Product",
"sku": "MOBILE-UPDATED-001",
"barcode": "1234567890123",
"category_id": 1,
"subcategory_id": 1,
"unit_id": 1,
"purchase_price": 130.00,
"selling_price": 165.00,
"minimum_stock_alert": 8,
"status": "active"
}
```

### Important rules

- same rules as product create
- `sku` must stay unique except for the current product
- `barcode` must stay unique except for the current product
- if product has variants, send valid variant fields

### Success response

Status: `200 OK`

```json
{
"message": "Product updated successfully.",
"data": {
"id": 1,
"name": "Mobile Updated Product"
}
}
```

## 3. POST `/api/inventory-manager/barcode/products`

Create a product from the inventory manager barcode flow.

### Allowed roles

- `inventory_manager`

### Request

```json
{
"name": "Barcode Created Product",
"sku": "BARCODE-PRODUCT-001",
"barcode": "1234567890123",
"category_id": 1,
"subcategory_id": 1,
"unit_id": 1,
"purchase_price": 110.00,
"selling_price": 145.00,
"minimum_stock_alert": 6,
"status": "active"
}
```

### Business use

Use this when the inventory manager scans a barcode and the product does not already exist, then creates the product from the scan flow.

### Success response

Status: `201 Created`

```json
{
"message": "Product created successfully.",
"data": {
"id": 1,
"barcode": "1234567890123"
}
}
```

## 4. PUT `/api/inventory-manager/barcode/products/{barcode}`

Update a product using barcode as the route key.

### Allowed roles

- `inventory_manager`

### Path param

- `{barcode}` = existing product barcode

### Request

```json
{
"name": "Barcode Updated Product",
"sku": "BARCODE-PRODUCT-001",
"barcode": "1234567890123",
"category_id": 1,
"subcategory_id": 1,
"unit_id": 1,
"purchase_price": 115.00,
"selling_price": 150.00,
"minimum_stock_alert": 7,
"status": "active"
}
```

### Business use

Use this when the inventory manager opens a product from barcode flow and edits it directly without first resolving numeric product id.

### Success response

Status: `200 OK`

```json
{
"message": "Product updated successfully.",
"data": {
"id": 1,
"barcode": "1234567890123"
}
}
```

## 5. POST `/api/purchases`

Create a purchase.

### Allowed roles

- `admin`
- `inventory_manager`

### Simple purchase request

```json
{
"purchase_date": "2026-04-14",
"note": "Simple purchase from mobile",
"items": [
{
"product_id": 1,
"quantity": 10,
"unit_cost": 90.00
}
]
}
```

### Variant purchase request

```json
{
"purchase_date": "2026-04-14",
"note": "Variant purchase from mobile",
"items": [
{
"product_id": 1,
"product_variant_id": 1,
"quantity": 5,
"unit_cost": 220.00
}
]
}
```

### Important rules

- `purchase_date` is required
- `items` is required
- at least one item is required
- `items.*.product_id` is required
- `items.*.product_variant_id` is required only for variant products
- `items.*.quantity` must be greater than `0`
- `items.*.unit_cost` can be `null` or `>= 0`
- duplicate purchase lines for the same product and variant combination are not allowed

### Success response

Status: `201 Created`

```json
{
"message": "Purchase created successfully.",
"data": {
"id": 1,
"purchase_no": "PUR-000001",
"purchase_date": "2026-04-14",
"total_amount": 900.0
}
}
```

## 6. PUT `/api/purchases/{id}`

Update an existing purchase.

### Allowed roles

- `admin`
- `inventory_manager`

### Request

```json
{
"purchase_date": "2026-04-15",
"note": "Updated purchase from mobile",
"items": [
{
"product_id": 1,
"quantity": 12,
"unit_cost": 95.00
}
]
}
```

### Variant update request

```json
{
"purchase_date": "2026-04-15",
"note": "Updated variant purchase from mobile",
"items": [
{
"product_id": 1,
"product_variant_id": 1,
"quantity": 8,
"unit_cost": 225.00
}
]
}
```

### Business rule

Purchase update is stock-safe.
Backend reverses the old purchase effect and then applies the new purchase effect.
Mobile only sends the final corrected purchase payload.

### Success response

Status: `200 OK`

```json
{
"message": "Purchase updated successfully.",
"data": {
"id": 1,
"purchase_date": "2026-04-15",
"total_amount": 1140.0
}
}
```

## 7. DELETE `/api/products/{id}`

### Role access

- `admin` only

### Inventory manager access

- not allowed

If inventory manager calls this endpoint, backend should reject the request with `403 Forbidden`.

## 8. DELETE `/api/purchases/{id}`

### Role access

- `admin` only

### Inventory manager access

- not allowed

If inventory manager calls this endpoint, backend should reject the request with `403 Forbidden`.

## 9. Validation Error Response

When request data is invalid, backend returns:

Status: `422 Unprocessable Entity`

Example:

```json
{
"message": "The given data was invalid.",
"errors": {
"purchase_date": [
"The purchase date field is required."
],
"items.0.quantity": [
"The quantity field must be greater than 0."
]
}
}
```

## 10. Unauthorized Error Response

### Missing or invalid token

Status: `401 Unauthorized`

```json
{
"message": "Unauthenticated."
}
```

### Wrong role

Status: `403 Forbidden`

```json
{
"message": "This action is unauthorized."
}
```

## 11. Final Mobile Rules

- inventory manager can create and update products
- inventory manager can create and update purchases
- inventory manager can create and update products from barcode flow
- inventory manager cannot delete products
- inventory manager cannot delete purchases
- send `product_variant_id` only for variant purchase lines
- do not calculate stock in mobile
- trust backend totals and validation
