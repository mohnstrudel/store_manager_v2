import { Link, router } from "@inertiajs/react";
import { useCallback, useMemo, useState } from "react";

import ImageUnavailable from "@/components/ImageUnavailable";
import Modal from "@/components/Modal";
import routes from "@/utils/routes";

import type { SalesTagDetailRecord, SalesTagSaleLink } from "../types";
import { leaveModalVisit } from "./modalVisits";

const previewSize = "aspect-3/4 w-25 shrink-0";

type TagDetailModalProps = {
  salesTag: SalesTagDetailRecord;
};

export default function TagDetailModal({ salesTag }: TagDetailModalProps) {
  const close = useCallback(() => router.visit(routes.salesTags.index.path(), leaveModalVisit), []);
  const title = useMemo(
    () => (
      <span className="sales_tag_title" data-color={salesTag.color}>
        {salesTag.name}
      </span>
    ),
    [salesTag.color, salesTag.name],
  );

  return (
    <Modal onClose={close} title={title}>
      <div className="max-h-[calc(100dvh-23rem)] overflow-y-auto p-1.5">
        <SaleLinks sales={salesTag.sales} />
      </div>
    </Modal>
  );
}

function SaleLinks({ sales }: { sales: SalesTagSaleLink[] }) {
  if (sales.length === 0) {
    return <p className="text-gray-500 dark:text-gray-400">No sale uses this tag yet.</p>;
  }

  return (
    <ol aria-label="Sales with this tag" className="flex flex-col gap-4">
      {sales.map((sale, index) => (
        <li className="flex items-start gap-3" key={sale.id}>
          <span aria-hidden className="w-6 shrink-0 text-right">
            {index + 1}.
          </span>
          <SalePreview sale={sale} />
          <Link className="link min-w-0" href={sale.path}>
            {sale.label}
          </Link>
        </li>
      ))}
    </ol>
  );
}

function SalePreview({ sale }: { sale: SalesTagSaleLink }) {
  const item = sale.items.find((candidate) => candidate.product_thumb_url);

  if (!item?.product_thumb_url) {
    return <ImageUnavailable alt={sale.label} className={previewSize} />;
  }

  return (
    <PreviewPicture
      alt={item.title}
      fallbackAlt={sale.label}
      key={item.product_thumb_url}
      src={item.product_thumb_url}
    />
  );
}

type PreviewPictureProps = {
  alt: string;
  fallbackAlt: string;
  src: string;
};

function PreviewPicture({ alt, fallbackAlt, src }: PreviewPictureProps) {
  const [failed, setFailed] = useState(false);
  const markFailed = useCallback(() => setFailed(true), []);

  if (failed) return <ImageUnavailable alt={fallbackAlt} className={previewSize} />;

  return (
    <img
      alt={alt}
      className={`${previewSize} rounded-md object-cover object-top`}
      loading="lazy"
      onError={markFailed}
      src={src}
    />
  );
}
