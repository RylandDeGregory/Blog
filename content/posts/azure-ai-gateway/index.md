---
title: "Use the Azure APIM AI Gateway"
date: 2026-10-03T16:10:00-04:00
draft: false
author: "Ryland DeGregory"
authorlink: "/about/"
categories:
- AI
- Azure
- Bicep
---

As AI continues to proliferate across the corporate world, and the marketplace of capable models continues to expand, the landscape of API providers expands with it. Rather than continue this sprawl, most organizations now look to centralize capacity, cost, governance, and observability so AI usage is aligned to their enterprise policies. Enter the "AI Gateway".

<!--more-->

## What is an AI Gateway

It's no secret that juggling half a dozen provider endpoints, multiple API keys and tokens, and increasingly confusing consumption patterns has become one of the most challenging parts of operating an AI-assisted development workflow or AI-enabled product. AI Gateways have become one of the hottest categories in the rapidly-growing field of "AI Infrastructure Management," and every major tech company and startup is racing to get in on the gold rush. The old adage is that, "in a gold rush, it's best to sell shovels," but in enterprise IT, it's often best to be the broker. You get visibility, attribution, and control; clients and users get ease of setup, clarity into consumption, and policy alignment without having to think about it.

The value of these services is reflected in the market. Payment tech giant Stripe acquired the OG AI gateway, OpenRouter, for [$7.5 Billion](https://www.nytimes.com/2026/08/19/business/stripe-openrouter-ai.html), hoping to become the AI model inference equivalent of what it already is for web payments. Palo Alto purchased self-hostable AI gateway Portkey for [$140 Million](https://www.paloaltonetworks.com/company/press/2026/palo-alto-networks-completes-acquisition-of-portkey-to-secure-ai-agents) to integrate it into their existing enterprise security stack. Cloudflare and Vercel's AI gateways both serve tens of trillions of tokens across multiple providers to enterprises and solo vibe coders alike.

### Where does Microsoft sit in all of this?

Microsoft, the enterprise IT stalwart, has long touted the [AI Gateway capabilities](https://learn.microsoft.com/en-us/azure/api-management/genai-gateway-capabilities) of its API Management Service, all the way back to [April 2024](https://github.com/Azure-Samples/AI-Gateway/commit/ef4e3e0fa9303270f23159d6b12ee266a5c8bd31). But it has also long been a highly manual, inflexible, and unpleasant experience—even by APIM standards. As someone building the infrastructure for an AI platform "in my day job," and having worked with APIM as an AI Gateway for the Azure OpenAI Service (now Microsoft Foundry) since before their repo was even launched, I've yearned for a (hopefully better) alternative.

Microsoft's solution (and its attempt to impact the market) is the [AI Gateway tier](https://learn.microsoft.com/en-us/azure/api-management/ai-gateway-overview). It's an entirely new experience, complete with a new portal, new management primitives and paradigms, and new quirks. It's currently in preview, but will likely go GA at Microsoft's Ignite conference next month.

## Provisioning and operating

Following the trend of other new "Azure in the AI age" services, including Microsoft Foundry, Azure Container Apps, and Web IQ, the APIM AI Gateway tier gets its own external vibe-coded purple and blue gradient portal: [ai.gateway.azure.com](https://ai.gateway.azure.com/). Today, during preview, the expected ways to interact with the service are exclusively through that portal and through coding agents using the AI Gateway skills. Neither of these work well for enterprise IT teams that manage their cloud infrastructure exclusively via IaC (as everyone should strive to do... ClickOps == bad).

Ever the early adopter, I've been eager to get up to speed on the AI Gateway tier's new operating model compared to "traditional" APIM: No API specs to find and edit (enigmatically, OpenAPI != APIM-compatible OpenAPI), no XML policies to write (*thank goodness*), no backend pools to manage. In this new world, we have three main primitives: providers, models, and aliases. That sounds a lot better already...

After following the [Microsoft quickstart](https://ai.gateway.azure.com/docs/quickstarts/portal), I spent an hour clicking around the portal and was able to get a Foundry provider set up and call a GPT model. But it wasn't much longer before I began getting frustrated with having to go back and forth between screens to test different configurations, waiting for the UI to catch up to my navigation, and breaking things by navigating to pages and modals in unexpected orders. I gave up. I need automation. I need IaC.

Unfortunately, Microsoft doesn't publish any Bicep or Terraform documentation for the new resource SKU (yes, it's simply a different SKU of the existing `Microsoft.ApiManagement/services` ARM resource with a stripped down feature set), Azure CLI command group, Azure PowerShell module, or even a [REST API spec](https://raw.githubusercontent.com/Azure/azure-rest-api-specs/refs/heads/main/specification/apimanagement/resource-manager/Microsoft.ApiManagement/ApiManagement/preview/2025-09-01-preview/openapi.json) (seriously, try to CTRL+F that spec for `modelProvider` or `alias`). I only discovered the Resource Provider API version it uses (`2025-09-01-preview`) by opening the JSON view of the service in the (real) Azure Portal. Once I found that, I knew what the next logical step was: reverse-engineer the AI Gateway portal so I could extract the ARM entities it creates and manages into a repeatable, versioned, testable Bicep template.

### Beyond the Bicep bleeding edge

I've been working with Bicep since it was announced in August 2020, and I've been a massive fan ever since. One of the best parts about it is the wonderful developer experience in VS Code with its LSP and [extension](https://marketplace.visualstudio.com/items?itemName=ms-azuretools.vscode-bicep). IntelliSense for resource types, local and AVM modules, and resource properties is an absolute game changer when working with Azure programmatically, where the hundreds of resource providers, thousands of resource types, and dozens of API versions (for each resource), each with their own properties, allowed values, and rough edges, make it impossible to maintain mentally and awful to look up documentation for. Without that tooling, when you're forced to resort to guessing at resource shapes (or worse, letting an AI agent hallucinate them), each iteration of your "inner loop" becomes a full deploy, wait, debug dance with ARM. Let's just say it loses its luster *very* fast. All that to say, that was my exact experience with getting this service working through Bicep...me and [BCP081](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/bicep-core-diagnostics#BCP081) got real close.

To their credit, Microsoft publishes a [half-baked sample](https://github.com/Azure-Samples/simple-foundry-hosted-agent-python-aigateway), which includes infrastructure defined in Bicep. But like most of their samples, it is incomplete, is meant for a hello-world experience, and hasn't been updated to work with the new features of the rapidly changing service in months. When I first explored the sample and tried to deploy it, I still needed to create model aliases manually in the portal before I was able to call the gateway. So, in my mind, the sample didn't really work at all... but it did give me a place to start and an idea of how to model the basic gateway components, like the service, workspace, and nested model provider.

Once I dug further into my manually deployed resource, I found more and more capabilities and settings that weren't documented (or configured in the sample) but *could* be done from the browser. I figured I'd need to pull out one of my favorite "Undocumented Microsoft Azure API detective" tricks: capturing and reviewing browser [HAR](https://en.wikipedia.org/wiki/HAR_(file_format)) files, generated by performing various management operations in the AI Gateway portal. This gave me the API contracts, endpoints (which generally translate to resource types!), and parent/child relationships I needed to complete my Bicep implementation.

The true beauty of ARM is that, regardless of the interaction channel (PowerShell, CLI, REST, Bicep, Terraform, SDK, etc.) the control plane request/response shape is identical. So spending the time to figure out the entity shape once by reverse-engineering the REST API allows you to translate it directly into a Bicep resource. BCP081 be damned.

## A GitHub repo for all to use

My findings produced [RylandDeGregory/AIGateway](https://github.com/RylandDeGregory/AIGateway), a complete Azure APIM AI Gateway solution that includes:

- Private Virtual Network integration between all services
- OTel telemetry export to an Azure Monitor Workspace / Application Insights
- Managed Identity authentication from AI Gateway to the Foundry backend
- Model providers for all three major AI labs: OpenAI, Anthropic, and Google
    - Brogrammers fear not: Grok is also available via Foundry, but it is not included in my sample `bicepparam` file
- Stable model aliases for each model provider and API wire format: `luna`, `sonnet`, and `gemini`

{{% admonition type=note title="A note on pricing" open=false %}}

I found the new SKU (which is free during preview) leverages the (previously restricted to Premium SKUs) [Workspaces feature](https://learn.microsoft.com/en-us/azure/api-management/workspaces-overview) of APIM to encapsulate new child resource types (providers, models, aliases) aligned to the primitives seen in the portal. If this alludes to the future pricing model, all I can say is: yikes.

{{% /admonition %}}

### Calling models

The repo contains samples for calling OpenAI, Anthropic, and Gemini models via their model providers from both cURL and PowerShell. But let's be honest: most of us are going to connect to our AI Gateway using a coding agent. Claude, Codex, and Copilot—oh my!

## Use AI Gateway with coding agents

Microsoft provides a [coding agent plugin](https://ai.gateway.azure.com/docs/quickstarts/skills) for AI Gateway that can help connect your local environment to your new AI Gateway, but I've included high-level guidance for all the coding agents I've used below. Happy vibing!

The first step is to set your `AZURE_AI_GATEWAY_API_KEY` environment variable by getting a key from the [AI Gateway Access page](https://ai.gateway.azure.com/access/keys). This environment variable is then used by the coding agents to configure authentication for their requests to the AI Gateway.

### Claude

Update your [Claude settings file](https://code.claude.com/docs/en/settings) with the following values.

{{% admonition type=info title="Why are there two auth env vars?" open=false %}}

The `ANTHROPIC_API_KEY` is intentionally a placeholder. It is not used by the AI Gateway (as it is sent by Claude in `x-api-key`, whereas the AI Gateway only accepts `api-key`), but it is required for Claude to work.

{{% /admonition %}}

This configuration works for both Claude Code CLI and Desktop.

```json
{
    "env": {
        "ANTHROPIC_BASE_URL": "https://<aiGatewayEndpoint>/default/models/anthropic",
        "ANTHROPIC_API_KEY": "placeholder",
        "ANTHROPIC_MODEL": "sonnet",
        "ANTHROPIC_DEFAULT_SONNET_MODEL": "sonnet",
        "ANTHROPIC_SMALL_FAST_MODEL": "sonnet",
        "CLAUDE_CODE_DISABLE_UNKNOWN_MODEL_WINDOW_ENFORCEMENT": "1"
    }
}
```

Claude's settings file cannot expand process or user environment variable names into their values directly, so also set the required authentication environment variable for your user or process before running `claude`.

- Bash: `export ANTHROPIC_CUSTOM_HEADERS="api-key: $AZURE_AI_GATEWAY_API_KEY"`
- PowerShell: `$env:ANTHROPIC_CUSTOM_HEADERS = "api-key: $AZURE_AI_GATEWAY_API_KEY"`

### Codex

Update your [Codex config file](https://learn.chatgpt.com/docs/config-file/config-basic) with the following values.

This configuration works for both Codex CLI and App.

```toml
model_provider = "azure_ai_gateway"
model = "luna"

[model_providers.azure_ai_gateway]
name = "Azure AI Gateway"
base_url = "https://<aiGatewayEndpoint>/default/models/openai/v1"
wire_api = "responses"
requires_openai_auth = false

[model_providers.azure_ai_gateway.env_http_headers]
api-key = "AZURE_AI_GATEWAY_API_KEY"

```

### GitHub Copilot

#### App

Sadly, the GitHub Copilot App doesn't currently support secure storage of Custom Provider API Headers.

You *can* get it working by configuring a Custom Endpoint provider with the following settings:

- **Display name:** `Azure AI Gateway`
- **Base URL:** `https://<aiGatewayEndpoint>/default/models/openai/v1`
- **Wire API:** `responses`
- **Custom headers (JSON):** `{"api-key": "<gateway API key>"}`

And then add a Model with the following settings:

- **Model ID:** `luna`
- **Display name:** `GPT-6 Luna`

But, don't get too excited. Your gateway API key will sit in the app's runtime config in plaintext. Which is...sub-optimal, and definitely not recommended.

#### CLI

Update your GitHub Copilot [environment variables](https://github.com/copilot-dev-days/copilot-cli-deep-dive-workshop/blob/main/docs/workshop/13-configuration.md?utm_source=chatgpt.com#environment-variables-reference) with the following values.

```shell
export COPILOT_PROVIDER_BASE_URL='https://<aiGatewayEndpoint>/default/models/openai/v1'
export COPILOT_PROVIDER_HEADERS="api-key:${AZURE_AI_GATEWAY_API_KEY}"
export COPILOT_PROVIDER_TYPE='openai'
export COPILOT_PROVIDER_WIRE_API='responses'
export COPILOT_PROVIDER_WIRE_MODEL='luna'
export COPILOT_PROVIDER_MODEL_ID='GPT-6 Luna'
```

```powershell
$env:COPILOT_PROVIDER_BASE_URL = 'https://<aiGatewayEndpoint>/default/models/openai/v1'
$env:COPILOT_PROVIDER_HEADERS = "api-key:$env:AZURE_AI_GATEWAY_API_KEY"
$env:COPILOT_PROVIDER_TYPE = 'openai'
$env:COPILOT_PROVIDER_WIRE_API = 'responses'
$env:COPILOT_PROVIDER_WIRE_MODEL = 'luna'
$env:COPILOT_PROVIDER_MODEL_ID = 'GPT-6 Luna'
```

For working with Gemini, use the following values

```powershell
$env:COPILOT_PROVIDER_BASE_URL = 'https://<aiGatewayEndpoint>/default/models/v1'
$env:COPILOT_PROVIDER_HEADERS = "api-key:$env:AZURE_AI_GATEWAY_API_KEY"
$env:COPILOT_PROVIDER_TYPE = 'openai'
$env:COPILOT_PROVIDER_WIRE_API = 'completions'
$env:COPILOT_PROVIDER_WIRE_MODEL = 'gemini'
$env:COPILOT_PROVIDER_MODEL_ID = 'Gemini 3.5 Flash Lite'
```

#### VS Code

Update your [VS Code chatLanguageModels.json](https://code.visualstudio.com/docs/agent-customization/language-models#_bring-your-own-language-model-key) with the following values.

I recommend setting the provider up using the interactive flow, which generates the secure `input:chat.lm.secret` value for the API key. You can then edit the Custom Endpoint Provider in the JSON to make other changes.

```json
[
    {
        "name": "Azure AI Gateway",
        "vendor": "customendpoint",
        "apiKey": "${input:chat.lm.secret.-5adef7d1}",
        "models": [
            {
                "apiType": "responses",
                "id": "luna",
                "name": "GPT-6 Luna",
                "url": "https://<aiGatewayEndpoint>/default/models/openai/v1",
                "requestHeaders": {
                    "api-key": "${apiKey}"
                },
                "toolCalling": true,
                "vision": true,
                "maxInputTokens": 922000,
                "maxOutputTokens": 128000
            },
            {
                "apiType": "chat-completions",
                "id": "gemini",
                "name": "Gemini 3.5 Flash Lite",
                "url": "https://<aiGatewayEndpoint>/default/models/v1",
                "requestHeaders": {
                    "api-key": "${apiKey}"
                },
                "toolCalling": true,
                "vision": true,
                "maxInputTokens": 922000,
                "maxOutputTokens": 128000
            },
            {
                "id": "sonnet",
                "name": "Claude Sonnet 5.5",
                "url": "https://<aiGatewayEndpoint>/default/models/anthropic/v1",
                "requestHeaders": {
                    "api-key": "${apiKey}"
                },
                "toolCalling": true,
                "vision": true,
                "maxInputTokens": 922000,
                "maxOutputTokens": 128000
            }
        ]
    }
]
```

To use the Custom Endpoint provider in the VS Code Agents window, set `"chat.agentHost.byokModels.enabled": true` in VS Code's [`settings.json`](https://code.visualstudio.com/docs/configure/settings).

### OpenCode

Update your [OpenCode config file](https://opencode.ai/docs/config/) with the following values.

This configuration works for both OpenCode CLI and Desktop.

```json
{
    "$schema": "https://opencode.ai/config.json",
    "model": "azure_ai_gateway/luna",
    "providers": {
        "azure_ai_gateway": {
            "name": "Azure AI Gateway",
            "package": "@opencode/ai/providers/openai/responses",
            "settings": {
                "baseURL": "https://<aiGatewayEndpoint>/default/models/openai/v1"
            },
            "headers": {
                "api-key": "{env:AZURE_AI_GATEWAY_API_KEY}"
            },
            "models": {
                "luna": {
                    "name": "GPT-6 Luna",
                    "modelID": "luna"
                }
            }
        },
        "azure_ai_gateway_anthropic": {
            "name": "Azure AI Gateway (Anthropic)",
            "package": "@opencode/ai/providers/anthropic",
            "settings": {
                "baseURL": "https://<aiGatewayEndpoint>/default/models/anthropic/v1"
            },
            "headers": {
                "api-key": "{env:AZURE_AI_GATEWAY_API_KEY}"
            },
            "models": {
                "sonnet": {
                    "name": "Claude Sonnet 5.5",
                    "modelID": "sonnet"
                }
            }
        }
    }
}
```

I was unable to get the Google AI Studio provider to work in OpenCode, seemingly due to [this GitHub issue](https://github.com/anomalyco/opencode/issues/45113). The provider config I tried with is below for reference, in case a future version fixes the problem.

```json
"azure_ai_gateway_chat_completions": {
    "name": "Azure AI Gateway (Gemini)",
    "package": "@opencode/ai/providers/openai/chat",
    "settings": {
        "baseURL": "https://aigw-x2cetz6c.azure-api.net/default/models/v1",
        "setCacheKey": false
    },
    "headers": {
        "api-key": "{env:AZURE_AI_GATEWAY_API_KEY}"
    },
    "models": {
        "gemini": {
            "name": "Gemini 3.5 Flash Lite",
            "modelID": "gemini"
        }
    }
}
```

## Closing thoughts & follow up

Microsoft's "official" AI Gateway offering is definitely a step in the right direction when compared to the "standard" APIM experience, because it provides a simplified UX that goes a long way toward providing the "paved path" for developers and IT admins that Microsoft is so well known for. While my experience setting up Bicep was... challenging... it's also nothing new for preview Azure services, and I wholly expect the management and automation experience to improve meaningfully once the service hits GA. Until then, reap the fruits of my labor in your own PoC!

In part 2 of this post, I'll dive into more of the new differentiating features of the AI Gateway SKU, including managed MCP servers, Connection Namespaces, Toolboxes, Entra ID Gateway auth, and managed (XML-free!) policies.

Thanks for reading!