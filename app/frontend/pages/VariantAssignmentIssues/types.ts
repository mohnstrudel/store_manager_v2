import type {
  VariantAssignmentIssuesIndex,
  VariantAssignmentIssuesPurchase,
  VariantAssignmentIssuesPurchaseItemLink,
  VariantAssignmentIssuesSaleItem,
  VariantAssignmentIssuesShopifyConflict,
  VariantAssignmentIssuesSkuCollision,
} from "@/types/serializers";

export type IssueType = VariantAssignmentIssuesIndex["issue_type"];

export type AssignmentIssueCounts = VariantAssignmentIssuesIndex["counts"];

export type IssueFilter = VariantAssignmentIssuesIndex["filters"][number];

export type PurchaseAssignmentIssue = VariantAssignmentIssuesPurchase;

export type SaleItemAssignmentIssue = VariantAssignmentIssuesSaleItem;

export type PurchaseItemLinkIssue = VariantAssignmentIssuesPurchaseItemLink;

export type SkuCollisionReference = VariantAssignmentIssuesSkuCollision["colliding_with"][number];

export type SkuCollisionIssue = VariantAssignmentIssuesSkuCollision;

export type ShopifyConflictIssue = VariantAssignmentIssuesShopifyConflict;

export type AssignmentIssue = VariantAssignmentIssuesIndex["issues"][number];

export type VariantAssignmentIssuesPageProps = VariantAssignmentIssuesIndex;
