resource "azurerm_policy_definition" "Deploy-ASC-Standard" {
  name                  = "Deploy-ASC-Standard"
  policy_type           = var.policy_definition_category
  mode                  = "All"
  display_name          = "Deploy-ASC-Standard"
  policy_rule           = file("${path.module}/policies/Deploy-ASC-Standard/policy-rule.json")
  parameters            = file("${path.module}/policies/Deploy-ASC-Standard/policy-parameter.json")
}
