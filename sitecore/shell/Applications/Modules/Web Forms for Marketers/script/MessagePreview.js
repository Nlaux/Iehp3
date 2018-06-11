(function() {
  window.Sitecore = window.Sitecore || {};
  window.Sitecore.Wfm = window.Sitecore.Wfm || {};

  window.Sitecore.Wfm.MessagePreview = new MessagePreview();

  function MessagePreview() {
    var self = this;

    this.initialized = false;
    this.HtmlBodyID = "HtmlBody";
    this.LinksDisabled = true;

    this.MakeActive = function(target) {
      $("BtnText").className = "switchButton";
      $("BtnHtml").className = "switchButton";
      $(target).className = "switchButtonActive";
      $("ActiveModeButton").value = target;
    };

    this.Initialize = function() {
      if (self.initialized)
        return;

      self.initialized = true;

      setTimeout(self.AddBody, 5);
    };

    this.DisableFrameLinks = function() {
      var bodyFrame = $('BodyFrame');
      if (!bodyFrame) return;

      var links = bodyFrame.contentWindow.document.links;
      if (!links) return;

      for (var i = 0; i < links.length; i++) {
        links[i].onclick = function() { return false; };
      }
    };

    this.AddBody = function() {
      var bodyFrame = $('BodyFrame');
      if (!bodyFrame) {
        return;
      }

      var innerDoc = (bodyFrame.contentDocument) ? bodyFrame.contentDocument : bodyFrame.contentWindow.document;

      if (innerDoc.readyState != null && innerDoc.readyState != 'complete' && innerDoc.readyState != 'interactive') {
        setTimeout(self.AddBody, 1000);
        return;
      }

      var htmlBody = $(self.HtmlBodyID);
      var bodyText = htmlBody.innerText;

      if (bodyText == undefined)
        bodyText = htmlBody.textContent;

      bodyFrame.contentWindow.document.close();
      bodyFrame.contentWindow.document.open();

      bodyFrame.contentWindow.document.write(bodyText);

      if (self.LinksDisabled)
        self.DisableFrameLinks();
    };

    this.InsertBodyByTimeout = function() {
      if (self.initialized)
        return;

      var bodyFrame = $('BodyFrame');
      if (!bodyFrame)
        return;

      if ((bodyFrame.contentWindow.document.readyState == 'complete' || bodyFrame.contentWindow.document.readyState == 'interactive')) {
        self.AddBody();
      } else {
        setTimeout(self.InsertBodyByTimeout, 500);
      }
    };

    if (window.document.readyState != null) {
      setTimeout(self.InsertBodyByTimeout, 500);
    }
  }
})();