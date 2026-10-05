import { Link } from "@inertiajs/react";

import PageHeader from "@/components/PageHeader";
import routes from "@/utils/routes";

import Form from "./components/Form";
import { FranchiseRecord } from "./types";

type EditProps = {
  franchise: FranchiseRecord;
};

export default function Edit({ franchise }: EditProps) {
  const currentFranchisePath =
    franchise.id === null
      ? routes.franchises.index.path()
      : routes.franchises.show.path({ id: franchise.id });

  return (
    <>
      <PageHeader className="mb-8" title="Edit Franchise">
        <li>
          <Link href={currentFranchisePath} prefetch>
            <i className="icn">📄</i>
            View Franchise Page
          </Link>
        </li>
      </PageHeader>
      <Form
        franchise={franchise}
        method="patch"
        submitLabel="Update Franchise"
        url={currentFranchisePath}
      />
    </>
  );
}
