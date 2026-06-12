import { Link } from "@inertiajs/react";
import Button from "@/components/Button";
import PageHeader from "@/components/PageHeader";
import { useConfirmAction } from "@/utils/useConfirmAction";
import Details from "./components/Details";
import PurchaseItems from "./components/PurchaseItems";
import { PurchaseItemRecord, ShippingCompanyRecord } from "./types";

type ShowProps = {
  purchaseItems: PurchaseItemRecord[];
  shippingCompany: ShippingCompanyRecord;
};

export default function Show({ purchaseItems, shippingCompany }: ShowProps) {
  const destroyShippingCompany = useConfirmAction(
    "delete",
    `/shipping_companies/${shippingCompany.id}`,
  );

  return (
    <>
      <PageHeader subtitle={`Shipping Company ${shippingCompany.id}`} title={shippingCompany.name}>
        <li>
          <Link href={`/shipping_companies/${shippingCompany.id}/edit`} prefetch>
            <i className="icn">✏</i>
            Edit
          </Link>
        </li>
      </PageHeader>

      <div className="section_wide flex flex-col gap-8 mt-8">
        <Details shippingCompany={shippingCompany} />
        <PurchaseItems purchaseItems={purchaseItems} />
      </div>

      <Button className="w-full h-12 mt-16" onClick={destroyShippingCompany} variant="danger">
        Destroy this shipping company
      </Button>
    </>
  );
}
