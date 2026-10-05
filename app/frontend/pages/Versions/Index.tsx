import ResourceIndexPage from "@/components/ResourceIndexPage";
import routes from "@/utils/routes";

import Table from "./components/Table";
import { VersionRecord } from "./types";

type IndexProps = {
  versions: VersionRecord[];
};

export default function Index({ versions }: IndexProps) {
  return (
    <ResourceIndexPage newPath={routes.versions.new.path()} title="Versions">
      <Table versions={versions} />
    </ResourceIndexPage>
  );
}
