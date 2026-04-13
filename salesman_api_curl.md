curl --location 'http://192.168.0.199:8000/api/products?q=milk&status=active&category_id=1&subcategory_id=1&page=1' \
--header 'Accept: application/json' \
--header 'X-Authorization: Bearer 17|9ZP0dSz8LNdT5SdLmrJBVvss78Z7sa8OkuogzxMyfb3e2897'

{
"data": [
{
"id": 1,
"name": "Samsug S28",
"sku": "SKU-MP-SS-20260412-156923-1683",
"barcode": "BC-20260412-274247",
"barcode_image_url": "http://localhost/storage/products/sku-mp-ss-20260412-156923-1683/barcode/barcode.svg",
"purchase_price": 120000.89,
"selling_price": 150000.88,
"minimum_stock_alert": 10,
"status": "active",
"has_variants": true,
"current_stock": 131,
"stock_status": "in_stock",
"variant_summary": {
"total_variants": 3,
"in_stock_count": 3,
"low_stock_count": 0,
"out_of_stock_count": 0
},
"primary_photo": {
"id": 2,
"file_name": "01kp1csfm4nhdret6nb1kahpzd.jpg",
"file_url": "http://localhost/storage/products/sku-mp-ss-20260412-156923-1683/photos/01kp1csfm4nhdret6nb1kahpzd.jpg",
"mime_type": "image/jpeg",
"file_size": 109268,
"sort_order": 0,
"is_primary": true,
"created_at": "2026-04-12T17:45:49.000000Z",
"updated_at": "2026-04-12T17:45:49.000000Z"
},
"photo_count": 0,
"category": {
"id": 1,
"name": "Mobile Phone"
},
"subcategory": {
"id": 1,
"name": "Samsung",
"category_id": 1
},
"unit": {
"id": 1,
"name": "Piece",
"short_name": "pc"
},
"created_at": "2026-04-12T14:45:56.000000Z",
"updated_at": "2026-04-12T14:45:56.000000Z"
}
],
"links": {
"first": "http://192.168.0.199:8000/api/products?status=active&category_id=1&subcategory_id=1&page=1",
"last": "http://192.168.0.199:8000/api/products?status=active&category_id=1&subcategory_id=1&page=1",
"prev": null,
"next": null
},
"meta": {
"current_page": 1,
"from": 1,
"last_page": 1,
"links": [
{
"url": null,
"label": "&laquo; Previous",
"page": null,
"active": false
},
{
"url": "http://192.168.0.199:8000/api/products?status=active&category_id=1&subcategory_id=1&page=1",
"label": "1",
"page": 1,
"active": true
},
{
"url": null,
"label": "Next &raquo;",
"page": null,
"active": false
}
],
"path": "http://192.168.0.199:8000/api/products",
"per_page": 15,
"to": 1,
"total": 1
}
}



curl --location 'http://192.168.0.199:8000/api/products/1' \
--header 'Accept: application/json' \
--header 'X-Authorization: Bearer 17|9ZP0dSz8LNdT5SdLmrJBVvss78Z7sa8OkuogzxMyfb3e2897'


{
"data": {
"id": 1,
"name": "Samsug S28",
"sku": "SKU-MP-SS-20260412-156923-1683",
"barcode": "BC-20260412-274247",
"barcode_image_url": "http://localhost/storage/products/sku-mp-ss-20260412-156923-1683/barcode/barcode.svg",
"purchase_price": 120000.89,
"selling_price": 150000.88,
"minimum_stock_alert": 10,
"status": "active",
"has_variants": true,
"current_stock": 131,
"stock_status": "in_stock",
"variant_summary": {
"total_variants": 3,
"in_stock_count": 3,
"low_stock_count": 0,
"out_of_stock_count": 0
},
"variant_attributes": [
{
"id": 7,
"name": "Red",
"values": [
"128",
"256",
"512"
]
}
],
"variants": [
{
"id": 1,
"combination_key": "red-128",
"combination_label": "128",
"option_values": {
"Red": "128"
},
"purchase_price": 120000.89,
"selling_price": 150000.88,
"is_active": true,
"current_stock": 103,
"stock_status": "in_stock"
},
{
"id": 2,
"combination_key": "red-256",
"combination_label": "256",
"option_values": {
"Red": "256"
},
"purchase_price": 120000.89,
"selling_price": 150000.88,
"is_active": true,
"current_stock": 12,
"stock_status": "in_stock"
},
{
"id": 3,
"combination_key": "red-512",
"combination_label": "512",
"option_values": {
"Red": "512"
},
"purchase_price": 120000.89,
"selling_price": 150000.88,
"is_active": true,
"current_stock": 16,
"stock_status": "in_stock"
}
],
"primary_photo": {
"id": 2,
"file_name": "01kp1csfm4nhdret6nb1kahpzd.jpg",
"file_url": "http://localhost/storage/products/sku-mp-ss-20260412-156923-1683/photos/01kp1csfm4nhdret6nb1kahpzd.jpg",
"mime_type": "image/jpeg",
"file_size": 109268,
"sort_order": 0,
"is_primary": true,
"created_at": "2026-04-12T17:45:49.000000Z",
"updated_at": "2026-04-12T17:45:49.000000Z"
},
"photo_count": 2,
"photos": [
{
"id": 2,
"file_name": "01kp1csfm4nhdret6nb1kahpzd.jpg",
"file_url": "http://localhost/storage/products/sku-mp-ss-20260412-156923-1683/photos/01kp1csfm4nhdret6nb1kahpzd.jpg",
"mime_type": "image/jpeg",
"file_size": 109268,
"sort_order": 0,
"is_primary": true,
"created_at": "2026-04-12T17:45:49.000000Z",
"updated_at": "2026-04-12T17:45:49.000000Z"
},
{
"id": 3,
"file_name": "01kp1csfn4em6adfc63xrfzvdj.webp",
"file_url": "http://localhost/storage/products/sku-mp-ss-20260412-156923-1683/photos/01kp1csfn4em6adfc63xrfzvdj.webp",
"mime_type": "image/webp",
"file_size": 24932,
"sort_order": 1,
"is_primary": false,
"created_at": "2026-04-12T17:45:49.000000Z",
"updated_at": "2026-04-12T17:45:49.000000Z"
}
],
"category": {
"id": 1,
"name": "Mobile Phone"
},
"subcategory": {
"id": 1,
"name": "Samsung",
"category_id": 1
},
"unit": {
"id": 1,
"name": "Piece",
"short_name": "pc"
},
"created_at": "2026-04-12T14:45:56.000000Z",
"updated_at": "2026-04-12T14:45:56.000000Z"
}
}

curl --location 'http://192.168.0.199:8000/api/subcategories?category_id=1' \
--header 'Accept: application/json' \
--header 'X-Authorization: Bearer 17|9ZP0dSz8LNdT5SdLmrJBVvss78Z7sa8OkuogzxMyfb3e2897'

{
"success": true,
"data": [
{
"id": 2,
"name": "Oppo",
"category_id": 1
},
{
"id": 3,
"name": "Real-me",
"category_id": 1
},
{
"id": 1,
"name": "Samsung",
"category_id": 1
},
{
"id": 4,
"name": "Vivo",
"category_id": 1
}
]
}


curl --location 'http://192.168.0.199:8000/api/customers?q=rahim&page=1' \
--header 'Accept: application/json' \
--header 'X-Authorization: Bearer 17|9ZP0dSz8LNdT5SdLmrJBVvss78Z7sa8OkuogzxMyfb3e2897'

{
"data": [
{
"id": 1,
"name": "Rabbi",
"phone": "01863098727",
"address": "Dhaka",
"area": "Dhaka",
"created_by": {
"id": 2,
"name": "Sales Demo"
},
"created_at": "2026-04-13T08:04:54.000000Z",
"updated_at": "2026-04-13T08:04:54.000000Z"
}
],
"links": {
"first": "http://192.168.0.199:8000/api/customers?page=1",
"last": "http://192.168.0.199:8000/api/customers?page=1",
"prev": null,
"next": null
},
"meta": {
"current_page": 1,
"from": 1,
"last_page": 1,
"links": [
{
"url": null,
"label": "&laquo; Previous",
"page": null,
"active": false
},
{
"url": "http://192.168.0.199:8000/api/customers?page=1",
"label": "1",
"page": 1,
"active": true
},
{
"url": null,
"label": "Next &raquo;",
"page": null,
"active": false
}
],
"path": "http://192.168.0.199:8000/api/customers",
"per_page": 15,
"to": 1,
"total": 1
}
}

curl --location 'http://192.168.0.199:8000/api/customers/1' \
--header 'Accept: application/json' \
--header 'X-Authorization: Bearer 17|9ZP0dSz8LNdT5SdLmrJBVvss78Z7sa8OkuogzxMyfb3e2897'

{
"data": {
"id": 1,
"name": "Rabbi",
"phone": "01863098727",
"address": "Dhaka",
"area": "Dhaka",
"created_by": {
"id": 2,
"name": "Sales Demo"
},
"created_at": "2026-04-13T08:04:54.000000Z",
"updated_at": "2026-04-13T08:04:54.000000Z"
}
}


curl --location 'http://192.168.0.199:8000/api/orders?q=rahim&status=draft&customer_id=1&start_date=2026-04-01&end_date=2026-04-30&page=1' \
--header 'Accept: application/json' \
--header 'X-Authorization: Bearer 17|9ZP0dSz8LNdT5SdLmrJBVvss78Z7sa8OkuogzxMyfb3e2897'

{
"data": [
{
"id": 6,
"order_no": "ORD-NYM1OGKH",
"order_date": "2026-04-13T00:00:00.000000Z",
"subtotal": 1800,
"discount_type": "percentage",
"discount_value": 5.12,
"discount_amount": 92.16,
"grand_total": 1707.84,
"status": "draft",
"note": null,
"customer": {
"id": 1,
"name": "Rabbi",
"phone": "01863098727"
},
"salesman": {
"id": 2,
"name": "Sales Demo"
},
"items": [
{
"id": 28,
"product_id": 5,
"product_variant_id": 13,
"product_name": "Basundhara Tissue (100)",
"variant_label": "100",
"quantity": 10,
"unit_price": 60,
"line_total": 600
},
{
"id": 29,
"product_id": 5,
"product_variant_id": 14,
"product_name": "Basundhara Tissue (200)",
"variant_label": "200",
"quantity": 10,
"unit_price": 60,
"line_total": 600
},
{
"id": 30,
"product_id": 5,
"product_variant_id": 15,
"product_name": "Basundhara Tissue (300)",
"variant_label": "300",
"quantity": 10,
"unit_price": 60,
"line_total": 600
}
],
"created_at": "2026-04-13T16:41:37.000000Z",
"updated_at": "2026-04-13T16:41:37.000000Z"
},
{
"id": 5,
"order_no": "ORD-RPUNTCHO",
"order_date": "2026-04-13T00:00:00.000000Z",
"subtotal": 1500608.8,
"discount_type": null,
"discount_value": 0,
"discount_amount": 0,
"grand_total": 1500608.8,
"status": "draft",
"note": null,
"customer": {
"id": 1,
"name": "Rabbi",
"phone": "01863098727"
},
"salesman": {
"id": 2,
"name": "Sales Demo"
},
"items": [
{
"id": 24,
"product_id": 1,
"product_variant_id": 1,
"product_name": "Samsug S28 (128)",
"variant_label": "128",
"quantity": 10,
"unit_price": 150000.88,
"line_total": 1500008.8
},
{
"id": 25,
"product_id": 4,
"product_variant_id": 10,
"product_name": "serfexel (L)",
"variant_label": "L",
"quantity": 30,
"unit_price": 10,
"line_total": 300
},
{
"id": 26,
"product_id": 4,
"product_variant_id": 11,
"product_name": "serfexel (M)",
"variant_label": "M",
"quantity": 20,
"unit_price": 10,
"line_total": 200
},
{
"id": 27,
"product_id": 4,
"product_variant_id": 12,
"product_name": "serfexel (S)",
"variant_label": "S",
"quantity": 10,
"unit_price": 10,
"line_total": 100
}
],
"created_at": "2026-04-13T16:20:45.000000Z",
"updated_at": "2026-04-13T16:20:45.000000Z"
},
{
"id": 4,
"order_no": "ORD-SRGBFVLZ",
"order_date": "2026-04-13T00:00:00.000000Z",
"subtotal": 301801.76,
"discount_type": "amount",
"discount_value": 109.99,
"discount_amount": 109.99,
"grand_total": 301691.77,
"status": "confirmed",
"note": null,
"customer": {
"id": 1,
"name": "Rabbi",
"phone": "01863098727"
},
"salesman": {
"id": 2,
"name": "Sales Demo"
},
"items": [
{
"id": 20,
"product_id": 5,
"product_variant_id": 13,
"product_name": "Basundhara Tissue (100)",
"variant_label": "100",
"quantity": 10,
"unit_price": 60,
"line_total": 600
},
{
"id": 21,
"product_id": 5,
"product_variant_id": 14,
"product_name": "Basundhara Tissue (200)",
"variant_label": "200",
"quantity": 10,
"unit_price": 60,
"line_total": 600
},
{
"id": 22,
"product_id": 5,
"product_variant_id": 15,
"product_name": "Basundhara Tissue (300)",
"variant_label": "300",
"quantity": 10,
"unit_price": 60,
"line_total": 600
},
{
"id": 23,
"product_id": 1,
"product_variant_id": 1,
"product_name": "Samsug S28 (128)",
"variant_label": "128",
"quantity": 2,
"unit_price": 150000.88,
"line_total": 300001.76
}
],
"created_at": "2026-04-13T15:36:07.000000Z",
"updated_at": "2026-04-13T15:36:26.000000Z"
},
{
"id": 3,
"order_no": "ORD-OJNBKRC3",
"order_date": "2026-04-13T00:00:00.000000Z",
"subtotal": 11700,
"discount_type": "percentage",
"discount_value": 23.93,
"discount_amount": 2799.81,
"grand_total": 8900.19,
"status": "confirmed",
"note": null,
"customer": {
"id": 1,
"name": "Rabbi",
"phone": "01863098727"
},
"salesman": {
"id": 2,
"name": "Sales Demo"
},
"items": [
{
"id": 10,
"product_id": 5,
"product_variant_id": 13,
"product_name": "Basundhara Tissue (100)",
"variant_label": "100",
"quantity": 100,
"unit_price": 60,
"line_total": 6000
},
{
"id": 11,
"product_id": 5,
"product_variant_id": 14,
"product_name": "Basundhara Tissue (200)",
"variant_label": "200",
"quantity": 95,
"unit_price": 60,
"line_total": 5700
}
],
"created_at": "2026-04-13T10:09:34.000000Z",
"updated_at": "2026-04-13T10:10:23.000000Z"
},
{
"id": 2,
"order_no": "ORD-O2ZU66LP",
"order_date": "2026-04-13T00:00:00.000000Z",
"subtotal": 6000,
"discount_type": "amount",
"discount_value": 7.11,
"discount_amount": 7.11,
"grand_total": 5992.89,
"status": "confirmed",
"note": "Test Draft",
"customer": {
"id": 1,
"name": "Rabbi",
"phone": "01863098727"
},
"salesman": {
"id": 2,
"name": "Sales Demo"
},
"items": [
{
"id": 5,
"product_id": 5,
"product_variant_id": 13,
"product_name": "Basundhara Tissue (100)",
"variant_label": "100",
"quantity": 100,
"unit_price": 60,
"line_total": 6000
}
],
"created_at": "2026-04-13T09:52:11.000000Z",
"updated_at": "2026-04-13T09:53:05.000000Z"
}
],
"links": {
"first": "http://192.168.0.199:8000/api/orders?customer_id=1&start_date=2026-04-01&end_date=2026-04-30&page=1",
"last": "http://192.168.0.199:8000/api/orders?customer_id=1&start_date=2026-04-01&end_date=2026-04-30&page=1",
"prev": null,
"next": null
},
"meta": {
"current_page": 1,
"from": 1,
"last_page": 1,
"links": [
{
"url": null,
"label": "&laquo; Previous",
"page": null,
"active": false
},
{
"url": "http://192.168.0.199:8000/api/orders?customer_id=1&start_date=2026-04-01&end_date=2026-04-30&page=1",
"label": "1",
"page": 1,
"active": true
},
{
"url": null,
"label": "Next &raquo;",
"page": null,
"active": false
}
],
"path": "http://192.168.0.199:8000/api/orders",
"per_page": 15,
"to": 5,
"total": 5
}
}


curl --location 'http://192.168.0.199:8000/api/orders/2' \
--header 'Accept: application/json' \
--header 'X-Authorization: Bearer 17|9ZP0dSz8LNdT5SdLmrJBVvss78Z7sa8OkuogzxMyfb3e2897'

{
"data": {
"id": 2,
"order_no": "ORD-O2ZU66LP",
"order_date": "2026-04-13T00:00:00.000000Z",
"subtotal": 6000,
"discount_type": "amount",
"discount_value": 7.11,
"discount_amount": 7.11,
"grand_total": 5992.89,
"status": "confirmed",
"note": "Test Draft",
"customer": {
"id": 1,
"name": "Rabbi",
"phone": "01863098727"
},
"salesman": {
"id": 2,
"name": "Sales Demo"
},
"items": [
{
"id": 5,
"product_id": 5,
"product_variant_id": 13,
"product_name": "Basundhara Tissue (100)",
"variant_label": "100",
"quantity": 100,
"unit_price": 60,
"line_total": 6000,
"product": {
"id": 5,
"sku": "SKU-TOILET-BT-20260413-932351-7051",
"unit": {
"id": 5,
"name": "Box",
"short_name": "box"
},
"variant": {
"id": 13,
"label": "100",
"option_values": {
"white": "100"
},
"selling_price": 60
}
}
}
],
"created_at": "2026-04-13T09:52:11.000000Z",
"updated_at": "2026-04-13T09:53:05.000000Z"
}
}

DRAFT ORDER

curl --location 'http://192.168.0.199:8000/api/orders' \
--header 'Accept: application/json' \
--header 'Content-Type: application/json' \
--header 'X-Authorization: Bearer 17|9ZP0dSz8LNdT5SdLmrJBVvss78Z7sa8OkuogzxMyfb3e2897' \
--data '{
"customer_id": 1,
"order_date": "2026-04-13",
"note": "Deliver quickly",
"discount_type": "amount",
"discount_value": 20,
"items": [
{
"product_id": 1,
"product_variant_id": 1,
"quantity": 5
},
{
"product_id": 1,
"product_variant_id": 2,
"quantity": 5
},
{
"product_id": 2,
"quantity": 2
}
]
}'

UPDATE DRAFT ORDER

curl --location --request PATCH 'http://192.168.0.199:8000/api/orders/1' \
--header 'Accept: application/json' \
--header 'Content-Type: application/json' \
--header 'X-Authorization: Bearer 17|9ZP0dSz8LNdT5SdLmrJBVvss78Z7sa8OkuogzxMyfb3e2897' \
--data '{
"customer_id": 1,
"order_date": "2026-04-14",
"note": "Updated draft with mixed lines",
"discount_type": "percentage",
"discount_value": 10,
"items": [
{
"product_id": 1,
"product_variant_id": 1,
"quantity": 4
},
{
"product_id": 1,
"product_variant_id": 2,
"quantity": 2
},
{
"product_id": 2,
"quantity": 3
}
]
}'

CONFIRM DRAFT

curl --location --request POST 'http://192.168.0.199:8000/api/orders/1/confirm' \
--header 'Accept: application/json' \
--header 'X-Authorization: Bearer 17|9ZP0dSz8LNdT5SdLmrJBVvss78Z7sa8OkuogzxMyfb3e2897'


DELETR DRAFT
curl --location --request DELETE 'http://192.168.0.199:8000/api/orders/1' \
--header 'Accept: application/json' \
--header 'X-Authorization: Bearer 17|9ZP0dSz8LNdT5SdLmrJBVvss78Z7sa8OkuogzxMyfb3e2897'
