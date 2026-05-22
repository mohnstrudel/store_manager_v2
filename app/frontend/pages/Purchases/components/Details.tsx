import { Link } from "@inertiajs/react";
import type { PurchaseShowRecord } from "../types";

type DetailsProps = {
  purchase: PurchaseShowRecord;
};

export default function Details({ purchase }: DetailsProps) {
  return (
    <div className="cards">
      {purchase.product_image_url && (
        <img className="product" src={purchase.product_image_url} alt={purchase.product_title} />
      )}

      <div className="card flex grow">
        <div className="flex-1">
          <h5>ID</h5>
          <p>{purchase.id}</p>
          <h5>Qty</h5>
          <p>{purchase.amount}</p>
          <h5>Unit price, $</h5>
          <p className="font-mono">{purchase.item_price}</p>
          <h5>Total price</h5>
          <p className="font-mono">{purchase.cost_total}</p>
          <h5>Shipping</h5>
          <p className="font-mono">{purchase.shipping_total}</p>
        </div>
        <div className="flex-1">
          <h5>Paid</h5>
          <p className="font-mono">{purchase.paid || "0"}</p>
          <h5>Debt</h5>
          <p className="font-mono">-{purchase.debt}</p>
        </div>
      </div>

      <div className="card">
        <h5>Supplier</h5>
        <p>
          <Link className="link" href={purchase.supplier_path}>
            {purchase.supplier_title}
          </Link>
        </p>
        <h5>Order reference</h5>
        <p>{purchase.order_reference}</p>
        <h5>Date</h5>
        <p>{purchase.date}</p>
      </div>
    </div>
  );
}
