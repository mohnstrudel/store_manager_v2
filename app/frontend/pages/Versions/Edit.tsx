import { Link } from "@inertiajs/react";
import PageHeader from "@/components/PageHeader";
import Form from "./components/Form";
import { VersionRecord } from "./types";

type EditProps = {
  version: VersionRecord;
};

export default function Edit({ version }: EditProps) {
  return (
    <>
      <PageHeader className="mb-8" title="Edit Version">
        <li>
          <Link href={`/versions/${version.id}`} prefetch>
            <i className="icn">📄</i>
            View Version Page
          </Link>
        </li>
      </PageHeader>

      <Form
        method="patch"
        submitLabel="Update Version"
        url={`/versions/${version.id}`}
        version={version}
      />
    </>
  );
}
