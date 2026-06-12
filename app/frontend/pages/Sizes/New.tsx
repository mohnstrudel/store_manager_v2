import PageHeader from "@/components/PageHeader";
import routes from "@/utils/routes";
import Form from "./components/Form";
import { SizeRecord } from "./types";

type NewProps = {
  size: SizeRecord;
};

export default function New({ size }: NewProps) {
  return (
    <>
      <PageHeader className="mb-8" title="New Size" />
      <Form method="post" size={size} submitLabel="Create Size" url={routes.sizes.create.path()} />
    </>
  );
}
