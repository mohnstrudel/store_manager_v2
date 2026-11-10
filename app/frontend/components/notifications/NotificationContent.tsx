import type { FlashMessage } from "@/types/inertia";

export default function NotificationContent({ notification }: { notification: FlashMessage }) {
  if (typeof notification === "string") return notification;

  const { link, message } = notification;

  return (
    <>
      {message}
      {link ? (
        <>
          {" "}
          <a className="link" href={link.href}>
            {link.label}
          </a>
          {link.suffix ? ` ${link.suffix}` : null}
        </>
      ) : null}
    </>
  );
}
