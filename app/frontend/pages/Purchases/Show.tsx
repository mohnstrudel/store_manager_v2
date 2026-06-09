import { useMemo } from "react";
import { Link } from "@inertiajs/react";
import Button from "@/components/Button";
import PageHeader from "@/components/PageHeader";
import { useConfirmAction } from "@/utils/useConfirmAction";
import Details from "./Show/Details";
import Payments from "./Show/Payments";
import PurchaseItems from "./Show/PurchaseItems";
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
  const destroyPurchase = useConfirmAction("delete", purchase.destroy_path);

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
        <PurchaseItems
          movePath={warehouse_move_path}
          purchase={purchase}
          purchaseItems={purchase_items}
          shippingCompanies={shipping_companies}
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

function PurchaseTitle({ id }: { id: number }) {
  return (
    <>
      <i className="icn mr-2">💰</i>
      Purchase {id}
    </>
  );
}
