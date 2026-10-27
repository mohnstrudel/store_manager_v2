import type { SalesTagCatalogRecord } from "../types";

export function makeSalesTagCatalogRecord(
  overrides: Partial<SalesTagCatalogRecord> = {},
): SalesTagCatalogRecord {
  return {
    id: 1,
    name: "VIP Order",
    color: "blue",
    usage_count: 0,
    ...overrides,
  };
}
