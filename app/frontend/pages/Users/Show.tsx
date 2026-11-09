import { Link } from "@inertiajs/react";
import { PencilIcon } from "lucide-react";

import Button from "@/components/Button";
import type { UsersShow } from "@/types/serializers";
import routes from "@/utils/routes";
import { useConfirmAction } from "@/utils/useConfirmAction";

type ShowProps = UsersShow;

export default function Show({ user }: ShowProps) {
  const currentUserPath = routes.users.show.path({ id: user.id });
  const currentEditPath = routes.users.edit.path({ id: user.id });
  const destroyUser = useConfirmAction("delete", currentUserPath);

  return (
    <>
      <header className="nav_header">
        <hgroup>
          <h1>{user.email_address}</h1>
        </hgroup>
        <menu className="nav_menu">
          <li>
            <Link href={currentEditPath} prefetch>
              <PencilIcon />
              Edit
            </Link>
          </li>
        </menu>
      </header>

      <section className="section_wide section_border_base">
        <table>
          <thead>
            <tr>
              <th>ID</th>
              <th>Email</th>
              <th>First Name</th>
              <th>Last Name</th>
              <th>Role</th>
              <th>Created</th>
              <th>Updated</th>
            </tr>
          </thead>
          <tbody>
            <tr>
              <td>{user.id}</td>
              <td>{user.email_address}</td>
              <td>{user.first_name}</td>
              <td>{user.last_name}</td>
              <td>{user.role}</td>
              <td>{user.created_at}</td>
              <td>{user.updated_at}</td>
            </tr>
          </tbody>
        </table>
      </section>

      <Button className="w-full h-12 mt-16" onClick={destroyUser} variant="danger">
        Destroy this user
      </Button>
    </>
  );
}
