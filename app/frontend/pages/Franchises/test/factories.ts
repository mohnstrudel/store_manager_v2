import type { FranchiseRecord, ProductRecord } from "../types";

export function makeFranchise(overrides: Partial<FranchiseRecord> = {}): FranchiseRecord {
  return {
    id: 1,
    title: "Pokemon",
    created_at: "19. May '26 16:18",
    updated_at: "19. May '26 16:18",
    ...overrides,
  };
}

export function makeFranchiseProduct(overrides: Partial<ProductRecord> = {}): ProductRecord {
  return {
    id: 10,
    full_title: "Pokemon - Pikachu",
    path: "/products/10",
    ...overrides,
  };
}
