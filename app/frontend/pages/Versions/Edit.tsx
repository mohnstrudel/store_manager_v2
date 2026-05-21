import Link from "@/components/Link";
import PageHeader from "@/components/PageHeader";
import Form from "./components/Form";
import { VersionRecord } from "./types";

type EditProps = {
  version: VersionRecord;
};

export default function Edit({ version }: EditProps) {
  return (
    <>

      <PageHeader
        actions={
          <li>
            <Link href={`/versions/${version.id}`}>
              <i className="icn">📄</i>
              View Version Page
            </Link>
          </li>
        }
        className="mb-8"
        title="Edit Version"
      />

      <Form
        method="patch"
        submitLabel="Update Version"
        url={`/versions/${version.id}`}
        version={version}
      />
    </>
  );
}
