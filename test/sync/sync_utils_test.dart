import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:sprint_14/cache/sync/sync_utils.dart';

void main() {
  test('SyncLock never runs the same key in parallel', () async {
    var running = 0;
    var maxParallel = 0;
    var runs = 0;

    Future<void> task() async {
      running++;
      runs++;
      maxParallel = running > maxParallel ? running : maxParallel;
      await Future.delayed(const Duration(milliseconds: 20));
      running--;
    }

    await Future.wait([
      SyncLock.run('k', task),
      SyncLock.run('k', task),
      SyncLock.run('k', task),
    ]);

    expect(maxParallel, 1);
    // First run plus exactly one catch-up pass for the overlapping requests.
    expect(runs, 2);
    expect(SyncLock.isRunning('k'), isFalse);
  });

  test('SyncLock releases the key when the task throws', () async {
    await expectLater(
      SyncLock.run('err', () async => throw StateError('boom')),
      throwsStateError,
    );
    expect(SyncLock.isRunning('err'), isFalse);
  });

  test('chunked splits into groups of 30', () {
    final ids = List.generate(65, (i) => '$i');
    final chunks = chunked(ids);
    expect(chunks.map((c) => c.length), [30, 30, 5]);
    expect(chunks.expand((c) => c).toList(), ids);
    expect(chunked(<String>[]), isEmpty);
  });
}
