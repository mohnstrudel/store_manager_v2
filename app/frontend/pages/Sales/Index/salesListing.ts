import routes from "@/utils/routes";

import type { SaleSort, SalesFilters } from "../types";

export type SalesListingSettings = SalesFilters & {
  q: string;
  sort: SaleSort;
};

export function listingHref(settings: SalesListingSettings) {
  const path = routes.sales.list.path();
  const query = new URLSearchParams(listingParams(settings)).toString();

  return query ? `${path}?${query}` : path;
}

export function listingParams({
  q,
  sort,
  hide_partial_payments,
  show_missing_purchases,
}: SalesListingSettings): Record<string, string> {
  const params: Record<string, string> = {};

  if (q) params.q = q;
  if (sort !== "newest") params.sort = sort;
  if (hide_partial_payments) params.hide_partial_payments = "1";
  if (show_missing_purchases) params.show_missing_purchases = "1";

  return params;
}

export function hasFilters(filters: SalesFilters) {
  return Object.values(filters).some(Boolean);
}
