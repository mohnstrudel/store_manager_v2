import { Link } from "@inertiajs/react";
import { ChevronsDownIcon, CircleDollarSignIcon, PencilIcon } from "lucide-react";

import { type ProductShowRecord } from "../types";

type ProductActionsProps = {
  product: ProductShowRecord;
};

export default function ProductActions({ product }: ProductActionsProps) {
  return (
    <>
      {canFetchFromShopify(product) && (
        <li>
          <Link href={product.shopify_pull_path} method="post">
            <ChevronsDownIcon />
            Fetch
          </Link>
        </li>
      )}
      <li>
        <Link href={product.new_purchase_path} prefetch>
          <CircleDollarSignIcon />
          New Purchase
        </Link>
      </li>
      <li>
        <Link href={product.edit_path} prefetch>
          <PencilIcon />
          Edit
        </Link>
      </li>
    </>
  );
}

function canFetchFromShopify(product: ProductShowRecord) {
  return product.can_pull_from_shopify && product.shopify_linked;
}
