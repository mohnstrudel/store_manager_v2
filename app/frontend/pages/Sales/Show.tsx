import { useMemo } from "react";

import PageHeader from "@/components/PageHeader";
import type { SalesTagColor, SalesTagRecord } from "@/types/salesTag";

import Details from "./Show/Details";
import Items from "./Show/Items";
import ProfitabilitySummary from "./Show/ProfitabilitySummary";
import SaleActions from "./Show/SaleActions";
import SaleTags from "./Show/SaleTags";
import type { SaleShowRecord } from "./types";

type ShowProps = {
  sale: SaleShowRecord;
  tag_options: SalesTagRecord[];
  tag_colors: SalesTagColor[];
  can_tag_sales: boolean;
};

export default function Show({ sale, tag_options, tag_colors, can_tag_sales }: ShowProps) {
  const title = useMemo(() => <SaleTitle sale={sale} />, [sale]);

  return (
    <>
      <PageHeader title={title}>
        <SaleActions sale={sale} />
      </PageHeader>

      <SaleTags
        canTagSales={can_tag_sales}
        colors={tag_colors}
        options={tag_options}
        saleId={sale.id}
        tags={sale.tags}
      />

      <div className="section_wide flex flex-col gap-8 mt-8">
        <ProfitabilitySummary profitability={sale.profitability} />
        <Items
          saleId={sale.id}
          saleItems={sale.sale_items}
          warehouseMovePath={sale.warehouse_move_path}
          warehouses={sale.warehouses}
        />
        <Details sale={sale} />
      </div>
    </>
  );
}

function SaleTitle({ sale }: Pick<ShowProps, "sale">) {
  const noun = sale.is_follow_up_payment ? "Payment" : "Sale";

  if (sale.shopify_name || sale.shopify_id) {
    return (
      <>
        <span className="inline-block icon_shopify w-13 h-13 mr-3 -mb-1" />
        {noun} {sale.shop_identifier}
      </>
    );
  }

  if (sale.woo_store_id) {
    return (
      <>
        <span className="inline-block icon_woo w-17 h-17 mr-4 -mb-4" />
        {noun} {sale.woo_store_id}
      </>
    );
  }

  return (
    <>
      {noun} {sale.id}
    </>
  );
}
