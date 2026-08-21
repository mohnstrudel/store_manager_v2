import type { PaginationMeta } from "@/types/pagination";
import type { VariantAssignmentOption } from "@/types/variantAssignment";

export type IssueType = "purchases" | "sale_items" | "purchase_item_links";

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

export type AssignmentIssue =
  | PurchaseAssignmentIssue
  | SaleItemAssignmentIssue
  | PurchaseItemLinkIssue;

export type VariantAssignmentIssuesPageProps = {
  counts: AssignmentIssueCounts;
  filter: string;
  filters: IssueFilter[];
  issue_type: IssueType;
  issues: AssignmentIssue[];
  pagination: PaginationMeta;
};
