import { Link } from "@inertiajs/react";
import { rowNavigationProps, stopRowNavigation } from "@/lib/rowNavigation";

export type UserRecord = {
  id: number;
  email_address: string;
  first_name: string;
  last_name: string;
  role: string;
  created_at: string;
  updated_at: string;
  path: string;
  edit_path: string;
  destroy_path: string;
};

type IndexTableProps = {
  users: UserRecord[];
};

export default function IndexTable({ users }: IndexTableProps) {
  return (
    <table role="grid">
      <thead>
        <tr>
          <th>Email</th>
          <th>First Name</th>
          <th>Last Name</th>
          <th>Role</th>
          <th>Created</th>
          <th>Updated</th>
          <th className="text-right">Actions</th>
        </tr>
      </thead>
      <tbody>
        {users.map((user) => (
          <tr className="hoverable" key={user.id} {...rowNavigationProps(user.path)}>
            <td>{user.email_address}</td>
            <td>{user.first_name}</td>
            <td>{user.last_name}</td>
            <td>{user.role}</td>
            <td>{user.created_at}</td>
            <td>{user.updated_at}</td>
            <td className="table_actions text-right">
              <Link href={user.edit_path} onClick={stopRowNavigation} prefetch>
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
