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
    <div className="card grow">
      <h5>Name</h5>
      <p>{warehouse.name}</p>
      <h5>English External Name (for Clients)</h5>
      <p>{warehouse.external_name_en}</p>
      <h5>English Description (for Clients)</h5>
      <p>{warehouse.desc_en}</p>
      <h5>German External Name (for Clients)</h5>
      <p>{warehouse.external_name_de}</p>
      <h5>German Description (for Clients)</h5>
      <p>{warehouse.desc_de}</p>
    </div>
  );
}

function WarehouseLogisticsCard({ warehouse }: { warehouse: WarehouseShowRecord }) {
  return (
    <div className="card grow">
      <h5>CBM</h5>
      <p>{warehouse.cbm}</p>
      <h5>Container Tracking Number</h5>
      <p>{warehouse.container_tracking_number}</p>
      <h5>Courier Tracking URL</h5>
      <p>
        {warehouse.courier_tracking_url ? (
          <a
            className="link"
            href={warehouse.courier_tracking_url}
            rel="noopener noreferrer"
            target="_blank"
          >
            {warehouse.courier_tracking_url}
          </a>
        ) : (
          "-"
        )}
      </p>
      <h5>Is Default?</h5>
      <p>{warehouse.is_default ? "Yes" : "No"}</p>
      <h5>Created At</h5>
      <p>{warehouse.created_at}</p>
    </div>
  );
}
