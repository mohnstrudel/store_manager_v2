import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="table"
export default class extends Controller {
  goTo(event) {
    if (event.target.className === "actions") return;
    if (event.target.parentNode.className === "actions") return;
    if (event.target.closest(".no-events")) {
      return;
    }

    event.preventDefault();

    let url;
    if (event.params.id) {
      url =
        window.location.origin +
        event.params.url +
        "?selected=" +
        event.params.id +
        "#" +
        event.params.id;
    } else {
      url = window.location.origin + event.params.url;
    }

    if (event.metaKey || event.ctrlKey) {
      window.open(url, "_blank");
      return;
    }

    window.location.assign(url);
  }
}
