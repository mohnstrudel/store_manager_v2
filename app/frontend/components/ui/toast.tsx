import { Toast as ToastPrimitive } from "@base-ui/react/toast";
import { InfoIcon, PartyPopperIcon, TriangleAlertIcon, XIcon } from "lucide-react";

const toast = ToastPrimitive.createToastManager();

const TOAST_CLASSES = [
  "group/toast pointer-events-auto absolute right-0 bottom-0 z-[calc(1000-var(--toast-index))] w-full origin-bottom rounded-2xl border shadow-lg will-change-transform outline-none select-none focus-visible:ring-[3px]",
  "border-gray-200 bg-white text-gray-950 dark:border-gray-800 dark:bg-gray-950 dark:text-gray-50",
  "data-[type=success]:border-lime-200 data-[type=success]:bg-lime-100 data-[type=success]:text-lime-800 dark:data-[type=success]:border-lime-700 dark:data-[type=success]:bg-lime-900 dark:data-[type=success]:text-lime-200",
  "data-[type=alert]:border-red-200 data-[type=alert]:bg-red-100 data-[type=alert]:text-red-800 dark:data-[type=alert]:border-red-700 dark:data-[type=alert]:bg-red-900 dark:data-[type=alert]:text-red-200",
  "[--gap:0.75rem] [--height:var(--toast-frontmost-height,var(--toast-height))] [--offset-y:calc(var(--toast-offset-y)*-1+calc(var(--toast-index)*var(--gap)*-1)+var(--toast-swipe-movement-y))] [--peek:0.75rem] [--scale:calc(max(0,1-(var(--toast-index)*0.1)))] [--shrink:calc(1-var(--scale))]",
  "h-(--height) [transform:translateX(var(--toast-swipe-movement-x))_translateY(calc(var(--toast-swipe-movement-y)-(var(--toast-index)*var(--peek))-(var(--shrink)*var(--height))))_scale(var(--scale))] [transition:transform_500ms_cubic-bezier(0.22,1,0.36,1),opacity_500ms,height_150ms] motion-reduce:transition-none",
  "after:absolute after:top-full after:left-0 after:h-[calc(var(--gap)+1px)] after:w-full after:content-['']",
  "data-expanded:h-(--toast-height) data-expanded:[transform:translateX(var(--toast-swipe-movement-x))_translateY(var(--offset-y))]",
  "data-limited:opacity-0 data-starting-style:[transform:translateY(150%)]",
  "[&[data-ending-style]:not([data-limited]):not([data-swipe-direction])]:[transform:translateY(150%)]",
  "data-ending-style:data-[swipe-direction=down]:[transform:translateY(calc(var(--toast-swipe-movement-y)+150%))]",
  "data-ending-style:data-[swipe-direction=left]:[transform:translateX(calc(var(--toast-swipe-movement-x)-150%))_translateY(var(--offset-y))]",
  "data-ending-style:data-[swipe-direction=right]:[transform:translateX(calc(var(--toast-swipe-movement-x)+150%))_translateY(var(--offset-y))]",
  "data-ending-style:data-[swipe-direction=up]:[transform:translateY(calc(var(--toast-swipe-movement-y)-150%))]",
].join(" ");

function Toaster() {
  return (
    <ToastPrimitive.Provider toastManager={toast}>
      <ToastPrimitive.Portal>
        <ToastPrimitive.Viewport className="pointer-events-none fixed inset-x-4 bottom-4 z-50 mx-auto w-auto max-w-md outline-none sm:right-4 sm:left-auto sm:mx-0 sm:w-full">
          <ToastList />
        </ToastPrimitive.Viewport>
      </ToastPrimitive.Portal>
    </ToastPrimitive.Provider>
  );
}

function ToastList() {
  const { toasts } = ToastPrimitive.useToastManager();

  return toasts.map((toastItem) => (
    <ToastPrimitive.Root className={TOAST_CLASSES} key={toastItem.id} toast={toastItem}>
      <ToastPrimitive.Content className="flex h-full items-center gap-3 overflow-hidden p-4 transition-opacity duration-250 data-behind:opacity-0 data-expanded:opacity-100">
        <ToastIcon type={toastItem.type} />
        <ToastPrimitive.Title className="min-w-0 flex-1 text-sm font-semibold" />
        <ToastPrimitive.Close
          aria-label="Close notification"
          className="relative shrink-0 rounded-full border-0 bg-transparent p-1 text-current opacity-70 hover:bg-current/10 dark:bg-transparent dark:hover:bg-current/10 after:absolute after:-inset-2 after:content-[''] hover:opacity-100"
        >
          <XIcon aria-hidden="true" className="size-4" />
        </ToastPrimitive.Close>
      </ToastPrimitive.Content>
    </ToastPrimitive.Root>
  ));
}

const TOAST_ICONS: Record<string, typeof InfoIcon> = {
  alert: TriangleAlertIcon,
  success: PartyPopperIcon,
};

function ToastIcon({ type }: { type: string | undefined }) {
  const Icon = TOAST_ICONS[type ?? ""] ?? InfoIcon;

  return <Icon aria-hidden="true" className="size-5 shrink-0" />;
}

export { Toaster, toast };
