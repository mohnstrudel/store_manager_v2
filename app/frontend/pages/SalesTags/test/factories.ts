import type { SalesTagCatalogRecord } from "../types";

export function makeSalesTagCatalogRecord(
  overrides: Partial<SalesTagCatalogRecord> = {},
): SalesTagCatalogRecord {
  return {
    id: 1,
    name: "VIP Order",
    color: "sky",
    usage_count: 0,
    ...overrides,
  };
}
