import ResourceIndexPage from "@/components/ResourceIndexPage";
import Table from "./components/Table";
import { VersionRecord } from "./types";

type IndexProps = {
  versions: VersionRecord[];
};

export default function Index({ versions }: IndexProps) {
  return (
    <ResourceIndexPage newPath="/versions/new" title="Versions">
      <Table versions={versions} />
    </ResourceIndexPage>
  );
}
