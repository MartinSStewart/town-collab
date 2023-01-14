// port supermario_copy_to_clipboard_to_js : String -> Cmd msg

exports.init = async function(app) {
  document.addEventListener(
    "keydown",
    (event) => {
        if (event.key === 'Tab')
        {
            event.preventDefault();
        }
    });

  window.addEventListener("mouseout", (event) => app.ports.mouse_leave.send());

  app.ports.get_local_storage.subscribe(() => app.ports.got_local_storage.send(window.localStorage.getItem("user-settings")));
  app.ports.set_local_storage.subscribe((text) => window.localStorage.setItem("user-settings", text));

  app.ports.supermario_read_from_clipboard_to_js.subscribe(function() {
    try {
        navigator.clipboard.readText().then((clipText) => app.ports.supermario_read_from_clipboard_from_js.send(clipText));
    }
    catch {
    }

  })

  app.ports.supermario_copy_to_clipboard_to_js.subscribe(function(text) {
    copyTextToClipboard(text);
  })
}

function copyTextToClipboard(text) {
  if (!navigator.clipboard) {
    fallbackCopyTextToClipboard(text);
    return;
  }
  navigator.clipboard.writeText(text).then(function() {
    // console.log('Async: Copying to clipboard was successful!');
  }, function(err) {
    console.error('Error: Could not copy text: ', err);
  });
}

function fallbackCopyTextToClipboard(text) {
  var textArea = document.createElement("textarea");
  textArea.value = text;

  // Avoid scrolling to bottom
  textArea.style.top = "0";
  textArea.style.left = "0";
  textArea.style.position = "fixed";

  document.body.appendChild(textArea);
  textArea.focus();
  textArea.select();

  try {
    var successful = document.execCommand('copy');
    if (successful !== true) {
      console.log('Error: Copying text command was unsuccessful');
    }
  } catch (err) {
    console.error('Error: Oops, unable to copy', err);
  }

  document.body.removeChild(textArea);
}
