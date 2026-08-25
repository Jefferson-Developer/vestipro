import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:vestipro/core/functions/functions.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/products/data/repositories/firestore_product_variant_repository.dart';
import 'package:vestipro/features/products/products.dart';
import 'package:vestipro/firebase_options.dart';

/// Real integration test against Firebase Emulator Suite validating
/// ProductVariant persistence under `organizations/{orgId}/productVariants`.
///
/// Requires Auth, Firestore and Functions emulators so the test can bootstrap
/// the tenant through the real `createOrganization` callable instead of
/// opening any client-side membership shortcut:
///
/// ```bash
/// firebase emulators:exec --only auth,firestore,functions "flutter test integration_test/features/products/product_variant_firestore_repository_integration_test.dart -d chrome"
/// ```
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const emulatorHost = 'localhost';
  const firestorePort = 8080;
  const authPort = 9099;
  const functionsPort = 5001;

  late FirestoreProductVariantRepository repository;
  late String organizationId;
  late String userId;

  setUpAll(() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    FirebaseFirestore.instance.useFirestoreEmulator(
      emulatorHost,
      firestorePort,
    );
    await firebase.FirebaseAuth.instance.useAuthEmulator(
      emulatorHost,
      authPort,
    );
    FirebaseFunctions.instance.useFunctionsEmulator(
      emulatorHost,
      functionsPort,
    );

    final unique = DateTime.now().microsecondsSinceEpoch;
    final email = 'task-072-$unique@vestipro.test';
    final credentials = await firebase.FirebaseAuth.instance
        .createUserWithEmailAndPassword(
          email: email,
          password: 'Sup3rSecret!123',
        );
    userId = credentials.user!.uid;
    organizationId = 'task-072-org-$unique';

    final functions = CloudFunctionsService.withDependencies(
      FirebaseFunctions.instance,
      firebase.FirebaseAuth.instance,
      PackageInfoClientMetadataProvider(),
    );
    await functions.call<Map<String, dynamic>>(
      'createOrganization',
      data: <String, dynamic>{
        'organizationId': organizationId,
        'name': 'Task 072 Org',
        'slug': 'task-072-org-$unique',
        'currency': 'BRL',
        'country': 'BR',
        'defaultLanguage': 'pt-BR',
        'segment': 'apparel',
      },
      requireAuth: true,
    );
  });

  setUp(() {
    repository = FirestoreProductVariantRepository(FirebaseFirestore.instance);
  });

  tearDownAll(() async {
    await firebase.FirebaseAuth.instance.signOut();
  });

  testWidgets(
    'persists and reads generated variants with catalog.manage RBAC',
    (tester) async {
      final now = DateTime.now().toUtc();
      final variant = ProductVariant(
        id: 'variant-preto-p',
        organizationId: organizationId,
        productId: 'product-1',
        colorId: 'color-preto',
        sizeGridTemplateId: 'grid-pp-m',
        sizeId: 'size-p',
        sku: Sku.parse('CAMISA-001-PRETO-P'),
        ean: Ean.parse('4006381333931'),
        status: ProductVariantStatus.active,
        createdAt: now,
        createdBy: userId,
        updatedAt: now,
        updatedBy: userId,
        version: 1,
        syncStatus: ProductSyncStatus.pending,
      );

      final created = await repository.create(variant: variant);
      expect(created, isA<AppSuccess<ProductVariant>>());

      final loaded = await repository.getById(
        organizationId: organizationId,
        id: variant.id,
      );
      expect((loaded as AppSuccess<ProductVariant>).value.sku, variant.sku);

      final listed = await repository.listByProduct(
        organizationId: organizationId,
        productId: variant.productId,
      );
      expect((listed as AppSuccess<List<ProductVariant>>).value, hasLength(1));

      final skuExists = await repository.existsBySku(
        organizationId: organizationId,
        sku: variant.sku,
      );
      expect((skuExists as AppSuccess<bool>).value, isTrue);
    },
  );
}
