# Mobile Inventory Manager Barcode + Product API

## Overview

This document describes the mobile-facing business for the `inventory_manager` role.
It combines:

- manual product CRUD support
- barcode scanner product flow
- purchase receiving lookup by barcode
- inventory-friendly product lookup
- master data APIs required by mobile product forms

The mobile app should treat barcode flow as a fast entry layer on top of the normal product business.
Barcode does not replace product CRUD or purchase logic.

## Authentication

- Base URL: `https://ordermanage.b2bhaat.com`
- API prefix: `/api`
- Protected endpoints require:
    - Sanctum bearer token
    - active user account
- Scanner endpoints are restricted to `inventory_manager`

Standard headers:

```http
Accept: application/json
Authorization: Bearer {token}
```

Use `multipart/form-data` when uploading photos.

## Main Mobile Business

The inventory manager mobile app can be built around these feature groups:

- Product
- Purchase
- Inventory
- Barcode scanner

This is enough for a first mobile version because:

- Product manages product master data
- Barcode makes product identification and entry fast
- Purchase handles stock receiving
- Inventory uses the existing stock and stock-movement business

## Master Data APIs

Load these before opening manual or barcode-driven product create/edit forms.

### Categories

```http
GET /api/categories
```

Response:

```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "name": "Beverages"
    }
  ]
}
```

### Units

```http
GET /api/units
```

Allowed roles:

- `admin`
- `manager`
- `salesman`
- `inventory_manager`

Business rules:

- active units only
- sorted by `name`
- used for product create/edit selectors

Response:

```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "name": "Kilogram",
      "short_name": "kg",
      "status": "active"
    },
    {
      "id": 2,
      "name": "Piece",
      "short_name": "pc",
      "status": "active"
    }
  ]
}
```

## Product Business

Product create and edit forms depend on:

- `category_id` from `/api/categories`
- `unit_id` from `/api/units`

### Manual Product CRUD Support

The normal product business remains the source of truth.
Barcode flow should reuse the same product form fields:

- `name`
- `sku`
- `barcode`
- `category_id`
- `unit_id`
- `purchase_price`
- `selling_price`
- `minimum_stock_alert`
- `status`
- optional `photos[]`

### Barcode Resolve Flow

Start every scan with:

```http
GET /api/inventory-manager/barcode/products/{barcode}/resolve
```

If product exists:

- `exists = true`
- `action = view_or_update`
- full product payload in `data`

If product does not exist:

- `exists = false`
- `action = create`
- scanned barcode returned
- `data = null`

### Create Product From Barcode Flow

```http
POST /api/inventory-manager/barcode/products
```

Use when:

- scanner returned `exists = false`

Supports:

- normal product fields
- optional `photos[]`

### Update Product By Barcode

```http
PUT /api/inventory-manager/barcode/products/{barcode}
```

Use when:

- scanner returned `exists = true`
- inventory manager wants to edit product after scan

Supports:

- normal product fields
- optional `photos[]`

### Get Exact Product By Barcode

```http
GET /api/inventory-manager/barcode/products/{barcode}
```

Use when:

- app already knows barcode exists
- app needs full product details again

## Product Photo Business

Photos are part of both manual and barcode product flows.

### During create

Supported through:

```http
POST /api/inventory-manager/barcode/products
```

### During update

Supported through:

```http
PUT /api/inventory-manager/barcode/products/{barcode}
```

### After product already exists

Use the existing photo endpoints:

```http
POST /api/products/{product}/photos
PATCH /api/products/{product}/photos/{photo}
PUT /api/products/{product}/photos/{photo}
DELETE /api/products/{product}/photos/{photo}
PATCH /api/products/{product}/photos/reorder
```

## Purchase Business

Purchase remains a `product_id`-based business.
Barcode helps resolve the product before adding the line item.

### Barcode Purchase Lookup

```http
GET /api/inventory-manager/barcode/purchase-products/{barcode}
```

Use when:

- scanning item during receiving
- preparing purchase line items

### Purchase Save Contract

Purchase save should still submit:

- `purchase_date`
- `note`
- `items[]`
- `items.*.product_id`
- `items.*.quantity`
- `items.*.unit_cost`

Barcode is not the saved purchase line key.
The saved purchase line key remains `product_id`.

## Inventory Business

Inventory is driven by the existing stock and stock movement logic.

Barcode helps mobile inventory by:

- identifying product instantly
- showing current stock
- preparing receiving
- avoiding fuzzy product search

The scanner product payload already includes:

- `current_stock`
- `minimum_stock_alert`
- `status`

## Recommended Mobile Workflow

### Workflow 1: Preload master data

Before opening product create/edit:

1. `GET /api/categories`
2. `GET /api/units`

### Workflow 2: Scan first

1. scan barcode
2. call `GET /api/inventory-manager/barcode/products/{barcode}/resolve`
3. if missing:
    - open create form
    - prefill barcode
    - use categories and units for selectors
4. if found:
    - open detail/edit screen
    - use categories and units for editable selectors

### Workflow 3: Purchase receiving

1. scan barcode
2. call `GET /api/inventory-manager/barcode/purchase-products/{barcode}`
3. use returned `data.id` as `product_id`
4. enter quantity and unit cost
5. submit purchase using the normal purchase contract

## Mobile Purchase API Design

Current purchase business is `product_id`-based.
Barcode is only a fast product lookup layer for mobile receiving flows.

That means:

- purchase items are saved with `product_id`
- barcode is only used to resolve the product faster
- stock is updated by purchase create/update business
- barcode itself does not directly update stock

### Purchase Business Rules

Purchase create and update should keep the existing business behavior.

Purchase request payloads should use:

- `purchase_date`
- `note`
- `items[]`
- `items.*.product_id`
- `items.*.quantity`
- `items.*.unit_cost`

Each item represents a stock-in line for a real product row.

### Recommended Mobile Purchase Endpoints

The mobile app should expose purchase write APIs that reuse the current backend purchase services.

#### Purchase list

```http
GET /api/inventory-manager/purchases
```

Use when:

- showing purchase history on mobile
- browsing recent receiving entries
- opening a purchase to review or edit

Suggested query parameters:

- `page`
- `per_page`
- `search`
- `date_from`
- `date_to`

Suggested response:

```json
{
  "success": true,
  "data": [
    {
      "id": 101,
      "purchase_date": "2026-04-10",
      "note": "Warehouse stock receive",
      "total_amount": 110,
      "items_count": 2,
      "created_at": "2026-04-10T09:30:00Z"
    }
  ],
  "meta": {
    "current_page": 1,
    "last_page": 1,
    "per_page": 15,
    "total": 1
  }
}
```

#### Purchase details

```http
GET /api/inventory-manager/purchases/{purchase}
```

Use when:

- opening purchase details
- prefilling purchase edit screen

Suggested response:

```json
{
  "success": true,
  "data": {
    "id": 101,
    "purchase_date": "2026-04-10",
    "note": "Warehouse stock receive",
    "total_amount": 110,
    "items": [
      {
        "id": 1,
        "product_id": 12,
        "quantity": 5,
        "unit_cost": 10,
        "line_total": 50,
        "product": {
          "id": 12,
          "name": "Soft Drink 250ml",
          "sku": "SD-250",
          "barcode": "1234567890123",
          "current_stock": 40,
          "category": {
            "id": 1,
            "name": "Beverages"
          },
          "unit": {
            "id": 2,
            "name": "Piece",
            "short_name": "pc"
          }
        }
      }
    ]
  }
}
```

#### Purchase create

```http
POST /api/inventory-manager/purchases
```

Use when:

- saving a new purchase from mobile
- completing barcode-assisted receiving

Request:

```json
{
  "purchase_date": "2026-04-10",
  "note": "Warehouse stock receive",
  "items": [
    {
      "product_id": 12,
      "quantity": 5,
      "unit_cost": 10
    },
    {
      "product_id": 15,
      "quantity": 3,
      "unit_cost": 20
    }
  ]
}
```

Business behavior:

1. find each product by `product_id`
2. create purchase item rows
3. find or create stock row for each product
4. add purchased quantity to stock
5. create `stock_movements` rows with purchase type
6. calculate and save purchase total amount

Suggested success response:

```json
{
  "success": true,
  "message": "Purchase created successfully.",
  "data": {
    "id": 101,
    "purchase_date": "2026-04-10",
    "note": "Warehouse stock receive",
    "total_amount": 110
  }
}
```

#### Purchase update

```http
PUT /api/inventory-manager/purchases/{purchase}
```

Use when:

- editing an existing purchase from mobile
- correcting quantity or unit cost after receiving

Request:

```json
{
  "purchase_date": "2026-04-10",
  "note": "Updated warehouse stock receive",
  "items": [
    {
      "product_id": 12,
      "quantity": 4,
      "unit_cost": 10
    },
    {
      "product_id": 15,
      "quantity": 6,
      "unit_cost": 20
    }
  ]
}
```

Business behavior:

1. load old purchase items
2. load new request items
3. collect all affected product IDs
4. lock related stock rows
5. reverse old purchase effect from stock
6. validate that reversal does not make stock negative
7. block update if stock integrity would break
8. apply new purchase quantities
9. create audit trail in `stock_movements`
10. replace stored purchase items
11. recalculate and save total amount

Suggested failure response when reversal is unsafe:

```json
{
  "success": false,
  "message": "Purchase update would make stock negative for one or more products.",
  "errors": {
    "items": [
      "Stock integrity check failed during purchase update."
    ]
  }
}
```

### Purchase Validation Rules

Mobile purchase APIs should validate at least:

- `purchase_date` is required and valid
- `items` is required and must not be empty
- `items.*.product_id` must exist
- `items.*.quantity` must be greater than 0
- `items.*.unit_cost` must be 0 or greater

Suggested validation error response:

```json
{
  "success": false,
  "message": "The given data was invalid.",
  "errors": {
    "items.0.quantity": [
      "The quantity field must be greater than 0."
    ]
  }
}
```

### Barcode-Assisted Purchase Item Flow

Barcode should be used for product selection, not as the saved purchase key.

Use:

```http
GET /api/inventory-manager/barcode/purchase-products/{barcode}
```

Response should give mobile app the product details needed to build a purchase line item, especially:

- `id`
- `name`
- `sku`
- `barcode`
- `current_stock`
- `purchase_price`
- `selling_price`
- `category`
- `unit`

Then mobile app should convert the barcode lookup result into a purchase item like:

```json
{
  "product_id": 12,
  "quantity": 5,
  "unit_cost": 10
}
```

Correct mobile purchase flow:

1. user scans barcode
2. app calls purchase barcode lookup API
3. app receives product details and `data.id`
4. app adds item to local purchase form using `product_id`
5. user enters quantity and unit cost
6. app submits purchase using the normal purchase contract
7. backend updates stock through purchase business

### Stock Update Behavior

Stock should continue to be updated only through purchase business.

#### During purchase create

- stock quantity increases
- stock movement type is purchase
- total amount is recalculated

#### During purchase update

- old purchase stock effect is reversed
- new purchase stock effect is applied
- unsafe reversal is rejected
- stock movements keep the audit trail

This preserves stock integrity and keeps purchase as the source of stock-in.

### Mobile Purchase Scope

For mobile product listing and barcode-assisted receiving preparation, the current APIs are already enough:

- `GET /api/products`
- `GET /api/inventory-manager/barcode/purchase-products/{barcode}`

For full mobile purchase save and edit, dedicated mobile purchase APIs should be exposed using the existing backend purchase services.

## Conclusion

For the inventory manager mobile app, these features are enough for v1:

- Product
- Purchase
- Inventory
- Barcode scanner
- Categories master data
- Units master data
- Mobile purchase list/details/create/update APIs built on the existing purchase business
