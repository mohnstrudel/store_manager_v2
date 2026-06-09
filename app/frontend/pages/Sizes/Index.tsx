import ResourceIndexPage from "@/components/ResourceIndexPage";
import Table from "./components/Table";
import { SizeRecord } from "./types";

type IndexProps = {
  sizes: SizeRecord[];
};

export default function Index({ sizes }: IndexProps) {
  return (
    <ResourceIndexPage newPath="/sizes/new" title="Sizes">
      <Table sizes={sizes} />
    </ResourceIndexPage>
  );
}
