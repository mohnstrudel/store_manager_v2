import ErrorNotice from "@/components/ErrorNotice";
import PageHeader from "@/components/PageHeader";
import Form from "./components/Form";
import { VersionErrors, VersionRecord } from "./types";

type NewProps = {
  errors?: VersionErrors;
  version: VersionRecord;
};

export default function New({ errors = {}, version }: NewProps) {
  return (
    <>
      <ErrorNotice errors={errors} />

      <PageHeader className="mb-8" title="New Version" />

      <Form
        errors={errors}
        method="post"
        submitLabel="Create Version"
        url="/versions"
        version={version}
      />
    </>
  );
}
