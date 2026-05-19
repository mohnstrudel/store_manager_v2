import { router } from "@inertiajs/react";
import Button from "@/components/Button";
import FlashMessages from "@/components/FlashMessages";
import Link from "@/components/Link";
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
      <FlashMessages />

      <header className="nav_header">
        <div className="flex gap-4">
          <hgroup>
            <h1>{version.value}</h1>
            <h4>Version {version.id}</h4>
          </hgroup>
        </div>
        <menu className="nav_menu">
          <li>
            <Link href={`/versions/${version.id}/edit`}>
              <i className="icn">✏</i>
              Edit
            </Link>
          </li>
        </menu>
      </header>

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
