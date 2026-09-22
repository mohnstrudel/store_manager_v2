import { Link } from "@inertiajs/react";

import PageHeader from "@/components/PageHeader";
import routes from "@/utils/routes";

import Form from "./components/Form";
import { ColorRecord } from "./types";

type EditProps = {
  color: ColorRecord;
};

export default function Edit({ color }: EditProps) {
  const currentColorPath =
    color.id === null ? routes.colors.index.path() : routes.colors.show.path({ id: color.id });

  return (
    <>
      <PageHeader className="mb-8" title="Edit Color">
        <li>
          <Link href={currentColorPath} prefetch>
            <i className="icn">📄</i>
            View Color Page
          </Link>
        </li>
      </PageHeader>
      <Form color={color} method="patch" submitLabel="Update Color" url={currentColorPath} />
    </>
  );
}
