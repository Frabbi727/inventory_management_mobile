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

## Conclusion

For the inventory manager mobile app, these features are enough for v1:

- Product
- Purchase
- Inventory
- Barcode scanner
- Categories master data
- Units master data
