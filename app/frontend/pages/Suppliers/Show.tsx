import { router } from "@inertiajs/react";
import Button from "@/components/Button";
import FlashMessages from "@/components/FlashMessages";
import Link from "@/components/Link";
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
      <FlashMessages />

      <header className="nav_header">
        <div className="flex gap-4">
          <hgroup>
            <h1>{supplier.title}</h1>
            <h4>Supplier {supplier.id}</h4>
          </hgroup>
        </div>
        <menu className="nav_menu">
          <li>
            <Link href={`/suppliers/${supplier.id}/edit`}>
              <i className="icn">✏</i>
              Edit
            </Link>
          </li>
        </menu>
      </header>

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
