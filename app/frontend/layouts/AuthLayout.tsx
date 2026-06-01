import type { ReactNode } from "react";
import FlashMessages from "@/components/FlashMessages";

// Chrome for unauthenticated screens (sign in, sign up, password reset).
// Replaces the former unauthenticated.html.slim Rails layout: a centered,
// blurred card on the marketing background.
export default function AuthLayout({ children }: { children: ReactNode }) {
  return (
    <div className="wbg flex flex-1 flex-col items-center justify-center px-4 py-12">
      <div className="w-full max-w-3xl">
        <FlashMessages />
      </div>
      <div className="section_border_base w-full max-w-3xl min-h-96 px-4 py-8 backdrop-blur-xl lg:px-12 lg:py-14">
        {children}
      </div>
      <div className="text-md font-bold text-gray-400 mt-6">StoreMate</div>
    </div>
  );
}
