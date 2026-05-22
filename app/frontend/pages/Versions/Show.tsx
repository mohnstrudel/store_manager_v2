import { router, Link } from "@inertiajs/react";
import Button from "@/components/Button";
import PageHeader from "@/components/PageHeader";
import Details from "./components/Details";
import Products from "./components/Products";
import { ProductRecord, VersionRecord } from "./types";

type ShowProps = {
  products: ProductRecord[];
  version: VersionRecord;
};

export default function Show({ products, version }: ShowProps) {
  function destroyVersion() {
    if (window.confirm("Are you sure?")) {
      router.delete(`/versions/${version.id}`);
    }
  }

  return (
    <>
      <PageHeader
        actions={
          <li>
            <Link href={`/versions/${version.id}/edit`}>
              <i className="icn">✏</i>
              Edit
            </Link>
          </li>
        }
        subtitle={`Version ${version.id}`}
        title={version.value}
      />

      <div className="section-wide flex flex-col gap-8 mt-8">
        <Details version={version} />
        <Products products={products} />
      </div>

      <Button className="w-full h-12 mt-16" onClick={destroyVersion} variant="danger">
        Destroy this version
      </Button>
    </>
  );
}
