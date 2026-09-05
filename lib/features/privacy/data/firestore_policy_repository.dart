import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/database/database.dart';
import '../../../core/errors/errors.dart';
import '../../../core/utils/utils.dart';
import '../domain/entities/policy_document.dart';
import '../domain/entities/user_policy_acceptance.dart';
import '../domain/repositories/policy_repository.dart';

final class FirestorePolicyRepository implements PolicyRepository {
  const FirestorePolicyRepository(this._firestore);
  final FirebaseFirestore _firestore;

  static final List<PolicyDocument> bundledDocuments = <PolicyDocument>[
    PolicyDocument(
      type: PolicyDocumentType.privacyPolicy,
      version: '2026-09-05',
      publishedAt: DateTime.utc(2026, 9, 5),
      content:
          'A VestiPro trata dados de cadastro, organização, clientes e atividade comercial para prestar o serviço. Aplicamos minimização, controle de acesso e isolamento por organização. Os dados são usados para autenticação, operação da força de vendas, suporte, segurança e cumprimento de obrigações legais. Você pode solicitar acesso, correção, portabilidade ou exclusão quando aplicável. Registros sujeitos a obrigação legal ou de auditoria serão conservados pelo prazo necessário. Dúvidas e solicitações de privacidade devem ser encaminhadas ao canal de suporte da VestiPro.',
    ),
    PolicyDocument(
      type: PolicyDocumentType.termsOfUse,
      version: '2026-09-05',
      publishedAt: DateTime.utc(2026, 9, 5),
      content:
          'Ao usar a VestiPro, você se compromete a fornecer informações verdadeiras, proteger suas credenciais e utilizar a plataforma apenas para atividades legítimas da sua organização. O acesso e as permissões dependem do vínculo ativo e do perfil atribuído. É proibido tentar acessar dados de outra organização, contornar controles de segurança ou usar o serviço de forma abusiva. Funcionalidades podem evoluir, mas uma nova versão destes termos ou da política sempre exigirá novo aceite explícito antes da continuidade de uso.',
    ),
  ];

  @override
  Future<AppResult<List<PolicyDocument>>> getCurrentDocuments() async {
    try {
      final snapshot = await _firestore
          .collection('policyDocuments')
          .where('published', isEqualTo: true)
          .get();
      final remote = snapshot.docs.map(_documentFromSnapshot).toList();
      final current = <PolicyDocument>[];
      for (final type in PolicyDocumentType.values) {
        final candidates =
            remote.where((document) => document.type == type).toList()
              ..sort((a, b) => b.publishedAt.compareTo(a.publishedAt));
        current.add(
          candidates.isEmpty
              ? bundledDocuments.firstWhere((document) => document.type == type)
              : candidates.first,
        );
      }
      return AppSuccess<List<PolicyDocument>>(current);
    } on FirebaseException catch (exception, stackTrace) {
      return AppFailure<List<PolicyDocument>>(
        mapAppExceptionToFailure(
          mapFirestoreExceptionToAppException(exception, stackTrace),
        ),
      );
    } on AppException catch (exception) {
      return AppFailure<List<PolicyDocument>>(
        mapAppExceptionToFailure(exception),
      );
    } catch (exception) {
      return AppFailure<List<PolicyDocument>>(
        UnexpectedFailure(
          'Não foi possível carregar os documentos legais.',
          code: 'policy_documents_unexpected',
          cause: exception,
        ),
      );
    }
  }

  @override
  Future<AppResult<Set<String>>> getAcceptedDocumentIds(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('policyAcceptances')
          .get();
      return AppSuccess<Set<String>>(
        snapshot.docs.map((document) => document.id).toSet(),
      );
    } on FirebaseException catch (exception, stackTrace) {
      return AppFailure<Set<String>>(
        mapAppExceptionToFailure(
          mapFirestoreExceptionToAppException(exception, stackTrace),
        ),
      );
    } catch (exception) {
      return AppFailure<Set<String>>(
        UnexpectedFailure(
          'Não foi possível verificar os aceites.',
          code: 'policy_acceptances_unexpected',
          cause: exception,
        ),
      );
    }
  }

  @override
  Future<AppResult<void>> registerAcceptances(
    List<UserPolicyAcceptance> acceptances,
  ) async {
    try {
      final batch = _firestore.batch();
      for (final acceptance in acceptances) {
        final reference = _firestore
            .collection('users')
            .doc(acceptance.userId)
            .collection('policyAcceptances')
            .doc(acceptance.id);
        batch.set(reference, <String, Object?>{
          'userId': acceptance.userId,
          'type': acceptance.type.code,
          'version': acceptance.version,
          // Server time is authoritative for the compliance trail; the
          // domain timestamp captures the user's action while Rules reject
          // any client-forged audit instant.
          'acceptedAt': FieldValue.serverTimestamp(),
          'device': acceptance.device,
        });
      }
      await batch.commit();
      return const AppSuccess<void>(null);
    } on FirebaseException catch (exception, stackTrace) {
      return AppFailure<void>(
        mapAppExceptionToFailure(
          mapFirestoreExceptionToAppException(exception, stackTrace),
        ),
      );
    } catch (exception) {
      return AppFailure<void>(
        UnexpectedFailure(
          'Não foi possível registrar o aceite.',
          code: 'policy_acceptance_write_unexpected',
          cause: exception,
        ),
      );
    }
  }

  PolicyDocument _documentFromSnapshot(
    QueryDocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data();
    final type = PolicyDocumentType.values
        .where((value) => value.code == data['type'])
        .firstOrNull;
    final version = data['version'];
    final content = data['content'];
    final publishedAt = data['publishedAt'];
    if (type == null ||
        version is! String ||
        content is! String ||
        publishedAt is! Timestamp) {
      throw const ValidationException(
        'Documento legal inválido.',
        code: 'invalid_policy_document',
      );
    }
    final url = data['url'];
    return PolicyDocument(
      type: type,
      version: version,
      content: content,
      publishedAt: publishedAt.toDate(),
      url: url is String ? Uri.tryParse(url) : null,
    );
  }
}
