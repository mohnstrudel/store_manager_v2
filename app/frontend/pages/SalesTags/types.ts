import type {
  SalesTagsCatalog,
  SalesTagsDetail,
  SalesTagsIndex,
  SalesTagsSale,
} from "@/types/serializers";

export type SalesTagCatalogRecord = SalesTagsCatalog;

export type SalesTagFormRecord = NonNullable<SalesTagsIndex["sales_tag"]>;

export type SalesTagDraft = Pick<SalesTagFormRecord, "name" | "color">;

export type SalesTagSaleItem = SalesTagsSale["items"][number];

export type SalesTagSaleLink = SalesTagsSale;

export type SalesTagDetailRecord = SalesTagsDetail;
