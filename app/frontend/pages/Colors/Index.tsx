import ResourceIndexPage from "@/components/ResourceIndexPage";
import routes from "@/utils/routes";

import Table from "./components/Table";
import { ColorRecord } from "./types";

type IndexProps = {
  colors: ColorRecord[];
};

export default function Index({ colors }: IndexProps) {
  return (
    <ResourceIndexPage newPath={routes.colors.new.path()} title="Colors">
      <Table colors={colors} />
    </ResourceIndexPage>
  );
}
