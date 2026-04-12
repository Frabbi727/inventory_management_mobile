curl --location 'http://192.168.0.129:8000/api/products' \
--header 'Accept: application/json' \
--header 'Content-Type: application/json' \
--header 'X-Authorization: Bearer 1|AmZBh9byz6MdlQeMRZrLcju1ClTSue3z2R5m6QZva02c6751' \
--data '{
"name": "Mobile Simple Product",
"sku": "MOBILE-SIMPLE-001",
"barcode": "BC-20260412-274247",
"category_id": 1,
"subcategory_id": 1,
"unit_id": 1,
"purchase_price": 120.00,
"selling_price": 150.00,
"minimum_stock_alert": 10,
"status": "active"
}'

curl --location --request PUT 'http://192.168.0.129:8000/api/products/1' \
--header 'Accept: application/json' \
--header 'Content-Type: application/json' \
--header 'X-Authorization: Bearer 1|AmZBh9byz6MdlQeMRZrLcju1ClTSue3z2R5m6QZva02c6751' \
--data '{
"name": "Mobile Updated Product",
"sku": "MOBILE-UPDATED-001",
"barcode": "BC-20260412-274247",
"category_id": 1,
"subcategory_id": 1,
"unit_id": 1,
"purchase_price": 130.00,
"selling_price": 165.00,
"minimum_stock_alert": 8,
"status": "active"
}'

curl --location 'http://192.168.0.129:8000/api/products' \
--header 'Accept: application/json' \
--header 'Content-Type: application/json' \
--header 'X-Authorization: Bearer 1|AmZBh9byz6MdlQeMRZrLcju1ClTSue3z2R5m6QZva02c6751' \
--data '{
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
}'


curl --location 'http://192.168.0.129:8000/api/purchases' \
--header 'Accept: application/json' \
--header 'Content-Type: application/json' \
--header 'X-Authorization: Bearer 1|AmZBh9byz6MdlQeMRZrLcju1ClTSue3z2R5m6QZva02c6751' \
--data '{
"purchase_date": "2026-04-12",
"note": "Simple purchase from mobile",
"items": [
{
"product_id": 1,
"quantity": 10,
"unit_cost": 90.00
}
]
}'

curl --location 'http://192.168.0.129:8000/api/purchases' \
--header 'Accept: application/json' \
--header 'Content-Type: application/json' \
--header 'X-Authorization: Bearer 1|AmZBh9byz6MdlQeMRZrLcju1ClTSue3z2R5m6QZva02c6751' \
--data '{
"purchase_date": "2026-04-12",
"note": "Variant purchase from mobile",
"items": [
{
"product_id": 1,
"product_variant_id": 1,
"quantity": 5,
"unit_cost": 220.00
}
]
}'


curl --location --request PUT 'http://192.168.0.129:8000/api/purchases/2' \
--header 'Accept: application/json' \
--header 'Content-Type: application/json' \
--header 'X-Authorization: Bearer 1|AmZBh9byz6MdlQeMRZrLcju1ClTSue3z2R5m6QZva02c6751' \
--data '{
"purchase_date": "2026-04-12",
"note": "Updated purchase from mobile",
"items": [
{
"product_id": 1,
"quantity": 12,
"unit_cost": 95.00
}
]
}'


curl --location 'http://192.168.0.129:8000/api/inventory-manager/barcode/products' \
--header 'Accept: application/json' \
--header 'Content-Type: application/json' \
--header 'X-Authorization: Bearer 1|AmZBh9byz6MdlQeMRZrLcju1ClTSue3z2R5m6QZva02c6751' \
--data '{
"name": "Barcode Created Product",
"sku": "BARCODE-PRODUCT-001",
"barcode": "BC-20260412-274247",
"category_id": 1,
"subcategory_id": 1,
"unit_id": 1,
"purchase_price": 110.00,
"selling_price": 145.00,
"minimum_stock_alert": 6,
"status": "active"
}'


curl --location --request PUT 'http://192.168.0.129:8000/api/inventory-manager/barcode/products/BC-20260412-274247' \
--header 'Accept: application/json' \
--header 'Content-Type: application/json' \
--header 'X-Authorization: Bearer 1|AmZBh9byz6MdlQeMRZrLcju1ClTSue3z2R5m6QZva02c6751' \
--data '{
"name": "Barcode Updated Product",
"sku": "BARCODE-PRODUCT-001",
"barcode": "BC-20260412-274247",
"category_id": 1,
"subcategory_id": 1,
"unit_id": 1,
"purchase_price": 115.00,
"selling_price": 150.00,
"minimum_stock_alert": 7,
"status": "active"
}'