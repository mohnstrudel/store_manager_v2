import type {
  BrokenSalesImportFailure,
  BrokenSalesIndex,
  BrokenSalesProductRow,
  BrokenSalesPurchase,
  BrokenSalesPurchaseItemLink,
  BrokenSalesSaleItem,
  BrokenSalesShopifyConflict,
  BrokenSalesSkuCollision,
} from "@/types/serializers";

export type IssueType = BrokenSalesIndex["issue_type"];

export type AssignmentIssueCounts = BrokenSalesIndex["counts"];

export type IssueFilter = BrokenSalesIndex["filters"][number];

export type PurchaseAssignmentIssue = BrokenSalesPurchase;

export type SaleItemAssignmentIssue = BrokenSalesSaleItem;

export type ProductIssueRow = BrokenSalesProductRow;

export type ImportFailureRow = BrokenSalesImportFailure;

export type OrderImportFailure = NonNullable<BrokenSalesSaleItem["import_failure"]>;

export type PurchaseItemLinkIssue = BrokenSalesPurchaseItemLink;

export type SkuCollisionReference = BrokenSalesSkuCollision["colliding_with"][number];

export type SkuCollisionIssue = BrokenSalesSkuCollision;

export type ShopifyConflictIssue = BrokenSalesShopifyConflict;

export type AssignmentIssue = BrokenSalesIndex["issues"][number];

export type BrokenSalesPageProps = BrokenSalesIndex;

export type OrderScope = NonNullable<BrokenSalesIndex["scope"]>;

export type IssueView = NonNullable<BrokenSalesIndex["view"]>;
