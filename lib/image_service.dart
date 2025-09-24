import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ImageService {
  static final ImageService _instance = ImageService._internal();
  factory ImageService() => _instance;
  ImageService._internal();

  // Cache de URLs processadas para evitar reprocessamento
  final Map<String, String> _urlCache = {};

  // Lista de proxies em ordem de preferência
  static const List<String> _proxies = [
    'https://api.allorigins.win/raw?url=',
    'https://cors-anywhere.herokuapp.com/',
    'https://thingproxy.freeboard.io/fetch/',
  ];

  /// Obtém a URL da imagem com tratamento de CORS para web
  String getImageUrl(String originalUrl) {
    if (!kIsWeb) {
      return originalUrl;
    }

    // Verifica cache primeiro
    if (_urlCache.containsKey(originalUrl)) {
      return _urlCache[originalUrl]!;
    }

    // Para URLs do Firebase Storage, tenta renovar o token primeiro
    if (originalUrl.contains('firebasestorage.googleapis.com')) {
      return _getFirebaseStorageUrl(originalUrl);
    }

    // Para outras URLs, usa proxy padrão
    String proxiedUrl = '${_proxies[0]}${Uri.encodeComponent(originalUrl)}';
    _urlCache[originalUrl] = proxiedUrl;
    return proxiedUrl;
  }

  /// Obtém múltiplas URLs com diferentes proxies para fallback
  List<String> getImageUrlsWithFallback(String originalUrl) {
    if (!kIsWeb) {
      return [originalUrl];
    }

    List<String> urls = [];

    // Adiciona versões com diferentes proxies
    for (String proxy in _proxies) {
      if (proxy.endsWith('=')) {
        urls.add('$proxy${Uri.encodeComponent(originalUrl)}');
      } else {
        urls.add('$proxy$originalUrl');
      }
    }

    // Adiciona URL original como último recurso
    urls.add(originalUrl);

    return urls;
  }

  String _getFirebaseStorageUrl(String originalUrl) {
    try {
      // Tenta renovar o token da URL do Firebase Storage
      Uri uri = Uri.parse(originalUrl);

      // Remove parâmetros de token antigos
      Map<String, String> newParams = Map.from(uri.queryParameters);
      newParams.remove('token');

      // Reconstrói a URL sem token (forçará renovação)
      Uri newUri =
          uri.replace(queryParameters: newParams.isEmpty ? null : newParams);
      String cleanUrl = newUri.toString();

      // Usa proxy para a URL limpa
      String proxiedUrl = '${_proxies[0]}${Uri.encodeComponent(cleanUrl)}';
      _urlCache[originalUrl] = proxiedUrl;
      return proxiedUrl;
    } catch (e) {
      print('Erro ao processar URL do Firebase Storage: $e');
      // Fallback para proxy simples
      String proxiedUrl = '${_proxies[0]}${Uri.encodeComponent(originalUrl)}';
      _urlCache[originalUrl] = proxiedUrl;
      return proxiedUrl;
    }
  }

  /// Limpa o cache de URLs (útil quando o usuário faz logout/login)
  void clearCache() {
    _urlCache.clear();
  }

  /// Força renovação de uma URL específica
  String refreshImageUrl(String originalUrl) {
    _urlCache.remove(originalUrl);
    return getImageUrl(originalUrl);
  }
}

/// Widget de imagem inteligente que tenta múltiplas URLs automaticamente
class SmartImage extends StatefulWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  final BorderRadius? borderRadius;

  const SmartImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.borderRadius,
  });

  @override
  State<SmartImage> createState() => _SmartImageState();
}

class _SmartImageState extends State<SmartImage> {
  late List<String> _urls;
  int _currentUrlIndex = 0;
  bool _hasError = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _urls = ImageService().getImageUrlsWithFallback(widget.imageUrl);
  }

  void _tryNextUrl() {
    if (_currentUrlIndex < _urls.length - 1) {
      setState(() {
        _currentUrlIndex++;
        _hasError = false;
        _isLoading = true;
      });
    } else {
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
    }
  }

  Widget _buildErrorWidget() {
    return widget.errorWidget ??
        Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: widget.borderRadius,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.broken_image, size: 32, color: Colors.grey[400]),
              const SizedBox(height: 8),
              Text(
                'Erro ao carregar\nimagem',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ],
          ),
        );
  }

  Widget _buildLoadingWidget() {
    return widget.placeholder ??
        Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.grey[100]!, Colors.grey[50]!],
            ),
            borderRadius: widget.borderRadius,
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  color: const Color.fromARGB(255, 1, 37, 54),
                  strokeWidth: 2,
                ),
                const SizedBox(height: 8),
                Text(
                  _currentUrlIndex > 0
                      ? 'Tentando proxy ${_currentUrlIndex + 1}...'
                      : 'Carregando...',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return _buildErrorWidget();
    }

    Widget imageWidget = Image.network(
      _urls[_currentUrlIndex],
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) {
          _isLoading = false;
          return child;
        }
        return _buildLoadingWidget();
      },
      errorBuilder: (context, error, stackTrace) {
        print(
            'Erro ao carregar URL ${_currentUrlIndex + 1}/${_urls.length}: ${_urls[_currentUrlIndex]}');
        print('Erro: $error');

        // Tenta a próxima URL automaticamente
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _tryNextUrl();
        });

        return _buildLoadingWidget();
      },
    );

    // Aplica borderRadius se fornecido
    if (widget.borderRadius != null) {
      return ClipRRect(
        borderRadius: widget.borderRadius!,
        child: imageWidget,
      );
    }

    return imageWidget;
  }
}
