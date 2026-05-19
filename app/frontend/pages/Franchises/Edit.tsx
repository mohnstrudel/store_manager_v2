import ErrorNotice from "@/components/ErrorNotice";
import Link from "@/components/Link";
import Form from "./components/Form";
import { FranchiseErrors, FranchiseRecord } from "./types";

type EditProps = {
  errors: FranchiseErrors;
  franchise: FranchiseRecord;
};

export default function Edit({ errors, franchise }: EditProps) {
  return (
    <>
      <ErrorNotice errors={errors} />

      <header className="nav_header mb-8">
        <div className="flex gap-4">
          <h1>Edit Franchise</h1>
        </div>
        <menu className="nav_menu">
          <li>
            <Link href={`/franchises/${franchise.id}`}>
              <i className="icn">📄</i>
              View Franchise Page
            </Link>
          </li>
        </menu>
      </header>

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
