import { router, usePage } from "@inertiajs/react";
import { useCallback } from "react";

type ImportFailureActionsProps = {
  orderName: string;
  pullPath: string;
  sentryUrl: string | null;
};

export default function ImportFailureActions({
  orderName,
  pullPath,
  sentryUrl,
}: ImportFailureActionsProps) {
  const page = usePage();
  const pullAgain = useCallback(() => {
    router.post(pullPath, { return_to: page.url }, { preserveScroll: true });
  }, [page.url, pullPath]);

  return (
    <div className="flex flex-wrap items-center gap-2">
      <button
        aria-label={`Pull ${orderName} again`}
        className="btn_xs"
        onClick={pullAgain}
        type="button"
      >
        Pull again
      </button>
      {sentryUrl && (
        <a
          aria-label={`Open ${orderName} in Sentry`}
          className="link"
          href={sentryUrl}
          rel="noopener noreferrer"
          target="_blank"
        >
          Open in Sentry
        </a>
      )}
    </div>
  );
}
