function disableAutocorrect(root = document) {
    root.querySelectorAll("input, textarea").forEach(el => {
        el.setAttribute("autocomplete", "off");
        el.setAttribute("autocorrect", "off");
        el.setAttribute("autocapitalize", "off");
        el.setAttribute("spellcheck", "false");
    });
}

document.addEventListener("DOMContentLoaded", () => disableAutocorrect());

new MutationObserver(mutations => {
    for (const { addedNodes } of mutations) {
        for (const node of addedNodes) {
            if (node.nodeType === 1) disableAutocorrect(node);
        }
    }
}).observe(document.documentElement, { childList: true, subtree: true });

import "@rails/request.js";
import "controllers";
import "activestorage"

ActiveStorage.start()

import "trix"
import "@rails/actiontext"

Trix.config.blockAttributes.default.tagName = "p"

Trix.config.blockAttributes.heading = {
    tagName: "h2",
    terminal: true,
    breakOnReturn: true,
    group: false
}

Trix.config.blockAttributes.subHeading = {
    tagName: "h3",
    terminal: true,
    breakOnReturn: true,
    group: false
}
