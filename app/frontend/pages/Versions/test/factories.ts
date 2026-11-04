import type { ProductRecord, VersionFormRecord, VersionRecord } from "../types";

export function makeVersion(overrides: Partial<VersionRecord> = {}): VersionRecord {
  return {
    id: 1,
    value: "Classic",
    created_at: "19. May '26 16:18",
    updated_at: "20. May '26 16:18",
    ...overrides,
  };
}

export function makeNewVersionForm(overrides: Partial<VersionFormRecord> = {}): VersionFormRecord {
  return {
    id: null,
    value: "",
    created_at: null,
    updated_at: null,
    ...overrides,
  };
}

export function makeVersionProduct(overrides: Partial<ProductRecord> = {}): ProductRecord {
  return {
    id: 10,
    full_title: "Pokemon - Pikachu",
    path: "/products/10",
    ...overrides,
  };
}
