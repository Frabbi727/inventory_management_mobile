# Mobile Product API Reference

This document is for the mobile app integration.

Covered endpoints:

1. `GET /api/products`
2. `GET /api/products/{id}`
3. `GET /api/products/barcode/{barcode}`
4. `GET /api/inventory-manager/barcode/products/{barcode}/resolve`
5. `GET /api/inventory-manager/barcode/purchase-products/{barcode}`

## Mobile Auth

Send these headers with every request:

```http
Authorization: Bearer <token>
Accept: application/json
```

## Request Body

All endpoints in this document are `GET`.

- Body: `none`
- Use query params or path params only

## 1. Product List

### Endpoint

```http
GET /api/products
```

### Mobile use

Use this for:

- product catalog screen
- search screen
- filtered product list

### Allowed roles

- `admin`
- `manager`
- `salesman`
- `inventory_manager`

### Query params

| Param | Type | Required | Notes |
| --- | --- | --- | --- |
| `q` | string | No | Search by product name, sku, barcode, variant sku, variant barcode, variant display name |
| `status` | string | No | `active` or `inactive` |
| `category_id` | integer | No | Filter by category |
| `subcategory_id` | integer | No | Filter by subcategory |
| `has_variants` | boolean | No | `1/0`, `true/false` |
| `unit_id` | integer | No | Filter by unit |
| `stock_status` | string | No | `in_stock` or `out_of_stock` |
| `sort` | string | No | `name`, `stock`, `latest` |
| `page` | integer | No | Pagination |
| `attribute[color]` | string | No | Variant attribute filter example |

### Example request

```http
GET /api/products?q=milk&status=active&category_id=1&page=1
```

### Success response

Status: `200 OK`

```json
{
  "data": [
    {
      "id": 1,
      "name": "Milk Pack",
      "sku": "PRD-MILK-PACK",
      "barcode": "BAR-000111",
      "barcode_image_url": "https://example.com/storage/products/milk-pack/barcode.svg",
      "purchase_price": 80.5,
      "selling_price": 100.75,
      "minimum_stock_alert": 5,
      "status": "active",
      "has_variants": false,
      "current_stock": 12,
      "stock_status": "in_stock",
      "price_summary": null,
      "variant_summary": null,
      "variant_attributes": [],
      "matched_variant": null,
      "primary_photo": null,
      "photo_count": 0,
      "category": {
        "id": 1,
        "name": "Beverages"
      },
      "subcategory": {
        "id": 2,
        "name": "Milk Drinks",
        "category_id": 1
      },
      "unit": {
        "id": 1,
        "name": "Piece",
        "short_name": "pc"
      },
      "created_at": "2026-04-14T10:00:00.000000Z",
      "updated_at": "2026-04-14T10:00:00.000000Z"
    }
  ],
  "links": {
    "first": "http://localhost/api/products?page=1",
    "last": "http://localhost/api/products?page=1",
    "prev": null,
    "next": null
  },
  "meta": {
    "current_page": 1,
    "from": 1,
    "last_page": 1,
    "path": "http://localhost/api/products",
    "per_page": 15,
    "to": 1,
    "total": 1
  }
}
```

### Error response

```json
{
  "message": "Unauthenticated."
}
```

Or:

```json
{
  "message": "This action is unauthorized."
}
```

## 2. Product Detail

### Endpoint

```http
GET /api/products/{id}
```

### Mobile use

Use this for:

- product details screen
- edit product prefill
- showing variants and photos

### Path param

| Param | Type | Required | Notes |
| --- | --- | --- | --- |
| `id` | integer | Yes | Product ID |

### Request body

None.

### Example request

```http
GET /api/products/1
```

### Success response

Status: `200 OK`

```json
{
  "data": {
    "id": 1,
    "name": "Classic T-Shirt",
    "sku": "TSHIRT-001",
    "barcode": "1234567890123",
    "barcode_image_url": "https://example.com/storage/products/barcode.svg",
    "purchase_price": 220,
    "selling_price": 350,
    "minimum_stock_alert": 5,
    "status": "active",
    "has_variants": true,
    "current_stock": 8,
    "stock_status": "in_stock",
    "price_summary": {
      "min_buying_price": 210,
      "max_buying_price": 225,
      "min_selling_price": 340,
      "max_selling_price": 360
    },
    "variant_summary": {
      "total_variants": 4,
      "in_stock_count": 2,
      "low_stock_count": 1,
      "out_of_stock_count": 1
    },
    "variant_attributes": [
      {
        "id": 1,
        "name": "Color",
        "values": ["Red", "Blue"]
      },
      {
        "id": 2,
        "name": "Size",
        "values": ["M", "L"]
      }
    ],
    "matched_variant": null,
    "variants": [
      {
        "id": 11,
        "sku": "TSHIRT-001-RED-M",
        "barcode": "TSHIRT-001-RED-M-BAR",
        "attributes": {
          "color": "Red",
          "size": "M"
        },
        "quantity": 5,
        "buying_price": 220,
        "selling_price": 350,
        "stock_status": "in_stock",
        "status": "active",
        "display_name": "Red / M",
        "combination_key": "color-red__size-m",
        "combination_label": "Red / M",
        "option_values": {
          "color": "Red",
          "size": "M"
        },
        "purchase_price": 220,
        "is_active": true
      }
    ],
    "primary_photo": null,
    "photo_count": 0,
    "photos": [],
    "category": {
      "id": 4,
      "name": "Apparel"
    },
    "subcategory": {
      "id": 7,
      "name": "T-Shirts",
      "category_id": 4
    },
    "unit": {
      "id": 2,
      "name": "Piece",
      "short_name": "pc"
    },
    "created_at": "2026-04-14T10:00:00.000000Z",
    "updated_at": "2026-04-14T10:00:00.000000Z"
  }
}
```

### Not found response

Status: `404 Not Found`

```json
{
  "message": "No query results for model [App\\Modules\\Products\\Models\\Product] 9999"
}
```

## 3. Exact Product Barcode Lookup

### Endpoint

```http
GET /api/products/barcode/{barcode}
```

### Mobile use

Use this when:

- mobile scans barcode
- barcode must match exactly
- app needs product or variant match immediately

### Path param

| Param | Type | Required | Notes |
| --- | --- | --- | --- |
| `barcode` | string | Yes | Exact product barcode or exact active variant barcode |

### Request body

None.

### Success response for product barcode

Status: `200 OK`

```json
{
  "match_type": "product",
  "product": {
    "id": 1,
    "name": "Barcode Search Product",
    "sku": "API-BAR-1001",
    "barcode": "BAR-000111",
    "barcode_image_url": "https://example.com/storage/products/api-bar-1001/barcode.svg",
    "purchase_price": 10,
    "selling_price": 15,
    "minimum_stock_alert": 2,
    "status": "active",
    "has_variants": false,
    "current_stock": 0,
    "stock_status": "out_of_stock",
    "price_summary": null,
    "variant_summary": null,
    "variant_attributes": [],
    "matched_variant": null,
    "primary_photo": null,
    "photo_count": 0,
    "photos": [],
    "category": {
      "id": 1,
      "name": "Category"
    },
    "subcategory": null,
    "unit": {
      "id": 1,
      "name": "Piece",
      "short_name": "pc"
    },
    "created_at": "2026-04-14T10:00:00.000000Z",
    "updated_at": "2026-04-14T10:00:00.000000Z"
  },
  "variant": null
}
```

### Success response for variant barcode

```json
{
  "match_type": "variant",
  "product": {
    "id": 1,
    "name": "Classic T-Shirt",
    "matched_variant": {
      "id": 11,
      "sku": "TSHIRT-001-RED-M",
      "barcode": "VAR-RED-M",
      "attributes": {
        "color": "Red",
        "size": "M"
      },
      "quantity": 5,
      "buying_price": 220,
      "selling_price": 350,
      "stock_status": "in_stock",
      "status": "active",
      "display_name": "Red / M"
    }
  },
  "variant": {
    "id": 11,
    "sku": "TSHIRT-001-RED-M",
    "barcode": "VAR-RED-M",
    "attributes": {
      "color": "Red",
      "size": "M"
    },
    "quantity": 5,
    "buying_price": 220,
    "selling_price": 350,
    "stock_status": "in_stock",
    "status": "active",
    "display_name": "Red / M"
  }
}
```

### Not found response

Status: `404 Not Found`

```json
{
  "message": "No query results for model [App\\Modules\\Products\\Models\\Product] BAR-UNKNOWN"
}
```

## 4. Inventory Manager Scan Resolve

### Endpoint

```http
GET /api/inventory-manager/barcode/products/{barcode}/resolve
```

### Mobile use

Use this first in inventory-manager barcode flow:

- if barcode exists, open view/update product flow
- if barcode does not exist, open create product flow

### Allowed role

- `inventory_manager`

### Path param

| Param | Type | Required | Notes |
| --- | --- | --- | --- |
| `barcode` | string | Yes | Scanned barcode |

### Request body

None.

### Success response when barcode exists

Status: `200 OK`

```json
{
  "message": "Barcode resolved successfully.",
  "exists": true,
  "action": "view_or_update",
  "barcode": "BAR-RESOLVE-1001",
  "match_type": "product",
  "data": {
    "id": 1,
    "name": "Scanner Product",
    "sku": "SCAN-1001",
    "barcode": "BAR-RESOLVE-1001"
  },
  "variant": null
}
```

### Success response when barcode does not exist

Status: `200 OK`

```json
{
  "message": "Barcode not found. Product can be created.",
  "exists": false,
  "action": "create",
  "barcode": "NEW-998877",
  "match_type": null,
  "data": null,
  "variant": null
}
```

### Success response when variant barcode exists

```json
{
  "message": "Barcode resolved successfully.",
  "exists": true,
  "action": "view_or_update",
  "barcode": "VAR-RED-M",
  "match_type": "variant",
  "data": {
    "id": 1,
    "name": "Classic T-Shirt",
    "matched_variant": {
      "id": 11,
      "sku": "TSHIRT-001-RED-M",
      "barcode": "VAR-RED-M",
      "attributes": {
        "color": "Red",
        "size": "M"
      },
      "quantity": 5,
      "buying_price": 220,
      "selling_price": 350,
      "stock_status": "in_stock",
      "status": "active",
      "display_name": "Red / M"
    }
  },
  "variant": {
    "id": 11,
    "sku": "TSHIRT-001-RED-M",
    "barcode": "VAR-RED-M",
    "attributes": {
      "color": "Red",
      "size": "M"
    },
    "quantity": 5,
    "buying_price": 220,
    "selling_price": 350,
    "stock_status": "in_stock",
    "status": "active",
    "display_name": "Red / M"
  }
}
```

## 5. Purchase Barcode Lookup

### Endpoint

```http
GET /api/inventory-manager/barcode/purchase-products/{barcode}
```

### Mobile use

Use this in purchase entry / receiving screen after scan.

### Allowed role

- `inventory_manager`

### Path param

| Param | Type | Required | Notes |
| --- | --- | --- | --- |
| `barcode` | string | Yes | Exact product barcode or exact active variant barcode |

### Request body

None.

### Success response

Status: `200 OK`

```json
{
  "data": {
    "id": 1,
    "name": "Purchase Lookup Product",
    "sku": "PUR-LOOKUP-1001",
    "barcode": "PUR-LOOKUP-1001",
    "barcode_image_url": null,
    "purchase_price": 10,
    "selling_price": 14,
    "minimum_stock_alert": 2,
    "status": "active",
    "has_variants": false,
    "current_stock": 0,
    "stock_status": "out_of_stock",
    "price_summary": null,
    "variant_summary": null,
    "variant_attributes": [],
    "matched_variant": null,
    "primary_photo": null,
    "photo_count": 0,
    "photos": [],
    "category": {
      "id": 1,
      "name": "Category"
    },
    "subcategory": null,
    "unit": {
      "id": 1,
      "name": "Piece",
      "short_name": "pc"
    },
    "created_at": "2026-04-14T10:00:00.000000Z",
    "updated_at": "2026-04-14T10:00:00.000000Z"
  }
}
```

### Not found response

Status: `404 Not Found`

```json
{
  "message": "No query results for model [App\\Modules\\Products\\Models\\Product] PUR-UNKNOWN"
}
```

## Mobile Integration Notes

- Use `GET /api/products` for list/search screens.
- Use `GET /api/products/{id}` for full detail.
- Use `GET /api/products/barcode/{barcode}` for exact mobile barcode lookup.
- Use `GET /api/inventory-manager/barcode/products/{barcode}/resolve` only for inventory-manager create/update scan flow.
- Use `GET /api/inventory-manager/barcode/purchase-products/{barcode}` for purchase receiving flow.
- Do not send request body in any of these APIs.
- Let the backend be the source of truth for `current_stock`, `stock_status`, `matched_variant`, `variant_summary`, and `price_summary`.
