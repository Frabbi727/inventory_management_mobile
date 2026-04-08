# Mobile Salesman API Documentation

## Inventory + Sales + Order Management System

### Flutter + Laravel API Reference with cURL, Response Samples, and `json_serializable` Model Plan

---

## 1. Overview

This document combines the confirmed API contracts for the Flutter mobile salesman app into one reference file.

It includes:
- API groups
- cURL examples
- response examples
- request/response model planning
- shared pagination structure
- `json_serializable` notes for Flutter

### Base URL

```text
https://ordermanage.b2bhaat.com
```

### API Prefix

```text
/api
```

### Protected Header Format

```http
Accept: application/json
Content-Type: application/json
X-Authorization: Bearer {token}
```

### Important Note

Protected APIs currently use `X-Authorization` instead of the standard `Authorization` header.

---

## 2. Flutter `json_serializable` Setup

### pubspec.yaml

```yaml
dependencies:
  json_annotation: ^4.8.1

dev_dependencies:
  build_runner: ^2.4.6
  json_serializable: ^6.7.1
```

### Generate command

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

---

## 3. Shared Pagination Models

These models should be reused for all paginated APIs such as products, customers, and orders.

### PaginationLinksModel

```dart
@JsonSerializable()
class PaginationLinksModel {
  final String? first;
  final String? last;
  final String? prev;
  final String? next;

  const PaginationLinksModel({
    this.first,
    this.last,
    this.prev,
    this.next,
  });

  factory PaginationLinksModel.fromJson(Map<String, dynamic> json) =>
      _$PaginationLinksModelFromJson(json);

  Map<String, dynamic> toJson() => _$PaginationLinksModelToJson(this);
}
```

### PaginationMetaLinkModel

```dart
@JsonSerializable()
class PaginationMetaLinkModel {
  final String? url;
  final String label;
  final int? page;
  final bool active;

  const PaginationMetaLinkModel({
    this.url,
    required this.label,
    this.page,
    required this.active,
  });

  factory PaginationMetaLinkModel.fromJson(Map<String, dynamic> json) =>
      _$PaginationMetaLinkModelFromJson(json);

  Map<String, dynamic> toJson() => _$PaginationMetaLinkModelToJson(this);
}
```

### PaginationMetaModel

```dart
@JsonSerializable(explicitToJson: true)
class PaginationMetaModel {
  @JsonKey(name: 'current_page')
  final int currentPage;

  final int? from;

  @JsonKey(name: 'last_page')
  final int lastPage;

  final List<PaginationMetaLinkModel> links;
  final String path;

  @JsonKey(name: 'per_page')
  final int perPage;

  final int? to;
  final int total;

  const PaginationMetaModel({
    required this.currentPage,
    this.from,
    required this.lastPage,
    required this.links,
    required this.path,
    required this.perPage,
    this.to,
    required this.total,
  });

  factory PaginationMetaModel.fromJson(Map<String, dynamic> json) =>
      _$PaginationMetaModelFromJson(json);

  Map<String, dynamic> toJson() => _$PaginationMetaModelToJson(this);
}
```

---

## 4. Auth APIs

## 4.1 Login

### Endpoint

```text
POST /api/login
```

### cURL

```bash
curl --location 'https://ordermanage.b2bhaat.com/api/login' \
--header 'Accept: application/json' \
--header 'Content-Type: application/json' \
--data-raw '{
  "login": "salesman@example.com",
  "password": "password",
  "device_name": "mobile-app"
}'
```

### Response

```json
{
  "message": "Login successful.",
  "data": {
    "token": "11|H6m9ZRmYD53mJdrKyLvNbu7hszATZyVyu53W1NwMd73d1e53",
    "token_type": "Bearer",
    "user": {
      "id": 2,
      "name": "Sales Demo",
      "email": "salesman@example.com",
      "phone": "+8801700000002",
      "status": "active",
      "role": {
        "id": 2,
        "name": "Salesman",
        "slug": "salesman"
      },
      "email_verified_at": null,
      "created_at": "2026-04-07T12:13:01.000000Z",
      "updated_at": "2026-04-07T13:50:38.000000Z"
    }
  }
}
```

### Models

```dart
@JsonSerializable()
class RoleModel {
  final int id;
  final String name;
  final String slug;

  const RoleModel({
    required this.id,
    required this.name,
    required this.slug,
  });

  factory RoleModel.fromJson(Map<String, dynamic> json) =>
      _$RoleModelFromJson(json);

  Map<String, dynamic> toJson() => _$RoleModelToJson(this);
}

@JsonSerializable(explicitToJson: true)
class UserModel {
  final int id;
  final String name;
  final String email;
  final String phone;
  final String status;
  final RoleModel role;

  @JsonKey(name: 'email_verified_at')
  final String? emailVerifiedAt;

  @JsonKey(name: 'created_at')
  final String createdAt;

  @JsonKey(name: 'updated_at')
  final String updatedAt;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.status,
    required this.role,
    this.emailVerifiedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);

  Map<String, dynamic> toJson() => _$UserModelToJson(this);
}

@JsonSerializable(explicitToJson: true)
class LoginDataModel {
  final String token;

  @JsonKey(name: 'token_type')
  final String tokenType;

  final UserModel user;

  const LoginDataModel({
    required this.token,
    required this.tokenType,
    required this.user,
  });

  factory LoginDataModel.fromJson(Map<String, dynamic> json) =>
      _$LoginDataModelFromJson(json);

  Map<String, dynamic> toJson() => _$LoginDataModelToJson(this);
}

@JsonSerializable(explicitToJson: true)
class LoginResponseModel {
  final String message;
  final LoginDataModel data;

  const LoginResponseModel({
    required this.message,
    required this.data,
  });

  factory LoginResponseModel.fromJson(Map<String, dynamic> json) =>
      _$LoginResponseModelFromJson(json);

  Map<String, dynamic> toJson() => _$LoginResponseModelToJson(this);
}
```

---

## 4.2 Logout

### Endpoint

```text
POST /api/logout
```

### cURL

```bash
curl --location --request POST 'https://ordermanage.b2bhaat.com/api/logout' \
--header 'Accept: application/json' \
--header 'X-Authorization: Bearer {token}'
```

### Response

```json
{
  "message": "Logout successful."
}
```

### Model

```dart
@JsonSerializable()
class LogoutResponseModel {
  final String message;

  const LogoutResponseModel({required this.message});

  factory LogoutResponseModel.fromJson(Map<String, dynamic> json) =>
      _$LogoutResponseModelFromJson(json);

  Map<String, dynamic> toJson() => _$LogoutResponseModelToJson(this);
}
```

---

## 4.3 Me / Profile

### Endpoint

```text
GET /api/me
```

### cURL

```bash
curl --location 'https://ordermanage.b2bhaat.com/api/me' \
--header 'Accept: application/json' \
--header 'X-Authorization: Bearer {token}'
```

### Response

```json
{
  "data": {
    "id": 2,
    "name": "Sales Demo",
    "email": "salesman@example.com",
    "phone": "+8801700000002",
    "status": "active",
    "role": {
      "id": 2,
      "name": "Salesman",
      "slug": "salesman"
    },
    "email_verified_at": null,
    "created_at": "2026-04-07T12:13:01.000000Z",
    "updated_at": "2026-04-07T13:50:38.000000Z"
  }
}
```

### Model

```dart
@JsonSerializable(explicitToJson: true)
class ProfileResponseModel {
  final UserModel data;

  const ProfileResponseModel({required this.data});

  factory ProfileResponseModel.fromJson(Map<String, dynamic> json) =>
      _$ProfileResponseModelFromJson(json);

  Map<String, dynamic> toJson() => _$ProfileResponseModelToJson(this);
}
```

---

## 5. Product APIs

## 5.1 Product List

### Endpoint

```text
GET /api/products
```

### Example Query

```text
/api/products?q=milk&status=active&page=1
```

### cURL

```bash
curl --location 'https://ordermanage.b2bhaat.com/api/products?q=milk&status=active&page=1' \
--header 'Accept: application/json' \
--header 'X-Authorization: Bearer {token}'
```

### Response

```json
{
  "data": [
    {
      "id": 2,
      "name": "Fresh Milk 500ml",
      "sku": "PRD-MILK-500",
      "purchase_price": 42,
      "selling_price": 52,
      "minimum_stock_alert": 18,
      "status": "active",
      "current_stock": 0,
      "category": {
        "id": 2,
        "name": "Dairy"
      },
      "unit": {
        "id": 1,
        "name": "Piece",
        "short_name": "pc"
      },
      "created_at": "2026-04-07T13:50:38.000000Z",
      "updated_at": "2026-04-07T13:50:38.000000Z"
    }
  ],
  "links": {
    "first": "https://ordermanage.b2bhaat.com/api/products?q=milk&status=active&page=1",
    "last": "https://ordermanage.b2bhaat.com/api/products?q=milk&status=active&page=1",
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
        "url": "https://ordermanage.b2bhaat.com/api/products?q=milk&status=active&page=1",
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
    "path": "https://ordermanage.b2bhaat.com/api/products",
    "per_page": 15,
    "to": 1,
    "total": 1
  }
}
```

### Models

```dart
@JsonSerializable()
class ProductCategoryModel {
  final int id;
  final String name;

  const ProductCategoryModel({
    required this.id,
    required this.name,
  });

  factory ProductCategoryModel.fromJson(Map<String, dynamic> json) =>
      _$ProductCategoryModelFromJson(json);

  Map<String, dynamic> toJson() => _$ProductCategoryModelToJson(this);
}

@JsonSerializable()
class ProductUnitModel {
  final int id;
  final String name;

  @JsonKey(name: 'short_name')
  final String shortName;

  const ProductUnitModel({
    required this.id,
    required this.name,
    required this.shortName,
  });

  factory ProductUnitModel.fromJson(Map<String, dynamic> json) =>
      _$ProductUnitModelFromJson(json);

  Map<String, dynamic> toJson() => _$ProductUnitModelToJson(this);
}

@JsonSerializable(explicitToJson: true)
class ProductModel {
  final int id;
  final String name;
  final String sku;

  @JsonKey(name: 'purchase_price')
  final num? purchasePrice;

  @JsonKey(name: 'selling_price')
  final num sellingPrice;

  @JsonKey(name: 'minimum_stock_alert')
  final int minimumStockAlert;

  final String status;

  @JsonKey(name: 'current_stock')
  final int currentStock;

  final ProductCategoryModel category;
  final ProductUnitModel unit;

  @JsonKey(name: 'created_at')
  final String createdAt;

  @JsonKey(name: 'updated_at')
  final String updatedAt;

  const ProductModel({
    required this.id,
    required this.name,
    required this.sku,
    this.purchasePrice,
    required this.sellingPrice,
    required this.minimumStockAlert,
    required this.status,
    required this.currentStock,
    required this.category,
    required this.unit,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) =>
      _$ProductModelFromJson(json);

  Map<String, dynamic> toJson() => _$ProductModelToJson(this);
}

@JsonSerializable(explicitToJson: true)
class ProductListResponseModel {
  final List<ProductModel> data;
  final PaginationLinksModel links;
  final PaginationMetaModel meta;

  const ProductListResponseModel({
    required this.data,
    required this.links,
    required this.meta,
  });

  factory ProductListResponseModel.fromJson(Map<String, dynamic> json) =>
      _$ProductListResponseModelFromJson(json);

  Map<String, dynamic> toJson() => _$ProductListResponseModelToJson(this);
}
```

---

## 5.2 Product Details

### Endpoint

```text
GET /api/products/{id}
```

### cURL

```bash
curl --location 'https://ordermanage.b2bhaat.com/api/products/1' \
--header 'Accept: application/json' \
--header 'X-Authorization: Bearer {token}'
```

### Response

```json
{
  "data": {
    "id": 1,
    "name": "Mineral Water 1L",
    "sku": "PRD-WATER-1L",
    "purchase_price": 16,
    "selling_price": 22,
    "minimum_stock_alert": 24,
    "status": "active",
    "current_stock": 0,
    "category": {
      "id": 1,
      "name": "Beverages"
    },
    "unit": {
      "id": 3,
      "name": "Liter",
      "short_name": "ltr"
    },
    "created_at": "2026-04-07T13:50:38.000000Z",
    "updated_at": "2026-04-07T14:05:22.000000Z"
  }
}
```

### Model

```dart
@JsonSerializable(explicitToJson: true)
class ProductDetailsResponseModel {
  final ProductModel data;

  const ProductDetailsResponseModel({required this.data});

  factory ProductDetailsResponseModel.fromJson(Map<String, dynamic> json) =>
      _$ProductDetailsResponseModelFromJson(json);

  Map<String, dynamic> toJson() => _$ProductDetailsResponseModelToJson(this);
}
```

---

## 6. Customer APIs

## 6.1 Customer List / Search

### Endpoint

```text
GET /api/customers
```

### Example Query

```text
/api/customers?q=Rahman&phone=01710001001&page=1
```

### cURL

```bash
curl --location 'https://ordermanage.b2bhaat.com/api/customers?q=Rahman&phone=01710001001&page=1' \
--header 'Accept: application/json' \
--header 'X-Authorization: Bearer {token}'
```

### Response

```json
{
  "data": [
    {
      "id": 1,
      "name": "Rahman Store",
      "phone": "+8801710001001",
      "address": "12 Lake Circus, Dhaka",
      "area": "Dhanmondi",
      "created_by": {
        "id": 2,
        "name": "Sales Demo"
      },
      "created_at": "2026-04-07T13:50:38.000000Z",
      "updated_at": "2026-04-07T13:50:38.000000Z"
    }
  ],
  "links": {
    "first": "https://ordermanage.b2bhaat.com/api/customers?q=Rahman&phone=01710001001&page=1",
    "last": "https://ordermanage.b2bhaat.com/api/customers?q=Rahman&phone=01710001001&page=1",
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
        "url": "https://ordermanage.b2bhaat.com/api/customers?q=Rahman&phone=01710001001&page=1",
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
    "path": "https://ordermanage.b2bhaat.com/api/customers",
    "per_page": 15,
    "to": 1,
    "total": 1
  }
}
```

### Models

```dart
@JsonSerializable()
class CustomerCreatedByModel {
  final int id;
  final String name;

  const CustomerCreatedByModel({
    required this.id,
    required this.name,
  });

  factory CustomerCreatedByModel.fromJson(Map<String, dynamic> json) =>
      _$CustomerCreatedByModelFromJson(json);

  Map<String, dynamic> toJson() => _$CustomerCreatedByModelToJson(this);
}

@JsonSerializable(explicitToJson: true)
class CustomerModel {
  final int id;
  final String name;
  final String phone;
  final String address;
  final String? area;

  @JsonKey(name: 'created_by')
  final CustomerCreatedByModel createdBy;

  @JsonKey(name: 'created_at')
  final String createdAt;

  @JsonKey(name: 'updated_at')
  final String updatedAt;

  const CustomerModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.address,
    this.area,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CustomerModel.fromJson(Map<String, dynamic> json) =>
      _$CustomerModelFromJson(json);

  Map<String, dynamic> toJson() => _$CustomerModelToJson(this);
}

@JsonSerializable(explicitToJson: true)
class CustomerListResponseModel {
  final List<CustomerModel> data;
  final PaginationLinksModel links;
  final PaginationMetaModel meta;

  const CustomerListResponseModel({
    required this.data,
    required this.links,
    required this.meta,
  });

  factory CustomerListResponseModel.fromJson(Map<String, dynamic> json) =>
      _$CustomerListResponseModelFromJson(json);

  Map<String, dynamic> toJson() => _$CustomerListResponseModelToJson(this);
}
```

---

## 6.2 Customer Details

### Endpoint

```text
GET /api/customers/{id}
```

### cURL

```bash
curl --location 'https://ordermanage.b2bhaat.com/api/customers/1' \
--header 'Accept: application/json' \
--header 'X-Authorization: Bearer {token}'
```

### Response

```json
{
  "data": {
    "id": 1,
    "name": "Rahman Store",
    "phone": "+8801710001001",
    "address": "12 Lake Circus, Dhaka",
    "area": "Dhanmondi",
    "created_by": {
      "id": 2,
      "name": "Sales Demo"
    },
    "created_at": "2026-04-07T13:50:38.000000Z",
    "updated_at": "2026-04-07T13:50:38.000000Z"
  }
}
```

### Model

```dart
@JsonSerializable(explicitToJson: true)
class CustomerDetailsResponseModel {
  final CustomerModel data;

  const CustomerDetailsResponseModel({required this.data});

  factory CustomerDetailsResponseModel.fromJson(Map<String, dynamic> json) =>
      _$CustomerDetailsResponseModelFromJson(json);

  Map<String, dynamic> toJson() => _$CustomerDetailsResponseModelToJson(this);
}
```

---

## 6.3 Create Customer

### Endpoint

```text
POST /api/customers
```

### cURL

```bash
curl --location 'https://ordermanage.b2bhaat.com/api/customers' \
--header 'Accept: application/json' \
--header 'Content-Type: application/json' \
--header 'X-Authorization: Bearer {token}' \
--data '{
  "name": "Customer Name",
  "phone": "01700000000",
  "address": "Full address",
  "area": "Mirpur"
}'
```

### Request Model

```dart
@JsonSerializable()
class CreateCustomerRequestModel {
  final String name;
  final String phone;
  final String address;
  final String? area;

  const CreateCustomerRequestModel({
    required this.name,
    required this.phone,
    required this.address,
    this.area,
  });

  factory CreateCustomerRequestModel.fromJson(Map<String, dynamic> json) =>
      _$CreateCustomerRequestModelFromJson(json);

  Map<String, dynamic> toJson() => _$CreateCustomerRequestModelToJson(this);
}
```

### Expected Response Shape

```json
{
  "message": "Customer created successfully.",
  "data": {
    "id": 5,
    "name": "Customer Name",
    "phone": "01700000000",
    "address": "Full address",
    "area": "Mirpur",
    "created_by": {
      "id": 2,
      "name": "Sales Demo"
    },
    "created_at": "2026-04-07T13:50:38.000000Z",
    "updated_at": "2026-04-07T13:50:38.000000Z"
  }
}
```

### Response Model

```dart
@JsonSerializable(explicitToJson: true)
class CreateCustomerResponseModel {
  final String message;
  final CustomerModel data;

  const CreateCustomerResponseModel({
    required this.message,
    required this.data,
  });

  factory CreateCustomerResponseModel.fromJson(Map<String, dynamic> json) =>
      _$CreateCustomerResponseModelFromJson(json);

  Map<String, dynamic> toJson() => _$CreateCustomerResponseModelToJson(this);
}
```

---

## 7. Order APIs

## 7.1 Order List

### Endpoint

```text
GET /api/orders
```

### Example Query

```text
/api/orders?status=confirmed&customer_id=2&start_date=2026-04-01&end_date=2026-04-30&page=1
```

### cURL

```bash
curl --location 'https://ordermanage.b2bhaat.com/api/orders?status=confirmed&customer_id=2&start_date=2026-04-01&end_date=2026-04-30&page=1' \
--header 'Accept: application/json' \
--header 'X-Authorization: Bearer {token}'
```

### Response

```json
{
  "data": [
    {
      "id": 2,
      "order_no": "ORD-NHPXCXHK",
      "order_date": "2026-04-07T00:00:00.000000Z",
      "subtotal": 85,
      "discount_type": null,
      "discount_value": 10,
      "discount_amount": 0,
      "grand_total": 85,
      "status": "confirmed",
      "note": "discount",
      "customer": {
        "id": 2,
        "name": "Bismillah Traders",
        "phone": "+8801710001002"
      },
      "salesman": {
        "id": 2,
        "name": "Sales Demo"
      },
      "items": [
        {
          "id": 2,
          "product_id": "5",
          "product_name": "Dishwashing Liquid 500ml",
          "quantity": 1,
          "unit_price": 85,
          "line_total": 85
        }
      ],
      "created_at": "2026-04-07T14:17:22.000000Z",
      "updated_at": "2026-04-07T14:17:22.000000Z"
    }
  ],
  "links": {
    "first": "https://ordermanage.b2bhaat.com/api/orders?status=confirmed&customer_id=2&start_date=2026-04-01&end_date=2026-04-30&page=1",
    "last": "https://ordermanage.b2bhaat.com/api/orders?status=confirmed&customer_id=2&start_date=2026-04-01&end_date=2026-04-30&page=1",
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
        "url": "https://ordermanage.b2bhaat.com/api/orders?status=confirmed&customer_id=2&start_date=2026-04-01&end_date=2026-04-30&page=1",
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
    "path": "https://ordermanage.b2bhaat.com/api/orders",
    "per_page": 15,
    "to": 1,
    "total": 1
  }
}
```

### Models

```dart
int _intFromAny(dynamic value) => int.parse(value.toString());

@JsonSerializable()
class OrderCustomerModel {
  final int id;
  final String name;
  final String phone;

  const OrderCustomerModel({
    required this.id,
    required this.name,
    required this.phone,
  });

  factory OrderCustomerModel.fromJson(Map<String, dynamic> json) =>
      _$OrderCustomerModelFromJson(json);

  Map<String, dynamic> toJson() => _$OrderCustomerModelToJson(this);
}

@JsonSerializable()
class OrderSalesmanModel {
  final int id;
  final String name;

  const OrderSalesmanModel({
    required this.id,
    required this.name,
  });

  factory OrderSalesmanModel.fromJson(Map<String, dynamic> json) =>
      _$OrderSalesmanModelFromJson(json);

  Map<String, dynamic> toJson() => _$OrderSalesmanModelToJson(this);
}

@JsonSerializable()
class OrderItemModel {
  final int id;

  @JsonKey(name: 'product_id', fromJson: _intFromAny)
  final int productId;

  @JsonKey(name: 'product_name')
  final String productName;

  final int quantity;

  @JsonKey(name: 'unit_price')
  final num unitPrice;

  @JsonKey(name: 'line_total')
  final num lineTotal;

  const OrderItemModel({
    required this.id,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.lineTotal,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) =>
      _$OrderItemModelFromJson(json);

  Map<String, dynamic> toJson() => _$OrderItemModelToJson(this);
}

@JsonSerializable(explicitToJson: true)
class OrderModel {
  final int id;

  @JsonKey(name: 'order_no')
  final String orderNo;

  @JsonKey(name: 'order_date')
  final String orderDate;

  final num subtotal;

  @JsonKey(name: 'discount_type')
  final String? discountType;

  @JsonKey(name: 'discount_value')
  final num? discountValue;

  @JsonKey(name: 'discount_amount')
  final num discountAmount;

  @JsonKey(name: 'grand_total')
  final num grandTotal;

  final String status;
  final String? note;
  final OrderCustomerModel customer;
  final OrderSalesmanModel salesman;
  final List<OrderItemModel> items;

  @JsonKey(name: 'created_at')
  final String createdAt;

  @JsonKey(name: 'updated_at')
  final String updatedAt;

  const OrderModel({
    required this.id,
    required this.orderNo,
    required this.orderDate,
    required this.subtotal,
    this.discountType,
    this.discountValue,
    required this.discountAmount,
    required this.grandTotal,
    required this.status,
    this.note,
    required this.customer,
    required this.salesman,
    required this.items,
    required this.createdAt,
    required this.updatedAt,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) =>
      _$OrderModelFromJson(json);

  Map<String, dynamic> toJson() => _$OrderModelToJson(this);
}

@JsonSerializable(explicitToJson: true)
class OrderListResponseModel {
  final List<OrderModel> data;
  final PaginationLinksModel links;
  final PaginationMetaModel meta;

  const OrderListResponseModel({
    required this.data,
    required this.links,
    required this.meta,
  });

  factory OrderListResponseModel.fromJson(Map<String, dynamic> json) =>
      _$OrderListResponseModelFromJson(json);

  Map<String, dynamic> toJson() => _$OrderListResponseModelToJson(this);
}
```

---

## 7.2 Create Order

### Endpoint

```text
POST /api/orders
```

### cURL

```bash
curl --location 'https://ordermanage.b2bhaat.com/api/orders' \
--header 'Accept: application/json' \
--header 'Content-Type: application/json' \
--header 'X-Authorization: Bearer {token}' \
--data '{
  "customer_id": 2,
  "order_date": "2026-04-08",
  "note": "Deliver quickly",
  "discount_type": "amount",
  "discount_value": 100,
  "items": [
    {
      "product_id": 1,
      "quantity": 2
    }
  ]
}'
```

### Request Models

```dart
@JsonSerializable()
class OrderItemRequestModel {
  @JsonKey(name: 'product_id')
  final int productId;

  final int quantity;

  const OrderItemRequestModel({
    required this.productId,
    required this.quantity,
  });

  factory OrderItemRequestModel.fromJson(Map<String, dynamic> json) =>
      _$OrderItemRequestModelFromJson(json);

  Map<String, dynamic> toJson() => _$OrderItemRequestModelToJson(this);
}

@JsonSerializable(explicitToJson: true)
class CreateOrderRequestModel {
  @JsonKey(name: 'customer_id')
  final int customerId;

  @JsonKey(name: 'order_date')
  final String orderDate;

  final String? note;

  @JsonKey(name: 'discount_type')
  final String? discountType;

  @JsonKey(name: 'discount_value')
  final num? discountValue;

  final List<OrderItemRequestModel> items;

  const CreateOrderRequestModel({
    required this.customerId,
    required this.orderDate,
    this.note,
    this.discountType,
    this.discountValue,
    required this.items,
  });

  factory CreateOrderRequestModel.fromJson(Map<String, dynamic> json) =>
      _$CreateOrderRequestModelFromJson(json);

  Map<String, dynamic> toJson() => _$CreateOrderRequestModelToJson(this);
}
```

### Expected Response Shape

```json
{
  "message": "Order created successfully.",
  "data": {
    "id": 99,
    "order_no": "ORD-ABC12345",
    "order_date": "2026-04-08",
    "subtotal": 1500,
    "discount_type": "amount",
    "discount_value": 100,
    "discount_amount": 100,
    "grand_total": 1400,
    "status": "confirmed",
    "note": "Deliver quickly",
    "customer": {
      "id": 5,
      "name": "Customer Name",
      "phone": "01700000000"
    },
    "salesman": {
      "id": 2,
      "name": "Sales Demo"
    },
    "items": []
  }
}
```

### Response Model

```dart
@JsonSerializable(explicitToJson: true)
class CreateOrderResponseModel {
  final String message;
  final OrderModel data;

  const CreateOrderResponseModel({
    required this.message,
    required this.data,
  });

  factory CreateOrderResponseModel.fromJson(Map<String, dynamic> json) =>
      _$CreateOrderResponseModelFromJson(json);

  Map<String, dynamic> toJson() => _$CreateOrderResponseModelToJson(this);
}
```

---

## 7.3 Order Details

### Endpoint

```text
GET /api/orders/{id}
```

### cURL

```bash
curl --location 'https://ordermanage.b2bhaat.com/api/orders/6' \
--header 'Accept: application/json' \
--header 'X-Authorization: Bearer {token}'
```

### Response Shape

```json
{
  "data": {
    "id": 99,
    "order_no": "ORD-ABC12345",
    "order_date": "2026-04-08",
    "subtotal": 1500,
    "discount_type": "amount",
    "discount_value": 100,
    "discount_amount": 100,
    "grand_total": 1400,
    "status": "confirmed",
    "note": "Deliver quickly",
    "customer": {
      "id": 5,
      "name": "Customer Name",
      "phone": "01700000000"
    },
    "salesman": {
      "id": 2,
      "name": "Sales Demo"
    },
    "items": [
      {
        "id": 1,
        "product_id": 10,
        "product_name": "Product Name",
        "quantity": 2,
        "unit_price": 100,
        "line_total": 200
      }
    ]
  }
}
```

### Model

```dart
@JsonSerializable(explicitToJson: true)
class OrderDetailsResponseModel {
  final OrderModel data;

  const OrderDetailsResponseModel({required this.data});

  factory OrderDetailsResponseModel.fromJson(Map<String, dynamic> json) =>
      _$OrderDetailsResponseModelFromJson(json);

  Map<String, dynamic> toJson() => _$OrderDetailsResponseModelToJson(this);
}
```

---

## 8. Model Inventory by File Suggestion

```text
lib/
 ┣ features/
 ┃ ┣ auth/
 ┃ ┃ ┗ data/models/
 ┃ ┃   ┣ login_response_model.dart
 ┃ ┃   ┣ logout_response_model.dart
 ┃ ┃   ┣ profile_response_model.dart
 ┃ ┃   ┣ login_data_model.dart
 ┃ ┃   ┣ user_model.dart
 ┃ ┃   ┗ role_model.dart
 ┃ ┣ products/
 ┃ ┃ ┗ data/models/
 ┃ ┃   ┣ product_model.dart
 ┃ ┃   ┣ product_category_model.dart
 ┃ ┃   ┣ product_unit_model.dart
 ┃ ┃   ┣ product_list_response_model.dart
 ┃ ┃   ┗ product_details_response_model.dart
 ┃ ┣ customers/
 ┃ ┃ ┗ data/models/
 ┃ ┃   ┣ customer_model.dart
 ┃ ┃   ┣ customer_created_by_model.dart
 ┃ ┃   ┣ customer_list_response_model.dart
 ┃ ┃   ┣ customer_details_response_model.dart
 ┃ ┃   ┣ create_customer_request_model.dart
 ┃ ┃   ┗ create_customer_response_model.dart
 ┃ ┣ orders/
 ┃ ┃ ┗ data/models/
 ┃ ┃   ┣ order_model.dart
 ┃ ┃   ┣ order_item_model.dart
 ┃ ┃   ┣ order_customer_model.dart
 ┃ ┃   ┣ order_salesman_model.dart
 ┃ ┃   ┣ order_list_response_model.dart
 ┃ ┃   ┣ order_details_response_model.dart
 ┃ ┃   ┣ order_item_request_model.dart
 ┃ ┃   ┣ create_order_request_model.dart
 ┃ ┃   ┗ create_order_response_model.dart
 ┣ shared/
 ┃ ┗ models/
 ┃   ┣ pagination_links_model.dart
 ┃   ┣ pagination_meta_model.dart
 ┃   ┗ pagination_meta_link_model.dart
```

---

## 9. Important Implementation Rules

1. Mobile app should treat totals as preview only.
2. Backend is the final source of truth for subtotal, discount, and grand total.
3. Do not send authoritative pricing fields in create order payload.
4. Reuse shared pagination models for all paginated endpoints.
5. Keep nullable fields safe, especially `discount_type`, `discount_value`, `email_verified_at`, `area`, `note`, and pagination URLs.
6. Parse `product_id` defensively because one order API returned it as a string.

---

## 10. Final Summary

This single file can be used as:
- API contract reference
- Flutter model planning document
- backend/mobile integration checklist
- `json_serializable` implementation guide

The confirmed modules covered in this document are:
- Auth
- Products
- Customers
- Orders

