resource "azurerm_service_plan" "frontend" {
  name                = "asp-${var.project}-frontend-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name
  os_type             = "Windows"
  sku_name            = var.sku_name
  tags                = var.tags
}

resource "azurerm_windows_web_app" "frontend" {
  name                = "app-${var.project}-frontend-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name
  service_plan_id     = azurerm_service_plan.frontend.id

  site_config {
    always_on = var.sku_name == "F1" ? false : true

    application_stack {
      current_stack = "node"
      node_version  = "~20"
    }
  }

  app_settings = {
    WEBSITE_RUN_FROM_PACKAGE = "1"
    NODE_ENV                 = "production"
  }

  tags = var.tags
}
