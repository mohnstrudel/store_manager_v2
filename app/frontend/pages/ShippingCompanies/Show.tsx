import { router } from "@inertiajs/react";
import Button from "@/components/Button";
import FlashMessages from "@/components/FlashMessages";
import Link from "@/components/Link";
import PageHeader from "@/components/PageHeader";
import Details from "./components/Details";
import PurchaseItems from "./components/PurchaseItems";
import { PurchaseItemRecord, ShippingCompanyRecord } from "./types";

type ShowProps = {
  purchaseItems: PurchaseItemRecord[];
  shippingCompany: ShippingCompanyRecord;
};

export default function Show({ purchaseItems, shippingCompany }: ShowProps) {
  function destroyShippingCompany() {
    if (window.confirm("Are you sure?")) {
      router.delete(`/shipping_companies/${shippingCompany.id}`);
    }
  }

  return (
    <>
      <FlashMessages />

      <PageHeader
        actions={
          <li>
            <Link href={`/shipping_companies/${shippingCompany.id}/edit`}>
              <i className="icn">✏</i>
              Edit
            </Link>
          </li>
        }
        subtitle={`Shipping Company ${shippingCompany.id}`}
        title={shippingCompany.name}
      />

      <div className="section-wide flex flex-col gap-8 mt-8">
        <Details shippingCompany={shippingCompany} />
        <PurchaseItems purchaseItems={purchaseItems} />
      </div>

      <Button className="w-full h-12 mt-16" onClick={destroyShippingCompany} variant="danger">
        Destroy this shipping company
      </Button>
    </>
  );
}
