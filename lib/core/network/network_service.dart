import 'package:dio/dio.dart';
import '../errors/exceptions.dart';

class NetworkService {
  late final Dio _dio;

  NetworkService() {
    _dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 30),
      ),
    );

    _dio.interceptors.add(
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        requestHeader: true,
        responseHeader: false,
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onError: (error, handler) {
          final exception = _handleDioError(error);
          handler.reject(
            DioException(
              requestOptions: error.requestOptions,
              error: exception,
            ),
          );
        },
      ),
    );
  }

  Dio get dio => _dio;

  Exception _handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const NetworkException('Tiempo de espera agotado');
      case DioExceptionType.connectionError:
        return const NetworkException('Error de conexión');
      case DioExceptionType.badResponse:
        return ServerException(
          'Error del servidor: ${error.response?.statusCode}',
        );
      case DioExceptionType.cancel:
        return const NetworkException('Solicitud cancelada');
      default:
        return const NetworkException('Error de red desconocido');
    }
  }
}
