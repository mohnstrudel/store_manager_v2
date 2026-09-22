export function replaceById<T extends { id: number }>(
  items: T[],
  id: number,
  updates: Partial<T>,
): T[] {
  return items.map((item) => (item.id === id ? { ...item, ...updates } : item));
}
