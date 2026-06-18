type HasId = { id: number };

// Like FactoryBot's create_list: builds `count` records from `factory`, auto-incrementing
// `id` so each record has a unique key. Override other fields via the third argument.
export function makeList<T extends HasId>(
  factory: (overrides?: Partial<T>) => T,
  count: number,
  overrides: Omit<Partial<T>, "id"> = {} as Omit<Partial<T>, "id">,
): T[] {
  return Array.from({ length: count }, (_, i) =>
    factory({ ...overrides, id: i + 1 } as Partial<T>),
  );
}
