import { Link } from "@inertiajs/react";

import ErrorNotice from "@/components/ErrorNotice";
import PageHeader from "@/components/PageHeader";
import routes from "@/utils/routes";

import Form from "./components/Form";
import { SizeRecord } from "./types";

type EditProps = {
  size: SizeRecord;
};

export default function Edit({ size }: EditProps) {
  const currentSizePath =
    size.id === null ? routes.sizes.index.path() : routes.sizes.show.path({ id: size.id });

  return (
    <>
      <ErrorNotice />

      <PageHeader className="mb-8" title="Edit Size">
        <li>
          <Link href={currentSizePath} prefetch>
            <i className="icn">📄</i>
            View Size Page
          </Link>
        </li>
      </PageHeader>

      <Form method="patch" size={size} submitLabel="Update Size" url={currentSizePath} />
    </>
  );
}
