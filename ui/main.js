let ContextMenus = [];

let CurrentEntityOptions = [];

class ContextMenu {
  constructor({ options, isSubMenu, subMenuLocation = {}, parent }) {
    // Sort options object by index
    this.options = options.sort((a, b) => a.priority - b.priority);
    this.parent = parent;
    this.isSubMenu = isSubMenu;
    this.subMenuLocation = subMenuLocation;
    this.menuItemsNode = this.getMenuItemsNode();
    this.isSubMenuOpen = false;
    this.currentSubMenu = null;
    this.id = ContextMenus.length;
  }

  // Get menu items
  getMenuItemsNode() {
    const nodes = [];

    this.options.forEach((data, index) => {
      const item = this.createItemMarkup(data);
      item.first().attr("style", `animation-delay: ${index * 0.08}s`);
      nodes.push(item);
    });

    return nodes;
  }

  // Create menu item markup
  createItemMarkup(data) {
    const item = $("<li/>");
    const button = $("<button/>");
    const text = $("<span/>");
    if (data.icon) {
      const icon = $("<i/>");
      icon.addClass(`${data.icon.split(" ")[0]} ${data.icon.split(" ")[1]}`);
      button.append(icon);
    }

    text.html(data.label);
    button.append(text);
    button.addClass("contextMenu-button");
    item.addClass("contextMenu-item");

    if (data.subOptions && !data.isAction) {
      const subIcon = $("<i/>");
      subIcon.addClass("fas fa-chevron-right subIcon");
      button.append(subIcon);
    }

    if (data.subOptions && data.isAction) {
      const subIcon = $("<i/>");
      subIcon.addClass("fa-solid fa-align-right subIcon");
      button.append(subIcon);
      button.attr("data-isRightClickable", true);
    }

    const initSubMenu = (e) => {
      if (this.isSubMenuOpen) {
        this.currentSubMenu.deleteMenu();
      }
      const subMenu = new ContextMenu({
        options: data.subOptions,
        mode: this.mode,
        isSubMenu: true,
        parent: this,
        subMenuLocation: {
          x: button.offset().left + button.outerWidth() + 5,
          y: button.offset().top - 5,
        },
      });
      subMenu.init();
      this.isSubMenuOpen = true;
      this.currentSubMenu = subMenu;
    };

    button.contextmenu(() => {
      if (data.subOptions && data.isAction) {
        initSubMenu();
      }
    });

    button.click(() => {
      if (data.subOptions && !data.isAction) {
        initSubMenu();
      } else {
        $.post(
          `https://${GetParentResourceName()}/OPTION_SELECTED`,
          JSON.stringify({
            index: data.index,
          })
        );
        closeAllMenus();
        sendState(false);
      }
    });

    item.attr("id", data.index);

    if (!data.display) {
      item.addClass("hidden");
    }

    item.append(button);
    return item;
  }

  // Render menu markup
  renderMenu() {
    const menuContainer = $("<ul/>");

    menuContainer.addClass("contextMenu");

    menuContainer.attr("id", "contextMenu" + this.id);

    this.menuItemsNode.forEach((item) => {
      menuContainer.append(item);
    });

    return menuContainer;
  }

  // Initialize menu
  init(e) {
    const contextMenu = this.renderMenu();
    // On outside click remove menu
    $(document).on("click", (e) => {
      if (!e.target.closest(".contextMenu")) {
        this.deleteMenu();
        sendState(false);
      }
    });

    $("body").append(contextMenu)
    
    let positionX = 0;
    let positionY = 0;

    if (this.isSubMenu) {
      positionX = this.subMenuLocation.x;
      positionY = this.subMenuLocation.y;
    } else {
      const { clientX, clientY } = e;
      positionY = clientY
      positionX = clientX
    }

    if  (positionY + contextMenu.height() > window.innerHeight) {
      positionY = window.innerHeight - contextMenu.height()
    }

    contextMenu.attr(
      "style",
        `
          --top: ${positionY}px;
          --left: ${positionX}px;`
    );

    ContextMenus.push(this);
  }


  // Delete menu
  deleteMenu() {
    const menu = $("#contextMenu" + this.id);
    if (menu) menu.remove();
    if (this.parent) this.parent.isSubMenuOpen = false;
    if (this.currentSubMenu) this.currentSubMenu.deleteMenu();

    ContextMenus = ContextMenus.filter((menu) => menu.id !== this.id);

    if (ContextMenus.length === 0 && CurrentEntityOptions.length > 0) {
      $(".cursor-eye").css("display", "block");
    }
  }
}

const sendState = (state) => {
  $.post(
    `https://${GetParentResourceName()}/SET_MENU_STATE`,
    JSON.stringify({
      state: state,
    })
  );
};

const refreshCurrentEntityOptions = () => {
  $.post(`https://${GetParentResourceName()}/REFRESH_CURRENT_ENTITY_OPTIONS`);
};

const closeAllMenus = () => {
  ContextMenus.forEach((menu) => menu.deleteMenu());
};

$(document).on("contextmenu", function (e) {
  let isRightClickable = false;

  if (e.target.tagName === "BUTTON") {
    isRightClickable = e.target.attributes["data-isRightClickable"]
  } else {
    isRightClickable = e.target.parentElement?.attributes["data-isRightClickable"]
  }

  if (isRightClickable) return;

  e.preventDefault();

  if (ContextMenus.length > 0) {
    refreshCurrentEntityOptions();
  }

  closeAllMenus();

  if (CurrentEntityOptions.length > 0) {
    let CurrentContext = new ContextMenu({
      options: CurrentEntityOptions,
    });
    CurrentContext.init(e);
    sendState(true);
  }
  $(".cursor-eye").css("display", "none");
});

$(document).on("mousemove", function (e) {
  var x = e.clientX;
  var y = e.clientY;
  var newposX = x - 60;
  var newposY = y - 60;
  $(".eye").css(
    "transform",
    "translate3d(" + newposX + "px," + newposY + "px,0px)"
  );
});

const UpdateCurrentOptions = (options) => {
  if (options.length > 0) {
    $(".cursor-eye").css("display", "block");
  } else {
    $(".cursor-eye").css("display", "none");
  }

  CurrentEntityOptions = options;
};

window.addEventListener("message", function (event) {
  const data = event.data;
  const action = data.action;
  switch (action) {
    case "SET_OPTIONS":
      UpdateCurrentOptions(data.options);
      break;
    case "CHANGE_ITEM_STATE":
      if (data.state) {
        $(`#${data.index}`).removeClass("hidden").fadeIn()
      } else {
        $(`#${data.index}`).fadeOut().addClass("hidden");
      }
      break;
    case "CLOSE_CONTEXT_MENU":
      closeAllMenus();
      break;
  }
});
