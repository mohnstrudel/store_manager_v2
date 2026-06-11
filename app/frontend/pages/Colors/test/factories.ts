import type { ColorRecord, ProductRecord } from "../types";

export function makeColor(overrides: Partial<ColorRecord> = {}): ColorRecord {
  return {
    id: 1,
    value: "Azure",
    created_at: "19. May '26 16:18",
    updated_at: "19. May '26 16:18",
    ...overrides,
  };
}

export function makeColorProduct(overrides: Partial<ProductRecord> = {}): ProductRecord {
  return {
    id: 10,
    full_title: "Studio Ghibli - Spirited Away",
    path: "/products/10",
    ...overrides,
  };
}
