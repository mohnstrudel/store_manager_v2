import { router, Link } from "@inertiajs/react";
import type { ChangeEvent, MouseEvent } from "react";
import { rowNavigationProps } from "@/lib/rowNavigation";
import PaymentProgressBar from "@/pages/Purchases/components/PaymentProgressBar";
import type { PaymentProgress } from "@/pages/Purchases/types";

type WarehouseRecord = {
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

type IndexProps = {
  warehouses: WarehouseRecord[];
};

export default function Index({ warehouses }: IndexProps) {
  function stopRowNavigation(event: MouseEvent | ChangeEvent<HTMLSelectElement>) {
    event.stopPropagation();
  }

  function updatePosition(warehouse: WarehouseRecord, event: ChangeEvent<HTMLSelectElement>) {
    stopRowNavigation(event);
    router.patch(warehouse.position_path, { position: event.target.value });
  }

  return (
    <>
      <header className="nav_header">
        <hgroup>
          <h1>Warehouses</h1>
        </hgroup>
        <menu className="nav_menu">
          <li>
            <Link href="/warehouses/new" prefetch>
              <i className="icn">🐣</i>
              Add New Record
            </Link>
          </li>
        </menu>
      </header>

      <section className="section-border-base section-wide">
        <table role="grid">
          <thead>
            <tr>
              <th>Position</th>
              <th>Name</th>
              <th>External Name</th>
              <th>CBM</th>
              <th>Items</th>
              <th>Payment Progress</th>
              <th className="text-right">Actions</th>
            </tr>
          </thead>
          <tbody>
            {warehouses.map((warehouse) => (
              <tr className="hoverable" key={warehouse.id} {...rowNavigationProps(warehouse.path)}>
                <td>
                  <select
                    aria-label={`Position for ${warehouse.name}`}
                    name="position"
                    onChange={(event) => updatePosition(warehouse, event)}
                    onClick={stopRowNavigation}
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
                    <span className="ml-2 text-sm text-blue-500">Default</span>
                  )}
                </td>
                <td>{warehouse.external_name_en}</td>
                <td>{warehouse.cbm}</td>
                <td>{warehouse.purchase_items_count}</td>
                <td className="min-w-44">
                  {warehouse.has_purchase_items ? (
                    <PaymentProgressBar onlyDebt progress={warehouse.payment_progress} />
                  ) : (
                    "-"
                  )}
                </td>
                <td className="actions text-right">
                  <Link href={warehouse.edit_path} onClick={stopRowNavigation} prefetch>
                    <i className="icn">✏</i>
                    Edit
                  </Link>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </section>
    </>
  );
}
