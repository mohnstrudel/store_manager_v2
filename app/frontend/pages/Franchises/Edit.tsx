import ErrorNotice from "@/components/ErrorNotice";
import Link from "@/components/Link";
import PageHeader from "@/components/PageHeader";
import Form from "./components/Form";
import { FranchiseErrors, FranchiseRecord } from "./types";

type EditProps = {
  errors?: FranchiseErrors;
  franchise: FranchiseRecord;
};

export default function Edit({ errors = {}, franchise }: EditProps) {
  return (
    <>
      <ErrorNotice errors={errors} />

      <PageHeader
        actions={
          <li>
            <Link href={`/franchises/${franchise.id}`}>
              <i className="icn">📄</i>
              View Franchise Page
            </Link>
          </li>
        }
        className="mb-8"
        title="Edit Franchise"
      />

      <Form
        errors={errors}
        franchise={franchise}
        method="patch"
        submitLabel="Update Franchise"
        url={`/franchises/${franchise.id}`}
      />
    </>
  );
}
