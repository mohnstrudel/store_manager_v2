import { Link } from "@inertiajs/react";
import { ChevronsDownIcon, Link2Icon, PencilIcon, StoreIcon } from "lucide-react";

import type { SaleShowRecord } from "../types";

type SaleActionsProps = {
  sale: SaleShowRecord;
};

export default function SaleActions({ sale }: SaleActionsProps) {
  return (
    <>
      {sale.can_link_purchase_items && (
        <li>
          <Link className="btn_lightblue" href={sale.link_purchase_items_path} method="post">
            <Link2Icon />
            Link with purchases
          </Link>
        </li>
      )}
      {canFetchSale(sale) && (
        <li>
          <Link href={sale.pull_path} method="post">
            <ChevronsDownIcon />
            Fetch
          </Link>
        </li>
      )}
      {sale.shop_admin_url && (
        <li>
          <a href={sale.shop_admin_url} rel="noopener noreferrer" target="_blank">
            <StoreIcon />
            Go to {storeAdminLabel(sale)}
          </a>
        </li>
      )}
      <li>
        <Link href={sale.edit_path} prefetch>
          <PencilIcon />
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
