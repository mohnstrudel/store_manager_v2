import type { SalesTagRecord } from "@/types/salesTag";

export type SalesTagCatalogRecord = SalesTagRecord & {
  usage_count: number;
};

export type SalesTagDraft = Pick<SalesTagRecord, "name" | "color">;

export type SalesTagFormRecord = SalesTagDraft & {
  id: number | null;
};

export type SalesTagSaleItem = {
  id: number;
  title: string;
  product_thumb_url: string | null;
};

export type SalesTagSaleLink = {
  id: number;
  path: string;
  label: string;
  items: SalesTagSaleItem[];
};

export type SalesTagDetailRecord = SalesTagRecord & {
  sales: SalesTagSaleLink[];
};
