/// Generic repository contract for CRUD-style access to items of type [T].
///
/// This is the single abstraction the rest of the app depends on. Any
/// concrete storage mechanism (a JSON file today, an in-memory store in
/// tests, a database tomorrow) only has to implement this interface, which
/// keeps the domain and presentation layers completely decoupled from how
/// data is actually persisted.
abstract class Repository<T> {
  /// Adds a new item. Should throw if an item with the same id exists.
  void add(T item);

  /// Returns every stored item.
  List<T> getAll();

  /// Replaces the stored item that shares [item]'s id.
  void update(T item);

  /// Removes the item with the given [id].
  void delete(String id);

  /// Returns the item with the given [id], or `null` if none exists.
  T? findById(String id);
}
