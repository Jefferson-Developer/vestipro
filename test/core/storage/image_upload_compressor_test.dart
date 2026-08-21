import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vestipro/core/storage/storage.dart';

class _MockImageCompressor extends Mock implements ImageCompressor {}

void main() {
  setUpAll(() {
    registerFallbackValue(Uint8List(0));
  });

  group('ImageUploadCompressor', () {
    late _MockImageCompressor compressor;
    late ImageUploadCompressor uploadCompressor;

    setUp(() {
      compressor = _MockImageCompressor();
      uploadCompressor = ImageUploadCompressor(compressor: compressor);
    });

    test(
      'compresses an image above the skip threshold through ImageCompressor',
      () async {
        final largeBytes = Uint8List(
          ImageUploadCompressor.skipCompressionThresholdBytes + 1,
        );
        final compressedBytes = Uint8List.fromList([1, 2, 3]);

        when(
          () => compressor.compress(
            any(),
            minWidth: any(named: 'minWidth'),
            minHeight: any(named: 'minHeight'),
            quality: any(named: 'quality'),
          ),
        ).thenAnswer((_) async => compressedBytes);

        final result = await uploadCompressor.compressForUpload(largeBytes);

        expect(result, same(compressedBytes));
        verify(
          () => compressor.compress(
            largeBytes,
            minWidth: ImageUploadCompressor.defaultMaxWidth,
            minHeight: ImageUploadCompressor.defaultMaxHeight,
            quality: ImageUploadCompressor.defaultQuality,
          ),
        ).called(1);
      },
    );

    test(
      'passes through custom limits to ImageCompressor for a large image',
      () async {
        final largeBytes = Uint8List(
          ImageUploadCompressor.skipCompressionThresholdBytes + 1,
        );
        final compressedBytes = Uint8List.fromList([9]);

        when(
          () => compressor.compress(
            any(),
            minWidth: any(named: 'minWidth'),
            minHeight: any(named: 'minHeight'),
            quality: any(named: 'quality'),
          ),
        ).thenAnswer((_) async => compressedBytes);

        final result = await uploadCompressor.compressForUpload(
          largeBytes,
          maxWidth: 800,
          maxHeight: 600,
          quality: 70,
        );

        expect(result, same(compressedBytes));
        verify(
          () => compressor.compress(
            largeBytes,
            minWidth: 800,
            minHeight: 600,
            quality: 70,
          ),
        ).called(1);
      },
    );

    test(
      'skips ImageCompressor entirely for an image already at/under the threshold',
      () async {
        final smallBytes = Uint8List(
          ImageUploadCompressor.skipCompressionThresholdBytes,
        );

        final result = await uploadCompressor.compressForUpload(smallBytes);

        expect(result, same(smallBytes));
        verifyNever(
          () => compressor.compress(
            any(),
            minWidth: any(named: 'minWidth'),
            minHeight: any(named: 'minHeight'),
            quality: any(named: 'quality'),
          ),
        );
      },
    );
  });
}
