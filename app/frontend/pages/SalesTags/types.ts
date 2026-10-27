import type { SalesTagRecord } from "@/types/salesTag";

export type SalesTagCatalogRecord = SalesTagRecord & {
  usage_count: number;
};
