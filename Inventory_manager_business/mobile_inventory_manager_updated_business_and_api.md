# Inventory Manager Mobile Updated Business and API Guide

This is the current updated backend contract for the inventory manager mobile app.

Use this document when moving the mobile app from the previous business to the new business.

## What Changed

The old mobile business was mostly read-only for inventory manager purchase work.

The updated business now supports:

- authenticated mobile inventory manager access
- master data preload for categories, subcategories, and units
- product list and product detail APIs
- barcode-driven product lookup flows
- barcode-driven purchase lookup flows
- purchase list and purchase detail APIs
- purchase create and purchase update APIs
- variant-aware purchase lines

## Main Business Rules

### 1. Authentication

Login first and keep the Sanctum token on the device.

Protected requests should send:

```http
Accept: application/json
X-Authorization: Bearer <token>
```

`X-Authorization` is supported for production environments where the normal `Authorization` header may be stripped before Laravel receives it.

### 2. Product Business

- A product may be a simple product or a variant product.
- `has_variants = false` means simple product.
- `has_variants = true` means the product has child variants.
- Mobile should trust backend stock fields like `current_stock` and `stock_status`.
- Mobile should not calculate stock itself.

### 3. Barcode Business

Barcode is now used for fast lookup and barcode-first product handling.

There are two barcode use cases:

- product lookup for inventory manager barcode screens
- purchase preparation lookup for scanned barcode flows

For variant products:

- barcode may match the parent product
- barcode may match a specific active variant
- backend returns `matched_variant` when a variant barcode is resolved

### 4. Purchase Business

Purchase APIs are now live for `admin` and `inventory_manager`.

Purchase lines are now variant-aware:

- simple product line: send `product_id`, do not send variant or send `null`
- variant product line: send both `product_id` and `product_variant_id`

Important validation rules:

- `purchase_date` is required
- `items` is required and must contain at least one line
- `items.*.product_id` is required
- `items.*.quantity` must be greater than `0`
- `items.*.unit_cost` may be `null` or `>= 0`
- variant products must include `product_variant_id`
- simple products must not include a variant id
- duplicate lines are blocked for the same `product_id + product_variant_id` combination

### 5. Stock Business

Purchase create increases stock.

Purchase update is not a blind overwrite.
Backend first reverses the old purchase effect, then applies the new purchase effect safely.

That means mobile only sends the corrected final payload.
Backend handles the stock correction rules.

## Roles

### Inventory manager

- login/logout/me
- categories/subcategories/units
- products list/detail
- barcode inventory manager endpoints
- purchases list/detail/create/update

### Admin

- same purchase access as inventory manager
- can also delete purchases

### Manager and salesman

- can read product and master data
- cannot use inventory-manager barcode endpoints
- cannot create or update purchases

## Updated API List

## Auth

- `POST /api/login`
- `POST /api/logout`
- `GET /api/me`

## Master Data

- `GET /api/categories`
- `GET /api/subcategories`
- `GET /api/subcategories?category_id={id}`
- `GET /api/units`

## Products

- `GET /api/products`
- `GET /api/products/{id}`
- `GET /api/products/barcode/{barcode}`
- `POST /api/products`
- `PUT /api/products/{id}`

## Inventory Manager Barcode

- `GET /api/inventory-manager/barcode/products/{barcode}/resolve`
- `GET /api/inventory-manager/barcode/products/{barcode}`
- `POST /api/inventory-manager/barcode/products`
- `PUT /api/inventory-manager/barcode/products/{barcode}`
- `GET /api/inventory-manager/barcode/purchase-products/{barcode}`

## Purchases

- `GET /api/purchases`
- `GET /api/purchases/{id}`
- `POST /api/purchases`
- `PUT /api/purchases/{id}`

## Product List Query Support

`GET /api/products`

Supported query params:

- `q`
- `status`
- `category_id`
- `subcategory_id`
- `has_variants`
- `unit_id`
- `stock_status`
- `sort`
- `page`
- `attribute[key]`

Search now supports partial matching on:

- product name
- SKU
- barcode
- active variant SKU
- active variant barcode
- active variant display name

## Purchase List Query Support

`GET /api/purchases`

Supported query params:

- `q`
- `start_date`
- `end_date`
- `page`

Use `q` against `purchase_no`.

## Updated Purchase Payloads

### Create simple product purchase

```json
{
  "purchase_date": "2026-04-14",
  "note": "Warehouse receive",
  "items": [
    {
      "product_id": 12,
      "product_variant_id": null,
      "quantity": 10,
      "unit_cost": 120
    }
  ]
}
```

### Create variant purchase

```json
{
  "purchase_date": "2026-04-14",
  "note": "Variant stock receive",
  "items": [
    {
      "product_id": 15,
      "product_variant_id": 44,
      "quantity": 8,
      "unit_cost": 220
    }
  ]
}
```

### Update purchase

```json
{
  "purchase_date": "2026-04-15",
  "note": "Corrected receive",
  "items": [
    {
      "product_id": 15,
      "product_variant_id": 44,
      "quantity": 12,
      "unit_cost": 220
    }
  ]
}
```

## Purchase Response Shape

Purchase detail and purchase create/update responses include:

- `id`
- `purchase_no`
- `purchase_date`
- `total_amount`
- `note`
- `creator`
- `items_count`
- `items`

Each purchase item can include:

- `id`
- `product_id`
- `product_variant_id`
- `product_name`
- `variant_label`
- `product_barcode`
- `quantity`
- `unit_cost`
- `line_total`
- `product.variant`

## Mobile Migration Notes

If your mobile app still follows the previous business, update these parts:

1. Add subcategory preload and category-based subcategory reload.
2. Add variant handling in product detail and purchase line selection.
3. Change purchase payload to support `product_variant_id`.
4. Stop computing stock in Flutter.
5. Use barcode resolve APIs for scanner flows instead of only local search.
6. Use purchase lookup barcode API before building a purchase line from scan.
7. Restrict purchase create/update screens to `inventory_manager` and `admin`.

## Postman Files To Use

Use these repo files directly:

- `docs/postman/inventory-manager-mobile-api.postman_collection.json`
- `docs/postman/Inventory-Manager-Mobile.postman_environment.json`

The main updated collection already includes:

- login
- me
- categories
- subcategories
- units
- products list/detail/barcode lookup
- inventory manager barcode resolve
- purchase scan lookup
- purchase list/detail
- create simple purchase
- create variant purchase
- update purchase

## Recommended Handoff To Mobile Developer

Give your mobile developer these four files first:

- `docs/mobile_inventory_manager_updated_business_and_api.md`
- `docs/inventory_manager_flutter_api_endpoints.md`
- `docs/mobile_product_api_reference.md`
- `docs/postman/inventory-manager-mobile-api.postman_collection.json`

## Important Note

This guide reflects the current backend contract in this codebase on April 14, 2026.
If you also want, the next step is to generate a clean Flutter-side API map and request/response model list from this backend so your mobile developer can plug it in directly.
