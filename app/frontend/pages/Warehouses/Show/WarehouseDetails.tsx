import Field from "@/components/Field";
import ImageGallery from "@/components/ImageGallery";
import type { WarehouseShowRecord } from "../types";

export function WarehouseDetails({ warehouse }: { warehouse: WarehouseShowRecord }) {
  return (
    <div className="cards">
      <ImageGallery media={warehouse.media} />
      <WarehouseIdentityCard warehouse={warehouse} />
      <WarehouseLogisticsCard warehouse={warehouse} />
    </div>
  );
}

function WarehouseIdentityCard({ warehouse }: { warehouse: WarehouseShowRecord }) {
  return (
    <dl className="card grow">
      <Field label="Name" value={warehouse.name} />
      <Field label="English External Name (for Clients)" value={warehouse.external_name_en} />
      <Field label="English Description (for Clients)" value={warehouse.desc_en} />
      <Field label="German External Name (for Clients)" value={warehouse.external_name_de} />
      <Field label="German Description (for Clients)" value={warehouse.desc_de} />
    </dl>
  );
}

function WarehouseLogisticsCard({ warehouse }: { warehouse: WarehouseShowRecord }) {
  return (
    <dl className="card grow">
      <Field label="CBM" value={warehouse.cbm} />
      <Field label="Container Tracking Number" value={warehouse.container_tracking_number} />
      <Field label="Courier Tracking URL" value={warehouse.courier_tracking_url}>
        <a
          className="link"
          href={warehouse.courier_tracking_url}
          rel="noopener noreferrer"
          target="_blank"
        >
          {warehouse.courier_tracking_url}
        </a>
      </Field>
      <Field label="Is Default?" value={warehouse.is_default ? "Yes" : "No"} />
      <Field label="Created At" value={warehouse.created_at} />
    </dl>
  );
}
