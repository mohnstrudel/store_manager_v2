import { useCallback, useState } from "react";
import { Link } from "@inertiajs/react";
import TipMark from "@/components/TipMark";
import type { SaleAddressRecord, SaleShowRecord } from "../types";

type DetailsProps = {
  sale: SaleShowRecord;
};

type TabKey = "shipping" | "billing";

export default function Details({ sale }: DetailsProps) {
  const [tab, setTab] = useState<TabKey>("shipping");

  const showShippingTab = useCallback(() => {
    setTab("shipping");
  }, []);

  const showBillingTab = useCallback(() => {
    setTab("billing");
  }, []);

  return (
    <div className="cards items-start">
      <div className="card w-2/3">
        <h5>E-Commerce Order Status</h5>
        <p>{formatStatus(sale.status)}</p>
        <h5>Email</h5>
        {sale.customer.email ? <p>{sale.customer.email}</p> : null}
        {sale.customer.shopify_id_short && (
          <>
            <h5>Customer Shop ID</h5>
            <p>
              <a className="link" href={sale.customer.shop_admin_url}>
                {sale.customer.shopify_id_short}
              </a>
            </p>
          </>
        )}
        <h5>Customer</h5>
        {sale.customer.full_name ? (
          <p>
            <Link className="link" href={sale.customer.path} prefetch>
              {sale.customer.full_name}
            </Link>
          </p>
        ) : null}
        <h5>Note</h5>
        {sale.note ? <p>{sale.note}</p> : null}
        <h5>Total, $</h5>
        {sale.total != null ? <p className="fit font-mono">{sale.total}</p> : null}
        <h5>Discount</h5>
        {sale.discount_total != null ? (
          <p className="fit font-mono">{sale.discount_total}</p>
        ) : null}
        <h5>Shipping</h5>
        {sale.shipping_total != null ? (
          <p className="fit font-mono">{sale.shipping_total}</p>
        ) : null}
      </div>

      <div className="card w-1/3">
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
              <TipMark starClassName="text-xl leading-0">
                Billing address differs from shipping.
              </TipMark>
            )}
          </button>
        </div>

        <div
          className={tab === "shipping" ? "" : "hidden"}
          data-panel-name="shipping"
          data-tabs-target="panel"
        >
          <AddressPanel address={sale.shipping_address} />
        </div>

        <div
          className={tab === "billing" ? "" : "hidden"}
          data-panel-name="billing"
          data-tabs-target="panel"
        >
          <AddressPanel address={sale.billing_address} />
        </div>
      </div>

      <div className="card">
        <h5>ID</h5>
        <p>{sale.id}</p>
        <h5>Shop Created</h5>
        {sale.created_at ? <p>{sale.created_at}</p> : null}
        <h5>Shop Updated</h5>
        {sale.updated_at ? <p>{sale.updated_at}</p> : null}
        {sale.shopify_id_short && (
          <>
            <h5>Order Shop ID</h5>
            <p>
              <a className="link" href={sale.shop_admin_url}>
                {sale.shopify_id_short}
              </a>
            </p>
          </>
        )}
      </div>
    </div>
  );
}

function AddressPanel({ address }: { address: SaleAddressRecord | null }) {
  if (!address) {
    return null;
  }

  return (
    <>
      {address.address_1 ? (
        <>
          <h5>Address 1</h5>
          <p>{address.address_1}</p>
        </>
      ) : null}
      {address.address_2 && (
        <>
          <h5>Address 2</h5>
          <p>{address.address_2}</p>
        </>
      )}
      {address.city ? (
        <>
          <h5>City</h5>
          <p>{address.city}</p>
        </>
      ) : null}
      {address.company && (
        <>
          <h5>Company</h5>
          <p>{address.company}</p>
        </>
      )}
      {address.country ? (
        <>
          <h5>Country</h5>
          <p>{address.country}</p>
        </>
      ) : null}
      {address.phone ? (
        <>
          <h5>Phone</h5>
          <p>{address.phone}</p>
        </>
      ) : null}
      {address.postcode ? (
        <>
          <h5>Postcode</h5>
          <p>{address.postcode}</p>
        </>
      ) : null}
      {address.state && (
        <>
          <h5>State</h5>
          <p>{address.state}</p>
        </>
      )}
    </>
  );
}

function formatStatus(status: string) {
  return status
    .split("-")
    .map((word) => word.charAt(0).toUpperCase() + word.slice(1))
    .join(" ");
}
