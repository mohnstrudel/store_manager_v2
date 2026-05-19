import { useFlash } from "@/lib/useFlash";

export default function FlashMessages() {
  const flash = useFlash();

  if (!flash.notice && !flash.alert) return null;

  return (
    <div id="flash-messages">
      {flash.notice ? (
        <article className="h-auto mx-auto bg-lime-100 rounded-xl flex flex-col justify-between items-center gap-3 p-4 my-8 text-center text-lime-700 lg:h-24 lg:flex-row lg:gap-0 lg:p-8 lg:text-left dark:bg-lime-800/70 dark:text-lime-300/90">
          <i className="icn text-2xl lg:text-3xl">🙏</i>
          <p className="text-base font-semibold lg:text-lg">{flash.notice}</p>
          <i className="icn text-2xl lg:text-3xl">🙏</i>
        </article>
      ) : null}

      {flash.alert ? (
        <article className="h-auto mx-auto bg-red-100 rounded-xl flex flex-col justify-between items-center gap-3 p-4 my-8 text-center text-red-700 lg:h-24 lg:flex-row lg:gap-0 lg:p-8 lg:text-left dark:bg-red-800/60 dark:text-red-300">
          <i className="icn text-2xl lg:text-3xl">🚨</i>
          <p className="text-base font-semibold lg:text-lg">{flash.alert}</p>
          <i className="icn text-2xl lg:text-3xl">🚨</i>
        </article>
      ) : null}
    </div>
  );
}
