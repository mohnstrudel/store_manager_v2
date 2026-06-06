import { Link } from "@inertiajs/react";
import Button from "@/components/Button";
import PageHeader from "@/components/PageHeader";
import { useConfirmAction } from "@/lib/useConfirmAction";
import Details from "./components/Details";
import Purchases from "./components/Purchases";
import { PurchaseRecord, SupplierRecord } from "./types";

type ShowProps = {
  purchases: PurchaseRecord[];
  supplier: SupplierRecord;
};

export default function Show({ purchases, supplier }: ShowProps) {
  const destroySupplier = useConfirmAction("delete", `/suppliers/${supplier.id}`);

  return (
    <>
      <PageHeader subtitle={`Supplier ${supplier.id}`} title={supplier.title}>
        <li>
          <Link href={`/suppliers/${supplier.id}/edit`} prefetch>
            <i className="icn">✏</i>
            Edit
          </Link>
        </li>
      </PageHeader>

      <div className="section_wide flex flex-col gap-8 mt-8">
        <Details supplier={supplier} />
        <Purchases purchases={purchases} />
      </div>

      <Button className="w-full h-12 mt-16" onClick={destroySupplier} variant="danger">
        Destroy this supplier
      </Button>
    </>
  );
}
