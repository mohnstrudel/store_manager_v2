import { ChevronDoubleDownIcon } from "@heroicons/react/20/solid";
import { BuildingStorefrontIcon } from "@heroicons/react/24/outline";
import { Link } from "@inertiajs/react";
import type { SaleShowRecord } from "../types";

type SaleActionsProps = {
  sale: SaleShowRecord;
};

export default function SaleActions({ sale }: SaleActionsProps) {
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

function canFetchSale(sale: SaleShowRecord) {
  return !!(sale.shopify_name || sale.shopify_id);
}

function storeAdminLabel(sale: SaleShowRecord) {
  return canFetchSale(sale) ? "Shopify" : "WooCommerce";
}
