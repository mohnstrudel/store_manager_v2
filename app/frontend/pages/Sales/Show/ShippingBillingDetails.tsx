import { useCallback, useState } from "react";

import Field from "@/components/Field";
import TipMark from "@/components/TipMark";

import type { SaleAddressRecord, SaleShowRecord } from "../types";

type TabKey = "shipping" | "billing";

export default function ShippingBillingDetails({ sale }: { sale: SaleShowRecord }) {
  const [tab, setTab] = useState<TabKey>("shipping");

  const showShippingTab = useCallback(() => {
    setTab("shipping");
  }, []);

  const showBillingTab = useCallback(() => {
    setTab("billing");
  }, []);

  return (
    <div className="card w-full">
      <div className="tab_bar">
        <button
          aria-selected={tab === "shipping"}
          className="tab_btn"
          data-tab-panel="shipping"
          onClick={showShippingTab}
          type="button"
        >
          Shipping
        </button>
        <button
          aria-selected={tab === "billing"}
          className="tab_btn"
          data-tab-panel="billing"
          onClick={showBillingTab}
          type="button"
        >
          Billing
          {sale.billing_differs_from_shipping && (
            <TipMark size="large" tone="orange">
              Billing address differs from shipping.
            </TipMark>
          )}
        </button>
      </div>

      <dl
        className={tab === "shipping" ? "" : "hidden"}
        data-panel-name="shipping"
        data-tabs-target="panel"
      >
        <AddressPanel address={sale.shipping_address} />
      </dl>

      <dl
        className={tab === "billing" ? "" : "hidden"}
        data-panel-name="billing"
        data-tabs-target="panel"
      >
        <AddressPanel address={sale.billing_address} />
      </dl>
    </div>
  );
}

function AddressPanel({ address }: { address: SaleAddressRecord | null | undefined }) {
  if (!address) {
    return null;
  }

  return (
    <>
      <Field label="Address 1" value={address.address_1} />
      <Field label="Address 2" value={address.address_2} />
      <Field label="City" value={address.city} />
      <Field label="Company" value={address.company} />
      <Field label="Country" value={address.country} />
      <Field label="Phone" value={address.phone} />
      <Field label="Postcode" value={address.postcode} />
      <Field label="State" value={address.state} />
    </>
  );
}
