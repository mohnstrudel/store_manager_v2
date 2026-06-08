/**
 * Returns a new array with the item matching `id` shallow-merged with `updates`.
 * Useful for optimistic updates of a record inside a collection of page props.
 */
export function replaceById<T extends { id: number }>(
  items: T[],
  id: number,
  updates: Partial<T>,
): T[] {
  return items.map((item) => (item.id === id ? { ...item, ...updates } : item));
}
