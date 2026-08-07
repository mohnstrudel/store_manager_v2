import { useCallback, useMemo, useState } from "react";
import ProductActions from "./Show/ProductActions";
import ProductDescription from "./Show/ProductDescription";
import ProductEconomicsDashboard from "./Show/ProductEconomicsDashboard";
import ProductOverview from "./Show/ProductOverview";
import ProductVariants from "./Show/ProductVariants";
import PurchasesSection from "./Show/PurchasesSection";
import SalesSection from "./Show/SalesSection";
import Button from "@/components/Button";
import PageHeader from "@/components/PageHeader";
import { useConfirmAction } from "@/utils/useConfirmAction";
import {
  type ProductShowRecord,
  type ProfitabilityRecord,
  type PurchaseRecord,
  type SaleItemRecord,
  type VariantRecord,
} from "./types";

type ShowProps = {
  active_sales: SaleItemRecord[];
  completed_sales: SaleItemRecord[];
  product: ProductShowRecord;
  profitability: ProfitabilityRecord | null;
  purchases: PurchaseRecord[];
  variants: VariantRecord[];
};

type TabId = "overview" | "variants" | "sales" | "purchases";

type Tab = {
  id: TabId;
  label: string;
  count?: number;
};

export default function Show({
  active_sales,
  completed_sales,
  product,
  profitability,
  purchases,
  variants,
}: ShowProps) {
  const [tab, setTab] = useState<TabId>("overview");
  const destroyProduct = useConfirmAction("delete", product.path);

  const hasVariants = variants.length > 0;
  const salesCount = active_sales.length + completed_sales.length;
  const tabs = useMemo<Tab[]>(
    () => [
      { id: "overview", label: "Overview" },
      ...(hasVariants
        ? [{ id: "variants", label: "Variants", count: variants.length } as Tab]
        : []),
      ...(salesCount > 0 ? [{ id: "sales", label: "Sales", count: salesCount } as Tab] : []),
      ...(purchases.length > 0
        ? [{ id: "purchases", label: "Purchases", count: purchases.length } as Tab]
        : []),
    ],
    [hasVariants, variants.length, salesCount, purchases.length],
  );

  return (
    <>
      <PageHeader subtitle={product.full_title} title={product.title}>
        <ProductActions product={product} />
      </PageHeader>

      <div className="section_wide flex flex-col gap-5">
        {profitability !== null && <ProductEconomicsDashboard profitability={profitability} />}

        <TabBar activeTab={tab} onSelect={setTab} tabs={tabs} />

        {tab === "overview" && (
          <div className="flex flex-col gap-8" role="tabpanel">
            <ProductOverview product={product} />
            <ProductDescription html={product.description_html} />
          </div>
        )}

        {tab === "variants" && (
          <div role="tabpanel">
            <ProductVariants variants={variants} />
          </div>
        )}

        {tab === "sales" && salesCount > 0 && (
          <div className="flex flex-col gap-8" role="tabpanel">
            <SalesSection hasVariants={hasVariants} sales={active_sales} title="Active Sales" />
            <SalesSection
              hasVariants={hasVariants}
              sales={completed_sales}
              title="Completed Sales"
            />
          </div>
        )}

        {tab === "purchases" && purchases.length > 0 && (
          <div role="tabpanel">
            <PurchasesSection purchases={purchases} />
          </div>
        )}
      </div>

      <Button className="w-full h-12 mt-16" onClick={destroyProduct} variant="danger">
        Destroy this product
      </Button>
    </>
  );
}

function TabBar({
  activeTab,
  onSelect,
  tabs,
}: {
  activeTab: TabId;
  onSelect: (tab: TabId) => void;
  tabs: Tab[];
}) {
  return (
    <div className="tab_bar_underline flex-wrap" role="tablist">
      {tabs.map((tab) => (
        <TabButton active={activeTab === tab.id} key={tab.id} onSelect={onSelect} tab={tab} />
      ))}
    </div>
  );
}

function TabButton({
  active,
  onSelect,
  tab,
}: {
  active: boolean;
  onSelect: (tab: TabId) => void;
  tab: Tab;
}) {
  const selectTab = useCallback(() => onSelect(tab.id), [onSelect, tab.id]);
  const accessibleName = tab.count === undefined ? tab.label : `${tab.label} ${tab.count}`;

  return (
    <button
      aria-label={accessibleName}
      aria-selected={active}
      className="tab_btn_underline w-auto"
      onClick={selectTab}
      role="tab"
      type="button"
    >
      {tab.label}
      {tab.count !== undefined && (
        <span className="ml-1.5 text-xs text-gray-400 dark:text-gray-500">{tab.count}</span>
      )}
    </button>
  );
}
