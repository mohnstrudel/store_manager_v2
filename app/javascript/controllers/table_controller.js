import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="table"
export default class extends Controller {
  goTo(event) {
    if (event.target.className === "actions") return;
    if (event.target.parentNode.className === "actions") return;
    event.preventDefault();
    const url = window.location.origin + "/" + event.params.url;
    window.location.assign(url);
  }
}
