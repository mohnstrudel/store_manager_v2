import { useMemo } from "react";
import PageHeader from "@/components/PageHeader";
import Details from "./Show/Details";
import Items from "./Show/Items";
import SaleActions from "./Show/SaleActions";
import type { SaleShowRecord } from "./types";

type ShowProps = {
  sale: SaleShowRecord;
};

export default function Show({ sale }: ShowProps) {
  const title = useMemo(() => <SaleTitle sale={sale} />, [sale]);

  return (
    <>
      <PageHeader title={title}>
        <SaleActions sale={sale} />
      </PageHeader>

      <div className="section_wide flex flex-col gap-8 mt-8">
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

function SaleTitle({ sale }: ShowProps) {
  if (sale.shopify_name || sale.shopify_id) {
    return (
      <>
        <span className="inline-block icon_shopify w-13 h-13 mr-3 -mb-1" />
        Sale {sale.shop_identifier}
      </>
    );
  }

  if (sale.woo_store_id) {
    return (
      <>
        <span className="inline-block icon_woo w-17 h-17 mr-4 -mb-4" />
        Sale {sale.woo_store_id}
      </>
    );
  }

  return <>Sale {sale.id}</>;
}
