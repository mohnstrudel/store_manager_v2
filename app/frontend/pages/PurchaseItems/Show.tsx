import { Link } from "@inertiajs/react";
import Button from "@/components/Button";
import ImageGallery from "@/components/ImageGallery";
import { useConfirmedDestroy } from "@/lib/useConfirmedDestroy";
import type { PurchaseItemShowRecord } from "./types";

type ShowProps = {
  purchase_item: PurchaseItemShowRecord;
};

export default function Show({ purchase_item }: ShowProps) {
  const destroyPurchaseItem = useConfirmedDestroy(purchase_item.destroy_path);

  return (
    <>
      <header className="nav_header">
        <div className="flex gap-4">
          <h1>
            <i className="icn mr-2">📦</i>
            Purchase Item {purchase_item.id}
          </h1>
        </div>
        <menu className="nav_menu">
          <li>
            <Link href={purchase_item.purchase_path} prefetch>
              <i className="icn">💰</i>
              Purchase
            </Link>
          </li>
          {purchase_item.sale_path && (
            <li>
              <Link href={purchase_item.sale_path} prefetch>
                <i className="icn">🛒</i>
                Sale
              </Link>
            </li>
          )}
          {purchase_item.sale_item_path && (
            <li>
              <Link href={purchase_item.sale_item_path} prefetch>
                Sale Item
              </Link>
            </li>
          )}
          <li>
            <Link href={purchase_item.edit_path} prefetch>
              <i className="icn">✏</i>
              Edit
            </Link>
          </li>
        </menu>
      </header>

      <div className="section_wide">
        <div className="cards">
          <ImageGallery media={purchase_item.media} />
          <div className="card grow">
            <h5>Supplier</h5>
            <p>
              <Link className="link" href={purchase_item.supplier_path} prefetch>
                {purchase_item.supplier_title}
              </Link>
            </p>
            <h5>Product</h5>
            <p>
              <Link className="link" href={purchase_item.product_path} prefetch>
                {purchase_item.product_title}
              </Link>
            </p>
            <h5>Current Warehouse</h5>
            <p>
              <Link className="link" href={purchase_item.warehouse_path} prefetch>
                {purchase_item.warehouse_name}
              </Link>
            </p>
            <h5>Expenses</h5>
            <p className="font-mono">{purchase_item.expenses}</p>
            <h5>Shipping</h5>
            <p className="font-mono">{purchase_item.shipping_cost}</p>
            <h5>Tracking Number</h5>
            <p>{purchase_item.tracking_number}</p>
            <h5>Shipping Company</h5>
            <p>{purchase_item.shipping_company_name}</p>
          </div>
          <div className="card">
            <h5>Length, cm</h5>
            <p>{purchase_item.length}</p>
            <h5>Width, cm</h5>
            <p>{purchase_item.width}</p>
            <h5>Height, cm</h5>
            <p>{purchase_item.height}</p>
            <h5>Weight, kg</h5>
            <p>{purchase_item.weight}</p>
            <h5>Created at</h5>
            <p>{purchase_item.created_at}</p>
            <h5>Updated at</h5>
            <p>{purchase_item.updated_at}</p>
          </div>
          {purchase_item.warehouse_movements.length > 0 && (
            <div className="card">
              <table className="vertical thead_static" role="grid">
                <thead>
                  <tr>
                    <th>Moved in</th>
                    <th>Warehouse</th>
                  </tr>
                </thead>
                <tbody>
                  {purchase_item.warehouse_movements.map((movement) => (
                    <tr key={movement.id}>
                      <td>{movement.moved_in}</td>
                      <td>
                        {movement.warehouse_path ? (
                          <Link className="link" href={movement.warehouse_path} prefetch>
                            {movement.warehouse_name}
                          </Link>
                        ) : (
                          "-"
                        )}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </div>
      </div>

      <Button className="w-full h-12 mt-16" onClick={destroyPurchaseItem} variant="danger">
        Destroy this purchase item
      </Button>
    </>
  );
}
