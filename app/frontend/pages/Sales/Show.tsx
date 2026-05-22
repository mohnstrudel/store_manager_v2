import { ChevronDoubleDownIcon } from "@heroicons/react/20/solid";
import { BuildingStorefrontIcon } from "@heroicons/react/24/outline";
import { Link } from "@inertiajs/react";
import Details from "./components/Details";
import Items from "./components/Items";
import type { SaleShowRecord } from "./types";

type ShowProps = {
  sale: SaleShowRecord;
};

export default function Show({ sale }: ShowProps) {
  return (
    <>
      <header className="nav_header">
        <div className="flex gap-4">
          <hgroup>
            {sale.shopify_name || sale.shopify_id ? (
              <h1>
                <span className="inline-block icon-shopify w-13 h-13 mr-3 -mb-1" />
                Sale {sale.shop_identifier}
              </h1>
            ) : sale.woo_store_id ? (
              <h1>
                <span className="inline-block icon-woo w-17 h-17 mr-4 -mb-4" />
                Sale {sale.woo_store_id}
              </h1>
            ) : (
              <h1>Sale {sale.id}</h1>
            )}
          </hgroup>
        </div>

        <menu className="nav_menu">
          {sale.can_link_purchase_items && (
            <li>
              <Link
                className="btn-rounded btn-lightblue"
                href={sale.link_purchase_items_path}
                method="post"
              >
                <i className="icn">🔗</i>
                Link with purchases
              </Link>
            </li>
          )}
          {sale.shopify_name || sale.shopify_id ? (
            <li>
              <Link className="btn-rounded" href={sale.pull_path} method="post">
                <ChevronDoubleDownIcon height={20} width={20} />
                Fetch
              </Link>
            </li>
          ) : null}
          {sale.shop_admin_url ? (
            <li>
              <a
                href={sale.shop_admin_url}
                rel="noopener noreferrer"
                target="_blank"
                className="no-events"
              >
                <BuildingStorefrontIcon height={20} width={20} />
                Go to {sale.shopify_name || sale.shopify_id ? "Shopify" : "WooCommerce"}
              </a>
            </li>
          ) : null}
          <li>
            <Link href={sale.edit_path} prefetch>
              <i className="icn">✏</i>
              Edit
            </Link>
          </li>
        </menu>
      </header>

      <div className="section-wide flex flex-col gap-8 mt-8">
        <Items saleItems={sale.sale_items} />
        <Details sale={sale} />
      </div>
    </>
  );
}
