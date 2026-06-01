import { Link } from "@inertiajs/react";
import Button from "@/components/Button";
import PageHeader from "@/components/PageHeader";
import { useConfirmedDestroy } from "@/lib/useConfirmedDestroy";
import Details from "./components/Details";
import Products from "./components/Products";
import { ProductRecord, VersionRecord } from "./types";

type ShowProps = {
  products: ProductRecord[];
  version: VersionRecord;
};

export default function Show({ products, version }: ShowProps) {
  const destroyVersion = useConfirmedDestroy(`/versions/${version.id}`);

  return (
    <>
      <PageHeader subtitle={`Version ${version.id}`} title={version.value}>
        <li>
          <Link href={`/versions/${version.id}/edit`} prefetch>
            <i className="icn">✏</i>
            Edit
          </Link>
        </li>
      </PageHeader>

      <div className="section_wide flex flex-col gap-8 mt-8">
        <Details version={version} />
        <Products products={products} />
      </div>

      <Button className="w-full h-12 mt-16" onClick={destroyVersion} variant="danger">
        Destroy this version
      </Button>
    </>
  );
}
