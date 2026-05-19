import ErrorNotice from "@/components/ErrorNotice";
import Link from "@/components/Link";
import PageHeader from "@/components/PageHeader";
import Form from "./components/Form";
import { VersionErrors, VersionRecord } from "./types";

type EditProps = {
  errors?: VersionErrors;
  version: VersionRecord;
};

export default function Edit({ errors = {}, version }: EditProps) {
  return (
    <>
      <ErrorNotice errors={errors} />

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
        errors={errors}
        method="patch"
        submitLabel="Update Version"
        url={`/versions/${version.id}`}
        version={version}
      />
    </>
  );
}
