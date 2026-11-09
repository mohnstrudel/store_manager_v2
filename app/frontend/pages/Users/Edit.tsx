import { Link } from "@inertiajs/react";
import { FileTextIcon } from "lucide-react";

import PageHeader from "@/components/PageHeader";
import type { UsersEdit } from "@/types/serializers";
import routes from "@/utils/routes";

import Form from "./components/Form";

type EditProps = UsersEdit;

export default function Edit({ is_admin, role_options, user }: EditProps) {
  const currentUserPath = routes.users.show.path({ id: user.id });

  return (
    <>
      <PageHeader className="mb-8" title="Edit User">
        <li>
          <Link href={currentUserPath} prefetch>
            <FileTextIcon />
            View User Page
          </Link>
        </li>
      </PageHeader>

      <Form canEditRole={!is_admin} roleOptions={role_options} user={user} />
    </>
  );
}
