import PageHeader from "@/components/PageHeader";
import Form from "./components/Form";
import { VersionRecord } from "./types";

type NewProps = {
  version: VersionRecord;
};

export default function New({ version }: NewProps) {
  return (
    <>
      <PageHeader className="mb-8" title="New Version" />

      <Form method="post" submitLabel="Create Version" url="/versions" version={version} />
    </>
  );
}
