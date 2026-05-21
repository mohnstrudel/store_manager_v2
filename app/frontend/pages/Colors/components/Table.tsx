import { router } from "@inertiajs/react";
import type { KeyboardEvent, MouseEvent } from "react";
import Link from "@/components/Link";
import { ColorRecord } from "../types";

type TableProps = {
  colors: ColorRecord[];
};

export default function Table({ colors }: TableProps) {
  function visitColor(color: ColorRecord) {
    router.visit(`/colors/${color.id}`);
  }

  function handleKeyDown(color: ColorRecord, event: KeyboardEvent<HTMLTableRowElement>) {
    if (event.key !== "Enter" && event.key !== " ") return;

    event.preventDefault();
    visitColor(color);
  }

  function stopRowNavigation(event: MouseEvent) {
    event.stopPropagation();
  }

  return (
    <table role="grid">
      <thead>
        <tr>
          <th>ID</th>
          <th>Value</th>
          <th>Created</th>
          <th>Updated</th>
          <th className="text-right">Actions</th>
        </tr>
      </thead>
      <tbody>
        {colors.map((color) => (
          <tr
            className="hoverable"
            key={color.id}
            onClick={() => visitColor(color)}
            onKeyDown={(event) => handleKeyDown(color, event)}
            tabIndex={0}
          >
            <td>{color.id}</td>
            <td>{color.value}</td>
            <td>{color.created_at}</td>
            <td>{color.updated_at}</td>
            <td className="actions text-right">
              <div className="flex flex-wrap justify-end gap-3">
                <Link href={`/colors/${color.id}`} onClick={stopRowNavigation}>
                  <i className="icn">📄</i>
                  Show
                </Link>
                <Link href={`/colors/${color.id}/edit`} onClick={stopRowNavigation}>
                  <i className="icn">✏</i>
                  Edit
                </Link>
              </div>
            </td>
          </tr>
        ))}
      </tbody>
    </table>
  );
}
