import ErrorNotice from "@/components/ErrorNotice";
import Link from "@/components/Link";
import Form from "./components/Form";
import { VersionErrors, VersionRecord } from "./types";

type EditProps = {
  errors: VersionErrors;
  version: VersionRecord;
};

export default function Edit({ errors, version }: EditProps) {
  return (
    <>
      <ErrorNotice errors={errors} />

      <header className="nav_header mb-8">
        <div className="flex gap-4">
          <h1>Edit Version</h1>
        </div>
        <menu className="nav_menu">
          <li>
            <Link href={`/versions/${version.id}`}>
              <i className="icn">📄</i>
              View Version Page
            </Link>
          </li>
        </menu>
      </header>

      <Form errors={errors} method="patch" submitLabel="Update Version" url={`/versions/${version.id}`} version={version} />
    </>
  );
}
