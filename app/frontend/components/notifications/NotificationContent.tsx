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
          <a className="link" href={link.href} {...newTabProps(link.href)}>
            {link.label}
          </a>
        </>
      ) : null}
    </>
  );
}

function newTabProps(href: string) {
  return href.startsWith("/jobs") ? { rel: "noopener noreferrer", target: "_blank" } : {};
}
