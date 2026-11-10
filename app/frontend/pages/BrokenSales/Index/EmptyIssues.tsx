import type { ReactNode } from "react";

export default function EmptyIssues({ children }: { children: ReactNode }) {
  return <p className="py-12 text-center text-gray-500 dark:text-gray-400">{children}</p>;
}
