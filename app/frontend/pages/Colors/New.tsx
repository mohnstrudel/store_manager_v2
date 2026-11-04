import PageHeader from "@/components/PageHeader";
import routes from "@/utils/routes";

import Form from "./components/Form";
import { ColorFormRecord } from "./types";

type NewProps = {
  color: ColorFormRecord;
};

export default function New({ color }: NewProps) {
  return (
    <>
      <PageHeader className="mb-8" title="New Color" />
      <Form
        color={color}
        method="post"
        submitLabel="Create Color"
        url={routes.colors.create.path()}
      />
    </>
  );
}
