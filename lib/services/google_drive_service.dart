// lib/services/google_drive_service.dart
import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis_auth/auth_io.dart';

class GoogleDriveService {
  static const String _credentialsPath = 'assets/google_drive_credentials.json';
  static const String _folderId = '1UU3H3jSG7054ZKKbNSKt0sd7S5ct1EhK';

  drive.DriveApi? _driveApi;
  AuthClient? _authClient;
  bool _isInitialized = false;

  // Singleton pattern
  static final GoogleDriveService _instance = GoogleDriveService._internal();
  factory GoogleDriveService() => _instance;
  GoogleDriveService._internal();

  /// Getter para verificar se está inicializado
  bool get isInitialized => _isInitialized && _driveApi != null;

  /// Inicializa a conexão com o Google Drive
  Future<void> initialize() async {
    if (_isInitialized && _driveApi != null) {
      print('Google Drive Service já inicializado');
      return;
    }

    try {
      print('Iniciando inicialização do Google Drive Service...');

      // Carregar credenciais
      String credentialsJson = await rootBundle.loadString(_credentialsPath);
      print('Credenciais carregadas com sucesso');

      Map<String, dynamic> credentialsMap = json.decode(credentialsJson);

      // Validar se as credenciais têm os campos necessários
      if (!credentialsMap.containsKey('private_key') ||
          !credentialsMap.containsKey('client_email')) {
        throw Exception('Credenciais inválidas: campos obrigatórios ausentes');
      }

      print('Service Account Email: ${credentialsMap['client_email']}');

      // Criar credenciais de service account
      ServiceAccountCredentials credentials =
          ServiceAccountCredentials.fromJson(credentialsMap);
      print('Credenciais de service account criadas');

      // Definir escopos
      List<String> scopes = [drive.DriveApi.driveScope];

      // Autenticar
      print('Iniciando autenticação...');
      _authClient = await clientViaServiceAccount(credentials, scopes);
      print('Autenticação realizada com sucesso');

      // Criar API client
      _driveApi = drive.DriveApi(_authClient!);

      // Testar a conexão
      await _testConnection();

      _isInitialized = true;
      print('Google Drive Service inicializado com sucesso');
    } catch (e) {
      _isInitialized = false;
      _driveApi = null;
      _authClient?.close();
      _authClient = null;
      print('Erro detalhado na inicialização: $e');
      throw Exception('Erro ao inicializar Google Drive Service: $e');
    }
  }

  /// Testa a conexão com o Google Drive
  Future<void> _testConnection() async {
    try {
      if (_driveApi == null) throw Exception('DriveApi é null');

      print('Testando conexão básica com Google Drive...');

      // Teste simples - listar arquivos
      drive.FileList testList = await _driveApi!.files.list(
        pageSize: 1,
      );

      print('Conexão com Google Drive estabelecida com sucesso');
      print(
          'Service account tem acesso a ${testList.files?.length ?? 0} arquivo(s) visível(is)');

      // Tentar testar acesso à pasta específica
      await _testFolderAccess();
    } catch (e) {
      throw Exception('Falha no teste de conexão básica: $e');
    }
  }

  /// Testa acesso à pasta específica
  Future<void> _testFolderAccess() async {
    try {
      print('Testando acesso à pasta específica...');

      // Tentar listar arquivos da pasta
      drive.FileList folderTest = await _driveApi!.files.list(
        q: "'$_folderId' in parents and trashed = false",
        pageSize: 1,
      );

      print(
          'Acesso à pasta específica OK. Arquivos encontrados: ${folderTest.files?.length ?? 0}');
    } catch (folderError) {
      print('Aviso: Não foi possível acessar a pasta específica: $folderError');
      print('O upload será feito na pasta raiz da service account');
    }
  }

  /// Faz upload de uma imagem para o Google Drive a partir de um arquivo físico
  Future<String?> uploadImage({
    required File imageFile,
    required String fileName,
    String? description,
  }) async {
    try {
      print('Iniciando upload de arquivo: $fileName');

      // Garantir que está inicializado
      if (!isInitialized) {
        await initialize();
      }

      if (_driveApi == null) {
        throw Exception('Google Drive API não inicializada');
      }

      // Verificar se o arquivo existe
      if (!await imageFile.exists()) {
        throw Exception('Arquivo não encontrado: ${imageFile.path}');
      }

      int fileSize = await imageFile.length();
      print('Tamanho do arquivo: $fileSize bytes');

      // Validar tamanho (máximo 10MB para o Google Drive API)
      if (fileSize > 10 * 1024 * 1024) {
        throw Exception('Arquivo muito grande. Máximo 10MB permitido.');
      }

      // Metadados do arquivo
      drive.File fileMetadata = drive.File()
        ..name = fileName
        ..description = description ?? 'Upload via app'
        ..parents = [_folderId]; // Sempre tentar usar a pasta específica

      // Media do arquivo
      drive.Media media = drive.Media(
        imageFile.openRead(),
        fileSize,
        contentType: _getContentType(fileName),
      );

      print('Enviando arquivo para Google Drive...');

      // Upload
      drive.File uploadedFile = await _driveApi!.files.create(
        fileMetadata,
        uploadMedia: media,
      );

      if (uploadedFile.id == null) {
        throw Exception('Falha no upload: ID do arquivo não retornado');
      }

      print('Arquivo enviado com sucesso. ID: ${uploadedFile.id}');

      // Tornar público
      await _makeFilePublic(uploadedFile.id!);

      // Retornar URL pública
      String publicUrl = _generatePublicUrl(uploadedFile.id!);
      print('URL pública gerada: $publicUrl');

      return publicUrl;
    } catch (e) {
      print('Erro detalhado no upload: $e');

      // Se o erro for relacionado à pasta, tentar novamente sem especificar pasta
      if (e.toString().contains('parents') || e.toString().contains('folder')) {
        print('Tentando upload sem pasta específica...');
        return await _uploadImageWithoutFolder(
            imageFile, fileName, description);
      }

      throw Exception('Falha no upload da imagem: $e');
    }
  }

  /// Upload sem pasta específica (fallback)
  Future<String?> _uploadImageWithoutFolder(
      File imageFile, String fileName, String? description) async {
    try {
      int fileSize = await imageFile.length();

      // Metadados do arquivo sem pasta específica
      drive.File fileMetadata = drive.File()
        ..name = fileName
        ..description = description ?? 'Upload via app (fallback)';

      // Media do arquivo
      drive.Media media = drive.Media(
        imageFile.openRead(),
        fileSize,
        contentType: _getContentType(fileName),
      );

      // Upload
      drive.File uploadedFile = await _driveApi!.files.create(
        fileMetadata,
        uploadMedia: media,
      );

      if (uploadedFile.id == null) {
        throw Exception(
            'Falha no upload fallback: ID do arquivo não retornado');
      }

      print('Upload fallback bem-sucedido. ID: ${uploadedFile.id}');

      // Tornar público
      await _makeFilePublic(uploadedFile.id!);

      // Retornar URL pública
      String publicUrl = _generatePublicUrl(uploadedFile.id!);
      return publicUrl;
    } catch (e) {
      throw Exception('Falha no upload fallback: $e');
    }
  }

  /// Faz upload de uma imagem para o Google Drive a partir de bytes (Web)
  Future<String?> uploadImageFromBytes({
    required Uint8List imageBytes,
    required String fileName,
    String? description,
  }) async {
    try {
      print(
          'Iniciando upload de bytes: $fileName (${imageBytes.length} bytes)');

      // Garantir que está inicializado
      if (!isInitialized) {
        await initialize();
      }

      if (_driveApi == null) {
        throw Exception('Google Drive API não inicializada');
      }

      // Validar tamanho (máximo 10MB)
      if (imageBytes.length > 10 * 1024 * 1024) {
        throw Exception('Arquivo muito grande. Máximo 10MB permitido.');
      }

      // Metadados do arquivo
      drive.File fileMetadata = drive.File()
        ..name = fileName
        ..description = description ?? 'Upload via app (bytes)'
        ..parents = [_folderId]; // Sempre tentar usar a pasta específica

      // Media a partir dos bytes
      drive.Media media = drive.Media(
        Stream.value(imageBytes),
        imageBytes.length,
        contentType: _getContentType(fileName),
      );

      print('Enviando bytes para Google Drive...');

      // Upload
      drive.File uploadedFile = await _driveApi!.files.create(
        fileMetadata,
        uploadMedia: media,
      );

      if (uploadedFile.id == null) {
        throw Exception('Falha no upload: ID do arquivo não retornado');
      }

      print('Bytes enviados com sucesso. ID: ${uploadedFile.id}');

      // Tornar público
      await _makeFilePublic(uploadedFile.id!);

      // Retornar URL pública
      String publicUrl = _generatePublicUrl(uploadedFile.id!);
      print('URL pública gerada: $publicUrl');

      return publicUrl;
    } catch (e) {
      print('Erro detalhado no upload de bytes: $e');

      // Se o erro for relacionado à pasta, tentar novamente sem especificar pasta
      if (e.toString().contains('parents') || e.toString().contains('folder')) {
        print('Tentando upload de bytes sem pasta específica...');
        return await _uploadBytesWithoutFolder(
            imageBytes, fileName, description);
      }

      throw Exception('Falha no upload da imagem: $e');
    }
  }

  /// Upload de bytes sem pasta específica (fallback)
  Future<String?> _uploadBytesWithoutFolder(
      Uint8List imageBytes, String fileName, String? description) async {
    try {
      // Metadados do arquivo sem pasta específica
      drive.File fileMetadata = drive.File()
        ..name = fileName
        ..description = description ?? 'Upload via app (bytes fallback)';

      // Media a partir dos bytes
      drive.Media media = drive.Media(
        Stream.value(imageBytes),
        imageBytes.length,
        contentType: _getContentType(fileName),
      );

      // Upload
      drive.File uploadedFile = await _driveApi!.files.create(
        fileMetadata,
        uploadMedia: media,
      );

      if (uploadedFile.id == null) {
        throw Exception(
            'Falha no upload fallback: ID do arquivo não retornado');
      }

      print('Upload de bytes fallback bem-sucedido. ID: ${uploadedFile.id}');

      // Tornar público
      await _makeFilePublic(uploadedFile.id!);

      // Retornar URL pública
      String publicUrl = _generatePublicUrl(uploadedFile.id!);
      return publicUrl;
    } catch (e) {
      throw Exception('Falha no upload de bytes fallback: $e');
    }
  }

  /// Deleta um arquivo do Google Drive usando sua URL
  Future<bool> deleteFileByUrl(String fileUrl) async {
    try {
      print('Tentando deletar arquivo: $fileUrl');

      // Garantir que está inicializado
      if (!isInitialized) {
        await initialize();
      }

      if (_driveApi == null) {
        print('DriveApi não inicializada');
        return false;
      }

      // Extrair ID do arquivo da URL
      String? fileId = _extractFileIdFromUrl(fileUrl);
      if (fileId == null) {
        print('Não foi possível extrair ID da URL: $fileUrl');
        return false;
      }

      print('Deletando arquivo com ID: $fileId');

      // Verificar se o arquivo existe antes de tentar deletar
      try {
        await _driveApi!.files.get(fileId);
        print('Arquivo encontrado, procedendo com a deleção...');
      } catch (e) {
        print('Arquivo não encontrado ou já foi deletado: $e');
        return true; // Considera como sucesso se já não existe
      }

      // Deletar arquivo
      await _driveApi!.files.delete(fileId);
      print('Arquivo deletado com sucesso');
      return true;
    } catch (e) {
      print('Erro ao deletar arquivo: $e');
      return false;
    }
  }

  /// Torna um arquivo público para leitura
  Future<void> _makeFilePublic(String fileId) async {
    try {
      print('Tornando arquivo público: $fileId');

      await _driveApi!.permissions.create(
        drive.Permission()
          ..role = 'reader'
          ..type = 'anyone',
        fileId,
      );

      print('Arquivo tornado público com sucesso');
    } catch (e) {
      print('Erro ao tornar arquivo público: $e');
      print('Aviso: Arquivo foi enviado mas não pôde ser tornado público');
    }
  }

  /// Gera URL pública para visualização
  String _generatePublicUrl(String fileId) {
    return 'https://drive.google.com/uc?export=view&id=$fileId';
  }

  /// Extrai o ID do arquivo de uma URL do Google Drive
  String? _extractFileIdFromUrl(String url) {
    try {
      if (url.contains('drive.google.com/uc?export=view&id=')) {
        String temp = url.split('id=')[1];
        return temp.contains('&') ? temp.split('&')[0] : temp;
      }
      if (url.contains('drive.google.com/file/d/')) {
        String temp = url.split('/d/')[1];
        return temp.split('/')[0];
      }
      if (url.contains('drive.google.com/open?id=')) {
        String temp = url.split('id=')[1];
        return temp.contains('&') ? temp.split('&')[0] : temp;
      }
      return null;
    } catch (e) {
      print('Erro ao extrair ID da URL: $e');
      return null;
    }
  }

  /// Determina o content type baseado na extensão do arquivo
  String _getContentType(String fileName) {
    String extension = fileName.split('.').last.toLowerCase();
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      case 'bmp':
        return 'image/bmp';
      case 'tiff':
      case 'tif':
        return 'image/tiff';
      default:
        return 'image/jpeg';
    }
  }

  /// Lista todos os arquivos na pasta
  Future<List<drive.File>> listFiles() async {
    try {
      if (!isInitialized) {
        await initialize();
      }

      if (_driveApi == null) return [];

      drive.FileList fileList = await _driveApi!.files.list(
        q: "'$_folderId' in parents and trashed = false",
        spaces: 'drive',
        orderBy: 'createdTime desc',
      );

      print('Arquivos listados: ${fileList.files?.length ?? 0}');
      return fileList.files ?? [];
    } catch (e) {
      print('Erro ao listar arquivos: $e');
      return [];
    }
  }

  /// Verifica se o serviço está funcionando corretamente
  Future<bool> healthCheck() async {
    try {
      if (!isInitialized) {
        await initialize();
      }

      if (_driveApi == null) return false;

      // Teste simples
      await _driveApi!.files.list(pageSize: 1);
      return true;
    } catch (e) {
      print('Health check falhou: $e');
      return false;
    }
  }

  /// Limpa recursos e reseta o serviço
  void dispose() {
    _authClient?.close();
    _authClient = null;
    _driveApi = null;
    _isInitialized = false;
    print('Google Drive Service disposed');
  }

  /// Força reinicialização do serviço
  Future<void> reinitialize() async {
    dispose();
    await initialize();
  }
}
