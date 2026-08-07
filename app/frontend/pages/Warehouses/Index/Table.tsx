import { Link } from "@inertiajs/react";
import type { ChangeEvent } from "react";
import TipMark from "@/components/TipMark";
import { rowNavigationProps, stopRowNavigation } from "@/utils/rowNavigation";
import PaymentProgressBar from "@/components/PaymentProgressBar";
import type { PaymentProgress } from "@/types/payment";

export type WarehouseRecord = {
  id: number;
  path: string;
  edit_path: string;
  position_path: string;
  position: number;
  positions: number[];
  name: string;
  is_default: boolean;
  external_name_en: string;
  cbm: string;
  purchase_items_count: number;
  has_purchase_items: boolean;
  payment_progress: PaymentProgress;
};

type IndexTableProps = {
  onPositionChange: (event: ChangeEvent<HTMLSelectElement>) => void;
  warehouses: WarehouseRecord[];
};

export default function IndexTable({ onPositionChange, warehouses }: IndexTableProps) {
  return (
    <table role="grid">
      <thead>
        <tr>
          <th>Position</th>
          <th>
            Name <span className="font-normal text-sm pl-4">+ External Name for Clients</span>
          </th>
          <th>CBM</th>
          <th>Products</th>
          <th>Payment Progress</th>
          <th className="text-right">Actions</th>
        </tr>
      </thead>
      <tbody>
        {warehouses.map((warehouse) => (
          <tr className="hoverable" key={warehouse.id} {...rowNavigationProps(warehouse.path)}>
            <td className="text-right w-6">
              <select
                aria-label={`Position for ${warehouse.name}`}
                data-position-path={warehouse.position_path}
                name="position"
                onChange={onPositionChange}
                onClick={stopRowNavigation}
                suppressHydrationWarning
                value={warehouse.position}
              >
                {warehouse.positions.map((position) => (
                  <option key={position} value={position}>
                    {position}
                  </option>
                ))}
              </select>
            </td>
            <td>
              <strong>{warehouse.name}</strong>
              {warehouse.is_default && (
                <TipMark tone="orange">
                  New purchases go to this warehouse by default. Change it on the edit page.
                </TipMark>
              )}
              <p>{warehouse.external_name_en}</p>
            </td>
            <td>{warehouse.cbm}</td>
            <td>{warehouse.purchase_items_count}</td>
            <td className={warehouse.has_purchase_items ? "w-full max-w-45 lg:w-45" : ""}>
              {warehouse.has_purchase_items ? (
                <PaymentProgressBar onlyDebt progress={warehouse.payment_progress} />
              ) : null}
            </td>
            <td className="table_actions text-right">
              <Link href={warehouse.edit_path} onClick={stopRowNavigation} prefetch>
                <i className="icn">✏</i>
                Edit
              </Link>
            </td>
          </tr>
        ))}
      </tbody>
    </table>
  );
}
