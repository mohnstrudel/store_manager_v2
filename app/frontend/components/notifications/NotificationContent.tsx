import type { NotificationMessage } from "./notification";

export default function NotificationContent({
  notification,
}: {
  notification: NotificationMessage;
}) {
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
        </>
      ) : null}
    </>
  );
}
