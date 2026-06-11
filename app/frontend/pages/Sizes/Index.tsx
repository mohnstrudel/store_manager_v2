import ResourceIndexPage from "@/components/ResourceIndexPage";
import routes from "@/utils/routes";
import Table from "./components/Table";
import { SizeRecord } from "./types";

type IndexProps = {
  sizes: SizeRecord[];
};

export default function Index({ sizes }: IndexProps) {
  return (
    <ResourceIndexPage newPath={routes.sizes.new.path()} title="Sizes">
      <Table sizes={sizes} />
    </ResourceIndexPage>
  );
}
