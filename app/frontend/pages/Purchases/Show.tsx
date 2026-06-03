import { useMemo } from "react";
import { Link } from "@inertiajs/react";
import Button from "@/components/Button";
import PageHeader from "@/components/PageHeader";
import { useConfirmedDestroy } from "@/lib/useConfirmedDestroy";
import Details from "./components/Details";
import Payments from "./components/Payments";
import PurchaseItems from "./components/PurchaseItems";
import type {
  NewPaymentRecord,
  PaymentRecord,
  PurchaseItemRecord,
  PurchaseShowRecord,
  ShippingCompanyOption,
  WarehouseOption,
} from "./types";

type ShowProps = {
  new_payment: NewPaymentRecord;
  payments: PaymentRecord[];
  purchase: PurchaseShowRecord;
  purchase_items: PurchaseItemRecord[];
  shipping_companies: ShippingCompanyOption[];
  warehouse_move_path: string;
  warehouses: WarehouseOption[];
};

export default function Show({
  new_payment,
  payments,
  purchase,
  purchase_items,
  shipping_companies,
  warehouse_move_path,
  warehouses,
}: ShowProps) {
  const destroyPurchase = useConfirmedDestroy(purchase.destroy_path);

  const title = useMemo(() => <PurchaseTitle id={purchase.id} />, [purchase.id]);

  return (
    <>
      <PageHeader title={title}>
        <li>
          <Link href={purchase.edit_path} prefetch>
            <i className="icn">✏</i>
            Edit
          </Link>
        </li>
      </PageHeader>

      <div className="section_wide flex flex-col gap-8">
        <PurchaseActivity
          newPayment={new_payment}
          payments={payments}
          purchase={purchase}
          purchaseItems={purchase_items}
          shippingCompanies={shipping_companies}
          warehouseMovePath={warehouse_move_path}
          warehouses={warehouses}
        />
      </div>

      <Button className="w-full h-12 mt-16" onClick={destroyPurchase} variant="danger">
        Destroy this purchase
      </Button>
    </>
  );
}

function PurchaseTitle({ id }: { id: number }) {
  return (
    <>
      <i className="icn mr-2">💰</i>
      Purchase {id}
    </>
  );
}

type PurchaseActivityProps = {
  newPayment: NewPaymentRecord;
  payments: PaymentRecord[];
  purchase: PurchaseShowRecord;
  purchaseItems: PurchaseItemRecord[];
  shippingCompanies: ShippingCompanyOption[];
  warehouseMovePath: string;
  warehouses: WarehouseOption[];
};

function PurchaseActivity({
  newPayment,
  payments,
  purchase,
  purchaseItems,
  shippingCompanies,
  warehouseMovePath,
  warehouses,
}: PurchaseActivityProps) {
  return (
    <>
      <PurchaseItems
        movePath={warehouseMovePath}
        purchase={purchase}
        purchaseItems={purchaseItems}
        shippingCompanies={shippingCompanies}
        warehouses={warehouses}
      />
      <Details purchase={purchase} />
      <Payments newPayment={newPayment} payments={payments} purchase={purchase} />
    </>
  );
}
