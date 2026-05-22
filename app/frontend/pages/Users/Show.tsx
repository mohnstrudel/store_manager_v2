import { router, Link } from "@inertiajs/react";
import Button from "@/components/Button";

type UserRecord = {
  id: number;
  email_address: string;
  first_name: string;
  last_name: string;
  role: string;
  created_at: string;
  updated_at: string;
  edit_path: string;
  destroy_path: string;
};

type ShowProps = {
  user: UserRecord;
};

export default function Show({ user }: ShowProps) {
  function destroyUser() {
    if (window.confirm("Are you sure?")) {
      router.delete(user.destroy_path);
    }
  }

  return (
    <>
      <header className="nav_header">
        <hgroup>
          <h1>{user.email_address}</h1>
        </hgroup>
        <menu className="nav_menu">
          <li>
            <Link href={user.edit_path}>
              <i className="icn">✏</i>
              Edit
            </Link>
          </li>
        </menu>
      </header>

      <main>
        <table className="vertical" role="grid">
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
      </main>

      <Button className="w-full h-12 mt-16" onClick={destroyUser} variant="danger">
        Destroy this user
      </Button>
    </>
  );
}
