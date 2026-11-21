import 'package:flutter_test/flutter_test.dart';
import 'package:sprint_14/cache/sync/sync_merge.dart';

class Item {
  final String id;
  final String value;
  final bool synced;
  final bool deleted;
  const Item(this.id, this.value, {this.synced = true, this.deleted = false});
  Item asSynced() => Item(id, value, synced: true, deleted: deleted);
}

MergeResult<Item> merge(
  List<Item> cloud,
  List<Item> local, {
  bool prune = true,
}) {
  return mergeCloudWithLocal<Item>(
    cloud: cloud,
    local: local,
    idOf: (i) => i.id,
    isSynced: (i) => i.synced,
    isDeleted: (i) => i.deleted,
    markSynced: (i) => i.asSynced(),
    pruneMissing: prune,
  );
}

void main() {
  test('unsynced local edit wins over cloud and is not overwritten', () {
    final r = merge(
      [const Item('a', 'cloud')],
      [const Item('a', 'local edit', synced: false)],
    );
    expect(r.visible.single.value, 'local edit');
    expect(r.toSave, isEmpty);
  });

  test('synced local row is refreshed from cloud', () {
    final r = merge([const Item('a', 'new')], [const Item('a', 'old')]);
    expect(r.visible.single.value, 'new');
    expect(r.toSave.single.value, 'new');
  });

  test('item created offline stays visible and on top', () {
    final r = merge(
      [const Item('a', 'cloud')],
      [const Item('a', 'cloud'), const Item('b', 'offline', synced: false)],
    );
    expect(r.visible.map((i) => i.id), ['b', 'a']);
    expect(r.toRemove, isEmpty);
  });

  test('synced row missing from cloud is removed (deleted elsewhere)', () {
    final r = merge([const Item('a', 'x')], [const Item('a', 'x'), const Item('gone', 'y')]);
    expect(r.toRemove, ['gone']);
    expect(r.visible.map((i) => i.id), ['a']);
  });

  test('pending local delete stays hidden even though cloud still has it', () {
    final r = merge(
      [const Item('a', 'x')],
      [const Item('a', 'x', synced: false, deleted: true)],
    );
    expect(r.visible, isEmpty);
    expect(r.toSave, isEmpty);
  });

  test('pruneMissing false never removes local rows', () {
    final r = merge([], [const Item('old', 'x')], prune: false);
    expect(r.toRemove, isEmpty);
    expect(r.visible, isEmpty);
  });

  test('empty cloud keeps pending creations', () {
    final r = merge([], [const Item('new', 'x', synced: false)]);
    expect(r.visible.single.id, 'new');
  });
}
