import { useEffect } from "react";
import type { ReactNode } from "react";

import FlashMessages from "@/components/flash-messages/FlashMessages";

// Layout for unauthenticated screens: sign in, sign up, password reset
export default function AuthLayout({ children }: { children: ReactNode }) {
  useBodyBackgroundImage();

  return (
    <div className="flex min-h-screen flex-col items-center py-4">
      <FlashMessages />

      <div className="flex flex-1 w-full items-center justify-center">
        <div className="section_border_base bg-transparent w-full max-w-3xl min-h-96 px-4 py-8 backdrop-blur border-gray-500/20 dark:shadow-2xl lg:px-12 lg:py-14">
          {children}
        </div>
      </div>

      <div className="text-md font-bold text-gray-400 mt-6">StoreMate</div>
    </div>
  );
}

function useBodyBackgroundImage() {
  useEffect(() => {
    document.body.classList.add("wbg");

    return () => {
      document.body.classList.remove("wbg");
    };
  }, []);
}
