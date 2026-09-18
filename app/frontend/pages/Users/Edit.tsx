import { Link } from "@inertiajs/react";

import PageHeader from "@/components/PageHeader";
import routes from "@/utils/routes";

import Form, { type UserFormValues } from "./components/Form";

type EditProps = {
  is_admin: boolean;
  role_options: [string, string][];
  user: UserFormValues;
};

export default function Edit({ is_admin, role_options, user }: EditProps) {
  const currentUserPath = routes.users.show.path({ id: user.id });

  return (
    <>
      <PageHeader className="mb-8" title="Edit User">
        <li>
          <Link href={currentUserPath} prefetch>
            <i className="icn">📄</i>
            View User Page
          </Link>
        </li>
      </PageHeader>

      <Form canEditRole={!is_admin} roleOptions={role_options} user={user} />
    </>
  );
}
