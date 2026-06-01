import { Link } from "@inertiajs/react";
import ZoomableThumbnail from "@/components/ZoomableThumbnail";
import { rowNavigationProps, stopRowNavigation } from "@/lib/rowNavigation";
import type { ProductIndexRecord } from "../types";

type IndexTableProps = {
  products: ProductIndexRecord[];
};

export default function IndexTable({ products }: IndexTableProps) {
  return (
    <table>
      <thead>
        <tr>
          <th className="text-center">Image</th>
          <th>Full name + Variants</th>
          <th>Woo ID</th>
          <th>Shopify ID</th>
          <th className="text-right">Actions</th>
        </tr>
      </thead>
      <tbody>
        {products.map((product) => (
          <tr className="hoverable" key={product.id} {...rowNavigationProps(product.path)}>
            <td className="text-center">
              <ZoomableThumbnail
                alt={product.title}
                key={`${product.id}-${product.thumb_url ?? "missing"}`}
                src={product.thumb_url}
              />
            </td>
            <td>
              <span>{product.full_title}</span>
              {product.variants.length > 0 && (
                <ul className="ml-4 mt-2">
                  {product.variants.map((variant) => (
                    <li className="mt-1" key={variant.id}>
                      {variant.title}
                    </li>
                  ))}
                </ul>
              )}
            </td>
            <td>{product.woo_store_id || "—"}</td>
            <td>{product.shopify_id_short || "—"}</td>
            <td className="actions text-right" onClick={stopRowNavigation}>
              <Link href={product.edit_path} prefetch>
                <i className="icn">✏</i>
                Edit
              </Link>
              <Link href={product.new_purchase_path} prefetch>
                <i className="icn">💰</i>
                Purchase
              </Link>
            </td>
          </tr>
        ))}
      </tbody>
    </table>
  );
}
