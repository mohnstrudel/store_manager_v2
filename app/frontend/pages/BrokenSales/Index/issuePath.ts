import routes from "@/utils/routes";

import type { BrokenSalesPageProps } from "../types";

export type IssueLocation = Pick<BrokenSalesPageProps, "issue_type"> &
  Partial<Pick<BrokenSalesPageProps, "view" | "filter" | "scope" | "product_id">>;

export function issuePath(location: IssueLocation, page?: number) {
  return routes.brokenSales.index.path({
    query: {
      issue_type: location.issue_type,
      view: location.view ?? undefined,
      reason: location.filter || undefined,
      scope: location.scope ?? undefined,
      product_id: location.product_id ?? undefined,
      page,
    },
  });
}
