import { router, Link } from "@inertiajs/react";
import Button from "@/components/Button";
import PageHeader from "@/components/PageHeader";
import Details from "./components/Details";
import Purchases from "./components/Purchases";
import { PurchaseRecord, SupplierRecord } from "./types";

type ShowProps = {
  purchases: PurchaseRecord[];
  supplier: SupplierRecord;
};

export default function Show({ purchases, supplier }: ShowProps) {
  function destroySupplier() {
    if (window.confirm("Are you sure?")) {
      router.delete(`/suppliers/${supplier.id}`);
    }
  }

  return (
    <>
      <PageHeader
        actions={
          <li>
            <Link href={`/suppliers/${supplier.id}/edit`} prefetch>
              <i className="icn">✏</i>
              Edit
            </Link>
          </li>
        }
        subtitle={`Supplier ${supplier.id}`}
        title={supplier.title}
      />

      <div className="section-wide flex flex-col gap-8 mt-8">
        <Details supplier={supplier} />
        <Purchases purchases={purchases} />
      </div>

      <Button className="w-full h-12 mt-16" onClick={destroySupplier} variant="danger">
        Destroy this supplier
      </Button>
    </>
  );
}
