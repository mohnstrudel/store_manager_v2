import ErrorNotice from "@/components/ErrorNotice";
import Form from "./components/Form";
import { VersionErrors, VersionRecord } from "./types";

type NewProps = {
  errors: VersionErrors;
  version: VersionRecord;
};

export default function New({ errors, version }: NewProps) {
  return (
    <>
      <ErrorNotice errors={errors} />

      <header className="nav_header mb-8">
        <div className="flex gap-4">
          <h1>New Version</h1>
        </div>
      </header>

      <Form errors={errors} method="post" submitLabel="Create Version" url="/versions" version={version} />
    </>
  );
}
