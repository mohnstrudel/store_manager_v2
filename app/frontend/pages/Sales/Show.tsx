import { useMemo } from "react";
import { ChevronDoubleDownIcon } from "@heroicons/react/20/solid";
import { BuildingStorefrontIcon } from "@heroicons/react/24/outline";
import { Link } from "@inertiajs/react";
import PageHeader from "@/components/PageHeader";
import Details from "./components/Details";
import Items from "./components/Items";
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
        <SaleActivity sale={sale} />
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

function SaleActions({ sale }: ShowProps) {
  return (
    <>
      {sale.can_link_purchase_items && (
        <li>
          <Link
            className="btn_rounded btn_lightblue"
            href={sale.link_purchase_items_path}
            method="post"
          >
            <i className="icn">🔗</i>
            Link with purchases
          </Link>
        </li>
      )}
      {canFetchSale(sale) && (
        <li>
          <Link className="btn_rounded" href={sale.pull_path} method="post">
            <ChevronDoubleDownIcon height={20} width={20} />
            Fetch
          </Link>
        </li>
      )}
      {sale.shop_admin_url && (
        <li>
          <a href={sale.shop_admin_url} rel="noopener noreferrer" target="_blank">
            <BuildingStorefrontIcon height={20} width={20} />
            Go to {storeAdminLabel(sale)}
          </a>
        </li>
      )}
      <li>
        <Link href={sale.edit_path} prefetch>
          <i className="icn">✏</i>
          Edit
        </Link>
      </li>
    </>
  );
}

function SaleActivity({ sale }: ShowProps) {
  return (
    <>
      <Items saleItems={sale.sale_items} />
      <Details sale={sale} />
    </>
  );
}

function canFetchSale(sale: SaleShowRecord) {
  return !!(sale.shopify_name || sale.shopify_id);
}

function storeAdminLabel(sale: SaleShowRecord) {
  return canFetchSale(sale) ? "Shopify" : "WooCommerce";
}
