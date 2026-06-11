import type { BrandRecord, ProductRecord } from "../types";

export function makeBrand(overrides: Partial<BrandRecord> = {}): BrandRecord {
  return {
    id: 1,
    title: "Moonbow",
    created_at: "19. May '26 16:18",
    updated_at: "19. May '26 16:18",
    ...overrides,
  };
}

export function makeBrandProduct(overrides: Partial<ProductRecord> = {}): ProductRecord {
  return {
    id: 10,
    full_title: "Studio Ghibli - Spirited Away",
    path: "/products/10",
    ...overrides,
  };
}
