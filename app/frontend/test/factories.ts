import type { PaginationMeta } from "@/types/pagination";

type HasId = { id: number };

export function makePagination(overrides: Partial<PaginationMeta> = {}): PaginationMeta {
  return {
    current_page: 1,
    total_pages: 1,
    total_count: 1,
    limit: 50,
    ...overrides,
  };
}

// Like FactoryBot's create_list: builds `count` records from `factory`, auto-incrementing
// `id` so each record has a unique key. Override other fields via the third argument.
export function makeList<T extends HasId>(
  factory: (overrides?: Partial<T>) => T,
  count: number,
  // eslint-disable-next-line @typescript-eslint/no-unsafe-type-assertion
  overrides: Omit<Partial<T>, "id"> = {} as Omit<Partial<T>, "id">,
): T[] {
  return Array.from({ length: count }, (_, i) =>
    // eslint-disable-next-line @typescript-eslint/no-unsafe-type-assertion
    factory({ ...overrides, id: i + 1 } as Partial<T>),
  );
}
