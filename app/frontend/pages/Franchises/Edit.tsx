import { Link } from "@inertiajs/react";
import PageHeader from "@/components/PageHeader";
import Form from "./components/Form";
import { FranchiseRecord } from "./types";

type EditProps = {
  franchise: FranchiseRecord;
};

export default function Edit({ franchise }: EditProps) {
  return (
    <>
      <PageHeader className="mb-8" title="Edit Franchise">
        <li>
          <Link href={`/franchises/${franchise.id}`} prefetch>
            <i className="icn">📄</i>
            View Franchise Page
          </Link>
        </li>
      </PageHeader>
      <Form
        franchise={franchise}
        method="patch"
        submitLabel="Update Franchise"
        url={`/franchises/${franchise.id}`}
      />
    </>
  );
}
