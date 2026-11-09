import type { ProductRecord, SizeFormRecord, SizeRecord } from "../types";

export function makeSize(overrides: Partial<SizeRecord> = {}): SizeRecord {
  return {
    id: 1,
    value: "1:6",
    created_at: "19. May '26 16:18",
    updated_at: "19. May '26 16:18",
    ...overrides,
  };
}

export function makeSizeProduct(overrides: Partial<ProductRecord> = {}): ProductRecord {
  return {
    id: 10,
    full_title: "Studio Ghibli - Spirited Away",
    path: "/products/10",
    ...overrides,
  };
}

export function makeSizeForm(overrides: Partial<SizeFormRecord> = {}): SizeFormRecord {
  return {
    value: "1:6",
    ...overrides,
  };
}
