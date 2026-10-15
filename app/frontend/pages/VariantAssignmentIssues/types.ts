import type { PaginationMeta } from "@/types/pagination";
import type { VariantAssignmentOption } from "@/types/variantAssignment";

export type IssueType =
  | "purchases"
  | "sale_items"
  | "purchase_item_links"
  | "sku_collisions"
  | "shopify_conflicts";

export type AssignmentIssueCounts = Record<IssueType, number>;

export type IssueFilter = {
  value: string;
  label: string;
};

type AssignmentIssueBase = {
  id: number;
  reason: string;
  reference: string;
  product_id: number | null;
  product_title: string;
  variant_id: number | null;
  current_variant_label: string;
  current_variant_product_id: number | null;
  candidates: VariantAssignmentOption[];
  linked_units: number;
  record_path: string;
};

export type PurchaseAssignmentIssue = AssignmentIssueBase & {
  kind: "purchase";
  inventory_units: number;
};

export type SaleItemAssignmentIssue = AssignmentIssueBase & {
  kind: "sale_item";
  ordered_units: number;
};

export type PurchaseItemLinkIssue = {
  kind: "purchase_item_link";
  id: number;
  reason: string;
  purchase_id: number;
  purchase_path: string;
  sale_item_id: number;
  sale_path: string;
  purchase_product_title: string;
  purchase_variant_label: string;
  sale_product_title: string;
  sale_variant_label: string;
  exact_replacements_available: number;
  exact_replacement_ids: number[];
  remaining_capacity_after_unlink: number;
};

export type SkuCollisionReference = {
  product_id: number;
  product_title: string;
  variant_id: number;
  variant_label: string;
  edit_path: string;
};

export type SkuCollisionIssue = {
  kind: "sku_collision";
  id: number;
  sku: string;
  product_id: number;
  product_title: string;
  variant_label: string;
  edit_path: string;
  colliding_with: SkuCollisionReference[];
};

export type ShopifyConflictIssue = {
  kind: "shopify_conflict";
  id: number;
  sku: string | null;
  store_id: string;
  shopify_options: Array<{ name: string; value: string }>;
  product_id: number;
  product_title: string;
  edit_path: string;
  conflicting_variant_label: string | null;
  conflicting_variant_sku: string | null;
};

export type AssignmentIssue =
  | PurchaseAssignmentIssue
  | SaleItemAssignmentIssue
  | PurchaseItemLinkIssue
  | SkuCollisionIssue
  | ShopifyConflictIssue;

export type VariantAssignmentIssuesPageProps = {
  counts: AssignmentIssueCounts;
  filter: string;
  filters: IssueFilter[];
  issue_type: IssueType;
  issues: AssignmentIssue[];
  pagination: PaginationMeta;
  repairable: boolean;
};
