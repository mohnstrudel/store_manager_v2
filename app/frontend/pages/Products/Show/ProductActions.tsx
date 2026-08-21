import { ChevronDoubleDownIcon } from "@heroicons/react/20/solid";
import { Link } from "@inertiajs/react";

import { type ProductShowRecord } from "../types";

type ProductActionsProps = {
  product: ProductShowRecord;
};

export default function ProductActions({ product }: ProductActionsProps) {
  return (
    <>
      {canFetchFromShopify(product) && (
        <li>
          <Link className="btn_rounded" href={product.shopify_pull_path} method="post">
            <ChevronDoubleDownIcon height={20} width={20} />
            Fetch
          </Link>
        </li>
      )}
      <li>
        <Link href={product.new_purchase_path} prefetch>
          <i className="icn">💰</i>
          New Purchase
        </Link>
      </li>
      <li>
        <Link href={product.edit_path} prefetch>
          <i className="icn">✏</i>
          Edit
        </Link>
      </li>
    </>
  );
}

function canFetchFromShopify(product: ProductShowRecord) {
  return product.can_pull_from_shopify && product.shopify_linked;
}
