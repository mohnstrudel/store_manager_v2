import { router, Link } from "@inertiajs/react";
import Button from "@/components/Button";
import Details from "./components/Details";
import Payments from "./components/Payments";
import PurchaseItems from "./components/PurchaseItems";
import type {
  NewPaymentRecord,
  PaymentRecord,
  PurchaseItemRecord,
  PurchaseShowRecord,
  WarehouseOption,
} from "./types";

type ShowProps = {
  new_payment: NewPaymentRecord;
  payments: PaymentRecord[];
  purchase: PurchaseShowRecord;
  purchase_items: PurchaseItemRecord[];
  warehouse_move_path: string;
  warehouses: WarehouseOption[];
};

export default function Show({
  new_payment,
  payments,
  purchase,
  purchase_items,
  warehouse_move_path,
  warehouses,
}: ShowProps) {
  function destroyPurchase() {
    if (window.confirm("Are you sure?")) {
      router.delete(purchase.destroy_path);
    }
  }

  return (
    <>
      <header className="nav_header">
        <div className="flex gap-4">
          <hgroup>
            <h1>
              <i className="icn mr-2">💰</i>
              Purchase {purchase.id}
            </h1>
          </hgroup>
        </div>
        <menu className="nav_menu">
          <li>
            <Link href={purchase.edit_path} prefetch>
              <i className="icn">✏</i>
              Edit
            </Link>
          </li>
        </menu>
      </header>

      <div className="section-wide flex flex-col gap-8">
        <PurchaseItems
          movePath={warehouse_move_path}
          purchase={purchase}
          purchaseItems={purchase_items}
          warehouses={warehouses}
        />
        <Details purchase={purchase} />
        <Payments newPayment={new_payment} payments={payments} purchase={purchase} />
      </div>

      <Button className="w-full h-12 mt-16" onClick={destroyPurchase} variant="danger">
        Destroy this purchase
      </Button>
    </>
  );
}
