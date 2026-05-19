import { router } from "@inertiajs/react";
import Link from "@/components/Link";
import { SizeRecord } from "../types";

type TableProps = {
  sizes: SizeRecord[];
};

export default function Table({ sizes }: TableProps) {
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
        {sizes.map((size) => (
          <tr
            id={`size_${size.id}`}
            key={size.id}
            onClick={() => router.visit(`/sizes/${size.id}`)}
            tabIndex={0}
          >
            <td>{size.id}</td>
            <td>{size.value}</td>
            <td>{size.created_at}</td>
            <td>{size.updated_at}</td>
            <td className="actions">
              <Link href={`/sizes/${size.id}`} onClick={(event) => event.stopPropagation()}>
                <i className="icn">📄</i>
                Show
              </Link>
              <Link href={`/sizes/${size.id}/edit`} onClick={(event) => event.stopPropagation()}>
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
