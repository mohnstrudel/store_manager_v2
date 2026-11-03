import routes from "@/utils/routes";

import type { SaleSort, SalesFilters } from "../types";

export type SalesListingSettings = SalesFilters & {
  q: string;
  sort: SaleSort;
};

const TAG_PROPS = ["tag_options", "tag_colors", "can_tag_sales"];

export const LISTING_PROPS = [
  "sales",
  "pagination",
  "search",
  "sort",
  "filters",
  ...TAG_PROPS,
  "flash",
];

export const TAG_SAVE_PROPS = ["sales", "pagination", "filters", ...TAG_PROPS, "flash"];

export function listingHref(settings: SalesListingSettings) {
  const path = routes.sales.list.path();
  const query = new URLSearchParams(listingParams(settings)).toString();

  return query ? `${path}?${query}` : path;
}

export function listingParams({
  q,
  sort,
  hide_partial_payments,
  missing_purchases_only,
  tag_id,
}: SalesListingSettings): Record<string, string> {
  const params: Record<string, string> = {};

  if (q) params.q = q;
  if (sort !== "newest") params.sort = sort;
  if (hide_partial_payments) params.hide_partial_payments = "1";
  if (missing_purchases_only) params.missing_purchases_only = "1";
  if (tag_id !== null) params.tag_id = String(tag_id);

  return params;
}

export function hasFilters(filters: SalesFilters) {
  return Object.values(filters).some(Boolean);
}
