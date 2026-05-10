class ApiConfig {
  ApiConfig._();
  //(LIVE)
 // static const baseUrl = 'https://ordermanage.b2bhaat.com';

  //(home)
 static const baseUrl = 'http://192.168.0.199:8000';
 // static const baseUrl = 'http://192.168.0.114:8000';
 //(Office)

    // static const baseUrl = 'http://10.44.66.202:8000';
  static const apiPrefix = '/api';
  static const protectedHeader = 'X-Authorization';
  static const bearerPrefix = 'Bearer';
}
