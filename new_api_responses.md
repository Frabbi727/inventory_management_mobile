curl --location 'http://192.168.0.129:8000/api/products?q=shirt&category_id=1&page=1&sub_category_id=1' \
--header 'Accept: application/json' \
--header 'X-Authorization: Bearer 1|AmZBh9byz6MdlQeMRZrLcju1ClTSue3z2R5m6QZva02c6751'

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
"current_stock": 0,
"stock_status": "out_of_stock",
"variant_summary": {
"total_variants": 3,
"in_stock_count": 0,
"low_stock_count": 0,
"out_of_stock_count": 3
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
"first": "http://192.168.0.129:8000/api/products?category_id=1&page=1",
"last": "http://192.168.0.129:8000/api/products?category_id=1&page=1",
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
"url": "http://192.168.0.129:8000/api/products?category_id=1&page=1",
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
"path": "http://192.168.0.129:8000/api/products",
"per_page": 15,
"to": 1,
"total": 1
}
}


curl --location 'http://192.168.0.129:8000/api/products/1' \
--header 'Accept: application/json' \
--header 'X-Authorization: Bearer 1|AmZBh9byz6MdlQeMRZrLcju1ClTSue3z2R5m6QZva02c6751'

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
"current_stock": 0,
"stock_status": "out_of_stock",
"variant_summary": {
"total_variants": 3,
"in_stock_count": 0,
"low_stock_count": 0,
"out_of_stock_count": 3
},
"variant_attributes": [
{
"id": 4,
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
"is_active": true,
"current_stock": 0,
"stock_status": "out_of_stock"
},
{
"id": 2,
"combination_key": "red-256",
"combination_label": "256",
"option_values": {
"Red": "256"
},
"is_active": true,
"current_stock": 0,
"stock_status": "out_of_stock"
},
{
"id": 3,
"combination_key": "red-512",
"combination_label": "512",
"option_values": {
"Red": "512"
},
"is_active": true,
"current_stock": 0,
"stock_status": "out_of_stock"
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


curl --location 'http://192.168.0.129:8000/api/subcategories?category_id=1' \
--header 'Accept: application/json' \
--header 'X-Authorization: Bearer 1|AmZBh9byz6MdlQeMRZrLcju1ClTSue3z2R5m6QZva02c6751'


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



curl --location 'http://192.168.0.129:8000/api/inventory-manager/barcode/products/BC-20260412-274247/resolve' \
--header 'Accept: application/json' \
--header 'X-Authorization: Bearer 1|AmZBh9byz6MdlQeMRZrLcju1ClTSue3z2R5m6QZva02c6751'

{
"message": "Barcode resolved successfully.",
"exists": true,
"action": "view_or_update",
"barcode": "BC-20260412-274247",
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
"current_stock": 0,
"stock_status": "out_of_stock",
"variant_summary": {
"total_variants": 3,
"in_stock_count": 0,
"low_stock_count": 0,
"out_of_stock_count": 3
},
"variant_attributes": [
{
"id": 4,
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
"is_active": true,
"current_stock": 0,
"stock_status": "out_of_stock"
},
{
"id": 2,
"combination_key": "red-256",
"combination_label": "256",
"option_values": {
"Red": "256"
},
"is_active": true,
"current_stock": 0,
"stock_status": "out_of_stock"
},
{
"id": 3,
"combination_key": "red-512",
"combination_label": "512",
"option_values": {
"Red": "512"
},
"is_active": true,
"current_stock": 0,
"stock_status": "out_of_stock"
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


curl --location 'http://192.168.0.129:8000/api/inventory-manager/barcode/products/BC-20260412-274247' \
--header 'Accept: application/json' \
--header 'X-Authorization: Bearer 1|AmZBh9byz6MdlQeMRZrLcju1ClTSue3z2R5m6QZva02c6751'
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
"current_stock": 0,
"stock_status": "out_of_stock",
"variant_summary": {
"total_variants": 3,
"in_stock_count": 0,
"low_stock_count": 0,
"out_of_stock_count": 3
},
"variant_attributes": [
{
"id": 4,
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
"is_active": true,
"current_stock": 0,
"stock_status": "out_of_stock"
},
{
"id": 2,
"combination_key": "red-256",
"combination_label": "256",
"option_values": {
"Red": "256"
},
"is_active": true,
"current_stock": 0,
"stock_status": "out_of_stock"
},
{
"id": 3,
"combination_key": "red-512",
"combination_label": "512",
"option_values": {
"Red": "512"
},
"is_active": true,
"current_stock": 0,
"stock_status": "out_of_stock"
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


curl --location 'http://192.168.0.129:8000/api/purchases?q=PUR&page=1' \
--header 'Accept: application/json' \
--header 'X-Authorization: Bearer 1|AmZBh9byz6MdlQeMRZrLcju1ClTSue3z2R5m6QZva02c6751'

{
"data": [
{
"id": 2,
"purchase_no": "PUR-KJXNNKQJ",
"purchase_date": "2026-04-12",
"total_amount": 11000,
"note": null,
"creator": {
"id": 1,
"name": "System Admin"
},
"items_count": 2,
"created_at": "2026-04-12T14:52:44.000000Z",
"updated_at": "2026-04-12T14:52:44.000000Z"
}
],
"links": {
"first": "http://192.168.0.129:8000/api/purchases?q=PUR&page=1",
"last": "http://192.168.0.129:8000/api/purchases?q=PUR&page=1",
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
"url": "http://192.168.0.129:8000/api/purchases?q=PUR&page=1",
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
"path": "http://192.168.0.129:8000/api/purchases",
"per_page": 15,
"to": 1,
"total": 1
}
}


curl --location 'http://192.168.0.129:8000/api/purchases/2' \
--header 'Accept: application/json' \
--header 'X-Authorization: Bearer 1|AmZBh9byz6MdlQeMRZrLcju1ClTSue3z2R5m6QZva02c6751'

{
"data": {
"id": 2,
"purchase_no": "PUR-KJXNNKQJ",
"purchase_date": "2026-04-12",
"total_amount": 11000,
"note": null,
"creator": {
"id": 1,
"name": "System Admin"
},
"items_count": 2,
"items": [
{
"id": 3,
"product_id": 1,
"product_variant_id": 1,
"product_name": "Samsug S28",
"variant_label": "128",
"product_barcode": "BC-20260412-274247",
"quantity": 100,
"unit_cost": 100,
"line_total": 10000,
"product": {
"id": 1,
"name": "Samsug S28",
"sku": "SKU-MP-SS-20260412-156923-1683",
"barcode": "BC-20260412-274247",
"category": {
"id": 1,
"name": "Mobile Phone"
},
"unit": {
"id": 1,
"name": "Piece",
"short_name": "pc"
},
"variant": {
"id": 1,
"label": "128",
"option_values": {
"Red": "128"
}
}
}
},
{
"id": 4,
"product_id": 1,
"product_variant_id": 2,
"product_name": "Samsug S28",
"variant_label": "256",
"product_barcode": "BC-20260412-274247",
"quantity": 10,
"unit_cost": 100,
"line_total": 1000,
"product": {
"id": 1,
"name": "Samsug S28",
"sku": "SKU-MP-SS-20260412-156923-1683",
"barcode": "BC-20260412-274247",
"category": {
"id": 1,
"name": "Mobile Phone"
},
"unit": {
"id": 1,
"name": "Piece",
"short_name": "pc"
},
"variant": {
"id": 2,
"label": "256",
"option_values": {
"Red": "256"
}
}
}
}
],
"created_at": "2026-04-12T14:52:44.000000Z",
"updated_at": "2026-04-12T14:52:44.000000Z"
}
}