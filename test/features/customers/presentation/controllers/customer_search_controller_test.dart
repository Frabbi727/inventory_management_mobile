import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:inventory_management_sales/core/models/pagination_links_model.dart';
import 'package:inventory_management_sales/core/models/pagination_meta_model.dart';
import 'package:inventory_management_sales/core/network/api_client.dart';
import 'package:inventory_management_sales/core/storage/token_storage.dart';
import 'package:inventory_management_sales/features/customers/data/models/customer_list_response_model.dart';
import 'package:inventory_management_sales/features/customers/data/models/customer_model.dart';
import 'package:inventory_management_sales/features/customers/data/repositories/customer_repository.dart';
import 'package:inventory_management_sales/features/customers/presentation/controllers/customer_search_controller.dart';

class FakeCustomerRepository extends CustomerRepository {
  FakeCustomerRepository()
    : super(
        apiClient: ApiClient(
          httpClient: MockClient((_) async => http.Response('{}', 200)),
        ),
        tokenStorage: TokenStorage(),
      );

  final List<(int page, String? query)> calls = [];

  @override
  Future<CustomerListResponseModel> fetchCustomers({
    int page = 1,
    String? query,
  }) async {
    calls.add((page, query));
    return CustomerListResponseModel(
      data: [
        CustomerModel(
          id: page,
          name: query == null ? 'Customer $page' : 'Search $query',
          phone: '01700000000',
          address: 'Dhaka',
        ),
      ],
      links: PaginationLinksModel(next: page < 2 ? 'next' : null),
      meta: PaginationMetaModel(currentPage: page, lastPage: 2),
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'customer search debounces and resets paging for query changes',
    () async {
      final repository = FakeCustomerRepository();
      final controller = CustomerSearchController(
        customerRepository: repository,
      );

      controller.onInit();
      expect(repository.calls, [(1, null)]);

      controller.onSearchChanged('ra');
      await Future<void>.delayed(const Duration(milliseconds: 500));
      expect(repository.calls, [(1, null), (1, 'ra')]);
      expect(controller.customers.first.name, 'Search ra');

      await controller.fetchCustomers(reset: false);
      expect(repository.calls, [(1, null), (1, 'ra'), (2, 'ra')]);

      controller.onSearchChanged('rah');
      await Future<void>.delayed(const Duration(milliseconds: 500));
      expect(repository.calls, [(1, null), (1, 'ra'), (2, 'ra'), (1, 'rah')]);
      expect(controller.customers.first.name, 'Search rah');

      controller.clearSearch();
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(repository.calls, [
        (1, null),
        (1, 'ra'),
        (2, 'ra'),
        (1, 'rah'),
        (1, null),
      ]);
      controller.onClose();
    },
  );
}
