import type { ReactNode } from "react";
import FlashMessages from "@/components/FlashMessages";

export default function AppLayout({ children }: { children: ReactNode }) {
  return (
    <>
      <FlashMessages />
      {children}
    </>
  );
}
