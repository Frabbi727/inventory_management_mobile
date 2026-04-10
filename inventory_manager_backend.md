**Barcode Scanner Business Documentation**

This document explains the full business for using barcode scanner plus manual product CRUD together, and how your mobile app can use the current APIs for `Product`, `Purchase`, and `Inventory` features.

## 1. Business Goal

The system supports two parallel product businesses:

- `Manual product CRUD`
- `Barcode-driven product flow`

These two flows must work together without breaking each other.

The barcode scanner flow is designed for the `inventory_manager` role so the mobile app can:

- scan barcode and instantly identify a product
- create a new product if barcode does not exist
- update a product by barcode
- use barcode lookup during purchase/stock receiving
- manage product photos during create/edit
- reuse existing product and purchase business safely

## 2. Main Business Principle

Do not think of barcode as a replacement for product CRUD.

Think of it like this:

- `Manual CRUD` is the normal business
- `Barcode flow` is a fast entry layer on top of product business
- `Purchase flow` still works by `product_id`
- `Inventory` is still derived from purchases and stock movements
- `Barcode` helps mobile users find or prepare product selection faster

So barcode is a `resolve and entry mechanism`, not a separate inventory database.

## 3. User Role

Current scanner APIs are for:

- `inventory_manager` only

That means:

- inventory manager can scan, create, update, and lookup barcode products
- other roles should not use these scanner endpoints unless you later expand access

## 4. Product Business Structure

### A. Manual Product CRUD

This is the existing product management business.

Use when:

- user manually creates product from web/mobile form
- user edits product using normal product screens
- user manages products without barcode scan first

Manual product business includes:

- product name
- sku
- barcode
- category
- unit
- purchase price
- selling price
- minimum stock alert
- status
- photos
- barcode image generation

### B. Barcode Product Flow

This is the new scanner-first business.

Use when:

- user scans a barcode first
- app must decide whether product already exists
- app must quickly create or update product from scanned barcode
- app must prepare purchase receiving by barcode

Barcode flow starts from:

```http
GET /api/inventory-manager/barcode/products/{barcode}/resolve
```

This endpoint tells the mobile app what to do next.

## 5. Core Barcode Business Flow

### Flow 1: Scan barcode

Mobile app scans barcode and calls:

```http
GET /api/inventory-manager/barcode/products/{barcode}/resolve
```

### Flow 2: System checks exact barcode match

Possible outcomes:

#### If product exists
System returns:

- `exists = true`
- `action = view_or_update`
- full product payload in `data`

Then mobile app can:

- open product details
- open edit product screen
- use product in purchase receiving
- show stock, price, category, unit, barcode image, photos

#### If product does not exist
System returns:

- `exists = false`
- `action = create`
- scanned barcode
- `data = null`

Then mobile app can:

- open create product screen
- prefill barcode field
- let inventory manager complete product form
- optionally upload photos during creation

## 6. Product APIs for Mobile App

### 6.1 Resolve barcode
```http
GET /api/inventory-manager/barcode/products/{barcode}/resolve
```

**Use**
- first API after scan
- decides create vs existing product

**Found response**
```json
{
  "message": "Barcode resolved successfully.",
  "exists": true,
  "action": "view_or_update",
  "barcode": "BAR-000111",
  "data": {
    "id": 12,
    "name": "Barcode Search Product",
    "sku": "API-BAR-1001",
    "barcode": "BAR-000111",
    "barcode_image_url": "https://example.com/storage/products/api-bar-1001/barcode/barcode.svg",
    "purchase_price": 10,
    "selling_price": 15,
    "minimum_stock_alert": 2,
    "status": "active",
    "current_stock": 8,
    "primary_photo": null,
    "photo_count": 0,
    "photos": [],
    "category": {
      "id": 3,
      "name": "Beverages"
    },
    "unit": {
      "id": 2,
      "name": "Piece",
      "short_name": "pc"
    },
    "created_at": "2026-04-10T09:00:00.000000Z",
    "updated_at": "2026-04-10T09:00:00.000000Z"
  }
}
```

**Not found response**
```json
{
  "message": "Barcode not found. Product can be created.",
  "exists": false,
  "action": "create",
  "barcode": "NEW-998877",
  "data": null
}
```

---

### 6.2 Create product from barcode flow
```http
POST /api/inventory-manager/barcode/products
```

**Use**
- create product after scan returned `exists=false`

**Request**
Use `multipart/form-data` if uploading photos.

Fields:

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

**Example**
```text
name=New Scanner Product
sku=SCN-1001
barcode=NEW-998877
category_id=1
unit_id=1
purchase_price=10
selling_price=15
minimum_stock_alert=2
status=active
photos[]=front.jpg
photos[]=side.png
```

**Success**
```json
{
  "message": "Product created successfully.",
  "data": {
    "id": 19,
    "name": "New Scanner Product",
    "sku": "SCN-1001",
    "barcode": "NEW-998877",
    "photo_count": 2
  }
}
```

**Validation**
- duplicate barcode not allowed
- duplicate sku not allowed
- category and unit must exist
- status must be valid
- photos follow product media validation rules

---

### 6.3 Update product by barcode
```http
PUT /api/inventory-manager/barcode/products/{barcode}
```

**Use**
- update product after scan returned `exists=true`

**Request**
Normal product fields plus optional `photos[]`

**Example**
```text
name=Updated Product
sku=SCN-1001
barcode=NEW-998877
category_id=1
unit_id=1
purchase_price=12
selling_price=18
minimum_stock_alert=3
status=active
photos[]=new-angle.jpg
```

**Success**
```json
{
  "message": "Product updated successfully.",
  "data": {
    "id": 19,
    "name": "Updated Product",
    "sku": "SCN-1001",
    "barcode": "NEW-998877"
  }
}
```

---

### 6.4 Get full product by barcode
```http
GET /api/inventory-manager/barcode/products/{barcode}
```

**Use**
- fetch exact product details when barcode is already known

**Response**
```json
{
  "data": {
    "id": 19,
    "name": "Updated Product",
    "sku": "SCN-1001",
    "barcode": "NEW-998877"
  }
}
```

## 7. Product Photo Business

Photos are part of the product business in both manual and barcode flows.

### During product create
Supported in:

```http
POST /api/inventory-manager/barcode/products
```

Use `photos[]`.

### During product update
Supported in:

```http
PUT /api/inventory-manager/barcode/products/{barcode}
```

Use `photos[]`.

### After product exists
Use existing product photo APIs:

#### Add more photos
```http
POST /api/products/{product}/photos
```

#### Replace or edit a photo
```http
PUT / PATCH /api/products/{product}/photos/{photo}
```

Can update:
- file
- `sort_order`
- `is_primary`

#### Delete photo
```http
DELETE /api/products/{product}/photos/{photo}
```

#### Reorder photos
```http
PATCH /api/products/{product}/photos/reorder
```

**Business rules**
- images only
- max count applies
- one primary photo
- if no primary exists, system auto assigns one

## 8. Purchase Business for Mobile App

### Current purchase business logic

Purchase still works by `product_id`, not barcode.

That means barcode is used only to find the product quickly. After lookup, purchase line items still use:

- `product_id`
- `quantity`
- `unit_cost`

### Purchase barcode helper API
```http
GET /api/inventory-manager/barcode/purchase-products/{barcode}
```

**Use**
- scan item during purchase receiving
- instantly resolve product
- frontend uses returned `data.id` as `product_id`

**Response**
```json
{
  "data": {
    "id": 12,
    "name": "Barcode Search Product",
    "sku": "API-BAR-1001",
    "barcode": "BAR-000111",
    "current_stock": 8,
    "purchase_price": 10,
    "selling_price": 15,
    "category": {
      "id": 3,
      "name": "Beverages"
    },
    "unit": {
      "id": 2,
      "name": "Piece",
      "short_name": "pc"
    }
  }
}
```

### Purchase save business
Your final purchase save should still use the existing purchase business contract.

If later you build a mobile purchase create screen, its business should still submit:

- `purchase_date`
- `note`
- `items[]`
- `items.*.product_id`
- `items.*.quantity`
- `items.*.unit_cost`

Barcode is not submitted as purchase line storage. Barcode is only used to resolve the product before submission.

## 9. Inventory Business for Mobile App

Inventory is not a separate write business here.

Inventory comes from existing stock and stock movement logic.

What mobile app can use from product scanner responses:

- `current_stock`
- `minimum_stock_alert`
- `status`
- product details
- purchase prices and selling prices

### What barcode helps with in inventory
- quickly identify product
- show stock on scan
- support stock receiving preparation
- avoid fuzzy product search

### What still drives inventory
- purchase create/update
- stock rows
- stock movement records

So for inventory-related mobile screens, barcode APIs are enough for:

- scan to identify product
- scan to display stock
- scan to prepare receiving item selection

## 10. Manual CRUD vs Barcode Flow

### Manual Product CRUD
Use when:
- user browses catalog
- user creates product without scanning
- user edits by selecting product manually

### Barcode Product Flow
Use when:
- user scans first
- app must decide instantly whether product exists
- user creates product from scanned code
- user updates product from scanned code
- user resolves product for purchase receiving

### Important rule
Both flows use the same underlying product business and data model.

That means:
- no duplicate product logic
- no different product schema
- no separate inventory rules
- backward compatibility stays safe

## 11. Mobile App Recommended Screens

For `inventory_manager`, these mobile screens are enough for a strong first version:

### Product module
- product list
- product details
- scan barcode
- create product from scan
- edit product from scan
- upload photos
- replace/delete/reorder photos

### Purchase module
- purchase list
- create purchase
- scan product barcode for line item selection
- manual quantity and unit cost entry
- submit purchase using `product_id`

### Inventory module
- scan product and show stock details
- low stock list
- stock summary per product
- product details with current stock
- stock movement history if you expose it later

## 12. Is Product + Purchase + Inventory Enough for Mobile App?

Yes, for an `inventory_manager` mobile app first version, these three features are enough.

A practical v1 is:

- `Product`
- `Purchase`
- `Inventory`

Why this is enough:

- Product gives master data management
- Barcode gives fast scanner entry
- Purchase updates stock inward
- Inventory lets user verify stock result

This is enough for warehouse/inventory staff to:

- scan product
- identify existing item
- add new product if missing
- manage photos
- receive stock by purchase
- verify available stock

## 13. Recommended End-to-End Mobile Workflows

### Workflow A: Scan existing product
1. Scan barcode
2. Call `resolve`
3. If exists, show product details
4. Allow edit if needed
5. Show current stock and photos

### Workflow B: Scan new product
1. Scan barcode
2. Call `resolve`
3. If not found, open create screen
4. Prefill barcode
5. Fill product fields
6. Upload photos if needed
7. Submit create request

### Workflow C: Purchase receiving
1. Open create purchase
2. Scan barcode for each item
3. Call purchase barcode lookup
4. Use returned `product_id`
5. Enter quantity and unit cost
6. Add line item
7. Submit purchase
8. Inventory updates through existing purchase business

### Workflow D: Inventory check
1. Scan barcode
2. Call resolve or product barcode detail
3. Show product info
4. Show `current_stock`
5. Show low stock status based on `minimum_stock_alert`

## 14. Error Handling

### 403 Forbidden
User is not inventory manager.

### 404 Not Found
Used by direct exact lookup endpoints when barcode does not exist.

Use `resolve` first if you want safe scanner behavior.

### 422 Validation Error
Returned when:
- barcode duplicate
- sku duplicate
- required fields missing
- category/unit invalid
- image validation fails

## 15. Final API Set For Mobile App

### Barcode scanner APIs
- `GET /api/inventory-manager/barcode/products/{barcode}/resolve`
- `GET /api/inventory-manager/barcode/products/{barcode}`
- `POST /api/inventory-manager/barcode/products`
- `PUT /api/inventory-manager/barcode/products/{barcode}`
- `GET /api/inventory-manager/barcode/purchase-products/{barcode}`

### Existing product media APIs
- `POST /api/products/{product}/photos`
- `PUT|PATCH /api/products/{product}/photos/{photo}`
- `DELETE /api/products/{product}/photos/{photo}`
- `PATCH /api/products/{product}/photos/reorder`

### Existing product/catalog APIs
- `GET /api/products`
- `GET /api/products/{product}`

### Existing purchase business APIs
If you expose purchase create/update for mobile later, keep using existing product-id based purchase contract.

## 16. Final Business Conclusion

Yes, for your mobile app, these features are enough for v1:

- `Product`
- `Purchase`
- `Inventory`
- `Barcode scanner entry layer`

That is enough for inventory staff to operate product intake and stock receiving efficiently.

If you want, next I can turn this into either:

1. a clean `mobile_barcode_business_documentation.md`, or
2. a full API integration document with request/response tables for Flutter mobile app use.