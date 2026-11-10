import type { BrokenSalesPageProps } from "../types";

const pageProps: Record<keyof BrokenSalesPageProps, true> = {
  issue_type: true,
  view: true,
  filter: true,
  scope: true,
  product_id: true,
  product_title: true,
  counts: true,
  repairable: true,
  filters: true,
  issues: true,
  pagination: true,
};

export const reloadProps = Object.keys(pageProps);
